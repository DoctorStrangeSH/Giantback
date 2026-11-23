"""Sleep glyph visuals are isolated from companion gameplay state."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
MODULE = (ROOT / "modules/CompanionSleepVisuals.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionSleepVisualsModuleTests(unittest.TestCase):
    def test_module_embedded_in_generated_place(self):
        self.assertIn('companion_sleep_visuals = obj(storage, "ModuleScript", "CompanionSleepVisuals")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionSleepVisuals"))', CLIENT)
        self.assertIn('local sleepVisuals = CompanionSleepVisuals.new(palette)', CLIENT)
        self.assertIn('local setSleepIndicator = sleepVisuals.setEnabled', CLIENT)

    def test_sleep_glyph_lifecycle_keeps_cancellation_guards(self):
        self.assertIn('local sleepIndicators = {}', MODULE)
        self.assertIn('sleepIndicators[model] = nil', MODULE)
        self.assertIn('if current then', MODULE)
        self.assertIn('while sleepIndicators[model] == billboard and billboard.Parent and model.Parent do', MODULE)
        self.assertIn('billboard.Name = "CompanionSleepZLocal"', MODULE)
        self.assertIn('Debris:AddItem(glyph, 1.4)', MODULE)
        self.assertIn('setSleepIndicator(model, false)', CLIENT)
        self.assertIn('setSleepIndicator(model, sleeping)', CLIENT)

    def test_client_only_visuals_and_no_duplicate_follow_loop(self):
        for forbidden in ('FireServer(', 'InvokeServer(', 'DataStoreService', 'SetAttribute(', 'RenderStepped:Connect'):
            self.assertNotIn(forbidden, MODULE)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)


if __name__ == "__main__":
    unittest.main()
