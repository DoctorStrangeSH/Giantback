from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class BridgeRepairContractTests(unittest.TestCase):
    def test_bridge_state_is_part_of_the_default_and_normalized_island_profile(self):
        self.assertIn("homeToGrove = false", WORLD)
        self.assertIn("city.bridges.homeToGrove = rawBridges.homeToGrove == true", WORLD)
        self.assertIn("savedIsland.bridges.homeToGrove = citySnapshot.bridges.homeToGrove == true", WORLD)

    def test_old_profiles_receive_a_small_first_bridge_material_bundle(self):
        self.assertIn('"Wood", "Stone"', WORLD)
        self.assertIn("session.inventory.Wood = 2", WORLD)
        self.assertIn("session.inventory.Stone = 1", WORLD)
        self.assertIn('elseif key == "Wood" and savedAmount == nil then', WORLD)
        self.assertIn('elseif key == "Stone" and savedAmount == nil then', WORLD)

    def test_home_material_nodes_are_per_island_and_owner_only(self):
        self.assertIn('"WoodPile"', BUILD)
        self.assertIn('"StonePile"', BUILD)
        self.assertIn('prompt(woodPile, "Сухие ветви"', WORLD)
        self.assertIn('prompt(stonePile, "Камни у дома"', WORLD)
        self.assertIn("local function gatherHomeMaterial(player, ownerUserId, materialId)", WORLD)
        self.assertIn("if player.UserId ~= ownerUserId then return end", WORLD)
        self.assertIn('gatherHomeMaterial(visitor, ownerUserId, "Wood")', WORLD)
        self.assertIn('gatherHomeMaterial(visitor, ownerUserId, "Stone")', WORLD)

    def test_material_gathering_has_cooldowns_and_persists_them(self):
        self.assertIn("session.homeMaterialCooldowns[materialId] = now + definition.cooldown", WORLD)
        self.assertIn("local homeMaterialCooldownSnapshot = {}", WORLD)
        self.assertIn("old.homeMaterialCooldowns = savedHomeCooldowns", WORLD)
        self.assertIn("data.homeMaterialCooldowns", WORLD)

    def test_home_bridge_starts_as_a_non_collidable_blueprint(self):
        self.assertIn('built=False)', BUILD)
        self.assertIn('prop(piece, "float", "Transparency", 0.62)', BUILD)
        self.assertIn('for key in ("CanCollide", "CanTouch", "CanQuery")', BUILD)
        self.assertIn('prop(piece, "bool", key, "false")', BUILD)
        self.assertIn('add_radial_bridge(bridge_dusk, "MoonBridge", math.pi / 8, 73, 120)', BUILD)

    def test_repair_checks_server_cost_and_activates_only_owners_bridge(self):
        self.assertIn("local function repairHomeBridge(player, ownerUserId)", WORLD)
        self.assertIn("local woodCost, stoneCost = 5, 3", WORLD)
        self.assertIn("if wood < woodCost or stone < stoneCost then", WORLD)
        self.assertIn("session.inventory.Wood = wood - woodCost", WORLD)
        self.assertIn("session.inventory.Stone = stone - stoneCost", WORLD)
        self.assertIn("session.city.bridges.homeToGrove = true", WORLD)
        self.assertIn("applyHomeBridgeState(session.homeSlot, true)", WORLD)
        self.assertIn("syncBridge(player)", WORLD)

    def test_bridge_repair_prompt_is_attached_to_the_personal_gangway(self):
        self.assertIn('local gangway = homeIsland:FindFirstChild("Gangway")', WORLD)
        self.assertIn('prompt(gangway, "Мост в Солнечную рощу", "Восстановить мост"', WORLD)
        self.assertIn('player:SetAttribute("Bridge_HomeToGrove"', WORLD)

    def test_hud_prioritizes_bridge_repair_and_displays_materials(self):
        self.assertIn('if not player:GetAttribute("Bridge_HomeToGrove") then', HUD)
        self.assertIn('Собери материалы для первого моста', HUD)
        self.assertIn('tostring(math.min(wood, 5)) .. "/5', HUD)
        self.assertIn('tostring(math.min(stone, 3)) .. "/3', HUD)
        self.assertIn('Resource_Wood', HUD)
        self.assertIn('Resource_Stone', HUD)
        self.assertIn("woodLabel.Text =", HUD)
        self.assertIn("stoneLabel.Text =", HUD)

    def test_home_material_piles_have_custom_visual_details(self):
        self.assertIn("Gatherable timber", VISUALS)
        self.assertIn("Gatherable stone", VISUALS)
        self.assertIn('item.Name == "WoodPile"', VISUALS)
        self.assertIn('item.Name == "StonePile"', VISUALS)


if __name__ == "__main__":
    unittest.main()
