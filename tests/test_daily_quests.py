"""Contract tests for the rotating, server-authoritative daily quest board."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class DailyQuestContractTests(unittest.TestCase):
    def test_pool_has_twelve_explicit_quest_definitions(self):
        block = WORLD.split("local DAILY_QUEST_DEFINITIONS = {", 1)[1].split("\n}", 1)[0]
        self.assertEqual(block.count(" = {goal = "), 12)
        for quest_id in (
            "Gather", "GatherWood", "GatherStone", "Plant", "Harvest", "Sell",
            "Scout", "Feed", "Play", "CraftSword", "UpgradeTool", "WinEncounter",
        ):
            self.assertIn(quest_id + " = {goal = ", block)
        self.assertIn("local DAILY_QUEST_COUNT = 3", WORLD)

    def test_daily_selection_is_stable_per_player_and_utc_day(self):
        self.assertIn('os.date("!%Y-%m-%d")', WORLD)
        self.assertIn("getEligibleDailyQuestIds(player, session)", WORLD)
        self.assertIn("Random.new(seed)", WORLD)
        self.assertIn("random:NextInteger(1, index)", WORLD)
        self.assertIn("version = 3", WORLD)
        self.assertIn("quests = selected", WORLD)

    def test_locked_content_is_excluded_from_the_daily_pool(self):
        self.assertIn('if player:GetAttribute("Fox") == true then table.insert(eligible, "Scout") end', WORLD)
        self.assertIn("if ownsCompanion then", WORLD)
        self.assertIn("if session.tools.Axe == true then", WORLD)
        self.assertIn("if session.tools.Pickaxe == true then", WORLD)
        self.assertIn("if session.tools.Sword == true then", WORLD)

    def test_progress_is_server_granted_by_successful_gameplay(self):
        markers = [
            'addDailyQuestProgress(player, "Gather", 1, false)',
            'addDailyQuestProgress(player, "GatherWood", rewardAmount, false)',
            'addDailyQuestProgress(player, "GatherStone", rewardAmount, false)',
            'addDailyQuestProgress(player, "Plant", 1, false)',
            'addDailyQuestProgress(player, "Harvest", definition.reward, false)',
            'addDailyQuestProgress(player, "Sell", totalItems)',
            'addDailyQuestProgress(player, "Scout", 1)',
            'addDailyQuestProgress(player, "Feed", 1, false)',
            'addDailyQuestProgress(player, "Play", 1, false)',
            'addDailyQuestProgress(player, "CraftSword", 1, false)',
            'addDailyQuestProgress(player, "UpgradeTool", 1, false)',
            'addDailyQuestProgress(player, "WinEncounter", 1)',
        ]
        for marker in markers:
            self.assertIn(marker, WORLD)
        self.assertIn("not table.find(session.dailyQuests.quests, questId)", WORLD)

    def test_daily_quest_selection_progress_and_claim_are_persisted(self):
        self.assertIn("local dailyQuestSnapshot = normalizeDailyQuests(session.dailyQuests, player, session)", WORLD)
        self.assertIn("old.dailyQuests = dailyQuestSnapshot", WORLD)
        self.assertIn("session.dailyQuests = data.dailyQuests", WORLD)
        self.assertIn("session.dailyQuests.claimed = true", WORLD)
        self.assertIn("session.dailyQuests.claimed = false", WORLD)
        self.assertIn("MAX_COINS - previousCoins < credited", WORLD)

    def test_journal_renders_server_selected_quest_cards(self):
        self.assertIn("local function renderDailyQuests()", HUD)
        self.assertIn('player:GetAttribute(prefix .. "Title")', HUD)
        self.assertIn('player:GetAttribute(prefix .. "Progress")', HUD)
        self.assertIn('event:FireServer("ClaimDailyQuests")', HUD)
        self.assertIn("Ежедневные задания и открытия мира", HUD)

    def test_daily_quests_have_tiered_rewards(self):
        self.assertIn('difficulty = "easy", reward = 10', WORLD)
        self.assertIn('difficulty = "medium", reward = 15', WORLD)
        self.assertIn('difficulty = "hard", reward = 20', WORLD)
        self.assertIn("local function getDailyQuestBaseReward(dailyQuests)", WORLD)
        self.assertIn('player:SetAttribute("DailyQuest_Reward", getDailyQuestBaseReward(session.dailyQuests))', WORLD)

    def test_daily_selection_balances_tiers_and_avoids_duplicate_categories(self):
        self.assertIn("local buckets = {easy = {}, medium = {}, hard = {}}", WORLD)
        self.assertIn("local selectedCategories = {}", WORLD)
        self.assertIn("pickFromBucket(buckets[difficulty])", WORLD)
        self.assertIn('for _, difficulty in {"medium", "easy", "hard"} do', WORLD)
        self.assertIn('local totalReward = reward + streakBonusToday', HUD)

    def test_journal_shows_difficulty_and_individual_rewards(self):
        self.assertIn('player:GetAttribute(prefix .. "Reward")', HUD)
        self.assertIn('player:GetAttribute(prefix .. "Difficulty")', HUD)
        self.assertIn('difficultyNames = {easy = "ЛЕГКО", medium = "СРЕДНЕ", hard = "СЛОЖНО"}', HUD)

    def test_streak_is_saved_across_daily_rollover(self):
        self.assertIn("streak = streak", WORLD)
        self.assertIn("bestStreak = bestStreak", WORLD)
        self.assertIn("lastCompletedDay = lastCompletedDay", WORLD)
        self.assertIn("version = 3", WORLD)
        self.assertIn('os.date("!%Y-%m-%d", os.time() - 86400)', WORLD)

    def test_streak_bonuses_are_only_three_day_and_seven_day_milestones(self):
        self.assertIn("local DAILY_STREAK_THREE_BONUS = 20", WORLD)
        self.assertIn("local DAILY_STREAK_WEEK_BONUS = 60", WORLD)
        self.assertIn("nextStreak == 3 and DAILY_STREAK_THREE_BONUS", WORLD)
        self.assertIn("nextStreak % 7 == 0 and DAILY_STREAK_WEEK_BONUS", WORLD)
        self.assertIn("local baseReward = getDailyQuestBaseReward(session.dailyQuests)", WORLD)
        self.assertIn("local credited = baseReward + streakBonus", WORLD)

    def test_streak_and_coins_roll_back_together_on_save_failure(self):
        self.assertIn("session.dailyQuests.streak = previousStreak", WORLD)
        self.assertIn("session.dailyQuests.bestStreak = previousBestStreak", WORLD)
        self.assertIn("session.dailyQuests.lastCompletedDay = previousCompletedDay", WORLD)
        self.assertIn("session.coins = previousCoins", WORLD)

    def test_journal_displays_current_and_best_streak(self):
        self.assertIn('player:GetAttribute("DailyQuest_Streak")', HUD)
        self.assertIn('player:GetAttribute("DailyQuest_BestStreak")', HUD)
        self.assertIn('player:GetAttribute("DailyQuest_StreakBonusToday")', HUD)
        self.assertIn('addInfo("СЕРИЯ ЗАДАНИЙ"', HUD)

    def test_studio_acceptance_checklist_covers_rotation_and_unlocks(self):
        self.assertIn("## Ежедневные задания 2.0", STUDIO)
        self.assertIn("## Ежедневные задания 2.0", ROADMAP)
        self.assertIn("## Серия ежедневных заданий", STUDIO)


if __name__ == "__main__":
    unittest.main()
