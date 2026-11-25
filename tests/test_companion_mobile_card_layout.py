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

    def test_pet_portrait_has_a_distinct_visual_plate(self):
        self.assertIn('iconPlate.Name = "IconPlate"', HUD)
        self.assertIn('corner(iconPlate, 18)', HUD)
        self.assertIn('stroke(iconPlate, palette.gold, 0.55, 1)', HUD)

    def test_open_pet_tab_rebuilds_when_screen_crosses_mobile_breakpoint(self):
        self.assertIn('local refreshActiveTab', HUD)
        self.assertIn('local lastCompactLayout', HUD)
        self.assertIn('if lastCompactLayout ~= nil and lastCompactLayout ~= compact and refreshActiveTab then', HUD)
        self.assertIn('refreshActiveTab = function()', HUD)
        self.assertIn('clearBody()\n    renderers[activeTab]()\n    applyPanelLayer()', HUD)


if __name__ == "__main__":
    unittest.main()
