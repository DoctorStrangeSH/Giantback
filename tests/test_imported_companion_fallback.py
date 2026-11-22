"""Ensure imported companion meshes only replace blockouts after explicit Studio approval."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class ImportedCompanionFallbackTests(unittest.TestCase):
    def test_unreviewed_imports_cannot_replace_blockouts(self):
        self.assertIn('imported:GetAttribute("GiantbackImportStatus") ~= "Approved"', CLIENT)
        self.assertIn('imported:GetAttribute("GiantbackRuntimeReady") ~= true', CLIENT)
        self.assertIn('imported:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true', CLIENT)

    def test_only_expected_mesh_parts_can_be_selected(self):
        self.assertIn('Fox = "FoxCompanion", Moth = "MothCompanion"', CLIENT)
        self.assertIn('local body = imported:FindFirstChild("Body")', CLIENT)
        self.assertIn('local movingPartName = id == "Fox" and "Tail" or "Wing"', CLIENT)
        self.assertIn('movingPart:IsA("MeshPart")', CLIENT)
        self.assertIn('local movingPart = imported:FindFirstChild(movingPartName)', CLIENT)
        self.assertIn('body:IsA("MeshPart")', CLIENT)

    def test_fallback_is_retained_for_unapproved_or_missing_assets(self):
        self.assertIn('local fallback = storage:FindFirstChild(id)', CLIENT)
        self.assertIn('local function companionTemplate(id)', CLIENT)
        self.assertIn('local template = companionTemplate(id)', CLIENT)
        self.assertIn('model = template:Clone()', CLIENT)
        self.assertNotIn('model = storage[id]:Clone()', CLIENT)

    def test_does_not_mutate_server_owned_template(self):
        source = CLIENT.split("local function companionTemplate(id)", 1)[1].split("local function follow(dt)", 1)[0]
        self.assertNotIn(":Destroy()", source)
        self.assertNotIn('SetAttribute(', source)
        self.assertNotIn('instance.new', source.lower())


if __name__ == "__main__":
    unittest.main()
