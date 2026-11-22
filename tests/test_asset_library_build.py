"""The generated Roblox place reserves safe imported-asset staging folders."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class AssetLibraryBuildTests(unittest.TestCase):
    def test_source_builder_creates_runtime_staging_folders(self):
        self.assertIn('def create_asset_library(service, categories)', BUILD)
        self.assertIn('create_asset_library(server_storage, ("Buildings", "Environment"))', BUILD)
        self.assertIn('create_asset_library(storage, ("Companions",))', BUILD)

    def test_companion_resolver_is_embedded_as_module_script(self):
        self.assertIn('resolver = obj(storage, "ModuleScript", "CompanionTemplateResolver")', BUILD)
        self.assertIn('(root / "modules" / "CompanionTemplateResolver.luau").read_text(encoding="utf-8")', BUILD)

    def test_import_folder_generation_does_not_replace_playable_blockouts(self):
        self.assertIn('for name in ("Fox", "Moth"):', BUILD)
        self.assertIn('model = obj(storage, "Model", name)', BUILD)



if __name__ == "__main__":
    unittest.main()
