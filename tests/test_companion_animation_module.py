"""Companion animation module integration and ownership safeguards."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules/CompanionAnimation.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")


class CompanionAnimationModuleTests(unittest.TestCase):
    def test_embedded_runtime_module(self):
        self.assertIn('companion_animation = obj(storage, "ModuleScript", "CompanionAnimation")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionAnimation"))', CLIENT)
        self.assertIn("CompanionAnimation.capture(model, id, isEncounter, isLocal)", CLIENT)
        self.assertIn("CompanionAnimation.animate(model, state, time, moving, resting,", CLIENT)

    def test_live_ability_context_and_model_lifecycle_remain_in_client(self):
        for marker in (
            "animationStates[model] = state",
            "player, foxSniffUntil, mothAbilityUntil, pettingUntil, state.searching == true)",
            "animationStates[model] = nil",
            "setSleepIndicator(model, false)",
            "local function follow(dt)",
            "captureAnimation(model, id, false, owner == player)",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, CLIENT)

    def test_three_species_and_motion_consistency(self):
        for marker in (
            'state.id == "Fox"',
            'state.id == "Moth"',
            'local playful = state.playful == true and not moving and not state.isEncounter',
            'state.id == "CrystalWisp"',
            'local growthStage = math.clamp',
            'local prismSenseActive = state.id == "CrystalWisp"',
            'part.CFrame = pivot * transform * offset',
            'local function aroundPoint(point, rotation)',
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, ANIMATION)


    def test_all_festival_hatchlings_have_species_specific_idle_and_affection_motion(self):
        species_markers = {
            "BrambleBun": ('string.find(part.Name, "Ear")', 'part.Name == "Acorn leaf"', "curiousDip"),
            "MossTurtle": ('part.Name == "Shell"', 'part.Name == "Head"', 'part.Name == "Foot"', "paddle"),
            "Glowcap": ('part.Name == "Mushroom stalk"', 'part.Name == "Mushroom cap"', 'part.Name == "Glow core"', 'part.Name == "Glowcap spot"'),
            "Dewdrop": ('string.find(part.Name, "Fin")', 'part.Name == "Water jewel"', 'part.Name == "Tail fin"'),
            "Starling": ('string.find(part.Name, "Wing")', 'part.Name == "Crest"', 'part.Name == "Star halo"'),
        }
        for species, markers in species_markers.items():
            with self.subTest(species=species):
                self.assertIn('state.id == "' + species + '"', ANIMATION)
                for marker in markers:
                    self.assertIn(marker, ANIMATION)
                self.assertIn('"' + species + '"', VISUALS)

    def test_companion_animation_uses_live_mood_personality_and_deep_sleep_state(self):
        for marker in (
            'state.mood == "Радость"',
            'personality == "Озорной"',
            'personality == "Застенчивый"',
            'state.sleeping',
            'local flapStrength = moving and 0.3 or happy and 0.22',
            'local paddle = moving and math.sin(time * 6.5',
        ):
            self.assertIn(marker, ANIMATION)
        self.assertIn('state.sleeping = sleeping', CLIENT)
        self.assertIn('state.mood = owner:GetAttribute("Companion_" .. id .. "_Mood")', CLIENT)
        self.assertIn('state.personality = owner:GetAttribute("Companion_" .. id .. "_Personality")', CLIENT)


    def test_all_festival_companions_react_to_autonomous_curiosity_state(self):
        self.assertIn('state.curious = curious', CLIENT)
        for marker in (
            'state.curious and 0.18',
            'state.curious and 0.13',
            'state.curious and 5.2',
            'state.curious and math.sin(time * 5.5)',
            'state.curious and 0.22',
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, ANIMATION)

    def test_playful_state_changes_fox_hops_and_moth_wing_flourishes(self):
        self.assertIn('elseif part.Name == "Body" and playful then', ANIMATION)
        self.assertIn('local hop = math.max(0, math.sin(time * 10)) * 0.16', ANIMATION)
        self.assertIn('(playful and 0.62 or sniffing and 0.48 or 0.3)', ANIMATION)
        self.assertIn('mothAbility and 21 or playful and 15 or 11.5', ANIMATION)
        self.assertIn('mothAbility and 0.76 or playful and 0.58 or 0.42', ANIMATION)
        self.assertIn('if resting and not playful then', ANIMATION)
        self.assertIn('if resting and not mothAbility and not playful then', ANIMATION)
        self.assertIn('elseif part.Name == "Moth head" and playful then', ANIMATION)
        self.assertIn('state.playful = playful', CLIENT)

    def test_festival_pet_animations_remain_cosmetic_and_keep_single_render_loop(self):
        for forbidden in ("FireServer(", "InvokeServer(", "DataStoreService", "SetAttribute(", "RenderStepped:Connect"):
            self.assertNotIn(forbidden, ANIMATION)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)

    def test_module_does_not_change_server_state_or_create_duplicate_follow_loop(self):
        for forbidden in ("FireServer(", "InvokeServer(", "DataStoreService", "SetAttribute(", "RenderStepped:Connect"):
            self.assertNotIn(forbidden, ANIMATION)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)
        self.assertEqual(ANIMATION.count('function CompanionAnimation.animate('), 1)
        self.assertEqual(ANIMATION.count('function CompanionAnimation.capture('), 1)


if __name__ == "__main__":
    unittest.main()
