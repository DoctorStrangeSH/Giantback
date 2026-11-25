"""Persistent companion gift discoveries are recorded in the expedition journal."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CompanionGiftJournalTests(unittest.TestCase):
    def test_gift_codex_uses_only_the_server_reward_catalog(self):
        for item in (
            "SunPetal", "Wood", "CarrotSeed", "StrawberrySeed", "MoonSeed",
            "MoonPetal", "StarShard", "Stone", "CrystalShard", "CrystalSigil",
            "PrismSeed", "VoidGeode",
        ):
            self.assertIn('"' + item + '"', WORLD)
            self.assertIn('id = "' + item + '"', HUD)

    def test_discovery_is_saved_with_biome_and_companion_and_loaded_safely(self):
        self.assertIn("companionGiftDiscoveries = {}", WORLD)
        self.assertIn("local savedGiftDiscoveries = type(data.companionGiftDiscoveries)", WORLD)
        self.assertIn("session.companionGiftDiscoveries[itemId] = {", WORLD)
        self.assertIn("savedGiftDiscoveries[itemId] = discovery", WORLD)
        self.assertIn("player:SetAttribute("CompanionGiftFound_" .. itemId, true)", WORLD)
        self.assertIn("player:SetAttribute("CompanionGiftBiome_" .. itemId, discovery.biome)", WORLD)
        self.assertIn("player:SetAttribute("CompanionGiftPet_" .. itemId, discovery.companionId)", WORLD)

    def test_first_discovery_is_part_of_same_save_and_rolls_back_on_failure(self):
        self.assertIn("local previousDiscovery = session.companionGiftDiscoveries[reward.itemId]", WORLD)
        self.assertIn("local isFirstDiscovery = previousDiscovery == nil", WORLD)
        self.assertIn("session.companionGiftDiscoveries[reward.itemId] = {biome = biomeName, companionId = companionId}", WORLD)
        self.assertIn("session.companionGiftDiscoveries[reward.itemId] = previousDiscovery", WORLD)
        self.assertIn('isFirstDiscovery and " • Новая запись в дневнике!"', WORLD)
        self.assertLess(WORLD.index("local saved = save(player)", WORLD.index("local function searchCompanionGift")),
                        WORLD.index('player:SetAttribute("CompanionGiftFound_"', WORLD.index("local function searchCompanionGift")))

    def test_journal_shows_collection_progress_and_biome_groups(self):
        for marker in (
            'addInfo("КОЛЛЕКЦИЯ НАХОДОК ПИТОМЦЕВ"',
            'local giftEntries = {',
            'tostring(foundGiftCount) .. "/" .. tostring(#giftEntries)',
            'id = "Grove", title = "СОЛНЕЧНАЯ РОЩА"',
            'id = "Dusk", title = "СУМЕРЕЧНАЯ ДОЛИНА"',
            'id = "CrystalGrotto", title = "КРИСТАЛЬНЫЙ ГРОТ"',
            'player:GetAttribute("CompanionGiftFound_" .. gift.id)',
            'player:GetAttribute("CompanionGiftPet_" .. gift.id)',
            'player:GetAttribute("CompanionGiftBiome_" .. gift.id)',
        ):
            self.assertIn(marker, HUD)

    def test_pictograms_have_dedicated_art_for_all_new_collection_symbols(self):
        for marker in (
            'elseif kind == "seed" then',
            'elseif kind == "moon" then',
            'elseif kind == "star" then',
            'elseif kind == "chest" then',
            'elseif kind == "lock" then',
        ):
            self.assertIn(marker, HUD)


if __name__ == "__main__":
    unittest.main()
