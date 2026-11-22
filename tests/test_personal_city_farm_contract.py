from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class PersonalCityFarmContractTests(unittest.TestCase):
    def test_profile_schema_v5_migrates_legacy_city_into_island(self):
        self.assertIn("old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 8)", WORLD)
        self.assertIn("local function defaultCity()", WORLD)
        self.assertIn("local function normalizeCity(raw)", WORLD)
        self.assertIn('normalizeCity(type(data.island) == "table" and data.island or data.city)', WORLD)
        self.assertIn('local savedIsland = type(old.island) == "table" and old.island', WORLD)
        self.assertIn('or (type(old.city) == "table" and old.city or {})', WORLD)
        self.assertIn("old.island = savedIsland", WORLD)
        self.assertIn("old.city = nil", WORLD)
        self.assertIn("savedFarm.plots = citySnapshot.farm.plots", WORLD)

    def test_legacy_profiles_receive_a_small_seed_starter_pack(self):
        self.assertIn("session.inventory.CarrotSeed = 3", WORLD)
        self.assertIn('if key == "CarrotSeed" and savedAmount == nil then', WORLD)

    def test_studio_uses_a_separate_datastore_from_live_profiles(self):
        self.assertIn('"GiantbackAlbum_Studio_v1"', WORLD)
        self.assertIn('"GiantbackAlbum_v1"', WORLD)
        self.assertIn("local storeName = RunService:IsStudio()", WORLD)
        self.assertIn('player:SetAttribute("OfflineAlbum", true)', WORLD)

    def test_home_island_template_lives_in_serverstorage(self):
        self.assertIn('obj(doc, "ServerStorage", "ServerStorage")', BUILD)
        self.assertIn('obj(server_storage, "Model", "HomeIslandTemplate")', BUILD)
        self.assertIn('ServerStorage:WaitForChild("HomeIslandTemplate")', WORLD)
        self.assertIn('local pivot = island:FindFirstChild("IslandPivot")', WORLD)

    def test_eight_home_islands_are_allocated_without_overlap(self):
        self.assertIn("HOME_ISLAND_SLOT_COUNT = 8", WORLD)
        self.assertIn("HOME_ISLAND_RADIUS = 240", WORLD)
        self.assertIn("occupiedHomeSlots[slotIndex] == nil", WORLD)
        self.assertIn("occupiedHomeSlots[slotIndex] = player.UserId", WORLD)
        self.assertIn("island:PivotTo(homeSlotCFrame(slotIndex))", WORLD)
        self.assertIn('player:SetAttribute("HomeIslandSlot", slotIndex)', WORLD)
        self.assertIn('homeIslandFolder.Name = "PlayerIslands"', WORLD)

    def test_home_island_has_server_owned_identity(self):
        self.assertIn('island:SetAttribute("OwnerUserId", player.UserId)', WORLD)
        self.assertIn('cityModel:SetAttribute("OwnerUserId", ownerUserId)', WORLD)
        self.assertIn("if visitor.UserId ~= player.UserId then return end", WORLD)
        self.assertIn("if player.UserId ~= ownerUserId then return end", WORLD)

    def test_personal_city_and_farm_plots_live_inside_the_owners_island(self):
        self.assertIn('local homeIsland = session.homeIsland', WORLD)
        self.assertIn('local previous = homeIsland:FindFirstChild("PersonalCity")', WORLD)
        self.assertIn("cityModel.Parent = homeIsland", WORLD)
        self.assertIn('local meadow = homeIsland:FindFirstChild("Meadow")', WORLD)
        self.assertIn("plotModel.Parent = cityModel", WORLD)
        self.assertNotIn("PersonalCities", WORLD)

    def test_home_island_spawn_is_used_and_slot_is_released(self):
        self.assertIn('player.RespawnLocation = publicSpawn', WORLD)
        self.assertIn("player.RespawnLocation = homeSpawn", WORLD)
        self.assertIn("character:PivotTo(session.homeSpawn.CFrame + Vector3.new(0, 4, 0))", WORLD)
        self.assertIn("session.homeIsland:Destroy()", WORLD)
        self.assertIn("occupiedHomeSlots[session.homeSlot] = nil", WORLD)

    def test_client_resolves_its_own_island_without_hiding_other_cities(self):
        self.assertIn('folder:FindFirstChild("HomeIsland_" .. tostring(player.UserId))', CLIENT)
        self.assertIn('area = "HomeIsland"', CLIENT)
        self.assertIn('waitForHomePart("Planter")', CLIENT)
        self.assertIn('waitForHomePart("LanternBase")', CLIENT)
        self.assertNotIn("PersonalCities", CLIENT)
        self.assertNotIn("sharedHomeParts", CLIENT)
        self.assertNotIn("findPersonalCityRoot", CLIENT)

    def test_four_plot_records_are_defined_and_unlock_by_farm_level(self):
        self.assertIn('local farmPlotIds = {"Plot01", "Plot02", "Plot03", "Plot04"}', WORLD)
        self.assertIn('if plotId == "Plot02" or plotId == "Plot03" then', WORLD)
        self.assertIn('if plotId == "Plot04" then', WORLD)
        self.assertIn("farm.level >= 2", WORLD)
        self.assertIn("farm.level >= 3", WORLD)

    def test_carrot_is_planted_and_harvested_on_server(self):
        self.assertIn("growthSeconds = 300", WORLD)
        self.assertIn("state.cropId = cropId", WORLD)
        self.assertIn("session.inventory[definition.seedItemId] -= 1", WORLD)
        self.assertIn("state.readyAt = now + definition.growthSeconds", WORLD)
        self.assertIn("if now < state.readyAt then", WORLD)
        self.assertIn("session.inventory[definition.harvestItemId]", WORLD)

    def test_plot_interactions_capture_stable_owner_and_plot_ids(self):
        self.assertIn("local ownerUserId = player.UserId", WORLD)
        self.assertIn("local currentPlotId = plotId", WORLD)
        self.assertIn("interactFarmPlot(visitor, ownerUserId, currentPlotId)", WORLD)

    def test_farm_progress_and_inventory_are_exposed_to_the_hud(self):
        self.assertIn('player:SetAttribute("Farm_Level"', WORLD)
        self.assertIn("Resource_CarrotSeed", CLIENT)
        self.assertIn("Resource_Carrot", CLIENT)
        self.assertIn("МАТЕРИАЛЫ И ФЕРМА", CLIENT)


if __name__ == "__main__":
    unittest.main()
