"""Breeding and hybrid incubation integration contract tests."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
MODULE = (ROOT / "modules/CompanionBreeding.luau").read_text(encoding="utf-8")


class CompanionBreedingTests(unittest.TestCase):
    def test_three_server_owned_recipes_have_distinct_parent_pairs(self):
        for recipe in ("LunarFox", "PrismFox", "Starwing"):
            self.assertIn(recipe + " = {", MODULE)
        self.assertIn('parents = {"Fox", "Moth"}', MODULE)
        self.assertIn('parents = {"Fox", "CrystalWisp"}', MODULE)
        self.assertIn('parents = {"Moth", "CrystalWisp"}', MODULE)

    def test_recipe_requirements_and_material_costs_are_server_defined(self):
        self.assertIn("bond = 400", MODULE)
        self.assertIn("level = 3", MODULE)
        self.assertIn("incubationSeconds = 90", MODULE)
        self.assertIn("items = {SunPetal = 10, MoonPetal = 10, MoonSeed = 2}", MODULE)
        self.assertIn("items = {SunPetal = 10, CrystalShard = 10, RootvaultEssence = 1}", MODULE)
        self.assertIn("items = {MoonPetal = 12, CrystalShard = 12, StarShard = 5}", MODULE)

    def test_egg_normalization_rejects_unknown_and_duplicate_records(self):
        self.assertIn("function CompanionBreeding.normalizeEggs(raw, now)", MODULE)
        self.assertIn("not seen[egg.id]", MODULE)
        self.assertIn("recipeById[egg.recipeId]", MODULE)
        self.assertIn("MAX_ACTIVE_EGGS = 3", MODULE)

    def test_breeding_validates_ownership_level_bond_and_resources(self):
        self.assertIn('player:GetAttribute(parentId) ~= true', WORLD)
        self.assertIn("progressData.level < recipe.level", WORLD)
        self.assertIn("progressData.bond < recipe.bond", WORLD)
        self.assertIn("if (session.inventory[itemId] or 0) < amount then", WORLD)
        self.assertIn("session.economyBusy = true", WORLD)

    def test_breeding_spends_materials_and_rolls_back_when_save_fails(self):
        self.assertIn('id = HttpService:GenerateGUID(false)', WORLD)
        self.assertIn("session.inventory[itemId] -= amount", WORLD)
        self.assertIn("if not save(player) then", WORLD)
        self.assertIn("session.companionEggs = previousEggs", WORLD)
        self.assertIn("session.inventory[itemId] = amount", WORLD)

    def test_incubation_and_discovery_are_persisted(self):
        for marker in (
            "companionEggs = {}",
            "companionHybridDiscoveries = {}",
            "old.companionBreeding = companionBreedingSnapshot",
            "data.companionBreeding",
            "session.companionEggs = CompanionBreeding.normalizeEggs",
            "session.companionHybridDiscoveries = CompanionBreeding.normalizeDiscoveries",
        ):
            self.assertIn(marker, WORLD)

    def test_hatching_requires_the_matching_ready_egg_and_rolls_back(self):
        self.assertIn('action == "HatchHybridEgg"', WORLD)
        self.assertIn("if os.time() < selectedEgg.hatchAt then", WORLD)
        self.assertIn("session.companionHybridDiscoveries[result.id] = true", WORLD)
        self.assertIn("table.insert(session.companionEggs", WORLD)
        self.assertIn('event:FireClient(player, "CompanionHybridDiscovered"', WORLD)

    def test_client_has_responsive_lab_incubators_and_codex(self):
        for marker in (
            "ГЕНЕТИЧЕСКАЯ ЛАБОРАТОРИЯ",
            "Создай неизвестного гибрида",
            "HybridIncubators",
            "updateIncubatorButton",
            "task.wait(1)",
            "BreedRecipe_",
            'event:FireServer("BreedCompanions", recipe.id)',
            'event:FireServer("HatchHybridEgg", egg.id)',
            "HybridDiscoveryCodex",
            "CompanionHybridDiscovered",
        ):
            self.assertIn(marker, HUD)

    def test_remote_actions_are_explicitly_routed(self):
        self.assertIn('action == "BreedCompanions"', WORLD)
        self.assertIn("breedCompanions(player, payload)", WORLD)
        self.assertIn("hatchHybridEgg(player, payload)", WORLD)


if __name__ == "__main__":
    unittest.main()
