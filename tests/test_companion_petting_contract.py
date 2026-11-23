from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
STARDUST = (ROOT / "modules/MothStardust.luau").read_text(encoding="utf-8")
INTERACTIONS = (ROOT / "modules/CompanionInteractions.luau").read_text(encoding="utf-8")
FOLLOW = (ROOT / "modules/CompanionFollow.luau").read_text(encoding="utf-8")
ACTIVITY = (ROOT / "modules/CompanionActivity.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules/CompanionAnimation.luau").read_text(encoding="utf-8")


class CompanionPettingContractTests(unittest.TestCase):
    def test_petting_is_server_validated_for_owned_equipped_companion(self):
        self.assertIn("local function petCompanion(player, companionId)", WORLD)
        self.assertIn('player:GetAttribute(companionId) ~= true', WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= companionId', WORLD)
        self.assertIn('if action == "PetCompanion" then', WORLD)
        self.assertIn("petCompanion(player, payload)", WORLD)

    def test_petting_has_independent_cooldown_and_grants_small_friendship_reward(self):
        self.assertIn("companionPetReadyAt", WORLD)
        self.assertIn("session.companionPetReadyAt[companionId] = now + 18", WORLD)
        self.assertIn("progressData.bond = math.clamp((progressData.bond or 0) + 5, 0, 1000)", WORLD)
        self.assertIn('setCompanionMood(player, companionId, "Радость")', WORLD)
        self.assertIn('event:FireClient(player, "CompanionPetted"', WORLD)

    def test_pets_card_offers_petting_only_for_owned_equipped_companion(self):
        self.assertIn('button(item, "Pet"', HUD)
        self.assertIn('event:FireServer("PetCompanion", pet.id)', HUD)
        self.assertIn("petButton.Active = owned and equipped", HUD)

    def test_equipped_companion_can_be_petted_from_world_prompt(self):
        self.assertIn("local function attachWorldPetPrompt(model, companionId)", INTERACTIONS)
        self.assertIn('prompt.Name = "WorldPetPrompt"', INTERACTIONS)
        self.assertIn('prompt.ActionText = "Погладить"', INTERACTIONS)
        self.assertIn("prompt.HoldDuration = 0.35", INTERACTIONS)
        self.assertIn("prompt.GamepadKeyCode = Enum.KeyCode.ButtonX", INTERACTIONS)
        self.assertIn('event:FireServer("PetCompanion", companionId)', INTERACTIONS)
        self.assertIn("attachWorldPetPrompt(model, id)", ALBUM)

    def test_species_play_distinct_affection_poses(self):
        self.assertIn("local affectionateDip = math.sin(time * 6.5)", ANIMATION)
        self.assertIn("math.rad(-4)", ANIMATION)
        self.assertIn("petting and 0.11", ANIMATION)
        self.assertIn("local affectionateNod = math.sin(time * 7)", ANIMATION)
        self.assertIn('part.Name == "Moth head" and petting', ANIMATION)

    def test_fox_has_periodic_idle_curiosity_and_moth_has_local_orbit_stardust(self):
        self.assertIn("nextCuriosityAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))", ACTIVITY)
        self.assertIn("foxSniffUntil = os.clock() + 2.2", ALBUM)
        self.assertIn("activity.nextCuriosityAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))", ACTIVITY)
        self.assertIn("local function attachMothStardust(model)", STARDUST)
        self.assertIn('emitter.Name = "CompanionStardust"', STARDUST)
        self.assertIn("emitter.Rate = mothStardustRate(personality, bondStage)", STARDUST)
        self.assertIn('id == "Moth" and isLocal', FOLLOW)
        self.assertIn("local orbitAngle = phase * (orbitSpeeds[personality] or 0.72)", FOLLOW)
        self.assertIn("attachMothStardust(model)", ALBUM)

    def test_petting_feedback_visuals_scale_with_server_relationship_stage(self):
        self.assertIn("bondStage = bondStage", WORLD)
        self.assertIn("payload.bondStage", ALBUM)
        self.assertIn("local function playCompanionPettingBurst(model, companionId, bondStage)", INTERACTIONS)
        self.assertIn("local sparkCount = 5 + bondStage * 2", INTERACTIONS)
        self.assertIn("baseColor:Lerp(palette.gold, bondStage / 4)", INTERACTIONS)
        self.assertIn('bondStage >= 4 and (index % 2 == 0 and "♥" or "✧")', INTERACTIONS)
        self.assertIn("playCompanionPettingBurst(model, id, bondStage)", ALBUM)
        self.assertIn("pendingPetBurst[id] ~= nil", ALBUM)

    def test_client_plays_species_specific_reaction_and_visual_feedback(self):
        self.assertIn('message == "CompanionPetted"', ALBUM)
        self.assertIn("pettingUntil", ALBUM)
        self.assertIn("playCompanionPettingBurst(model, id, bondStage)", ALBUM)
        self.assertIn("swaySpeed = 10.5", ANIMATION)
        self.assertIn("if petting and not mothAbility then", ANIMATION)
        self.assertIn("flapSpeed = 17", ANIMATION)
        self.assertIn("CompanionPettingBurstLocal", INTERACTIONS)


if __name__ == "__main__":
    unittest.main()
