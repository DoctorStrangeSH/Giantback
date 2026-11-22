"""The generated Roblox place reserves safe imported-asset staging folders."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class AssetLibraryBuildTests(unittest.TestCase):
    def test_source_builder_creates_runtime_staging_folders(self):
        self.assertIn('def create_asset_library(service, categories)', BUILD)
        self.assertIn('create_asset_library(server_storage, ("Buildings", "Environment"))', BUILD)
        self.assertIn('create_asset_library(storage, ("Companions",))', BUILD)

    def test_import_folder_generation_does_not_replace_playable_blockouts(self):
        self.assertIn('for name in ("Fox", "Moth"):', BUILD)
        self.assertIn('model = obj(storage, "Model", name)', BUILD)

    def test_generated_place_asset_library_placement(self):
        place = ROOT / "Giantback.rbxlx"
        if not place.exists():
            self.skipTest("Place not generated yet; source builder contract remains active")
        root = ET.parse(place).getroot()
        def name(item):
            return item.findtext("./Properties/string[@name='Name']", default="")
        services = {name(item): item for item in root.findall("./Item")}
        for service_name, categories in (
            ("ServerStorage", {"Buildings", "Environment"}),
            ("ReplicatedStorage", {"Companions"}),
        ):
            with self.subTest(service=service_name):
                service = services[service_name]
                libraries = [item for item in service.findall("./Item") if name(item) == "AssetLibrary"]
                self.assertEqual(len(libraries), 1)
                models = [item for item in libraries[0].findall("./Item") if name(item) == "Models"]
                self.assertEqual(len(models), 1)
                self.assertTrue(categories.issubset({name(item) for item in models[0].findall("./Item")}))


if __name__ == "__main__":
    unittest.main()
