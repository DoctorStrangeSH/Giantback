"""Checks that the craftable sword animates only on accepted server combat actions."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SERVER = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class SwordCombatVisualContracts(unittest.TestCase):
    def test_combos_emit_only_after_server_cooldown_and_validation(self):
        combo = SERVER.split('local function performAttack(player, state, now)', 1)[1].split('local function performChargedAttack', 1)[0]
        self.assertLess(combo.index('if now < state.attackReadyAt then'), combo.index('remote:FireClient(player, "CombatSwing"'))
        self.assertLess(combo.index('state.comboStep = state.comboStep % #COMBO_DAMAGE + 1'), combo.index('remote:FireClient(player, "CombatSwing"'))
        self.assertIn('remote:FireClient(player, "CombatSwing", {comboStep = comboStep, charged = false})', combo)
        self.assertIn('dealEnemyDamage(enemy, entry, COMBO_DAMAGE[comboStep])', combo)

    def test_charged_swing_emits_after_charge_validation(self):
        charge = SERVER.split('local function performChargedAttack(player, state, now)', 1)[1].split('local function performCompanionSkill', 1)[0]
        self.assertLess(charge.index('if chargeSeconds < CHARGE_MIN_SECONDS then'), charge.index('remote:FireClient(player, "CombatSwing"'))
        self.assertLess(charge.index('if now < state.attackReadyAt then'), charge.index('remote:FireClient(player, "CombatSwing"'))
        self.assertIn('remote:FireClient(player, "CombatSwing", {charged = true})', charge)

    def test_visuals_require_equipped_player_owned_real_sword(self):
        self.assertIn('local sword = character:FindFirstChild("Меч странника")', CLIENT)
        self.assertIn('sword:GetAttribute("PetKingdomsToolId") ~= "Sword"', CLIENT)
        self.assertIn('sword.Parent ~= character', CLIENT)
        self.assertIn('TweenService:Create(sword, TweenInfo.new(', CLIENT)
        self.assertIn('{Grip = windupGrip}', CLIENT)
        self.assertIn('{Grip = strikeGrip}', CLIENT)
        self.assertIn('{Grip = restGrip}', CLIENT)
        self.assertIn('swordRestGrips = setmetatable({}, {__mode = "k"})', CLIENT)
        self.assertIn('player.CharacterRemoving:Connect(clearSwordSwing)', CLIENT)
        self.assertIn('if message == "CombatSwing" then', CLIENT)

    def test_real_sword_and_live_place_are_still_present(self):
        self.assertIn('createToolPart(tool, "SwordBlade"', WORLD)
        self.assertIn('toolId == "Sword" and "Меч странника"', WORLD)
        self.assertIn('if action == "CraftSword" then', WORLD)
        self.assertIn('"Combat.server.luau"', BUILD)
        self.assertIn('"Combat.client.luau"', BUILD)


if __name__ == "__main__":
    unittest.main()
