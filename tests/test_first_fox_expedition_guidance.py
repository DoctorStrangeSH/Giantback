"""The first expedition provides actionable guidance after bridge repair."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class FirstFoxExpeditionGuidanceTests(unittest.TestCase):
    def test_fox_discovery_precedes_unavailable_cache_guidance(self):
        fox = HUD.index('if not player:GetAttribute("Fox") then\n        return "Найди лисёнка в Солнечной роще"')
        cache = HUD.index('local activeCacheId = player:GetAttribute("FoxCacheSpot")', fox)
        self.assertLess(fox, cache)
        self.assertIn('Перейди мост → найди гнездо в роще → нажми «Подружиться».', HUD)
        self.assertIn('prompt(nest,pets[id],"Подружиться",function(player)', WORLD)
        self.assertIn('encounter("Fox",workspace.Grove,1.8)', WORLD)

    def test_equipping_fox_and_following_trail_have_separate_hints(self):
        self.assertIn('Позови лисёнка из коллекции питомцев', HUD)
        self.assertIn('Открой «ПИТОМЦЫ» внизу и выбери лисёнка.', HUD)
        self.assertIn('Лисёнок нашёл тайник! Иди по золотым следам.', HUD)
        self.assertIn('Ищи золотые следы лап возле тропы в роще.', HUD)
        self.assertIn('Пройди с лисёнком по тропе рощи: ищи находку.', HUD)
        self.assertIn('player:GetAttribute("Companion") == "Fox"', HUD)

    def test_next_moth_milestone_after_first_seed(self):
        self.assertIn('if not player:GetAttribute("Seed") then', HUD)
        self.assertIn('if not player:GetAttribute("Moth") then', HUD)
        self.assertIn('По мосту из рощи иди в Сумеречную долину.', HUD)

    def test_guidance_is_client_only_and_reactive(self):
        self.assertIn('player.AttributeChanged:Connect(refresh)', HUD)
        self.assertNotIn('player:SetAttribute("Fox"', HUD)
        self.assertNotIn('player:SetAttribute("Seed"', HUD)


if __name__ == "__main__":
    unittest.main()
