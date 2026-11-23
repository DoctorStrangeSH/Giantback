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

    def test_harvest_festival_uses_a_recurring_utc_window(self):
        self.assertIn('DateTime.fromUniversalTime(year, 11, 23, 0, 0, 0)', WORLD)
        self.assertIn('DateTime.fromUniversalTime(year, 12, 8, 0, 0, 0)', WORLD)
        self.assertIn('id = "harvest-festival-" .. tostring(year)', WORLD)
        self.assertIn("local function normalizeSeasonalEvent(raw)", WORLD)
        self.assertIn("local function syncSeasonalEvent(player)", WORLD)

    def test_seasonal_event_points_only_follow_server_validated_gameplay_actions(self):
        for marker in (
            "Gather = 1", "GatherWood = 2", "GatherStone = 2",
            "Plant = 1", "Harvest = 2", "Sell = 2", "Scout = 3",
            "Feed = 2", "Play = 3", "CraftSword = 4",
            "UpgradeTool = 4", "WinEncounter = 5",
        ):
            self.assertIn(marker, WORLD)
        self.assertIn("local seasonalChanged = addSeasonalEventProgress(player, questId, amount)", WORLD)
        self.assertIn("if (weeklyChanged or seasonalChanged)", WORLD)

    def test_seasonal_event_milestones_and_rewards_are_atomic(self):
        self.assertIn("{points = 20, coins = 30, starShards = 0}", WORLD)
        self.assertIn("{points = 50, coins = 0, starShards = 1}", WORLD)
        self.assertIn("{points = 100, coins = 80, starShards = 2}", WORLD)
        self.assertIn("local function claimSeasonalEventRewards(player)", WORLD)
        self.assertIn("local previousClaims = table.clone(session.seasonalEvent.claimedMilestones)", WORLD)
        self.assertIn("session.seasonalEvent.claimedMilestones = previousClaims", WORLD)
        self.assertIn('if action == "ClaimSeasonalEventRewards" then', WORLD)

    def test_seasonal_event_progress_persists_and_migrates_profile(self):
        self.assertIn("local seasonalEventSnapshot = normalizeSeasonalEvent(session.seasonalEvent)", WORLD)
        self.assertIn("old.seasonalEvent = seasonalEventSnapshot", WORLD)
        self.assertIn("session.seasonalEvent = data.seasonalEvent", WORLD)
        self.assertIn("old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 14)", WORLD)

    def test_journal_displays_harvest_festival_track_and_claim_button(self):
        self.assertIn('player:GetAttribute("SeasonalEvent_Active")', HUD)
        self.assertIn('player:GetAttribute("SeasonalEvent_Points")', HUD)
        self.assertIn('button(body, "ClaimSeasonalEventRewards"', HUD)
        self.assertIn('event:FireServer("ClaimSeasonalEventRewards")', HUD)
        self.assertIn('addInfo("СЕЗОННОЕ СОБЫТИЕ • " .. eventStatus', HUD)

    def test_weekly_challenges_rotate_and_persist_by_utc_week(self):
        self.assertIn('os.date("!%Y-%W")', WORLD)
        self.assertIn("local function normalizeWeeklyChallenges(raw, player, session)", WORLD)
        self.assertIn("Random.new((math.abs(player.UserId) % 1000003 + weekSeed) % 2147483647)", WORLD)
        self.assertIn("weeklyChallenges = nil", WORLD)
        self.assertIn("session.weeklyChallenges = data.weeklyChallenges", WORLD)
        self.assertIn("old.weeklyChallenges = weeklyChallengeSnapshot", WORLD)
        self.assertIn("old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 13)", WORLD)

    def test_weekly_progress_tracks_server_gameplay_events(self):
        for marker in (
            'Gather = "Gather"', 'Plant = "Farm"', 'Harvest = "Farm"',
            'Sell = "Market"', 'Scout = "Explore"', 'Feed = "Companion"',
            'Play = "Companion"', 'WinEncounter = "Combat"',
        ):
            self.assertIn(marker, WORLD)
        self.assertIn("local weeklyChanged = addWeeklyChallengeProgress(player, questId, amount)", WORLD)
        self.assertIn("syncWeeklyChallenges(player)", WORLD)

    def test_weekly_progress_is_saved_even_when_daily_goal_is_already_complete(self):
        self.assertIn("if nextValue == previous then", WORLD)
        self.assertIn("if weeklyChanged and saveProgress ~= false and session.online and not save(player) then", WORLD)

    def test_weekly_reward_is_atomic_and_includes_star_shard(self):
        self.assertIn("local function claimWeeklyChallenges(player)", WORLD)
        self.assertIn('session.inventory.StarShard = previousStarShards + 1', WORLD)
        self.assertIn('session.weeklyChallenges.claimed = true', WORLD)
        self.assertIn('session.weeklyChallenges.claimed = false', WORLD)
        self.assertIn('session.inventory.StarShard = previousStarShards', WORLD)
        self.assertIn('if action == "ClaimWeeklyChallenges" then', WORLD)

    def test_journal_displays_weekly_challenges_and_chest(self):
        self.assertIn('player:GetAttribute("WeeklyChallenge_Week")', HUD)
        self.assertIn('player:GetAttribute(prefix .. "Progress")', HUD)
        self.assertIn('button(body, "ClaimWeeklyChallenges"', HUD)
        self.assertIn('event:FireServer("ClaimWeeklyChallenges")', HUD)
        self.assertIn('addInfo("НЕДЕЛЬНЫЕ ИСПЫТАНИЯ"', HUD)

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
