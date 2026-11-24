"""Personal-island greenhouse gameplay and placement contracts."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class GreenhouseBuildingContractTests(unittest.TestCase):
    def test_greenhouse_is_persisted_and_exposed_to_the_hud(self):
        self.assertIn('saved.id == "Path" or saved.id == "FlowerBed" or saved.id == "Cottage" or saved.id == "Warehouse" or saved.id == "Greenhouse"', WORLD)
        self.assertIn('savedIsland.buildings = citySnapshot.buildings', WORLD)
        self.assertIn('player:SetAttribute("Greenhouse_Built"', WORLD)
        self.assertIn('end)(), "Greenhouse") ~= nil)', WORLD)

    def test_greenhouse_is_server_gated_costed_and_unique(self):
        self.assertIn('if decorationId == "Greenhouse" and session.city.farm.level < 3 then', WORLD)
        self.assertIn('Теплица откроется после улучшения фермы до 3 уровня.', WORLD)
        self.assertIn('if decorationId == "Greenhouse" and not moveIndex then', WORLD)
        self.assertIn('Теплица уже построена на твоём острове.', WORLD)
        self.assertIn('Greenhouse = {Wood = 18, Stone = 12}', WORLD)
        self.assertIn('Greenhouse = {Wood = 9, Stone = 6}', WORLD)
        self.assertIn('Greenhouse = "Теплица"', HUD)

    def test_greenhouse_accelerates_new_planting_and_strawberry_regrowth(self):
        helper = WORLD.split("local function getFarmGrowthDuration(session, baseSeconds)", 1)[1].split("local function interactFarmPlot", 1)[0]
        self.assertIn('building.id == "Greenhouse"', helper)
        self.assertIn('math.floor(baseSeconds * 0.85 + 0.5)', helper)
        farming = WORLD.split("local function interactFarmPlot(player, ownerUserId, plotId)", 1)[1].split("local function gatherHomeMaterial", 1)[0]
        self.assertIn('getFarmGrowthDuration(session, definition.growthSeconds)', farming)
        self.assertIn('getFarmGrowthDuration(session, definition.regrowSeconds)', farming)
        self.assertIn('state.readyAt = now + growthSeconds', farming)
        self.assertIn('state.readyAt = now + regrowSeconds', farming)

    def test_greenhouse_is_a_real_visual_building_with_owner_prompt(self):
        renderer = WORLD.split("local function renderIslandDecoration", 1)[1].split("local function refreshFarmPlotVisual", 1)[0]
        self.assertIn('elseif id == "Greenhouse" then', renderer)
        self.assertIn('"GreenhouseGlassWall"', renderer)
        self.assertIn('"GreenhouseGlassRoof"', renderer)
        self.assertIn('"GreenhouseSeedling"', renderer)
        self.assertIn('prompt(anchor, "Теплица", "Осмотреть посадки"', renderer)
        self.assertIn('visitor.UserId ~= ownerUserId', renderer)

    def test_hud_explains_unlock_bonus_and_placement_requirements(self):
        self.assertIn('{id = "Greenhouse", title = "Теплица"', HUD)
        self.assertIn('placementState == "Greenhouse" and farmLevel >= 3 and wood >= 18 and stone >= 12', HUD)
        self.assertIn('GreenhousePreviewGlass', HUD)
        self.assertIn('ОТКРОЕТСЯ НА УР. 3', HUD)
        self.assertIn('Теплица построена • +15% к скорости роста', HUD)
        self.assertIn('УЖЕ ПОСТРОЕНА', HUD)


if __name__ == "__main__":
    unittest.main()
