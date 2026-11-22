from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CompanionMoodContractTests(unittest.TestCase):
    def test_each_companion_has_a_distinct_non_punitive_default_mood(self):
        self.assertIn('Fox = "Любопытство"', WORLD)
        self.assertIn('Moth = "Спокойствие"', WORLD)
        self.assertIn('CrystalWisp = "Любопытство"', WORLD)
        self.assertIn('CrystalWisp = companionMoodDefaults.CrystalWisp', WORLD)

    def test_mood_is_server_owned_and_synced_as_a_player_attribute(self):
        self.assertIn("local function setCompanionMood(player, companionId, mood)", WORLD)
        self.assertIn('session.companionMood[companionId] = mood', WORLD)
        self.assertIn('player:SetAttribute("Companion_" .. companionId .. "_Mood", mood)', WORLD)
        self.assertIn('player:SetAttribute("Companion_" .. id .. "_Mood", mood)', WORLD)

    def test_successful_care_and_play_change_mood_without_failure_penalties(self):
        self.assertIn('setCompanionMood(player, challenge.companionId, "Радость")', WORLD)
        self.assertIn('setCompanionMood(player, companionId, "Довольство")', WORLD)
        self.assertIn('setCompanionMood(player, action, action == "Fox" and "Любопытство" or "Спокойствие")', WORLD)
        self.assertIn('if not success then', WORLD)

    def test_pets_album_shows_personality_and_current_mood(self):
        self.assertIn('local mood = player:GetAttribute("Companion_" .. pet.id .. "_Mood")', HUD)
        self.assertIn("Любопытный исследователь", HUD)
        self.assertIn("Нежная хранительница света", HUD)
        self.assertIn('"Mood"', HUD)
        self.assertIn("Довольство", HUD)


if __name__ == "__main__":
    unittest.main()
