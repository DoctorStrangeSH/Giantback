import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class SeedMarketShopContractTests(unittest.TestCase):
    def test_server_catalog_has_fixed_seed_bundles(self):
        self.assertIn("local seedShopOffers = {", WORLD)
        self.assertIn("Carrot = {amount = 3, cost = 12}", WORLD)
        self.assertIn("Strawberry = {amount = 3, cost = 21}", WORLD)
        self.assertIn("Pumpkin = {amount = 2, cost = 20}", WORLD)
        self.assertIn("Cabbage = {amount = 2, cost = 16}", WORLD)

    def test_purchase_is_server_validated_and_persisted(self):
        self.assertIn("local function buyFarmSeeds(player, cropId)", WORLD)
        self.assertIn("if not session.online then", WORLD)
        self.assertIn("if session.economyBusy then return end", WORLD)
        self.assertIn("local MAX_SEED_STACK = 999", WORLD)
        self.assertIn("session.coins = currentCoins - offer.cost", WORLD)
        self.assertIn("session.inventory[seedItemId] = currentSeeds + offer.amount", WORLD)
        self.assertIn("if not save(player) then", WORLD)
        self.assertIn('session.coins = currentCoins', WORLD)
        self.assertIn('session.inventory[seedItemId] = currentSeeds', WORLD)
        self.assertIn('if action == "BuySeeds" then', WORLD)
        self.assertIn("buyFarmSeeds(player, payload)", WORLD)

    def test_farm_ui_displays_price_and_purchase_action(self):
        self.assertIn('local seedShopOffers = {', HUD)
        self.assertIn('"КУПИТЬ ×"', HUD)
        self.assertIn('event:FireServer("BuySeeds", crop.id)', HUD)
        self.assertIn("local coins = tonumber(player:GetAttribute(\"Coins\")) or 0", HUD)

    def test_studio_acceptance_is_documented(self):
        self.assertIn("## Магазин семян", ROADMAP)
        self.assertIn("## Магазин семян", STUDIO)
        self.assertIn("лимита 999 семян", STUDIO)


if __name__ == "__main__":
    unittest.main()
