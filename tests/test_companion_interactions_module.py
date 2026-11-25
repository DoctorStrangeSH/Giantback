"""Client pet interactions are isolated; petting authority stays on the server."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
INTERACTIONS = (ROOT / "modules/CompanionInteractions.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionInteractionsModuleTests(unittest.TestCase):
    def test_module_is_embedded_and_used(self):
        self.assertIn('companion_interactions = obj(storage, "ModuleScript", "CompanionInteractions")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionInteractions"))', CLIENT)
        self.assertIn('CompanionInteractions.new(player, event, names, palette)', CLIENT)
        self.assertIn('attachWorldPetPrompt(model, id)', CLIENT)
        self.assertIn('playCompanionPettingBurst(model, id, bondStage)', CLIENT)

    def test_prompt_checks_local_equipped_pet_before_server_request(self):
        for marker in (
            'prompt.Name = "WorldPetPrompt"',
            'prompt.HoldDuration = 0.35',
            'prompt.GamepadKeyCode = Enum.KeyCode.ButtonX',
            'if triggeringPlayer and triggeringPlayer ~= player then return end',
            'if player:GetAttribute("Companion") ~= companionId then return end',
            'event:FireServer("PetCompanion", companionId)',
        ):
            self.assertIn(marker, INTERACTIONS)
        self.assertIn('if anchor:FindFirstChild("WorldPetPrompt") then return end', INTERACTIONS)

    def test_petting_effects_keep_relationship_scaling_and_wisp_color(self):
        self.assertIn('local sparkCount = 5 + bondStage * 2', INTERACTIONS)
        self.assertIn('baseColor:Lerp(palette.gold, bondStage / 4)', INTERACTIONS)
        self.assertIn('companionId == "CrystalWisp" and palette.water', INTERACTIONS)
        self.assertIn('water = Color3.fromRGB(135, 211, 231)', CLIENT)
        self.assertIn('Debris:AddItem(folder, 0.9)', INTERACTIONS)


    def test_idle_attention_bubble_is_local_temporary_and_species_aware(self):
        self.assertIn('local function showCompanionAttention(model, companionId)', INTERACTIONS)
        self.assertIn('billboard.Name = "CompanionAttentionBubble"', INTERACTIONS)
        self.assertIn('if anchor:FindFirstChild("CompanionAttentionBubble") then return end', INTERACTIONS)
        self.assertIn('companionId == "Fox" and "♥"', INTERACTIONS)
        self.assertIn('companionId == "Moth" and "✦"', INTERACTIONS)
        self.assertIn('companionId == "Starling" and "♪"', INTERACTIONS)
        self.assertIn('Debris:AddItem(billboard, 0.35)', INTERACTIONS)
        self.assertIn('showCompanionAttention = showCompanionAttention', INTERACTIONS)
        self.assertIn('local showCompanionAttention = interactions.showCompanionAttention', CLIENT)

    def test_module_does_not_award_bond_or_replace_server_validator(self):
        for forbidden in ('DataStoreService', 'InvokeServer(', ':SetAttribute(', 'companionPetReadyAt'):
            self.assertNotIn(forbidden, INTERACTIONS)
        self.assertEqual(INTERACTIONS.count('event:FireServer("PetCompanion", companionId)'), 1)


if __name__ == "__main__":
    unittest.main()
