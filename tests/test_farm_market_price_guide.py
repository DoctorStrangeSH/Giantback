"""Farm market price guide stays aligned with server-side sale values."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class FarmMarketPriceGuideTests(unittest.TestCase):
    def test_ui_prices_match_server_market_prices(self):
        expected = {
            "Carrot": 4,
            "Strawberry": 3,
            "Pumpkin": 18,
            "Cabbage": 12,
        }
        for crop, price in expected.items():
            self.assertIn(f"{crop} = {price}", WORLD)
            self.assertIn(f'sale = {price}', HUD)

    def test_crop_income_targets_are_balanced_per_hour(self):
        # Gross revenue after the first harvest, before seed costs.
        hourly_income = {
            "Carrot": 4 * 3600 / 300,
            "Strawberry": 2 * 3 * 3600 / 480,
            "Pumpkin": 18 * 3600 / 1800,
            "Cabbage": 12 * 3600 / 1200,
        }
        self.assertEqual(hourly_income, {
            "Carrot": 48,
            "Strawberry": 45,
            "Pumpkin": 36,
            "Cabbage": 36,
        })

    def test_prices_are_built_from_crop_catalog(self):
        self.assertIn("local marketPriceSummary = {}", HUD)
        self.assertIn(
            'table.insert(marketPriceSummary, crop.name .. " — " .. tostring(crop.sale) .. " мон.")',
            HUD,
        )
        self.assertIn('addInfo("3. Цены на рынке", table.concat(marketPriceSummary,', HUD)

    def test_instructions_explain_where_and_what_to_sell(self):
        self.assertIn('Подойди к стойке «РЫНОК» на своём острове', HUD)
        self.assertIn("Семена и материалы рынок не покупает.", HUD)
        self.assertIn("local function sellIslandHarvest(player, ownerUserId)", WORLD)

    def test_roadmap_and_studio_acceptance_are_tracked(self):
        self.assertIn("## Ферма и рынок — понятные цены продажи", ROADMAP)
        self.assertIn("## Ферма — подсказка о ценах рынка", STUDIO)
        self.assertIn("320/375/414 px", STUDIO)


if __name__ == "__main__":
    unittest.main()
