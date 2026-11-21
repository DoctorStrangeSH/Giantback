from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")


class PersonalCityFarmContractTests(unittest.TestCase):
    def test_profile_schema_v4_persists_city_and_farm_plots(self):
        self.assertIn("old.schemaVersion = 4", WORLD)
        self.assertIn("local function defaultCity()", WORLD)
        self.assertIn("local function normalizeCity(raw)", WORLD)
        self.assertIn("session.city = normalizeCity(data.city)", WORLD)
        self.assertIn("savedCity.level = citySnapshot.level", WORLD)
        self.assertIn("savedFarm.plots = citySnapshot.farm.plots", WORLD)

    def test_legacy_profiles_receive_a_small_seed_starter_pack(self):
        self.assertIn("session.inventory.CarrotSeed = 3", WORLD)
        self.assertIn('if key == "CarrotSeed" and savedAmount == nil then', WORLD)

    def test_studio_uses_a_separate_datastore_from_live_profiles(self):
        self.assertIn('"GiantbackAlbum_Studio_v1"', WORLD)
        self.assertIn('"GiantbackAlbum_v1"', WORLD)
        self.assertIn("local storeName = RunService:IsStudio()", WORLD)
        self.assertIn('player:SetAttribute("OfflineAlbum", true)', WORLD)

    def test_personal_city_has_server_owned_identity(self):
        self.assertIn('cityModel:SetAttribute("OwnerUserId", ownerUserId)', WORLD)
        self.assertIn("if visitor.UserId ~= player.UserId then return end", WORLD)
        self.assertIn("if player.UserId ~= ownerUserId then return end", WORLD)

    def test_personal_home_visuals_are_cloned_per_owner(self):
        self.assertIn("PersonalCities", WORLD)
        self.assertIn('local cityName = "City_" .. tostring(player.UserId)', WORLD)
        self.assertIn("clone.Parent = cityModel", WORLD)
        self.assertIn("Cottage = true", WORLD)
        self.assertIn("Planter = true", WORLD)
        self.assertIn("LanternBase = true", WORLD)

    def test_client_only_renders_its_own_city(self):
        self.assertIn('cityFolder and cityFolder:FindFirstChild("City_" .. tostring(player.UserId))', CLIENT)
        self.assertIn("LocalTransparencyModifier = visible and 0 or 1", CLIENT)
        self.assertIn("descendant.Enabled = visible", CLIENT)
        self.assertIn("sharedHomeParts[descendant.Name]", CLIENT)

    def test_four_plot_records_are_defined_and_unlock_by_farm_level(self):
        self.assertIn('local farmPlotIds = {"Plot01", "Plot02", "Plot03", "Plot04"}', WORLD)
        self.assertIn('if plotId == "Plot02" or plotId == "Plot03" then', WORLD)
        self.assertIn('if plotId == "Plot04" then', WORLD)
        self.assertIn("farm.level >= 2", WORLD)
        self.assertIn("farm.level >= 3", WORLD)

    def test_carrot_is_planted_and_harvested_on_server(self):
        self.assertIn("growthSeconds = 180", WORLD)
        self.assertIn('state.cropId = "Carrot"', WORLD)
        self.assertIn("session.inventory.CarrotSeed -= 1", WORLD)
        self.assertIn("state.readyAt = now + cropDefinitions.Carrot.growthSeconds", WORLD)
        self.assertIn("if now < state.readyAt then", WORLD)
        self.assertIn("session.inventory.Carrot = (session.inventory.Carrot or 0) + 1", WORLD)

    def test_plot_interactions_capture_stable_owner_and_plot_ids(self):
        self.assertIn("local ownerUserId = player.UserId", WORLD)
        self.assertIn("local currentPlotId = plotId", WORLD)
        self.assertIn("interactFarmPlot(visitor, ownerUserId, currentPlotId)", WORLD)

    def test_farm_progress_and_inventory_are_exposed_to_the_hud(self):
        self.assertIn('player:SetAttribute("Farm_Level"', WORLD)
        self.assertIn("Resource_CarrotSeed", CLIENT)
        self.assertIn("Resource_Carrot", CLIENT)
        self.assertIn("МАТЕРИАЛЫ И ФЕРМА", CLIENT)

    def test_city_models_follow_the_shared_mossback_transform(self):
        self.assertIn("cityModel.Parent = cityFolder", WORLD)
        self.assertIn("local origin = giant:GetPivot()", WORLD)
        self.assertIn("giant:PivotTo(frame)", WORLD)


if __name__ == "__main__":
    unittest.main()
