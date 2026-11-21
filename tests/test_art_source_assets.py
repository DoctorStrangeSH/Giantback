from pathlib import Path
import re
import struct
import sys
import tempfile
import unittest
import zlib


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "source_models"
sys.path.insert(0, str(ROOT / "tools" / "blender"))
from obj_export_validation import validate_obj
from generate_uv_checker import build_checker
REQUIRED = (
    "fox_companion",
    "moth_companion",
    "home_cottage",
    "farm_bed",
    "bridge_segment",
    "home_island",
)



class BlenderUVPipelineContractTests(unittest.TestCase):
    def test_blender_uv_preview_script_is_valid_python(self):
        script_path = ROOT / "tools" / "blender" / "prepare_source_uv.py"
        self.assertTrue(script_path.is_file())
        source = script_path.read_text(encoding="utf-8")
        compile(source, str(script_path), "exec")

    def test_blender_uv_preview_protects_sources_and_existing_previews(self):
        source = (ROOT / "tools" / "blender" / "prepare_source_uv.py").read_text(encoding="utf-8")
        self.assertIn("input_dir == output_dir", source)
        self.assertIn("if existing and not args.overwrite_previews", source)
        self.assertIn("--overwrite-previews", source)
        self.assertIn("FileExistsError", source)
        self.assertIn("source_sha256", source)

    def test_blender_uv_preview_uses_tested_obj_validator_and_checks_material_library(self):
        source = (ROOT / "tools" / "blender" / "prepare_source_uv.py").read_text(encoding="utf-8")
        self.assertIn("from obj_export_validation import sha256_file, validate_obj", source)
        self.assertIn("export_stats = validate_obj(destination)", source)
        self.assertIn("material_file = destination.with_suffix(\".mtl\")", source)
        self.assertIn("material_file.name not in export_stats[\"material_libraries\"]", source)


class BlenderUVReviewRendererTests(unittest.TestCase):
    def test_review_renderer_is_valid_python_and_non_destructive(self):
        path = ROOT / "tools" / "blender" / "render_uv_preview.py"
        self.assertTrue(path.is_file())
        source = path.read_text(encoding="utf-8")
        compile(source, str(path), "exec")
        self.assertIn("input_path = args.input.resolve()", source)
        self.assertIn("checker_path = args.checker.resolve()", source)
        self.assertIn("if existing and not args.overwrite", source)
        self.assertIn("FileExistsError", source)
        self.assertIn("save_as_mainfile", source)
        self.assertIn("write_still=True", source)

    def test_review_renderer_requires_uvs_and_uses_diagnostic_only_material(self):
        source = (ROOT / "tools" / "blender" / "render_uv_preview.py").read_text(encoding="utf-8")
        self.assertIn("if not obj.data.uv_layers", source)
        self.assertIn("TEMP_UV_DIAGNOSTIC_CHECKER", source)
        self.assertIn("Diagnostic only", source)
        self.assertIn('scene.render.engine = "BLENDER_EEVEE_NEXT"', source)
        self.assertIn('scene.render.image_settings.file_format = "PNG"', source)


class UVCheckerTextureTests(unittest.TestCase):
    def test_checker_generator_emits_valid_rgb_png_with_expected_dimensions(self):
        png = build_checker(size=128, tiles=8, subdivisions=4)
        self.assertTrue(png.startswith(bytes((137, 80, 78, 71, 13, 10, 26, 10))))
        offset = 8
        chunks = {}
        while offset < len(png):
            length = struct.unpack(">I", png[offset:offset + 4])[0]
            kind = png[offset + 4:offset + 8]
            payload = png[offset + 8:offset + 8 + length]
            chunks.setdefault(kind, []).append(payload)
            offset += 12 + length
        width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
            ">IIBBBBB", chunks[b"IHDR"][0]
        )
        self.assertEqual((width, height, bit_depth, color_type), (128, 128, 8, 2))
        self.assertEqual((compression, filtering, interlace), (0, 0, 0))
        pixels = zlib.decompress(b"".join(chunks[b"IDAT"]))
        self.assertEqual(len(pixels), height * (1 + width * 3))
        self.assertIn(b"IEND", chunks)

    def test_checker_generator_rejects_invalid_dimensions_and_grid(self):
        with self.assertRaises(ValueError):
            build_checker(size=100, tiles=8)
        with self.assertRaises(ValueError):
            build_checker(size=128, tiles=1)


class BlenderObjExportValidationTests(unittest.TestCase):
    def _write_obj(self, directory: Path, content: str) -> Path:
        path = directory / "preview.obj"
        path.write_text(content, encoding="utf-8")
        return path

    def test_valid_obj_with_uv_normals_and_material_reference(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self._write_obj(Path(directory), """mtllib preview.mtl
v 0 0 0
v 1 0 0
v 0 1 0
vt 0 0
vt 1 0
vt 0 1
vn 0 0 1
usemtl fur
f 1/1/1 2/2/1 3/3/1
""")
            result = validate_obj(path)
            self.assertEqual(result["vertices"], 3)
            self.assertEqual(result["uv_coordinates"], 3)
            self.assertEqual(result["normals"], 1)
            self.assertEqual(result["faces"], 1)
            self.assertEqual(result["material_libraries"], ["preview.mtl"])
            self.assertEqual(result["material_uses"], 1)
            self.assertEqual(len(result["sha256"]), 64)

    def test_valid_obj_supports_negative_relative_indices(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self._write_obj(Path(directory), """v 0 0 0
v 1 0 0
v 0 1 0
vt 0 0
vt 1 0
vt 0 1
vn 0 0 1
f -3/-3/-1 -2/-2/-1 -1/-1/-1
""")
            self.assertEqual(validate_obj(path)["faces"], 1)

    def test_invalid_vertex_uv_and_normal_indices_are_rejected(self):
        fixtures = (
            ("v 0 0 0\nv 1 0 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 4/3/1\n", "vertex index out of range"),
            ("v 0 0 0\nv 1 0 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/4/1\n", "UV index out of range"),
            ("v 0 0 0\nv 1 0 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/3/2\n", "normal index out of range"),
        )
        for content, message in fixtures:
            with self.subTest(message=message), tempfile.TemporaryDirectory() as directory:
                path = self._write_obj(Path(directory), content)
                with self.assertRaisesRegex(RuntimeError, message):
                    validate_obj(path)

    def test_uv_coordinates_outside_atlas_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self._write_obj(Path(directory), """v 0 0 0
v 1 0 0
v 0 1 0
vt 0 0
vt 1.2 0
vt 0 1
vn 0 0 1
f 1/1/1 2/2/1 3/3/1
""")
            with self.assertRaisesRegex(RuntimeError, "exceeds the 0-1 range"):
                validate_obj(path)

    def test_faces_without_uv_or_normal_data_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self._write_obj(Path(directory), """v 0 0 0
v 1 0 0
v 0 1 0
vt 0 0
vt 1 0
vt 0 1
vn 0 0 1
f 1//1 2//1 3//1
""")
            with self.assertRaisesRegex(RuntimeError, "missing vertex, UV or normal"):
                validate_obj(path)


    def test_blender_uv_preview_is_non_destructive_and_exports_uv_normals(self):
        source = (ROOT / "tools" / "blender" / "prepare_source_uv.py").read_text(encoding="utf-8")
        self.assertIn("bpy.ops.uv.smart_project(", source)
        self.assertIn("bpy.ops.uv.pack_islands(", source)
        self.assertIn("export_uv=True", source)
        self.assertIn("export_normals=True", source)
        self.assertIn("export_object_groups=True", source)
        self.assertIn('"final_art_approved": False', source)
        main_block = source.split("def main()", 1)[1]
        self.assertIn('source = input_dir / f"{asset}.obj"', main_block)
        self.assertIn('destination = output_dir / f"{asset}.obj"', main_block)
        self.assertIn("export_preview(objects, destination)", main_block)


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



    def test_source_mesh_dimensions_stay_within_import_scale_contract(self):
        # Dimensions are source-space units, not Roblox-imported MeshPart measurements.
        expected_dimensions = {
            "fox_companion": (1.36, 2.65, 3.54),
            "moth_companion": (3.18, 1.97, 1.11),
            "home_cottage": (12.55, 11.38, 13.85),
            "farm_bed": (7.51, 1.39, 4.85),
            "bridge_segment": (6.20, 2.50, 5.50),
            "home_island": (68.73, 20.95, 52.86),
        }
        for stem, expected in expected_dimensions.items():
            vertices = []
            for line in (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8").splitlines():
                if line.startswith("v "):
                    vertices.append(tuple(float(value) for value in line.split()[1:4]))
            actual = tuple(
                max(vertex[axis] for vertex in vertices) - min(vertex[axis] for vertex in vertices)
                for axis in range(3)
            )
            for axis, (measured, target) in enumerate(zip(actual, expected)):
                self.assertAlmostEqual(measured, target, delta=0.025, msg=f"{stem} axis {axis} scale drift")

    def test_source_meshes_stay_within_provisional_mobile_geometry_budgets(self):
        # These are source-mesh guardrails, not a substitute for Roblox device profiling.
        face_budgets = {
            "fox_companion": 6000,
            "moth_companion": 4000,
            "home_cottage": 1800,
            "farm_bed": 3500,
            "bridge_segment": 1200,
            "home_island": 1000,
        }
        vertex_budgets = {
            "fox_companion": 3500,
            "moth_companion": 2200,
            "home_cottage": 1000,
            "farm_bed": 2000,
            "bridge_segment": 600,
            "home_island": 500,
        }
        for stem in REQUIRED:
            lines = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8").splitlines()
            vertices = sum(line.startswith("v ") for line in lines)
            faces = sum(line.startswith("f ") for line in lines)
            self.assertLessEqual(vertices, vertex_budgets[stem], f"{stem} vertex budget")
            self.assertLessEqual(faces, face_budgets[stem], f"{stem} face budget")




    def test_companion_obj_groups_match_the_documented_rig_mapping(self):
        expected = {
            "fox_companion": {
                "FoxBody", "FoxBelly", "FoxHead", "FoxMuzzle",
                "FoxEarLeft", "FoxEarRight", "FoxEarInner",
                "FoxLegFrontLeft", "FoxLegFrontRight",
                "FoxLegBackLeft", "FoxLegBackRight",
                "FoxTail", "FoxTailTip", "FoxEyes", "FoxEyeSparkles", "FoxNose",
            },
            "moth_companion": {
                "MothBody", "MothHead",
                "MothUpperWingLeft", "MothUpperWingRight", "MothUpperWingRoot",
                "MothLowerWingLeft", "MothLowerWingRight", "MothLowerWingRoot",
                "MothWingTipLeft", "MothWingTipRight",
                "MothAntennaLeft", "MothAntennaRight",
                "MothEyeLeft", "MothEyeRight", "MothGlowCore",
            },
        }
        for stem, required_groups in expected.items():
            content = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            actual_groups = set(re.findall(r"^o (.+)$", content, re.MULTILINE))
            self.assertEqual(actual_groups, required_groups, f"{stem}: rig group mapping changed")


    def test_every_source_face_references_a_valid_unit_face_normal(self):
        for stem in REQUIRED:
            content = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            normals = []
            corner_count = 0
            face_count = 0
            for line in content.splitlines():
                if line.startswith("vn "):
                    normal = tuple(float(value) for value in line.split()[1:4])
                    self.assertEqual(len(normal), 3, stem)
                    length = sum(value * value for value in normal) ** 0.5
                    self.assertAlmostEqual(length, 1.0, delta=0.002, msg=f"{stem}: non-unit normal")
                    normals.append(normal)
                elif line.startswith("f "):
                    face_count += 1
                    tokens = line.split()[1:]
                    self.assertGreaterEqual(len(tokens), 3, stem)
                    for token in tokens:
                        corner_count += 1
                        parts = token.split("/")
                        self.assertEqual(len(parts), 3, f"{stem}: face lacks explicit normal")
                        self.assertEqual(parts[1], "", f"{stem}: unexpected unreviewed UV index")
                        normal_index = int(parts[2])
                        self.assertGreater(normal_index, 0, stem)
                        self.assertLessEqual(normal_index, len(normals), stem)
            self.assertEqual(len(normals), corner_count, f"{stem}: expected a crease-aware normal per face corner")
            self.assertGreater(len(normals), face_count, f"{stem}: corner normals were not generated")

    def test_obj_faces_do_not_contain_zero_area_triangles(self):
        for stem in REQUIRED:
            content = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            vertices = []
            for line in content.splitlines():
                if line.startswith("v "):
                    vertices.append(tuple(float(value) for value in line.split()[1:4]))
                    continue
                if not line.startswith("f "):
                    continue
                indices = [int(token.split("/")[0]) - 1 for token in line.split()[1:]]
                self.assertGreaterEqual(len(indices), 3, stem)
                for offset in range(1, len(indices) - 1):
                    a, b, c = (vertices[indices[index]] for index in (0, offset, offset + 1))
                    ab = tuple(b[i] - a[i] for i in range(3))
                    ac = tuple(c[i] - a[i] for i in range(3))
                    cross = (
                        ab[1] * ac[2] - ab[2] * ac[1],
                        ab[2] * ac[0] - ab[0] * ac[2],
                        ab[0] * ac[1] - ab[1] * ac[0],
                    )
                    area_twice = sum(value * value for value in cross) ** 0.5
                    self.assertGreater(area_twice, 1e-9, f"{stem}: zero-area face {indices}")

    def test_every_named_mesh_group_contains_geometry(self):
        for stem in REQUIRED:
            content = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            groups = re.split(r"(?=^o )", content, flags=re.MULTILINE)
            named_groups = [block for block in groups if block.startswith("o ")]
            self.assertGreater(len(named_groups), 0, stem)
            for block in named_groups:
                name = block.splitlines()[0][2:]
                self.assertRegex(block, r"(?m)^f ", f"{stem}: empty group {name}")

    def test_source_material_library_has_no_unused_or_invalid_materials(self):
        for stem in REQUIRED:
            obj = (ASSET_DIR / f"{stem}.obj").read_text(encoding="utf-8")
            mtl = (ASSET_DIR / f"{stem}.mtl").read_text(encoding="utf-8")
            used = set(re.findall(r"^usemtl\s+(\S+)", obj, re.MULTILINE))
            declared = set(re.findall(r"^newmtl\s+(\S+)", mtl, re.MULTILINE))
            self.assertEqual(declared - used, set(), f"{stem}: unused materials")
            blocks = re.split(r"(?=^newmtl )", mtl, flags=re.MULTILINE)
            for block in blocks:
                if not block.startswith("newmtl "):
                    continue
                name = block.splitlines()[0][7:]
                for property_name in ("Ka", "Kd", "Ks"):
                    match = re.search(rf"^{property_name}\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s*$", block, re.MULTILINE)
                    self.assertIsNotNone(match, f"{stem}/{name}: missing {property_name}")
                    values = [float(value) for value in match.groups()]
                    self.assertTrue(all(0.0 <= value <= 1.0 for value in values), f"{stem}/{name}: invalid {property_name}")

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
