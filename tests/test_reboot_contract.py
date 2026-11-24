from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
SPEC = (ROOT / "PROJECT_SPEC.md").read_text(encoding="utf-8")


class RebootContractTests(unittest.TestCase):




    def test_mobile_topbar_geometry_fits_minimum_supported_viewports(self):
        # Mirror the compact HUD sizing rules at the supported 375 px minimum.
        for viewport_width in (320, 375, 414, 480, 620, 699):
            compact = viewport_width < 620
            narrow = viewport_width < 480
            top_bar_width = viewport_width - (16 if compact else 32)
            brand_width = (104 if narrow else 132) if compact else 178
            resources_width = (144 if narrow else 174) if compact else 214
            self.assertGreaterEqual(brand_width, 1, f"{viewport_width}px brand")
            self.assertGreaterEqual(resources_width, 1, f"{viewport_width}px resources")
            self.assertLessEqual(
                brand_width + resources_width,
                top_bar_width,
                f"{viewport_width}px top bar overlaps",
            )

    def test_compact_topbar_reserves_a_gap_without_overlapping_brand_and_resources(self):
        self.assertIn('brand.Size = UDim2.fromOffset(compact and (narrow and 104 or 132) or 178, compact and 48 or 58)', HUD)
        self.assertIn('resources.Size = UDim2.fromOffset(compact and (narrow and 150 or 174) or 214, compact and 48 or 58)', HUD)
        self.assertIn('topBar.Position = UDim2.fromOffset(compact and 8 or 16, compact and 8 or 16)', HUD)
        self.assertIn('local narrow = viewport.X < 480', HUD)

    def test_hud_callbacks_are_forward_declared_before_renderers_use_them(self):
        toast_decl = HUD.index("local showToast")
        objective_decl = HUD.index("local getObjective")
        render_city = HUD.index("local function renderCity")
        render_pets = HUD.index("local function renderPets")
        self.assertLess(toast_decl, render_pets)
        self.assertLess(objective_decl, render_city)
        self.assertEqual(HUD.count("local showToast"), 1)
        self.assertEqual(HUD.count("local getObjective"), 1)

    def test_toast_lifetime_is_generation_safe_when_messages_arrive_quickly(self):
        self.assertIn("local toastGeneration = 0", HUD)
        self.assertIn("local currentGeneration = toastGeneration", HUD)
        self.assertIn("currentGeneration ~= toastGeneration", HUD)
        self.assertIn("toastTween:Cancel()", HUD)

    def test_compact_panel_height_is_clamped_for_short_viewports(self):
        self.assertIn("math.max(210, math.min(560, viewport.Y - (shortScreen and 64 or compact and 112 or 160)))", HUD)
        self.assertIn("panel.Size = UDim2.fromOffset(panelWidth, panelHeight)", HUD)

    def test_product_spec_uses_fixed_archipelago(self):
        self.assertIn("Острова **не перемещаются**", SPEC)
        self.assertIn("строительство мостов", SPEC)
        self.assertIn("Первый вертикальный срез", SPEC)

    def test_each_player_gets_a_static_home_island_clone(self):
        self.assertIn('obj(server_storage, "Model", "HomeIslandTemplate")', BUILD)
        self.assertIn('ServerStorage:WaitForChild("HomeIslandTemplate")', WORLD)
        self.assertIn("homeIslandTemplate:Clone()", WORLD)
        self.assertIn('homeIslandFolder.Name = "PlayerIslands"', WORLD)
        self.assertIn('island.Name = "HomeIsland_" .. tostring(player.UserId)', WORLD)
        self.assertNotIn("workspace.Mossback", WORLD)

    def test_server_does_not_move_home_islands_or_switch_docks(self):
        self.assertNotIn("giant:PivotTo(frame)", WORLD)
        self.assertNotIn("atDusk", WORLD)
        self.assertNotIn("sailing", WORLD)
        self.assertNotIn('SetAttribute("Dock"', WORLD)

    def test_client_no_longer_teaches_sailing_or_dock_switching(self):
        self.assertNotIn('GetAttribute("Dock")', CLIENT)
        self.assertNotIn("Штурвал", CLIENT)
        self.assertNotIn("Колокольчик", CLIENT)

    def test_eight_permanent_bridges_are_generated_around_the_hub(self):
        self.assertIn('obj(w, "Model", "BridgeToGrove")', BUILD)
        self.assertIn('obj(w, "Model", "BridgeToDusk")', BUILD)
        self.assertIn("for slot_index in range(8):", BUILD)
        self.assertIn("HomeBridge{slot_index + 1:02d}", BUILD)
        self.assertIn("add_radial_bridge", BUILD)
        self.assertIn('\"BridgeDeck\"', BUILD)
        self.assertIn('\"BridgeRail\"', BUILD)
        self.assertIn('\"BridgePost\"', BUILD)

    def test_bridge_visuals_use_consistent_materials_and_lighting(self):
        self.assertIn('item.Name == "BridgeDeck"', VISUALS)
        self.assertIn("Enum.Material.WoodPlanks", VISUALS)
        self.assertIn('item.Name == "BridgeLamp"', VISUALS)
        self.assertIn("addLight(item, palette.gold", VISUALS)

    def test_unified_hud_has_one_clear_navigation(self):
        for label in ("ОСТРОВ", "ФЕРМА", "ПИТОМЦЫ", "КАРТА"):
            self.assertIn(label, HUD)
        self.assertIn('gui.Name = "GiantbackHUD"', HUD)
        self.assertIn('local panel = Instance.new("Frame")', HUD)

    def test_farm_screen_explains_planting_and_harvesting(self):
        self.assertIn("Подойди к свободной грядке", HUD)
        self.assertIn("Собрать", HUD)
        self.assertIn('"Farm_" .. plotId .. "_Unlocked"', HUD)
        self.assertIn('"Farm_" .. plotId .. "_ReadyAt"', HUD)
        self.assertIn('player:GetAttribute("Resource_" .. crop.seed)', HUD)
        self.assertIn('player:GetAttribute("Resource_" .. crop.id)', HUD)

    def test_pet_screen_explains_roles_and_equipping(self):
        self.assertIn("Разведчик", HUD)
        self.assertIn("Хранитель света", HUD)
        self.assertIn("ПОЗВАТЬ", HUD)
        self.assertIn("event:FireServer(pet.id)", HUD)

    def test_legacy_hud_is_disabled_and_new_hud_is_embedded(self):
        self.assertNotIn('GiantbackJournal', CLIENT)
        self.assertIn('root / "HUD.client.luau"', BUILD)

    def test_world_map_describes_the_fixed_bridge_hub(self):
        self.assertIn('workspace:FindFirstChild("BridgeToGrove")', HUD)
        self.assertIn('workspace:FindFirstChild("BridgeToDusk")', HUD)
        self.assertIn("Все острова остаются на своих местах", HUD)
        self.assertIn("восемь домашних островов", HUD.lower())


if __name__ == "__main__":
    unittest.main()
