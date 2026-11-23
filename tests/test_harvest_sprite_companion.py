"""Contract tests for the one-time Harvest Festival companion reward."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules" / "CompanionAnimation.luau").read_text(encoding="utf-8")
APPEARANCE = (ROOT / "modules" / "CompanionAppearance.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class HarvestSpriteCompanionContractTests(unittest.TestCase):
    def test_companion_is_in_every_server_owned_profile_registry(self):
        self.assertIn('local pets = {Fox = "Лисёнок-корешок", Moth = "Лунная моль", CrystalWisp = "Кристальный светляк", HarvestSprite = "Тыквик", BrambleBun = "Колючка", MossTurtle = "Мохопанцирь", Glowcap = "Светошляп", Dewdrop = "Росинка", Starling = "Звёздокрыл"}', WORLD)
        self.assertIn('"HarvestSprite"', WORLD[WORLD.index("local progress ="):WORLD.index("local inventoryKeys")])
        self.assertIn('local COMPANION_IDS = {"Fox", "Moth", "CrystalWisp", "HarvestSprite", "BrambleBun", "MossTurtle", "Glowcap", "Dewdrop", "Starling"}', WORLD)
        self.assertIn('HarvestSprite = "Радость"', WORLD)
        self.assertIn('old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 14)', WORLD)

    def test_claim_is_server_gated_by_active_event_and_100_points(self):
        start = WORLD.index("local function claimHarvestSprite")
        end = WORLD.index("\nsave = function(player)", start)
        claim = WORLD[start:end]
        self.assertIn("if not window.active then", claim)
        self.assertIn("session.seasonalEvent.points < 100", claim)
        self.assertIn("session.seasonalEvent.harvestSpriteClaimed", claim)
        self.assertIn('player:SetAttribute("HarvestSprite", true)', claim)
        self.assertIn('player:SetAttribute("Companion", "HarvestSprite")', claim)
        self.assertIn('if action == "ClaimHarvestSprite" then', WORLD)
        self.assertIn("claimHarvestSprite(player)", WORLD)

    def test_reward_persists_and_rolls_back_all_owned_state_on_save_failure(self):
        start = WORLD.index("local function claimHarvestSprite")
        end = WORLD.index("\nsave = function(player)", start)
        claim = WORLD[start:end]
        self.assertIn("if not save(player) then", claim)
        self.assertIn("session.seasonalEvent.harvestSpriteClaimed = false", claim)
        self.assertIn('player:SetAttribute("HarvestSprite", false)', claim)
        self.assertIn('player:SetAttribute("Companion", previousCompanion or "")', claim)
        self.assertIn("session.companionMutations.HarvestSprite = previousMutation", claim)
        self.assertIn("syncCompanionProgress(player)", claim)
        self.assertIn("session.economyBusy = false", claim)

    def test_seasonal_claim_state_is_scoped_to_event_year(self):
        normalize = WORLD[WORLD.index("local function normalizeSeasonalEvent"):WORLD.index("local function getSeasonalEventAvailableReward")]
        self.assertIn("sameEvent and saved.harvestSpriteClaimed == true or false", normalize)
        self.assertIn('player:SetAttribute("SeasonalEvent_HarvestSpriteClaimed"', WORLD)
        self.assertIn('player:GetAttribute("SeasonalEvent_HarvestSpriteClaimed")', HUD)

    def test_original_companion_model_and_animation_are_available(self):
        self.assertIn('harvestSprite.Name = "HarvestSprite"', VISUALS)
        self.assertIn('harvestSprite:SetAttribute("GiantbackSeasonalCompanion", true)', VISUALS)
        for part in ('"Body"', '"Leaf"', '"Lantern core"', '"Vine tail"'):
            self.assertIn(part, VISUALS)
        self.assertIn('elseif state.id == "HarvestSprite" then', ANIMATION)
        self.assertIn('part.Name == "Lantern core"', ANIMATION)
        self.assertIn("AutumnHeart", APPEARANCE)

    def test_album_and_hud_expose_the_new_companion(self):
        self.assertIn('HarvestSprite = "Тыквик"', ALBUM)
        self.assertIn('HarvestSprite = 0', ALBUM)
        self.assertIn('companionId == "HarvestSprite"', ALBUM)
        self.assertIn('{id = "HarvestSprite", name = "Тыквик"', HUD)
        self.assertIn('button(body, "ClaimHarvestSprite"', HUD)
        self.assertIn('event:FireServer("ClaimHarvestSprite")', HUD)

    def test_studio_acceptance_and_roadmap_are_explicit(self):
        self.assertIn("## Фестиваль урожая — питомец Тыквик", STUDIO)
        self.assertIn("сезонного питомца Тыквика", ROADMAP)
        self.assertIn("Магазин фестивальных предметов", ROADMAP)


if __name__ == "__main__":
    unittest.main()
