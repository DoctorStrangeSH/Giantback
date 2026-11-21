from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")


class MothLunarGlowContractTests(unittest.TestCase):
    def test_moonbloom_is_a_persisted_progress_flag(self):
        self.assertIn('"MoonBloom"', WORLD)
        self.assertIn("for _, key in progress do snapshot[key] = player:GetAttribute(key) == true end", WORLD)
        self.assertIn("old[key] = old[key] == true or snapshot[key]", WORLD)

    def test_dusk_contains_a_hidden_queryable_moonbloom_anchor(self):
        self.assertIn('part(model, "MoonBloom"', BUILD)
        self.assertIn('prop(moon_bloom, "float", "Transparency", "1")', BUILD)
        self.assertIn('prop(moon_bloom, "bool", "CanCollide", "false")', BUILD)
        self.assertIn('prop(moon_bloom, "bool", "CanTouch", "false")', BUILD)
        self.assertIn('prop(moon_bloom, "bool", "CanQuery", "true")', BUILD)

    def test_moonbloom_has_an_original_hidden_moonlit_visual(self):
        self.assertIn('moonBloom.Name = "MoonBloomVisual"', VISUALS)
        self.assertIn('"Moon petal"', VISUALS)
        self.assertIn('"Moon heart"', VISUALS)
        self.assertIn("moonLight.Enabled = false", VISUALS)

    def test_server_discovery_requires_the_equipped_moth(self):
        self.assertIn('if action == "CollectMoonBloom" then', WORLD)
        self.assertIn("local function collectMoonBloom(player)", WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= "Moth"', WORLD)

    def test_server_checks_personal_state_anchor_and_interaction_distance(self):
        self.assertIn('if player:GetAttribute("MoonBloom") then', WORLD)
        self.assertIn('local anchor = dusk and dusk:FindFirstChild("MoonBloom")', WORLD)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 10', WORLD)
        self.assertIn('player:SetAttribute("MoonBloom", true)', WORLD)

    def test_first_discovery_grants_two_moon_petals_and_syncs_inventory(self):
        self.assertIn("session.inventory.MoonPetal = (session.inventory.MoonPetal or 0) + 2", WORLD)
        self.assertIn("syncInventory(player)", WORLD)
        self.assertIn("Лунная моль раскрыла тайный цветок", WORLD)

    def test_client_hides_the_visual_until_moth_or_personal_discovery(self):
        self.assertIn("local function updateMothBloomReveal()", ALBUM)
        self.assertIn("local revealed = mothEquipped or found", ALBUM)
        self.assertIn("descendant.LocalTransparencyModifier = revealed and 0 or 1", ALBUM)
        self.assertIn("descendant.Enabled = revealed", ALBUM)

    def test_local_prompt_and_highlight_are_personal_to_the_moth_owner(self):
        self.assertIn('mothBloomPrompt.Name = "MoonBloomLocalPrompt"', ALBUM)
        self.assertIn('mothBloomPrompt.Enabled = mothEquipped and not found', ALBUM)
        self.assertIn('event:FireServer("CollectMoonBloom")', ALBUM)
        self.assertIn('mothBloomHighlight.Name = "MoonBloomHighlight"', ALBUM)
        self.assertIn("mothBloomHighlight.Enabled = mothEquipped and not found", ALBUM)

    def test_first_expedition_visits_moonbloom_after_meeting_the_moth(self):
        moth = ALBUM.index('{flag = "Moth",')
        moon_bloom = ALBUM.index('{flag = "MoonBloom",')
        flower = ALBUM.index('{flag = "Flower",')
        self.assertLess(moth, moon_bloom)
        self.assertLess(moon_bloom, flower)
        self.assertIn('if not player:GetAttribute("MoonBloom") then', HUD)
        self.assertIn("её сияние раскроет скрытый цветок", HUD)


if __name__ == "__main__":
    unittest.main()
