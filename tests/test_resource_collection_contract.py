from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
VISIBILITY = (ROOT / "modules/ResourceNodeVisibility.luau").read_text(encoding="utf-8")


class ResourceCollectionContractTests(unittest.TestCase):
    def test_registry_matches_spawned_nodes(self):
        registry_section = WORLD.split("local resourceNodeIds = {", 1)[1].split("}", 1)[0]
        registry = set(re.findall(r"^\s*([A-Za-z0-9_]+)\s*=\s*true,", registry_section, re.MULTILINE))
        definitions = set(re.findall(r'^\s*key = "([^"]+)"', WORLD, re.MULTILINE))
        self.assertEqual(registry, definitions)

    def test_each_player_has_an_independent_cooldown(self):
        self.assertIn("session.resourceCooldowns[def.key] = nextReadyAt", WORLD)
        self.assertIn("local readyAt = session.resourceCooldowns[def.key] or 0", WORLD)
        self.assertIn("old.resourceCooldowns = savedCooldowns", WORLD)
        self.assertNotIn("state.active = false", WORLD)
        self.assertNotIn("state.model:Destroy()", WORLD)

    def test_unique_collectibles_are_permanent_per_player(self):
        self.assertIn('if def.kind == "unique" then', WORLD)
        self.assertIn("session.collectedNodes[def.key] = true", WORLD)
        self.assertIn("old.collectedNodes = savedCollected", WORLD)
        self.assertIn("for nodeId, collected in savedCollected do", WORLD)

    def test_profile_schema_and_migration_compatible_fields(self):
        self.assertIn("old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 11)", WORLD)
        self.assertIn('"IronOre", "IronIngot"', WORLD)

    def test_saving_legacy_schema_never_downgrades_newer_profile(self):
        self.assertIn("math.max(tonumber(old.schemaVersion) or 0, 11)", WORLD)
        self.assertIn("local savedIsland = type(old.island) == \"table\" and old.island", WORLD)
        self.assertIn("if type(savedIsland.buildings) ~= \"table\" then", WORLD)
        self.assertIn("savedIsland.buildings = {}", WORLD)
        self.assertIn("data.resourceCooldowns", WORLD)
        self.assertIn("data.collectedNodes", WORLD)

    def test_server_checks_prompt_distance(self):
        self.assertIn("p.MaxActivationDistance + 1", WORLD)
        self.assertIn("(root.Position-part.Position).Magnitude", WORLD)

    def test_client_hides_only_its_local_resource_copy(self):
        self.assertIn("LocalTransparencyModifier = visible and 0 or 1", VISIBILITY)
        self.assertIn("descendant.Enabled = visible", VISIBILITY)
        self.assertIn('"ResourceState"', CLIENT)
        self.assertIn('"ResourcePicked"', CLIENT)
        self.assertIn('event:FireServer("RequestResourceState")', CLIENT)

    def test_renewable_nodes_have_explicit_personal_cooldowns(self):
        self.assertEqual(WORLD.count('kind = "renewable"'), 14)
        self.assertEqual(WORLD.count("respawnSeconds = 300"), 8)
        self.assertEqual(WORLD.count("respawnSeconds = 600"), 2)
        self.assertEqual(WORLD.count("respawnSeconds = 900"), 4)


    def test_tools_are_persisted_and_restored_after_respawn(self):
        self.assertIn("local toolIds = {Axe = true, Pickaxe = true}", WORLD)
        self.assertIn("tools = {Axe = true, Pickaxe = true}", WORLD)
        self.assertIn("local function createHarvestTool(toolId, level)", WORLD)
        self.assertIn("local function ensurePlayerTools(player, session)", WORLD)
        self.assertIn("session.toolCharacterConnection", WORLD)
        self.assertIn("savedTools.Axe = toolsSnapshot.Axe", WORLD)
        self.assertIn("savedTools.Pickaxe = toolsSnapshot.Pickaxe", WORLD)

    def test_wood_and_stone_nodes_require_the_correct_equipped_tool(self):
        for node_id in ("GroveWood01", "GroveWood02", "DuskStone01", "DuskStone02"):
            self.assertIn(f'key = "{node_id}"', WORLD)
        self.assertIn('requiredTool = "Axe"', WORLD)
        self.assertIn('requiredTool = "Pickaxe"', WORLD)
        self.assertIn('session.equippedTool ~= def.requiredTool', WORLD)
        self.assertIn('equippedTool.Parent ~= player.Character', WORLD)

    def test_resource_hits_are_server_limited_and_tool_upgrade_reduces_hits(self):
        self.assertIn("session.resourceHitCooldowns[def.key]", WORLD)
        self.assertIn("if hitNow - lastHitAt < 0.4 then return end", WORLD)
        self.assertIn("session.resourceHits[def.key] = hits", WORLD)
        self.assertIn('event:FireClient(player, "ResourceHit"', WORLD)
        self.assertIn("hitsRequired - 1", WORLD)
        self.assertIn("session.resourceHits[def.key] = nil", WORLD)

    def test_tool_upgrade_checks_owner_workshop_and_material_cost(self):
        upgrade = WORLD.split('if action == "UpgradeTool" then', 1)[1].split('if action == "EquipTool" then', 1)[0]
        self.assertIn("session.homeIsland", upgrade)
        self.assertIn("session.inventory.Wood", upgrade)
        self.assertIn("session.inventory.Stone", upgrade)
        self.assertIn("session.toolLevels[payload] = 2", upgrade)

    def test_client_shows_hit_progress_and_clears_it_after_collection(self):
        self.assertIn('message == "ResourceHit"', CLIENT)
        self.assertIn('showResourceHitFeedback(payload)', CLIENT)
        self.assertIn('LocalHarvestProgress', CLIENT)
        self.assertIn('clearResourceHitFeedback(payload.nodeId)', CLIENT)

    def test_tools_hud_supports_equipping_and_upgrading_both_tools(self):
        hud = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
        self.assertIn("local function renderTools()", hud)
        self.assertIn('event:FireServer("EquipTool", definition.id)', hud)
        self.assertIn('event:FireServer("UpgradeTool", definition.id)', hud)
        self.assertIn('Tools = renderTools', hud)


    def test_iron_nodes_require_pickaxe_and_award_ore(self):
        for node_id in ("DuskIron01", "DuskIron02"):
            self.assertIn(f'key = "{node_id}"', WORLD)
        self.assertIn('itemId = "IronOre"', WORLD)
        self.assertIn('requiredTool = "Pickaxe", hitsRequired = 5', WORLD)
        self.assertIn('visual = "ore"', WORLD)
        self.assertIn('def.visual == "ore"', WORLD)

    def test_resource_definition_amount_is_actually_awarded(self):
        self.assertIn('local rewardAmount = math.max(1, math.floor(tonumber(def.amount) or 1))', WORLD)
        self.assertIn('+ rewardAmount', WORLD)
        self.assertIn('tostring(rewardAmount)', WORLD)

    def test_smelter_is_persistent_and_only_collects_after_timer(self):
        self.assertIn('local function useHomeSmelter(player, ownerUserId, smelterAnchor)', WORLD)
        self.assertIn('session.smeltingReadyAt = now + duration', WORLD)
        self.assertIn('session.smeltingAmount = 1', WORLD)
        self.assertIn('session.inventory.IronOre -= oreCost', WORLD)
        self.assertIn('session.inventory.Wood -= woodCost', WORLD)
        self.assertIn('session.inventory.IronIngot = (session.inventory.IronIngot or 0) + amount', WORLD)
        self.assertIn('old.smelting = smeltingSnapshot', WORLD)
        self.assertIn('data.smelting', WORLD)
        self.assertIn('smelter.Name = "Smelter"', WORLD)

    def test_smelter_requires_owner_and_materials(self):
        smelter = WORLD.split('local function useHomeSmelter', 1)[1].split('local function repairHomeBridge', 1)[0]
        self.assertIn('if player.UserId ~= ownerUserId then return end', smelter)
        self.assertIn('session.inventory.IronOre or 0) < oreCost', smelter)
        self.assertIn('session.inventory.Wood or 0) < woodCost', smelter)
        self.assertIn('(root.Position - smelterAnchor.Position).Magnitude > 14', smelter)

    def test_remote_handshake_is_registered_before_player_initialization(self):
        self.assertLess(WORLD.index("event.OnServerEvent:Connect"), WORLD.index("Players.PlayerAdded:Connect(init)"))

    def test_concurrent_saves_are_serialized(self):
        self.assertIn("session.saveAgain = true", WORLD)
        self.assertIn("repeat task.wait() until not session.saving", WORLD)


if __name__ == "__main__":
    unittest.main()
