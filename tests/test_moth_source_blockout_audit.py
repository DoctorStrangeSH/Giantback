from pathlib import Path
import math
import unittest


ROOT = Path(__file__).resolve().parents[1]
OBJ = ROOT / "assets" / "source_models" / "moth_companion.obj"
BRIEF = ROOT / "assets" / "source_models" / "MOTH_ART_BRIEF.md"


def inspect_obj(path):
    vertices = []
    faces = []
    objects = []
    materials = set()
    uv_count = 0
    current_object = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("v "):
            vertices.append(tuple(map(float, line.split()[1:4])))
        elif line.startswith("vt "):
            uv_count += 1
        elif line.startswith("o "):
            current_object = line[2:].strip()
            objects.append(current_object)
        elif line.startswith("usemtl "):
            materials.add(line[7:].strip())
        elif line.startswith("f "):
            indices = [int(part.split("/")[0]) - 1 for part in line[2:].split()]
            faces.append((indices, current_object))
    edge_uses = {}
    zero_area = 0
    for indices, _ in faces:
        if len(indices) < 3:
            continue
        a, b, c = (vertices[indices[i]] for i in range(3))
        ab = tuple(b[i] - a[i] for i in range(3))
        ac = tuple(c[i] - a[i] for i in range(3))
        cross = (
            ab[1] * ac[2] - ab[2] * ac[1],
            ab[2] * ac[0] - ab[0] * ac[2],
            ab[0] * ac[1] - ab[1] * ac[0],
        )
        if math.sqrt(sum(v * v for v in cross)) < 1e-9:
            zero_area += 1
        for i, left in enumerate(indices):
            right = indices[(i + 1) % len(indices)]
            edge = tuple(sorted((left, right)))
            edge_uses[edge] = edge_uses.get(edge, 0) + 1
    return {
        "vertices": len(vertices),
        "uvs": uv_count,
        "faces": len(faces),
        "objects": objects,
        "materials": materials,
        "zero_area": zero_area,
        "nonmanifold": sum(count > 2 for count in edge_uses.values()),
        "boundary": sum(count == 1 for count in edge_uses.values()),
    }


class MothSourceBlockoutAuditTests(unittest.TestCase):
    """Lock the measured legacy source baseline; this is NOT hero-asset approval."""

    @classmethod
    def setUpClass(cls):
        cls.audit = inspect_obj(OBJ)
        cls.brief = BRIEF.read_text(encoding="utf-8")

    def test_source_geometry_inventory_is_stable(self):
        self.assertEqual(self.audit["vertices"], 1306)
        self.assertEqual(self.audit["faces"], 1980)
        self.assertEqual(len(self.audit["objects"]), 15)
        self.assertEqual(len(self.audit["materials"]), 7)

    def test_source_has_no_degenerate_faces_or_overused_edges(self):
        self.assertEqual(self.audit["zero_area"], 0)
        self.assertEqual(self.audit["nonmanifold"], 0)
        self.assertEqual(self.audit["boundary"], 616)

    def test_missing_uvs_remain_an_explicit_open_production_gate(self):
        self.assertEqual(self.audit["uvs"], 0)
        self.assertIn("0 UV coordinates", self.brief)
        self.assertIn("not a finished hero asset", self.brief.lower())
        self.assertIn("Preserve it unchanged as rollback baseline", self.brief)


if __name__ == "__main__":
    unittest.main()
