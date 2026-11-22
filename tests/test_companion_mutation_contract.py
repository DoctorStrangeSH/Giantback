from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class CompanionMutationContractTests(unittest.TestCase):
    def test_mutations_are_species_scoped_weighted_and_validated(self):
        self.assertIn('Fox = {', WORLD)
        self.assertIn('Moth = {', WORLD)
        self.assertIn('id = "Mossback"', WORLD)
        self.assertIn('id = "Sunblessed"', WORLD)
        self.assertIn('id = "Prismtail"', WORLD)
        self.assertIn('id = "Moonveil"', WORLD)
        self.assertIn('id = "Stardust"', WORLD)
        self.assertIn('id = "Aurora"', WORLD)
        self.assertIn("local function normalizeCompanionMutations(raw)", WORLD)
        self.assertIn("local function rollCompanionMutation(companionId, biomeId)", WORLD)

    def test_mutation_is_rolled_once_when_companion_is_owned_and_saved(self):
        self.assertIn("ensureCompanionMutation(player, id)", WORLD)
        self.assertIn('player:GetAttributeChangedSignal(companionId)', WORLD)
        self.assertIn('savedMutations[id] = saved.mutation', WORLD)
        self.assertIn('savedCompanion.mutation = session.companionMutations[companionId]', WORLD)
        self.assertIn('session.companionMutations = normalizeCompanionMutations(savedMutations)', WORLD)

    def test_mutation_metadata_is_replicated_for_collection_and_other_players(self):
        self.assertIn('"Companion_" .. companionId .. "_MutationName"', WORLD)
        self.assertIn('"Companion_" .. companionId .. "_MutationRarity"', WORLD)
        self.assertIn('entry.name.Text = names[id] .. " ✦ " .. mutationName', ALBUM)

    def test_discovery_roll_uses_the_actual_encounter_biome(self):
        self.assertIn("local function rollCompanionMutation(companionId, biomeId)", WORLD)
        self.assertIn("if definition.biome == biomeId then", WORLD)
        self.assertIn("rollCompanionMutation(companionId, discoveryBiome)", WORLD)
        self.assertIn("session.companionDiscoveryBiomes[id] = island.Name", WORLD)
        self.assertIn("ensureCompanionMutation(player, id)", WORLD)
        self.assertIn('encounter("Fox",workspace.Grove,1.8)', WORLD)
        self.assertIn('encounter("Moth",workspace.Dusk,3.5)', WORLD)

    def test_legendary_mutations_have_half_percent_weight_and_biome_identity(self):
        self.assertIn('id = "Elderwood", name = "Древесный дух", rarity = "Легендарный", weight = 1, biome = "Grove"', WORLD)
        self.assertIn('id = "Eclipse", name = "Затмение", rarity = "Легендарный", weight = 1, biome = "Dusk"', WORLD)
        self.assertIn('weight = 140, biome = "Grove"', WORLD)
        self.assertIn('weight = 48, biome = "Grove"', WORLD)
        self.assertIn('weight = 11, biome = "Grove"', WORLD)
        self.assertIn('weight = 140, biome = "Dusk"', WORLD)
        self.assertIn('weight = 48, biome = "Dusk"', WORLD)
        self.assertIn('weight = 11, biome = "Dusk"', WORLD)
        self.assertIn('"_MutationBiome"', WORLD)

    def test_legendary_mutations_receive_separate_particle_aura(self):
        self.assertIn('Elderwood = {color =', ALBUM)
        self.assertIn('Eclipse = {color =', ALBUM)
        self.assertIn('if visual.legendary then', ALBUM)
        self.assertIn('LegendaryMutationAttachment', ALBUM)
        self.assertIn('LegendaryMutationParticles', ALBUM)
        self.assertIn('mutationRarity == "Легендарный"', ALBUM)

    def test_visual_mutations_restore_base_colors_and_apply_bounded_tint(self):
        self.assertIn("local function applyCompanionMutation(model, owner, companionId)", ALBUM)
        self.assertIn("mutationOriginalColors", ALBUM)
        self.assertIn("part.Color = originalColor", ALBUM)
        self.assertIn("descendant.Color:Lerp(visual.color, accent and 0.58 or 0.24)", ALBUM)
        self.assertIn("CompanionMutationHighlight", ALBUM)
        self.assertIn("applyCompanionMutation(model, owner, id)", ALBUM)


if __name__ == "__main__":
    unittest.main()
