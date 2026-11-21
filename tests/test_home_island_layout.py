import math
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class HomeIslandLayoutTests(unittest.TestCase):
    def setUp(self):
        self.center = (0.0, -40.0)
        self.radius = 240.0
        self.slots = []
        for index in range(8):
            angle = math.tau * index / 8
            self.slots.append((
                math.sin(angle) * self.radius,
                self.center[1] - math.cos(angle) * self.radius,
                angle,
            ))

    def test_runtime_and_build_use_the_same_eight_slot_ring(self):
        self.assertIn("HOME_ISLAND_SLOT_COUNT = 8", WORLD)
        self.assertIn("HOME_ISLAND_RADIUS = 240", WORLD)
        self.assertIn("HOME_WORLD_CENTER = Vector3.new(0, 0, -40)", WORLD)
        self.assertIn("for slot_index in range(8):", BUILD)
        self.assertIn("HOME_ISLAND_RADIUS", WORLD)

    def test_all_eight_home_islands_have_distinct_safe_spacing(self):
        self.assertEqual(len(self.slots), 8)
        distances = []
        for i, first in enumerate(self.slots):
            for second in self.slots[i + 1:]:
                distance = math.dist(first[:2], second[:2])
                distances.append(distance)
        self.assertGreater(min(distances), 180.0)

    def test_each_home_bridge_reaches_the_shared_grove_edge(self):
        start_radius = 219.0
        end_radius = 73.0
        bridge_length = start_radius - end_radius
        self.assertAlmostEqual(bridge_length, 146.0)
        self.assertLess(end_radius, 75.0)  # Grove half-width / half-depth.
        self.assertIn("add_radial_bridge(bridge_home", BUILD)
        self.assertIn("angle, 219, 73", BUILD)

    def test_dusk_bridge_sits_between_home_bridge_spokes(self):
        dusk_x = 57.4025
        dusk_z = -178.5819
        dx = dusk_x - self.center[0]
        dz = dusk_z - self.center[1]
        dusk_radius = math.hypot(dx, dz)
        dusk_angle = math.atan2(dx, -dz)
        self.assertAlmostEqual(dusk_radius, 150.0, places=2)
        self.assertAlmostEqual(dusk_angle, math.pi / 8, places=3)
        self.assertIn("math.pi / 8, 73, 120", BUILD)

    def test_bridge_geometry_is_segmented_and_has_rails_and_lamps(self):
        self.assertIn("math.ceil(length / 8)", BUILD)
        self.assertIn('"BridgeDeck"', BUILD)
        self.assertIn('"BridgeRail"', BUILD)
        self.assertIn('"BridgePost"', BUILD)
        self.assertIn('"BridgeLamp"', BUILD)


if __name__ == "__main__":
    unittest.main()
