"""Modal focus, dismissal and font-safe glyph contracts for the main HUD."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class ModalPolishTests(unittest.TestCase):
    def test_modal_backdrop_is_a_real_fullscreen_focus_layer(self):
        self.assertIn('modalBackdrop.Name = "ModalBackdrop"', HUD)
        self.assertIn('modalBackdrop.Size = UDim2.fromScale(1, 1)', HUD)
        self.assertIn('modalBackdrop.ZIndex = 20', HUD)
        self.assertIn('panel.ZIndex = 21', HUD)
        self.assertIn('descendant:IsA("GuiObject")', HUD)
        self.assertIn('descendant.ZIndex = 22', HUD)
        self.assertIn('modalBackdrop.Visible = true', HUD)

    def test_every_close_path_uses_one_state_reset(self):
        self.assertIn('closeActivePanel = function()', HUD)
        self.assertIn('panel.Visible = false', HUD)
        self.assertIn('modalBackdrop.Visible = false', HUD)
        self.assertIn('navButton.BackgroundColor3 = palette.forestLight', HUD)
        self.assertIn('modalBackdrop.Activated:Connect(function()', HUD)
        self.assertIn('closeButton.Activated:Connect(function()', HUD)
        self.assertIn('input.KeyCode == Enum.KeyCode.Escape', HUD)
        self.assertIn('input.KeyCode == Enum.KeyCode.ButtonB', HUD)
        self.assertIn('if not panelTitles[tabName] or not renderers[tabName] then return end', HUD)

    def test_modal_header_and_toast_keep_correct_layers_on_small_screens(self):
        self.assertIn('panelTitle.TextSize = compact and 16 or 20', HUD)
        self.assertIn('panelSubtitle.TextSize = compact and 10 or 12', HUD)
        self.assertIn('closeButton.Size = UDim2.fromOffset(compact and 36 or 42, compact and 36 or 42)', HUD)
        self.assertIn('toast.ZIndex = 40', HUD)
        self.assertIn('toastText.ZIndex = 41', HUD)

    def test_companion_memory_game_uses_same_font_safe_symbols_on_client_and_server(self):
        symbols = 'local companionPlaySymbols = {"●", "◆", "✦"}'
        self.assertIn(symbols, WORLD)
        self.assertIn('local playSymbols = {"●", "◆", "✦"}', HUD)

    def test_hud_no_longer_depends_on_emoji_presentation_glyphs(self):
        emoji_ranges = re.compile("[\\U0001F000-\\U0001FAFF]")
        self.assertIsNone(emoji_ranges.search(HUD))
        self.assertIsNone(emoji_ranges.search(WORLD))


if __name__ == "__main__":
    unittest.main()
