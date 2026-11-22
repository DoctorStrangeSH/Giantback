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
        self.assertIn("local function rollCompanionMutation(companionId)", WORLD)

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

    def test_visual_mutations_restore_base_colors_and_apply_bounded_tint(self):
        self.assertIn("local function applyCompanionMutation(model, owner, companionId)", ALBUM)
        self.assertIn("mutationOriginalColors", ALBUM)
        self.assertIn("part.Color = originalColor", ALBUM)
        self.assertIn("descendant.Color:Lerp(visual.color, accent and 0.58 or 0.24)", ALBUM)
        self.assertIn("CompanionMutationHighlight", ALBUM)
        self.assertIn("applyCompanionMutation(model, owner, id)", ALBUM)


if __name__ == "__main__":
    unittest.main()
