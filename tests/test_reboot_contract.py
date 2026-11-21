from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
SPEC = (ROOT / "PROJECT_SPEC.md").read_text(encoding="utf-8")


class RebootContractTests(unittest.TestCase):
    def test_product_spec_uses_fixed_archipelago(self):
        self.assertIn("Острова **не перемещаются**", SPEC)
        self.assertIn("строительство мостов", SPEC)
        self.assertIn("Первый вертикальный срез", SPEC)

    def test_server_no_longer_moves_the_home_island(self):
        self.assertNotIn("giant:PivotTo(frame)", WORLD)
        self.assertNotIn("atDusk", WORLD)
        self.assertNotIn("sailing", WORLD)
        self.assertNotIn('SetAttribute("Dock"', WORLD)

    def test_client_no_longer_teaches_sailing_or_dock_switching(self):
        self.assertNotIn('GetAttribute("Dock")', CLIENT)
        self.assertNotIn("Штурвал", CLIENT)
        self.assertNotIn("Колокольчик", CLIENT)

    def test_static_bridges_are_generated_in_the_place(self):
        self.assertIn('obj(w, "Model", "BridgeToGrove")', BUILD)
        self.assertIn('obj(w, "Model", "BridgeToDusk")', BUILD)
        self.assertIn('"BridgeDeck"', BUILD)
        self.assertIn('"BridgeRail"', BUILD)
        self.assertIn('"BridgePost"', BUILD)

    def test_bridge_visuals_use_consistent_materials_and_lighting(self):
        self.assertIn('item.Name == "BridgeDeck"', VISUALS)
        self.assertIn("Enum.Material.WoodPlanks", VISUALS)
        self.assertIn('item.Name == "BridgeLamp"', VISUALS)
        self.assertIn("addLight(item, palette.gold", VISUALS)

    def test_unified_hud_has_one_clear_navigation(self):
        for label in ("ОСТРОВ", "ФЕРМА", "ПИТОМЦЫ", "КАРТА"):
            self.assertIn(label, HUD)
        self.assertIn('gui.Name = "GiantbackHUD"', HUD)
        self.assertIn("local panel = Instance.new(\\"Frame\\")", HUD)

    def test_farm_screen_explains_planting_and_harvesting(self):
        self.assertIn("Подойди к свободной грядке", HUD)
        self.assertIn("Собрать", HUD)
        self.assertIn("Farm_Plot", HUD)
        self.assertIn("Resource_CarrotSeed", HUD)
        self.assertIn("Resource_Carrot", HUD)

    def test_pet_screen_explains_roles_and_equipping(self):
        self.assertIn("Разведчик", HUD)
        self.assertIn("Хранитель света", HUD)
        self.assertIn("ПОЗВАТЬ", HUD)
        self.assertIn("event:FireServer(pet.id)", HUD)

    def test_legacy_hud_is_disabled_and_new_hud_is_embedded(self):
        self.assertIn("gui.Enabled = false", CLIENT)
        self.assertIn('root / "HUD.client.luau"', BUILD)

    def test_map_panel_uses_fixed_bridges(self):
        self.assertIn('workspace:FindFirstChild("BridgeToGrove")', HUD)
        self.assertIn('workspace:FindFirstChild("BridgeToDusk")', HUD)
        self.assertIn("Острова остаются на своих местах", HUD)


if __name__ == "__main__":
    unittest.main()
