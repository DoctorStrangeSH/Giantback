"""Contract tests for the server-authoritative daily quest board."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class DailyQuestContractTests(unittest.TestCase):
    def test_daily_quest_catalog_and_reward_are_explicit(self):
        self.assertIn("local DAILY_QUEST_REWARD = 40", WORLD)
        self.assertIn('Gather = {goal = 3', WORLD)
        self.assertIn('Sell = {goal = 3', WORLD)
        self.assertIn('Scout = {goal = 1', WORLD)

    def test_quest_day_uses_utc_and_resets_progress(self):
        self.assertIn('os.date("!%Y-%m-%d")', WORLD)
        self.assertIn('return {day = today, progress = {Gather = 0, Sell = 0, Scout = 0}, claimed = false}', WORLD)
        self.assertIn("task.wait(60)", WORLD)
        self.assertIn("syncDailyQuests(player)", WORLD)

    def test_progress_is_server_granted_by_valid_gameplay_actions(self):
        self.assertIn('addDailyQuestProgress(player, "Gather", 1, false)', WORLD)
        self.assertIn('addDailyQuestProgress(player, "Sell", totalItems)', WORLD)
        self.assertIn('addDailyQuestProgress(player, "Scout", 1)', WORLD)
        self.assertIn("addDailyQuestProgress = function(player, questId, amount, saveProgress)", WORLD)
        self.assertIn('if not session or not definition or not player:GetAttribute("Ready") then return end', WORLD)

    def test_daily_progress_is_saved_and_restored(self):
        self.assertIn("local dailyQuestSnapshot = normalizeDailyQuests(session.dailyQuests)", WORLD)
        self.assertIn("old.dailyQuests = dailyQuestSnapshot", WORLD)
        self.assertIn("session.dailyQuests = normalizeDailyQuests(data.dailyQuests)", WORLD)

    def test_claim_is_server_validated_idempotent_and_atomic(self):
        self.assertIn('if action == "ClaimDailyQuests" then', WORLD)
        self.assertIn("local function claimDailyQuestReward(player)", WORLD)
        self.assertIn("if session.dailyQuests.claimed then", WORLD)
        self.assertIn("session.dailyQuests.claimed = true", WORLD)
        self.assertIn("session.dailyQuests.claimed = false", WORLD)
        self.assertIn("MAX_COINS - previousCoins < DAILY_QUEST_REWARD", WORLD)
        self.assertIn("session.economyBusy = true", WORLD)

    def test_daily_board_is_integrated_into_existing_journal(self):
        self.assertIn("local function renderDailyQuests()", HUD)
        self.assertIn("renderDailyQuests()", HUD)
        self.assertIn('event:FireServer("ClaimDailyQuests")', HUD)
        self.assertIn("Ежедневные задания и открытия мира", HUD)
        self.assertIn("## Ежедневные задания", STUDIO)
        self.assertIn("## Ежедневные задания — первая версия", ROADMAP)


if __name__ == "__main__":
    unittest.main()
