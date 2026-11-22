from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CompanionPlayContractTests(unittest.TestCase):
    def test_start_requires_owned_equipped_companion_and_server_cooldown(self):
        self.assertIn("local function startCompanionPlay(player, companionId)", WORLD)
        self.assertIn('player:GetAttribute(companionId) ~= true', WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= companionId', WORLD)
        self.assertIn("companionPlayReadyAt", WORLD)
        self.assertIn("companionPlayCooldownSeconds = 25", WORLD)

    def test_server_owns_token_sequence_and_expires_abandoned_challenge(self):
        self.assertIn("HttpService:GenerateGUID(false)", WORLD)
        self.assertIn("sequence = sequence", WORLD)
        self.assertIn("expiresAt = now + 18", WORLD)
        self.assertIn("task.delay(18, function()", WORLD)
        self.assertIn("currentSession.companionPlay.token == token", WORLD)

    def test_each_input_is_validated_in_order_on_the_server(self):
        self.assertIn("local function submitCompanionPlayInput(player, payload)", WORLD)
        self.assertIn("payload.token ~= challenge.token", WORLD)
        self.assertIn("index ~= challenge.nextIndex", WORLD)
        self.assertIn("symbol ~= challenge.sequence[challenge.nextIndex]", WORLD)
        self.assertIn('if action == "CompanionPlayInput" then', WORLD)

    def test_success_rewards_friendship_and_companion_xp(self):
        self.assertIn("progressData.bond = math.clamp((progressData.bond or 0) + 15, 0, 1000)", WORLD)
        self.assertIn('awardCompanionXp(player, challenge.companionId, 8)', WORLD)
        self.assertIn('event:FireClient(player, "CompanionPlayFinished"', WORLD)

    def test_pets_tab_starts_the_game_and_client_renders_sequence_input(self):
        self.assertIn('event:FireServer("StartCompanionPlay", pet.id)', HUD)
        self.assertIn('event:FireServer("CompanionPlayInput"', HUD)
        self.assertIn('message == "CompanionPlayStarted"', HUD)
        self.assertIn('message == "CompanionPlayFinished"', HUD)
        self.assertIn("table.concat(sequenceText", HUD)


if __name__ == "__main__":
    unittest.main()
