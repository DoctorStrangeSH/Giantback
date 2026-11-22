from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class ResourceCollectionContractTests(unittest.TestCase):
    def test_registry_matches_spawned_nodes(self):
        registry_section = WORLD.split("local resourceNodeIds = {", 1)[1].split("}", 1)[0]
        registry = set(re.findall(r"^\s*([A-Za-z0-9_]+)\s*=\s*true,", registry_section, re.MULTILINE))
        definitions = set(re.findall(r'^\s*key = "([^"]+)"', WORLD, re.MULTILINE))
        self.assertEqual(registry, definitions)
        self.assertIn("DuskIron01", registry)
        self.assertIn("DuskIron02", registry)

    def test_each_player_has_an_independent_cooldown(self):
        self.assertIn("session.resourceCooldowns[def.key] = nextReadyAt", WORLD)
        self.assertIn("local readyAt = session.resourceCooldowns[def.key] or 0", WORLD)
        self.assertIn("old.resourceCooldowns = savedCooldowns", WORLD)
        self.assertNotIn("state.active = false", WORLD)
        self.assertNotIn("state.model:Destroy()", WORLD)

    def test_unique_collectibles_are_permanent_per_player(self):
        self.assertIn('if def.kind == "unique" then', WORLD)
        self.assertIn("session.collectedNodes[def.key] = true", WORLD)
        self.assertIn("old.collectedNodes = savedCollected", WORLD)
        self.assertIn("for nodeId, collected in savedCollected do", WORLD)

    def test_profile_schema_and_migration_compatible_fields(self):
        self.assertIn("old.schemaVersion = 10", WORLD)
        self.assertIn("data.resourceCooldowns", WORLD)
        self.assertIn("data.collectedNodes", WORLD)

    def test_tool_level_migration_defaults_old_profiles_and_clamps_saved_values(self):
        self.assertIn('local savedLevels = type(savedTools.levels) == "table" and savedTools.levels or {}', WORLD)
        self.assertIn('Axe = math.clamp(math.floor(tonumber(savedLevels.Axe) or 1), 1, 3)', WORLD)
        self.assertIn('Pickaxe = math.clamp(math.floor(tonumber(savedLevels.Pickaxe) or 1), 1, 3)', WORLD)
        self.assertIn('savedTools.levels = toolsSnapshot.levels', WORLD)
        self.assertIn('old.schemaVersion = 10', WORLD)

    def test_workshop_upgrade_is_server_validated_and_charged_once(self):
        upgrade = WORLD.split('if action == "UpgradeTool" then', 1)[1].split('if action == "EquipTool" then', 1)[0]
        self.assertIn('session.tools[payload] ~= true', upgrade)
        self.assertIn('currentLevel >= 3', upgrade)
        self.assertIn('local nextLevel = currentLevel + 1', upgrade)
        self.assertIn('station:FindFirstChild("PromptAnchor")', upgrade)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 14', upgrade)
        self.assertIn('local cost = toolUpgradeCosts[payload][nextLevel]', upgrade)
        self.assertIn('for itemId, amount in cost do', upgrade)
        self.assertIn('session.inventory[itemId] -= amount', upgrade)
        self.assertIn('session.toolLevels[payload] = nextLevel', upgrade)

    def test_harvest_tools_have_crafted_grips_and_level_two_visual_identity(self):
        tools = WORLD.split("local function createHarvestTool(toolId, level)", 1)[1].split("local function findPlayerTool", 1)[0]
        self.assertIn('attach("GripLowerWrap"', tools)
        self.assertIn('attach("GripUpperWrap"', tools)
        self.assertIn('attach("HandleFerrule"', tools)
        self.assertIn('attach("AxeSocket"', tools)
        self.assertIn('attach("PickaxeSocket"', tools)
        self.assertIn('attach("AxeRune"', tools)
        self.assertIn('attach("PickaxeRune"', tools)
        self.assertIn("Enum.Material.Leather", tools)
        self.assertIn("Enum.Material.Neon", tools)
        self.assertIn("level >= 2", tools)

    def test_iron_sword_recipe_is_server_validated_and_saved(self):
        self.assertIn("Sword = true", WORLD)
        self.assertIn("Wood = 8, Stone = 4, IronIngot = 3", WORLD)
        craft = WORLD.split('if action == "CraftSword" then', 1)[1].split('if action == "UpgradeTool" then', 1)[0]
        self.assertIn("session.tools.Sword", craft)
        self.assertIn('session.cityModel and session.cityModel:FindFirstChild("Workshop")', craft)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 14', craft)
        self.assertIn("session.inventory[itemId] -= amount", craft)
        self.assertIn('session.equippedTool = "Sword"', craft)
        self.assertIn("savedTools.Sword = toolsSnapshot.Sword", WORLD)
        self.assertIn('player:SetAttribute("Tool_SwordOwned"', WORLD)

    def test_sword_is_a_real_tool_with_owner_checked_training_combat(self):
        sword = WORLD.split('if isSword then', 1)[1].split('return tool', 1)[0]
        self.assertIn('attach("SwordBlade"', sword)
        self.assertIn('attach("SwordGuard"', sword)
        self.assertIn("tool.Activated:Connect", sword)
        self.assertIn("humanoid:TakeDamage(20)", sword)
        self.assertIn('dummy:GetAttribute("OwnerUserId") ~= player.UserId', sword)
        self.assertIn("session.combatReadyAt = now + 0.8", sword)
        self.assertIn("humanoid.Health = humanoid.MaxHealth", sword)
        self.assertIn('(root.Position - dummyRoot.Position).Magnitude > 10', sword)

    def test_training_dummy_has_live_health_bar_and_owner_safe_raycast_combat(self):
        dummy = WORLD.split("local function createTrainingDummy(session)", 1)[1].split("local function createHarvestTool", 1)[0]
        self.assertIn('billboard.Name = "HealthDisplay"', dummy)
        self.assertIn('fill.Name = "BarFill"', dummy)
        self.assertIn("humanoid.HealthChanged:Connect(updateHealthDisplay)", dummy)
        sword = WORLD.split("if isSword then", 1)[1].split("return tool", 1)[0]
        self.assertIn("RaycastParams.new()", sword)
        self.assertIn("rayParams.FilterDescendantsInstances = {character}", sword)
        self.assertIn("workspace:Raycast(rayOrigin, rayDirection, rayParams)", sword)
        self.assertIn("hit.Instance:IsDescendantOf(dummy)", sword)
        self.assertIn('dummy:GetAttribute("OwnerUserId") ~= player.UserId', sword)
        self.assertIn("humanoid:TakeDamage(20)", sword)

    def test_hud_exposes_forge_crafting_and_training_dummy_health(self):
        tools = HUD.split("local function renderTools()", 1)[1].split("local function renderWorld()", 1)[0]
        self.assertIn("ВЫКОВАТЬ МЕЧ", tools)
        self.assertIn("CraftSword", tools)
        self.assertIn("Тренировочный манекен", tools)
        self.assertIn("payload.health", HUD)

    def test_selected_tool_is_actually_equipped_and_restored_after_respawn(self):
        sync_tools = WORLD.split("local function syncTools(player)", 1)[1].split("local function syncBridge(player)", 1)[0]
        self.assertIn("ensurePlayerTools(player, session)", sync_tools)
        self.assertIn("local selectedTool = toolIds[session.equippedTool]", sync_tools)
        self.assertIn('character:FindFirstChildOfClass("Humanoid")', sync_tools)
        self.assertIn('player:FindFirstChildOfClass("Backpack")', sync_tools)
        self.assertIn("humanoid:EquipTool(selectedTool)", sync_tools)
        self.assertIn("player.CharacterAdded:Connect(function()", WORLD)
        self.assertIn("syncTools(player)", WORLD)

    def test_equip_action_updates_selected_tool_before_sync(self):
        equip = WORLD.split('if action == "EquipTool" then', 1)[1].split('if action == "RequestResourceState" then', 1)[0]
        self.assertIn("session.equippedTool = payload", equip)
        self.assertIn("syncTools(player)", equip)
        self.assertIn("if session.tools[payload] ~= true then", equip)

    def test_server_checks_prompt_distance(self):
        self.assertIn("p.MaxActivationDistance + 1", WORLD)
        self.assertIn("(root.Position-part.Position).Magnitude", WORLD)

    def test_harvest_swing_animates_r6_and_r15_right_arm_locally(self):
        swing = CLIENT.split("local function playHarvestCharacterSwing(character, nodeId, generation)", 1)[1].split("local function playHarvestToolSwing(nodeId)", 1)[0]
        self.assertIn('character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")', swing)
        self.assertIn('descendant.Name == "RightShoulder" or descendant.Name == "Right Shoulder"', swing)
        self.assertIn('descendant.Name == "RightElbow"', swing)
        self.assertIn("RunService:BindToRenderStep", swing)
        self.assertIn("Enum.RenderPriority.Last.Value", swing)
        self.assertIn("shoulder.Transform = shoulder.Transform * pose", swing)
        self.assertIn("elbow.Transform = elbow.Transform * CFrame.Angles", swing)
        self.assertIn("RunService:UnbindFromRenderStep(bindingName)", swing)
        tool_swing = CLIENT.split("local function playHarvestToolSwing(nodeId)", 1)[1].split("local function ensureHarvestDamageOverlay", 1)[0]
        self.assertIn("playHarvestCharacterSwing(character, nodeId, generation)", tool_swing)

    def test_camera_shake_is_local_short_and_user_toggleable(self):
        shake = CLIENT.split("local function playHarvestCameraShake(intensity)", 1)[1].split("local function playHarvestCharacterSwing", 1)[0]
        self.assertIn('player:GetAttribute("HarvestCameraShakeEnabled") == false', shake)
        self.assertIn("RunService:BindToRenderStep(cameraShakeBinding", shake)
        self.assertIn("Enum.RenderPriority.Camera.Value + 1", shake)
        self.assertIn("local duration = 0.13", shake)
        self.assertIn("RunService:UnbindFromRenderStep(cameraShakeBinding)", shake)
        feedback = CLIENT.split("local function showResourceHitFeedback(payload)", 1)[1].split("local function clearResourceHitFeedback(nodeId)", 1)[0]
        self.assertIn("playHarvestCameraShake(", feedback)
        picked = CLIENT.split('elseif message == "ResourcePicked"', 1)[1].split('elseif message == "ResourceHit"', 1)[0]
        self.assertIn("playHarvestCameraShake(0.58)", picked)

    def test_harvest_camera_shake_setting_is_visible_in_tools_panel(self):
        tools = HUD.split("local function renderTools()", 1)[1].split("local function renderWorld()", 1)[0]
        self.assertIn('card(body, "HarvestFeedbackSettings"', tools)
        self.assertIn('player:GetAttribute("HarvestCameraShakeEnabled") ~= false', tools)
        self.assertIn('player:SetAttribute("HarvestCameraShakeEnabled", nextEnabled)', tools)
        self.assertIn('showToast(nextEnabled and "Вибрация камеры включена." or "Вибрация камеры отключена.")', tools)

    def test_final_harvest_hit_has_distinct_local_break_burst(self):
        burst = CLIENT.split("local function playResourceFinalBreakBurst(anchor, nodeId)", 1)[1].split("local function playResourceBreakFeedback(nodeId)", 1)[0]
        self.assertIn('ring.Name = "LocalHarvestFinalBurst"', burst)
        self.assertIn("Enum.PartType.Cylinder", burst)
        self.assertIn("Enum.Material.Neon", burst)
        self.assertIn('fragment.Name = "LocalHarvestFinalFragment"', burst)
        self.assertIn("fragment.Anchored = true", burst)
        self.assertIn("fragment.CanCollide = false", burst)
        self.assertIn("Debris:AddItem(ring, 0.42)", burst)
        self.assertIn("Debris:AddItem(fragment, 0.46)", burst)
        feedback = CLIENT.split("local function playResourceBreakFeedback(nodeId)", 1)[1].split("local function spawnHarvestChips", 1)[0]
        self.assertIn("playResourceFinalBreakBurst(anchor, nodeId)", feedback)
        picked = CLIENT.split('elseif message == "ResourcePicked"', 1)[1].split('elseif message == "ResourceHit"', 1)[0]
        self.assertIn("playResourceBreakFeedback(payload.nodeId)", picked)

    def test_harvest_hit_spawns_local_material_chips_without_server_physics(self):
        chips = CLIENT.split("local function spawnHarvestChips(anchor, nodeId)", 1)[1].split("local function showResourceHitFeedback(payload)", 1)[0]
        self.assertIn('chip.Name = "LocalHarvestChip"', chips)
        self.assertIn("Enum.Material.Wood", chips)
        self.assertIn("Enum.Material.Slate", chips)
        self.assertIn("chip.Anchored = true", chips)
        self.assertIn("chip.CanCollide = false", chips)
        self.assertIn("chip.Parent = workspace", chips)
        self.assertIn("Debris:AddItem(chip, 0.5)", chips)
        feedback = CLIENT.split("local function showResourceHitFeedback(payload)", 1)[1].split("local function clearResourceHitFeedback(nodeId)", 1)[0]
        self.assertIn("spawnHarvestChips(anchor, nodeId)", feedback)

    def test_client_hides_only_its_local_resource_copy(self):
        self.assertIn("LocalTransparencyModifier = visible and 0 or 1", CLIENT)
        self.assertIn("descendant.Enabled = visible", CLIENT)
        self.assertIn('"ResourceState"', CLIENT)
        self.assertIn('"ResourcePicked"', CLIENT)
        self.assertIn('event:FireServer("RequestResourceState")', CLIENT)

    def test_tool_levels_persist_through_schema_nine_and_allow_level_three(self):
        self.assertIn("old.schemaVersion = 10", WORLD)
        self.assertIn("Axe = math.clamp(math.floor(tonumber(session.toolLevels.Axe) or 1), 1, 3)", WORLD)
        self.assertIn("Pickaxe = math.clamp(math.floor(tonumber(session.toolLevels.Pickaxe) or 1), 1, 3)", WORLD)
        self.assertIn("Axe = math.clamp(math.floor(tonumber(savedLevels.Axe) or 1), 1, 3)", WORLD)
        self.assertIn("Pickaxe = math.clamp(math.floor(tonumber(savedLevels.Pickaxe) or 1), 1, 3)", WORLD)

    def test_tier_three_requires_iron_ingots_and_consumes_recipe_server_side(self):
        self.assertIn("[3] = {Wood = 12, Stone = 10, IronIngot = 2}", WORLD)
        self.assertIn("[3] = {Wood = 10, Stone = 12, IronIngot = 2}", WORLD)
        upgrade = WORLD.split('if action == "UpgradeTool" then', 1)[1].split('if action == "EquipTool" then', 1)[0]
        self.assertIn("local nextLevel = currentLevel + 1", upgrade)
        self.assertIn("local cost = toolUpgradeCosts[payload][nextLevel]", upgrade)
        self.assertIn("for itemId, amount in cost do", upgrade)
        self.assertIn("session.inventory[itemId] -= amount", upgrade)
        self.assertIn("session.toolLevels[payload] = nextLevel", upgrade)
        self.assertIn("if currentLevel >= 3 then", upgrade)

    def test_tier_three_tool_visuals_and_harvest_speed_scale(self):
        builder = WORLD.split("local function createHarvestTool(toolId, level)", 1)[1].split("local function findPlayerTool", 1)[0]
        self.assertIn("1, 3", builder)
        self.assertIn('attach("AxeCrystal"', builder)
        self.assertIn('attach("PickaxeCrystal"', builder)
        self.assertIn("Color3.fromRGB(113, 245, 221)", builder)
        harvest = WORLD.split('local hitsRequired = math.clamp', 1)[1].split('if hitsRequired > 1 then', 1)[0]
        self.assertIn("hitsRequired - (toolLevel - 1)", harvest)

    def test_hud_displays_tier_three_cost_and_maximum_level(self):
        tools = HUD.split("local function renderTools()", 1)[1].split("local function renderWorld()", 1)[0]
        self.assertIn("Кристальный", tools)
        self.assertIn("МАКС. УРОВЕНЬ", tools)
        self.assertIn("IronIngot", WORLD)
        self.assertIn("слитки ×2", tools)

    def test_smelter_is_persisted_in_island_buildings_and_offline_timer_is_absolute(self):
        self.assertIn('smelter = {readyAt = 0}', WORLD)
        self.assertIn('city.buildings.smelter = {', WORLD)
        self.assertIn('readyAt = safeTimestamp(rawSmelter.readyAt)', WORLD)
        self.assertIn('savedIsland.buildings.smelter = {', WORLD)
        self.assertIn('readyAt = safeTimestamp(citySnapshot.buildings.smelter.readyAt)', WORLD)
        self.assertIn('smelter.readyAt = os.time() + 120', WORLD)
        self.assertIn('if os.time() < smelter.readyAt then', WORLD)

    def test_smelting_recipe_is_server_validated_and_consumes_materials_once(self):
        start = WORLD.split('local function startSmelting(player)', 1)[1].split('local function collectSmelting(player)', 1)[0]
        self.assertIn('local oreCost, woodCost = 3, 2', start)
        self.assertIn('session.inventory.IronOre -= oreCost', start)
        self.assertIn('session.inventory.Wood -= woodCost', start)
        self.assertIn('smelter.readyAt = os.time() + 120', start)
        self.assertIn('if smelter.readyAt > os.time()', start)
        collect = WORLD.split('local function collectSmelting(player)', 1)[1].split('local function collectFoxCache', 1)[0]
        self.assertIn('session.inventory.IronIngot = (session.inventory.IronIngot or 0) + 1', collect)
        self.assertIn('smelter.readyAt = 0', collect)
        self.assertIn('if os.time() < smelter.readyAt then', collect)
        self.assertIn('if not root or not anchor or (root.Position - anchor.Position).Magnitude > 14 then', collect)
        self.assertIn('if not root or not anchor or (root.Position - anchor.Position).Magnitude > 14 then', start)

    def test_personal_furnace_is_created_and_owner_only_prompt_opens_smelter(self):
        self.assertIn('furnace.Name = "Smelter"', WORLD)
        self.assertIn('furnace:SetAttribute("OwnerUserId", ownerUserId)', WORLD)
        self.assertIn('prompt(furnaceAnchor, "Плавильня", "Плавить железо"', WORLD)
        self.assertIn('event:FireClient(visitor, "OpenSmelter")', WORLD)
        self.assertIn('visitor.UserId ~= ownerUserId', WORLD)

    def test_smelter_ui_shows_recipe_state_and_calls_server_actions(self):
        self.assertIn('player:GetAttribute("Resource_IronIngot")', HUD)
        self.assertIn('player:GetAttribute("Smelter_ReadyAt")', HUD)
        self.assertIn('event:FireServer("StartSmelting")', HUD)
        self.assertIn('event:FireServer("CollectSmelting")', HUD)
        self.assertIn('OpenSmelter', HUD)
        self.assertIn('выйдешь из игры', HUD)

    def test_iron_ore_is_a_persistent_pickaxe_resource_with_distinct_visual(self):
        self.assertIn('"IronOre"', WORLD.split("local inventoryKeys =", 1)[1].split("\n", 1)[0])
        self.assertIn("DuskIron01 = true", WORLD)
        self.assertIn("DuskIron02 = true", WORLD)
        self.assertEqual(WORLD.count('itemId = "IronOre"'), 2)
        self.assertEqual(WORLD.count('visual = "ironOre"'), 2)
        self.assertIn('verb = "Добыть железную руду"', WORLD)
        self.assertIn('hitsRequired = 5', WORLD)
        self.assertIn('respawnSeconds = 420', WORLD)
        self.assertIn('makePart("IronVeinA"', WORLD)
        self.assertIn('makePart("IronVeinB"', WORLD)
        self.assertIn('makePart("IronVeinC"', WORLD)
        self.assertIn('glow.Parent = glint', WORLD)
        self.assertIn('player:GetAttribute("Resource_IronOre")', HUD)
        self.assertIn("Новая находка: железная руда", HUD)
        self.assertIn("железной жиле", HUD)

    def test_renewable_nodes_have_explicit_personal_cooldowns(self):
        self.assertEqual(WORLD.count('kind = "renewable"'), 10)
        self.assertEqual(WORLD.count("respawnSeconds = 300"), 8)
        self.assertEqual(WORLD.count("respawnSeconds = 420"), 2)

    def test_remote_handshake_is_registered_before_player_initialization(self):
        self.assertLess(WORLD.index("event.OnServerEvent:Connect"), WORLD.index("Players.PlayerAdded:Connect(init)"))

    def test_concurrent_saves_are_serialized(self):
        self.assertIn("session.saveAgain = true", WORLD)
        self.assertIn("repeat task.wait() until not session.saving", WORLD)


if __name__ == "__main__":
    unittest.main()
