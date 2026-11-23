import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class FarmUpgradeContractTests(unittest.TestCase):
    def test_upgrade_prices_and_server_action_are_defined(self):
        self.assertIn("local farmUpgradeCosts = {[2] = 60, [3] = 150}", WORLD)
        self.assertIn("local function upgradeFarm(player)", WORLD)
        self.assertIn('if action == "UpgradeFarm" then', WORLD)
        self.assertIn("upgradeFarm(player)", WORLD)

    def test_upgrade_is_server_validated_and_capped(self):
        self.assertIn("if not session.online then", WORLD)
        self.assertIn("if session.economyBusy then return end", WORLD)
        self.assertIn("if currentLevel >= 3 then", WORLD)
        self.assertIn("if currentCoins < cost then", WORLD)
        self.assertIn("session.city.farm.level = nextLevel", WORLD)

    def test_upgrade_rolls_back_coins_and_level_when_save_fails(self):
        start = WORLD.index("local function upgradeFarm(player)")
        end = WORLD.index("local function useWarehouse", start)
        upgrade = WORLD[start:end]
        self.assertIn("if not save(player) then", upgrade)
        self.assertIn("session.coins = currentCoins", upgrade)
        self.assertIn("session.city.farm.level = currentLevel", upgrade)
        self.assertIn("session.economyBusy = false", upgrade)

    def test_plot_unlocks_are_bound_to_saved_farm_level(self):
        self.assertIn("farm.level >= 2", WORLD)
        self.assertIn("farm.level >= 3", WORLD)
        self.assertIn("local function syncFarm(player)", WORLD)
        self.assertIn('player:SetAttribute("Farm_" .. plotId .. "_Unlocked"', WORLD)

    def test_ui_explains_upgrade_and_sends_server_action(self):
        self.assertIn("local function addFarmUpgrade(farmLevel)", HUD)
        self.assertIn("Откроет две дополнительные грядки", HUD)
        self.assertIn("Откроет последнюю грядку", HUD)
        self.assertIn('event:FireServer("UpgradeFarm")', HUD)
        self.assertIn('"МАКС."', HUD)

    def test_acceptance_is_documented(self):
        self.assertIn("## Улучшения фермы за Coins", ROADMAP)
        self.assertIn("## Улучшения фермы", STUDIO)
        self.assertIn("1→2", STUDIO)
        self.assertIn("2→3", STUDIO)


if __name__ == "__main__":
    unittest.main()
