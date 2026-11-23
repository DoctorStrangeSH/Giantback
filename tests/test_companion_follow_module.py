"""Companion follow geometry is shared without affecting game state."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
FOLLOW = (ROOT / "modules/CompanionFollow.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionFollowModuleTests(unittest.TestCase):
    def test_module_is_packaged_and_invoked(self):
        self.assertIn('companion_follow = obj(storage, "ModuleScript", "CompanionFollow")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionFollow"))', CLIENT)
        self.assertIn('CompanionFollow.target(root, owner, id, now, owner == player)', CLIENT)
        self.assertIn('CompanionFollow.smooth(model, target, dt)', CLIENT)

    def test_local_moth_orbits_and_other_companions_keep_offsets(self):
        self.assertIn('if id == "Moth" and isLocal then', FOLLOW)
        self.assertIn('personalityRadius - bondStage * 0.035', FOLLOW)
        self.assertIn('local orbitAngle = phase * (orbitSpeeds[personality] or 0.72)', FOLLOW)
        self.assertIn('id == "Fox" and -1.35 or 1.05', FOLLOW)
        self.assertIn('root.CFrame', FOLLOW)

    def test_frame_rate_independent_motion_is_preserved(self):
        self.assertIn('1 - math.exp(-9 * dt)', FOLLOW)
        self.assertIn('model:GetPivot():Lerp(target, 1 - math.exp(-9 * dt))', FOLLOW)
        self.assertIn('return target, phase', FOLLOW)
        self.assertIn('animateModelParts(model, state, phase, moving, resting)', CLIENT)

    def test_visual_module_does_not_change_server_state(self):
        for forbidden in ('FireServer(', 'InvokeServer(', 'DataStoreService', 'SetAttribute(', 'Instance.new('):
            self.assertNotIn(forbidden, FOLLOW)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)


if __name__ == "__main__":
    unittest.main()
