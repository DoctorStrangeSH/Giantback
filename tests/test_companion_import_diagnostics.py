"""Contract checks for the read-only Roblox Studio import diagnostics."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHECKER = (ROOT / "tools/roblox/inspect_companion_imports.luau").read_text(encoding="utf-8")


class CompanionImportDiagnosticsTests(unittest.TestCase):
    def test_expected_pets_and_asset_keys(self):
        self.assertIn('FoxCompanion = {key = "fox_companion"', CHECKER)
        self.assertIn('MothCompanion = {key = "moth_companion"', CHECKER)

    def test_checks_procedural_animation_safety(self):
        for marker in (
            'model:FindFirstChild("Body")',
            'body:IsA("MeshPart")',
            'desc:IsA("Bone")',
            'desc:IsA("WeldConstraint")',
            'desc:IsA("JointInstance")',
            'desc.CanCollide',
            'desc.MeshId',
            'model:GetExtentsSize()',
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, CHECKER)

    def test_separate_mesh_parts_required_for_animation(self):
        self.assertIn('descendant:IsA("MeshPart")', CHECKER)
        self.assertIn('model.Name == "MothCompanion" and partName == "Wing"', CHECKER)
        self.assertIn('and 2 or 1', CHECKER)
        self.assertIn('matchingMeshes < requiredCount', CHECKER)

    def test_no_automatic_approval_or_mutation(self):
        for forbidden in (":Destroy()", ":Clone()", ".Parent =", ":SetAttribute(", "GiantbackRuntimeReady = true"):
            self.assertNotIn(forbidden, CHECKER)
        self.assertIn("Selection:Get()", CHECKER)
        self.assertIn("Diagnostics complete. No assets or approval flags were changed.", CHECKER)

    def test_manual_studio_acceptance_remains_required(self):
        self.assertIn('GiantbackImportStatus") ~= "Approved"', CHECKER)
        self.assertIn('GiantbackProceduralAnimationCompatible") ~= true', CHECKER)
        self.assertIn("mobile performance still need Studio playtest", CHECKER)


if __name__ == "__main__":
    unittest.main()
