"""Contract checks for ResourceNodeVisibility extracted from Album client."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
MODULE = (ROOT / "modules/ResourceNodeVisibility.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class ResourceNodeVisibilityTests(unittest.TestCase):
    def test_module_embedded_and_required_by_active_client(self):
        self.assertIn('resource_visibility = obj(storage, "ModuleScript", "ResourceNodeVisibility")', BUILD)
        self.assertIn('require(storage:WaitForChild("ResourceNodeVisibility"))', CLIENT)
        self.assertIn('ResourceNodeVisibility.new(findResourceNode, restoreResourceGrowth)', CLIENT)

    def test_server_authoritative_cooldowns_and_cancelled_delayed_callbacks(self):
        self.assertIn('resourceVisibilityGeneration[nodeId] = generation', MODULE)
        self.assertIn('if resourceVisibilityGeneration[nodeId] == generation then', MODULE)
        self.assertIn('(tonumber(readyAt) or 0) - os.time()', MODULE)
        self.assertIn('hideResourceNodeWhenReady(nodeId, generation, 0)', MODULE)

    def test_new_resource_models_keep_collected_state(self):
        self.assertIn('descendant:GetAttribute("ResourceNodeId")', MODULE)
        self.assertIn('if nodeId and resourceNodeHidden[nodeId] then', MODULE)
        self.assertIn('workspace.DescendantAdded:Connect(resourceVisibility.onDescendantAdded)', CLIENT)
        self.assertIn('descendant.Enabled = visible', MODULE)
        self.assertIn('descendant.LocalTransparencyModifier = visible and 0 or 1', MODULE)

    def test_geometry_callbacks_retain_local_scope_and_respawn_effect(self):
        self.assertIn('local findResourceNode', CLIENT)
        self.assertIn('findResourceNode = function(nodeId)', CLIENT)
        self.assertIn('local function restoreResourceGrowth(model)', CLIENT)
        self.assertIn('playResourceRegrowthBurst(model)', CLIENT)
        self.assertIn('resourceVisibility.apply(nodeId, readyAt, unique)', CLIENT)


if __name__ == "__main__":
    unittest.main()
