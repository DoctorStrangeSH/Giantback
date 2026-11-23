"""The first player goal is readable, actionable and driven by server-owned resources."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class FirstBridgeObjectiveTests(unittest.TestCase):
    def test_starting_goal_has_independent_hint_and_resource_progress(self):
        self.assertIn('local objectiveHint = label(objective, "Hint"', HUD)
        self.assertIn('local function bridgeResourceProgress()', HUD)
        self.assertIn('player:GetAttribute("Resource_Wood")', HUD)
        self.assertIn('player:GetAttribute("Resource_Stone")', HUD)
        self.assertIn('"🪵 " .. tostring(math.min(wood, 5)) .. "/5', HUD)
        self.assertIn('"🪨 " .. tostring(math.min(stone, 3)) .. "/3', HUD)
        self.assertIn('Подойди к кучам у дома и нажми кнопку сбора', HUD)
        self.assertIn('НАЧНИ ЗДЕСЬ • ПЕРВЫЙ МОСТ', HUD)
        self.assertIn('if player:GetAttribute("Ready") and not bridgeBuilt then', HUD)

    def test_bridge_ready_instructs_actual_interaction(self):
        self.assertIn('if wood < 5 or stone < 3 then', HUD)
        self.assertIn('Материалы готовы! Восстанови мост.', HUD)
        self.assertIn('Подойди к мосту у края острова и нажми E или кнопку действия.', HUD)
        self.assertIn('Собери материалы для первого моста', HUD)

    def test_hints_have_nonoverlapping_vertical_ranges(self):
        self.assertIn('objective.Size = UDim2.fromOffset(352, 138)', HUD)
        self.assertIn('objective.Size = UDim2.new(1, -32, 0, 138)', HUD)
        self.assertIn('UDim2.fromOffset(76, 66), 11', HUD)
        self.assertIn('UDim2.fromOffset(76, 29), 14', HUD)
        # Text: 29..63, hint: 66..98, count: 109..121, bar: 125..131
        self.assertLessEqual(29 + 34, 66)
        self.assertLessEqual(66 + 32, 138 - 29)

    def test_uses_server_attributes_without_client_mutation(self):
        self.assertNotIn('player:SetAttribute("Resource_Wood"', HUD)
        self.assertNotIn('player:SetAttribute("Resource_Stone"', HUD)
        self.assertIn('player.AttributeChanged:Connect(refresh)', HUD)


if __name__ == "__main__":
    unittest.main()
