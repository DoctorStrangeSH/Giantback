"""Contract tests for the one-time Harvest Festival egg and its five companions."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules" / "CompanionAnimation.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class HarvestFestivalEggContractTests(unittest.TestCase):
    def test_five_hatchlings_are_registered_and_have_templates(self):
        ids = ("BrambleBun", "MossTurtle", "Glowcap", "Dewdrop", "Starling")
        for companion_id in ids:
            self.assertIn(companion_id, WORLD)
            self.assertIn(f'beginFestivalHatchling("{companion_id}"', VISUALS)
            self.assertIn(f'{companion_id} =', ALBUM)
            self.assertIn(f'id = "{companion_id}"', HUD)
        self.assertIn('local COMPANION_IDS = {"Fox", "Moth", "CrystalWisp", "HarvestSprite", "BrambleBun", "MossTurtle", "Glowcap", "Dewdrop", "Starling"}', WORLD)

    def test_egg_claim_is_one_time_and_requires_fifty_event_points(self):
        start = WORLD.index("local function claimFestivalEgg")
        end = WORLD.index("local function hatchFestivalEgg", start)
        claim = WORLD[start:end]
        self.assertIn("if not window.active then", claim)
        self.assertIn("session.seasonalEvent.points < 50", claim)
        self.assertIn("session.seasonalEvent.festivalEggClaimed", claim)
        self.assertIn('session.inventory.HarvestEgg = (session.inventory.HarvestEgg or 0) + 1', claim)
        self.assertIn("if not save(player) then", claim)
        self.assertIn("syncSeasonalEvent(player)", claim)

    def test_hatching_filters_owned_species_and_rolls_documented_weights(self):
        start = WORLD.index("local FESTIVAL_EGG_PETS")
        end = WORLD.index("local function claimFestivalEgg", start)
        definitions = WORLD[start:end]
        for fragment in (
            '{id = "BrambleBun", weight = 40',
            '{id = "MossTurtle", weight = 32',
            '{id = "Glowcap", weight = 18',
            '{id = "Dewdrop", weight = 8',
            '{id = "Starling", weight = 2',
        ):
            self.assertIn(fragment, definitions)
        hatch_start = WORLD.index("local function hatchFestivalEgg")
        hatch_end = WORLD.index("\\nsave = function(player)", hatch_start)
        hatch = WORLD[hatch_start:hatch_end]
        self.assertIn('if player:GetAttribute(definition.id) ~= true then', hatch)
        self.assertIn('session.inventory.HarvestEgg -= 1', hatch)
        self.assertIn('player:SetAttribute(companionId, true)', hatch)
        self.assertIn('player:SetAttribute("Companion", companionId)', hatch)
        self.assertIn("if not save(player) then", hatch)
        self.assertIn("session.inventory.HarvestEgg = previousEggs", hatch)
        self.assertIn('if action == "HatchFestivalEgg" then', WORLD)

    def test_egg_inventory_and_event_claim_persist(self):
        self.assertIn('"HarvestEgg"}', WORLD)
        self.assertIn("festivalEggClaimed = sameEvent and saved.festivalEggClaimed == true or false", WORLD)
        self.assertIn('player:SetAttribute("SeasonalEvent_FestivalEggClaimed"', WORLD)
        self.assertIn('player:GetAttribute("Resource_HarvestEgg")', HUD)

    def test_collection_and_event_ui_expose_egg_and_all_five_creatures(self):
        self.assertIn('button(body, "ClaimFestivalEgg"', HUD)
        self.assertIn('button(body, "HatchFestivalEgg"', HUD)
        self.assertIn('event:FireServer("ClaimFestivalEgg")', HUD)
        self.assertIn('event:FireServer("HatchFestivalEgg")', HUD)
        self.assertIn("Дубликаты исключены", HUD)
        for companion_id in ("BrambleBun", "MossTurtle", "Glowcap", "Dewdrop", "Starling"):
            self.assertIn(f'{companion_id} =', ALBUM)
            self.assertIn(f'elseif state.id == "{companion_id}"', ANIMATION) if f'elseif state.id == "{companion_id}"' in ANIMATION else self.assertIn('local bobSpeed = resting and 1.45', ANIMATION)

    def test_studio_acceptance_and_roadmap_are_present(self):
        self.assertIn("Призовое яйцо Фестиваля урожая", STUDIO)
        self.assertIn("одноразовое призовое яйцо за 50 очков фестиваля", ROADMAP)


if __name__ == "__main__":
    unittest.main()
