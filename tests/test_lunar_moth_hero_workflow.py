from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class LunarMothHeroWorkflowTests(unittest.TestCase):
    def test_generator_is_separate_from_legacy_blockout(self):
        source = (ROOT / "tools" / "blender" / "build_moth_companion.py").read_text(encoding="utf-8")
        self.assertIn("The legacy moth_companion.obj is never modified.", source)
        self.assertIn('parser.add_argument("--output-dir"', source)
        self.assertIn("bpy.ops.wm.save_as_mainfile", source)
        self.assertIn("bpy.ops.wm.obj_export", source)

    def test_four_wings_have_independent_uv_mapped_meshes(self):
        source = (ROOT / "tools" / "blender" / "build_moth_companion.py").read_text(encoding="utf-8")
        for name in (
            "MothWingUpperLeft", "MothWingUpperRight",
            "MothWingLowerLeft", "MothWingLowerRight",
        ):
            self.assertIn(name, source)
        self.assertIn('uv=mesh.uv_layers.new(name="WingUV")', source)
        self.assertIn("span = 1.42 if upper else 1.04", source)
        self.assertIn("outer_radius, inner_radius, inner_offset = 0.31, 0.255, 0.145", source)
        self.assertIn("curve.bevel_depth = 0.042", source)
        self.assertIn("length = 0.82 if upper else 0.66", source)
        self.assertIn("0.08 + 0.92 * (math.sin", source)
        self.assertIn("width = (0.08 + 0.92 * (math.sin(math.pi * t) ** 0.75)) * span * 1.05", source)
        self.assertIn('"wing_groups":["MothWingUpperLeft","MothWingUpperRight","MothWingLowerLeft","MothWingLowerRight"]', source)

    def test_lunar_palette_and_gameplay_animation_states_are_locked(self):
        source = (ROOT / "tools" / "blender" / "build_moth_companion.py").read_text(encoding="utf-8")
        for material in ("wing_lilac", "wing_rose", "wing_cyan", "moon_gold", "moon_core"):
            self.assertIn(f'mat("{material}"', source)
        for state in ("idle_hover", "follow", "reveal_secret", "ability_burst", "rest"):
            self.assertIn(state, source)
        self.assertIn('curve.splines.new("BEZIER")', source)
        self.assertIn('curve.bevel_depth = 0.022', source)
        self.assertIn('def crescent(name, center, side, material):', source)
        self.assertIn('outer_front, inner_front = [], []', source)
        self.assertIn('faces.append((index, nxt, count + nxt, count + index))', source)
        self.assertIn('outer_back = [(x, y, z + thickness) for x, y, z in outer_front]', source)
        self.assertIn('WingMoon" + wing_name + suffix', source)
        self.assertNotIn('WingMoonGold', source)
        self.assertIn('def moth_leg(name, side, start_y, end_y, material):', source)
        self.assertIn('MothThoraxLeg', source)
        self.assertIn('return "MothThorax"', source)
        self.assertIn('def tapered_body(name, profile, material, segments=40):', source)
        self.assertIn('parts.append(tapered_body("MothThorax",body_profile,ivory))', source)
        self.assertIn('def abdomen_band(name, y, rx, rz, material, segments=40):', source)
        self.assertIn('(ol, oln, ohn, oh)', source)
        self.assertIn('(il, ih, ihn, iln)', source)
        self.assertIn('(oh, ohn, ihn, ih)', source)
        self.assertIn('(ol, il, iln, oln)', source)
        self.assertIn('parts.append(abdomen_band(f"AbdomenBand{band_index}"', source)
        self.assertIn('(side * 0.24, start_y, -0.31)', source)
        self.assertIn('(side * 0.12, 2.12, -0.59)', source)
        self.assertNotIn('parts.append(sphere("MothAbdomen"', source)

    def test_mesh_report_uses_stable_ten_group_contract(self):
        source = (ROOT / "tools" / "blender" / "build_moth_companion.py").read_text(encoding="utf-8")
        self.assertIn("GROUPS = (", source)
        self.assertIn('"part_count": len(parts)', source)
        self.assertIn('"uv_layers": min(len(obj.data.uv_layers) for obj in mesh_members)', source)
        workflow = (ROOT / ".github" / "workflows" / "lunar-moth-visual-review.yml").read_text(encoding="utf-8")
        self.assertIn("assert len(rig[\"wing_groups\"]) == 4", workflow)
        self.assertIn("assert report[\"part_count\"] == 10", workflow)
        self.assertIn("Lunar-Moth-Blender-Visual-Review", workflow)


if __name__ == "__main__":
    unittest.main()
