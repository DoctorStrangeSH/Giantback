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
        self.assertIn('"wing_groups":["MothWingUpperLeft","MothWingUpperRight","MothWingLowerLeft","MothWingLowerRight"]', source)

    def test_lunar_palette_and_gameplay_animation_states_are_locked(self):
        source = (ROOT / "tools" / "blender" / "build_moth_companion.py").read_text(encoding="utf-8")
        for material in ("wing_lilac", "wing_rose", "wing_cyan", "moon_gold", "moon_core"):
            self.assertIn(f'mat("{material}"', source)
        for state in ("idle_hover", "follow", "reveal_secret", "ability_burst", "rest"):
            self.assertIn(state, source)

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
