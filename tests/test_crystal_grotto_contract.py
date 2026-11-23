from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ANIMATION = (ROOT / "modules/CompanionAnimation.luau").read_text(encoding="utf-8")
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
COMBAT_CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")


class CrystalGrottoContractTests(unittest.TestCase):
    def test_grotto_is_a_real_visual_destination_with_a_return_path(self):
        self.assertIn('crystalGrotto.Name = "CrystalGrotto"', VISUALS)
        self.assertIn('"CrystalGrottoArrival"', VISUALS)
        self.assertIn('"CrystalGrottoReturn"', VISUALS)
        self.assertIn('"CrystalGrottoEntrance"', VISUALS)
        self.assertIn('crystalGrotto.Parent = combatGlade', VISUALS)

    def test_access_requires_the_persisted_moon_relic(self):
        self.assertIn('"CrystalGrottoDiscovered"', WORLD.split("local inventoryKeys")[0])
        self.assertIn('if not player:GetAttribute("MoonRelic") then', WORLD)
        self.assertIn('player:SetAttribute("CrystalGrottoDiscovered", true)', WORLD)
        self.assertIn('character:PivotTo(crystalArrival.CFrame', WORLD)

    def test_crystal_heart_is_a_single_server_granted_persistent_reward(self):
        self.assertIn('"CrystalHeart"', WORLD.split("local inventoryKeys")[0])
        self.assertIn('"CrystalShard"', WORLD.split("local toolIds")[0])
        self.assertIn('if player:GetAttribute("CrystalHeart") then', WORLD)
        self.assertIn('session.inventory.CrystalShard = (session.inventory.CrystalShard or 0) + 1', WORLD)
        self.assertIn('syncInventory(player)', WORLD)
        self.assertIn('if session.online and not save(player) then', WORLD)

    def test_grotto_prompts_reuse_visual_prompt_anchors(self):
        self.assertIn('connectTrialPrompt(crystalEntrance, function(player)', WORLD)
        self.assertIn('connectTrialPrompt(crystalReturn, function(player)', WORLD)
        self.assertIn('connectTrialPrompt(crystalHeart, function(player)', WORLD)
        self.assertNotIn('prompt(crystalEntrance,', WORLD)
        self.assertNotIn('prompt(crystalReturn,', WORLD)
        self.assertNotIn('prompt(crystalHeart,', WORLD)

    def test_lumen_crystal_deposits_use_the_existing_pickaxe_harvesting_loop(self):
        self.assertIn('CrystalGrottoLumen01 = true', WORLD)
        self.assertIn('CrystalGrottoLumen02 = true', WORLD)
        self.assertIn('key = "CrystalGrottoLumen01", amount = 1, requiredTool = "Pickaxe", hitsRequired = 6', WORLD)
        self.assertIn('key = "CrystalGrottoLumen02", amount = 1, requiredTool = "Pickaxe", hitsRequired = 6', WORLD)
        self.assertIn('itemId = "CrystalShard"', WORLD)
        self.assertIn('respawnSeconds = 900', WORLD)

    def test_grotto_resource_nodes_spawn_inside_the_cave_model(self):
        self.assertIn('if def.area == "CrystalGrotto" then', WORLD)
        self.assertIn('island = glade and glade:FindFirstChild("CrystalGrotto")', WORLD)
        self.assertIn('origin = island and island:FindFirstChild("CrystalGrottoFloor")', WORLD)
        self.assertIn('local crystalGrotto = Instance.new("Model")', VISUALS)
        self.assertIn('def.visual == "crystal"', WORLD)

    def test_crystal_mining_requires_cave_membership_and_nearby_interaction(self):
        self.assertIn('player:GetAttribute("InCrystalGrotto") ~= true', WORLD)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 13', WORLD)
        self.assertIn('session.equippedTool ~= def.requiredTool', WORLD)


    def test_grotto_rune_puzzle_uses_the_clued_order_and_player_local_progress(self):
        self.assertIn('local crystalRuneSequence = {"CrystalRuneMoon", "CrystalRuneDawn", "CrystalRuneTide"}', WORLD)
        self.assertIn('local crystalRuneProgress = {}', WORLD)
        self.assertIn('now - state.lastAt > 25', WORLD)
        self.assertIn('player:GetAttribute("CrystalRunes")', WORLD)
        self.assertIn('player:SetAttribute("CrystalRunes", true)', WORLD)
        self.assertIn('if session.online then save(player) end', WORLD)

    def test_grotto_cache_requires_runes_and_grants_one_persistent_sigil(self):
        self.assertIn('local crystalCache = crystalGrotto and crystalGrotto:FindFirstChild("CrystalGrottoCache")', WORLD)
        self.assertIn('if not player:GetAttribute("CrystalRunes") then', WORLD)
        self.assertIn('if player:GetAttribute("CrystalCache") then', WORLD)
        self.assertIn('player:SetAttribute("CrystalCache", true)', WORLD)
        self.assertIn('session.inventory.CrystalSigil = (session.inventory.CrystalSigil or 0) + 1', WORLD)
        self.assertIn('"CrystalSigil", "PrismSeed"}', WORLD.split("local toolIds")[0])

    def test_rune_puzzle_and_cache_are_real_visual_interactions(self):
        self.assertIn('name = "CrystalRuneMoon"', VISUALS)
        self.assertIn('name = "CrystalRuneDawn"', VISUALS)
        self.assertIn('name = "CrystalRuneTide"', VISUALS)
        self.assertIn('Луна → Рассвет → Прилив', VISUALS)
        self.assertIn('"CrystalGrottoCache"', VISUALS)
        self.assertIn('placeTrialPrompt(crystalCache', VISUALS)

    def test_rune_progress_is_cleaned_up_when_player_leaves(self):
        self.assertIn('crystalRuneProgress[player] = nil', WORLD)


    def test_crystal_fall_event_warns_before_damage_and_uses_a_visible_impact_zone(self):
        self.assertIn('local function runCrystalFallEvent()', WORLD)
        self.assertIn('warning.Name = "CrystalFallWarning"', WORLD)
        self.assertIn('warning.Size = Vector3.new(0.18, 16, 16)', WORLD)
        self.assertIn('task.wait(3)', WORLD)
        self.assertIn('TweenService:Create(', WORLD)
        self.assertIn('shard.Name = "CrystalFallShard"', WORLD)
        self.assertIn('humanoid:TakeDamage(18)', WORLD)
        self.assertIn('(root.Position - impactPosition).Magnitude <= 8', WORLD)

    def test_crystal_fall_only_runs_when_players_are_inside_the_grotto(self):
        self.assertIn('local function getCrystalGrottoPlayers()', WORLD)
        self.assertIn('for player, inside in crystalGrottoInside do', WORLD)
        self.assertIn('if #getCrystalGrottoPlayers() > 0 then', WORLD)
        self.assertIn('crystalFallRandom:NextNumber(-16, 16)', WORLD)
        self.assertIn('crystalFallRandom:NextNumber(-13, 13)', WORLD)

    def test_echo_chamber_requires_the_persistent_cache_sigil(self):
        self.assertIn('local crystalEchoGate = crystalGrotto and crystalGrotto:FindFirstChild("CrystalEchoGate")', WORLD)
        self.assertIn('if not player:GetAttribute("CrystalCache") or (session.inventory.CrystalSigil or 0) < 1 then', WORLD)
        self.assertIn('crystalEchoInside[player] = true', WORLD)
        self.assertIn('player:SetAttribute("CrystalEchoDiscovered", true)', WORLD)

    def test_echo_chamber_has_a_return_route_and_cleans_player_state(self):
        self.assertIn('local crystalEchoReturn = crystalGrotto and crystalGrotto:FindFirstChild("CrystalEchoReturn", true)', WORLD)
        self.assertIn('crystalEchoInside[player] = nil', WORLD)
        self.assertIn('character:PivotTo(crystalEchoGate.CFrame', WORLD)
        self.assertIn('crystalEchoInside[player] = nil', WORLD)

    def test_prism_seed_is_a_unique_persistent_server_reward(self):
        self.assertIn('"PrismSeed"}', WORLD.split("local toolIds")[0])
        self.assertIn('if player:GetAttribute("PrismSeedFound") then', WORLD)
        self.assertIn('player:SetAttribute("PrismSeedFound", true)', WORLD)
        self.assertIn('session.inventory.PrismSeed = (session.inventory.PrismSeed or 0) + 1', WORLD)
        self.assertIn('syncInventory(player)', WORLD)

    def test_echo_chamber_and_prism_seed_are_present_in_world_visuals(self):
        self.assertIn('echoChamber.Name = "CrystalEchoChamber"', VISUALS)
        self.assertIn('"CrystalEchoFloor"', VISUALS)
        self.assertIn('"CrystalEchoGate"', VISUALS)
        self.assertIn('"CrystalEchoReturn"', VISUALS)
        self.assertIn('"PrismSeed"', VISUALS)


    def test_crystal_wisp_is_a_persistent_third_companion_with_grotto_mutations(self):
        self.assertIn('local COMPANION_IDS = {"Fox", "Moth", "CrystalWisp", "HarvestSprite", "BrambleBun", "MossTurtle", "Glowcap", "Dewdrop", "Starling"}', WORLD)
        self.assertIn('CrystalWisp = "Кристальный светляк"', WORLD)
        self.assertIn('CrystalWisp = {', WORLD)
        self.assertIn('biome = "CrystalGrotto"', WORLD)
        self.assertIn('"CrystalWisp", "Seed"', WORLD.split("local progress = ", 1)[1].split("local inventoryKeys", 1)[0])

    def test_crystal_wisp_adoption_consumes_seed_and_requires_echo_chamber(self):
        self.assertIn('local crystalWispNest = crystalGrotto and crystalGrotto:FindFirstChild("CrystalWispNest", true)', WORLD)
        self.assertIn('if not crystalEchoInside[player] or player:GetAttribute("CrystalEchoDiscovered") ~= true then', WORLD)
        self.assertIn('if (session.inventory.PrismSeed or 0) < 1 then', WORLD)
        self.assertIn('session.inventory.PrismSeed -= 1', WORLD)
        self.assertIn('player:SetAttribute("CrystalWisp", true)', WORLD)
        self.assertIn('player:SetAttribute("Companion", "CrystalWisp")', WORLD)

    def test_crystal_wisp_visual_is_shared_by_encounter_and_followers(self):
        self.assertIn('wispModel.Name = "CrystalWisp"', VISUALS)
        self.assertIn('wispModel.PrimaryPart = wispBody', VISUALS)
        self.assertIn('encounterModel.Name = "CrystalWispEncounter"', WORLD)
        self.assertIn('CrystalWisp = "CombatTrainingGlade"', ALBUM)
        self.assertIn('{id = "CrystalWisp", name = "Кристальный светляк"', HUD)

    def test_prism_sense_reveals_two_hidden_renewable_crystal_veins(self):
        self.assertIn('CrystalGrottoPrismVein01 = true', WORLD)
        self.assertIn('CrystalGrottoPrismVein02 = true', WORLD)
        self.assertIn('hiddenByPrismSense = true', WORLD)
        self.assertIn('resourcePrompt.Enabled = false', WORLD)
        self.assertIn('def.hiddenByPrismSense and (tonumber(player:GetAttribute("PrismSenseUntil")) or 0) < workspace:GetServerTimeNow()', WORLD)
        self.assertIn('PrismSenseOriginalTransparency', WORLD)
        self.assertIn('CrystalShard', WORLD)

    def test_prism_sense_is_server_authoritative_and_level_scaled(self):
        self.assertIn('companionId ~= "CrystalWisp"', COMBAT)
        self.assertIn('player:GetAttribute("InCrystalGrotto") ~= true', COMBAT)
        self.assertIn('local revealDuration = 16 + (companionLevel - 1) * 3', COMBAT)
        self.assertIn('player:SetAttribute("PrismSenseUntil", revealUntil)', COMBAT)
        self.assertIn('local PRISM_SENSE_COOLDOWN = 45', COMBAT)
        self.assertIn('companionXpFunction:Invoke(player, "CrystalWisp", 8)', COMBAT)
        self.assertIn('PrismSenseRevealUntil', COMBAT)
        self.assertIn('Workspace:GetServerTimeNow() + revealDuration', COMBAT)
        self.assertIn('Workspace:GetServerTimeNow()', COMBAT)

    def test_prism_sense_feedback_and_collection_description_are_connected(self):
        self.assertIn('data.companionId == "CrystalWisp"', COMBAT_CLIENT)
        self.assertIn('КРИСТАЛЬНЫЙ СВЕТЛЯК · ПРИЗМЕННОЕ ЧУТЬЁ', COMBAT_CLIENT)
        self.assertIn('Призменное чутьё: скрытые жилы на ', HUD)
        self.assertIn('local prismSenseActive = state.id == "CrystalWisp"', ANIMATION)
        self.assertIn('^OrbitCrystal', ANIMATION)

    def test_crystal_wisp_is_in_expedition_journal(self):
        self.assertIn('{key = "CrystalWisp", title = "Подружиться с кристальным светляком"', HUD)

    def test_expedition_journal_tracks_both_grotto_milestones(self):
        self.assertIn('{key = "CrystalGrottoDiscovered"', HUD)
        self.assertIn('{key = "CrystalHeart"', HUD)


if __name__ == "__main__":
    unittest.main()
