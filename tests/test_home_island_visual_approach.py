from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class HomeIslandVisualApproachTests(unittest.TestCase):
    def test_garden_path_has_five_stones_between_house_and_farm(self):
        self.assertIn('makeFolder(homeDetails, "GardenApproach")', VISUALS)
        self.assertIn('local pathStones = {', VISUALS)
        self.assertEqual(VISUALS.count('Vector3.new(-12.2, 12.12, -0.1)'), 1)
        self.assertIn('Vector3.new(-12.2, 12.12, 7.9)', VISUALS)
        self.assertIn('"Garden path stone"', VISUALS)
        self.assertIn('local plotPositions = {', WORLD)
        self.assertIn('Plot01 = Vector3.new(-14.5', WORLD)
        self.assertIn('Plot04 = Vector3.new(-10.5', WORLD)

    def test_arch_frames_the_garden_without_covering_crop_plots(self):
        self.assertIn('"Garden arch post"', VISUALS)
        self.assertIn('"Garden arch lintel"', VISUALS)
        self.assertIn('"Garden arch moon charm"', VISUALS)
        self.assertIn('CFrame.new(-12.2, 15.85, 6.2)', VISUALS)
        self.assertIn('Vector3.new(-16.7, 12.15, 6.2)', VISUALS)
        self.assertIn('Vector3.new(-7.7, 12.15, 6.2)', VISUALS)

    def test_garden_details_use_existing_non_colliding_visual_helpers(self):
        helper_start = VISUALS.index("local function makePart")
        helper_end = VISUALS.index("\nend", helper_start)
        helper = VISUALS[helper_start:helper_end]
        self.assertIn("part.CanCollide = false", helper)
        self.assertIn("part.CanTouch = false", helper)
        self.assertIn("part.CanQuery = false", helper)
        self.assertIn('addLight(archMoon, palette.gold, 7, 0.28)', VISUALS)


if __name__ == "__main__":
    unittest.main()
