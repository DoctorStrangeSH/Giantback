"""Cross-species companion lineage research contract tests."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
APPEARANCE = (ROOT / "modules/CompanionAppearance.luau").read_text(encoding="utf-8")


class CompanionLineageTests(unittest.TestCase):
    def test_three_explicit_cross_species_combinations(self):
        for recipe, host, partner in (
            ("LunarScent", "Fox", "Moth"),
            ("PrismNose", "Fox", "CrystalWisp"),
            ("PrismDust", "Moth", "CrystalWisp"),
        ):
            self.assertIn(recipe + " = {", WORLD)
            self.assertIn('host = "' + host + '"', WORLD)
            self.assertIn('partner = "' + partner + '"', WORLD)

    def test_server_validates_both_owned_parents_active_host_and_bond(self):
        self.assertIn('player:GetAttribute(recipe.host) ~= true or player:GetAttribute(recipe.partner) ~= true', WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= recipe.host', WORLD)
        self.assertIn("if hostBond < 300 or partnerBond < 300 then", WORLD)
        self.assertIn('local recipe = type(recipeId) == "string" and companionLineageRecipes[recipeId] or nil', WORLD)

    def test_each_host_can_choose_only_one_lineage_path(self):
        self.assertIn("if session.companionLineages[recipe.host] then", WORLD)
        self.assertIn("and not hasOtherLineage", HUD)
        self.assertIn('or hasOtherLineage and "ДРУГОЙ ПУТЬ УЖЕ ВЫБРАН"', HUD)

    def test_costs_are_server_defined_and_consumed_atomically(self):
        self.assertIn("for itemId, amount in recipe.items do", WORLD)
        self.assertIn("session.inventory[itemId] -= amount", WORLD)
        self.assertIn("if not save(player) then", WORLD)
        self.assertIn("session.companionLineages[recipe.host] = previousLineage", WORLD)
        self.assertIn("for itemId, amount in previousAmounts do session.inventory[itemId] = amount end", WORLD)

    def test_lineage_is_normalized_loaded_saved_and_replicated(self):
        for marker in (
            "local function normalizeCompanionLineages(raw)",
            "companionLineages = normalizeCompanionLineages(nil)",
            "local companionLineageSnapshot = normalizeCompanionLineages(session.companionLineages)",
            "savedCompanion.lineage = companionLineageSnapshot[companionId]",
            "savedLineages[id] = saved.lineage",
            "session.companionLineages = normalizeCompanionLineages(savedLineages)",
            '"_LineageName"',
        ):
            self.assertIn(marker, WORLD)

    def test_discovery_rewards_are_applied_to_future_gift_searches(self):
        self.assertIn("if lineage and lineage.biome == biomeName then amount += 1 end", WORLD)
        self.assertIn('event:FireClient(player, "CompanionLineageDiscovered"', WORLD)

    def test_profile_shows_pair_requirements_and_gates_experiment(self):
        for marker in (
            'local lineageRecipes = {',
            'LunarScent = {host = "Fox", partner = "Moth"',
            'PrismNose = {host = "Fox", partner = "CrystalWisp"',
            'PrismDust = {host = "Moth", partner = "CrystalWisp"',
            "hostBond >= 300 and partnerBond >= 300",
            'event:FireServer("DiscoverCompanionLineage", recipeId)',
            "CompanionLineageDiscovered",
        ):
            self.assertIn(marker, HUD)

    def test_inherited_traits_have_unique_visual_treatments(self):
        for trait in ("LunarScent", "PrismNose", "PrismDust"):
            self.assertIn(trait + " = {color =", APPEARANCE)
        self.assertIn('owner:GetAttribute("Companion_" .. companionId .. "_Lineage")', APPEARANCE)
        self.assertIn("and lineageId or mutationId", APPEARANCE)


if __name__ == "__main__":
    unittest.main()
