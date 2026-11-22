from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
WORKFLOW = (ROOT / ".github/workflows/validate-place.yml").read_text(encoding="utf-8")


class CombatFoundationContractTests(unittest.TestCase):
    def test_dedicated_server_owned_remote_is_created(self):
        self.assertIn('remote.Name = "CombatAction"', COMBAT)
        self.assertIn('remote.Parent = ReplicatedStorage', COMBAT)
        self.assertIn("remote.OnServerEvent:Connect(handleAction)", COMBAT)
        self.assertIn('if remote and not remote:IsA("RemoteEvent") then', COMBAT)

    def test_client_cannot_supply_combat_payload_values(self):
        self.assertIn("local function handleAction(player, action, ...)", COMBAT)
        self.assertIn('select("#", ...) ~= 0', COMBAT)
        self.assertIn('reject(player, "UnexpectedPayload")', COMBAT)

    def test_even_nil_and_extra_remote_arguments_are_rejected(self):
        self.assertIn("select(\"#\", ...) ~= 0", COMBAT)
        self.assertNotIn("function handleAction(player, action, payload)", COMBAT)
        self.assertNotIn("payload.damage", COMBAT.lower())
        self.assertNotIn("payload.reward", COMBAT.lower())
        self.assertNotIn("payload.target", COMBAT.lower())

    def test_actions_are_allow_listed_and_unknown_actions_rejected(self):
        self.assertIn('action == "RequestCombatState"', COMBAT)
        self.assertIn('action ~= "Attack" and action ~= "BlockStart"', COMBAT)
        self.assertIn('and action ~= "Dodge"', COMBAT)
        self.assertIn('reject(player, "UnknownAction")', COMBAT)

    def test_global_request_rate_is_bounded(self):
        self.assertIn("MAX_ACTIONS_PER_WINDOW = 10", COMBAT)
        self.assertIn("ACTION_RATE_WINDOW = 1", COMBAT)
        self.assertIn("return state.windowActionCount <= MAX_ACTIONS_PER_WINDOW", COMBAT)
        self.assertIn('reject(player, "RateLimited")', COMBAT)

    def test_combat_requires_server_ready_alive_region_and_weapon_state(self):
        self.assertIn('player:GetAttribute("Ready") == true', COMBAT)
        self.assertIn("humanoid.Health > 0", COMBAT)
        self.assertIn("ALLOWED_REGIONS[regionId]", COMBAT)
        self.assertIn("ALLOWED_WEAPONS[weaponId]", COMBAT)
        self.assertIn('reject(player, "CombatRegionRequired")', COMBAT)
        self.assertIn('reject(player, "NoServerEquippedWeapon")', COMBAT)

    def test_c1_uses_server_owned_enemy_damage_and_never_client_values(self):
        self.assertIn("entry.humanoid:TakeDamage(PLAYER_DAMAGE)", COMBAT)
        self.assertIn("currentHumanoid:TakeDamage(damage)", COMBAT)
        self.assertNotIn("payload.damage", COMBAT.lower())
        self.assertNotIn("payload.reward", COMBAT.lower())
        self.assertNotIn("payload.target", COMBAT.lower())

    def test_enemy_targets_are_server_registered_and_alive(self):
        self.assertIn('CollectionService:GetTagged("GiantbackEnemy")', COMBAT)
        self.assertIn("local function isEnemyModel(instance)", COMBAT)
        self.assertIn("local function isEnemyAlive(enemy)", COMBAT)
        self.assertIn("entry.regionId == getPlayerRegion(player)", COMBAT)

    def test_melee_hitbox_range_facing_and_cooldown_are_server_owned(self):
        self.assertIn("PLAYER_ATTACK_COOLDOWN = 0.65", COMBAT)
        self.assertIn("Workspace:GetPartBoundsInBox(hitCFrame, PLAYER_ATTACK_BOX, overlap)", COMBAT)
        self.assertIn("root.CFrame.LookVector:Dot(offset.Unit) >= 0.25", COMBAT)

    def test_block_and_dodge_are_server_timed(self):
        self.assertIn("DODGE_DURATION = 0.45", COMBAT)
        self.assertIn('if action == "BlockEnd" then', COMBAT)
        self.assertIn('state.blocking = false', COMBAT)
        self.assertIn("DODGE_COOLDOWN = 1.5", COMBAT)
        self.assertIn("state.dodgingUntil = now + DODGE_DURATION", COMBAT)
        self.assertIn("playerState.blocking", COMBAT)
        self.assertIn("BLOCK_DAMAGE_MULTIPLIER = 0.25", COMBAT)

    def test_enemy_telegraphs_before_server_damage(self):
        self.assertIn('enemy:SetAttribute("CombatState", "Telegraph")', COMBAT)
        self.assertIn("task.wait(entry.telegraphSeconds)", COMBAT)
        self.assertIn("ENEMY_TELEGRAPH_SECONDS = 0.85", COMBAT)
        self.assertIn("PathfindingService:CreatePath(ENEMY_PATH_AGENT)", COMBAT)
        self.assertIn("path:ComputeAsync(root.Position, targetRoot.Position)", COMBAT)
        self.assertIn("ENEMY_PATH_REFRESH_SECONDS = 1.15", COMBAT)

    def test_rewards_are_persistent_and_idempotent(self):
        self.assertIn('ServerStorage:WaitForChild("GiantbackGrantCombatReward"', COMBAT)
        self.assertIn("rewardFunction:Invoke(contributor, entry.encounterId)", COMBAT)
        self.assertIn("entry.contributors[player] = true", COMBAT)
        self.assertIn("for contributor in entry.contributors do", COMBAT)
        self.assertIn("contributor.Parent == Players", COMBAT)
        self.assertNotIn("entry.lastHitBy", COMBAT)
        self.assertIn("completedCombatEncounters", WORLD)
        self.assertIn("old.completedCombatEncounters = savedCombatEncounters", WORLD)
        self.assertIn("GroveGrunt01", WORLD)

    def test_coop_rewards_each_server_verified_contributor_once(self):
        self.assertIn("contributors = {}", COMBAT)
        self.assertIn("entry.contributors[player] = true", COMBAT)
        self.assertIn("for contributor in entry.contributors do", COMBAT)
        self.assertIn("rewardFunction:Invoke(contributor, entry.encounterId)", COMBAT)
        self.assertIn("if entry.rewardResolved then return end", COMBAT)
        self.assertIn("contributor.Parent == Players", COMBAT)

    def test_transient_state_is_cleared_on_death_respawn_and_leave(self):
        self.assertIn("local function clearTransientState(player)", COMBAT)
        self.assertIn("player.CharacterAdded:Connect", COMBAT)
        self.assertIn("humanoid.Died:Connect", COMBAT)
        self.assertIn("Players.PlayerRemoving:Connect", COMBAT)
        self.assertIn("playerStates[player] = nil", COMBAT)

    def test_sanitized_state_snapshot_does_not_expose_mutable_server_tables(self):
        self.assertIn('remote:FireClient(player, "CombatState"', COMBAT)
        self.assertIn("enabled = true", COMBAT)
        self.assertIn('phase = "C1"', COMBAT)
        self.assertIn('regionId = regionId', COMBAT)

    def test_place_builder_embeds_server_and_client_combat_scripts(self):
        self.assertIn('"Combat.server.luau"', BUILD)
        self.assertIn('"Combat.client.luau"', BUILD)
        self.assertIn('"CombatControls"', BUILD)
        self.assertIn('"Combat"', WORKFLOW)
        self.assertIn('"CombatAction"', WORKFLOW)

    def test_place_generates_tagged_training_arena_and_first_r6_enemy(self):
        self.assertIn('combatGlade.Name = "CombatTrainingGlade"', VISUALS)
        self.assertIn('region:SetAttribute("RegionId", "GroveTraining")', VISUALS)
        self.assertIn('CollectionService:AddTag(region, "GiantbackCombatRegion")', VISUALS)
        self.assertIn('enemy:SetAttribute("EncounterId", "GroveGrunt01")', VISUALS)
        self.assertIn('enemy:SetAttribute("RegionId", "GroveTraining")', VISUALS)
        self.assertIn('CollectionService:AddTag(enemy, "GiantbackEnemy")', VISUALS)
        for rig_part in ("HumanoidRootPart", "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"):
            self.assertIn(f'"{rig_part}"', VISUALS)
        self.assertIn('enemyHumanoid.DisplayName = "Корневой страж"', VISUALS)
        self.assertIn("enemyHumanoid.MaxHealth = 100", VISUALS)
        self.assertIn("enemyRoot.Massless = false", VISUALS)
        self.assertIn("CFrame.lookAt(enemySpawn, enemySpawn + Vector3.new(0, 0, -1))", VISUALS)
        self.assertIn('enemyHighlight.Name = "CombatTelegraphHighlight"', VISUALS)
        self.assertIn('warningBillboard.Name = "CombatTelegraphWarning"', VISUALS)
        self.assertIn('warningText.Text = "БЕРЕГИСЬ!"', VISUALS)
        self.assertIn('warningText.Text = "АТАКА!"', VISUALS)
        self.assertIn("TweenService:Create(rightShoulder", VISUALS)
        self.assertIn("GroveApproach", VISUALS)
        self.assertIn("Training stone platform", VISUALS)

    def test_enemy_archetypes_use_server_clamped_per_enemy_combat_profiles(self):
        self.assertIn('REWARD_ENCOUNTERS = { GroveGrunt01 = true, GroveScout02 = true, RootvaultSentinel01 = true, RootvaultStalker01 = true }', COMBAT)
        self.assertIn('aggroRange = math.clamp(tonumber(enemy:GetAttribute("AggroRange")) or ENEMY_AGGRO_RANGE, 8, 80)', COMBAT)
        self.assertIn('attackDamage = math.clamp(math.floor(tonumber(enemy:GetAttribute("AttackDamage")) or ENEMY_ATTACK_DAMAGE), 1, 30)', COMBAT)
        self.assertIn('task.wait(entry.telegraphSeconds)', COMBAT)
        self.assertIn('local bestDistance = entry.aggroRange', COMBAT)
        self.assertIn('if bestDistance > entry.attackRange then', COMBAT)
        self.assertIn('GroveScout02 = {itemId = "SunPetal", amount = 2}', WORLD)

    def test_forest_scout_has_distinct_speed_health_telegraph_and_reward(self):
        self.assertIn('scout.Name = "GroveScout02"', VISUALS)
        self.assertIn('scoutHumanoid.DisplayName = "Мшистый разведчик"', VISUALS)
        self.assertIn('scoutHumanoid.MaxHealth = 65', VISUALS)
        self.assertIn('scoutHumanoid.WalkSpeed = 14', VISUALS)
        self.assertIn('scout:SetAttribute("TelegraphSeconds", 0.58)', VISUALS)
        self.assertIn('scout:SetAttribute("AttackDamage", 8)', VISUALS)
        self.assertIn('CollectionService:AddTag(scout, "GiantbackEnemy")', VISUALS)
        self.assertIn('scoutWarningText.Text = "РЫВОК!"', VISUALS)

    def test_forest_trial_chamber_requires_both_server_victories(self):
        self.assertIn('trialPortal', VISUALS)
        self.assertIn('"ForestTrialGate"', VISUALS)
        self.assertIn('"ForestTrialChamber"', VISUALS)
        self.assertIn('"ForestTrialArrival"', VISUALS)
        self.assertIn('"ForestTrialReturn"', VISUALS)
        self.assertIn('"ForestTrialChest"', VISUALS)
        self.assertIn("session.completedCombatEncounters.GroveGrunt01 == true", WORLD)
        self.assertIn("session.completedCombatEncounters.GroveScout02 == true", WORLD)
        self.assertIn("hasCompletedForestTrial(session)", WORLD)
        self.assertIn("validTrialInteraction(player, gatePart)", WORLD)
        self.assertIn("validTrialInteraction(player, chestPart)", WORLD)
        self.assertIn("(root.Position - anchorPart.Position).Magnitude > 13", WORLD)
        self.assertIn('GroveTrialChest01 = {itemId = "StarShard", amount = 1}', WORLD)
        self.assertIn('combatRewardFunction:Invoke(player, "GroveTrialChest01")', WORLD)
        self.assertIn("if trialBusy[player] then return end", WORLD)
        self.assertIn("if session.completedCombatEncounters.GroveTrialChest01 then", WORLD)

    def test_forest_trial_rune_puzzle_is_server_authoritative_and_per_player(self):
        self.assertIn('TRIAL_RUNE_SEQUENCE = {"ForestTrialRuneMoon", "ForestTrialRuneDawn", "ForestTrialRuneTide"}', WORLD)
        self.assertIn('local trialPuzzleProgress = {}', WORLD)
        self.assertIn('local trialPuzzleComplete = {}', WORLD)
        self.assertIn('now - progress.lastAt > 20', WORLD)
        self.assertIn('runeName ~= TRIAL_RUNE_SEQUENCE[progress.nextIndex]', WORLD)
        self.assertIn('trialPuzzleComplete[player] = true', WORLD)
        self.assertIn('trialPuzzleProgress[player] = nil', WORLD)
        self.assertIn('if not trialPuzzleComplete[player] then', WORLD)
        self.assertIn('trialPuzzleComplete[player] = nil', WORLD)
        self.assertIn('"ForestTrialRuneMoon"', VISUALS)
        self.assertIn('"ForestTrialRuneDawn"', VISUALS)
        self.assertIn('"ForestTrialRuneTide"', VISUALS)
        self.assertIn('Луна → Рассвет → Прилив', VISUALS)
        self.assertIn('runePrompt.HoldDuration = 0.25', VISUALS)

    def test_rootvault_is_gated_and_rewards_each_player_once(self):
        self.assertIn('RootvaultChest01 = {itemId = "IronOre", amount = 3}', WORLD)
        self.assertIn('session.completedCombatEncounters.GroveTrialChest01 ~= true', WORLD)
        self.assertIn('rootvaultInside[player] = true', WORLD)
        self.assertIn('player:SetAttribute("InRootvault", true)', WORLD)
        self.assertIn('rootvaultLeverActivated[player] = true', WORLD)
        self.assertIn('if not rootvaultLeverActivated[player] then', WORLD)
        self.assertIn('combatRewardFunction:Invoke(player, "RootvaultChest01")', WORLD)
        self.assertIn('session.completedCombatEncounters.RootvaultChest01', WORLD)
        self.assertIn('trap.Touched:Connect(function(hit)', WORLD)
        self.assertIn('humanoid:TakeDamage(math.clamp(tonumber(trap:GetAttribute("TrapDamage")) or 10, 1, 20))', WORLD)
        self.assertIn('rootvaultTrapCooldown[player]', WORLD)
        self.assertIn('"RootvaultDungeon"', VISUALS)
        self.assertIn('"RootvaultEntryRoom"', VISUALS)
        self.assertIn('"RootvaultTrapPassage"', VISUALS)
        self.assertIn('"RootvaultMechanismRoom"', VISUALS)
        self.assertIn('"RootvaultSealedDoor"', VISUALS)
        self.assertIn('"RootvaultRewardRoom"', VISUALS)
        self.assertIn('"RootvaultRewardChest"', VISUALS)
        self.assertIn("local vaultFloorY = 0", VISUALS)
        self.assertIn('"RootvaultPressurePlate"', VISUALS)
        self.assertIn('"RootvaultEntrance"', VISUALS)

    def test_rootvault_sentinel_drops_persistent_key_and_owns_its_combat_region(self):
        self.assertIn('RootvaultSentinel01 = {itemId = "RootvaultKey", amount = 1}', WORLD)
        self.assertIn('"RootvaultKey"', WORLD)
        self.assertIn('RootvaultSentinel01 = true', COMBAT)
        self.assertIn('Rootvault = true', COMBAT)
        self.assertIn('EncounterId", "RootvaultSentinel01"', VISUALS)
        self.assertIn('DisplayName = "Страж хранилища"', VISUALS)
        self.assertIn('CollectionService:AddTag(rootvaultRegion, "GiantbackCombatRegion")', VISUALS)
        self.assertIn('RegionId", "Rootvault"', VISUALS)
        self.assertIn('if (session.inventory.RootvaultKey or 0) < 1 then', WORLD)
        self.assertIn('Победи Стража хранилища и забери ключ.', WORLD)
        self.assertIn('RootvaultKey', WORLD)

    def test_rootvault_stalker_is_a_distinct_fast_enemy_with_persistent_material_reward(self):
        self.assertIn('RootvaultStalker01 = {itemId = "RootvaultEssence", amount = 1}', WORLD)
        self.assertIn('"RootvaultEssence"', WORLD)
        self.assertIn('RootvaultStalker01 = true', COMBAT)
        self.assertIn('EncounterId", "RootvaultStalker01"', VISUALS)
        self.assertIn('DisplayName = "Корневой охотник"', VISUALS)
        self.assertIn('stalkerHumanoid.MaxHealth = 75', VISUALS)
        self.assertIn('stalkerHumanoid.WalkSpeed = 15', VISUALS)
        self.assertIn('AttackDamage", 8', VISUALS)
        self.assertIn('AttackCooldown", 1.8', VISUALS)
        self.assertIn('CollectionService:AddTag(stalker, "GiantbackEnemy")', VISUALS)

    def test_rootvault_seal_keeper_has_three_server_driven_phases_and_gates_relic(self):
        self.assertIn('RootvaultSealKeeper01 = {itemId = "RootvaultSigil", amount = 1}', WORLD)
        self.assertIn('session.completedCombatEncounters.RootvaultSealKeeper01 ~= true', WORLD)
        self.assertIn('Страж печатей. Победи его, чтобы открыть сундук.', WORLD)
        self.assertIn('RootvaultSealKeeper01 = true', COMBAT)
        self.assertIn('IsBoss", true', VISUALS)
        self.assertIn('MaxHealth = 360', VISUALS)
        self.assertIn('Phase2WalkSpeed', VISUALS)
        self.assertIn('Phase3WalkSpeed', VISUALS)
        self.assertIn('local nextPhase = ratio <= 0.25 and 3 or (ratio <= 0.6 and 2 or 1)', COMBAT)
        self.assertIn('enemy:SetAttribute("BossPhase", nextPhase)', COMBAT)
        self.assertIn('entry.attackDamage = math.clamp', COMBAT)
        self.assertIn('humanoid.WalkSpeed = math.clamp', COMBAT)
        self.assertIn('DisplayName = "Страж печатей"', VISUALS)
        self.assertIn('SealCore', VISUALS)

    def test_client_supports_keyboard_gamepad_and_touch_intents(self):
        self.assertIn("Enum.UserInputType.MouseButton1", CLIENT)
        self.assertIn("Enum.KeyCode.ButtonR2", CLIENT)
        self.assertIn("Enum.KeyCode.ButtonL2", CLIENT)
        self.assertIn("Enum.KeyCode.ButtonB", CLIENT)
        self.assertIn('remote:FireServer("Attack")', CLIENT)
        self.assertIn('remote:FireServer("BlockStart")', CLIENT)
        self.assertIn('remote:FireServer("BlockEnd")', CLIENT)
        self.assertIn('remote:FireServer("Dodge")', CLIENT)
        self.assertIn('feedbackGui.Name = "GiantbackCombatFeedback"', CLIENT)
        self.assertIn('showFeedback("ПОПАЛ!"', CLIENT)
        self.assertIn('CombatRegionRequired = "Войди на тренировочную арену"', CLIENT)
        self.assertIn('ContextActionService:BindAction(', CLIENT)


if __name__ == "__main__":
    unittest.main()
