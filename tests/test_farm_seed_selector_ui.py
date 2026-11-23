from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class FarmSeedSelectorUiTests(unittest.TestCase):
    def test_all_four_crops_are_visible_in_seed_catalog(self):
        for crop_id in ("Carrot", "Strawberry", "Pumpkin", "Cabbage"):
            self.assertIn('id = "' + crop_id + '"', HUD)
        for name in ("Морковь", "Клубника", "Тыква", "Капуста"):
            self.assertIn(name, HUD)

    def test_seed_catalog_shows_inventory_and_growth_time(self):
        self.assertIn('player:GetAttribute("Resource_" .. crop.seed)', HUD)
        self.assertIn('crop.grow .. "  •  семян: "', HUD)
        self.assertIn("повторный сбор 8 мин", HUD)

    def test_select_button_sends_server_validated_action(self):
        self.assertIn('event:FireServer("SelectCrop", crop.id)', HUD)
        self.assertIn('if action == "SelectCrop" then', WORLD)
        self.assertIn("session.selectedCropId = cropId", WORLD)

    def test_selected_crop_is_reflected_in_farm_plot_cards(self):
        self.assertIn('player:GetAttribute("Farm_SelectedCrop")', HUD)
        self.assertIn('stateText = "Свободна — выбрано: "', HUD)
        self.assertIn('choose.TextSize = 10', HUD)

    def test_farm_summary_lists_all_harvested_crops(self):
        self.assertIn("local harvestSummary = {}", HUD)
        self.assertIn('player:GetAttribute("Resource_" .. crop.id)', HUD)
        self.assertIn("table.concat(harvestSummary, \", \")", HUD)

    def test_farm_catalog_renders_before_plot_status(self):
        self.assertIn("for _, crop in cropCatalog do addSeedChoice(crop, selectedCrop) end", HUD)
        self.assertIn('addPlot(string.format("Plot%02d", index), index)', HUD)


if __name__ == "__main__":
    unittest.main()
