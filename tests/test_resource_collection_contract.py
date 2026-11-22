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

    def test_remote_handshake_is_registered_before_player_initialization(self):
        self.assertLess(WORLD.index("event.OnServerEvent:Connect"), WORLD.index("Players.PlayerAdded:Connect(init)"))

    def test_concurrent_saves_are_serialized(self):
        self.assertIn("session.saveAgain = true", WORLD)
        self.assertIn("repeat task.wait() until not session.saving", WORLD)


if __name__ == "__main__":
    unittest.main()
