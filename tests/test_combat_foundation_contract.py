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
        self.assertIn("task.wait(ENEMY_TELEGRAPH_SECONDS)", COMBAT)
        self.assertIn("ENEMY_TELEGRAPH_SECONDS = 0.85", COMBAT)

    def test_rewards_are_persistent_and_idempotent(self):
        self.assertIn('ServerStorage:WaitForChild("GiantbackGrantCombatReward"', COMBAT)
        self.assertIn("rewardFunction:Invoke(entry.lastHitBy, entry.encounterId)", COMBAT)
        self.assertIn("completedCombatEncounters", WORLD)
        self.assertIn("old.completedCombatEncounters = savedCombatEncounters", WORLD)
        self.assertIn("GroveGrunt01", WORLD)

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
        self.assertIn("CFrame.lookAt(enemySpawn, enemySpawn + Vector3.new(0, 0, 1))", VISUALS)
        self.assertIn('enemyHighlight.Name = "CombatTelegraphHighlight"', VISUALS)
        self.assertIn('warningBillboard.Name = "CombatTelegraphWarning"', VISUALS)
        self.assertIn('warningText.Text = "БЕРЕГИСЬ!"', VISUALS)
        self.assertIn("GroveApproach", VISUALS)
        self.assertIn("Training stone platform", VISUALS)

    def test_client_supports_keyboard_gamepad_and_touch_intents(self):
        self.assertIn("Enum.UserInputType.MouseButton1", CLIENT)
        self.assertIn("Enum.KeyCode.ButtonR2", CLIENT)
        self.assertIn("Enum.KeyCode.ButtonL2", CLIENT)
        self.assertIn("Enum.KeyCode.ButtonB", CLIENT)
        self.assertIn('remote:FireServer("Attack")', CLIENT)
        self.assertIn('remote:FireServer("BlockStart")', CLIENT)
        self.assertIn('remote:FireServer("BlockEnd")', CLIENT)
        self.assertIn('remote:FireServer("Dodge")', CLIENT)
        self.assertIn('ContextActionService:BindAction(', CLIENT)


if __name__ == "__main__":
    unittest.main()
