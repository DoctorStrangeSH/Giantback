from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
CI = (ROOT / ".github/workflows/validate-place.yml").read_text(encoding="utf-8")


class CompanionProgressionContractTests(unittest.TestCase):
    def test_companion_progression_is_versioned_and_persisted(self):
        self.assertIn("COMPANION_MAX_LEVEL = 5", WORLD)
        self.assertIn("old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 11)", WORLD)
        self.assertIn("local companionProgressSnapshot = normalizeCompanionProgress(session.companionProgress)", WORLD)
        self.assertIn('local savedCompanions = type(old.companions) == "table" and old.companions or {}', WORLD)
        self.assertIn("savedCompanion = companionProgressSnapshot[companionId]", WORLD)
        self.assertIn("savedCompanions[companionId] = savedCompanion", WORLD)
        self.assertIn("session.companionProgress = normalizeCompanionProgress(data.companions)", WORLD)

    def test_companion_xp_is_bounded_and_levels_have_increasing_thresholds(self):
        self.assertIn("return 100 + math.max(0, level - 1) * 75", WORLD)
        self.assertIn("amount = math.clamp(math.floor(tonumber(amount) or 0), 0, 100)", WORLD)
        self.assertIn("while progressData.level < COMPANION_MAX_LEVEL do", WORLD)
        self.assertIn("if progressData.level >= COMPANION_MAX_LEVEL then progressData.xp = 0 end", WORLD)

    def test_progression_requires_owned_companion_and_only_accepts_known_ids(self):
        self.assertIn('if table.find(COMPANION_IDS, companionId) == nil then return false, "InvalidCompanion" end', WORLD)
        self.assertIn('player:GetAttribute(companionId) ~= true', WORLD)
        self.assertIn('if not session or not player:GetAttribute("Ready")', WORLD)
        self.assertIn('companionXpFunction.OnInvoke = function(player, companionId, amount)', WORLD)
        self.assertIn('companionXpFunction.Name = "GiantbackGrantCompanionXP"', WORLD)

    def test_progression_attributes_sync_to_the_collection_ui(self):
        for attribute in ("_Level", "_XP", "_XPToNext"):
            self.assertIn('player:SetAttribute("Companion_" .. id .. "' + attribute + '",', WORLD)
        self.assertIn('player:GetAttribute("Companion_" .. id .. "_Level")', ALBUM)
        self.assertIn('player:GetAttribute("Companion_" .. id .. "_XP")', ALBUM)
        self.assertIn('player:GetAttribute("Companion_" .. id .. "_XPToNext")', ALBUM)
        self.assertIn('entry.xpFill.Size = UDim2.fromScale', ALBUM)
        self.assertIn('ВЗРОСЛЫЙ · УР. 5 · МАКСИМУМ', ALBUM)

    def test_verified_exploration_milestones_award_the_matching_companion(self):
        self.assertIn('awardCompanionXp(player, "Fox", 30)', WORLD)
        self.assertIn('awardCompanionXp(player, "Fox", 20)', WORLD)
        self.assertIn('awardCompanionXp(player, "Moth", 25)', WORLD)
        self.assertIn('awardCompanionXp(player, "Moth", 35)', WORLD)

    def test_combat_abilities_scale_with_level_and_award_server_side_xp(self):
        self.assertIn("FOX_SKILL_DAMAGE_PER_LEVEL = 3", COMBAT)
        self.assertIn("MOTH_HEAL_PER_LEVEL = 2", COMBAT)
        self.assertIn('player:GetAttribute("Companion_Fox_Level")', COMBAT)
        self.assertIn('player:GetAttribute("Companion_Moth_Level")', COMBAT)
        self.assertIn('companionXpFunction:Invoke(player, "Fox", 12)', COMBAT)
        self.assertIn('companionXpFunction:Invoke(player, "Moth", xpReward)', COMBAT)
        self.assertIn("local xpReward = math.min(24, #healedPlayers * 6)", COMBAT)

    def test_combat_cooldown_is_committed_before_async_progression_write(self):
        skill_start = COMBAT.index("local function performCompanionSkill")
        fox_start = COMBAT.index('if companionId == "Fox" then', skill_start)
        fox_cooldown = COMBAT.index("state.companionSkillReadyAt = now + COMPANION_SKILL_COOLDOWN", fox_start)
        fox_xp_spawn = COMBAT.index("task.spawn(function()", fox_cooldown)
        self.assertLess(fox_cooldown, fox_xp_spawn)
        moth_start = COMBAT.index("local companionLevel = math.clamp", fox_xp_spawn)
        moth_cooldown = COMBAT.index("state.companionSkillReadyAt = now + COMPANION_SKILL_COOLDOWN", moth_start)
        moth_xp_spawn = COMBAT.index("task.spawn(function()", moth_cooldown)
        self.assertLess(moth_cooldown, moth_xp_spawn)

    def test_level_three_and_five_unlock_server_side_passive_talents(self):
        self.assertIn("local function foxScoutCooldownForLevel(level)", WORLD)
        self.assertIn("if level >= 5 then return 60 end", WORLD)
        self.assertIn("if level >= 3 then return 90 end", WORLD)
        self.assertIn("session.foxSearchReadyAt = os.time() + foxScoutCooldownForLevel(foxLevel)", WORLD)
        self.assertIn("local healRadius = MOTH_HEAL_RADIUS + (companionLevel >= 5 and 4 or companionLevel >= 3 and 2 or 0)", COMBAT)
        self.assertIn("Magnitude <= healRadius", COMBAT)
        self.assertIn("healRadius = healRadius", COMBAT)
        self.assertIn("Острый нюх: поиск каждые 60 сек.", ALBUM)
        self.assertIn("Чуткий нюх: поиск каждые 90 сек.", ALBUM)
        self.assertIn("Лунная аура: радиус лечения +4.", ALBUM)
        self.assertIn("Лунная аура: радиус лечения +2.", ALBUM)

    def test_ci_checks_companion_progression_contract(self):
        for marker in (
            "GiantbackGrantCompanionXP",
            "COMPANION_MAX_LEVEL = 5",
            "normalizeCompanionProgress",
            "Companion_Fox_Level",
            "Companion_Moth_Level",
            "FOX_SKILL_DAMAGE_PER_LEVEL = 3",
            "MOTH_HEAL_PER_LEVEL = 2",
            "FeedCompanion",
            'player:SetAttribute("Companion_" .. id .. "_Bond"',
            "УР. 5 · МАКСИМУМ",
        ):
            self.assertIn(marker, CI)


if __name__ == "__main__":
    unittest.main()
