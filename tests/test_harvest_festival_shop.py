"""Contract tests for the persistent Harvest Festival token shop."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class HarvestFestivalShopContractTests(unittest.TestCase):
    def test_shop_currency_is_derived_without_spending_event_progress(self):
        self.assertIn("local earnedTokens = math.clamp(math.floor(session.seasonalEvent.points / 5), 0, FESTIVAL_TOKEN_CAP)", WORLD)
        self.assertIn("shopSpent = sameEvent and math.clamp", WORLD)
        self.assertIn("availableTokens = math.max(0, earnedTokens - eventData.shopSpent)", WORLD)
        self.assertIn("eventData.points", WORLD)
        self.assertIn("eventData.shopSpent += offer.cost", WORLD)
        self.assertIn("FESTIVAL_TOKEN_CAP = 20", WORLD)

    def test_four_offers_have_bounded_event_limits(self):
        offers = WORLD[WORLD.index("local FESTIVAL_SHOP_OFFERS"):WORLD.index("local FESTIVAL_SHOP_ORDER")]
        for fragment in (
            'HarvestEgg = {itemId = "HarvestEgg", amount = 1, cost = 10, limit = 1',
            'StarShard = {itemId = "StarShard", amount = 1, cost = 4, limit = 2',
            'MoonPetal = {itemId = "MoonPetal", amount = 3, cost = 2, limit = 3',
            'PumpkinSeed = {itemId = "PumpkinSeed", amount = 5, cost = 1, limit = 3',
        ):
            self.assertIn(fragment, offers)

    def test_purchase_requires_live_event_and_online_profile(self):
        start = WORLD.index("local function buyFestivalShopItem")
        end = WORLD.index("\nsave = function(player)", start)
        purchase = WORLD[start:end]
        self.assertIn("if not session.online then", purchase)
        self.assertIn("if not window.active then", purchase)
        self.assertIn("if session.economyBusy then", purchase)
        self.assertIn("if purchased >= offer.limit then", purchase)
        self.assertIn("if availableTokens < offer.cost then", purchase)
        self.assertIn("if currentAmount + offer.amount > maxStack then", purchase)
        self.assertIn("if allOwned then", purchase)

    def test_purchase_is_atomic_and_rolls_back_on_save_failure(self):
        start = WORLD.index("local function buyFestivalShopItem")
        end = WORLD.index("\nsave = function(player)", start)
        purchase = WORLD[start:end]
        self.assertIn("if not save(player) then", purchase)
        self.assertIn("eventData.shopSpent = previousSpent", purchase)
        self.assertIn("eventData.shopPurchases[offerId] = previousPurchases", purchase)
        self.assertIn("session.inventory[offer.itemId] = currentAmount", purchase)
        self.assertIn("syncInventory(player)", purchase)
        self.assertIn("syncSeasonalEvent(player)", purchase)

    def test_event_purchase_history_is_normalized_and_synced(self):
        self.assertIn("shopPurchases = purchases", WORLD)
        self.assertIn("shopSpent = sameEvent", WORLD)
        self.assertIn('player:SetAttribute("SeasonalEvent_ShopTokens"', WORLD)
        self.assertIn('player:SetAttribute("SeasonalEvent_ShopPurchase_" .. offerId', WORLD)
        self.assertIn("old.seasonalEvent = seasonalEventSnapshot", WORLD)

    def test_server_action_and_client_shop_are_connected(self):
        self.assertIn('if action == "BuyFestivalShopItem" then', WORLD)
        self.assertIn('buyFestivalShopItem(player, payload)', WORLD)
        self.assertIn('event:FireServer("BuyFestivalShopItem", offer.id)', HUD)
        self.assertIn('local shopTokens = math.max(0', HUD)
        self.assertIn('SeasonalEvent_ShopPurchase_', HUD)
        self.assertIn('local festivalShopOffers = {', HUD)
        self.assertIn("ЛАВКА ФЕСТИВАЛЯ", HUD)
        self.assertIn("ЛИСТОЧКИ", HUD)

    def test_roadmap_and_studio_acceptance_cover_shop(self):
        self.assertIn("Лавка фестиваля: листочки начисляются", ROADMAP)
        self.assertIn("## Лавка Фестиваля урожая", STUDIO)
        self.assertIn("Смоделировать отказ DataStore", STUDIO)
        self.assertIn("320/375/414/768/1920 px", STUDIO)


if __name__ == "__main__":
    unittest.main()
