from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CompanionGrowthContractTests(unittest.TestCase):
    def test_growth_stages_are_bounded_and_level_gated(self):
        self.assertIn("local function companionGrowthForLevel(level)", ALBUM)
        self.assertIn('return "Взрослый", 1.1, 3', ALBUM)
        self.assertIn('return "Подросток", 1, 2', ALBUM)
        self.assertIn('return "Малыш", 0.9, 1', ALBUM)
        self.assertIn("level = math.clamp(math.floor(tonumber(level) or 1), 1, 5)", ALBUM)

    def test_world_companion_models_apply_and_refresh_growth_scale(self):
        self.assertIn("local function applyCompanionGrowth(model, owner, companionId)", ALBUM)
        self.assertIn('model:GetAttribute("AppliedGrowthStage") == stageId', ALBUM)
        self.assertIn("model:ScaleTo(scale)", ALBUM)
        self.assertIn("local currentState = animationStates[model]", ALBUM)
        self.assertIn("part.CFrame = pivot * offset", ALBUM)
        self.assertIn('model:SetAttribute("GrowthStageName", stageName)', ALBUM)
        self.assertIn("captureAnimation(model, companionId, false, owner == player)", ALBUM)
        self.assertIn("applyCompanionGrowth(model, owner, id)", ALBUM)

    def test_growth_stage_changes_companion_motion_without_gameplay_effects(self):
        self.assertIn('local growthStage = math.clamp(math.floor(tonumber(model:GetAttribute("AppliedGrowthStage")) or 1), 1, 3)', ALBUM)
        self.assertIn('local growthSway = ({[1] = 0.82, [2] = 1, [3] = 1.22})[growthStage]', ALBUM)
        self.assertIn('local growthStride = ({[1] = 0.82, [2] = 1, [3] = 1.12})[growthStage]', ALBUM)
        self.assertIn('local growthFlap = ({[1] = 0.88, [2] = 1, [3] = 1.16})[growthStage]', ALBUM)
        self.assertIn('local adultGlow = growthStage == 3 and 1.18', ALBUM)
        self.assertNotIn("GrowthDamage", ALBUM)
        self.assertNotIn("GrowthReward", ALBUM)

    def test_collection_cards_show_the_matching_growth_stage(self):
        self.assertIn('companionLevel >= 5 and "ВЗРОСЛЫЙ"', HUD)
        self.assertIn('companionLevel >= 3 and "ПОДРОСТОК"', HUD)
        self.assertIn('"МАЛЫШ"', HUD)
        self.assertIn('companionLevel >= 5 and "УР. 5 · МАКСИМУМ"', HUD)
        self.assertIn('growthStage .. " · " .. levelText .. mutationText', HUD)


if __name__ == "__main__":
    unittest.main()
