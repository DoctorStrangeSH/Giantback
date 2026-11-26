from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class WorldWayfindingTests(unittest.TestCase):
    def test_bridge_landings_have_small_physical_destination_signs(self):
        self.assertIn('addWayfindingSign("GroveWayfindingSign"', VISUALS)
        self.assertIn('"СОЛНЕЧНАЯ РОЩА"', VISUALS)
        self.assertIn('addWayfindingSign("DuskWayfindingSign"', VISUALS)
        self.assertIn('"СУМЕРЕЧНАЯ ДОЛИНА"', VISUALS)
        self.assertIn('"GiantbackWorldDetails"', VISUALS)

    def test_wayfinding_signs_are_decorative_and_do_not_block_players(self):
        self.assertIn('local function addWayfindingSign(name, position, title, subtitle, accent)', VISUALS)
        self.assertIn('makePart(sign, "SignPost"', VISUALS)
        self.assertIn('makePart(sign, "SignBoard"', VISUALS)
        self.assertIn('Enum.NormalId.Front', VISUALS)
        self.assertIn('heading.TextScaled = true', VISUALS)
        self.assertIn('caption.TextWrapped = true', VISUALS)
        self.assertIn('part.CanCollide = false', VISUALS)

    def test_existing_fox_cache_anchors_receive_subtle_directional_trails(self):
        self.assertIn('local foxCacheAnchors = {"FoxCache01", "FoxCache02", "FoxCache03"}', VISUALS)
        self.assertIn("local function addCacheTrail(parent, anchor)", VISUALS)
        self.assertIn('"Quiet cache trail"', VISUALS)
        self.assertIn("direction = direction.Unit", VISUALS)
        self.assertIn("addCacheTrail(visual, anchor)", VISUALS)
        self.assertIn("0.42 + step * 0.08", VISUALS)

    def test_crystal_grotto_entrance_has_non_interactive_visual_landmarks(self):
        self.assertIn('makeFolder(dusk, "CrystalGrottoEntranceLandmarks")', VISUALS)
        self.assertIn('"Entrance crystal"', VISUALS)
        self.assertIn("grottoEntrance.Position", VISUALS)
        self.assertIn('placeTrialPrompt(grottoEntrance, "Запечатанная кристальная пещера", "Исследовать")', VISUALS)
        self.assertIn("addLight(crystal, palette.lilacLight, 5, 0.22)", VISUALS)

    def test_cache_trails_reuse_existing_cache_anchors_without_new_prompts(self):
        self.assertIn('grove:FindFirstChild(cacheId)', VISUALS)
        self.assertNotIn('ProximityPrompt', VISUALS[VISUALS.index("local function addCacheTrail"):VISUALS.index("local moonBloomVisuals")])

    def test_fox_habitat_uses_existing_grove_nest_without_changing_encounter(self):
        self.assertIn('local foxNest = grove:FindFirstChild("Nest")', VISUALS)
        self.assertIn('makeFolder(habitatVisuals, "FoxNestHabitat")', VISUALS)
        self.assertIn('"Fern shelter"', VISUALS)
        self.assertIn('"Foxglove mushroom"', VISUALS)
        self.assertIn('local mothNest = dusk:FindFirstChild("Nest")', VISUALS)

    def test_moth_habitat_uses_moonlit_resting_visuals(self):
        self.assertIn('makeFolder(habitatVisuals, "MothRestingGrove")', VISUALS)
        self.assertIn('"Moonlit resting stone"', VISUALS)
        self.assertIn('"Moon moth lantern flower"', VISUALS)
        self.assertIn('"Moon moth petal"', VISUALS)

    def test_companion_habitat_visuals_do_not_add_prompts_or_collisions(self):
        start = VISUALS.index('local habitatVisuals = makeFolder(workspace, "GiantbackCompanionHabitats")')
        end = VISUALS.index('local foxCacheVisuals = makeFolder(grove, "FoxCacheVisuals")', start)
        habitat_code = VISUALS[start:end]
        self.assertNotIn("ProximityPrompt", habitat_code)
        self.assertNotIn("CanCollide = true", habitat_code)
        self.assertIn('grove:FindFirstChild("Nest")', habitat_code)
        self.assertIn('dusk:FindFirstChild("Nest")', habitat_code)

    def test_fox_habitat_has_small_ground_level_pawprints(self):
        self.assertIn('addHabitatTracks(habitatVisuals:FindFirstChild("FoxNestHabitat"), foxNest, "Fox")', VISUALS)
        self.assertIn('"Tiny paw print"', VISUALS)
        self.assertIn('"Paw toe"', VISUALS)
        self.assertIn("local function addHabitatTracks(parent, nest, kind)", VISUALS)

    def test_moth_habitat_has_soft_moon_dust_trail(self):
        self.assertIn('addHabitatTracks(habitatVisuals:FindFirstChild("MothRestingGrove"), mothNest, "Moth")', VISUALS)
        self.assertIn('"Moon dust mote"', VISUALS)
        self.assertIn("palette.lilacLight", VISUALS)

    def test_habitat_traces_are_visual_only_and_rebuilt_with_habitat_folder(self):
        start = VISUALS.index("local function addHabitatTracks(parent, nest, kind)")
        end = VISUALS.index('local foxCacheVisuals = makeFolder(grove, "FoxCacheVisuals")', start)
        trace_code = VISUALS[start:end]
        self.assertNotIn("ProximityPrompt", trace_code)
        self.assertNotIn("CanCollide = true", trace_code)
        self.assertIn('makeFolder(parent, kind .. "Tracks")', trace_code)

    def test_fall_recovery_returns_character_to_owners_home_without_resetting_inventory(self):
        self.assertIn('root.Position.Y < -80', WORLD)
        self.assertIn('local recovery = session.homeSpawn', WORLD)
        self.assertIn('character:PivotTo(recovery.CFrame + Vector3.new(0, 6, 0))', WORLD)
        self.assertIn('root.AssemblyLinearVelocity = Vector3.zero', WORLD)
        self.assertIn('root.AssemblyAngularVelocity = Vector3.zero', WORLD)
        self.assertIn('humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)', WORLD)


if __name__ == "__main__":
    unittest.main()
