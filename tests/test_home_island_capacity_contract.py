"""Capacity and cleanup contracts for fixed personal home-island slots."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class HomeIslandCapacityContractTests(unittest.TestCase):
    def test_server_capacity_is_exactly_eight_fixed_slots(self):
        self.assertIn("local HOME_ISLAND_SLOT_COUNT = 8", WORLD)
        allocator = WORLD.split("local function allocateHomeIsland", 1)[1].split("local function tip", 1)[0]
        self.assertIn("for slotIndex = 1, HOME_ISLAND_SLOT_COUNT do", allocator)
        self.assertIn("if occupiedHomeSlots[slotIndex] == nil then", allocator)
        self.assertIn("occupiedHomeSlots[slotIndex] = player.UserId", allocator)

    def test_capacity_exhaustion_returns_without_reusing_an_occupied_slot(self):
        allocator = WORLD.split("local function allocateHomeIsland", 1)[1].split("local function tip", 1)[0]
        self.assertIn("return false", allocator)
        self.assertIn("return true", allocator)
        self.assertLess(allocator.rindex("return false"), len(allocator))
        self.assertIn('island.Name = "HomeIsland_" .. tostring(player.UserId)', allocator)

    def test_rejected_ninth_player_is_kicked_and_listener_connections_are_disconnected(self):
        init = WORLD.split("local function init(player)", 1)[1].split("local combatRewardFunction", 1)[0]
        capacity = init.split("if not allocateHomeIsland(player, session) then", 1)[1].split("end", 1)[0]
        self.assertIn("connection:Disconnect()", capacity)
        self.assertIn("session.companionOwnershipConnections = nil", capacity)
        self.assertIn("sessions[player] = nil", capacity)
        self.assertIn("player:Kick(\"На этом сервере заняты все 8 домашних островов.", capacity)
        self.assertLess(capacity.index("connection:Disconnect()"), capacity.index("sessions[player] = nil"))

    def test_leaving_player_disconnects_listeners_and_releases_exact_slot(self):
        removing = WORLD.split("Players.PlayerRemoving:Connect(function(player)\n    save(player)", 1)[1].split("end)\ngame:BindToClose", 1)[0]
        self.assertIn("connection:Disconnect()", removing)
        self.assertIn("session.homeIsland:Destroy()", removing)
        self.assertIn("occupiedHomeSlots[session.homeSlot] = nil", removing)
        self.assertIn("sessions[player] = nil", removing)


if __name__ == "__main__":
    unittest.main()
