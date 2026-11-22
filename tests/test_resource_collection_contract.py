from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


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
        self.assertIn("old.schemaVersion = 7", WORLD)
        self.assertIn("data.resourceCooldowns", WORLD)
        self.assertIn("data.collectedNodes", WORLD)
        self.assertIn("data.resourceCooldowns", WORLD)
        self.assertIn("data.collectedNodes", WORLD)

    def test_server_checks_prompt_distance(self):
        self.assertIn("p.MaxActivationDistance + 1", WORLD)
        self.assertIn("(root.Position-part.Position).Magnitude", WORLD)

    def test_client_hides_only_its_local_resource_copy(self):
        self.assertIn("LocalTransparencyModifier = visible and 0 or 1", CLIENT)
        self.assertIn("descendant.Enabled = visible", CLIENT)
        self.assertIn('"ResourceState"', CLIENT)
        self.assertIn('"ResourcePicked"', CLIENT)
        self.assertIn('event:FireServer("RequestResourceState")', CLIENT)

    def test_renewable_nodes_have_explicit_personal_cooldowns(self):
        self.assertEqual(WORLD.count('kind = "renewable"'), 8)
        self.assertEqual(WORLD.count("respawnSeconds = 300"), 8)

    def test_tools_are_persisted_and_equipped_server_side(self):
        self.assertIn('local toolIds = {Axe = true, Pickaxe = true}', WORLD)
        self.assertIn('tools = {Axe = true, Pickaxe = true}', WORLD)
        self.assertIn('old.tools = savedTools', WORLD)
        self.assertIn('action == "EquipTool"', WORLD)
        self.assertIn('session.equippedTool = payload', WORLD)
        self.assertIn('player:SetAttribute("Tool_Equipped"', WORLD)
        self.assertIn('Instance.new("Tool")', WORLD)
        self.assertIn('Instance.new("WeldConstraint")', WORLD)
        self.assertIn('humanoid:EquipTool(equipped)', WORLD)
        self.assertIn('session.toolCharacterConnection', WORLD)
        self.assertLess(WORLD.index('player:SetAttribute("Ready", true)'), WORLD.index('syncTools(player)', WORLD.index('player:SetAttribute("Ready", true)')))

    def test_resource_nodes_require_the_matching_equipped_tool(self):
        self.assertEqual(WORLD.count('requiredTool = "Axe"'), 2)
        self.assertEqual(WORLD.count('requiredTool = "Pickaxe"'), 2)
        self.assertIn('session.equippedTool ~= def.requiredTool', WORLD)
        self.assertIn('event:FireServer("EquipTool", tool.id)', CLIENT)

    def test_wood_and_stone_require_multiple_server_validated_hits(self):
        self.assertEqual(WORLD.count('hitsRequired = 3'), 2)
        self.assertEqual(WORLD.count('hitsRequired = 4'), 2)
        self.assertIn('session.resourceHits[def.key] = hits', WORLD)
        self.assertIn('hits < hitsRequired', WORLD)
        self.assertIn('"ResourceHit"', WORLD)
        self.assertIn('"ResourceHit"', CLIENT)
        self.assertIn('node:PivotTo(origin * CFrame.new(offset))', CLIENT)
        self.assertIn('Instance.new("BillboardGui")', CLIENT)
        self.assertIn('"LocalHarvestProgress"', CLIENT)
        self.assertIn('"Добыча "', CLIENT)
        self.assertIn('Instance.new("ParticleEmitter")', CLIENT)
        self.assertIn('emitter:Emit(7)', CLIENT)
        self.assertIn('clearResourceHitFeedback(payload.nodeId)', CLIENT)
        self.assertIn('local function playHarvestToolSwing(nodeId)', CLIENT)
        self.assertIn('TweenService:Create(tool', CLIENT)
        self.assertIn('toolSwingGeneration', CLIENT)
        self.assertIn('ColorSequence.new(Color3.fromRGB(183, 133, 83)', CLIENT)
        self.assertIn('ColorSequence.new(Color3.fromRGB(151, 164, 169)', CLIENT)
        self.assertIn('local function ensureHarvestDamageOverlay', CLIENT)
        self.assertIn('Instance.new("SurfaceGui")', CLIENT)
        self.assertIn('"LocalHarvestCracks"', CLIENT)
        self.assertIn('local function playResourceBreakFeedback', CLIENT)
        self.assertIn('emitter:Emit(20)', CLIENT)
        self.assertIn('playResourceBreakFeedback(payload.nodeId)', CLIENT)
        self.assertIn('local function playResourceBreakAnimation(nodeId)', CLIENT)
        self.assertIn('local function restoreResourceGrowth(model)', CLIENT)
        self.assertIn('local function playResourceRegrowthBurst(model)', CLIENT)
        self.assertIn('"LocalResourceRegrowth"', CLIENT)
        self.assertIn('emitter:Emit(12)', CLIENT)
        self.assertIn('Size = geometry.size * 0.12', CLIENT)
        self.assertIn('restoreResourceGrowth(model)', CLIENT)
        self.assertIn('task.delay(0.3, function()', CLIENT)
        self.assertIn('if payload.itemId ~= nil and payload.amount ~= nil then', CLIENT)
        self.assertIn('Cooldown and already-collected responses only synchronize visibility', CLIENT)
        self.assertIn('itemId = def.itemId', WORLD)
        self.assertIn('amount = amount', WORLD)
        self.assertIn('local function playResourceRewardPickup(payload)', CLIENT)
        self.assertIn('"LocalResourceReward"', CLIENT)
        self.assertIn('pickup:Destroy()', CLIENT)
        self.assertIn('itemId ~= "Wood" and itemId ~= "Stone"', CLIENT)
    def test_world_resource_yields_are_server_defined_and_positive(self):
        self.assertIn('amount = 2,', WORLD)
        self.assertIn('def.amount) or 1', WORLD)
        self.assertIn('math.clamp(math.floor(tonumber(def.amount) or 1), 1, 100)', WORLD)
        self.assertIn('def.verb or "Собрать"', WORLD)
        self.assertIn('tostring(amount)', WORLD)

    def test_world_has_personal_wood_and_stone_nodes_in_adventure_biomes(self):
        self.assertIn('GroveWood01 = true', WORLD)
        self.assertIn('GroveWood02 = true', WORLD)
        self.assertIn('DuskStone01 = true', WORLD)
        self.assertIn('DuskStone02 = true', WORLD)
        self.assertIn('visual = "tree"', WORLD)
        self.assertIn('visual = "rock"', WORLD)
        self.assertIn('itemId = "Wood"', WORLD)
        self.assertIn('itemId = "Stone"', WORLD)

    def test_remote_handshake_is_registered_before_player_initialization(self):
        self.assertLess(WORLD.index("event.OnServerEvent:Connect"), WORLD.index("Players.PlayerAdded:Connect(init)"))

    def test_concurrent_saves_are_serialized(self):
        self.assertIn("session.saveAgain = true", WORLD)
        self.assertIn("repeat task.wait() until not session.saving", WORLD)


if __name__ == "__main__":
    unittest.main()
