from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
FOLLOW = (ROOT / "modules/CompanionFollow.luau").read_text(encoding="utf-8")
ACTIVITY = (ROOT / "modules/CompanionActivity.luau").read_text(encoding="utf-8")


class CompanionPersonalityContractTests(unittest.TestCase):
    def test_server_assigns_a_stable_species_specific_personality(self):
        self.assertIn('local companionPersonalities = {"Любопытный", "Озорной", "Смелый", "Застенчивый"}', WORLD)
        self.assertIn("local function getDefaultCompanionPersonality(userId, companionId)", WORLD)
        self.assertIn("((math.abs(userId) + speciesOffset) % #companionPersonalities) + 1", WORLD)
        self.assertIn("local function normalizeCompanionPersonalities(raw, userId)", WORLD)
        self.assertIn('player:SetAttribute("Companion_" .. id .. "_Personality", session.companionPersonalities[id])', WORLD)

    def test_personalities_are_saved_and_restored_with_companion_profile(self):
        self.assertIn("companionPersonalities = normalizeCompanionPersonalities(nil, player.UserId)", WORLD)
        self.assertIn("savedPersonalities[id] = saved.personality", WORLD)
        self.assertIn("session.companionPersonalities = normalizeCompanionPersonalities(savedPersonalities, player.UserId)", WORLD)
        self.assertIn("savedCompanion.personality = session.companionPersonalities[companionId]", WORLD)

    def test_unknown_or_missing_saved_personality_uses_safe_default(self):
        self.assertIn("companionPersonalitySet[saved]", WORLD)
        self.assertIn("and saved or getDefaultCompanionPersonality(userId, id)", WORLD)

    def test_relationship_stage_is_synced_from_bond_thresholds(self):
        self.assertIn('progressData.bond >= 900 and 4', WORLD)
        self.assertIn('progressData.bond >= 600 and 3', WORLD)
        self.assertIn('progressData.bond >= 300 and 2', WORLD)
        self.assertIn('progressData.bond >= 100 and 1', WORLD)
        self.assertIn('"_BondStage", bondStage', WORLD)

    def test_higher_bond_changes_fox_and_moth_idle_behavior(self):
        self.assertIn('owner:GetAttribute("Companion_" .. id .. "_BondStage")', ACTIVITY)
        self.assertIn('window[1] - bondStage * 1.5', ACTIVITY)
        self.assertIn('window[2] - bondStage * 2', ACTIVITY)
        self.assertIn('personalityRadius - bondStage * 0.035', FOLLOW)
        self.assertIn('local function updateMothStardust(model, owner)', ALBUM)
        self.assertIn('emitter:GetAttribute("AppliedBondStage") == bondStage', ALBUM)
        self.assertIn('updateMothStardust(model, owner)', ALBUM)

    def test_fox_idle_curiosity_frequency_depends_on_personality(self):
        self.assertIn('["Любопытный"] = {5, 10}', ACTIVITY)
        self.assertIn('["Озорной"] = {6, 11}', ACTIVITY)
        self.assertIn('["Смелый"] = {9, 15}', ACTIVITY)
        self.assertIn('["Застенчивый"] = {15, 23}', ACTIVITY)
        self.assertIn('owner:GetAttribute("Companion_Fox_Personality")', ACTIVITY)

    def test_moth_orbit_and_stardust_depend_on_personality(self):
        self.assertIn('["Любопытный"] = 0.9', FOLLOW)
        self.assertIn('["Озорной"] = 1.18', FOLLOW)
        self.assertIn('["Смелый"] = 0.78', FOLLOW)
        self.assertIn('["Застенчивый"] = 0.52', FOLLOW)
        self.assertIn('owner:GetAttribute("Companion_Moth_Personality")', FOLLOW)
        self.assertIn('["Озорной"] = 12', ALBUM)
        self.assertIn('["Застенчивый"] = 4', ALBUM)


if __name__ == "__main__":
    unittest.main()
