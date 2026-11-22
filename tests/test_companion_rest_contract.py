from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class CompanionRestContractTests(unittest.TestCase):
    def test_rest_starts_only_after_a_short_owner_idle_period(self):
        self.assertIn("local companionActivity = {}", ALBUM)
        self.assertIn("idleSince = now", ALBUM)
        self.assertIn("now - activity.idleSince >= 12", ALBUM)
        self.assertIn("if moving then", ALBUM)
        self.assertIn("activity.idleSince = now", ALBUM)

    def test_fox_uses_soft_breathing_and_relaxed_tail_and_paws(self):
        self.assertIn("math.sin(time * 1.8) * 0.035", ALBUM)
        self.assertIn("resting and 1.6", ALBUM)
        self.assertIn("resting and 0.12", ALBUM)
        self.assertIn("local stride = resting and 0", ALBUM)

    def test_moth_folds_into_a_quiet_hover_and_dims_its_core(self):
        self.assertIn("resting and 3.2", ALBUM)
        self.assertIn("resting and 0.13", ALBUM)
        self.assertIn("resting and 1.1", ALBUM)
        self.assertIn("resting and 0.38", ALBUM)

    def test_rest_is_visual_only_and_activity_state_is_cleaned_up(self):
        self.assertIn("animateModelParts(model, state, phase, moving, resting)", ALBUM)
        self.assertIn("companionActivity[owner] = nil", ALBUM)
        self.assertNotIn("RestEnergy", ALBUM)
        self.assertNotIn("RestPenalty", ALBUM)


if __name__ == "__main__":
    unittest.main()
