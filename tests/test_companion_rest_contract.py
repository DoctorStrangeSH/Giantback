from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules/CompanionAnimation.luau").read_text(encoding="utf-8")


class CompanionRestContractTests(unittest.TestCase):
    def test_rest_starts_only_after_a_short_owner_idle_period(self):
        self.assertIn("local companionActivity = {}", ALBUM)
        self.assertIn("idleSince = now", ALBUM)
        self.assertIn("idleSeconds >= 12", ALBUM)
        self.assertIn("if moving then", ALBUM)
        self.assertIn("activity.idleSince = now", ALBUM)

    def test_fox_uses_soft_breathing_and_relaxed_tail_and_paws(self):
        self.assertIn("math.sin(time * 1.8) * 0.035", ANIMATION)
        self.assertIn("swaySpeed = 1.6", ANIMATION)
        self.assertIn("swayStrength = 0.12", ANIMATION)
        self.assertIn("local stride = resting and 0", ANIMATION)

    def test_moth_folds_into_a_quiet_hover_and_dims_its_core(self):
        self.assertIn("flapSpeed = 3.2", ANIMATION)
        self.assertIn("flapStrength = 0.13", ANIMATION)
        self.assertIn("resting and 1.1", ANIMATION)
        self.assertIn("resting and 0.38", ANIMATION)

    def test_deep_idle_adds_local_sleep_z_glyphs_and_cleans_them_up(self):
        self.assertIn('local sleepIndicators = {}', ALBUM)
        self.assertIn('idleSeconds >= 45', ALBUM)
        self.assertIn('setSleepIndicator(model, sleeping)', ALBUM)
        self.assertIn('CompanionSleepZLocal', ALBUM)
        self.assertIn('AlwaysOnTop = true', ALBUM)
        self.assertIn('glyph.Text = glyphText', ALBUM)
        self.assertIn('Debris:AddItem(glyph, 1.4)', ALBUM)
        self.assertIn('setSleepIndicator(model, false)', ALBUM)
        self.assertIn('sleepIndicators[model] = nil', ALBUM)

    def test_rest_is_visual_only_and_activity_state_is_cleaned_up(self):
        self.assertIn("animateModelParts(model, state, phase, moving, resting)", ALBUM)
        self.assertIn("companionActivity[owner] = nil", ALBUM)
        self.assertNotIn("RestEnergy", ALBUM)
        self.assertNotIn("RestPenalty", ALBUM)


if __name__ == "__main__":
    unittest.main()
