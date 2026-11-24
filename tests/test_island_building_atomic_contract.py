"""Atomic persistence contracts for personal-island construction."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class IslandBuildingAtomicContractTests(unittest.TestCase):
    def test_build_and_move_require_a_persistable_profile(self):
        placement = WORLD.split("placeIslandDecoration = function(player, payload)", 1)[1].split("local function encounter(", 1)[0]
        self.assertIn("if not session.online then", placement)
        self.assertIn("if session.economyBusy then", placement)
        self.assertIn("session.economyBusy = true", placement)
        self.assertIn("if not save(player) then", placement)
        self.assertNotIn("if session.online then save(player) end", placement)

    def test_failed_build_restores_materials_and_previous_buildings(self):
        placement = WORLD.split("placeIslandDecoration = function(player, payload)", 1)[1].split("local function encounter(", 1)[0]
        self.assertIn("local previousBuildings = copyCityBuildings(session.city.buildings)", placement)
        self.assertIn("local previousWood = session.inventory.Wood or 0", placement)
        self.assertIn("local previousStone = session.inventory.Stone or 0", placement)
        self.assertIn("rollbackCityBuildingOperation(player, session, cityModel, meadow, previousBuildings, moveIndex and 0 or cost.Wood, moveIndex and 0 or cost.Stone)", placement)
        self.assertIn("Постройка и материалы восстановлены.", placement)
        self.assertLess(placement.index("if not save(player) then"), placement.index("tip(player, placedMessages[decorationId])"))

    def test_demolition_refund_is_rolled_back_when_save_fails(self):
        demolition = WORLD.split("removeIslandDecoration = function(player, payload)", 1)[1].split("placeIslandDecoration = function(player, payload)", 1)[0]
        self.assertIn("if not session.online then", demolition)
        self.assertIn("if session.economyBusy then", demolition)
        self.assertIn("local previousBuildings = copyCityBuildings(session.city.buildings)", demolition)
        self.assertIn("session.inventory.Wood = (session.inventory.Wood or 0) + refund.Wood", demolition)
        self.assertIn("session.inventory.Stone = (session.inventory.Stone or 0) + refund.Stone", demolition)
        self.assertIn("rollbackCityBuildingOperation(player, session, cityModel, meadow, previousBuildings, -refund.Wood, -refund.Stone)", demolition)
        self.assertIn("if not save(player) then", demolition)
        self.assertIn("Постройка и материалы восстановлены.", demolition)
        self.assertLess(demolition.index("if not save(player) then"), demolition.index('tip(player, "Постройка разобрана.'))

    def test_rollback_uses_inverse_deltas_to_preserve_concurrent_pickups(self):
        helper = WORLD.split("local function rollbackCityBuildingOperation", 1)[1].split("removeIslandDecoration = function", 1)[0]
        self.assertIn("woodDelta", helper)
        self.assertIn("stoneDelta", helper)
        self.assertIn("math.max(0, (session.inventory.Wood or 0) + woodDelta)", helper)
        self.assertIn("math.max(0, (session.inventory.Stone or 0) + stoneDelta)", helper)
        self.assertIn("moveIndex and 0 or cost.Wood, moveIndex and 0 or cost.Stone", WORLD)
        self.assertIn("-refund.Wood, -refund.Stone", WORLD)

    def test_failed_move_never_refunds_a_purchase_cost(self):
        placement = WORLD.split("placeIslandDecoration = function(player, payload)", 1)[1].split("local function encounter(", 1)[0]
        self.assertIn("if moveIndex then", placement)
        self.assertIn("else\n        session.inventory.Wood = previousWood - cost.Wood", placement)
        self.assertIn("moveIndex and 0 or cost.Wood", placement)
        self.assertIn("moveIndex and 0 or cost.Stone", placement)

    def test_rollback_rebuilds_visuals_and_syncs_player_attributes(self):
        helper = WORLD.split("local function rollbackCityBuildingOperation", 1)[1].split("removeIslandDecoration = function", 1)[0]
        self.assertIn("session.city.buildings = buildings", helper)
        self.assertIn("(session.inventory.Wood or 0) + woodDelta", helper)
        self.assertIn("(session.inventory.Stone or 0) + stoneDelta", helper)
        self.assertNotIn("session.inventory.Wood = wood", helper)
        self.assertNotIn("session.inventory.Stone = stone", helper)
        self.assertIn("rebuildCityDecorations(player, session, cityModel, meadow)", helper)
        self.assertIn("syncInventory(player)", helper)
        self.assertIn("syncFarm(player)", helper)


if __name__ == "__main__":
    unittest.main()
