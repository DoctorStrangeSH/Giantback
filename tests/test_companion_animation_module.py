"""Companion animation module integration and ownership safeguards."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules/CompanionAnimation.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionAnimationModuleTests(unittest.TestCase):
    def test_embedded_runtime_module(self):
        self.assertIn('companion_animation = obj(storage, "ModuleScript", "CompanionAnimation")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionAnimation"))', CLIENT)
        self.assertIn("CompanionAnimation.capture(model, id, isEncounter, isLocal)", CLIENT)
        self.assertIn("CompanionAnimation.animate(model, state, time, moving, resting,", CLIENT)

    def test_live_ability_context_and_model_lifecycle_remain_in_client(self):
        for marker in (
            "animationStates[model] = state",
            "player, foxSniffUntil, mothAbilityUntil, pettingUntil)",
            "animationStates[model] = nil",
            "setSleepIndicator(model, false)",
            "local function follow(dt)",
            "captureAnimation(model, id, false, owner == player)",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, CLIENT)

    def test_three_species_and_motion_consistency(self):
        for marker in (
            'state.id == "Fox"',
            'state.id == "Moth"',
            'state.id == "CrystalWisp"',
            'local growthStage = math.clamp',
            'local prismSenseActive = state.id == "CrystalWisp"',
            'part.CFrame = pivot * transform * offset',
            'local function aroundPoint(point, rotation)',
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, ANIMATION)

    def test_module_does_not_change_server_state_or_create_duplicate_follow_loop(self):
        for forbidden in ("FireServer(", "InvokeServer(", "DataStoreService", "SetAttribute(", "RenderStepped:Connect"):
            self.assertNotIn(forbidden, ANIMATION)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)
        self.assertEqual(ANIMATION.count('function CompanionAnimation.animate('), 1)
        self.assertEqual(ANIMATION.count('function CompanionAnimation.capture('), 1)


if __name__ == "__main__":
    unittest.main()
