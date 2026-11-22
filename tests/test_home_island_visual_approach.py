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

    def test_companion_sanctuary_has_three_rest_spots_and_a_clear_approach(self):
        self.assertIn('makeFolder(homeDetails, "PetSanctuary")', VISUALS)
        self.assertIn('local sanctuaryCenter = Vector3.new(-23, 12.16, -8.5)', VISUALS)
        self.assertIn('"Companion sanctuary moss pad"', VISUALS)
        self.assertIn('"Companion sanctuary stone dais"', VISUALS)
        self.assertEqual(VISUALS.count('"Companion resting cushion base"'), 1)
        self.assertIn('local restSpots = {', VISUALS)
        self.assertIn('Vector3.new(-25.1, 12.48, -8.5)', VISUALS)
        self.assertIn('Vector3.new(-20.9, 12.48, -8.5)', VISUALS)
        self.assertIn('Vector3.new(-23.0, 12.48, -6.1)', VISUALS)
        self.assertIn('"Sanctuary moon lantern"', VISUALS)
        self.assertIn('"Companion nook stepping stone"', VISUALS)
        self.assertIn('"Sanctuary border pebble"', VISUALS)

    def test_home_island_has_layered_canopy_and_understory_without_using_plot_space(self):
        self.assertIn('makeFolder(homeDetails, "HomeCanopy")', VISUALS)
        self.assertIn('local homeTreeSites = {', VISUALS)
        self.assertIn('Vector3.new(-28.0, 12.0, 15.5)', VISUALS)
        self.assertIn('Vector3.new(1.5, 12.0, -23.0)', VISUALS)
        self.assertIn('Vector3.new(22.0, 12.0, -16.5)', VISUALS)
        self.assertIn('addTree(homeCanopy, treeSite.position, treeSite.scale, treeSite.color, treeSite.seed)', VISUALS)
        self.assertIn('"Canopy glow berry"', VISUALS)
        self.assertIn('local homeGardenPockets = {', VISUALS)
        self.assertIn('"Rounded berry shrub"', VISUALS)
        self.assertIn('local homeMushroomSites = {', VISUALS)
        self.assertIn('addMushroom(', VISUALS)
        # Farm plots occupy the south-west quadrant; the new canopy stays around
        # the outer rim and does not consume the crop grid or companion rest pad.
        self.assertNotIn('Vector3.new(-14.5, 12.0, 8.8)', VISUALS)
        self.assertNotIn('Vector3.new(-10.5, 12.0, 12.4)', VISUALS)
        self.assertNotIn('Vector3.new(-23.0, 12.0, -8.5)', VISUALS)

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
