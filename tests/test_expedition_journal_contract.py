from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class ExpeditionJournalContractTests(unittest.TestCase):
    def test_expedition_journal_is_registered_as_a_hud_tab(self):
        self.assertIn("local function renderExpeditions()", HUD)
        self.assertIn("Expeditions = renderExpeditions", HUD)
        self.assertIn('Expeditions = {"ДНЕВНИК"', HUD)
        self.assertIn('{id = "Expeditions", title = "ДНЕВНИК"', HUD)

    def test_grove_track_uses_existing_server_authoritative_discoveries(self):
        self.assertIn('id = "Grove", title = "СОЛНЕЧНАЯ РОЩА"', HUD)
        self.assertIn('{key = "Fox", title = "Познакомиться с лисёнком"', HUD)
        self.assertIn('{key = "Seed", title = "Найти лунное семя"', HUD)
        self.assertIn('{key = "FoxCaches", title = "Открыть три тайника"', HUD)
        self.assertIn('player:GetAttribute("FoxSearchCount")', HUD)
        self.assertIn('session.foxSearchCount += 1', WORLD)

    def test_dusk_track_uses_existing_persistent_moon_gate_milestones(self):
        self.assertIn('id = "Dusk", title = "СУМЕРЕЧНАЯ ДОЛИНА"', HUD)
        for key in ("Moth", "MoonBloom", "MoonGateTrace", "MoonGateOpen", "MoonRelic"):
            self.assertIn('key = "' + key + '"', HUD)
            self.assertIn('"' + key + '"', WORLD)

    def test_crystal_relic_collection_uses_persistent_discovery_flags(self):
        self.assertIn('id = "Discovered_StarPrism", name = "Звёздная призма"', HUD)
        self.assertIn('id = "Discovered_MoonGlass", name = "Лунное стекло"', HUD)
        self.assertIn('id = "Discovered_VoidGeode", name = "Пустотная жеода"', HUD)
        self.assertIn('player:GetAttribute(relic.id) == true', HUD)
        self.assertIn('foundRelics .. "/3"', HUD)
        self.assertIn('rewardButton.Activated:Connect', HUD)
        self.assertIn('event:FireServer("ClaimCrystalRelicSet")', HUD)
        self.assertIn('"CrystalRelicSetRewardClaimed"', WORLD)

    def test_crystal_relic_set_reward_is_server_validated_and_one_time(self):
        self.assertIn('if action == "ClaimCrystalRelicSet" then', WORLD)
        self.assertIn('player:GetAttribute("Discovered_StarPrism") ~= true', WORLD)
        self.assertIn('player:GetAttribute("Discovered_MoonGlass") ~= true', WORLD)
        self.assertIn('player:GetAttribute("Discovered_VoidGeode") ~= true', WORLD)
        self.assertIn('player:GetAttribute("CrystalRelicSetRewardClaimed") == true', WORLD)
        self.assertIn('session.coins = previousCoins + reward', WORLD)
        self.assertIn('if not save(player) then', WORLD)
        self.assertIn('player:SetAttribute("CrystalRelicSetRewardClaimed", false)', WORLD)

    def test_journal_is_read_only_and_refreshes_from_replicated_attributes(self):
        self.assertIn("return player:GetAttribute(step.key) == true", HUD)
        self.assertIn("player.AttributeChanged:Connect(refresh)", HUD)
        self.assertNotIn('event:FireServer("CompleteExpedition"', HUD)
        self.assertNotIn('player:SetAttribute("MoonRelic"', HUD)


if __name__ == "__main__":
    unittest.main()
