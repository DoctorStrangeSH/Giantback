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
        self.assertIn('visitor:SetAttribute("HomeInteriorIslandOwnerUserId", ownerUserId)', WORLD)
        self.assertIn("visitorSession.homeReturnCFrame = nil", WORLD)
        self.assertIn('visitor:SetAttribute("HomeInteriorActive", false)', WORLD)

    def test_respawn_and_owner_departure_do_not_strand_visitors(self):
        self.assertIn('player:SetAttribute("HomeInteriorActive", false)', WORLD)
        self.assertIn("otherSession.homeInteriorIsland == session.homeIsland", WORLD)
        self.assertIn("otherSession.homeSpawn and otherSession.homeSpawn.Parent", WORLD)
        self.assertIn("Владелец острова вышел. Ты вернулся на свой остров.", WORLD)

    def test_client_hides_roof_only_while_inside_and_restores_it_outside(self):
        self.assertIn('player:GetAttributeChangedSignal("HomeInteriorActive")', HUD)
        self.assertIn("item.LocalTransparencyModifier = active and 1 or 0", HUD)
        self.assertIn('child.Name == "HomeHouseVisuals"', HUD)

    def test_roof_visibility_tracks_rebuilt_house_visuals(self):
        self.assertIn("visuals.DescendantAdded:Connect(updatePart)", HUD)
        self.assertIn("island.ChildAdded:Connect", HUD)

    def test_home_has_three_companion_beds_and_a_shared_rest_anchor(self):
        self.assertIn('add("PetBedFrame"', WORLD)
        self.assertIn('add("PetBedCushion"', WORLD)
        self.assertIn('add("PetBedPillow"', WORLD)
        self.assertIn('add("PetToyBall"', WORLD)
        self.assertIn('ensureAnchor("HomePetRestAnchor" .. string.format("%02d", bedIndex)', WORLD)
        self.assertIn('local homePetRestAnchors = {}', WORLD)
        self.assertIn('local anchorName = "HomePetRestAnchor" .. string.format("%02d", bedIndex)', WORLD)

    def test_each_pet_bed_has_its_own_stable_interaction_anchor(self):
        self.assertIn('for bedIndex = 1, 3 do', WORLD)
        self.assertIn('ensureAnchor(anchorName, Vector3.new(bedX, -0.6, -1.8))', WORLD)
        self.assertIn('tostring(bedIndex) .. ". Дружба +4."', WORLD)

    def test_companion_rest_is_owner_only_and_updates_bond(self):
        self.assertIn('prompt(bedEntry.anchor, "Лежанка " .. tostring(bedEntry.index), "Отдохнуть здесь"', WORLD)
        self.assertIn('restPrompt.MaxActivationDistance = 4', WORLD)
        self.assertIn('for _, bedEntry in ipairs(homePetRestAnchors) do', WORLD)
        self.assertIn('if visitor.UserId ~= ownerUserId then', WORLD)
        self.assertIn('visitorSession.homeInteriorIsland ~= homeIsland', WORLD)
        self.assertIn('visitorSession.companionRestReadyAt[companionId] = now + 45', WORLD)
        self.assertIn('progressData.bond = math.clamp((progressData.bond or 0) + 4, 0, 1000)', WORLD)
        self.assertIn('setCompanionMood(visitor, companionId, "Спокойствие")', WORLD)
        self.assertIn('if visitorSession.online and not save(visitor) then', WORLD)


if __name__ == "__main__":
    unittest.main()
