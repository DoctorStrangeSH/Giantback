from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class HomeHouseProgressionContractTests(unittest.TestCase):
    def test_home_level_is_part_of_city_defaults_and_normalization(self):
        self.assertIn("homeLevel = 1", WORLD)
        self.assertIn('city.homeLevel = math.clamp(math.floor(tonumber(raw.homeLevel) or 1), 1, 3)', WORLD)

    def test_home_level_is_persisted_in_island_profile(self):
        self.assertIn('savedIsland.homeLevel = citySnapshot.homeLevel', WORLD)
        self.assertIn('player:SetAttribute("Home_Level", session.city.homeLevel or 1)', WORLD)

    def test_three_distinct_visual_tiers_are_built_from_the_owners_island(self):
        self.assertIn("local function applyHomeHouseVisuals(homeIsland, houseLevel)", WORLD)
        self.assertIn('visuals:SetAttribute("HouseLevel", level)', WORLD)
        self.assertIn('add("BalconyFloor"', WORLD)
        self.assertIn('add("SideExtension"', WORLD)
        self.assertIn('add("ManorUpper"', WORLD)
        self.assertIn('add("TowerRoof"', WORLD)
        self.assertIn("if item:IsA(\"BasePart\") and solidParts[item.Name] then", WORLD)
        self.assertIn("item.CanCollide = true", WORLD)

    def test_upgrade_is_owner_only_and_requires_persistable_profile(self):
        self.assertIn('if player.UserId ~= ownerUserId then return tip(player, "Этот дом принадлежит другому игроку.") end', WORLD)
        self.assertIn("if not session.online then", WORLD)
        self.assertIn("session.economyBusy = true", WORLD)
        self.assertIn('prompt(houseUpgradeAnchor, "Твой дом", "Улучшить дом"', WORLD)

    def test_upgrade_costs_are_server_owned_and_levels_are_capped(self):
        self.assertIn('[2] = {Wood = 20, Stone = 12}', WORLD)
        self.assertIn('[3] = {Wood = 45, Stone = 30}', WORLD)
        self.assertIn("if currentLevel >= 3 then", WORLD)

    def test_failed_save_restores_resources_level_and_visuals(self):
        self.assertIn("if not save(player) then", WORLD)
        self.assertIn("session.city.homeLevel = currentLevel", WORLD)
        self.assertIn("applyHomeHouseVisuals(session.homeIsland, currentLevel)", WORLD)
        self.assertIn("Улучшение отменено.", WORLD)

    def test_hud_explains_current_home_level_and_next_upgrade(self):
        self.assertIn('player:GetAttribute("Home_Level")', HUD)
        self.assertIn('addInfo("Дом • уровень "', HUD)
        self.assertIn('Подойди к дому и нажми «Улучшить дом».', HUD)


if __name__ == "__main__":
    unittest.main()
