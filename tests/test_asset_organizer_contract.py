"""Source-level safeguards for the Studio-only asset organizer."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "tools/roblox/organize_imported_assets.luau").read_text(encoding="utf-8")
ASSETS = ROOT / "assets/source_models"


class AssetOrganizerTests(unittest.TestCase):
    def test_all_six_source_assets_are_registered(self):
        for name in ("fox_companion", "moth_companion", "home_cottage", "farm_bed", "bridge_segment", "home_island"):
            with self.subTest(name=name):
                self.assertTrue((ASSETS / (name + ".obj")).exists())
                self.assertIn(name + " = {", SCRIPT)

    def test_preview_is_default_and_does_not_modify_selection(self):
        self.assertIn("local APPLY = false", SCRIPT)
        self.assertIn("if APPLY then", SCRIPT)
        self.assertIn("Selection:Get()", SCRIPT)
        self.assertIn('item:IsA("Model")', SCRIPT)
        self.assertIn('FindFirstChildWhichIsA("MeshPart", true)', SCRIPT)

    def test_no_asset_overwrite_or_gameplay_replacement(self):
        self.assertIn("if existing and existing ~= entry.model then", SCRIPT)
        self.assertIn("if seen[identity] then", SCRIPT)
        self.assertIn('entry.model.Parent = dest', SCRIPT)
        self.assertNotIn(":Destroy()", SCRIPT)
        self.assertNotIn("game.Workspace:ClearAllChildren()", SCRIPT)

    def test_runtime_destinations_and_review_status(self):
        for text in ("ReplicatedStorage", "ServerStorage", "AssetLibrary", "Companions", "Buildings", "Environment"):
            self.assertIn(text, SCRIPT)
        self.assertIn('"NeedsStudioReview"', SCRIPT)
        self.assertIn("GiantbackAssetKey", SCRIPT)


if __name__ == "__main__":
    unittest.main()
