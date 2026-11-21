from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "source_models"
REQUIRED = (
    "fox_companion",
    "moth_companion",
    "home_cottage",
    "farm_bed",
    "bridge_segment",
    "home_island",
)


class OriginalMeshSourceTests(unittest.TestCase):
    def test_every_source_mesh_has_a_matching_material_file(self):
        for stem in REQUIRED:
            obj = ASSET_DIR / f"{stem}.obj"
            mtl = ASSET_DIR / f"{stem}.mtl"
            self.assertTrue(obj.is_file(), stem)
            self.assertTrue(mtl.is_file(), stem)
            self.assertIn(f"mtllib {stem}.mtl", obj.read_text(encoding="utf-8"))

    def test_obj_files_have_geometry_and_valid_face_indices(self):
        for stem in REQUIRED:
            content = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            lines = content.splitlines()
            vertices = [line for line in lines if line.startswith("v ")]
            faces = [line for line in lines if line.startswith("f ")]
            self.assertGreater(len(vertices), 40, stem)
            self.assertGreater(len(faces), 30, stem)
            for face in faces:
                for token in face.split()[1:]:
                    index = int(token.split("/")[0])
                    self.assertGreater(index, 0, stem)
                    self.assertLessEqual(index, len(vertices), stem)

    def test_every_used_material_is_declared(self):
        for stem in REQUIRED:
            obj = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            mtl = (ASSET_DIR / f"{stem}.mtl").read_text(encoding="utf-8")
            used = set(re.findall(r"^usemtl\s+(\S+)", obj, re.MULTILINE))
            declared = set(re.findall(r"^newmtl\s+(\S+)", mtl, re.MULTILINE))
            self.assertTrue(used, stem)
            self.assertTrue(used.issubset(declared), f"{stem}: {used - declared}")


    def test_world_visual_palette_defines_every_referenced_color(self):
        script = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
        palette_block = re.search(r"local palette = \{(.*?)\n\}", script, re.DOTALL)
        self.assertIsNotNone(palette_block)
        declared = set(re.findall(r"^\s+([A-Za-z_]\w*)\s*=", palette_block.group(1), re.MULTILINE))
        referenced = set(re.findall(r"palette\.([A-Za-z_]\w*)", script))
        self.assertTrue(referenced)
        self.assertEqual(referenced - declared, set())

    def test_companion_sources_keep_named_rigging_parts(self):
        fox = (ASSET_DIR / "fox_companion.obj").read_text(encoding="utf-8")
        moth = (ASSET_DIR / "moth_companion.obj").read_text(encoding="utf-8")
        for name in ("FoxBody", "FoxHead", "FoxTail", "FoxTailTip", "FoxLegFrontLeft"):
            self.assertIn(f"o {name}", fox)
        for name in ("MothBody", "MothHead", "MothUpperWingLeft", "MothUpperWingRight", "MothUpperWingRoot", "MothLowerWingLeft", "MothLowerWingRight", "MothLowerWingRoot", "MothWingTipLeft", "MothWingTipRight", "MothAntennaLeft", "MothAntennaRight", "MothEyeLeft", "MothEyeRight", "MothGlowCore"):
            self.assertIn(f"o {name}", moth)

    def test_island_has_separate_grass_and_cliff_materials(self):
        island = (ASSET_DIR / "home_island.obj").read_text(encoding="utf-8")
        self.assertIn("o IslandGrassTop", island)
        self.assertIn("o IslandCliff", island)
        self.assertIn("usemtl grass", island)
        self.assertIn("usemtl cliff", island)

    def test_moth_wing_and_antenna_meshes_are_split_for_independent_animation(self):
        moth = (ASSET_DIR / "moth_companion.obj").read_text(encoding="utf-8")
        blocks = re.split(r"(?=^o )", moth, flags=re.MULTILINE)
        by_name = {block.splitlines()[0][2:]: block for block in blocks if block.startswith("o ")}
        for left, right in (
            ("MothUpperWingLeft", "MothUpperWingRight"),
            ("MothLowerWingLeft", "MothLowerWingRight"),
            ("MothWingTipLeft", "MothWingTipRight"),
            ("MothAntennaLeft", "MothAntennaRight"),
            ("MothEyeLeft", "MothEyeRight"),
        ):
            self.assertRegex(by_name[left], r"(?m)^f ")
            self.assertRegex(by_name[right], r"(?m)^f ")

    def test_fox_source_mesh_keeps_every_animated_limb_and_face_detail_separate(self):
        fox = (ASSET_DIR / "fox_companion.obj").read_text(encoding="utf-8")
        for name in (
            "FoxBody", "FoxBelly", "FoxHead", "FoxMuzzle",
            "FoxEarLeft", "FoxEarRight", "FoxEarInner",
            "FoxLegFrontLeft", "FoxLegFrontRight",
            "FoxLegBackLeft", "FoxLegBackRight",
            "FoxTail", "FoxTailTip", "FoxEyes", "FoxEyeSparkles", "FoxNose",
        ):
            self.assertIn(f"o {name}", fox)


if __name__ == "__main__":
    unittest.main()
