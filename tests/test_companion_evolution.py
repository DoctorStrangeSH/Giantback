"""Secret companion evolution is server-owned, persistent, and visible in the pet profile."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
APPEARANCE = (ROOT / "modules/CompanionAppearance.luau").read_text(encoding="utf-8")


class CompanionEvolutionTests(unittest.TestCase):
    def test_only_three_starter_species_have_explicit_secret_forms(self):
        recipes = {
            "Fox": ("VerdantGuardian", "SunPetal", "MoonSeed", "RootvaultEssence"),
            "Moth": ("LunarOracle", "MoonPetal", "StarShard", "MoonSeed"),
            "CrystalWisp": ("PrismSovereign", "CrystalShard", "CrystalSigil", "VoidGeode"),
        }
        for species, values in recipes.items():
            self.assertIn(species + " = {", WORLD)
            for value in values:
                self.assertIn(value, WORLD)
        self.assertIn('rarity = "Секретная"', WORLD)

    def test_evolution_requires_level_bond_and_server_inventory(self):
        self.assertIn("if progressData.level < requirements.level or progressData.bond < requirements.bond then", WORLD)
        self.assertIn("if (session.inventory[itemId] or 0) < amount then", WORLD)
        self.assertIn("session.inventory[itemId] -= amount", WORLD)
        self.assertIn("player:GetAttribute(companionId) ~= true", WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= companionId', WORLD)
        self.assertIn("if not session.online then", WORLD)

    def test_evolution_is_saved_inside_existing_companion_profile_and_normalized(self):
        self.assertIn("local function normalizeCompanionEvolutions(raw)", WORLD)
        self.assertIn("companionEvolutions = normalizeCompanionEvolutions(nil)", WORLD)
        self.assertIn("local companionEvolutionSnapshot = normalizeCompanionEvolutions(session.companionEvolutions)", WORLD)
        self.assertIn("savedCompanion.evolution = companionEvolutionSnapshot[companionId]", WORLD)
        self.assertIn("savedEvolutions[id] = saved.evolution", WORLD)
        self.assertIn("session.companionEvolutions = normalizeCompanionEvolutions(savedEvolutions)", WORLD)

    def test_resource_spend_and_evolution_roll_back_together_if_save_fails(self):
        self.assertIn("local previousEvolution = session.companionEvolutions[companionId]", WORLD)
        self.assertIn("session.companionEvolutions[companionId] = definition.id", WORLD)
        self.assertIn("if not save(player) then", WORLD)
        self.assertIn("session.companionEvolutions[companionId] = previousEvolution", WORLD)
        self.assertIn("for itemId, amount in previousAmounts do session.inventory[itemId] = amount end", WORLD)

    def test_client_cannot_select_evolution_or_reward_and_action_is_routed(self):
        self.assertIn('if action == "EvolveCompanion" then', WORLD)
        self.assertIn("evolveCompanion(player, payload)", WORLD)
        self.assertIn("local definition = companionEvolutionDefinitions[companionId]", WORLD)
        self.assertIn('event:FireClient(player, "CompanionEvolved"', WORLD)

    def test_profile_shows_requirements_and_only_enables_ready_evolution(self):
        for marker in (
            'local evolutionRecipes = {',
            'Fox = {name = "Страж древней рощи"',
            'Moth = {name = "Оракул лунного света"',
            'CrystalWisp = {name = "Владыка призмы"',
            'local evolutionReady = owned and equipped and level >= 5 and bond >= 900 and enoughResources and not evolutionUnlocked',
            'event:FireServer("EvolveCompanion", selectedPet.id)',
            'CompanionEvolved',
        ):
            self.assertIn(marker, HUD)

    def test_secret_forms_override_mutation_tint_and_have_distinct_legendary_aura(self):
        for form in ("VerdantGuardian", "LunarOracle", "PrismSovereign"):
            self.assertIn(form + " = {color =", APPEARANCE)
        self.assertIn('owner:GetAttribute("Companion_" .. companionId .. "_Evolution")', APPEARANCE)
        self.assertIn("and evolutionId or mutationId", APPEARANCE)
        self.assertIn("if visual.legendary then", APPEARANCE)


if __name__ == "__main__":
    unittest.main()
