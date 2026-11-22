"""Ensure only approved imported companion rigs replace playable blockouts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
RESOLVER = (ROOT / "modules/CompanionTemplateResolver.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class ImportedCompanionFallbackTests(unittest.TestCase):
    def test_unreviewed_imports_cannot_replace_blockouts(self):
        for marker in (
            'imported:GetAttribute("GiantbackImportStatus") ~= "Approved"',
            'imported:GetAttribute("GiantbackRuntimeReady") ~= true',
            'imported:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true',
        ):
            self.assertIn(marker, RESOLVER)

    def test_only_expected_direct_meshparts_can_be_selected(self):
        self.assertIn('Fox = "FoxCompanion", Moth = "MothCompanion"', RESOLVER)
        self.assertIn('model:FindFirstChild(name)', RESOLVER)
        self.assertIn('part:IsA("MeshPart")', RESOLVER)
        self.assertIn('usablePart(imported, "Body")', RESOLVER)
        self.assertIn('local movingPartName = id == "Fox" and "Tail" or "Wing"', RESOLVER)
        self.assertIn('usablePart(imported, movingPartName)', RESOLVER)

    def test_fallback_is_retained_for_unapproved_or_missing_assets(self):
        self.assertIn('local fallback = storage:FindFirstChild(id)', RESOLVER)
        self.assertIn('local function companionTemplate(id)', CLIENT)
        self.assertIn('return CompanionTemplateResolver.resolve(storage, id)', CLIENT)
        self.assertIn('local template = companionTemplate(id)', CLIENT)
        self.assertIn('model = template:Clone()', CLIENT)
        self.assertNotIn('model = storage[id]:Clone()', CLIENT)

    def test_module_is_embedded_in_place_and_not_mutated(self):
        self.assertIn('resolver = obj(storage, "ModuleScript", "CompanionTemplateResolver")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionTemplateResolver"))', CLIENT)
        for forbidden in (':Destroy()', ':SetAttribute(', 'Instance.new('):
            self.assertNotIn(forbidden, RESOLVER)


if __name__ == "__main__":
    unittest.main()
