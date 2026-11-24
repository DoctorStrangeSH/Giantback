from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class HomeInteriorContractTests(unittest.TestCase):
    def test_house_has_a_real_walkable_doorway_and_floor(self):
        for marker in (
            'add("InteriorFloor"',
            'add("FrontWallLeft"',
            'add("FrontWallRight"',
            'add("DoorLintel"',
            'add("DoorFrameLeft"',
            'add("DoorFrameRight"',
        ):
            self.assertIn(marker, WORLD)

    def test_living_room_contains_readable_furniture_and_fireplace(self):
        for marker in (
            'add("LivingRoomRug"',
            'add("SofaBase"',
            'add("SofaSeat"',
            'add("CoffeeTableTop"',
            'add("FireplaceStone"',
            'add("FireplaceMantel"',
            'add("Bookcase"',
            'add("IndoorPlantLeaves"',
        ):
            self.assertIn(marker, WORLD)
        self.assertIn('fireLight.Name = "FireplaceLight"', WORLD)

    def test_home_interaction_anchors_survive_visual_rebuilds(self):
        self.assertIn('ensureAnchor("HomeUpgradeAnchor"', WORLD)
        self.assertIn('ensureAnchor("HomeEntranceAnchor"', WORLD)
        self.assertIn('ensureAnchor("HomeExitAnchor"', WORLD)
        self.assertIn('ensureAnchor("HomeInteriorSpawn"', WORLD)
        self.assertIn('local previous = homeIsland:FindFirstChild("HomeHouseVisuals")', WORLD)

    def test_entry_and_exit_keep_a_per_visitor_return_position(self):
        self.assertIn('prompt(homeEntranceAnchor, "Домашний очаг", "Войти домой"', WORLD)
        self.assertIn('prompt(homeExitAnchor, "Входная дверь", "Выйти во двор"', WORLD)
        self.assertIn("visitorSession.homeReturnCFrame = root.CFrame", WORLD)
        self.assertIn("visitorSession.homeInteriorIsland = homeIsland", WORLD)
        self.assertIn("visitorSession.homeReturnCFrame = nil", WORLD)
        self.assertIn('visitor:SetAttribute("HomeInteriorActive", false)', WORLD)

    def test_respawn_and_owner_departure_do_not_strand_visitors(self):
        self.assertIn('player:SetAttribute("HomeInteriorActive", false)', WORLD)
        self.assertIn("otherSession.homeInteriorIsland == session.homeIsland", WORLD)
        self.assertIn("Владелец острова вышел. Ты вернулся во двор.", WORLD)

    def test_client_hides_roof_only_while_inside_and_restores_it_outside(self):
        self.assertIn('player:GetAttributeChangedSignal("HomeInteriorActive")', HUD)
        self.assertIn("item.LocalTransparencyModifier = active and 1 or 0", HUD)
        self.assertIn('child.Name == "HomeHouseVisuals"', HUD)

    def test_roof_visibility_tracks_rebuilt_house_visuals(self):
        self.assertIn("visuals.DescendantAdded:Connect(updatePart)", HUD)
        self.assertIn("island.ChildAdded:Connect", HUD)


if __name__ == "__main__":
    unittest.main()
