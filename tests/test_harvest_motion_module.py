"""Harvest camera/character/tool feedback is isolated from reward authority."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
MOTION = (ROOT / "modules/HarvestMotion.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class HarvestMotionModuleTests(unittest.TestCase):
    def test_motion_module_embeds_and_connects_to_client(self):
        self.assertIn('harvest_motion = obj(storage, "ModuleScript", "HarvestMotion")', BUILD)
        self.assertIn('modules" / "HarvestMotion.luau', BUILD)
        self.assertIn('require(storage:WaitForChild("HarvestMotion"))', CLIENT)
        self.assertIn('HarvestMotion.new(player)', CLIENT)
        self.assertIn('local playHarvestToolSwing = harvestMotion.playToolSwing', CLIENT)
        self.assertIn('local playHarvestCameraShake = harvestMotion.playCameraShake', CLIENT)

    def test_motion_keeps_its_independent_generation_guards(self):
        self.assertIn('local toolSwingGeneration = 0', MOTION)
        self.assertIn('local cameraShakeGeneration = 0', MOTION)
        self.assertIn('if generation ~= toolSwingGeneration', MOTION)
        self.assertIn('if generation ~= cameraShakeGeneration', MOTION)
        self.assertIn('RunService:UnbindFromRenderStep(cameraShakeBinding)', MOTION)
        self.assertIn('player:GetAttribute("HarvestCameraShakeEnabled") == false', MOTION)

    def test_character_animation_and_tool_sequence_preserved(self):
        self.assertIn('local function playHarvestCharacterSwing(character, nodeId, generation)', MOTION)
        self.assertIn('shoulder.Transform = shoulder.Transform * pose', MOTION)
        self.assertIn('tool:GetAttribute("PetKingdomsToolId")', MOTION)
        self.assertIn('first.Completed:Once(function()', MOTION)
        self.assertIn('second.Completed:Once(function()', MOTION)
        self.assertIn('playHarvestToolSwing(nodeId)', CLIENT)
        self.assertIn('playHarvestCameraShake(0.58)', CLIENT)

    def test_visual_module_never_awards_inventory_or_edits_server_state(self):
        for forbidden in ('FireServer(', 'InvokeServer(', 'SetAttribute(', 'DataStoreService', 'ResourcePicked'):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, MOTION)
        self.assertIn('message == "ResourceHit"', CLIENT)
        self.assertIn('message == "ResourcePicked"', CLIENT)


if __name__ == "__main__":
    unittest.main()
