"""Harvest feedback lives in an isolated cosmetic-only ModuleScript."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
FEEDBACK = (ROOT / "modules/HarvestFeedback.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class HarvestFeedbackTests(unittest.TestCase):
    def test_module_is_embedded_and_used_by_client(self):
        self.assertIn('harvest_feedback = obj(storage, "ModuleScript", "HarvestFeedback")', BUILD)
        self.assertIn('require(storage:WaitForChild("HarvestFeedback"))', CLIENT)
        self.assertIn("HarvestFeedback.new(player, function(nodeId)", CLIENT)
        for marker in ("harvestFeedback.onHit", "harvestFeedback.clearHit",
                       "harvestFeedback.rewardPickup", "harvestFeedback.breakFeedback"):
            self.assertIn(marker, CLIENT)

    def test_impact_and_reward_effects_are_not_removed(self):
        for marker in ("LocalHarvestProgress", "LocalHarvestCracks", "LocalHarvestChip",
                       "LocalResourceReward", "LocalHarvestFinalBurst", "LocalHarvestFinalFragment",
                       "HarvestImpact", "local function playResourceRewardPickup(payload)",
                       "local function showResourceHitFeedback(payload)",
                       "local function clearResourceHitFeedback(nodeId)"):
            with self.subTest(marker=marker):
                self.assertIn(marker, FEEDBACK)

    def test_no_server_authority_and_per_node_cancel_guards_survive(self):
        for forbidden in ("FireServer(", "InvokeServer(", "DataStoreService", "SetAttribute("):
            self.assertNotIn(forbidden, FEEDBACK)
        self.assertIn("resourceHitEffects[nodeId] = effectGeneration", FEEDBACK)
        self.assertIn("resourceHitEffects[nodeId] ~= effectGeneration", FEEDBACK)
        self.assertIn("resourceHitBars[nodeId] = nil", FEEDBACK)
        self.assertIn('message == "ResourcePicked"', CLIENT)
        self.assertIn('message == "ResourceHit"', CLIENT)
        self.assertIn('playResourceBreakAnimation(payload.nodeId)', CLIENT)

    def test_forward_declared_lookup_is_closed_over_lazily(self):
        self.assertIn("local findResourceNode", CLIENT)
        self.assertIn("findResourceNode = function(nodeId)", CLIENT)
        self.assertIn("return findResourceNode(nodeId)", CLIENT)
        self.assertIn("local node = findNode(nodeId)", FEEDBACK)
        self.assertNotIn("local findResourceNode", FEEDBACK)


if __name__ == "__main__":
    unittest.main()
