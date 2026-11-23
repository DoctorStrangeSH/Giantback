"""Contracts for touch combat buttons in the live playable place."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")
SERVER = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class MobileCombatContextContracts(unittest.TestCase):
    def test_all_five_controls_keep_touch_keyboard_and_gamepad_bindings(self):
        for action in ("GiantbackAttack", "GiantbackBlock", "GiantbackDodge",
                       "GiantbackCharge", "GiantbackCompanion"):
            self.assertIn(f'ContextActionService:BindAction(\n    "{action}"', CLIENT)
        self.assertIn('Enum.UserInputType.MouseButton1', CLIENT)
        self.assertIn('Enum.KeyCode.ButtonR2', CLIENT)
        self.assertIn('Enum.KeyCode.ButtonB', CLIENT)

    def test_buttons_are_compact_and_hidden_outside_fight_zones(self):
        self.assertIn('local TOUCH_ACTIONS = {', CLIENT)
        self.assertIn('local TOUCH_POSITIONS = {', CLIENT)
        self.assertIn('ContextActionService:SetPosition(actionName, TOUCH_POSITIONS[i])', CLIENT)
        self.assertIn('UserInputService.TouchEnabled', CLIENT)
        self.assertIn('ContextActionService:GetButton(actionName)', CLIENT)
        self.assertIn('touchButton.Size = UDim2.fromOffset(58, 58)', CLIENT)
        self.assertIn('touchButton.Visible = visible', CLIENT)
        self.assertIn('task.wait(0.25)', CLIENT)

    def test_local_region_check_uses_same_tags_and_3d_bounds_as_server(self):
        self.assertIn('player:GetAttribute("Ready") ~= true', CLIENT)
        self.assertIn('humanoid.Health <= 0', CLIENT)
        self.assertIn('CollectionService:GetTagged("GiantbackCombatRegion")', CLIENT)
        self.assertIn('regionPart.CFrame:PointToObjectSpace(root.Position)', CLIENT)
        self.assertIn('math.abs(localPoint.X) <= half.X', CLIENT)
        self.assertIn('math.abs(localPoint.Y) <= half.Y', CLIENT)
        self.assertIn('math.abs(localPoint.Z) <= half.Z', CLIENT)
        self.assertIn('CollectionService:GetTagged("GiantbackCombatRegion")', SERVER)
        self.assertIn('CollectionService:AddTag(region, "GiantbackCombatRegion")', WORLD)

    def test_hit_validation_remains_server_owned(self):
        self.assertIn('remote:FireServer("Attack")', CLIENT)
        self.assertIn('local function performAttack(player, state, now)', SERVER)
        self.assertIn('state.attackReadyAt = now + COMBO_COOLDOWN[comboStep]', SERVER)
        self.assertIn('"Combat.client.luau"', BUILD)


if __name__ == "__main__":
    unittest.main()
