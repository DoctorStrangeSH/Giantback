"""Responsive HUD layout contracts for desktop, tablet, and mobile viewports."""
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class HudResponsiveLayoutContractTests(unittest.TestCase):
    def test_layout_uses_live_viewport_breakpoints(self):
        self.assertIn("local function updateResponsiveLayout()", HUD)
        self.assertIn("local viewport = camera.ViewportSize", HUD)
        self.assertIn("local compact = viewport.X < 620", HUD)
        self.assertIn("local narrow = viewport.X < 480", HUD)
        self.assertIn("local shortScreen = viewport.Y < 440", HUD)
        self.assertIn('camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout)', HUD)
        self.assertIn('workspace:GetPropertyChangedSignal("CurrentCamera"):Connect', HUD)

    def test_mobile_topbar_and_objective_fit_narrow_screens(self):
        self.assertIn("brand.Size = UDim2.fromOffset(compact and (narrow and 104 or 132) or 178", HUD)
        self.assertIn("resources.Size = UDim2.fromOffset(compact and (narrow and 150 or 174) or 214", HUD)
        self.assertIn("objective.Size = UDim2.fromOffset(compact and (narrow and 210 or 250) or 352", HUD)
        self.assertIn("objectiveHint.Visible = not compact", HUD)
        self.assertIn("progressCount.Visible = not compact", HUD)

    def test_modal_panel_is_bounded_by_available_viewport(self):
        self.assertIn("local panelWidth = math.max(1, math.min(560, viewport.X - 16))", HUD)
        self.assertIn("local panelHeight = math.max(1, math.min(560, viewport.Y - (shortScreen and 64 or compact and 112 or 160)))", HUD)
        self.assertIn("Never let the modal extend beyond the actual viewport", HUD)
        self.assertNotIn("math.max(240, math.min(560, viewport.X - 16))", HUD)
        self.assertNotIn("math.max(210, math.min(560, viewport.Y -", HUD)
        self.assertIn("panel.Size = UDim2.fromOffset(panelWidth, panelHeight)", HUD)
        self.assertIn("body.Size = UDim2.new(1, -24, 1, compact and -78 or -88)", HUD)
        self.assertIn("body.AutomaticCanvasSize = Enum.AutomaticSize.Y", HUD)

    def test_mobile_navigation_keeps_compact_tap_targets(self):
        self.assertIn("nav.Size = UDim2.new(1, compact and -16 or -32, 0, compact and (shortScreen and 48 or 56) or 72)", HUD)
        self.assertIn("navButton.Size = UDim2.new(1 / #navDefinitions, narrow and -1 or compact and -4 or -8, 1, -8)", HUD)
        self.assertIn('createPictogram(navButton, "Icon", definition.icon, 24, palette.white)', HUD)
        self.assertIn('titleLabel.Visible = true', HUD)
        self.assertIn("titleLabel.TextSize = narrow and 9 or compact and 9 or 11", HUD)
        self.assertIn("Keep the icon above its caption on compact and narrow navigation bars", HUD)
        self.assertIn("iconRoot.Position = UDim2.new(0.5, -iconSize / 2, 0, 3)", HUD)
        self.assertNotIn("0.5, -iconSize / 2, 0.5, -iconSize / 2", HUD)


    def test_every_pet_and_navigation_icon_has_a_native_pictogram(self):
        catalog_start = HUD.index("local function renderPets()")
        catalog_end = HUD.find("\\nlocal function ", catalog_start + 30)
        pet_catalog = HUD[catalog_start:catalog_end]
        icon_start = HUD.index("local function createPictogram")
        icon_end = HUD.find("\\nlocal function ", icon_start + 30)
        pictogram_factory = HUD[icon_start:icon_end]

        pet_icons = set(re.findall(r'icon\s*=\s*"([^"]+)"', pet_catalog))
        navigation_icons = set(re.findall(r'icon\s*=\s*"([^"]+)"', HUD[HUD.index("navDefinitions ="):]))
        directly_used_icons = set(
            re.findall(r'createPictogram\([^,\n]+,\s*[^,\n]+,\s*"([^"]+)"', HUD)
        )
        supported_icons = set(re.findall(r'kind\s*==\s*"([^"]+)"', pictogram_factory))

        self.assertTrue(pet_icons, "Pet catalog must declare its pictograms")
        self.assertTrue(navigation_icons, "Navigation must declare its pictograms")
        self.assertFalse(pet_icons - supported_icons, f"Missing pet pictograms: {pet_icons - supported_icons}")
        self.assertFalse(navigation_icons - supported_icons, f"Missing navigation pictograms: {navigation_icons - supported_icons}")
        self.assertFalse(directly_used_icons - supported_icons, f"Missing directly used pictograms: {directly_used_icons - supported_icons}")
        self.assertIn('part("FallbackBadge"', pictogram_factory)
        self.assertIn('part("FallbackMark"', pictogram_factory)

    def test_layout_rebuilds_active_tab_when_crossing_breakpoint(self):
        self.assertIn("if lastCompactLayout ~= nil and lastCompactLayout ~= compact and refreshActiveTab then", HUD)
        self.assertIn("refreshActiveTab()", HUD)
        self.assertIn('gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayout)', HUD)


if __name__ == "__main__":
    unittest.main()
