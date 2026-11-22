from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class TutorialProgressHudTests(unittest.TestCase):
    def test_objective_card_shows_numbered_adventure_progress(self):
        self.assertIn("local tutorialMilestones = {", HUD)
        self.assertIn('{key = "Fox", title = "Знакомство с лисёнком"}', HUD)
        self.assertIn('{key = "MoonGateOpen", title = "Открытие тайного прохода"}', HUD)
        self.assertIn('{key = "Lit", title = "Пробуждение фонаря"}', HUD)
        self.assertIn('("ПУТЕШЕСТВИЕ • ШАГ " .. tostring(completed + 1) .. " ИЗ " .. tostring(total))', HUD)
        self.assertIn("objectiveGlyph.Text = completed >= total and", HUD)

    def test_progress_uses_existing_server_attributes_without_client_mutation(self):
        self.assertIn('player:GetAttribute(milestone.key) == true', HUD)
        self.assertNotIn('player:SetAttribute(milestone.key', HUD)
        self.assertIn("local completed, total = getTutorialProgress()", HUD)


if __name__ == "__main__":
    unittest.main()
