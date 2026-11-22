from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class FarmingRegistryTests(unittest.TestCase):
    def test_four_crops_have_server_owned_growth_and_rewards(self):
        expected = {
            "Carrot": ('seedItemId = "CarrotSeed"', "growthSeconds = 300", "reward = 1"),
            "Strawberry": ('seedItemId = "StrawberrySeed"', "growthSeconds = 720", "regrowSeconds = 480", "reward = 2"),
            "Pumpkin": ('seedItemId = "PumpkinSeed"', "growthSeconds = 1800", "reward = 1"),
            "Cabbage": ('seedItemId = "CabbageSeed"', "growthSeconds = 1200", "reward = 1"),
        }
        for crop_id, fragments in expected.items():
            self.assertIn(crop_id + " = {", WORLD)
            for fragment in fragments:
                self.assertIn(fragment, WORLD)

    def test_seed_and_harvest_items_are_in_persistent_inventory(self):
        for item in ("StrawberrySeed", "Strawberry", "PumpkinSeed", "Pumpkin", "CabbageSeed", "Cabbage"):
            self.assertIn('"' + item + '"', WORLD)
        self.assertIn("session.inventory.StrawberrySeed = 2", WORLD)
        self.assertIn("session.inventory.PumpkinSeed = 1", WORLD)
        self.assertIn("session.inventory.CabbageSeed = 1", WORLD)

    def test_crop_selection_is_server_validated_and_requires_seed(self):
        self.assertIn('if action == "SelectCrop" then', WORLD)
        self.assertIn("local definition = cropDefinitions[cropId]", WORLD)
        self.assertIn("session.selectedCropId = cropId", WORLD)
        self.assertIn("session.inventory[definition.seedItemId] or 0", WORLD)
        self.assertIn('player:SetAttribute("Farm_SelectedCrop"', WORLD)

    def test_harvest_is_guarded_and_strawberry_regrows(self):
        self.assertIn("session.farmActionBusy[plotId]", WORLD)
        self.assertIn("definition.regrowSeconds", WORLD)
        self.assertIn("state.readyAt = now + definition.regrowSeconds", WORLD)
        self.assertIn("session.inventory[definition.harvestItemId]", WORLD)
        self.assertIn("if now < state.readyAt then", WORLD)

    def test_growth_is_persisted_as_server_timestamps(self):
        self.assertIn("plantedAt = safeTimestamp(saved.plantedAt)", WORLD)
        self.assertIn("readyAt = safeTimestamp(saved.readyAt)", WORLD)
        self.assertIn("state.plantedAt = now", WORLD)
        self.assertIn("state.readyAt = now + definition.growthSeconds", WORLD)


if __name__ == "__main__":
    unittest.main()
