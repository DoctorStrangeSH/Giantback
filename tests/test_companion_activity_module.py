"""Companion idle behavior must be extracted without changing server authority."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ACTIVITY = (ROOT / "modules/CompanionActivity.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionActivityModuleTests(unittest.TestCase):
    def test_builder_installs_activity_module(self):
        self.assertIn('companion_activity = obj(storage, "ModuleScript", "CompanionActivity")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionActivity"))', CLIENT)
        self.assertIn('local companionActivity = CompanionActivity.new()', CLIENT)

    def test_idle_and_sniff_behavior_retained(self):
        self.assertIn('local companionActivity = setmetatable({}, {__mode = "k"})', ACTIVITY)
        self.assertIn('idleSeconds >= 12', ACTIVITY)
        self.assertIn('idleSeconds >= 45', ACTIVITY)
        self.assertIn('isLocal and id == "Fox"', ACTIVITY)
        self.assertIn('local resting, sleeping, sniff = companionActivity.update(owner, id, now, moving, owner == player)', CLIENT)
        self.assertIn('if sniff then foxSniffUntil = os.clock() + 2.2 end', CLIENT)
        self.assertIn('setSleepIndicator(model, sleeping)', CLIENT)

    def test_owner_cleanup_and_personality_windows(self):
        self.assertIn('companionActivity.forget(owner)', CLIENT)
        self.assertIn('companionActivity[owner] = nil', ACTIVITY)
        for personality in ('Любопытный', 'Озорной', 'Смелый', 'Застенчивый'):
            self.assertIn('["' + personality + '"]', ACTIVITY)

    def test_module_is_read_only_to_server_and_does_not_animate(self):
        for forbidden in ('FireServer(', 'InvokeServer(', 'DataStoreService', 'Instance.new(', 'RenderStepped:Connect', ':SetAttribute('):
            self.assertNotIn(forbidden, ACTIVITY)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)


if __name__ == "__main__":
    unittest.main()
