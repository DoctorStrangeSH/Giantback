"""Contracts for the first UI and world usability quality pass."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class UIWorldQualityContracts(unittest.TestCase):
    def test_hud_responds_to_viewport_and_keeps_navigation_reachable(self):
        self.assertIn('local UserInputService = game:GetService("UserInputService")', HUD)
        self.assertIn('local function updateResponsiveLayout()', HUD)
        self.assertIn('local compact = viewport.X < 620', HUD)
        self.assertIn('local narrow = viewport.X < 420', HUD)
        self.assertIn('local panelHeight = math.max(160, math.min(420, viewport.Y - (compact and 140 or 220)))', HUD)
        self.assertIn('panel.Size = UDim2.fromOffset(panelWidth, panelHeight)', HUD)
        self.assertIn('nav.Size = UDim2.new(1, compact and -16 or -32, 0, compact and 54 or 68)', HUD)
        self.assertIn('navButton.Text = compact and definition.glyph', HUD)
        self.assertIn('ViewportSize"):Connect(updateResponsiveLayout)', HUD)
        self.assertIn('panel.Visible = true', HUD)

    def test_critical_icons_have_font_safe_fallbacks(self):
        for glyph in ('glyph = "О"', 'glyph = "Ф"', 'glyph = "П"',
                      'glyph = "И"', 'glyph = "М"', 'glyph = "Д"',
                      'icon = "Л"', 'icon = "М"', 'icon = "С"'):
            self.assertIn(glyph, HUD)
        self.assertNotIn('glyph = "📖"', HUD)
        self.assertNotIn('icon = "🦊"', HUD)
        self.assertNotIn('icon = "🦋"', HUD)

    def test_bridges_are_wider_and_rails_follow_new_deck_edges(self):
        self.assertIn('(8.2, 0.55, plank_length)', BUILD)
        self.assertEqual(BUILD.count('side * 4.15'), 4)
        self.assertEqual(BUILD.count('side * 3.35'), 2)
        self.assertNotIn('(5.2, 0.48, plank_length)', BUILD)

    def test_fall_recovery_is_server_authoritative_and_preserves_character(self):
        self.assertIn('root.Position.Y < -80', WORLD)
        self.assertIn('character:PivotTo(recovery.CFrame + Vector3.new(0, 6, 0))', WORLD)
        self.assertIn('root.AssemblyLinearVelocity = Vector3.zero', WORLD)
        self.assertIn('root.AssemblyAngularVelocity = Vector3.zero', WORLD)
        self.assertIn('sessions[player] == session', WORLD)
        self.assertIn('workspace:FindFirstChild("Grove")', WORLD)
        self.assertIn('spawn:IsA("BasePart")', WORLD)

    def test_world_signs_are_distance_limited_and_not_always_on_top(self):
        self.assertIn('dummySign.MaxDistance = 55', VISUALS)
        self.assertIn('warningBillboard.MaxDistance = 65', VISUALS)
        self.assertIn('label.MaxDistance = 34', VISUALS)
        self.assertIn('dummySign.AlwaysOnTop = false', VISUALS)
        self.assertIn('warningBillboard.AlwaysOnTop = false', VISUALS)
        self.assertIn('label.AlwaysOnTop = false', VISUALS)

    def test_russian_copy_is_clear_and_navigation_has_single_active_panel(self):
        self.assertIn('Друзья могут приходить в гости, но строить и менять что-либо здесь можешь только ты.', HUD)
        self.assertIn('На острове четыре грядки. Открой раздел «Ферма»', HUD)
        self.assertIn('if activeTab == tabName and panel.Visible then', HUD)
        self.assertIn('panel.Visible = false', HUD)


if __name__ == "__main__":
    unittest.main()
