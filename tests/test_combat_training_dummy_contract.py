"""Static contracts for the live, reward-free combat practice target."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class TrainingDummyContract(unittest.TestCase):
    def test_target_is_spawned_in_playable_arena(self):
        self.assertIn('dummy.Name = "GroveTrainingDummy01"', WORLD)
        self.assertIn('dummy:SetAttribute("RegionId", "GroveTraining")', WORLD)
        self.assertIn('CollectionService:AddTag(dummy, "GiantbackEnemy")', WORLD)
        self.assertIn('dummyRoot.CanQuery = false', WORLD)
        self.assertIn('piece.CanQuery = true', WORLD)

    def test_existing_combat_pipeline_validates_hits(self):
        self.assertIn('GroveTrainingDummy01 = true', COMBAT)
        self.assertIn('entry.regionId == getPlayerRegion(player)', COMBAT)
        self.assertIn('dealEnemyDamage(enemy, entry, COMBO_DAMAGE[comboStep])', COMBAT)
        self.assertIn('dealEnemyDamage(enemy, entry, damage)', COMBAT)
        self.assertIn('dealEnemyDamage(target, targetEntry, damage)', COMBAT)

    def test_no_aggression_or_repeatable_reward(self):
        self.assertIn('and not entry.isTrainingDummy do', COMBAT)
        self.assertIn('if entry.isTrainingDummy then return end', COMBAT)
        self.assertIn('and not entry.isTrainingDummy then', COMBAT)
        self.assertIn('math.max(0, entry.humanoid.Health - 1)', COMBAT)
        self.assertIn('task.delay(2.5, function()', COMBAT)
        self.assertIn('entry.trainingGeneration ~= generation', COMBAT)
        self.assertIn('entry.humanoid.Health = entry.humanoid.MaxHealth', COMBAT)

    def test_bundled_in_existing_place_scripts(self):
        self.assertIn('"WorldVisuals.server.luau", "Combat.server.luau"', BUILD)


if __name__ == "__main__":
    unittest.main()
