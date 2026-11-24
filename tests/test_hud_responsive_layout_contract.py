"""Responsive HUD layout contracts for desktop, tablet, and mobile viewports."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class HudResponsiveLayoutContractTests(unittest.TestCase):
    def test_layout_uses_live_viewport_breakpoints(self):
        self.assertIn("local function updateResponsiveLayout()", HUD)
        self.assertIn("local viewport = camera.ViewportSize", HUD)
        self.assertIn("local compact = viewport.X < 620", HUD)
        self.assertIn("local narrow = viewport.X < 420", HUD)
        self.assertIn('camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout)', HUD)
        self.assertIn('workspace:GetPropertyChangedSignal("CurrentCamera"):Connect', HUD)

    def test_mobile_topbar_and_objective_fit_narrow_screens(self):
        self.assertIn("brand.Size = UDim2.fromOffset(compact and (narrow and 112 or 132) or 178", HUD)
        self.assertIn("resources.Size = UDim2.fromOffset(compact and (narrow and 150 or 174) or 214", HUD)
        self.assertIn("objective.Size = UDim2.fromOffset(compact and (narrow and 210 or 250) or 352", HUD)
        self.assertIn("objectiveHint.Visible = not compact", HUD)
        self.assertIn("progressCount.Visible = not compact", HUD)

    def test_modal_panel_is_bounded_by_available_viewport(self):
        self.assertIn("local panelWidth = math.max(240, math.min(470, viewport.X - (compact and 16 or 48)))", HUD)
        self.assertIn("local panelHeight = math.max(160, math.min(420, viewport.Y - (compact and 140 or 220)))", HUD)
        self.assertIn("panel.Size = UDim2.fromOffset(panelWidth, panelHeight)", HUD)
        self.assertIn("body.Size = UDim2.new(1, -24, 1, -84)", HUD)
        self.assertIn("body.AutomaticCanvasSize = Enum.AutomaticSize.Y", HUD)

    def test_mobile_navigation_keeps_compact_tap_targets(self):
        self.assertIn("nav.Size = UDim2.new(1, compact and -16 or -32, 0, compact and 54 or 68)", HUD)
        self.assertIn("navButton.Size = UDim2.new(1 / #navDefinitions, compact and -2 or -6, 1, -8)", HUD)
        self.assertIn('navButton.Text = compact and definition.glyph or (definition.glyph .. "\\\\n" .. definition.title)', HUD)
        self.assertIn("navButton.TextSize = compact and 20 or 13", HUD)

    def test_layout_rebuilds_active_tab_when_crossing_breakpoint(self):
        self.assertIn("if lastCompactLayout ~= nil and lastCompactLayout ~= compact and refreshActiveTab then", HUD)
        self.assertIn("refreshActiveTab()", HUD)
        self.assertIn('gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayout)', HUD)


if __name__ == "__main__":
    unittest.main()
