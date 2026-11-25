"""Mobile companion collection layout contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CompanionMobileCardLayoutTests(unittest.TestCase):
    def test_companion_cards_expand_and_reflow_below_mobile_breakpoint(self):
        self.assertIn('local compact = gui.AbsoluteSize.X < 620', HUD)
        self.assertIn('compact and 394 or 254', HUD)
        self.assertIn('compact and UDim2.new(1, hasHeroPreview and -188 or -168, 0, 58)', HUD)
        self.assertIn('rarityBadge.Position = UDim2.new(1, -92, 0, 12)', HUD)
        self.assertIn('compact and UDim2.new(1, -28, 0, 32)', HUD)
        self.assertIn('nameLabel.TextWrapped = true', HUD)
        self.assertIn('descriptionLabel.TextWrapped = true', HUD)
        self.assertIn('progressionLabel.TextWrapped = true', HUD)
        self.assertIn('talentLabel.TextWrapped = true', HUD)

    def test_mobile_actions_are_a_two_by_two_grid_and_keep_existing_server_actions(self):
        self.assertIn('local actionSize = compact and UDim2.new(0.5, -18, 0, 36)', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 258)', HUD)
        self.assertIn('compact and UDim2.new(0.5, 6, 0, 258)', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 300)', HUD)
        self.assertIn('compact and UDim2.new(0.5, 6, 0, 300)', HUD)
        self.assertIn('event:FireServer(pet.id)', HUD)
        self.assertIn('event:FireServer("FeedCompanion", pet.id)', HUD)
        self.assertIn('event:FireServer("StartCompanionPlay", pet.id)', HUD)
        self.assertIn('event:FireServer("PetCompanion", pet.id)', HUD)

    def test_mobile_card_action_rows_and_profile_link_stay_inside_card(self):
        card_height = 394
        action_row_top = 258
        action_height = 36
        second_row_top = 300
        profile_top = 350
        profile_height = 30
        self.assertLess(action_row_top + action_height, second_row_top)
        self.assertLess(second_row_top + action_height, profile_top)
        self.assertLess(profile_top + profile_height, card_height)
        self.assertIn('compact and UDim2.fromOffset(12, 350)', HUD)
        self.assertIn('compact and UDim2.new(1, -24, 0, 30)', HUD)

    def test_compact_profile_hero_reserves_preview_and_text_columns_without_overflow(self):
        body_width = 280
        preview_left = 12
        preview_size = 132
        text_left = 156
        text_right_padding = 12
        self.assertLessEqual(preview_left + preview_size, text_left)
        self.assertLessEqual(text_left + 112 + text_right_padding, body_width)
        self.assertIn('compactProfile and 132 or 164', HUD)
        self.assertIn('local textX = compactProfile and 156 or 192', HUD)
        self.assertIn('UDim2.new(1, -textX - 12, 0, compactProfile and 40 or 48)', HUD)

    def test_pet_portrait_has_a_distinct_visual_plate(self):
        self.assertIn('iconPlate.Name = "IconPlate"', HUD)
        self.assertIn('corner(iconPlate, 18)', HUD)
        self.assertIn('stroke(iconPlate, palette.gold, 0.55, 1)', HUD)

    def test_open_pet_tab_rebuilds_when_screen_crosses_mobile_breakpoint(self):
        self.assertIn('local refreshActiveTab', HUD)
        self.assertIn('local lastCompactLayout', HUD)
        self.assertIn('if lastCompactLayout ~= nil and lastCompactLayout ~= compact and refreshActiveTab then', HUD)
        self.assertIn('refreshActiveTab = function()', HUD)
        self.assertIn('clearBody()\\n    renderers[activeTab]()\\n    applyPanelLayer()', HUD)


if __name__ == "__main__":
    unittest.main()
