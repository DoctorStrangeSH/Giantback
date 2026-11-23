from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CompanionCareContractTests(unittest.TestCase):
    def test_friendship_is_normalized_persisted_and_synced(self):
        self.assertIn('local bond = math.clamp(math.floor(tonumber(saved.bond) or 0), 0, 1000)', WORLD)
        self.assertIn('bond = bond}', WORLD)
        self.assertIn('player:SetAttribute("Companion_" .. id .. "_Bond", progressData.bond)', WORLD)
        self.assertIn('player:SetAttribute("Companion_" .. id .. "_BondRank", bondRank)', WORLD)
        self.assertIn('savedCompanion = companionProgressSnapshot[companionId]', WORLD)
        self.assertIn('savedCompanions[companionId] = savedCompanion', WORLD)

    def test_feeding_is_server_validated_and_requires_the_equipped_owned_pet(self):
        self.assertIn('local function feedCompanion(player, companionId)', WORLD)
        self.assertIn('player:GetAttribute(companionId) ~= true', WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= companionId', WORLD)
        self.assertIn('if action == "FeedCompanion" then', WORLD)
        self.assertIn('feedCompanion(player, payload)', WORLD)

    def test_feeding_consumes_real_harvest_and_has_server_cooldown(self):
        for food in ("Pumpkin", "Strawberry", "Cabbage", "Carrot"):
            self.assertIn(food, WORLD)
        self.assertIn('local companionFeedOrder = {"Pumpkin", "Strawberry", "Cabbage", "Carrot"}', WORLD)
        self.assertIn('session.inventory[foodId] -= 1', WORLD)
        self.assertIn('session.companionFeedReadyAt[companionId] = now + 8', WORLD)
        self.assertIn('progressData.bond = math.clamp((progressData.bond or 0) + food.bond, 0, 1000)', WORLD)

    def test_friendship_ranks_are_non_decaying_and_shown_in_the_pets_tab(self):
        for rank in ("Родственные души", "Лучшие друзья", "Друзья", "Знакомцы", "Знакомство"):
            self.assertIn(rank, WORLD)
        self.assertIn('("Дружба " .. tostring(bond) .. "/1000 · " .. bondRank)', HUD)
        self.assertIn('event:FireServer("FeedCompanion", pet.id)', HUD)
        self.assertIn('feedText = not owned', HUD)


if __name__ == "__main__":
    unittest.main()
