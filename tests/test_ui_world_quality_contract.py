"""Contracts for the first UI and world usability quality pass."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class UIWorldQualityContracts(unittest.TestCase):
    def test_hud_responds_to_viewport_and_keeps_navigation_reachable(self):
        self.assertIn('local UserInputService = game:GetService("UserInputService")', HUD)
        self.assertIn('local function updateResponsiveLayout()', HUD)
        self.assertIn('local compact = viewport.X < 620', HUD)
        self.assertIn('local narrow = viewport.X < 480', HUD)
        self.assertIn('local shortScreen = viewport.Y < 440', HUD)
        self.assertIn('local panelWidth = math.max(240, math.min(560, viewport.X - 16))', HUD)
        self.assertIn('local panelHeight = math.max(210, math.min(560, viewport.Y - (shortScreen and 64 or compact and 112 or 160)))', HUD)
        self.assertIn('panel.Size = UDim2.fromOffset(panelWidth, panelHeight)', HUD)
        self.assertIn('nav.Size = UDim2.new(1, compact and -16 or -32, 0, compact and (shortScreen and 48 or 56) or 72)', HUD)
        self.assertIn('titleLabel.Visible = true', HUD)
        self.assertIn('ViewportSize"):Connect(updateResponsiveLayout)', HUD)
        self.assertIn('panel.Visible = true', HUD)
        self.assertIn('gui.IgnoreGuiInset = false', HUD)
        self.assertIn('local updatePlayOverlayLayout', HUD)
        self.assertIn('local width = math.max(240, math.min(340, viewport.X - 24))', HUD)
        self.assertIn('updatePlayOverlayLayout()', HUD)

    def test_farm_and_daily_quest_cards_reflow_on_compact_screens(self):
        self.assertIn('local compact = gui.AbsoluteSize.X < 620', HUD)
        self.assertIn('card(body, "Seed_" .. crop.id, compact and 122 or 82)', HUD)
        self.assertIn('compact and UDim2.new(0.5, -18, 0, 34)', HUD)
        self.assertIn('card(body, "Plot" .. tostring(index), compact and 88 or 66)', HUD)
        self.assertIn('card(body, "DailyQuest_" .. tostring(index), compact and 112 or 78)', HUD)
        self.assertIn('compact and UDim2.new(1, -28, 0, 30)', HUD)
        self.assertIn('compact and "ВЫБРАТЬ МЕСТО" or "ПОСТРОИТЬ"', HUD)

    def test_pet_actions_have_touch_friendly_compact_targets(self):
        self.assertIn('card(body, pet.id .. "Card", compact and 330 or 214)', HUD)
        self.assertIn('local actionSize = compact and UDim2.new(0.5, -18, 0, 36)', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 284)', HUD)
        self.assertIn('compact and UDim2.new(0.5, 6, 0, 284)', HUD)

    def test_weekly_challenges_reflow_and_use_their_real_index(self):
        self.assertIn('card(body, "WeeklyChallenge_" .. tostring(index), compact and 112 or 72)', HUD)
        self.assertIn('label(item, "Number", tostring(index)', HUD)
        self.assertIn('compact and UDim2.new(1, -28, 0, 30)', HUD)
        self.assertIn('UDim2.fromOffset(compact and 14 or 54, compact and 84 or 51)', HUD)
        self.assertIn('compact and UDim2.new(1, -90, 0, 18)', HUD)

    def test_important_icons_are_native_gui_pictograms(self):
        self.assertIn('local function createPictogram(parent, name, kind, size, tint)', HUD)
        self.assertIn('local function setPictogramColor(root, color)', HUD)
        self.assertIn('part("FallbackBadge"', HUD)
        self.assertIn('FallbackMark', HUD)
        self.assertIn('local playSymbols = {"1", "2", "3"}', HUD)
        self.assertNotIn(' · ✦ ', HUD)
        self.assertNotIn('☀ Солнечные лепестки', HUD)
        self.assertNotIn('☾ Лунные лепестки', HUD)
        for icon_kind in ('house', 'farm', 'paw', 'backpack', 'map', 'journal',
                          'wood', 'stone', 'fox', 'moth', 'crystal', 'carrot',
                          'berry', 'pumpkin', 'cabbage', 'flower', 'greenhouse',
                          'lamp', 'fence', 'bench', 'tree', 'birdbath', 'axe',
                          'pickaxe', 'sword', 'egg', 'owl', 'turtle'):
            self.assertIn(f'"{icon_kind}"', HUD)
        self.assertNotIn('glyph = "О"', HUD)
        self.assertNotIn('icon = "Л"', HUD)
        self.assertNotIn('definition.glyph', HUD)

    def test_companion_mutation_album_has_progress_discovery_states_and_visual_cards(self):
        self.assertIn('card(body, "CompanionMutationCodexHeader", 82)', HUD)
        self.assertIn('CodexProgressTrack', HUD)
        self.assertIn('CodexProgressFill', HUD)
        self.assertIn('discoveredMutations / #mutationPets', HUD)
        self.assertIn('card(body, "CompanionMutationCodex_" .. tostring(index), compactAlbum and 92 or 82)', HUD)
        self.assertIn('MutationIconPlate', HUD)
        self.assertIn('found and pet.icon or "lock"', HUD)
        self.assertIn('found and "ОТКРЫТО" or "ИСКАТЬ"', HUD)
        self.assertIn('"Место поиска: " .. pet.biome', HUD)
        self.assertIn('CompanionCodexRewardClaimed', HUD)
        self.assertIn('ClaimCompanionCodexReward', HUD)

    def test_bridges_are_wider_and_rails_follow_new_deck_edges(self):
        self.assertIn('(8.2, 0.55, plank_length)', BUILD)
        self.assertEqual(BUILD.count('side * 4.15'), 4)
        self.assertEqual(BUILD.count('side * 3.35'), 2)
        self.assertNotIn('(5.2, 0.48, plank_length)', BUILD)

    def test_fall_recovery_is_server_authoritative_and_preserves_character(self):
        self.assertIn('root.Position.Y < -80', WORLD)
        self.assertIn('character:PivotTo(recovery.CFrame + Vector3.new(0, 6, 0))', WORLD)
        self.assertIn('root.AssemblyLinearVelocity = Vector3.zero', WORLD)
        self.assertIn('root.AssemblyAngularVelocity = Vector3.zero', WORLD)
        self.assertIn('sessions[player] == session', WORLD)
        self.assertIn('workspace:FindFirstChild("Grove")', WORLD)
        self.assertIn('spawn:IsA("BasePart")', WORLD)

    def test_world_signs_are_distance_limited_and_not_always_on_top(self):
        self.assertIn('dummySign.MaxDistance = 55', VISUALS)
        self.assertIn('warningBillboard.MaxDistance = 65', VISUALS)
        self.assertIn('label.MaxDistance = 34', VISUALS)
        self.assertIn('dummySign.AlwaysOnTop = false', VISUALS)
        self.assertIn('warningBillboard.AlwaysOnTop = false', VISUALS)
        self.assertIn('label.AlwaysOnTop = false', VISUALS)

    def test_russian_copy_is_clear_and_navigation_has_single_active_panel(self):
        self.assertIn('Друзья могут приходить в гости, но строить и менять что-либо здесь можешь только ты.', HUD)
        self.assertIn('На острове четыре грядки. Открой раздел «Ферма»', HUD)
        self.assertIn('if activeTab == tabName and panel.Visible then', HUD)
        self.assertIn('panel.Visible = false', HUD)


if __name__ == "__main__":
    unittest.main()
