"""Moth particle formula and imported follower geometry regression contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class CompanionVisualCleanupTests(unittest.TestCase):
    def test_moth_stardust_personality_mapping_is_single_source(self):
        self.assertEqual(CLIENT.count('["Любопытный"] = 9,'), 1)
        self.assertEqual(CLIENT.count('["Озорной"] = 12,'), 1)
        self.assertIn("local function mothStardustRate(personality, bondStage)", CLIENT)
        self.assertEqual(CLIENT.count("emitter.Rate = mothStardustRate(personality, bondStage)"), 2)

    def test_stardust_updates_when_personality_changes_without_bond_change(self):
        self.assertIn('emitter:GetAttribute("AppliedBondStage") == bondStage', CLIENT)
        self.assertIn('emitter:GetAttribute("AppliedPersonality") == (personality or "")', CLIENT)
        self.assertEqual(CLIENT.count('emitter:SetAttribute("AppliedPersonality", personality or "")'), 2)

    def test_imported_rig_needs_direct_meshparts_as_runtime_animator_does(self):
        self.assertIn('local body = imported:FindFirstChild("Body")', CLIENT)
        self.assertIn('local movingPart = imported:FindFirstChild(movingPartName)', CLIENT)
        self.assertNotIn('imported:FindFirstChild("Body", true)', CLIENT)
        self.assertIn('local body = model:FindFirstChild("Body")', CLIENT)


if __name__ == "__main__":
    unittest.main()
