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
        self.assertIn("old.schemaVersion = 8", WORLD)
        self.assertIn("data.resourceCooldowns", WORLD)
        self.assertIn("data.collectedNodes", WORLD)

    def test_tool_level_migration_defaults_old_profiles_and_clamps_saved_values(self):
        self.assertIn('local savedLevels = type(savedTools.levels) == "table" and savedTools.levels or {}', WORLD)
        self.assertIn('Axe = math.clamp(math.floor(tonumber(savedLevels.Axe) or 1), 1, 2)', WORLD)
        self.assertIn('Pickaxe = math.clamp(math.floor(tonumber(savedLevels.Pickaxe) or 1), 1, 2)', WORLD)
        self.assertIn('savedTools.levels = toolsSnapshot.levels', WORLD)
        self.assertIn('old.schemaVersion = 8', WORLD)

    def test_workshop_upgrade_is_server_validated_and_charged_once(self):
        upgrade = WORLD.split('if action == "UpgradeTool" then', 1)[1].split('if action == "EquipTool" then', 1)[0]
        self.assertIn('session.tools[payload] ~= true', upgrade)
        self.assertIn('session.toolLevels[payload] >= 2', upgrade)
        self.assertIn('station:FindFirstChild("PromptAnchor")', upgrade)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 14', upgrade)
        self.assertIn('(session.inventory.Wood or 0) < woodCost', upgrade)
        self.assertIn('(session.inventory.Stone or 0) < stoneCost', upgrade)
        self.assertIn('session.inventory.Wood -= woodCost', upgrade)
        self.assertIn('session.inventory.Stone -= stoneCost', upgrade)
        self.assertIn('session.toolLevels[payload] = 2', upgrade)

    def test_selected_tool_is_actually_equipped_and_restored_after_respawn(self):
        sync_tools = WORLD.split("local function syncTools(player)", 1)[1].split("local function syncBridge(player)", 1)[0]
        self.assertIn("ensurePlayerTools(player, session)", sync_tools)
        self.assertIn("local selectedTool = toolIds[session.equippedTool]", sync_tools)
        self.assertIn('character:FindFirstChildOfClass("Humanoid")', sync_tools)
        self.assertIn('player:FindFirstChildOfClass("Backpack")', sync_tools)
        self.assertIn("humanoid:EquipTool(selectedTool)", sync_tools)
        self.assertIn("player.CharacterAdded:Connect(function()", WORLD)
        self.assertIn("syncTools(player)", WORLD)

    def test_equip_action_updates_selected_tool_before_sync(self):
        equip = WORLD.split('if action == "EquipTool" then', 1)[1].split('if action == "RequestResourceState" then', 1)[0]
        self.assertIn("session.equippedTool = payload", equip)
        self.assertIn("syncTools(player)", equip)
        self.assertIn("if session.tools[payload] ~= true then", equip)

    def test_server_checks_prompt_distance(self):
        self.assertIn("p.MaxActivationDistance + 1", WORLD)
        self.assertIn("(root.Position-part.Position).Magnitude", WORLD)

    def test_harvest_swing_animates_r6_and_r15_right_arm_locally(self):
        swing = CLIENT.split("local function playHarvestCharacterSwing(character, nodeId, generation)", 1)[1].split("local function playHarvestToolSwing(nodeId)", 1)[0]
        self.assertIn('character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")', swing)
        self.assertIn('descendant.Name == "RightShoulder" or descendant.Name == "Right Shoulder"', swing)
        self.assertIn('descendant.Name == "RightElbow"', swing)
        self.assertIn("RunService:BindToRenderStep", swing)
        self.assertIn("Enum.RenderPriority.Last.Value", swing)
        self.assertIn("shoulder.Transform = shoulder.Transform * pose", swing)
        self.assertIn("elbow.Transform = elbow.Transform * CFrame.Angles", swing)
        self.assertIn("RunService:UnbindFromRenderStep(bindingName)", swing)
        tool_swing = CLIENT.split("local function playHarvestToolSwing(nodeId)", 1)[1].split("local function ensureHarvestDamageOverlay", 1)[0]
        self.assertIn("playHarvestCharacterSwing(character, nodeId, generation)", tool_swing)

    def test_harvest_hit_spawns_local_material_chips_without_server_physics(self):
        chips = CLIENT.split("local function spawnHarvestChips(anchor, nodeId)", 1)[1].split("local function showResourceHitFeedback(payload)", 1)[0]
        self.assertIn('chip.Name = "LocalHarvestChip"', chips)
        self.assertIn("Enum.Material.Wood", chips)
        self.assertIn("Enum.Material.Slate", chips)
        self.assertIn("chip.Anchored = true", chips)
        self.assertIn("chip.CanCollide = false", chips)
        self.assertIn("chip.Parent = workspace", chips)
        self.assertIn("Debris:AddItem(chip, 0.5)", chips)
        feedback = CLIENT.split("local function showResourceHitFeedback(payload)", 1)[1].split("local function clearResourceHitFeedback(nodeId)", 1)[0]
        self.assertIn("spawnHarvestChips(anchor, nodeId)", feedback)

    def test_client_hides_only_its_local_resource_copy(self):
        self.assertIn("LocalTransparencyModifier = visible and 0 or 1", CLIENT)
        self.assertIn("descendant.Enabled = visible", CLIENT)
        self.assertIn('"ResourceState"', CLIENT)
        self.assertIn('"ResourcePicked"', CLIENT)
        self.assertIn('event:FireServer("RequestResourceState")', CLIENT)

    def test_renewable_nodes_have_explicit_personal_cooldowns(self):
        self.assertEqual(WORLD.count('kind = "renewable"'), 8)
        self.assertEqual(WORLD.count("respawnSeconds = 300"), 8)

    def test_remote_handshake_is_registered_before_player_initialization(self):
        self.assertLess(WORLD.index("event.OnServerEvent:Connect"), WORLD.index("Players.PlayerAdded:Connect(init)"))

    def test_concurrent_saves_are_serialized(self):
        self.assertIn("session.saveAgain = true", WORLD)
        self.assertIn("repeat task.wait() until not session.saving", WORLD)


if __name__ == "__main__":
    unittest.main()
