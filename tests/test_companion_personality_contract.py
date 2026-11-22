from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class CompanionPersonalityContractTests(unittest.TestCase):
    def test_server_assigns_a_stable_species_specific_personality(self):
        self.assertIn('local companionPersonalities = {"Любопытный", "Озорной", "Смелый", "Застенчивый"}', WORLD)
        self.assertIn("local function getCompanionPersonality(userId, companionId)", WORLD)
        self.assertIn("((math.abs(userId) + speciesOffset) % #companionPersonalities) + 1", WORLD)
        self.assertIn('player:SetAttribute("Companion_" .. id .. "_Personality", getCompanionPersonality(player.UserId, id))', WORLD)

    def test_fox_idle_curiosity_frequency_depends_on_personality(self):
        self.assertIn('["Любопытный"] = {5, 10}', ALBUM)
        self.assertIn('["Озорной"] = {6, 11}', ALBUM)
        self.assertIn('["Смелый"] = {9, 15}', ALBUM)
        self.assertIn('["Застенчивый"] = {15, 23}', ALBUM)
        self.assertIn('owner:GetAttribute("Companion_Fox_Personality")', ALBUM)

    def test_moth_orbit_and_stardust_depend_on_personality(self):
        self.assertIn('["Любопытный"] = 0.9', ALBUM)
        self.assertIn('["Озорной"] = 1.18', ALBUM)
        self.assertIn('["Смелый"] = 0.78', ALBUM)
        self.assertIn('["Застенчивый"] = 0.52', ALBUM)
        self.assertIn('owner:GetAttribute("Companion_Moth_Personality")', ALBUM)
        self.assertIn('["Озорной"] = 12', ALBUM)
        self.assertIn('["Застенчивый"] = 4', ALBUM)


if __name__ == "__main__":
    unittest.main()
