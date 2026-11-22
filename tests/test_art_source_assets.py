import ast
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
from fox_rig_contract import validate_rig_payload
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


class FoxHeroVisualWorkflowContractTests(unittest.TestCase):
    def test_visual_workflow_does_not_cancel_active_renders(self):
        workflow = ROOT / ".github" / "workflows" / "fox-hero-visual-review.yml"
        self.assertTrue(workflow.is_file())
        source = workflow.read_text(encoding="utf-8")
        self.assertIn("bpy==4.2.0", source)
        self.assertIn("cancel-in-progress: false", source)
        self.assertNotIn("cancel-in-progress: true", source)
        self.assertIn("timeout-minutes: 35", source)

    def test_visual_workflow_keeps_four_view_and_mesh_quality_gate(self):
        source = (ROOT / ".github" / "workflows" / "fox-hero-visual-review.yml").read_text(encoding="utf-8")
        for view in ("three_quarter", "front", "side", "back"):
            self.assertIn(f"fox_companion_hero_{view}.png", source)
        for check in (
            "zero_area_faces", "non_manifold_edges", "uv_layers",
            "material_profiles", "soft_fur",
        ):
            self.assertIn(check, source)


class FoxHeroMeshGeneratorTests(unittest.TestCase):
    def test_hero_generator_is_valid_python_and_keeps_source_non_destructive(self):
        path = ROOT / "tools" / "blender" / "build_fox_companion.py"
        self.assertTrue(path.is_file())
        source = path.read_text(encoding="utf-8")
        compile(source, str(path), "exec")
        self.assertIn('obj_path = output / "fox_companion_hero.obj"', source)
        self.assertIn('blend_path = output / "fox_companion_hero.blend"', source)
        self.assertIn('if output.exists() and any(output.iterdir()) and not args.overwrite', source)
        self.assertNotIn('fox_companion.obj"', source)

    def test_fox_hero_palette_and_layered_chest_ruff_are_present(self):
        source = (ROOT / "tools" / "blender" / "build_fox_companion.py").read_text(encoding="utf-8")
        self.assertIn('"fox_orange": material("fox_orange", (0.90, 0.065, 0.001), 0.90, soft_fur=True)', source)
        self.assertIn('"cream": material("cream", (0.92, 0.72, 0.48), 0.92, soft_fur=True)', source)
        self.assertIn('curved_plume("ChestRuffCenter"', source)
        self.assertIn('curved_plume("ChestRuffLeft"', source)
        self.assertIn('curved_plume("ChestRuffRight"', source)
        self.assertIn('"FoxBelly": ["FoxBelly", "ChestRuffCenter", "ChestRuffLeft", "ChestRuffRight"]', source)

    def test_review_lighting_preserves_fox_color_and_form_contrast(self):
        source = (ROOT / "tools" / "blender" / "build_fox_companion.py").read_text(encoding="utf-8")
        self.assertIn('("Key", (1.8, 2.8, -2.0), 175, 3.2)', source)
        self.assertIn('("Fill", (-2.0, 1.0, -1.0), 75, 2.8)', source)
        self.assertIn('("Rim", (0.0, 2.0, 2.8), 125, 2.4)', source)
        self.assertIn('scene.view_settings.look = "AgX - High Contrast"', source)

    def test_review_cameras_use_explicit_y_up_basis_for_all_views(self):
        source = (ROOT / "tools" / "blender" / "build_fox_companion.py").read_text(encoding="utf-8")
        self.assertIn("from mathutils import Matrix, Vector", source)
        self.assertIn("world_up = Vector((0.0, 1.0, 0.0))", source)
        self.assertIn("right = forward.cross(world_up).normalized()", source)
        self.assertIn("camera_up = right.cross(forward).normalized()", source)
        self.assertIn("Matrix((right, camera_up, back)).transposed()", source)

    def test_hero_generator_preserves_all_seventeen_runtime_rig_groups(self):
        source = (ROOT / "tools" / "blender" / "build_fox_companion.py").read_text(encoding="utf-8")
        expected = (
            "FoxBody", "FoxBelly", "FoxHead", "FoxMuzzle",
            "FoxEarLeft", "FoxEarRight", "FoxEarInnerLeft", "FoxEarInnerRight",
            "FoxLegFrontLeft", "FoxLegFrontRight",
            "FoxLegBackLeft", "FoxLegBackRight",
            "FoxTail", "FoxTailTip", "FoxEyes", "FoxEyeSparkles", "FoxNose",
        )
        for group in expected:
            self.assertIn('"' + group + '"', source)
        self.assertIn("bpy.ops.uv.smart_project(", source)
        self.assertIn("bpy.ops.uv.pack_islands(", source)
        self.assertIn("export_uv=True", source)
        self.assertIn("export_normals=True", source)
        self.assertIn("def write_mesh_quality_report(output, objects):", source)
        self.assertIn("fox_companion_hero_mesh_report.json", source)
        self.assertIn("if not obj.data.uv_layers:", source)
        self.assertIn("if not obj.data.materials or any(mat is None for mat in obj.data.materials):", source)
        self.assertIn("import bmesh", source)
        self.assertIn("bmesh.ops.recalc_face_normals(bm, faces=bm.faces)", source)
        self.assertIn("face.calc_area() <= 1e-10", source)
        self.assertIn("not edge.is_manifold", source)
        self.assertIn('"non_manifold_edges": 0', source)

    def test_hero_rig_sidecar_matches_all_groups_and_has_valid_pivots(self):
        source_path = ROOT / "tools" / "blender" / "build_fox_companion.py"
        tree = ast.parse(source_path.read_text(encoding="utf-8"))
        assignments = {
            node.targets[0].id: ast.literal_eval(node.value)
            for node in tree.body
            if isinstance(node, ast.Assign)
            and len(node.targets) == 1
            and isinstance(node.targets[0], ast.Name)
            and node.targets[0].id in {"GROUPS", "RIG_PARTS"}
        }
        groups = assignments["GROUPS"]
        parts = assignments["RIG_PARTS"]
        payload = {
            "asset": "fox_companion_hero",
            "coordinate_system": "Y-up; character faces -Z",
            "units": "source model units",
            "parts": parts,
        }
        result = validate_rig_payload(payload, expected_groups=groups)
        self.assertEqual(result["part_count"], 17)
        self.assertEqual(result["animated_count"], 12)
        self.assertEqual(result["attachment_count"], 3)

    def test_hero_rig_validator_rejects_missing_groups_and_bad_pivots(self):
        source_path = ROOT / "tools" / "blender" / "build_fox_companion.py"
        tree = ast.parse(source_path.read_text(encoding="utf-8"))
        assignments = {
            node.targets[0].id: ast.literal_eval(node.value)
            for node in tree.body
            if isinstance(node, ast.Assign)
            and len(node.targets) == 1
            and isinstance(node.targets[0], ast.Name)
            and node.targets[0].id in {"GROUPS", "RIG_PARTS"}
        }
        payload = {
            "asset": "fox_companion_hero",
            "coordinate_system": "Y-up; character faces -Z",
            "units": "source model units",
            "parts": assignments["RIG_PARTS"],
        }
        with self.assertRaisesRegex(ValueError, "group mismatch"):
            validate_rig_payload(payload, expected_groups=assignments["GROUPS"] + ("Unexpected",))
        broken = {**payload, "parts": {**payload["parts"], "FoxTail": {**payload["parts"]["FoxTail"], "pivot": [0, float("nan"), 1]}}}
        with self.assertRaisesRegex(ValueError, "three finite numbers"):
            validate_rig_payload(broken, expected_groups=assignments["GROUPS"])

    def test_hero_rig_validator_rejects_unknown_attachment_parent(self):
        payload = {
            "asset": "fox_companion_hero",
            "coordinate_system": "Y-up; character faces -Z",
            "units": "source model units",
            "parts": {
                "FoxTail": {"runtime_name": "Tail", "pivot": [0, 0, 0], "animated": True},
                "FoxTailTip": {"runtime_name": "Tail tip", "pivot": [0, 1, 0], "animated": True, "attach_to": "MissingTail"},
            },
        }
        with self.assertRaisesRegex(ValueError, "unknown group"):
            validate_rig_payload(payload)

    def test_hero_generator_has_separate_face_ear_tail_and_paw_forms(self):
        source = (ROOT / "tools" / "blender" / "build_fox_companion.py").read_text(encoding="utf-8")
        for feature in ("CheekFluff_L", "CheekFluff_R", "FoxEarInner_L",
                        "FoxEarInner_R", "FoxTailTip", "EyeShineLeft",
                        "EyeShineRight", "PawFrontLeft", "PawBackRight"):
            self.assertIn(feature, source)
        self.assertIn("curved_plume(", source)
        self.assertIn("leaf_mesh(", source)
        self.assertIn('"EyeLidUpper" + suffix', source)
        self.assertIn('"EyeShineSmall" + suffix', source)
        self.assertIn('"EyeLidUpperLeft", "EyeLidUpperRight"', source)
        self.assertIn('"EyeShineSmallLeft", "EyeShineSmallRight"', source)
        self.assertIn("def material(name, color, roughness=0.72, metallic=0.0, soft_fur=False):", source)
        self.assertIn("ShaderNodeTexNoise", source)
        self.assertIn("ShaderNodeBump", source)
        self.assertIn('"Sheen Weight"].default_value = 0.08', source)
        self.assertIn('"Sheen Roughness"].default_value = 0.72', source)
        self.assertIn('noise.inputs["Scale"].default_value = 16.0', source)
        self.assertIn('bump.inputs["Strength"].default_value = 0.004', source)
        self.assertIn('bump.inputs["Distance"].default_value = 0.002', source)
        self.assertIn('"giantback_surface_profile"] = "soft_fur"', source)
        self.assertIn('"material_profiles": {', source)
        self.assertIn('"fox_orange": material("fox_orange", (0.90, 0.065, 0.001), 0.90, soft_fur=True)', source)
        self.assertIn('"cream": material("cream", (0.92, 0.72, 0.48), 0.92, soft_fur=True)', source)
        self.assertIn("true single-vertex poles and clean topology", source)
        self.assertIn("verts, faces = [(cx, cy + sy, cz)], []", source)
        self.assertIn("bottom = len(verts)", source)
        self.assertIn("faces.append((0, first_ring + side, first_ring + nxt))", source)
        self.assertNotIn("faces.append(tuple(range(segments - 1, -1, -1)))", source)
        self.assertIn("def leaf_mesh(", source)
        self.assertIn("ring_count, sides = 25, 32", source)
        self.assertIn("profile = max(0.018, math.sin(math.pi * (t ** 0.82)) ** 0.78)", source)
        self.assertIn("center_x = cx + (t ** 1.55)", source)
        self.assertIn('curved_plume("ForeheadTuft"', source)
        self.assertIn('curved_plume("ForeheadTuft_L"', source)
        self.assertIn('curved_plume("ForeheadTuft_R"', source)
        self.assertIn('"paw_detail": material("paw_detail", (0.66, 0.34, 0.22), 0.78)', source)
        self.assertIn('curved_plume("PawToeFront" + suffix + str(toe)', source)
        self.assertIn('curved_plume("PawToeBack" + suffix + str(toe)', source)
        self.assertIn('"PawToeFrontLeft0", "PawToeFrontLeft1", "PawToeFrontLeft2"', source)
        self.assertIn('"ForeheadTuft_L", "ForeheadTuft_R"', source)
        self.assertIn('ellipsoid("CheekFluff_L"', source)
        self.assertIn('ellipsoid("CheekFluff_R"', source)
        self.assertIn('(-0.285, 1.435, -1.025), (0.072, 0.048, 0.022)', source)
        self.assertIn('(0.285, 1.435, -1.025), (0.072, 0.048, 0.022)', source)
        self.assertIn("Rounded cream cheek pads blend into the muzzle", source)
        self.assertIn("def plush_tail(", source)
        self.assertIn('plush_tail("FoxTail"', source)
        self.assertIn('plush_tail("FoxTailTip"', source)
        self.assertIn("(0.12, 1.91, 1.99), (0.10, 1.96, 2.04)", source)
        self.assertIn("[0.27, 0.255, 0.205, 0.115, 0.012]", source)
        self.assertIn("widths[segment]", source)
        self.assertIn("depths[segment]", source)
        self.assertIn("def organic_torso(", source)
        self.assertIn('organic_torso("FoxBody"', source)
        self.assertIn('organic_torso("FoxBelly"', source)
        self.assertIn('organic_torso("FoxLegFront" + suffix', source)
        self.assertIn('organic_torso("FoxLegBack" + suffix', source)
        self.assertIn("def sculpted_head(", source)
        self.assertIn("def lofted_muzzle(", source)
        self.assertIn('sculpted_head("FoxHead"', source)
        self.assertIn('lofted_muzzle("FoxMuzzle"', source)
        self.assertIn("cheek = 1.0 + 0.16", source)
        self.assertIn("jaw_taper = 1.0 - 0.20", source)
        self.assertIn('\"BrowLeft\"', source)
        self.assertIn('\"BrowRight\"', source)
        self.assertIn('\"Smile\"', source)
        self.assertIn('\"expression\": material(\"expression\"', source)
        self.assertIn('"FoxHead": ["FoxHead", "ForeheadTuft", "ForeheadTuft_L", "ForeheadTuft_R", "BrowLeft", "BrowRight"]', source)
        self.assertIn('\"FoxMuzzle\": [\"FoxMuzzle\", \"CheekFluff_L\", \"CheekFluff_R\", \"Smile\"]', source)
        self.assertIn("def render_review_views(", source)
        for view in ("three_quarter", "front", "side", "back"):
            self.assertIn('"' + view + '"', source)
            self.assertIn('fox_companion_hero_{view_name}.png', source)
        self.assertIn("REVIEW_ONLY_Ground", source)
        self.assertIn("floor.rotation_euler.x = math.radians(90.0)", source)
        self.assertIn("# Blender planes are created in XY (normal +Z); the character uses Y-up.", source)
        self.assertIn("data.use_shadow = True", source)
        self.assertIn("def write_rig_metadata(output, objects):", source)
        self.assertIn('fox_companion_hero_rig.json', source)
        self.assertIn('"FoxEarInnerLeft"', source)
        self.assertIn('"FoxEarInnerRight"', source)
        self.assertIn('"attach_to": "FoxEarLeft"', source)
        self.assertIn('"attach_to": "FoxEarRight"', source)
        self.assertIn('"FoxTail": {"runtime_name": "Tail", "pivot": [0.15, 1.02, 0.68]', source)
        self.assertIn('"obj_note": "OBJ does not preserve object origins;', source)


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

    def test_collapsed_uv_faces_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self._write_obj(Path(directory), """v 0 0 0
v 1 0 0
v 0 1 0
vt 0.5 0.5
vt 0.5 0.5
vt 0.5 0.5
vn 0 0 1
f 1/1/1 2/2/1 3/3/1
""")
            with self.assertRaisesRegex(RuntimeError, "zero-area UVs"):
                validate_obj(path)

    def test_validator_reports_uv_face_area_for_review(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self._write_obj(Path(directory), """v 0 0 0
v 1 0 0
v 0 1 0
vt 0 0
vt 1 0
vt 0 1
vn 0 0 1
f 1/1/1 2/2/1 3/3/1
""")
            result = validate_obj(path)
            self.assertEqual(result["uv_degenerate_faces"], 0)
            self.assertAlmostEqual(result["uv_face_area_total"], 0.5)

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
