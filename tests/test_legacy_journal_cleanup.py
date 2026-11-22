"""Old disabled Journal UI must not schedule an idle-time polling loop."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
FEEDBACK = (ROOT / "modules/HarvestFeedback.luau").read_text(encoding="utf-8")


class LegacyJournalCleanupTests(unittest.TestCase):
    def test_unified_hud_remains_active_and_legacy_ui_disabled(self):
        self.assertNotIn('GiantbackJournal', CLIENT)
        self.assertNotIn('QuestCard', CLIENT)
        self.assertNotIn('CollectionPanel', CLIENT)
        self.assertIn('"GiantbackHUD"', HUD)

    def test_disabled_legacy_layout_and_perpetual_poll_are_removed(self):
        self.assertNotIn("local function updateLayout()", CLIENT)
        self.assertNotIn('gui:GetPropertyChangedSignal("AbsoluteSize")', CLIENT)
        self.assertNotIn("while gui.Parent do", CLIENT)

    def test_gameplay_visual_handlers_are_preserved(self):
        for marker in ("local function follow(dt)", "RequestResourceState",
                       "local function companionTemplate(id)"):
            with self.subTest(marker=marker):
                self.assertIn(marker, CLIENT)
        self.assertIn("LocalHarvestProgress", FEEDBACK)


if __name__ == "__main__":
    unittest.main()
