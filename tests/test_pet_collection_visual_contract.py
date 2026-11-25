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
        self.assertIn('card(body, pet.id .. "Card", compact and 394 or 254)', HUD)
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


    def test_every_pet_has_an_explicit_rarity_and_a_visible_rarity_badge(self):
        pet_ids = ("Fox", "Moth", "CrystalWisp", "HarvestSprite", "BrambleBun",
                   "MossTurtle", "Glowcap", "Dewdrop", "Starling")
        for pet_id in pet_ids:
            pet_line = next(line for line in HUD.splitlines() if 'id = "' + pet_id + '"' in line)
            self.assertIn("rarity =", pet_line, f"{pet_id} must declare its collection rarity")
        for rarity in ("Обычный", "Редкий", "Эпический", "Легендарный", "Сезонный"):
            self.assertIn('["' + rarity + '"] = {color =', HUD)
        self.assertIn('local displayRarity = owned and type(mutationRarity) == "string"', HUD)
        self.assertIn('rarityBadge.Name = "RarityBadge"', HUD)
        self.assertIn('rarityBadge.Position = UDim2.new(1, -92, 0, 12)', HUD)
        self.assertIn('rarityRail.Name = "RarityAccent"', HUD)
        self.assertIn('rarityBorder.Thickness = displayRarity == "Легендарный" and 2 or 1.35', HUD)

    def test_compact_pet_name_reserves_space_for_the_rarity_badge(self):
        self.assertIn('compact and UDim2.new(1, hasHeroPreview and -188 or -168, 0, 58)', HUD)
        self.assertIn('rarityBadge.Size = UDim2.fromOffset(82, 23)', HUD)

    def test_legendary_rarity_badge_has_a_distinct_gold_finish(self):
        self.assertIn('if displayRarity == "Легендарный" then', HUD)
        self.assertIn('gradient(rarityBadge, Color3.fromRGB(255, 246, 213), Color3.fromRGB(246, 207, 126))', HUD)


    def test_pet_cards_open_a_dedicated_profile_and_can_return_to_the_collection(self):
        self.assertIn('local companionProfileSelected = nil', HUD)
        self.assertIn('detailsButton = button(item, "OpenProfile", "ПОДРОБНЕЕ О ПИТОМЦЕ"', HUD)
        self.assertIn('companionProfileSelected = pet.id', HUD)
        self.assertIn('local back = button(body, "BackToPetCollection", "←  ВСЕ ПИТОМЦЫ"', HUD)
        self.assertIn('companionProfileSelected = nil', HUD)
        self.assertIn('refreshActiveTab()', HUD)

    def test_pet_profile_shows_identity_progress_mutation_and_talent(self):
        for section in ("CompanionProfileHero", "ProfileName", "ProfileRole", "ProfileRarityBadge",
                        "ЗНАКОМСТВО", "ХАРАКТЕР И НАСТРОЕНИЕ", "РОСТ И ДРУЖБА",
                        "ОСОБАЯ ФОРМА", "ТАЛАНТ"):
            self.assertIn(section, HUD)
        self.assertIn('CompanionProfilePreview', HUD)
        self.assertIn('CompanionProfilePortrait', HUD)
        self.assertIn('Companion_" .. selectedPet.id .. "_Bond', HUD)
        self.assertIn('Companion_" .. selectedPet.id .. "_XP', HUD)

    def test_pet_profile_keeps_all_four_existing_server_authoritative_care_actions(self):
        self.assertIn('profileAction("CallCompanion"', HUD)
        self.assertIn('event:FireServer(selectedPet.id)', HUD)
        self.assertIn('event:FireServer("FeedCompanion", selectedPet.id)', HUD)
        self.assertIn('event:FireServer("StartCompanionPlay", selectedPet.id)', HUD)
        self.assertIn('event:FireServer("PetCompanion", selectedPet.id)', HUD)
        self.assertIn('owned and equipped and foodCount > 0', HUD)

    def test_pet_profile_has_mobile_and_desktop_sizing(self):
        self.assertIn('compactProfile and 188 or 222', HUD)
        self.assertIn('compactProfile and 132 or 164', HUD)
        self.assertIn('compact and 394 or 254', HUD)

    def test_preview_is_not_allowed_to_replace_server_authoritative_actions(self):
        self.assertIn('event:FireServer("FeedCompanion", pet.id)', HUD)
        self.assertIn('event:FireServer("StartCompanionPlay", pet.id)', HUD)
        self.assertIn('event:FireServer("PetCompanion", pet.id)', HUD)
        self.assertIn('event:FireServer(pet.id)', HUD)


if __name__ == "__main__":
    unittest.main()
