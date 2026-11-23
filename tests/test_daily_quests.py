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
        self.assertIn("local DAILY_QUEST_REWARD = 40", WORLD)

    def test_daily_selection_is_stable_per_player_and_utc_day(self):
        self.assertIn('os.date("!%Y-%m-%d")', WORLD)
        self.assertIn("getEligibleDailyQuestIds(player, session)", WORLD)
        self.assertIn("Random.new(seed)", WORLD)
        self.assertIn("random:NextInteger(1, index)", WORLD)
        self.assertIn("version = 2", WORLD)
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
        self.assertIn("MAX_COINS - previousCoins < DAILY_QUEST_REWARD", WORLD)

    def test_journal_renders_server_selected_quest_cards(self):
        self.assertIn("local function renderDailyQuests()", HUD)
        self.assertIn('player:GetAttribute(prefix .. "Title")', HUD)
        self.assertIn('player:GetAttribute(prefix .. "Progress")', HUD)
        self.assertIn('event:FireServer("ClaimDailyQuests")', HUD)
        self.assertIn("Ежедневные задания и открытия мира", HUD)

    def test_studio_acceptance_checklist_covers_rotation_and_unlocks(self):
        self.assertIn("## Ежедневные задания 2.0", STUDIO)
        self.assertIn("## Ежедневные задания 2.0", ROADMAP)


if __name__ == "__main__":
    unittest.main()
