"""Backpack grouping and mobile equipment card layout contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class EquipmentInventoryLayoutTests(unittest.TestCase):
    def test_tools_tab_is_presented_as_a_categorized_backpack(self):
        self.assertIn('Tools = {"МОЙ РЮКЗАК", "Ресурсы, находки и снаряжение путешественника"}', HUD)
        self.assertIn('{id = "Tools", title = "Сумка", icon = "backpack"}', HUD)
        self.assertIn('addInfo("Твой рюкзак"', HUD)
        self.assertIn('addInfo("Материалы"', HUD)
        self.assertIn('addInfo("Семена и урожай"', HUD)
        self.assertIn('addInfo("Редкие находки"', HUD)

    def test_backpack_summaries_use_live_player_resource_attributes(self):
        for attribute in (
            "Resource_Wood", "Resource_Stone", "Resource_IronOre", "Resource_IronIngot",
            "Resource_MoonSeed", "Resource_StarShard", "Resource_SunPetal", "Resource_MoonPetal",
        ):
            self.assertIn('player:GetAttribute("' + attribute + '")', HUD)
        self.assertIn('player:GetAttribute("Resource_" .. crop.seed)', HUD)
        self.assertIn('player:GetAttribute("Resource_" .. crop.id)', HUD)

    def test_tool_cards_reflow_actions_below_details_on_mobile(self):
        self.assertIn('local compact = gui.AbsoluteSize.X < 620', HUD)
        self.assertIn('compact and 160 or 106', HUD)
        self.assertIn('local actionSize = compact and UDim2.new(0.5, -18, 0, 42)', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 110)', HUD)
        self.assertIn('compact and UDim2.new(0.5, 6, 0, 110)', HUD)
        self.assertIn('nameLabel.TextWrapped = true', HUD)
        self.assertIn('detailsLabel.TextWrapped = true', HUD)

    def test_sword_actions_keep_existing_server_events_and_fit_mobile_card(self):
        self.assertIn('compact and 172 or 124', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 122)', HUD)
        self.assertIn('compact and UDim2.new(0.5, 6, 0, 122)', HUD)
        self.assertIn('event:FireServer("EquipTool", "Sword")', HUD)
        self.assertIn('event:FireServer("CraftSword")', HUD)
        self.assertIn('event:FireServer("EquipTool", definition.id)', HUD)
        self.assertIn('event:FireServer("UpgradeTool", definition.id)', HUD)


if __name__ == "__main__":
    unittest.main()
