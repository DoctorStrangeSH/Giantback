from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
WORKFLOW = (ROOT / ".github/workflows/validate-place.yml").read_text(encoding="utf-8")


class CombatFoundationContractTests(unittest.TestCase):
    def test_dedicated_server_owned_remote_is_created(self):
        self.assertIn('remote.Name = "CombatAction"', COMBAT)
        self.assertIn('remote.Parent = ReplicatedStorage', COMBAT)
        self.assertIn("remote.OnServerEvent:Connect(handleAction)", COMBAT)
        self.assertIn('if remote and not remote:IsA("RemoteEvent") then', COMBAT)

    def test_client_cannot_supply_combat_payload_values(self):
        self.assertIn("if payload ~= nil then", COMBAT)
        self.assertIn('reject(player, "UnexpectedPayload")', COMBAT)
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
        self.assertIn("state.windowActionCount > MAX_ACTIONS_PER_WINDOW", COMBAT)
        self.assertIn('reject(player, "RateLimited")', COMBAT)

    def test_combat_requires_server_ready_alive_region_and_weapon_state(self):
        self.assertIn('player:GetAttribute("Ready") == true', COMBAT)
        self.assertIn("humanoid.Health > 0", COMBAT)
        self.assertIn("COMBAT_REGIONS[regionId] == true", COMBAT)
        self.assertIn("COMBAT_WEAPONS[weaponId] == true", COMBAT)
        self.assertIn('reject(player, "CombatRegionRequired")', COMBAT)
        self.assertIn('reject(player, "NoServerEquippedWeapon")', COMBAT)

    def test_c0_never_applies_client_requested_damage_or_rewards(self):
        self.assertIn('reject(player, "CombatNotEnabled")', COMBAT)
        self.assertNotIn("TakeDamage", COMBAT)
        self.assertNotIn("Health =", COMBAT)
        self.assertNotIn('FireClient(player, "Reward"', COMBAT)

    def test_transient_state_is_cleared_on_death_respawn_and_leave(self):
        self.assertIn("local function clearTransientState(player)", COMBAT)
        self.assertIn("player.CharacterAdded:Connect", COMBAT)
        self.assertIn("humanoid.Died:Connect", COMBAT)
        self.assertIn("Players.PlayerRemoving:Connect", COMBAT)
        self.assertIn("playerStates[player] = nil", COMBAT)

    def test_sanitized_state_snapshot_does_not_expose_mutable_server_tables(self):
        self.assertIn('remote:FireClient(player, "CombatState"', COMBAT)
        self.assertIn("enabled = false", COMBAT)
        self.assertIn('phase = "C0"', COMBAT)
        self.assertIn('regionId = player:GetAttribute("CombatRegionId") or ""', COMBAT)

    def test_place_builder_embeds_combat_server_script(self):
        self.assertIn('"Combat.server.luau"', BUILD)
        self.assertIn('"Combat"', WORKFLOW)
        self.assertIn('"CombatAction"', WORKFLOW)


if __name__ == "__main__":
    unittest.main()
