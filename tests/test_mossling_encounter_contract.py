"""Contracts for Mossling's live, server-authoritative Grove encounter."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class MosslingEncounterContracts(unittest.TestCase):
    def test_spawned_in_existing_arena_and_registered_for_real_combat(self):
        self.assertIn('local function spawnMossling()', VISUALS)
        self.assertIn('mossling.Name = "GroveMossling01"', VISUALS)
        self.assertIn('mossling:SetAttribute("EncounterId", "GroveMossling01")', VISUALS)
        self.assertIn('mossling:SetAttribute("RegionId", "GroveTraining")', VISUALS)
        self.assertIn('CollectionService:RemoveTag(mossling, "GiantbackEnemy")', VISUALS)
        self.assertIn('CollectionService:AddTag(mossling, "GiantbackEnemy")', VISUALS)
        self.assertIn("    GroveMossling01 = true,", COMBAT)
        self.assertIn('GetInstanceAddedSignal("GiantbackEnemy")', COMBAT)

    def test_recognizable_telegraphed_enemy_with_capped_damage(self):
        self.assertIn('humanoid.DisplayName = "Моховичок"', VISUALS)
        self.assertIn('mossling:SetAttribute("AttackDamage", 6)', VISUALS)
        self.assertIn('mossling:SetAttribute("TelegraphSeconds", 1.15)', VISUALS)
        self.assertIn('local state = mossling:GetAttribute("CombatState")', VISUALS)
        self.assertIn('local telegraphing = state == "Telegraph" or state == "PollenTelegraph"', VISUALS)
        self.assertIn('warningText.Text = telegraphing and "УКЛОНЯЙСЯ!" or "АТАКА!"', VISUALS)
        self.assertIn('if highlight then highlight.Enabled = telegraphing end', VISUALS)
        self.assertIn('mossling:SetAttribute("AggroRange", 25)', VISUALS)
        self.assertIn('local function registerEnemy(enemy)', COMBAT)
        self.assertIn('entry.regionId == getPlayerRegion(player)', COMBAT)

    def test_one_time_authoritative_reward_and_respawn(self):
        self.assertRegex(WORLD, r'GroveMossling01 = \{itemId = "Stone", amount = 2(?:, [^}]+)?\}')
        self.assertIn('    GroveMossling01 = true,', COMBAT.split("local REWARD_ENCOUNTERS = {", 1)[1])
        self.assertIn('if session.completedCombatEncounters[encounterId] then return true end', WORLD)
        self.assertIn('session.completedCombatEncounters[encounterId] = true', WORLD)
        self.assertIn('humanoid.Died:Connect(function()', VISUALS)
        self.assertIn('task.delay(20, function()', VISUALS)
        self.assertIn('if combatGlade.Parent then spawnMossling() end', VISUALS)
        self.assertIn('rewardFunction:Invoke(contributor, entry.encounterId)', COMBAT)

    def test_reuses_current_place_builder(self):
        self.assertIn('"WorldVisuals.server.luau", "Combat.server.luau"', BUILD)


if __name__ == "__main__":
    unittest.main()
