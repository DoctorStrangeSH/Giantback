"""Appearance module preserves client-only growth and mutation visual contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
APPEARANCE = (ROOT / "modules/CompanionAppearance.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionAppearanceModuleTests(unittest.TestCase):
    def test_appearance_is_packaged_and_initialized(self):
        self.assertIn('companion_appearance = obj(storage, "ModuleScript", "CompanionAppearance")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionAppearance"))', CLIENT)
        self.assertIn('CompanionAppearance.new(player, animationStates, captureAnimation)', CLIENT)
        self.assertIn('local applyCompanionGrowth = appearance.growth', CLIENT)
        self.assertIn('local applyCompanionMutation = appearance.mutation', CLIENT)

    def test_growth_refreshes_rig_animation_offsets(self):
        self.assertIn('model:ScaleTo(scale)', APPEARANCE)
        self.assertIn('local currentState = animationStates[model]', APPEARANCE)
        self.assertIn('captureAnimation(model, companionId, false, owner == player)', APPEARANCE)
        self.assertIn('model:SetAttribute("AppliedGrowthStage", stageId)', APPEARANCE)

    def test_mutation_preserves_color_restore_and_legendary_aura(self):
        self.assertIn('mutationOriginalColors = setmetatable({}, {__mode = "k"})', APPEARANCE)
        self.assertIn('part.Color = originalColor', APPEARANCE)
        self.assertIn('table.clear(originals)', APPEARANCE)
        self.assertIn('if visual.legendary then', APPEARANCE)
        self.assertIn('LegendaryMutationParticles', APPEARANCE)
        self.assertIn('model:SetAttribute("AppliedMutation", normalizedId)', APPEARANCE)

    def test_no_mutation_roll_or_inventory_grant_on_client(self):
        for forbidden in ('FireServer(', 'InvokeServer(', 'DataStoreService', 'rollCompanionMutation(', 'GrantCompanionXP'):
            self.assertNotIn(forbidden, APPEARANCE)
        self.assertIn('applyCompanionGrowth(model, owner, id)', CLIENT)
        self.assertIn('applyCompanionMutation(model, owner, id)', CLIENT)


if __name__ == "__main__":
    unittest.main()
