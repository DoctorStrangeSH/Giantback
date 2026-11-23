"""First Grove waypoint is a client-only hint, never a substitute for server prompts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE = (ROOT / "modules/GroveFirstSteps.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class GroveFirstStepsTests(unittest.TestCase):
    def test_embedded_and_live_in_album_client(self):
        self.assertIn('grove_first_steps = obj(storage, "ModuleScript", "GroveFirstSteps")', BUILD)
        self.assertIn('require(storage:WaitForChild("GroveFirstSteps"))', ALBUM)
        self.assertIn('GroveFirstSteps.new(player)', ALBUM)
        self.assertIn('local groveFirstSteps = GroveFirstSteps.new(player)', ALBUM)

    def test_ordered_local_markers(self):
        self.assertIn('player:GetAttribute("Ready") ~= true', MODULE)
        self.assertIn('player:GetAttribute("Bridge_HomeToGrove") ~= true', MODULE)
        self.assertIn('if player:GetAttribute("Fox") ~= true then', MODULE)
        self.assertIn('grove:FindFirstChild("Nest")', MODULE)
        self.assertIn('grove:FindFirstChild("Trail")', MODULE)
        self.assertIn('player:GetAttribute("Companion") == "Fox"', MODULE)
        self.assertIn('player:GetAttribute("Seed") ~= true', MODULE)
        self.assertIn('type(cache) ~= "string" or cache == ""', MODULE)
        self.assertLess(MODULE.index('grove:FindFirstChild("Nest")'), MODULE.index('grove:FindFirstChild("Trail")'))

    def test_only_one_visual_marker_and_no_duplicate_prompts(self):
        self.assertIn('if marker and targetPart == part and marker.Parent then return end', MODULE)
        self.assertIn('marker:Destroy()', MODULE)
        self.assertIn('marker.Name = "GiantbackFirstStepsLocal"', MODULE)
        self.assertIn('billboard.MaxDistance = 60', MODULE)
        self.assertIn('if child.Name == "Nest" or child.Name == "Trail" then update() end', MODULE)
        for forbidden in ('ProximityPrompt', ':FireServer(', ':InvokeServer(', ':SetAttribute(', 'DataStoreService'):
            self.assertNotIn(forbidden, MODULE)
        self.assertIn('prompt(nest,pets[id],"Подружиться",function(player)', WORLD)
        self.assertIn('prompt(workspace.Grove.Trail,"Следы в траве","Попросить лисёнка искать",startFoxSearch)', WORLD)

    def test_attribute_and_grove_lifecycle_responsive(self):
        for key in ('"Ready"', '"Bridge_HomeToGrove"', '"Fox"', '"Seed"', '"Companion"', '"FoxCacheSpot"'):
            self.assertIn(key, MODULE)
        self.assertIn('workspace.ChildAdded:Connect', MODULE)
        self.assertIn('workspace.ChildRemoved:Connect', MODULE)
        self.assertIn('groveConnection:Disconnect()', MODULE)


if __name__ == "__main__":
    unittest.main()
