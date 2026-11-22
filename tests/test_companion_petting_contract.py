from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class CompanionPettingContractTests(unittest.TestCase):
    def test_petting_is_server_validated_for_owned_equipped_companion(self):
        self.assertIn("local function petCompanion(player, companionId)", WORLD)
        self.assertIn('player:GetAttribute(companionId) ~= true', WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= companionId', WORLD)
        self.assertIn('if action == "PetCompanion" then', WORLD)
        self.assertIn("petCompanion(player, payload)", WORLD)

    def test_petting_has_independent_cooldown_and_grants_small_friendship_reward(self):
        self.assertIn("companionPetReadyAt", WORLD)
        self.assertIn("session.companionPetReadyAt[companionId] = now + 18", WORLD)
        self.assertIn("progressData.bond = math.clamp((progressData.bond or 0) + 5, 0, 1000)", WORLD)
        self.assertIn('setCompanionMood(player, companionId, "Радость")', WORLD)
        self.assertIn('event:FireClient(player, "CompanionPetted"', WORLD)

    def test_pets_card_offers_petting_only_for_owned_equipped_companion(self):
        self.assertIn('button(item, "Pet"', HUD)
        self.assertIn('event:FireServer("PetCompanion", pet.id)', HUD)
        self.assertIn("petButton.Active = owned and equipped", HUD)

    def test_client_plays_species_specific_reaction_and_visual_feedback(self):
        self.assertIn('message == "CompanionPetted"', ALBUM)
        self.assertIn("pettingUntil", ALBUM)
        self.assertIn("playCompanionPettingBurst(model, id)", ALBUM)
        self.assertIn("petting and 10.5", ALBUM)
        self.assertIn("petting and 17", ALBUM)
        self.assertIn("CompanionPettingBurstLocal", ALBUM)


if __name__ == "__main__":
    unittest.main()
