"""Seasonal Harvest Festival world decor follows the server event window."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class HarvestFestivalVisualContractTests(unittest.TestCase):
    def test_visuals_use_the_same_annual_utc_window_as_gameplay(self):
        for source in (VISUALS, WORLD):
            self.assertIn("DateTime.fromUniversalTime(festivalYear, 11, 23, 0, 0, 0)", source) if source is VISUALS else self.assertIn(
                "DateTime.fromUniversalTime(year, 11, 23, 0, 0, 0)", source
            )
            self.assertIn("DateTime.fromUniversalTime", source)
        self.assertIn("festivalNow >= festivalStart and festivalNow < festivalEnd", VISUALS)
        self.assertIn("now >= startAt and now < endAt", WORLD)

    def test_festival_decor_is_added_to_each_personal_island_template(self):
        self.assertIn('makeFolder(homeDetails, "HarvestFestival")', VISUALS)
        self.assertIn('"Harvest Festival Banner"', VISUALS)
        self.assertIn('"ФЕСТИВАЛЬ УРОЖАЯ"', VISUALS)
        self.assertIn('"HarvestLantern"', VISUALS)
        self.assertIn('"HarvestWheatSheaf"', VISUALS)
        self.assertIn('"HarvestBasket"', VISUALS)

    def test_decoration_stays_non_interactive_and_outside_the_garden_path(self):
        helper_start = VISUALS.index("local function makePart")
        helper_end = VISUALS.index("local function orb", helper_start)
        helper = VISUALS[helper_start:helper_end]
        self.assertIn("part.CanCollide = false", helper)
        self.assertIn("part.CanTouch = false", helper)
        self.assertIn("part.CanQuery = false", helper)
        self.assertIn("Vector3.new(-19.0, 12.14, 9.4)", VISUALS)
        self.assertIn("Vector3.new(-12.2, 12.14, 11.2)", VISUALS)
        festival_start = VISUALS.index("-- The Harvest Festival is a real seasonal world event")
        festival_end = VISUALS.index("-- A dedicated, readable rest nook", festival_start)
        festival = VISUALS[festival_start:festival_end]
        self.assertNotIn("ProximityPrompt", festival)
        self.assertNotIn(".Touched", festival)
        self.assertNotIn("RemoteEvent", festival)

    def test_studio_acceptance_and_roadmap_track_the_visual_gate(self):
        self.assertIn("## Фестиваль урожая — сезонный декор", STUDIO)
        self.assertIn("## Сезонное событие — Фестиваль урожая", ROADMAP)
        self.assertIn("уникальные питомцы/яйца и магазин фестивальных предметов", ROADMAP)


if __name__ == "__main__":
    unittest.main()
