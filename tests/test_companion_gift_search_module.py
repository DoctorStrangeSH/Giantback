"""Companion gift searches must be biome-aware, persistent, and server-authoritative."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
INTERACTIONS = (ROOT / "modules/CompanionInteractions.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules/CompanionAnimation.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class CompanionGiftSearchTests(unittest.TestCase):
    def test_search_action_is_routed_and_validates_owned_equipped_companion(self):
        self.assertIn('if action == "SearchCompanionGift" then', WORLD)
        self.assertIn('searchCompanionGift(player, payload)', WORLD)
        self.assertIn('table.find(COMPANION_IDS, companionId) == nil', WORLD)
        self.assertIn('player:GetAttribute(companionId) ~= true', WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= companionId', WORLD)

    def test_biome_reward_tables_only_use_supported_inventory_items(self):
        for biome in ("Grove", "Dusk", "CrystalGrotto"):
            self.assertIn(biome + " = {", WORLD)
        for item in ("SunPetal", "Wood", "CarrotSeed", "MoonPetal", "StarShard",
                     "CrystalShard", "CrystalSigil", "PrismSeed", "VoidGeode"):
            self.assertIn('itemId = "' + item + '"', WORLD)
            self.assertIn('"' + item + '"', WORLD[WORLD.index("local inventoryKeys"):WORLD.index("local toolIds")])
        self.assertIn('table.find(inventoryKeys, reward.itemId)', WORLD)

    def test_search_requires_player_inside_known_biome_and_uses_cooldown(self):
        self.assertIn('local function getCompanionGiftBiome(position)', WORLD)
        self.assertIn('local biomeName = getCompanionGiftBiome(root.Position)', WORLD)
        self.assertIn('isPositionInsideBiome(position, biomeName)', WORLD)
        self.assertIn('local COMPANION_GIFT_COOLDOWN_SECONDS = 180', WORLD)
        self.assertIn('if readyAt > now then', WORLD)
        self.assertIn('session.companionGiftReadyAt[companionId] = now + COMPANION_GIFT_COOLDOWN_SECONDS', WORLD)

    def test_cooldowns_persist_and_reward_rolls_back_if_save_fails(self):
        self.assertIn('companionGiftReadyAt = {}', WORLD)
        self.assertIn('local companionGiftSnapshot = {}', WORLD)
        self.assertIn('old.companionGiftSearch = savedCompanionGiftSearch', WORLD)
        self.assertIn('local savedCompanionGiftSearch = type(data.companionGiftSearch)', WORLD)
        self.assertIn('session.inventory[reward.itemId] = previousAmount', WORLD)
        self.assertIn('session.companionGiftReadyAt[companionId] = previousReadyAt', WORLD)

    def test_reward_grants_xp_only_after_successful_persist(self):
        self.assertIn('local saved = save(player)', WORLD)
        self.assertIn('awardCompanionXp(player, companionId, 12)', WORLD)
        self.assertIn('session.economyBusy = true', WORLD)
        self.assertIn('session.economyBusy = false', WORLD)

    def test_search_prompt_is_separate_from_petting_and_uses_existing_local_companion(self):
        self.assertIn('searchPrompt.Name = "WorldPetSearchPrompt"', INTERACTIONS)
        self.assertIn('searchPrompt.ActionText = "Искать подарок"', INTERACTIONS)
        self.assertIn('searchPrompt.KeyboardKeyCode = Enum.KeyCode.F', INTERACTIONS)
        self.assertIn('event:FireServer("SearchCompanionGift", companionId)', INTERACTIONS)
        self.assertIn('attachWorldPetPrompt(model, id)', CLIENT)

    def test_search_has_species_animation_and_server_confirmed_discovery_feedback(self):
        self.assertIn('companionSearchUntil = os.clock() + 3.8', CLIENT)
        self.assertIn('state.searching = owner == player and os.clock() < companionSearchUntil', CLIENT)
        self.assertIn('state.searching == true', CLIENT)
        self.assertIn('if searching and (part.Name == "Body"', ANIMATION)
        self.assertIn('playCompanionSearchStart(model, companionId)', INTERACTIONS)
        self.assertIn('playCompanionGiftDiscovery(model, companionId, rarity)', INTERACTIONS)
        self.assertIn('player:GetAttributeChangedSignal("CompanionGiftSearchSerial")', CLIENT)
        self.assertIn('player:SetAttribute("CompanionGiftSearchResult"', WORLD)
        self.assertIn('player:SetAttribute("CompanionGiftSearchSerial"', WORLD)
        self.assertIn('local rarity = reward.weight <= 2 and "epic"', WORLD)


if __name__ == "__main__":
    unittest.main()
