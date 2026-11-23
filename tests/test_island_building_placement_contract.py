"""Server-authoritative personal-island decoration placement contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class IslandBuildingPlacementContractTests(unittest.TestCase):
    def test_only_known_decorations_are_normalized_and_saved(self):
        self.assertIn('saved.id == "Path" or saved.id == "FlowerBed"', WORLD)
        self.assertIn('local rawBuildings = type(raw.buildings) == "table" and raw.buildings or {}', WORLD)
        self.assertIn('if #city.buildings >= 24 then break end', WORLD)
        self.assertIn('savedIsland.buildings = citySnapshot.buildings', WORLD)
        self.assertIn('local citySnapshot = normalizeCity(session.city)', WORLD)

    def test_server_checks_ownership_location_bounds_capacity_and_cost(self):
        self.assertIn('if action == "PlaceIslandDecoration" then', WORLD)
        self.assertIn('decorationId ~= "Path" and decorationId ~= "FlowerBed"', WORLD)
        self.assertIn('if #session.city.buildings >= 12 then', WORLD)
        self.assertIn('(root.Position - meadow.Position).Magnitude > 22', WORLD)
        self.assertIn('localTarget.X < -2 or localTarget.X > 14', WORLD)
        self.assertIn('localTarget.Z < -6 or localTarget.Z > 6', WORLD)
        self.assertIn('local x = math.clamp(math.floor(localTarget.X / 4 + 0.5) * 4, 0, 12)', WORLD)
        self.assertIn('local z = math.clamp(math.floor(localTarget.Z / 4 + 0.5) * 4, -4, 4)', WORLD)
        self.assertIn('if existing.x == x and existing.z == z then', WORLD)
        self.assertIn('decorationId == "Path" and {Wood = 2, Stone = 0} or {Wood = 4, Stone = 2}', WORLD)

    def test_rotation_and_visuals_are_server_generated(self):
        self.assertIn('local rotation = (math.floor(math.deg(math.atan2(-localLook.X, -localLook.Z)) / 90 + 0.5) % 4) * 90', WORLD)
        self.assertIn('local function renderIslandDecoration(', WORLD)
        self.assertIn('"PavingStone"', WORLD)
        self.assertIn('"FlowerBedSoil"', WORLD)
        self.assertIn('"FlowerBloom"', WORLD)
        self.assertIn('renderIslandDecoration(cityModel, meadow, decoration, index, ownerUserId)', WORLD)

    def test_city_menu_offers_both_placeable_items(self):
        self.assertIn('local decorationCount = tonumber(player:GetAttribute("City_DecorationCount")) or 0', HUD)
        self.assertIn('{id = "Path", title = "Каменная дорожка"', HUD)
        self.assertIn('{id = "FlowerBed", title = "Цветочная клумба"', HUD)
        self.assertIn('event:FireServer("PlaceIslandDecoration", definition.id)', HUD)
        self.assertIn('action.TextSize = compact and 9 or 10', HUD)


if __name__ == "__main__":
    unittest.main()
