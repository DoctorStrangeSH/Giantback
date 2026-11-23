"""Responsive information-card sizing and readable Russian copy contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CardTextLayoutTests(unittest.TestCase):
    def test_information_cards_measure_wrapped_title_and_description(self):
        self.assertIn('local TextService = game:GetService("TextService")', HUD)
        self.assertIn('TextService:GetTextSize(', HUD)
        self.assertIn('local availableWidth = math.max(180, body.AbsoluteSize.X - 28)', HUD)
        self.assertIn('local titleHeight = math.max(22, math.ceil(titleBounds.Y))', HUD)
        self.assertIn('local detailHeight = math.max(18, math.ceil(detailBounds.Y))', HUD)
        self.assertIn('local finalHeight = math.max(height or 82, contentHeight)', HUD)

    def test_information_cards_have_consistent_accent_and_responsive_typography(self):
        self.assertIn('accent.Name = "Accent"', HUD)
        self.assertIn('accent.BackgroundColor3 = palette.gold', HUD)
        self.assertIn('local titleSize = compact and 14 or 15', HUD)
        self.assertIn('local detailSize = compact and 12 or 13', HUD)
        self.assertIn('detail.TextYAlignment = Enum.TextYAlignment.Top', HUD)

    def test_player_instructions_use_clear_action_language(self):
        self.assertIn('Выбери культуру — её можно будет посадить на любой свободной грядке.', HUD)
        self.assertIn('Когда урожай созреет, возвращайся за ним.', HUD)
        self.assertIn('Для каждого ресурса нужен подходящий инструмент.', HUD)
        self.assertIn('Записывай новые находки и выполненные задания.', HUD)
        self.assertNotIn('Твой дом и ферма не накладываются на чужие участки.', HUD)


if __name__ == "__main__":
    unittest.main()
