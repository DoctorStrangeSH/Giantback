"""Contracts for server-confirmed combat damage feedback in the playable place."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SERVER = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CombatHitFeedbackContracts(unittest.TestCase):
    def test_normal_combo_reports_actual_damage_not_requested_damage(self):
        combo = SERVER.split('local function performAttack(player, state, now)', 1)[1].split('local function performChargedAttack', 1)[0]
        self.assertIn('local healthBefore = entry.humanoid.Health', combo)
        self.assertIn('local damageDealt = math.max(0, math.floor(healthBefore - entry.humanoid.Health + 0.5))', combo)
        self.assertIn('damage = damageDealt', combo)
        self.assertIn('health = math.max(0, entry.humanoid.Health)', combo)
        self.assertIn('maxHealth = entry.humanoid.MaxHealth', combo)

    def test_charged_attack_reports_actual_damage_and_health(self):
        charge = SERVER.split('local function performChargedAttack(player, state, now)', 1)[1].split('local function performCompanionSkill', 1)[0]
        self.assertIn('local healthBefore = entry.humanoid.Health', charge)
        self.assertIn('damage = damageDealt', charge)
        self.assertIn('health = math.max(0, entry.humanoid.Health)', charge)
        self.assertIn('maxHealth = entry.humanoid.MaxHealth', charge)

    def test_damage_feedback_uses_only_server_hit_payload_and_is_local_cosmetic(self):
        self.assertIn('showDamageNumber(data.enemyId, data.damage, data.finisher == true, data.charged == true)', CLIENT)
        self.assertIn('local function showDamageNumber(enemyId, damage, finisher, charged)', CLIENT)
        self.assertIn('findEnemyRoot(enemyId)', CLIENT)
        self.assertIn('text.Text = amount > 0 and ("-" .. tostring(amount)) or "УДАР"', CLIENT)
        self.assertIn('flash.Name = "LocalCombatHitFlash"', CLIENT)
        self.assertIn('TweenService:Create(billboard', CLIENT)
        self.assertIn('task.delay(0.68, function()', CLIENT)
        self.assertIn('"Combat.client.luau"', BUILD)
        self.assertIn('"Combat.server.luau"', BUILD)


if __name__ == "__main__":
    unittest.main()
