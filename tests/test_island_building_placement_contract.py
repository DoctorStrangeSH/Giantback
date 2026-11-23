"""Server-authoritative personal-island decoration placement contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class IslandBuildingPlacementContractTests(unittest.TestCase):
    def test_only_known_decorations_are_normalized_and_saved(self):
        self.assertIn('saved.id == "Path" or saved.id == "FlowerBed" or saved.id == "Cottage" or saved.id == "Warehouse"', WORLD)
        self.assertIn('city.storage[itemId] = math.clamp(math.floor(tonumber(rawStorage[itemId]) or 0), 0, WAREHOUSE_CAPACITY)', WORLD)
        self.assertIn('savedIsland.storage = citySnapshot.storage', WORLD)
        self.assertIn('local rawBuildings = type(raw.buildings) == "table" and raw.buildings or {}', WORLD)
        self.assertIn('if #city.buildings >= 24 then break end', WORLD)
        self.assertIn('savedIsland.buildings = citySnapshot.buildings', WORLD)
        self.assertIn('local citySnapshot = normalizeCity(session.city)', WORLD)

    def test_server_checks_ownership_location_bounds_capacity_and_cost(self):
        self.assertIn('if action == "PlaceIslandDecoration" then', WORLD)
        self.assertIn('decorationId ~= "Path" and decorationId ~= "FlowerBed" and decorationId ~= "Cottage" and decorationId ~= "Warehouse"', WORLD)
        self.assertIn('if #session.city.buildings >= 12 and not moveIndex then', WORLD)
        self.assertIn('(root.Position - meadow.Position).Magnitude > 22', WORLD)
        self.assertIn('(root.Position - targetFrame.Position).Magnitude > 24', WORLD)
        self.assertIn('x % 1 ~= 0 or z % 1 ~= 0 or rotation % 1 ~= 0', WORLD)
        self.assertIn('x < 0 or x > 12 or x % 4 ~= 0', WORLD)
        self.assertIn('z < -4 or z > 4 or z % 4 ~= 0', WORLD)
        self.assertIn('rotation < 0 or rotation >= 360 or rotation % 90 ~= 0', WORLD)
        self.assertIn('if index ~= moveIndex and existing.x == x and existing.z == z then', WORLD)
        self.assertIn('Cottage = {Wood = 8, Stone = 6}', WORLD)
        self.assertIn('Warehouse = {Wood = 10, Stone = 8}', WORLD)
        self.assertIn('Warehouse = {Wood = 5, Stone = 4}', WORLD)
        self.assertIn('Перед разборкой склада сначала забери все материалы.', WORLD)
        self.assertIn('local function useWarehouse(player, ownerUserId, action)', WORLD)
        self.assertIn('local WAREHOUSE_CAPACITY = 120', WORLD)
        self.assertIn('Warehouse_Used', WORLD)
        self.assertIn('Warehouse_Built', WORLD)

    def test_client_ghost_preview_and_manual_placement_controls(self):
        self.assertIn('local function createPlacementGhost(decorationId)', HUD)
        self.assertIn('workspace:Raycast(ray.Origin, ray.Direction * 600, params)', HUD)
        self.assertIn('FilterDescendantsInstances = {meadow}', HUD)
        self.assertIn('placementValid = inBounds and not occupied and enough and hasSpace', HUD)
        self.assertIn('placementRotation = (placementRotation + 90) % 360', HUD)
        self.assertIn('event:FireServer("PlaceIslandDecoration", {', HUD)
        self.assertIn('placementButtons.Confirm.Active = placementValid', HUD)
        self.assertIn('input.KeyCode == Enum.KeyCode.Escape', HUD)
        self.assertIn('input.KeyCode == Enum.KeyCode.R', HUD)

    def test_server_publishes_occupied_cells_for_preview(self):
        self.assertIn('player:SetAttribute("City_BuildingCells", table.concat(occupiedCells, ";"))', WORLD)
        self.assertIn('local occupiedCells = {}', WORLD)

    def test_server_authorizes_move_and_demolition_with_partial_refund(self):
        self.assertIn('if action == "RemoveIslandDecoration" then', WORLD)
        self.assertIn('removeIslandDecoration = function(player, payload)', WORLD)
        self.assertIn('local movingDecoration = moveIndex and session.city.buildings[moveIndex] or nil', WORLD)
        self.assertIn('session.city.buildings[moveIndex] = decoration', WORLD)
        self.assertIn('if index ~= moveIndex and existing.x == x and existing.z == z then', WORLD)
        self.assertIn('local refunds = {Path = {Wood = 1, Stone = 0}, FlowerBed = {Wood = 2, Stone = 1}, Cottage = {Wood = 4, Stone = 3}, Warehouse = {Wood = 5, Stone = 4}}', WORLD)
        self.assertIn('session.inventory.Wood = (session.inventory.Wood or 0) + refund.Wood', WORLD)
        self.assertIn('session.inventory.Stone = (session.inventory.Stone or 0) + refund.Stone', WORLD)
        self.assertIn('if session.online then save(player) end', WORLD)

    def test_city_lists_existing_buildings_and_offers_actions(self):
        self.assertIn('City_Decoration_" .. tostring(index) .. "_Id', WORLD)
        self.assertIn('City_Decoration_" .. tostring(index) .. "_Rotation', WORLD)
        self.assertIn('for index = 1, decorationCount do', HUD)
        self.assertIn('beginIslandPlacement(decorationId, index)', HUD)
        self.assertIn('event:FireServer("RemoveIslandDecoration", index)', HUD)
        self.assertIn('moveIndex = placementMoveIndex', HUD)
        self.assertIn('getOccupiedPlacementCells(placementMoveIndex)', HUD)

    def test_rotation_and_visuals_are_server_generated(self):
        self.assertIn('local rotation = (math.floor((tonumber(decoration.rotation) or 0) / 90 + 0.5) % 4) * 90', WORLD)
        self.assertIn('local function renderIslandDecoration(', WORLD)
        self.assertIn('"CottageRoof"', WORLD)
        self.assertIn('"CottageWalls"', WORLD)
        self.assertIn('"WarehouseBody"', WORLD)
        self.assertIn('"WarehouseRoof"', WORLD)
        self.assertIn('useWarehouse(visitor, ownerUserId, "Deposit")', WORLD)
        self.assertIn('useWarehouse(visitor, ownerUserId, "Withdraw")', WORLD)
        self.assertIn('"PavingStone"', WORLD)
        self.assertIn('"FlowerBedSoil"', WORLD)
        self.assertIn('"FlowerBloom"', WORLD)
        self.assertIn('renderIslandDecoration(cityModel, meadow, decoration, index, ownerUserId)', WORLD)

    def test_city_menu_offers_both_placeable_items(self):
        self.assertIn('local decorationCount = tonumber(player:GetAttribute("City_DecorationCount")) or 0', HUD)
        self.assertIn('{id = "Path", title = "Каменная дорожка"', HUD)
        self.assertIn('{id = "FlowerBed", title = "Цветочная клумба"', HUD)
        self.assertIn('{id = "Cottage", title = "Уютный домик"', HUD)
        self.assertIn('{id = "Warehouse", title = "Склад"', HUD)
        self.assertIn('placementState == "Warehouse" and wood >= 10 and stone >= 8', HUD)
        self.assertIn('WarehousePreviewBody', HUD)
        self.assertIn('Warehouse_Used', HUD)
        self.assertIn('Склад ещё не построен', HUD)
        self.assertIn('Построй склад, чтобы хранить до 120 единиц', HUD)
        self.assertIn('placementState == "Cottage" and wood >= 8 and stone >= 6', HUD)
        self.assertIn('CottagePreviewWalls', HUD)
        self.assertIn('if decorationId ~= "Path" and decorationId ~= "FlowerBed" and decorationId ~= "Cottage" and decorationId ~= "Warehouse" then return end', HUD)
        self.assertIn('if decorationId ~= "Path" and decorationId ~= "FlowerBed" and decorationId ~= "Cottage" and decorationId ~= "Warehouse" then', WORLD)
        self.assertIn('placedMessages[decorationId]', WORLD)
        self.assertIn('Cottage = {Wood = 4, Stone = 3}', WORLD)
        self.assertIn('beginIslandPlacement(definition.id)', HUD)
        self.assertIn('action.TextSize = compact and 9 or 10', HUD)


if __name__ == "__main__":
    unittest.main()
