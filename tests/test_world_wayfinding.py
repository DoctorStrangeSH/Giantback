from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class WorldWayfindingTests(unittest.TestCase):
    def test_bridge_landings_have_small_physical_destination_signs(self):
        self.assertIn('addWayfindingSign("GroveWayfindingSign"', VISUALS)
        self.assertIn('"СОЛНЕЧНАЯ РОЩА"', VISUALS)
        self.assertIn('addWayfindingSign("DuskWayfindingSign"', VISUALS)
        self.assertIn('"СУМЕРЕЧНАЯ ДОЛИНА"', VISUALS)
        self.assertIn('"GiantbackWorldDetails"', VISUALS)

    def test_wayfinding_signs_are_decorative_and_do_not_block_players(self):
        self.assertIn('local function addWayfindingSign(name, position, title, subtitle, accent)', VISUALS)
        self.assertIn('makePart(sign, "SignPost"', VISUALS)
        self.assertIn('makePart(sign, "SignBoard"', VISUALS)
        self.assertIn('Enum.NormalId.Front', VISUALS)
        self.assertIn('heading.TextScaled = true', VISUALS)
        self.assertIn('caption.TextWrapped = true', VISUALS)
        self.assertIn('part.CanCollide = false', VISUALS)

    def test_fall_recovery_returns_character_to_owners_home_without_resetting_inventory(self):
        self.assertIn('root.Position.Y < -80', WORLD)
        self.assertIn('local recovery = session.homeSpawn', WORLD)
        self.assertIn('character:PivotTo(recovery.CFrame + Vector3.new(0, 6, 0))', WORLD)
        self.assertIn('root.AssemblyLinearVelocity = Vector3.zero', WORLD)
        self.assertIn('root.AssemblyAngularVelocity = Vector3.zero', WORLD)
        self.assertIn('humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)', WORLD)


if __name__ == "__main__":
    unittest.main()
