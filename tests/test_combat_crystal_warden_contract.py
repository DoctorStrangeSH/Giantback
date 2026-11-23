"""Source contracts for the Crystal Warden encounter in the Crystal Grotto."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class CrystalWardenEncounterTests(unittest.TestCase):
    def test_grotto_is_registered_as_an_isolated_combat_region(self):
        self.assertIn("CrystalGrotto = true", COMBAT.split("local ALLOWED_REGIONS", 1)[1].split("\n", 1)[0])
        self.assertIn('local grottoCombatRegion = makePart(', VISUALS)
        self.assertIn('"CrystalGrottoCombatRegion"', VISUALS)
        self.assertIn('grottoCombatRegion:SetAttribute("RegionId", "CrystalGrotto")', VISUALS)
        self.assertIn('CollectionService:AddTag(grottoCombatRegion, "GiantbackCombatRegion")', VISUALS)

    def test_warden_is_a_real_tagged_enemy_with_distinct_crystal_model(self):
        self.assertIn('warden.Name = "CrystalGrottoWarden01"', VISUALS)
        self.assertIn('warden:SetAttribute("EncounterId", "CrystalGrottoWarden01")', VISUALS)
        self.assertIn('warden:SetAttribute("ArchetypeId", "CrystalWarden")', VISUALS)
        self.assertIn('humanoid.DisplayName = "Кристальный страж"', VISUALS)
        self.assertIn("humanoid.MaxHealth = 130", VISUALS)
        self.assertIn('addWardenCrystal("Warden prism core"', VISUALS)
        self.assertIn('"Crown crystal " .. tostring(index)', VISUALS)
        self.assertIn('CollectionService:AddTag(warden, "GiantbackEnemy")', VISUALS)
        self.assertIn("if crystalGrotto.Parent then spawnCrystalWarden() end", VISUALS)

    def test_server_accepts_and_rewards_the_grotto_encounter(self):
        self.assertIn("CrystalGrottoWarden01 = true", COMBAT.split("local KNOWN_ENCOUNTERS", 1)[1].split("local REWARD_ENCOUNTERS", 1)[0])
        self.assertIn("CrystalGrottoWarden01 = true", COMBAT.split("local REWARD_ENCOUNTERS", 1)[1].split("local remote", 1)[0])
        self.assertIn('CrystalGrottoWarden01 = {itemId = "CrystalShard", amount = 2, coins = 15}', WORLD)

    def test_crystal_fan_is_a_frontal_cone_with_server_authoritative_damage(self):
        self.assertIn('local useCrystalFan = enemy:GetAttribute("ArchetypeId") == "CrystalWarden"', COMBAT)
        self.assertIn('enemy:SetAttribute("BossAttack", "CrystalFan")', COMBAT)
        self.assertIn('enemy:SetAttribute("CombatState", "CrystalFanTelegraph")', COMBAT)
        self.assertIn('math.clamp(tonumber(enemy:GetAttribute("CrystalFanRange")) or 16, 10, 22)', COMBAT)
        self.assertIn('math.clamp(math.floor(tonumber(enemy:GetAttribute("CrystalFanDamage")) or 16), 1, 24)', COMBAT)
        self.assertIn('attackDirection:Dot(offset.Unit) >= fanDot', COMBAT)
        self.assertIn('currentHumanoid:TakeDamage(damage)', COMBAT)

    def test_crystal_fan_respects_dodge_and_directional_block(self):
        branch = COMBAT.split("elseif useCrystalFan then", 1)[1].split('\n                    else\n                        enemy:SetAttribute("CombatState", "Telegraph")', 1)[0]
        self.assertIn('local dodging = playerState and playerState.dodgingUntil > os.clock()', branch)
        self.assertIn("if not dodging then", branch)
        self.assertIn("playerState.blocking", branch)
        self.assertIn("BLOCK_DAMAGE_MULTIPLIER", branch)
        self.assertIn('currentRoot.CFrame.LookVector:Dot(towardWarden.Unit) >= 0.35', branch)
        self.assertIn('getPlayerRegion(player) == entry.regionId', branch)

    def test_client_shows_three_directional_warning_lines_and_windup_pose(self):
        self.assertIn("local function showCrystalFanTelegraph(enemy)", CLIENT)
        self.assertIn('markerFolder.Name = "LocalCrystalFanTelegraph"', CLIENT)
        self.assertIn("for _, angle in {-38, 0, 38} do", CLIENT)
        self.assertIn('attack == "CrystalFan" and isCrystalWarden', CLIENT)
        self.assertIn('state == "CrystalFanTelegraph"', CLIENT)


    def test_shardling_is_a_distinct_live_enemy_with_one_time_reward(self):
        self.assertIn("CrystalGrottoShardling01 = true", COMBAT.split("local KNOWN_ENCOUNTERS", 1)[1].split("local REWARD_ENCOUNTERS", 1)[0])
        self.assertIn("CrystalGrottoShardling01 = true", COMBAT.split("local REWARD_ENCOUNTERS", 1)[1].split("local remote", 1)[0])
        self.assertIn('shardling.Name = "CrystalGrottoShardling01"', VISUALS)
        self.assertIn('shardling:SetAttribute("ArchetypeId", "Shardling")', VISUALS)
        self.assertIn('humanoid.DisplayName = "Осколочник"', VISUALS)
        self.assertIn("humanoid.MaxHealth = 72", VISUALS)
        self.assertIn("humanoid.WalkSpeed = 12", VISUALS)
        self.assertIn("if crystalGrotto.Parent then spawnCrystalShardling() end", VISUALS)
        self.assertIn('CrystalGrottoShardling01 = {itemId = "CrystalShard", amount = 1, coins = 8}', WORLD)

    def test_shardling_feint_is_a_non_damaging_short_dash(self):
        self.assertIn('local useShardlingFeint = enemy:GetAttribute("ArchetypeId") == "Shardling"', COMBAT)
        feint = COMBAT.split("elseif useShardlingFeint then", 1)[1].split("elseif useShardlingDash then", 1)[0]
        self.assertIn('enemy:SetAttribute("BossAttack", "ShardlingFeint")', feint)
        self.assertIn('enemy:SetAttribute("CombatState", "ShardlingFeintTelegraph")', feint)
        self.assertIn("root.AssemblyLinearVelocity = direction * 34", feint)
        self.assertNotIn("TakeDamage", feint)

    def test_shardling_real_dash_uses_a_server_checked_lane(self):
        self.assertIn('local useShardlingDash = enemy:GetAttribute("ArchetypeId") == "Shardling"', COMBAT)
        dash = COMBAT.split("elseif useShardlingDash then", 1)[1].split('\n                    else\n                        enemy:SetAttribute("CombatState", "Telegraph")', 1)[0]
        self.assertIn('enemy:SetAttribute("BossAttack", "ShardlingDash")', dash)
        self.assertIn("if isEnemyAlive(enemy) and targetPlayer.Parent then", dash)
        self.assertIn('enemy:SetAttribute("CombatState", "ShardlingDashTelegraph")', dash)
        self.assertIn("local projection = horizontalOffset:Dot(direction)", dash)
        self.assertIn("local lateral = (horizontalOffset - direction * projection).Magnitude", dash)
        self.assertIn("projection >= -1 and projection <= dashRange + 2 and lateral <= 3.25", dash)
        self.assertIn("if not dodging then", dash)
        self.assertIn("BLOCK_DAMAGE_MULTIPLIER", dash)
        self.assertIn("currentHumanoid:TakeDamage(damage)", dash)

    def test_shardling_has_readable_local_telegraph_and_windup_pose(self):
        self.assertIn("local function showShardlingDashTelegraph(enemy, isFeint)", CLIENT)
        self.assertIn('"ОБМАННЫЙ РЫВОК"', CLIENT)
        self.assertIn('"РЫВОК!"', CLIENT)
        self.assertIn('attack == "ShardlingFeint" and isShardling', CLIENT)
        self.assertIn('attack == "ShardlingDash" and isShardling', CLIENT)
        self.assertIn('state == "ShardlingFeintTelegraph" or state == "ShardlingDashTelegraph"', CLIENT)


if __name__ == "__main__":
    unittest.main()
