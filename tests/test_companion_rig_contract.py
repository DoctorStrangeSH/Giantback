from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionRigContractTests(unittest.TestCase):
    def test_fox_blockout_has_a_recognizable_face_and_chest_silhouette(self):
        for name in ("Chest bib", "Cheek fluff", "Nose", "Nose shine", "Inner ear", "Tail tip", "Leaf charm"):
            self.assertIn(f'"{name}"', VISUALS)

    def test_fox_paws_have_individual_toes_and_share_the_gait_animation(self):
        self.assertIn('"Paw toe"', VISUALS)
        self.assertIn('part.Name == "Paw" or part.Name == "Paw toe"', ALBUM)

    def test_moth_blockout_has_a_head_face_and_layered_wings(self):
        for name in ("Moth head", "Moth eye", "Wing lower", "Wing lower tip", "Wing spot", "Antenna tip", "Abdomen band"):
            self.assertIn(f'"{name}"', VISUALS)

    def test_moth_upper_and_lower_wings_share_a_hinge_but_keep_phase_offset(self):
        self.assertIn('part.Name == "Wing" or part.Name == "Wing lower"', ALBUM)
        self.assertIn('string.find(part.Name, "lower") and 0.38 or 0', ALBUM)
        self.assertIn("local wingHinge = rigOrigin + Vector3.new(side * 0.42, 0.28, 0)", ALBUM)

    def test_fox_tail_and_ears_rotate_from_their_roots(self):
        self.assertIn("local tailHinge = rigOrigin + Vector3.new(0, 0.25, 0.95)", ALBUM)
        self.assertIn("local earHinge = rigOrigin + Vector3.new(side * 0.8, 0.55, -0.4)", ALBUM)
        self.assertIn("local function aroundPoint(point, rotation)", ALBUM)

    def test_animation_transforms_are_applied_in_model_space_before_part_offsets(self):
        self.assertIn("part.CFrame = pivot * transform * offset", ALBUM)
        self.assertNotIn("part.CFrame = pivot * offset * transform", ALBUM)

    def test_visual_details_are_non_collidable_and_do_not_intercept_interactions(self):
        self.assertIn("part.CanCollide = false", VISUALS)
        self.assertIn("part.CanTouch = false", VISUALS)
        self.assertIn("part.CanQuery = false", VISUALS)

    def test_source_obj_import_remains_explicitly_pending_studio_approval(self):
        self.assertIn("Final OBJ imports remain pending Studio approval", VISUALS)
        self.assertIn('for name in ("Fox", "Moth"):', BUILD)


if __name__ == "__main__":
    unittest.main()
