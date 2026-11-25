from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class PetCollectionVisualContracts(unittest.TestCase):
    def test_only_approved_hero_companions_get_3d_collection_previews(self):
        self.assertIn('createApprovedCompanionPreview(\n            item, pet.id, "PetHeroPreview"', HUD)
        self.assertIn('local expectedName = companionId == "Fox" and "FoxCompanion"', HUD)
        self.assertIn('or companionId == "Moth" and "MothCompanion" or nil', HUD)
        self.assertIn('template:GetAttribute("GiantbackImportStatus") ~= "Approved"', HUD)
        self.assertIn('template:GetAttribute("GiantbackRuntimeReady") ~= true', HUD)
        self.assertIn('template:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true', HUD)

    def test_unapproved_companions_keep_a_visible_native_pictogram(self):
        self.assertIn('createPictogram(iconPlate, "PetPictogram", pet.icon, 42, petTint)', HUD)
        self.assertIn('iconPlate.Visible = not hasHeroPreview', HUD)
        self.assertIn('if not expectedName then return false end', HUD)

    def test_compact_pet_cards_reserve_room_for_large_hero_previews(self):
        self.assertIn('card(body, pet.id .. "Card", compact and 354 or 214)', HUD)
        self.assertIn('UDim2.fromOffset(76, 76), UDim2.fromOffset(10, 10)', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 258)', HUD)
        self.assertIn('compact and UDim2.fromOffset(12, 300)', HUD)


    def test_hero_preview_camera_fits_wide_and_tall_models_to_the_viewport(self):
        self.assertIn('local aspectRatio = viewport.AbsoluteSize.X / math.max(viewport.AbsoluteSize.Y, 1)', HUD)
        self.assertIn('local halfFovTangent = math.tan(math.rad(camera.FieldOfView * 0.5))', HUD)
        self.assertIn('local verticalDistance = (boundsSize.Y * 0.5 + framingMargin) / halfFovTangent', HUD)
        self.assertIn('local horizontalDistance = (boundsSize.X * 0.5 + framingMargin) / (halfFovTangent * aspectRatio)', HUD)
        self.assertIn('local cameraDistance = math.max(verticalDistance, horizontalDistance, depthDistance, 1) * 1.08', HUD)
        self.assertIn('camera.CFrame = CFrame.lookAt(focus + viewDirection * cameraDistance, focus)', HUD)

    def test_preview_is_not_allowed_to_replace_server_authoritative_actions(self):
        self.assertIn('event:FireServer("FeedCompanion", pet.id)', HUD)
        self.assertIn('event:FireServer("StartCompanionPlay", pet.id)', HUD)
        self.assertIn('event:FireServer("PetCompanion", pet.id)', HUD)
        self.assertIn('event:FireServer(pet.id)', HUD)


if __name__ == "__main__":
    unittest.main()
