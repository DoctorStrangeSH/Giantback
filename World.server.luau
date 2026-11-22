local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local storeName = RunService:IsStudio() and "GiantbackAlbum_Studio_v1" or "GiantbackAlbum_v1"
local storeOk, storeResult = pcall(function()
    return DataStoreService:GetDataStore(storeName)
end)
local store = storeOk and storeResult or nil
if not store then
    warn("Giantback profile storage is unavailable; this session will not be saved.")
end
local event = Instance.new("RemoteEvent")
event.Name = "AlbumAction"
event.Parent = Storage
local homeIslandTemplate = ServerStorage:WaitForChild("HomeIslandTemplate")
local homeIslandFolder = workspace:FindFirstChild("PlayerIslands")
if not homeIslandFolder then
    homeIslandFolder = Instance.new("Folder")
    homeIslandFolder.Name = "PlayerIslands"
    homeIslandFolder.Parent = workspace
end
local HOME_ISLAND_SLOT_COUNT = 8
local HOME_ISLAND_RADIUS = 240
local HOME_WORLD_CENTER = Vector3.new(0, 0, -40)
local occupiedHomeSlots = {}
if not Storage:WaitForChild("GiantbackVisualsReady", 12) then
    warn("Giantback visual layer did not finish in time; continuing with base models.")
end
local pets = {Fox = "Лисёнок-корешок", Moth = "Лунная моль"}
local progress = {"Fox", "Moth", "Seed", "MoonBloom", "MoonGateTrace", "MoonGateOpen", "MoonRelic", "Flower", "Timber", "Lantern", "Lit"}
local inventoryKeys = {"SunPetal", "MoonPetal", "CarrotSeed", "Carrot", "StrawberrySeed", "Strawberry", "PumpkinSeed", "Pumpkin", "CabbageSeed", "Cabbage", "Wood", "Stone", "IronOre", "IronIngot", "MoonSeed", "StarShard", "RootvaultKey", "RootvaultEssence", "RootvaultSigil"}
local toolIds = {Axe = true, Pickaxe = true}
local combatRewardDefinitions = {
    GroveGrunt01 = {itemId = "Wood", amount = 3},
    GroveScout02 = {itemId = "SunPetal", amount = 2},
    GroveTrialChest01 = {itemId = "StarShard", amount = 1},
    RootvaultChest01 = {itemId = "IronOre", amount = 3},
    RootvaultSentinel01 = {itemId = "RootvaultKey", amount = 1},
    RootvaultStalker01 = {itemId = "RootvaultEssence", amount = 1},
    RootvaultSealKeeper01 = {itemId = "RootvaultSigil", amount = 1},
}
local toolUpgradeCosts = {Axe = {Wood = 8, Stone = 6}, Pickaxe = {Wood = 6, Stone = 8}}
local foxCacheIds = {"FoxCache01", "FoxCache02", "FoxCache03"}
local foxCacheIdSet = {}
for _, cacheId in foxCacheIds do
    foxCacheIdSet[cacheId] = true
end
local FOX_SCOUT_COOLDOWN_SECONDS = 120

local function foxScoutCooldownForLevel(level)
    level = math.clamp(math.floor(tonumber(level) or 1), 1, 5)
    if level >= 5 then return 60 end
    if level >= 3 then return 90 end
    return FOX_SCOUT_COOLDOWN_SECONDS
end
local foxCacheRewards = {
    FoxCache01 = {itemId = "SunPetal", amount = 2},
    FoxCache02 = {itemId = "Wood", amount = 2},
    FoxCache03 = {itemId = "CarrotSeed", amount = 1},
}
local farmPlotIds = {"Plot01", "Plot02", "Plot03", "Plot04"}
local cropDefinitions = {
    Carrot = {seedItemId = "CarrotSeed", harvestItemId = "Carrot", growthSeconds = 300, reward = 1, displayName = "Морковь"},
    Strawberry = {seedItemId = "StrawberrySeed", harvestItemId = "Strawberry", growthSeconds = 720, regrowSeconds = 480, reward = 2, displayName = "Клубника"},
    Pumpkin = {seedItemId = "PumpkinSeed", harvestItemId = "Pumpkin", growthSeconds = 1800, reward = 1, displayName = "Тыква"},
    Cabbage = {seedItemId = "CabbageSeed", harvestItemId = "Cabbage", growthSeconds = 1200, reward = 1, displayName = "Капуста"},
}
local defaultCropId = "Carrot"
local function isValidCropId(cropId)
    return type(cropId) == "string" and cropDefinitions[cropId] ~= nil
end
local resourceNodeIds = {
    GroveSunPetal01 = true,
    GroveSunPetal02 = true,
    DuskMoonPetal01 = true,
    DuskMoonPetal02 = true,
    GroveWood01 = true,
    GroveWood02 = true,
    DuskStone01 = true,
    DuskStone02 = true,
    DuskIron01 = true,
    DuskIron02 = true,
}
local sessions = {}
local createPersonalCity
local applyHomeBridgeState

local function homeSlotCFrame(slotIndex)
    local angle = math.pi * 2 * (slotIndex - 1) / HOME_ISLAND_SLOT_COUNT
    local position = Vector3.new(
        math.sin(angle) * HOME_ISLAND_RADIUS,
        0,
        HOME_WORLD_CENTER.Z - math.cos(angle) * HOME_ISLAND_RADIUS
    )
    return CFrame.new(position) * CFrame.Angles(0, math.pi - angle, 0)
end

local function allocateHomeIsland(player, session)
    for slotIndex = 1, HOME_ISLAND_SLOT_COUNT do
        if occupiedHomeSlots[slotIndex] == nil then
            occupiedHomeSlots[slotIndex] = player.UserId
            local island = homeIslandTemplate:Clone()
            island.Name = "HomeIsland_" .. tostring(player.UserId)
            island:SetAttribute("OwnerUserId", player.UserId)
            island:SetAttribute("OwnerName", player.DisplayName)
            island:SetAttribute("HomeIslandSlot", slotIndex)

            local pivot = island:FindFirstChild("IslandPivot")
            if pivot and pivot:IsA("BasePart") then
                island.PrimaryPart = pivot
            end
            island.Parent = homeIslandFolder
            island:PivotTo(homeSlotCFrame(slotIndex))
            applyHomeBridgeState(slotIndex, session.city.bridges.homeToGrove == true)

            local homeSpawn = island:FindFirstChild("HomeSpawn")
            if not homeSpawn or not homeSpawn:IsA("SpawnLocation") then
                island:Destroy()
                occupiedHomeSlots[slotIndex] = nil
                warn("Home island template is missing its HomeSpawn SpawnLocation.")
                return false
            end

            session.homeIsland = island
            session.homeSpawn = homeSpawn
            session.homeSlot = slotIndex
            player:SetAttribute("HomeIslandSlot", slotIndex)
            player.RespawnLocation = homeSpawn
            return true
        end
    end
    return false
end

local function tip(player, message)
    event:FireClient(player, message)
end

local function defaultCity()
    local plots = {}
    for _, plotId in farmPlotIds do
        plots[plotId] = {
            cropId = "",
            plantedAt = 0,
            readyAt = 0,
        }
    end
    return {
        level = 1,
        farm = {
            level = 1,
            selectedCropId = defaultCropId,
            plots = plots,
        },
        bridges = {
            homeToGrove = false,
        },
        buildings = {},
    }
end

local function safeTimestamp(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then
        return 0
    end
    return math.clamp(math.floor(number), 0, 4102444800)
end

local function isFarmPlotUnlocked(farm, plotId)
    if plotId == "Plot01" then return true end
    if plotId == "Plot02" or plotId == "Plot03" then
        return farm.level >= 2
    end
    if plotId == "Plot04" then
        return farm.level >= 3
    end
    return false
end

local function normalizeCity(raw)
    local city = defaultCity()
    if type(raw) ~= "table" then return city end

    city.level = math.clamp(math.floor(tonumber(raw.level) or 1), 1, 5)
    local rawBridges = type(raw.bridges) == "table" and raw.bridges or {}
    city.bridges.homeToGrove = rawBridges.homeToGrove == true
    local rawFarm = type(raw.farm) == "table" and raw.farm or {}
    city.farm.level = math.clamp(math.floor(tonumber(rawFarm.level) or 1), 1, 3)
    city.farm.selectedCropId = isValidCropId(rawFarm.selectedCropId) and rawFarm.selectedCropId or defaultCropId
    local rawPlots = type(rawFarm.plots) == "table" and rawFarm.plots or {}

    for _, plotId in farmPlotIds do
        local saved = type(rawPlots[plotId]) == "table" and rawPlots[plotId] or {}
        local cropId = saved.cropId
        local plantedAt = safeTimestamp(saved.plantedAt)
        local readyAt = safeTimestamp(saved.readyAt)

        if isValidCropId(cropId)
            and isFarmPlotUnlocked(city.farm, plotId)
            and plantedAt > 0
            and readyAt >= plantedAt then
            city.farm.plots[plotId] = {
                cropId = cropId,
                plantedAt = plantedAt,
                readyAt = readyAt,
            }
        end
    end

    return city
end

local function syncFarm(player)
    local session = sessions[player]
    if not session or not session.city then return end

    player:SetAttribute("City_Level", session.city.level)
    player:SetAttribute("Farm_Level", session.city.farm.level)
    player:SetAttribute("Farm_SelectedCrop", session.selectedCropId or defaultCropId)
    for _, plotId in farmPlotIds do
        local plot = session.city.farm.plots[plotId]
        player:SetAttribute("Farm_" .. plotId .. "_Unlocked", isFarmPlotUnlocked(session.city.farm, plotId))
        player:SetAttribute("Farm_" .. plotId .. "_CropId", plot.cropId or "")
        player:SetAttribute("Farm_" .. plotId .. "_ReadyAt", plot.readyAt or 0)
    end
end


local function syncInventory(player)
    local session = sessions[player]
    for _, key in inventoryKeys do
        local amount = session and session.inventory and session.inventory[key] or 0
        player:SetAttribute("Resource_" .. key, amount)
    end
    player:SetAttribute("Smelter_ReadyAt", session and session.smeltingReadyAt or 0)
    player:SetAttribute("Smelter_Pending", session and session.smeltingAmount or 0)
end

local save

local COMPANION_IDS = {"Fox", "Moth"}
local COMPANION_MAX_LEVEL = 5

local function companionXpToNext(level)
    return 100 + math.max(0, level - 1) * 75
end

local function normalizeCompanionProgress(raw)
    raw = type(raw) == "table" and raw or {}
    local result = {}
    for _, id in COMPANION_IDS do
        local saved = type(raw[id]) == "table" and raw[id] or {}
        local level = math.clamp(math.floor(tonumber(saved.level) or 1), 1, COMPANION_MAX_LEVEL)
        local xp = math.max(0, math.floor(tonumber(saved.xp) or 0))
        if level >= COMPANION_MAX_LEVEL then
            xp = 0
        else
            local needed = companionXpToNext(level)
            while xp >= needed and level < COMPANION_MAX_LEVEL do
                xp -= needed
                level += 1
                needed = companionXpToNext(level)
            end
        end
        local bond = math.clamp(math.floor(tonumber(saved.bond) or 0), 0, 1000)
        result[id] = {level = level, xp = level >= COMPANION_MAX_LEVEL and 0 or xp, bond = bond}
    end
    return result
end

local companionMoodDefaults = {
    Fox = "Любопытство",
    Moth = "Спокойствие",
}

local function setCompanionMood(player, companionId, mood)
    local session = sessions[player]
    if not session or (companionId ~= "Fox" and companionId ~= "Moth") then return end
    session.companionMood = session.companionMood or {}
    session.companionMood[companionId] = mood
    player:SetAttribute("Companion_" .. companionId .. "_Mood", mood)
end

local function syncCompanionProgress(player)
    local session = sessions[player]
    if not session then return end
    for _, id in COMPANION_IDS do
        local progressData = session.companionProgress[id]
        player:SetAttribute("Companion_" .. id .. "_Level", progressData.level)
        player:SetAttribute("Companion_" .. id .. "_XP", progressData.xp)
        player:SetAttribute("Companion_" .. id .. "_XPToNext",
            progressData.level >= COMPANION_MAX_LEVEL and 0 or companionXpToNext(progressData.level))
        player:SetAttribute("Companion_" .. id .. "_Bond", progressData.bond)
        local bondRank = progressData.bond >= 900 and "Родственные души"
            or progressData.bond >= 600 and "Лучшие друзья"
            or progressData.bond >= 300 and "Друзья"
            or progressData.bond >= 100 and "Знакомцы"
            or "Знакомство"
        player:SetAttribute("Companion_" .. id .. "_BondRank", bondRank)
        local mood = session.companionMood and session.companionMood[id] or companionMoodDefaults[id]
        player:SetAttribute("Companion_" .. id .. "_Mood", mood)
    end
end

local function awardCompanionXp(player, companionId, amount)
    if companionId ~= "Fox" and companionId ~= "Moth" then return false, "InvalidCompanion" end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") or player:GetAttribute(companionId) ~= true then
        return false, "CompanionNotOwned"
    end
    amount = math.clamp(math.floor(tonumber(amount) or 0), 0, 100)
    if amount <= 0 then return false, "InvalidAmount" end

    local progressData = session.companionProgress[companionId]
    if progressData.level >= COMPANION_MAX_LEVEL then
        return false, "MaxLevel"
    end

    progressData.xp += amount
    local levelsGained = 0
    while progressData.level < COMPANION_MAX_LEVEL do
        local needed = companionXpToNext(progressData.level)
        if progressData.xp < needed then break end
        progressData.xp -= needed
        progressData.level += 1
        levelsGained += 1
    end
    if progressData.level >= COMPANION_MAX_LEVEL then progressData.xp = 0 end

    syncCompanionProgress(player)
    if session.online and not save(player) then
        warn("Companion progression save will be retried:", player.UserId, companionId)
    end
    if levelsGained > 0 then
        tip(player, pets[companionId] .. " вырос до уровня " .. tostring(progressData.level) .. "!")
    end
    return true, {level = progressData.level, xp = progressData.xp, levelsGained = levelsGained}
end

local companionFeedFoods = {
    Pumpkin = {bond = 25, name = "тыкву"},
    Strawberry = {bond = 20, name = "клубнику"},
    Cabbage = {bond = 18, name = "капусту"},
    Carrot = {bond = 15, name = "морковь"},
}
local companionFeedOrder = {"Pumpkin", "Strawberry", "Cabbage", "Carrot"}

local companionPlaySymbols = {"🐾", "🍃", "✨"}
local companionPlayCooldownSeconds = 25

local function finishCompanionPlay(player, success, reason)
    local session = sessions[player]
    if not session then return end
    local challenge = session.companionPlay
    session.companionPlay = nil
    if not challenge then return end

    if not success then
        event:FireClient(player, "CompanionPlayFinished", {
            success = false,
            message = reason or "Ничего страшного! Попробуй ещё раз, когда питомец снова захочет играть.",
        })
        return
    end

    local progressData = session.companionProgress[challenge.companionId]
    progressData.bond = math.clamp((progressData.bond or 0) + 15, 0, 1000)
    setCompanionMood(player, challenge.companionId, "Радость")
    syncCompanionProgress(player)
    local xpGranted = awardCompanionXp(player, challenge.companionId, 8)
    if not xpGranted and session.online then
        save(player)
    end
    event:FireClient(player, "CompanionPlayFinished", {
        success = true,
        message = pets[challenge.companionId] .. " отлично поиграл с тобой! Дружба +15.",
    })
end

local function startCompanionPlay(player, companionId)
    if companionId ~= "Fox" and companionId ~= "Moth" then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") or player:GetAttribute(companionId) ~= true then return end
    if player:GetAttribute("Companion") ~= companionId then
        return tip(player, "Сначала позови питомца, с которым хочешь поиграть.")
    end
    if session.companionPlay then
        return tip(player, "Вы уже играете! Повтори последовательность.")
    end

    session.companionPlayReadyAt = session.companionPlayReadyAt or {}
    local now = os.clock()
    local readyAt = session.companionPlayReadyAt[companionId] or 0
    if now < readyAt then
        return tip(player, "Питомцу нужен небольшой отдых перед следующей игрой.")
    end

    local bond = session.companionProgress[companionId].bond or 0
    local length = bond >= 600 and 4 or 3
    local sequence = {}
    for index = 1, length do
        sequence[index] = math.random(1, #companionPlaySymbols)
    end

    local token = HttpService:GenerateGUID(false)
    session.companionPlay = {
        token = token,
        companionId = companionId,
        sequence = sequence,
        nextIndex = 1,
        startedAt = now,
        expiresAt = now + 18,
    }
    session.companionPlayReadyAt[companionId] = now + companionPlayCooldownSeconds
    event:FireClient(player, "CompanionPlayStarted", {
        token = token,
        companionId = companionId,
        sequence = sequence,
        symbols = companionPlaySymbols,
    })
    task.delay(18, function()
        local currentSession = sessions[player]
        if currentSession and currentSession.companionPlay and currentSession.companionPlay.token == token then
            finishCompanionPlay(player, false, "Игра закончилась по времени. Питомец будет рад сыграть с тобой позже!")
        end
    end)
end

local function submitCompanionPlayInput(player, payload)
    local session = sessions[player]
    local challenge = session and session.companionPlay
    if not challenge or type(payload) ~= "table" then return end
    if payload.token ~= challenge.token then return end
    if os.clock() > challenge.expiresAt then
        return finishCompanionPlay(player, false, "Время игры вышло. Питомец всё равно рад, что ты попробовал!")
    end

    local index = tonumber(payload.index)
    local symbol = tonumber(payload.symbol)
    if not index or not symbol or index ~= challenge.nextIndex
        or symbol ~= challenge.sequence[challenge.nextIndex] then
        return finishCompanionPlay(player, false, "Ой! Последовательность сбилась. Ничего страшного — сыграем ещё!")
    end

    challenge.nextIndex += 1
    if challenge.nextIndex > #challenge.sequence then
        if os.clock() - challenge.startedAt < 1.1 then
            return finishCompanionPlay(player, false, "Как быстро! Давай сыграем ещё раз и не спеша.")
        end
        finishCompanionPlay(player, true)
    end
end

local function petCompanion(player, companionId)
    if companionId ~= "Fox" and companionId ~= "Moth" then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") or player:GetAttribute(companionId) ~= true then return end
    if player:GetAttribute("Companion") ~= companionId then
        return tip(player, "Сначала позови питомца, которого хочешь погладить.")
    end

    session.companionPetReadyAt = session.companionPetReadyAt or {}
    local now = os.clock()
    local readyAt = session.companionPetReadyAt[companionId] or 0
    if now < readyAt then
        return tip(player, "Питомец уже получил ласку. Побудь рядом ещё немного!")
    end

    session.companionPetReadyAt[companionId] = now + 18
    local progressData = session.companionProgress[companionId]
    progressData.bond = math.clamp((progressData.bond or 0) + 5, 0, 1000)
    setCompanionMood(player, companionId, "Радость")
    syncCompanionProgress(player)
    event:FireClient(player, "CompanionPetted", {companionId = companionId})
    tip(player, pets[companionId] .. " довольно прижался к тебе. Дружба +5.")
    if session.online and not save(player) then
        warn("Companion petting save will be retried:", player.UserId, companionId)
    end
end

local function feedCompanion(player, companionId)
    if companionId ~= "Fox" and companionId ~= "Moth" then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") or player:GetAttribute(companionId) ~= true then return end
    if player:GetAttribute("Companion") ~= companionId then
        return tip(player, "Сначала позови питомца, которого хочешь угостить.")
    end

    local now = os.clock()
    session.companionFeedReadyAt = session.companionFeedReadyAt or {}
    local readyAt = session.companionFeedReadyAt[companionId] or 0
    if now < readyAt then
        return tip(player, "Питомец ещё наслаждается угощением. Попробуй чуть позже!")
    end

    local foodId
    for _, candidate in companionFeedOrder do
        if (session.inventory[candidate] or 0) > 0 then
            foodId = candidate
            break
        end
    end
    if not foodId then
        return tip(player, "В рюкзаке пока нет урожая. Вырасти морковь, клубнику, капусту или тыкву!")
    end

    local food = companionFeedFoods[foodId]
    session.inventory[foodId] -= 1
    local progressData = session.companionProgress[companionId]
    progressData.bond = math.clamp((progressData.bond or 0) + food.bond, 0, 1000)
    setCompanionMood(player, companionId, "Довольство")
    session.companionFeedReadyAt[companionId] = now + 8
    syncInventory(player)
    syncCompanionProgress(player)
    tip(player, pets[companionId] .. " с радостью съел " .. food.name .. "! Дружба +" .. tostring(food.bond) .. ".")
    if session.online and not save(player) then
        warn("Companion feeding save will be retried:", player.UserId, companionId)
    end
end

local companionXpFunction = ServerStorage:FindFirstChild("GiantbackGrantCompanionXP")
if companionXpFunction and not companionXpFunction:IsA("BindableFunction") then
    companionXpFunction:Destroy()
    companionXpFunction = nil
end
if not companionXpFunction then
    companionXpFunction = Instance.new("BindableFunction")
    companionXpFunction.Name = "GiantbackGrantCompanionXP"
    companionXpFunction.Parent = ServerStorage
end
companionXpFunction.OnInvoke = function(player, companionId, amount)
    return awardCompanionXp(player, companionId, amount)
end

local function createToolPart(parent, name, size, offset, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CFrame = offset
    part.Parent = parent
    return part
end

local function createHarvestTool(toolId, level)
    level = math.clamp(math.floor(tonumber(level) or 1), 1, 2)
    local tool = Instance.new("Tool")
    tool.Name = toolId == "Axe" and "Топор путешественника" or "Кирка путешественника"
    tool.ToolTip = level >= 2 and "Усиленный инструмент: добыча быстрее" or (toolId == "Axe" and "Нужен для добычи дерева" or "Нужна для добычи камня")
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("PetKingdomsToolId", toolId)
    tool:SetAttribute("PetKingdomsToolLevel", level)

    local handle = createToolPart(tool, "Handle", Vector3.new(0.28, 0.28, 2.5), CFrame.new(), Color3.fromRGB(132, 91, 57), Enum.Material.Wood, Enum.PartType.Cylinder)
    handle.CFrame = CFrame.new() * CFrame.Angles(0, 0, math.rad(90))

    if toolId == "Axe" then
        local blade = createToolPart(tool, "AxeHead", Vector3.new(0.32, 1.0, 0.9), CFrame.new(0, 0.85, -0.05), level >= 2 and Color3.fromRGB(218, 169, 83) or Color3.fromRGB(178, 190, 190), Enum.Material.Metal)
        local edge = createToolPart(tool, "AxeEdge", Vector3.new(0.12, 0.82, 0.72), CFrame.new(0, 0.87, -0.52), level >= 2 and Color3.fromRGB(255, 218, 132) or Color3.fromRGB(220, 225, 216), Enum.Material.Metal)
        for _, part in {blade, edge} do
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = part
            weld.Parent = handle
        end
    else
        local head = createToolPart(tool, "PickaxeHead", Vector3.new(0.28, 0.32, 1.75), CFrame.new(0, 1.05, 0), level >= 2 and Color3.fromRGB(218, 169, 83) or Color3.fromRGB(166, 181, 184), Enum.Material.Metal)
        local tipLeft = createToolPart(tool, "PickaxeTipLeft", Vector3.new(0.24, 0.28, 0.42), CFrame.new(0, 1.05, -1.0), level >= 2 and Color3.fromRGB(255, 218, 132) or Color3.fromRGB(205, 211, 205), Enum.Material.Metal)
        local tipRight = createToolPart(tool, "PickaxeTipRight", Vector3.new(0.24, 0.28, 0.42), CFrame.new(0, 1.05, 1.0), level >= 2 and Color3.fromRGB(255, 218, 132) or Color3.fromRGB(205, 211, 205), Enum.Material.Metal)
        for _, part in {head, tipLeft, tipRight} do
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = part
            weld.Parent = handle
        end
    end

    tool.Grip = CFrame.new(0, -0.8, -0.45) * CFrame.Angles(math.rad(-90), 0, math.rad(90))
    tool.Equipped:Connect(function()
        local character = tool.Parent
        local player = Players:GetPlayerFromCharacter(character)
        local session = player and sessions[player]
        if not player or not session or session.tools[toolId] ~= true or not player:GetAttribute("Ready") then return end
        session.equippedTool = toolId
        player:SetAttribute("Tool_Equipped", toolId)
    end)
    return tool
end

local function findPlayerTool(player, toolId)
    local toolName = toolId == "Axe" and "Топор путешественника" or "Кирка путешественника"
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end

local function ensurePlayerTools(player, session)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    for toolId, owned in session.tools do
        if owned == true then
            local level = session.toolLevels[toolId] or 1
            local current = findPlayerTool(player, toolId)
            if current and current:GetAttribute("PetKingdomsToolLevel") ~= level then
                current:Destroy()
                current = nil
            end
            if not current then
                createHarvestTool(toolId, level).Parent = backpack
            end
        end
    end
    local equipped = findPlayerTool(player, session.equippedTool)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if equipped and humanoid and equipped.Parent ~= player.Character then
        humanoid:EquipTool(equipped)
    end
end

local function syncTools(player)
    local session = sessions[player]
    local tools = session and session.tools or {}
    player:SetAttribute("Tool_AxeOwned", tools.Axe == true)
    player:SetAttribute("Tool_PickaxeOwned", tools.Pickaxe == true)
    player:SetAttribute("Tool_Equipped", session and session.equippedTool or "")
    player:SetAttribute("Tool_AxeLevel", session and session.toolLevels.Axe or 1)
    player:SetAttribute("Tool_PickaxeLevel", session and session.toolLevels.Pickaxe or 1)
    if session and player:GetAttribute("Ready") then
        ensurePlayerTools(player, session)
    end
end

local function syncBridge(player)
    local session = sessions[player]
    player:SetAttribute("Bridge_HomeToGrove", session ~= nil and session.city.bridges.homeToGrove == true)
end

local function syncFoxScout(player)
    local session = sessions[player]
    player:SetAttribute("FoxCacheSpot", session and session.foxCacheActiveId or "")
    player:SetAttribute("FoxSearchReadyAt", session and session.foxSearchReadyAt or 0)
    player:SetAttribute("FoxSearchCount", session and session.foxSearchCount or 0)
end

applyHomeBridgeState = function(slotIndex, built)
    local bridgeRoot = workspace:FindFirstChild("BridgeToGrove")
    local bridge = bridgeRoot and bridgeRoot:FindFirstChild(string.format("HomeBridge%02d", slotIndex))
    if not bridge then return false end

    for _, item in bridge:GetDescendants() do
        if item:IsA("BasePart") then
            item.Transparency = built and 0 or 0.62
            item.CanCollide = built
            item.CanTouch = built
            item.CanQuery = built
            if item.Name == "BridgeLamp" then
                local light = item:FindFirstChildOfClass("PointLight")
                if light then light.Brightness = built and 0.7 or 0.08 end
            end
        end
    end
    return true
end

save = function(player)
    local session = sessions[player]
    if not session or not session.online or not store then return false end
    if session.saving then
        session.saveAgain = true
        repeat task.wait() until not session.saving
        return session.lastSaveOk == true
    end

    session.saving = true
    local allOk = true
    repeat
        session.saveAgain = false
        local snapshot = {}
        for _, key in progress do snapshot[key] = player:GetAttribute(key) == true end

        local inventorySnapshot = {}
        for _, key in inventoryKeys do
            inventorySnapshot[key] = math.max(0, math.floor(tonumber(session.inventory[key]) or 0))
        end

        local cooldownSnapshot = {}
        for nodeId, readyAt in session.resourceCooldowns do
            if resourceNodeIds[nodeId] then
                cooldownSnapshot[nodeId] = math.max(0, math.floor(tonumber(readyAt) or 0))
            end
        end

        local collectedSnapshot = {}
        for nodeId, collected in session.collectedNodes do
            if resourceNodeIds[nodeId] and collected == true then
                collectedSnapshot[nodeId] = true
            end
        end

        local homeMaterialCooldownSnapshot = {}
        for materialId, readyAt in session.homeMaterialCooldowns do
            if materialId == "Wood" or materialId == "Stone" then
                homeMaterialCooldownSnapshot[materialId] = math.max(0, math.floor(tonumber(readyAt) or 0))
            end
        end

        local smeltingSnapshot = {
            readyAt = math.max(0, math.floor(tonumber(session.smeltingReadyAt) or 0)),
            amount = math.clamp(math.floor(tonumber(session.smeltingAmount) or 0), 0, 10),
        }
        local toolsSnapshot = {
            Axe = session.tools.Axe == true,
            Pickaxe = session.tools.Pickaxe == true,
            equipped = toolIds[session.equippedTool] and session.equippedTool or "Axe",
            levels = {
                Axe = math.clamp(math.floor(tonumber(session.toolLevels.Axe) or 1), 1, 2),
                Pickaxe = math.clamp(math.floor(tonumber(session.toolLevels.Pickaxe) or 1), 1, 2),
            },
        }
        local citySnapshot = normalizeCity(session.city)
        local foxScoutSnapshot = {
            activeCacheId = foxCacheIdSet[session.foxCacheActiveId] and session.foxCacheActiveId or nil,
            readyAt = math.max(0, math.floor(tonumber(session.foxSearchReadyAt) or 0)),
            searchCount = math.max(0, math.floor(tonumber(session.foxSearchCount) or 0)),
        }
        local completedCombatSnapshot = {}
        for encounterId, completed in session.completedCombatEncounters do
            if type(encounterId) == "string" and #encounterId <= 64 and completed == true then
                completedCombatSnapshot[encounterId] = true
            end
        end

        local companionProgressSnapshot = normalizeCompanionProgress(session.companionProgress)

        local ok, err = pcall(function()
            store:UpdateAsync(tostring(player.UserId), function(old)
                if type(old) ~= "table" then old = {} end
                for _, key in progress do
                    old[key] = old[key] == true or snapshot[key]
                end
                -- Never downgrade a profile written by a newer feature branch.
                old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 11)

                local savedTools = type(old.tools) == "table" and old.tools or {}
                savedTools.Axe = toolsSnapshot.Axe
                savedTools.Pickaxe = toolsSnapshot.Pickaxe
                savedTools.equipped = toolsSnapshot.equipped
                savedTools.levels = toolsSnapshot.levels
                old.tools = savedTools
                old.smelting = smeltingSnapshot

                local savedInventory = type(old.inventory) == "table" and old.inventory or {}
                for _, key in inventoryKeys do
                    savedInventory[key] = inventorySnapshot[key]
                end
                old.inventory = savedInventory

                local savedCooldowns = type(old.resourceCooldowns) == "table" and old.resourceCooldowns or {}
                for nodeId, readyAt in cooldownSnapshot do
                    savedCooldowns[nodeId] = math.max(tonumber(savedCooldowns[nodeId]) or 0, readyAt)
                end
                old.resourceCooldowns = savedCooldowns

                local savedCollected = type(old.collectedNodes) == "table" and old.collectedNodes or {}
                for nodeId, collected in collectedSnapshot do
                    if collected then savedCollected[nodeId] = true end
                end
                old.collectedNodes = savedCollected

                local savedHomeCooldowns = type(old.homeMaterialCooldowns) == "table" and old.homeMaterialCooldowns or {}
                for materialId, readyAt in homeMaterialCooldownSnapshot do
                    savedHomeCooldowns[materialId] = math.max(tonumber(savedHomeCooldowns[materialId]) or 0, readyAt)
                end
                old.homeMaterialCooldowns = savedHomeCooldowns

                local savedFoxScout = type(old.foxScout) == "table" and old.foxScout or {}
                savedFoxScout.activeCacheId = foxScoutSnapshot.activeCacheId
                savedFoxScout.readyAt = math.max(tonumber(savedFoxScout.readyAt) or 0, foxScoutSnapshot.readyAt)
                savedFoxScout.searchCount = math.max(tonumber(savedFoxScout.searchCount) or 0, foxScoutSnapshot.searchCount)
                old.foxScout = savedFoxScout

                local savedCombatEncounters = type(old.completedCombatEncounters) == "table" and old.completedCombatEncounters or {}
                for encounterId, completed in completedCombatSnapshot do
                    if completed then savedCombatEncounters[encounterId] = true end
                end
                old.completedCombatEncounters = savedCombatEncounters

                local savedCompanions = type(old.companions) == "table" and old.companions or {}
                for _, companionId in COMPANION_IDS do
                    savedCompanions[companionId] = companionProgressSnapshot[companionId]
                end
                old.companions = savedCompanions

                -- Schema v5 moves the old city payload into the permanent island record.
                -- Schema v6 adds persistent companion scouting and the MoonSeed inventory item.
                -- Keep this migration idempotent and preserve existing farm/building progress.
                local savedIsland = type(old.island) == "table" and old.island
                    or (type(old.city) == "table" and old.city or {})
                savedIsland.level = citySnapshot.level
                local savedFarm = type(savedIsland.farm) == "table" and savedIsland.farm or {}
                savedFarm.level = citySnapshot.farm.level
                savedFarm.selectedCropId = citySnapshot.farm.selectedCropId
                savedFarm.plots = citySnapshot.farm.plots
                savedIsland.farm = savedFarm
                savedIsland.bridges = type(savedIsland.bridges) == "table" and savedIsland.bridges or {}
                savedIsland.bridges.homeToGrove = citySnapshot.bridges.homeToGrove == true
                if type(savedIsland.buildings) ~= "table" then
                    savedIsland.buildings = {}
                end
                old.island = savedIsland
                old.city = nil
                return old
            end)
        end)
        if not ok then
            warn("Album save:", err)
            allOk = false
            break
        end
    until not session.saveAgain

    session.saving = false
    session.lastSaveOk = allOk
    return allOk
end
local function init(player)
    if sessions[player] then return end
    local session = {
        inventory = {},
        tools = {Axe = true, Pickaxe = true},
        toolLevels = {Axe = 1, Pickaxe = 1},
        equippedTool = "Axe",
        resourceCooldowns = {},
        resourceHits = {},
        resourceHitCooldowns = {},
        smeltingReadyAt = 0,
        smeltingAmount = 0,
        collectedNodes = {},
        city = defaultCity(),
        cityModel = nil,
        homeIsland = nil,
        homeSpawn = nil,
        homeSlot = nil,
        homeMaterialCooldowns = {},
        foxCacheActiveId = nil,
        foxSearchReadyAt = 0,
        foxSearchCount = 0,
        completedCombatEncounters = {},
        companionProgress = normalizeCompanionProgress(nil),
        companionMood = {Fox = companionMoodDefaults.Fox, Moth = companionMoodDefaults.Moth},
        companionFeedReadyAt = {},
        companionPetReadyAt = {},
        companionPlayReadyAt = {},
        companionPlay = nil,
        online = false,
        selectedCropId = defaultCropId,
        farmActionBusy = {},
    }
    for _, key in inventoryKeys do session.inventory[key] = 0 end
    session.inventory.CarrotSeed = 3
    session.inventory.StrawberrySeed = 2
    session.inventory.PumpkinSeed = 1
    session.inventory.CabbageSeed = 1
    session.inventory.Wood = 2
    session.inventory.Stone = 1
    sessions[player] = session

    -- Spawn safely in the public hub while the private island profile is loading.
    local grove = workspace:FindFirstChild("Grove")
    local publicSpawn = grove and grove:FindFirstChild("PublicSpawn")
    if publicSpawn and publicSpawn:IsA("SpawnLocation") then
        player.RespawnLocation = publicSpawn
    end

    local function placeCharacterAtHome(character)
        task.spawn(function()
            local root = character:WaitForChild("HumanoidRootPart", 12)
            local deadline = os.clock() + 20
            while player.Parent and not session.homeSpawn and os.clock() < deadline do
                task.wait(0.1)
            end
            if root and session.homeSpawn and character.Parent and player.Character == character then
                character:PivotTo(session.homeSpawn.CFrame + Vector3.new(0, 4, 0))
            end
        end)
    end
    session.characterConnection = player.CharacterAdded:Connect(placeCharacterAtHome)
    session.toolCharacterConnection = player.CharacterAdded:Connect(function()
        task.defer(function()
            if sessions[player] == session and player.Parent then syncTools(player) end
        end)
    end)
    if player.Character then
        placeCharacterAtHome(player.Character)
    end

    if store then
        local ok, data = pcall(function() return store:GetAsync(tostring(player.UserId)) end)
        if sessions[player] ~= session then return end
        session.online = ok
        if ok and type(data) == "table" then
            for _, key in progress do player:SetAttribute(key, data[key] == true) end
            local savedInventory = type(data.inventory) == "table" and data.inventory or {}
            for _, key in inventoryKeys do
                local savedAmount = savedInventory[key]
                local amount
                if key == "CarrotSeed" and savedAmount == nil then
                    amount = 3
                elseif key == "StrawberrySeed" and savedAmount == nil then
                    amount = 2
                elseif key == "PumpkinSeed" and savedAmount == nil then
                    amount = 1
                elseif key == "CabbageSeed" and savedAmount == nil then
                    amount = 1
                elseif key == "Wood" and savedAmount == nil then
                    amount = 2
                elseif key == "Stone" and savedAmount == nil then
                    amount = 1
                else
                    amount = tonumber(savedAmount) or 0
                end
                session.inventory[key] = math.clamp(math.floor(amount), 0, 1000000)
            end
            local savedSmelting = type(data.smelting) == "table" and data.smelting or {}
            session.smeltingReadyAt = math.max(0, math.floor(tonumber(savedSmelting.readyAt) or 0))
            session.smeltingAmount = math.clamp(math.floor(tonumber(savedSmelting.amount) or 0), 0, 10)
            local savedTools = type(data.tools) == "table" and data.tools or {}
            session.tools = {
                Axe = savedTools.Axe == true or savedTools.Axe == nil,
                Pickaxe = savedTools.Pickaxe == true or savedTools.Pickaxe == nil,
            }
            local savedLevels = type(savedTools.levels) == "table" and savedTools.levels or {}
            session.toolLevels = {
                Axe = math.clamp(math.floor(tonumber(savedLevels.Axe) or 1), 1, 2),
                Pickaxe = math.clamp(math.floor(tonumber(savedLevels.Pickaxe) or 1), 1, 2),
            }
            local savedEquippedTool = savedTools.equipped
            session.equippedTool = toolIds[savedEquippedTool] and session.tools[savedEquippedTool] and savedEquippedTool or "Axe"
            session.city = normalizeCity(type(data.island) == "table" and data.island or data.city)
            session.selectedCropId = session.city.farm.selectedCropId or defaultCropId

            local savedCooldowns = type(data.resourceCooldowns) == "table" and data.resourceCooldowns or {}
            for nodeId, readyAt in savedCooldowns do
                if resourceNodeIds[nodeId] and type(readyAt) == "number" then
                    session.resourceCooldowns[nodeId] = math.max(0, math.floor(readyAt))
                end
            end

            local savedCollected = type(data.collectedNodes) == "table" and data.collectedNodes or {}
            for nodeId, collected in savedCollected do
                if resourceNodeIds[nodeId] and collected == true then
                    session.collectedNodes[nodeId] = true
                end
            end

            local savedHomeCooldowns = type(data.homeMaterialCooldowns) == "table" and data.homeMaterialCooldowns or {}
            for materialId, readyAt in savedHomeCooldowns do
                if (materialId == "Wood" or materialId == "Stone") and type(readyAt) == "number" then
                    session.homeMaterialCooldowns[materialId] = math.max(0, math.floor(readyAt))
                end
            end

            local savedFoxScout = type(data.foxScout) == "table" and data.foxScout or {}
            if foxCacheIdSet[savedFoxScout.activeCacheId] then
                session.foxCacheActiveId = savedFoxScout.activeCacheId
            end
            session.foxSearchReadyAt = math.max(0, math.floor(tonumber(savedFoxScout.readyAt) or 0))
            session.foxSearchCount = math.max(0, math.floor(tonumber(savedFoxScout.searchCount) or 0))

            local savedCombatEncounters = type(data.completedCombatEncounters) == "table" and data.completedCombatEncounters or {}
            for encounterId, completed in savedCombatEncounters do
                if combatRewardDefinitions[encounterId] and completed == true then
                    session.completedCombatEncounters[encounterId] = true
                end
            end

            session.companionProgress = normalizeCompanionProgress(data.companions)
        end
        if not ok then player:SetAttribute("OfflineAlbum", true) end
    else
        player:SetAttribute("OfflineAlbum", true)
    end

    syncInventory(player)
    syncFarm(player)
    syncBridge(player)
    syncFoxScout(player)
    syncCompanionProgress(player)
    if not allocateHomeIsland(player, session) then
        sessions[player] = nil
        player:Kick("На этом сервере заняты все 8 домашних островов. Попробуй другой сервер.")
        return
    end
    if createPersonalCity then
        createPersonalCity(player, session)
    end
    if player.Character then
        task.defer(function()
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if character and root and session.homeSpawn then
                character:PivotTo(session.homeSpawn.CFrame + Vector3.new(0, 4, 0))
            end
        end)
    end
    player:SetAttribute("Ready", true)
    syncTools(player)
end
local combatRewardFunction = ServerStorage:FindFirstChild("GiantbackGrantCombatReward")
if combatRewardFunction and not combatRewardFunction:IsA("BindableFunction") then
    combatRewardFunction:Destroy()
    combatRewardFunction = nil
end
if not combatRewardFunction then
    combatRewardFunction = Instance.new("BindableFunction")
    combatRewardFunction.Name = "GiantbackGrantCombatReward"
    combatRewardFunction.Parent = ServerStorage
end

combatRewardFunction.OnInvoke = function(player, encounterId)
    if not player or not player:IsA("Player") or type(encounterId) ~= "string" then return false end
    local session = sessions[player]
    local reward = combatRewardDefinitions[encounterId]
    if not session or not player:GetAttribute("Ready") or not reward then return false end
    -- Repeated delivery is success: the reward was already persisted previously.
    if session.completedCombatEncounters[encounterId] then return true end

    session.completedCombatEncounters[encounterId] = true
    session.inventory[reward.itemId] = (session.inventory[reward.itemId] or 0) + reward.amount
    syncInventory(player)
    if session.online and not save(player) then
        session.completedCombatEncounters[encounterId] = nil
        session.inventory[reward.itemId] = math.max(0, (session.inventory[reward.itemId] or 0) - reward.amount)
        syncInventory(player)
        return false
    end
    tip(player, "Победа! Получено: " .. reward.itemId .. " ×" .. tostring(reward.amount))
    return true
end

local function collectFoxCache(player, cacheId)
    if typeof(cacheId) ~= "string" or not foxCacheIdSet[cacheId] then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if session.foxCacheActiveId ~= cacheId then return end
    if player:GetAttribute("Companion") ~= "Fox" then
        return tip(player, "Позови лисёнка, чтобы забрать найденный тайник.")
    end

    local grove = workspace:FindFirstChild("Grove")
    local anchor = grove and grove:FindFirstChild(cacheId)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not anchor or not anchor:IsA("BasePart") or not root then return end
    if (root.Position - anchor.Position).Magnitude > 10 then return end

    local reward = foxCacheRewards[cacheId]
    if not reward then return end
    local itemId = reward.itemId
    local amount = reward.amount
    if not player:GetAttribute("Seed") then
        itemId = "MoonSeed"
        amount = 1
        player:SetAttribute("Seed", true)
    end

    session.inventory[itemId] = (session.inventory[itemId] or 0) + amount
    session.foxCacheActiveId = nil
    session.foxSearchCount += 1
    local foxLevel = tonumber(player:GetAttribute("Companion_Fox_Level")) or 1
    session.foxSearchReadyAt = os.time() + foxScoutCooldownForLevel(foxLevel)
    syncInventory(player)
    syncFoxScout(player)

    local rewardNames = {
        MoonSeed = "лунное семя",
        SunPetal = "солнечные лепестки",
        Wood = "дерево",
        CarrotSeed = "семена моркови",
    }
    tip(player, "Лисёнок нашёл: " .. rewardNames[itemId] .. " ×" .. tostring(amount) .. "!")
    if session.online and not save(player) then
        warn("Fox cache reward save will be retried:", player.UserId, cacheId)
    end
    awardCompanionXp(player, "Fox", 30)
end

local function searchMoonGate(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if not player:GetAttribute("Fox") or player:GetAttribute("Companion") ~= "Fox" then
        return tip(player, "Позови лисёнка — только его нюх найдёт следы у древних корней.")
    end
    if not player:GetAttribute("Moth") or not player:GetAttribute("MoonBloom") then
        return tip(player, "Сначала познакомься с лунной молью и пробуди её первый цветок.")
    end
    if player:GetAttribute("MoonGateTrace") then
        return tip(player, "Лисёнок уже нашёл следы. Теперь руны ждут лунного света.")
    end

    local dusk = workspace:FindFirstChild("Dusk")
    local anchor = dusk and dusk:FindFirstChild("MoonGateTracks")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not anchor or not anchor:IsA("BasePart") or not root then return end
    if (root.Position - anchor.Position).Magnitude > 10 then return end

    player:SetAttribute("MoonGateTrace", true)
    tip(player, "Лисёнок нашёл древний след под корнями! Теперь позови лунную моль к рунам.")
    if session.online and not save(player) then
        warn("MoonGate Fox trace save will be retried:", player.UserId)
    end
    awardCompanionXp(player, "Fox", 20)
end

local function revealMoonGate(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if not player:GetAttribute("MoonGateTrace") then
        return tip(player, "Сначала попроси лисёнка найти древний след у корней.")
    end
    if not player:GetAttribute("Moth") or player:GetAttribute("Companion") ~= "Moth" then
        return tip(player, "Позови лунную моль — только её свет пробудит древние руны.")
    end
    if player:GetAttribute("MoonGateOpen") then
        return tip(player, "Тайный проход уже открыт. Поляна ждёт тебя за аркой.")
    end

    local dusk = workspace:FindFirstChild("Dusk")
    local anchor = dusk and dusk:FindFirstChild("MoonGateRune")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not anchor or not anchor:IsA("BasePart") or not root then return end
    if (root.Position - anchor.Position).Magnitude > 10 then return end

    player:SetAttribute("MoonGateOpen", true)
    tip(player, "Лунная моль зажгла древние руны! Тайный проход открылся — за аркой спрятан звёздный осколок.")
    if session.online and not save(player) then
        warn("MoonGate Moth reveal save will be retried:", player.UserId)
    end
    awardCompanionXp(player, "Moth", 25)
end

local function collectMoonRelic(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if not player:GetAttribute("MoonGateOpen") then
        return tip(player, "Сначала раскрой тайный проход с помощью обоих питомцев.")
    end
    if player:GetAttribute("MoonRelic") then
        return tip(player, "Звёздный осколок уже хранится в твоей коллекции.")
    end

    local dusk = workspace:FindFirstChild("Dusk")
    local anchor = dusk and dusk:FindFirstChild("MoonRelic")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not anchor or not anchor:IsA("BasePart") or not root then return end
    if (root.Position - anchor.Position).Magnitude > 10 then return end

    player:SetAttribute("MoonRelic", true)
    session.inventory.StarShard = (session.inventory.StarShard or 0) + 1
    syncInventory(player)
    tip(player, "Редкая находка! Ты получил звёздный осколок ×1.")
    if session.online and not save(player) then
        warn("Moon Relic reward save will be retried:", player.UserId)
    end
end

local function collectMoonBloom(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if player:GetAttribute("Companion") ~= "Moth" then
        return tip(player, "Позови лунную моль — только её свет раскрывает этот цветок.")
    end
    if player:GetAttribute("MoonBloom") then
        return tip(player, "Этот лунный цветок уже пробуждён.")
    end

    local dusk = workspace:FindFirstChild("Dusk")
    local anchor = dusk and dusk:FindFirstChild("MoonBloom")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not anchor or not anchor:IsA("BasePart") or not root then return end
    if (root.Position - anchor.Position).Magnitude > 10 then return end

    player:SetAttribute("MoonBloom", true)
    session.inventory.MoonPetal = (session.inventory.MoonPetal or 0) + 2
    syncInventory(player)
    tip(player, "Лунная моль раскрыла тайный цветок! Получено: лунные лепестки ×2.")
    if session.online and not save(player) then
        warn("MoonBloom discovery save will be retried:", player.UserId)
    end
    awardCompanionXp(player, "Moth", 35)
end

local function startFoxSearch(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if player:GetAttribute("Companion") ~= "Fox" then
        return tip(player, "Позови лисёнка из альбома — он умеет находить тайники.")
    end
    if session.foxCacheActiveId then
        return tip(player, "Лисёнок уже учуял тайник. Следуй за золотой меткой!")
    end

    local now = os.time()
    if session.foxSearchReadyAt > now then
        local remaining = session.foxSearchReadyAt - now
        return tip(player, "Нюх лисёнка восстановится через " .. tostring(math.ceil(remaining / 60)) .. " мин.")
    end

    local cacheIndex = (session.foxSearchCount % #foxCacheIds) + 1
    local cacheId = foxCacheIds[cacheIndex]
    local grove = workspace:FindFirstChild("Grove")
    local anchor = grove and grove:FindFirstChild(cacheId)
    if not anchor then
        warn("Fox scout cache is missing:", cacheId)
        return tip(player, "Лисёнок пока не может найти след. Попробуй немного позже.")
    end

    session.foxCacheActiveId = cacheId
    syncFoxScout(player)
    tip(player, "Лисёнок учуял тайник! Ищи золотую метку в Солнечной роще.")
    if session.online and not save(player) then
        warn("Fox scout search state save will be retried:", player.UserId, cacheId)
    end
end

event.OnServerEvent:Connect(function(player, action, payload)
    if typeof(action) ~= "string" or not player:GetAttribute("Ready") then return end

    if action == "PetCompanion" then
        petCompanion(player, payload)
        return
    end

    if action == "FeedCompanion" then
        feedCompanion(player, payload)
        return
    end

    if action == "StartCompanionPlay" then
        startCompanionPlay(player, payload)
        return
    end

    if action == "CompanionPlayInput" then
        submitCompanionPlayInput(player, payload)
        return
    end

    if action == "SearchMoonGate" then
        searchMoonGate(player)
        return
    end

    if action == "RevealMoonGate" then
        revealMoonGate(player)
        return
    end

    if action == "CollectMoonRelic" then
        collectMoonRelic(player)
        return
    end

    if action == "CollectMoonBloom" then
        collectMoonBloom(player)
        return
    end

    if action == "CollectFoxCache" then
        collectFoxCache(player, payload)
        return
    end

    if action == "UpgradeTool" then
        local session = sessions[player]
        if not session or typeof(payload) ~= "string" or not toolUpgradeCosts[payload] then return end
        if session.tools[payload] ~= true then return tip(player, "Сначала открой этот инструмент.") end
        if session.toolLevels[payload] >= 2 then return tip(player, "Инструмент уже улучшен до максимального уровня.") end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local city = session.homeIsland and session.homeIsland:FindFirstChild("PersonalCity")
        local station = city and city:FindFirstChild("Workshop")
        local anchor = station and station:FindFirstChild("PromptAnchor")
        if not root or not anchor or (root.Position - anchor.Position).Magnitude > 14 then
            return tip(player, "Улучшать инструменты можно только у верстака на своём острове.")
        end
        local cost = toolUpgradeCosts[payload]
        if (session.inventory.Wood or 0) < cost.Wood or (session.inventory.Stone or 0) < cost.Stone then
            return tip(player, "Не хватает дерева ×" .. tostring(cost.Wood) .. " и камня ×" .. tostring(cost.Stone) .. ".")
        end
        session.inventory.Wood -= cost.Wood
        session.inventory.Stone -= cost.Stone
        session.toolLevels[payload] = 2
        syncInventory(player)
        syncTools(player)
        event:FireClient(player, "ToolUpgraded", payload)
        tip(player, payload == "Axe" and "Топор улучшен! Деревья рубятся быстрее." or "Кирка улучшена! Камень добывается быстрее.")
        if session.online then save(player) end
        return
    end

    if action == "EquipTool" then
        local session = sessions[player]
        if not session or typeof(payload) ~= "string" or not toolIds[payload] then return end
        if session.tools[payload] ~= true then return tip(player, "Этот инструмент ещё не открыт.") end
        session.equippedTool = payload
        syncTools(player)
        tip(player, payload == "Axe" and "Топор экипирован." or "Кирка экипирована.")
        if session.online then save(player) end
        return
    end

    if action == "RequestResourceState" then
        local session = sessions[player]
        if not session then return end
        local state = {cooldowns = {}, collected = {}}
        local now = os.time()
        for nodeId, readyAt in session.resourceCooldowns do
            if resourceNodeIds[nodeId] and readyAt > now then
                state.cooldowns[nodeId] = readyAt
            end
        end
        for nodeId, collected in session.collectedNodes do
            if resourceNodeIds[nodeId] and collected == true then
                state.collected[nodeId] = true
            end
        end
        event:FireClient(player, "ResourceState", state)
        return
    end

    if action == "SelectCrop" then
        local session = sessions[player]
        local cropId = type(payload) == "string" and payload or ""
        local definition = cropDefinitions[cropId]
        if not session or not definition then return end
        if (session.inventory[definition.seedItemId] or 0) < 1 then
            return tip(player, "У тебя пока нет семян: " .. definition.displayName .. ".")
        end
        session.selectedCropId = cropId
        session.city.farm.selectedCropId = cropId
        syncFarm(player)
        tip(player, "Выбрано для посадки: " .. definition.displayName .. ". Подойди к свободной грядке.")
        return
    end

    if pets[action] and player:GetAttribute(action) then
        player:SetAttribute("Companion",action)
        setCompanionMood(player, action, action == "Fox" and "Любопытство" or "Спокойствие")
    end
end)

local function prompt(part, title, verb, callback)
    local p = Instance.new("ProximityPrompt")
    p.ObjectText, p.ActionText = title, verb
    p.RequiresLineOfSight = false
    p.MaxActivationDistance = 9
    p.Parent = part
    p.Triggered:Connect(function(player)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and player:GetAttribute("Ready") and (root.Position-part.Position).Magnitude <= p.MaxActivationDistance + 1 then
            callback(player)
        end
    end)
    return p
end

local function makeFarmVisualPart(parent, name, size, frame, color, shape, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = frame
    part.Color = color
    part.Shape = shape or Enum.PartType.Block
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function refreshFarmPlotVisual(cityModel, plotId, farm, selectedCropId)
    local plotModel = cityModel and cityModel:FindFirstChild(plotId)
    if not plotModel then return end

    local state = farm.plots[plotId]
    if not state then return end
    local unlocked = isFarmPlotUnlocked(farm, plotId)
    local soil = plotModel:FindFirstChild("Soil")
    local anchor = plotModel:FindFirstChild("PromptAnchor")
    local interaction = anchor and anchor:FindFirstChildOfClass("ProximityPrompt")

    if soil then
        soil.Color = unlocked and Color3.fromRGB(111, 77, 54) or Color3.fromRGB(88, 91, 83)
        soil.Material = unlocked and Enum.Material.Ground or Enum.Material.Slate
    end

    if interaction then
        if not unlocked then
            interaction.ActionText = "Закрыто"
            interaction.ObjectText = "Улучшить ферму"
        elseif state.cropId == "" then
            interaction.ActionText = "Посадить"
            interaction.ObjectText = cropDefinitions[selectedCropId or defaultCropId].displayName
        elseif os.time() >= state.readyAt then
            interaction.ActionText = "Собрать"
            interaction.ObjectText = (cropDefinitions[state.cropId] and cropDefinitions[state.cropId].displayName or "Урожай") .. " созрела"
        else
            interaction.ActionText = "Проверить"
            interaction.ObjectText = (cropDefinitions[state.cropId] and cropDefinitions[state.cropId].displayName or "Растение") .. " растёт"
        end
    end

    local cropVisual = plotModel:FindFirstChild("CropVisual")
    if not unlocked or state.cropId == "" then
        if cropVisual then cropVisual:Destroy() end
        return
    end

    local cropDefinition = cropDefinitions[state.cropId]
    if not cropDefinition then return end
    if cropVisual and cropVisual:GetAttribute("CropId") ~= state.cropId then
        cropVisual:Destroy()
        cropVisual = nil
    end

    local cropPieces = {
        Carrot = {
            {name = "LeafA", size = Vector3.new(0.9, 0.16, 0.34), offset = Vector3.new(-0.28, 0.7, 0), color = Color3.fromRGB(111, 178, 91), shape = Enum.PartType.Ball, rotation = -28},
            {name = "LeafB", size = Vector3.new(0.92, 0.16, 0.34), offset = Vector3.new(0.28, 0.78, 0), color = Color3.fromRGB(91, 157, 80), shape = Enum.PartType.Ball, rotation = 28},
            {name = "LeafC", size = Vector3.new(0.62, 0.15, 0.3), offset = Vector3.new(0, 1.02, 0), color = Color3.fromRGB(132, 190, 96), shape = Enum.PartType.Ball, rotation = 90},
            {name = "Root", size = Vector3.new(0.34, 0.92, 0.34), offset = Vector3.new(0, 0.24, 0), color = Color3.fromRGB(239, 145, 65), shape = Enum.PartType.Cylinder, rotation = 90, revealAt = 0.72},
        },
        Strawberry = {
            {name = "LeafA", size = Vector3.new(0.9, 0.18, 0.42), offset = Vector3.new(-0.34, 0.62, 0), color = Color3.fromRGB(77, 157, 79), shape = Enum.PartType.Ball, rotation = -22},
            {name = "LeafB", size = Vector3.new(0.9, 0.18, 0.42), offset = Vector3.new(0.34, 0.66, 0), color = Color3.fromRGB(94, 176, 85), shape = Enum.PartType.Ball, rotation = 22},
            {name = "LeafC", size = Vector3.new(0.72, 0.18, 0.38), offset = Vector3.new(0, 0.82, 0.22), color = Color3.fromRGB(111, 187, 94), shape = Enum.PartType.Ball, rotation = 0},
            {name = "BerryA", size = Vector3.new(0.42, 0.46, 0.42), offset = Vector3.new(-0.38, 0.32, -0.2), color = Color3.fromRGB(218, 67, 74), shape = Enum.PartType.Ball, revealAt = 0.72},
            {name = "BerryB", size = Vector3.new(0.4, 0.44, 0.4), offset = Vector3.new(0.34, 0.34, 0.22), color = Color3.fromRGB(232, 81, 79), shape = Enum.PartType.Ball, revealAt = 0.82},
        },
        Pumpkin = {
            {name = "VineA", size = Vector3.new(1.25, 0.16, 0.36), offset = Vector3.new(-0.34, 0.38, 0), color = Color3.fromRGB(75, 143, 69), shape = Enum.PartType.Ball, rotation = -18},
            {name = "VineB", size = Vector3.new(1.2, 0.16, 0.36), offset = Vector3.new(0.34, 0.4, 0), color = Color3.fromRGB(91, 160, 74), shape = Enum.PartType.Ball, rotation = 18},
            {name = "LeafA", size = Vector3.new(0.8, 0.18, 0.72), offset = Vector3.new(-0.5, 0.58, 0.24), color = Color3.fromRGB(85, 165, 76), shape = Enum.PartType.Ball},
            {name = "LeafB", size = Vector3.new(0.82, 0.18, 0.7), offset = Vector3.new(0.5, 0.58, -0.22), color = Color3.fromRGB(105, 179, 82), shape = Enum.PartType.Ball},
            {name = "Fruit", size = Vector3.new(0.9, 0.78, 0.9), offset = Vector3.new(0, 0.35, 0), color = Color3.fromRGB(239, 139, 48), shape = Enum.PartType.Ball, revealAt = 0.72},
            {name = "FruitStem", size = Vector3.new(0.16, 0.3, 0.16), offset = Vector3.new(0, 0.86, 0), color = Color3.fromRGB(80, 119, 58), shape = Enum.PartType.Cylinder, revealAt = 0.78},
        },
        Cabbage = {
            {name = "OuterA", size = Vector3.new(0.92, 0.22, 0.72), offset = Vector3.new(-0.34, 0.34, 0), color = Color3.fromRGB(111, 178, 91), shape = Enum.PartType.Ball},
            {name = "OuterB", size = Vector3.new(0.92, 0.22, 0.72), offset = Vector3.new(0.34, 0.34, 0), color = Color3.fromRGB(91, 160, 82), shape = Enum.PartType.Ball},
            {name = "OuterC", size = Vector3.new(0.82, 0.22, 0.72), offset = Vector3.new(0, 0.52, -0.32), color = Color3.fromRGB(130, 190, 105), shape = Enum.PartType.Ball},
            {name = "OuterD", size = Vector3.new(0.82, 0.22, 0.72), offset = Vector3.new(0, 0.52, 0.32), color = Color3.fromRGB(105, 174, 91), shape = Enum.PartType.Ball},
            {name = "Heart", size = Vector3.new(0.72, 0.72, 0.72), offset = Vector3.new(0, 0.48, 0), color = Color3.fromRGB(191, 218, 139), shape = Enum.PartType.Ball, revealAt = 0.68},
        },
    }

    if not cropVisual then
        cropVisual = Instance.new("Model")
        cropVisual.Name = "CropVisual"
        cropVisual:SetAttribute("CropId", state.cropId)
        cropVisual.Parent = plotModel
        for _, definition in cropPieces[state.cropId] do
            makeFarmVisualPart(cropVisual, definition.name, definition.size, CFrame.new(), definition.color, definition.shape)
        end
    end

    local now = os.time()
    local duration = math.max(1, state.readyAt - state.plantedAt)
    local growth = math.clamp((now - state.plantedAt) / duration, 0, 1)
    local stage = math.clamp(math.floor(growth * 5) + 1, 1, 5)
    local scale = 0.28 + growth * 0.72
    local baseY = soil and (soil.Size.Y / 2) or 0
    cropVisual:SetAttribute("GrowthStage", stage)
    cropVisual:SetAttribute("GrowthProgress", growth)

    if soil then
        for _, definition in cropPieces[state.cropId] do
            local piece = cropVisual:FindFirstChild(definition.name)
            if piece then
                local visible = growth >= (definition.revealAt or 0.08)
                piece.Transparency = visible and 0 or 1
                piece.Size = definition.size * scale
                local offset = definition.offset * scale
                piece.CFrame = soil.CFrame
                    * CFrame.new(offset.X, baseY + offset.Y, offset.Z)
                    * CFrame.Angles(0, 0, math.rad(definition.rotation or 0))
            end
        end
    end
end

local function refreshFarmCity(player, cityModel)
    local session = sessions[player]
    if not session or not session.city or not cityModel then return end
    for _, plotId in farmPlotIds do
        refreshFarmPlotVisual(cityModel, plotId, session.city.farm, session.selectedCropId)
    end
end

local function interactFarmPlot(player, ownerUserId, plotId)
    if player.UserId ~= ownerUserId then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end

    local farm = session.city.farm
    local state = farm.plots[plotId]
    if not state then return end
    if not isFarmPlotUnlocked(farm, plotId) then
        return tip(player, "Эта грядка откроется после улучшения фермы.")
    end

    if session.farmActionBusy[plotId] then return end
    session.farmActionBusy[plotId] = true
    local now = os.time()
    if state.cropId == "" then
        local cropId = session.selectedCropId or defaultCropId
        local definition = cropDefinitions[cropId]
        if not definition then session.farmActionBusy[plotId] = nil return end
        if (session.inventory[definition.seedItemId] or 0) < 1 then
            session.farmActionBusy[plotId] = nil
            return tip(player, "Нет семян: " .. definition.displayName .. ". Выбери другую культуру.")
        end
        session.inventory[definition.seedItemId] -= 1
        state.cropId = cropId
        state.plantedAt = now
        state.readyAt = now + definition.growthSeconds
        tip(player, definition.displayName .. " посажена! Рост займёт около " .. tostring(math.ceil(definition.growthSeconds / 60)) .. " мин.")
    else
        local definition = cropDefinitions[state.cropId]
        if not definition then
            state.cropId, state.plantedAt, state.readyAt = "", 0, 0
            session.farmActionBusy[plotId] = nil
            return
        end
        if now < state.readyAt then
            local remaining = state.readyAt - now
            session.farmActionBusy[plotId] = nil
            return tip(player, definition.displayName .. " ещё растёт: осталось " .. tostring(math.ceil(remaining / 60)) .. " мин.")
        end
        session.inventory[definition.harvestItemId] = (session.inventory[definition.harvestItemId] or 0) + definition.reward
        if definition.regrowSeconds then
            state.plantedAt = now
            state.readyAt = now + definition.regrowSeconds
            tip(player, "Собрано: " .. definition.displayName .. " ×" .. tostring(definition.reward) .. "! Куст снова плодоносит.")
        else
            state.cropId, state.plantedAt, state.readyAt = "", 0, 0
            tip(player, "Урожай собран: " .. definition.displayName .. " ×" .. tostring(definition.reward) .. "!")
        end
    end
    session.farmActionBusy[plotId] = nil

    syncInventory(player)
    syncFarm(player)
    refreshFarmCity(player, session.cityModel)
    if session.online and not save(player) then
        warn("Farm save will be retried:", player.UserId, plotId)
        tip(player, "Урожай сохранён в текущей сессии. Сохранение временно задерживается.")
    end
end

local function gatherHomeMaterial(player, ownerUserId, materialId)
    if player.UserId ~= ownerUserId then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end

    local definitions = {
        Wood = {amount = 3, cooldown = 60, title = "Дерево"},
        Stone = {amount = 2, cooldown = 60, title = "Камень"},
    }
    local definition = definitions[materialId]
    if not definition then return end

    local now = os.time()
    local readyAt = session.homeMaterialCooldowns[materialId] or 0
    if readyAt > now then
        return tip(player, definition.title .. " снова появится через " .. tostring(math.ceil((readyAt - now) / 60)) .. " мин.")
    end

    session.inventory[materialId] = (session.inventory[materialId] or 0) + definition.amount
    session.homeMaterialCooldowns[materialId] = now + definition.cooldown
    syncInventory(player)
    tip(player, "Собрано: " .. definition.title .. " ×" .. tostring(definition.amount))
    if session.online then save(player) end
end

local function useHomeSmelter(player, ownerUserId, smelterAnchor)
    if player.UserId ~= ownerUserId then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not smelterAnchor or not smelterAnchor.Parent or (root.Position - smelterAnchor.Position).Magnitude > 14 then
        return tip(player, "Подойди к своей плавильне.")
    end

    local now = os.time()
    if (session.smeltingAmount or 0) > 0 then
        if (session.smeltingReadyAt or 0) > now then
            local remaining = session.smeltingReadyAt - now
            return tip(player, "Железо плавится. Осталось примерно " .. tostring(math.ceil(remaining / 10) * 10) .. " сек.")
        end
        local amount = math.max(1, math.floor(session.smeltingAmount))
        session.inventory.IronIngot = (session.inventory.IronIngot or 0) + amount
        session.smeltingAmount = 0
        session.smeltingReadyAt = 0
        syncInventory(player)
        tip(player, "Готово! Получено железных слитков ×" .. tostring(amount) .. ".")
        if session.online then save(player) end
        return
    end

    local oreCost, woodCost, duration = 3, 2, 60
    if (session.inventory.IronOre or 0) < oreCost or (session.inventory.Wood or 0) < woodCost then
        return tip(player, "Для плавки нужно железо ×3 и дерево ×2 для растопки.")
    end
    session.inventory.IronOre -= oreCost
    session.inventory.Wood -= woodCost
    session.smeltingAmount = 1
    session.smeltingReadyAt = now + duration
    syncInventory(player)
    tip(player, "Плавка началась! Через минуту забери железный слиток у плавильни.")
    if session.online then save(player) end
end

local function repairHomeBridge(player, ownerUserId)
    if player.UserId ~= ownerUserId then return end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if session.city.bridges.homeToGrove then
        return tip(player, "Мост в Солнечную рощу уже восстановлен.")
    end

    local woodCost, stoneCost = 5, 3
    local wood = session.inventory.Wood or 0
    local stone = session.inventory.Stone or 0
    if wood < woodCost or stone < stoneCost then
        return tip(player, "Для моста нужно дерево ×5 и камень ×3. Собери материалы на своём острове.")
    end

    session.inventory.Wood = wood - woodCost
    session.inventory.Stone = stone - stoneCost
    session.city.bridges.homeToGrove = true
    applyHomeBridgeState(session.homeSlot, true)
    syncInventory(player)
    syncBridge(player)
    tip(player, "Мост восстановлен! Теперь можно идти в Солнечную рощу.")
    if session.online then save(player) end
end

createPersonalCity = function(player, session)
    local ownerUserId = player.UserId
    local homeIsland = session.homeIsland
    if not homeIsland then return end

    local previous = homeIsland:FindFirstChild("PersonalCity")
    if previous then previous:Destroy() end

    local cityModel = Instance.new("Model")
    cityModel.Name = "PersonalCity"
    cityModel:SetAttribute("OwnerUserId", ownerUserId)
    cityModel:SetAttribute("CityLevel", session.city.level)
    cityModel:SetAttribute("FarmLevel", session.city.farm.level)
    cityModel.Parent = homeIsland

    -- The cloned island already owns its cottage, garden and lantern pad.
    -- Only player-specific quest interactions and farm plots are created here.
    local planter = homeIsland:FindFirstChild("Planter")
    local lanternBase = homeIsland:FindFirstChild("LanternBase")
    local woodPile = homeIsland:FindFirstChild("WoodPile")
    local stonePile = homeIsland:FindFirstChild("StonePile")
    local gangway = homeIsland:FindFirstChild("Gangway")

    if woodPile then
        prompt(woodPile, "Сухие ветви", "Собрать дерево ×3", function(visitor)
            gatherHomeMaterial(visitor, ownerUserId, "Wood")
        end)
    end
    if stonePile then
        prompt(stonePile, "Камни у дома", "Собрать камень ×2", function(visitor)
            gatherHomeMaterial(visitor, ownerUserId, "Stone")
        end)
    end
    if gangway then
        prompt(gangway, "Мост в Солнечную рощу", "Восстановить мост", function(visitor)
            repairHomeBridge(visitor, ownerUserId)
        end)
    end

    if planter then
        prompt(planter, "Сад у дома", "Разбудить цветок", function(visitor)
            if visitor.UserId ~= player.UserId then return end
            if visitor:GetAttribute("Flower") then return tip(visitor, "Твой лунный цветок уже расцвёл.") end
            if not visitor:GetAttribute("Seed") then return tip(visitor, "Лисёнок чует семя на тропе возле гнезда.") end
            if visitor:GetAttribute("Companion") ~= "Moth" then return tip(visitor, "Позови лунную моль из альбома.") end
            local visitorSession = sessions[visitor]
            if visitorSession and (visitorSession.inventory.MoonSeed or 0) > 0 then
                visitorSession.inventory.MoonSeed -= 1
                syncInventory(visitor)
            end
            visitor:SetAttribute("Flower", true)
            tip(visitor, "Моль расправила крылья. Твой лунный цветок расцвёл!")
        end)
    end

    if lanternBase then
        prompt(lanternBase, "Садовый фонарь", "Осмотреть площадку", function(visitor)
            if visitor.UserId ~= player.UserId then return end
            if not visitor:GetAttribute("Timber") then return tip(visitor, "После цветения возьми лисёнка к коряге в Солнечной роще.") end
            if not visitor:GetAttribute("Lantern") then
                visitor:SetAttribute("Lantern", true)
                return tip(visitor, "Фонарь построен! Позови моль, чтобы зажечь его.")
            end
            if visitor:GetAttribute("Lit") then return tip(visitor, "Фонарь освещает твой сад.") end
            if visitor:GetAttribute("Companion") ~= "Moth" then return tip(visitor, "Позови лунную моль из альбома.") end
            visitor:SetAttribute("Lit", true)
            tip(visitor, "Моль зажгла твой первый садовый фонарь!")
        end)
    end

    local meadow = homeIsland:FindFirstChild("Meadow")
    if meadow then
        local workshop = Instance.new("Model")
        workshop.Name = "Workshop"
        workshop:SetAttribute("OwnerUserId", ownerUserId)
        workshop.Parent = cityModel
        local benchFrame = meadow.CFrame * CFrame.new(4, meadow.Size.Y / 2 + 0.72, -10)
        makeFarmVisualPart(workshop, "WorkbenchTop", Vector3.new(4.8, 0.38, 2.4), benchFrame, Color3.fromRGB(126, 83, 53), Enum.PartType.Block, Enum.Material.Wood)
        for _, offset in {
            Vector3.new(-2.0, -0.78, -0.85), Vector3.new(2.0, -0.78, -0.85),
            Vector3.new(-2.0, -0.78, 0.85), Vector3.new(2.0, -0.78, 0.85),
        } do
            makeFarmVisualPart(workshop, "WorkbenchLeg", Vector3.new(0.32, 1.2, 0.32), benchFrame * CFrame.new(offset), Color3.fromRGB(91, 61, 43), Enum.PartType.Block, Enum.Material.Wood)
        end
        makeFarmVisualPart(workshop, "AnvilBase", Vector3.new(1.15, 0.42, 0.72), benchFrame * CFrame.new(0, 0.42, 0), Color3.fromRGB(75, 83, 86), Enum.PartType.Block, Enum.Material.Metal)
        makeFarmVisualPart(workshop, "AnvilTop", Vector3.new(1.65, 0.3, 0.8), benchFrame * CFrame.new(0, 0.78, 0), Color3.fromRGB(137, 151, 151), Enum.PartType.Block, Enum.Material.Metal)
        local workshopAnchor = Instance.new("Part")
        workshopAnchor.Name = "PromptAnchor"
        workshopAnchor.Size = Vector3.new(0.5, 0.5, 0.5)
        workshopAnchor.Transparency = 1
        workshopAnchor.Anchored = true
        workshopAnchor.CanCollide = false
        workshopAnchor.CanTouch = false
        workshopAnchor.CanQuery = true
        workshopAnchor.CFrame = benchFrame * CFrame.new(0, 2.0, 0)
        workshopAnchor.Parent = workshop
        prompt(workshopAnchor, "Мастерская", "Улучшить инструменты", function(visitor)
            if visitor.UserId ~= ownerUserId then return end
            tip(visitor, "Открой вкладку «Инструменты», чтобы улучшить топор или кирку.")
        end)

        local smelter = Instance.new("Model")
        smelter.Name = "Smelter"
        smelter:SetAttribute("OwnerUserId", ownerUserId)
        smelter.Parent = workshop
        local smelterFrame = benchFrame * CFrame.new(4.2, 0.2, 0)
        makeFarmVisualPart(smelter, "FurnaceBody", Vector3.new(2.3, 2.6, 2.3), smelterFrame, Color3.fromRGB(83, 91, 91), Enum.PartType.Block, Enum.Material.Slate)
        makeFarmVisualPart(smelter, "FurnaceMouth", Vector3.new(1.1, 0.85, 0.16), smelterFrame * CFrame.new(0, -0.15, -1.18), Color3.fromRGB(244, 133, 72), Enum.PartType.Block, Enum.Material.Neon)
        makeFarmVisualPart(smelter, "FurnaceChimney", Vector3.new(0.7, 1.4, 0.7), smelterFrame * CFrame.new(0.55, 1.8, 0.25), Color3.fromRGB(100, 106, 102), Enum.PartType.Block, Enum.Material.Slate)
        makeFarmVisualPart(smelter, "FurnaceCap", Vector3.new(1.0, 0.18, 1.0), smelterFrame * CFrame.new(0.55, 2.55, 0.25), Color3.fromRGB(66, 73, 72), Enum.PartType.Block, Enum.Material.Metal)
        local smelterAnchor = Instance.new("Part")
        smelterAnchor.Name = "PromptAnchor"
        smelterAnchor.Size = Vector3.new(0.5, 0.5, 0.5)
        smelterAnchor.Transparency = 1
        smelterAnchor.Anchored = true
        smelterAnchor.CanCollide = false
        smelterAnchor.CanTouch = false
        smelterAnchor.CanQuery = true
        smelterAnchor.CFrame = smelterFrame * CFrame.new(0, 1.0, -1.5)
        smelterAnchor.Parent = smelter
        prompt(smelterAnchor, "Плавильня", "Запустить плавку / забрать слиток", function(visitor)
            useHomeSmelter(visitor, ownerUserId, smelterAnchor)
        end)

        local plotPositions = {
            Plot01 = Vector3.new(-14.5, meadow.Size.Y / 2 + 0.22, 8.8),
            Plot02 = Vector3.new(-10.5, meadow.Size.Y / 2 + 0.22, 8.8),
            Plot03 = Vector3.new(-14.5, meadow.Size.Y / 2 + 0.22, 12.4),
            Plot04 = Vector3.new(-10.5, meadow.Size.Y / 2 + 0.22, 12.4),
        }

        for _, plotId in farmPlotIds do
            local currentPlotId = plotId
            local plotModel = Instance.new("Model")
            plotModel.Name = currentPlotId
            plotModel:SetAttribute("OwnerUserId", ownerUserId)
            plotModel:SetAttribute("PlotId", currentPlotId)
            plotModel.Parent = cityModel

            local soilFrame = meadow.CFrame * CFrame.new(plotPositions[currentPlotId])
            local soil = makeFarmVisualPart(
                plotModel,
                "Soil",
                Vector3.new(3.2, 0.44, 3.2),
                soilFrame,
                Color3.fromRGB(111, 77, 54),
                Enum.PartType.Block,
                Enum.Material.Ground
            )

            -- Raised timber edging and shallow furrows make each plot readable
            -- before planting; all detail parts stay non-interactive and non-colliding.
            local bedFrame = soil.CFrame
            local bedTop = soil.Size.Y / 2
            local bedLength = soil.Size.X
            local bedWidth = soil.Size.Z
            local edgeColor = Color3.fromRGB(137, 94, 62)
            local edgeMaterial = Enum.Material.WoodPlanks
            makeFarmVisualPart(
                plotModel,
                "BedEdgeFront",
                Vector3.new(bedLength + 0.22, 0.28, 0.22),
                bedFrame * CFrame.new(0, bedTop + 0.04, -bedWidth / 2),
                edgeColor,
                Enum.PartType.Block,
                edgeMaterial
            )
            makeFarmVisualPart(
                plotModel,
                "BedEdgeBack",
                Vector3.new(bedLength + 0.22, 0.28, 0.22),
                bedFrame * CFrame.new(0, bedTop + 0.04, bedWidth / 2),
                edgeColor,
                Enum.PartType.Block,
                edgeMaterial
            )
            makeFarmVisualPart(
                plotModel,
                "BedEdgeLeft",
                Vector3.new(0.22, 0.28, bedWidth - 0.18),
                bedFrame * CFrame.new(-bedLength / 2, bedTop + 0.04, 0),
                edgeColor,
                Enum.PartType.Block,
                edgeMaterial
            )
            makeFarmVisualPart(
                plotModel,
                "BedEdgeRight",
                Vector3.new(0.22, 0.28, bedWidth - 0.18),
                bedFrame * CFrame.new(bedLength / 2, bedTop + 0.04, 0),
                edgeColor,
                Enum.PartType.Block,
                edgeMaterial
            )
            for furrowIndex = 1, 3 do
                local furrowX = (furrowIndex - 2) * 0.72
                makeFarmVisualPart(
                    plotModel,
                    "SoilFurrow",
                    Vector3.new(0.12, 0.025, bedWidth - 0.62),
                    bedFrame * CFrame.new(furrowX, bedTop + 0.015, 0),
                    Color3.fromRGB(83, 57, 43),
                    Enum.PartType.Block,
                    Enum.Material.Ground
                )
            end

            local anchor = Instance.new("Part")
            anchor.Name = "PromptAnchor"
            anchor.Size = Vector3.new(0.5, 0.5, 0.5)
            anchor.Transparency = 1
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.CanTouch = false
            anchor.CanQuery = true
            anchor.CFrame = soil.CFrame * CFrame.new(0, 1.1, 0)
            anchor.Parent = plotModel

            prompt(anchor, "Грядка", "Посадить", function(visitor)
                interactFarmPlot(visitor, ownerUserId, currentPlotId)
            end)
        end
    end

    session.cityModel = cityModel
    refreshFarmCity(player, cityModel)
end


local function encounter(id, island, height)
    local nest = island.Nest
    local model = Storage[id]:Clone()
    model.Name = id .. "Encounter"
    model:SetAttribute("CompanionId", id)
    model.Parent = island
    model:PivotTo(CFrame.new(nest.Position + Vector3.new(0,height,0)) * CFrame.Angles(0,math.pi,0))
    prompt(nest,pets[id],"Подружиться",function(player)
        if player:GetAttribute(id) then
            return tip(player, "Вы уже познакомились с " .. pets[id] .. ". Найти её повторно не нужно.")
        end
        player:SetAttribute(id,true)
        player:SetAttribute("Companion",id)
        tip(player,pets[id] .. " теперь с тобой!")
    end)
end
encounter("Fox",workspace.Grove,1.8)
encounter("Moth",workspace.Dusk,3.5)


-- Server-authoritative gatherables. Nodes stay in the shared world, while each
-- player's cooldown and permanent-claim state are stored independently in their profile.
-- The client hides a collected node locally; other players can still gather it.
local function createResourceFlower(def, position)
    local model = Instance.new("Model")
    model.Name = def.key
    model:SetAttribute("ResourceNodeId", def.key)
    model:SetAttribute("ResourceItemId", def.itemId)

    local function makePart(name, size, frame, color, material, shape)
        local part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Size = size
        part.CFrame = frame
        part.Color = color
        part.Material = material or Enum.Material.SmoothPlastic
        part.Shape = shape or Enum.PartType.Ball
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = model
        return part
    end

    local anchor = Instance.new("Part")
    anchor.Name = "PromptAnchor"
    anchor.Size = Vector3.new(0.55, 0.55, 0.55)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = true
    anchor.CFrame = CFrame.new()
    anchor.Parent = model
    model.PrimaryPart = anchor

    if def.visual == "tree" then
        makePart("Trunk", Vector3.new(1.25, 3.8, 1.25), CFrame.new(0, 1.8, 0), Color3.fromRGB(126, 88, 59), Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart("CanopyLower", Vector3.new(4.8, 3.4, 4.8), CFrame.new(0, 4.2, 0), Color3.fromRGB(91, 145, 91), Enum.Material.Grass)
        makePart("CanopyUpper", Vector3.new(3.6, 3.1, 3.6), CFrame.new(0, 6.1, 0), Color3.fromRGB(119, 169, 105), Enum.Material.Grass)
        makePart("HarvestMark", Vector3.new(0.55, 0.18, 0.55), CFrame.new(0, 2.15, -0.68), Color3.fromRGB(221, 179, 105), Enum.Material.Wood)
    elseif def.visual == "rock" or def.visual == "ore" then
        makePart("StoneMain", Vector3.new(3.4, 2.7, 2.8), CFrame.new(0, 1.15, 0), Color3.fromRGB(125, 132, 132), Enum.Material.Slate)
        makePart("StoneLeft", Vector3.new(1.8, 1.55, 1.8), CFrame.new(-1.35, 0.72, 0.8), Color3.fromRGB(151, 157, 154), Enum.Material.Rock)
        makePart("StoneRight", Vector3.new(1.65, 1.3, 1.6), CFrame.new(1.25, 0.62, -0.72), Color3.fromRGB(103, 112, 113), Enum.Material.Rock)
        makePart("OreGlint", Vector3.new(0.55, 0.22, 0.28), CFrame.new(0.35, 1.85, -1.15), def.visual == "ore" and Color3.fromRGB(242, 163, 91) or Color3.fromRGB(191, 202, 194), def.visual == "ore" and Enum.Material.Neon or Enum.Material.SmoothPlastic)
        if def.visual == "ore" then
            makePart("IronVein", Vector3.new(0.9, 0.32, 0.34), CFrame.new(-0.7, 1.35, -1.22), Color3.fromRGB(183, 104, 67), Enum.Material.Metal)
            makePart("IronVeinSmall", Vector3.new(0.48, 0.22, 0.25), CFrame.new(0.9, 1.15, -1.0), Color3.fromRGB(224, 145, 91), Enum.Material.Metal)
        end
    else
    makePart(
        "Stem",
        Vector3.new(0.95, 0.14, 0.14),
        CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(111, 164, 111),
        Enum.Material.Grass,
        Enum.PartType.Cylinder
    )

    for i = 1, 5 do
        local angle = (i - 1) * math.pi * 2 / 5
        local petalPosition = Vector3.new(math.cos(angle) * 0.48, 1.05, math.sin(angle) * 0.48)
        makePart(
            "Petal",
            Vector3.new(0.82, 0.32, 0.62),
            CFrame.new(petalPosition),
            def.petalColor,
            Enum.Material.SmoothPlastic
        )
    end

    local heart = makePart(
        "Heart",
        Vector3.new(0.42, 0.42, 0.42),
        CFrame.new(0, 1.12, 0),
        def.heartColor,
        Enum.Material.Neon
    )
    local glow = Instance.new("PointLight")
    glow.Color = def.heartColor
    glow.Range = 7
    glow.Brightness = 0.45
    glow.Parent = heart

    makePart(
        "LeafLeft",
        Vector3.new(0.7, 0.22, 0.42),
        CFrame.new(-0.38, 0.48, 0) * CFrame.Angles(0, 0, math.rad(-24)),
        Color3.fromRGB(143, 190, 128)
    )
    makePart(
        "LeafRight",
        Vector3.new(0.7, 0.22, 0.42),
        CFrame.new(0.38, 0.64, 0) * CFrame.Angles(0, 0, math.rad(24)),
        Color3.fromRGB(113, 164, 111)
    )

    end
    model:PivotTo(position)
    return model, anchor
end

local resourceDefinitions = {
    {
        key = "GroveSunPetal01",
        itemId = "SunPetal",
        displayName = "Солнечный лепесток",
        area = "Grove",
        offset = Vector3.new(-12, 0, 3),
        petalColor = Color3.fromRGB(244, 190, 111),
        heartColor = Color3.fromRGB(255, 226, 145),
        kind = "renewable",
        respawnSeconds = 300,
    },
    {
        key = "GroveSunPetal02",
        itemId = "SunPetal",
        displayName = "Солнечный лепесток",
        area = "Grove",
        offset = Vector3.new(13, 0, -7),
        petalColor = Color3.fromRGB(244, 190, 111),
        heartColor = Color3.fromRGB(255, 226, 145),
        kind = "renewable",
        respawnSeconds = 300,
    },
    {
        key = "DuskMoonPetal01",
        itemId = "MoonPetal",
        displayName = "Лунный лепесток",
        area = "Dusk",
        offset = Vector3.new(-11, 0, 5),
        petalColor = Color3.fromRGB(190, 164, 232),
        heartColor = Color3.fromRGB(218, 208, 255),
        kind = "renewable",
        respawnSeconds = 300,
    },
    {
        key = "DuskMoonPetal02",
        itemId = "MoonPetal",
        displayName = "Лунный лепесток",
        area = "Dusk",
        offset = Vector3.new(12, 0, -8),
        petalColor = Color3.fromRGB(190, 164, 232),
        heartColor = Color3.fromRGB(218, 208, 255),
        kind = "renewable",
        respawnSeconds = 300,
    },
    {
        key = "GroveWood01", amount = 2, requiredTool = "Axe", hitsRequired = 3,
        verb = "Ударить топором", itemId = "Wood", displayName = "Лесная древесина",
        area = "Grove", offset = Vector3.new(-34, 0, -25), visual = "tree",
        kind = "renewable", respawnSeconds = 300,
    },
    {
        key = "GroveWood02", amount = 2, requiredTool = "Axe", hitsRequired = 3,
        verb = "Ударить топором", itemId = "Wood", displayName = "Лесная древесина",
        area = "Grove", offset = Vector3.new(34, 0, 24), visual = "tree",
        kind = "renewable", respawnSeconds = 300,
    },
    {
        key = "DuskStone01", amount = 2, requiredTool = "Pickaxe", hitsRequired = 4,
        verb = "Ударить киркой", itemId = "Stone", displayName = "Каменная жила",
        area = "Dusk", offset = Vector3.new(-20, 0, -17), visual = "rock",
        kind = "renewable", respawnSeconds = 300,
    },
    {
        key = "DuskStone02", amount = 2, requiredTool = "Pickaxe", hitsRequired = 4,
        verb = "Ударить киркой", itemId = "Stone", displayName = "Каменная жила",
        area = "Dusk", offset = Vector3.new(20, 0, 17), visual = "rock",
        kind = "renewable", respawnSeconds = 300,
    },
    {
        key = "DuskIron01", amount = 2, requiredTool = "Pickaxe", hitsRequired = 5,
        verb = "Добыть железо", itemId = "IronOre", displayName = "Железная жила",
        area = "Dusk", offset = Vector3.new(-42, 0, 27), visual = "ore",
        kind = "renewable", respawnSeconds = 600,
    },
    {
        key = "DuskIron02", amount = 2, requiredTool = "Pickaxe", hitsRequired = 5,
        verb = "Добыть железо", itemId = "IronOre", displayName = "Железная жила",
        area = "Dusk", offset = Vector3.new(42, 0, -29), visual = "ore",
        kind = "renewable", respawnSeconds = 600,
    },
}

local function spawnResource(def)
    if not resourceNodeIds[def.key] then
        warn("Unknown resource node ID:", def.key)
        return
    end

    local island = workspace:FindFirstChild(def.area)
    local bank = island and island:FindFirstChild("Bank")
    if not island or not bank then return end

    local folder = island:FindFirstChild("ResourceNodes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ResourceNodes"
        folder.Parent = island
    end
    if folder:FindFirstChild(def.key) then return end

    local position = CFrame.new(
        bank.Position + Vector3.new(def.offset.X, bank.Size.Y / 2 + 0.18, def.offset.Z)
    )
    local model, anchor = createResourceFlower(def, position)
    model.Parent = folder

    prompt(anchor, def.displayName, def.verb or "Собрать", function(player)
        local session = sessions[player]
        if not session or not player:GetAttribute("Ready") then return end

        if def.requiredTool then
            local equippedTool = findPlayerTool(player, def.requiredTool)
            if session.equippedTool ~= def.requiredTool or not equippedTool or equippedTool.Parent ~= player.Character then
                syncTools(player)
                return tip(player, def.requiredTool == "Axe" and "Возьми топор в руки, чтобы рубить дерево." or "Возьми кирку в руки, чтобы добывать камень.")
            end
        end

        local now = os.time()
        local nextReadyAt
        if def.kind == "unique" then
            if session.collectedNodes[def.key] then
                event:FireClient(player, "ResourcePicked", {
                    nodeId = def.key,
                    unique = true,
                })
                return tip(player, "Эта находка уже есть в твоей коллекции.")
            end
            session.collectedNodes[def.key] = true
        else
            local readyAt = session.resourceCooldowns[def.key] or 0
            if readyAt > now then
                event:FireClient(player, "ResourcePicked", {
                    nodeId = def.key,
                    readyAt = readyAt,
                })
                local remaining = readyAt - now
                return tip(player, "Цветок снова расцветёт через " .. tostring(math.ceil(remaining / 60)) .. " мин.")
            end
            local hitsRequired = math.clamp(math.floor(tonumber(def.hitsRequired) or 1), 1, 10)
            if def.requiredTool and (session.toolLevels[def.requiredTool] or 1) >= 2 then
                hitsRequired = math.max(1, hitsRequired - 1)
            end
            if hitsRequired > 1 then
                local hitNow = os.clock()
                local lastHitAt = session.resourceHitCooldowns[def.key] or 0
                if hitNow - lastHitAt < 0.4 then return end
                session.resourceHitCooldowns[def.key] = hitNow
                local hits = math.min(hitsRequired, (session.resourceHits[def.key] or 0) + 1)
                session.resourceHits[def.key] = hits
                event:FireClient(player, "ResourceHit", {nodeId = def.key, hits = hits, maxHits = hitsRequired})
                if hits < hitsRequired then
                    return tip(player, def.displayName .. ": удар " .. tostring(hits) .. "/" .. tostring(hitsRequired))
                end
                session.resourceHits[def.key] = nil
            end
            nextReadyAt = now + math.max(1, math.floor(def.respawnSeconds or 300))
            session.resourceCooldowns[def.key] = nextReadyAt
        end

        local rewardAmount = math.max(1, math.floor(tonumber(def.amount) or 1))
        session.inventory[def.itemId] = (session.inventory[def.itemId] or 0) + rewardAmount
        syncInventory(player)
        event:FireClient(player, "ResourcePicked", {
            nodeId = def.key,
            unique = def.kind == "unique",
            readyAt = nextReadyAt,
        })
        tip(player, "Получено: " .. def.displayName .. " ×" .. tostring(rewardAmount))

        if session.online and not save(player) then
            warn("Resource pickup save will be retried:", player.UserId, def.key)
            tip(player, "Предмет получен. Сохранение временно задерживается и будет повторено автоматически.")
        end
    end)
end

for _, definition in resourceDefinitions do
    spawnResource(definition)
end

prompt(workspace.Grove.Trail,"Следы в траве","Попросить лисёнка искать",startFoxSearch)

prompt(workspace.Grove.Driftwood,"Коряга на берегу","Искать сухие ветви",function(player)
    if not player:GetAttribute("Flower") then return tip(player,"Сначала вырасти лунный цветок у дома.") end
    if player:GetAttribute("Timber") then return tip(player,"Ветви уже собраны. Площадка рядом с домом.") end
    if player:GetAttribute("Companion") ~= "Fox" then return tip(player,"Позови лисёнка. Он найдёт крепкие ветви.") end
    player:SetAttribute("Timber",true)
    tip(player,"Лисёнок нашёл ветви для садового фонаря!")
end)

-- First-clear forest trial: only players who defeated both enemy archetypes
-- may enter the chamber. Prompts have independent distance/ready checks server-side.
local trial = workspace:FindFirstChild("CombatTrainingGlade")
local trialChamber = trial and trial:FindFirstChild("ForestTrialChamber")
local trialArena = trial and trial:FindFirstChild("TrainingRing")
local trialBusy = {}
local trialPuzzleProgress = {}
local trialPuzzleComplete = {}
local TRIAL_RUNE_SEQUENCE = {"ForestTrialRuneMoon", "ForestTrialRuneDawn", "ForestTrialRuneTide"}

local function validTrialInteraction(player, anchorPart)
    local session = sessions[player]
    if not session or player:GetAttribute("Ready") ~= true then return nil end
    if not anchorPart or not anchorPart:IsA("BasePart") then return nil end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then return nil end
    if (root.Position - anchorPart.Position).Magnitude > 13 then return nil end
    return session, character
end

local function hasCompletedForestTrial(session)
    return session.completedCombatEncounters.GroveGrunt01 == true
        and session.completedCombatEncounters.GroveScout02 == true
end

local function connectTrialPrompt(anchorPart, callback)
    local interaction = anchorPart and anchorPart:FindFirstChildOfClass("ProximityPrompt")
    if interaction then
        interaction.Triggered:Connect(callback)
    else
        warn("Forest trial interaction is missing:", anchorPart and anchorPart.Name)
    end
end

local gatePart = trialArena and trialArena:FindFirstChild("ForestTrialGate")
local arrivalPart = trialChamber and trialChamber:FindFirstChild("ForestTrialArrival")
local returnPart = trialChamber and trialChamber:FindFirstChild("ForestTrialReturn")
local chestPart = trialChamber and trialChamber:FindFirstChild("ForestTrialChest")
local runeParts = {}
for _, runeName in TRIAL_RUNE_SEQUENCE do
    runeParts[runeName] = trialChamber and trialChamber:FindFirstChild(runeName)
end

for expectedIndex, runeName in TRIAL_RUNE_SEQUENCE do
    local runePart = runeParts[runeName]
    if runePart then
        connectTrialPrompt(runePart, function(player)
            local session = validTrialInteraction(player, runePart)
            if not session then return end
            if not hasCompletedForestTrial(session) then
                return tip(player, "Сначала пройди испытание двух стражей.")
            end
            if trialPuzzleComplete[player] then
                return tip(player, "Руны уже пробуждены. Сундук ждёт тебя!")
            end

            local now = os.clock()
            local progress = trialPuzzleProgress[player]
            if not progress or now - progress.lastAt > 20 then
                progress = {nextIndex = 1, lastAt = now}
                trialPuzzleProgress[player] = progress
            end
            progress.lastAt = now

            if runeName ~= TRIAL_RUNE_SEQUENCE[progress.nextIndex] then
                progress.nextIndex = 1
                if runeName == TRIAL_RUNE_SEQUENCE[1] then
                    progress.nextIndex = 2
                    tip(player, "Начало верное! Луна пробудилась. Теперь Рассвет.")
                else
                    tip(player, "Руны погасли. Подсказка на табличке поможет вспомнить порядок.")
                end
                return
            end

            progress.nextIndex += 1
            if progress.nextIndex > #TRIAL_RUNE_SEQUENCE then
                trialPuzzleComplete[player] = true
                trialPuzzleProgress[player] = nil
                tip(player, "Все три руны пробуждены! Сундук открыт.")
            else
                tip(player, "Руна пробуждена. Продолжай последовательность.")
            end
        end)
    else
        warn("Forest trial puzzle rune is missing:", runeName)
    end
end


if gatePart and arrivalPart then
    connectTrialPrompt(gatePart, function(player)
        local session, character = validTrialInteraction(player, gatePart)
        if not session then return end
        if not hasCompletedForestTrial(session) then
            return tip(player, "Сначала победи Корневого стража и Мшистого разведчика!")
        end
        character:PivotTo(arrivalPart.CFrame * CFrame.new(0, 4, 0))
        tip(player, "Тайная комната открыта. Найди сундук испытания!")
    end)
end

if returnPart and gatePart then
    connectTrialPrompt(returnPart, function(player)
        local session, character = validTrialInteraction(player, returnPart)
        if not session then return end
        character:PivotTo(gatePart.CFrame * CFrame.new(0, 0, -6))
    end)
end

if chestPart then
    connectTrialPrompt(chestPart, function(player)
        local session = validTrialInteraction(player, chestPart)
        if not session then return end
        if not hasCompletedForestTrial(session) then
            return tip(player, "Испытание ещё не завершено.")
        end
        if not trialPuzzleComplete[player] then
            return tip(player, "Сначала разбуди руны в порядке: Луна, Рассвет, Прилив.")
        end
        if session.completedCombatEncounters.GroveTrialChest01 then
            return tip(player, "Ты уже получил награду этого испытания.")
        end
        if trialBusy[player] then return end
        trialBusy[player] = true
        local ok, granted = pcall(function()
            return combatRewardFunction:Invoke(player, "GroveTrialChest01")
        end)
        trialBusy[player] = nil
        if not ok or granted ~= true then
            tip(player, "Не удалось сохранить награду. Попробуй ещё раз.")
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    trialBusy[player] = nil
    trialPuzzleProgress[player] = nil
    trialPuzzleComplete[player] = nil
end)

-- Rootvault expedition: unlock, traversal, trap damage and one-time personal relic cache.
local rootvault = trial and trial:FindFirstChild("RootvaultDungeon")
local rootvaultEntryRoom = rootvault and rootvault:FindFirstChild("RootvaultEntryRoom")
local rootvaultMechanismRoom = rootvault and rootvault:FindFirstChild("RootvaultMechanismRoom")
local rootvaultRewardRoom = rootvault and rootvault:FindFirstChild("RootvaultRewardRoom")
local rootvaultInside = {}
local rootvaultLeverActivated = {}
local rootvaultTrapCooldown = {}
local rootvaultChestBusy = {}

local rootvaultEntrance = trialChamber and trialChamber:FindFirstChild("RootvaultEntrance")
local rootvaultArrival = rootvaultEntryRoom and rootvaultEntryRoom:FindFirstChild("RootvaultArrival")
local rootvaultEntryReturn = rootvaultEntryRoom and rootvaultEntryRoom:FindFirstChild("RootvaultReturn")
local rootvaultLever = rootvaultMechanismRoom and rootvaultMechanismRoom:FindFirstChild("RootvaultLeverBase")
local rootvaultDoorPrompt = rootvaultMechanismRoom and rootvaultMechanismRoom:FindFirstChild("RootvaultDoorPrompt")
local rootvaultMechanismExit = rootvaultMechanismRoom and rootvaultMechanismRoom:FindFirstChild("RootvaultMechanismExit")
local rootvaultRewardReturn = rootvaultRewardRoom and rootvaultRewardRoom:FindFirstChild("RootvaultReturnDoorPrompt")
local rootvaultChest = rootvaultRewardRoom and rootvaultRewardRoom:FindFirstChild("RootvaultRewardChest")
local rootvaultSealedDoor = rootvaultMechanismRoom and rootvaultMechanismRoom:FindFirstChild("RootvaultSealedDoor")

local function validRootvaultInteraction(player, anchorPart)
    if not rootvaultInside[player] then return nil end
    return validTrialInteraction(player, anchorPart)
end

if rootvaultEntrance and rootvaultArrival then
    connectTrialPrompt(rootvaultEntrance, function(player)
        local session, character = validTrialInteraction(player, rootvaultEntrance)
        if not session then return end
        if session.completedCombatEncounters.GroveTrialChest01 ~= true then
            return tip(player, "Сначала заверши тайник с тремя рунами и забери его награду.")
        end
        rootvaultInside[player] = true
        rootvaultLeverActivated[player] = nil
        player:SetAttribute("InRootvault", true)
        character:PivotTo(rootvaultArrival.CFrame * CFrame.new(0, 4, 0))
        tip(player, "Хранилище корней: найди механизм и открой путь к реликвии!")
    end)
end

if rootvaultEntryReturn and rootvaultEntrance then
    connectTrialPrompt(rootvaultEntryReturn, function(player)
        local session, character = validRootvaultInteraction(player, rootvaultEntryReturn)
        if not session then return end
        rootvaultInside[player] = nil
        rootvaultLeverActivated[player] = nil
        player:SetAttribute("InRootvault", false)
        character:PivotTo(rootvaultEntrance.CFrame * CFrame.new(0, 0, -7))
    end)
end

if rootvaultLever then
    connectTrialPrompt(rootvaultLever, function(player)
        local session = validRootvaultInteraction(player, rootvaultLever)
        if not session then return end
        if rootvaultLeverActivated[player] then
            return tip(player, "Механизм уже активирован. Дверь хранилища ждёт тебя.")
        end
        rootvaultLeverActivated[player] = true
        tip(player, "Механизм загудел! Печать хранилища ослабла.")
    end)
end

if rootvaultDoorPrompt and rootvaultRewardRoom then
    connectTrialPrompt(rootvaultDoorPrompt, function(player)
        local session, character = validRootvaultInteraction(player, rootvaultDoorPrompt)
        if not session then return end
        if (session.inventory.RootvaultKey or 0) < 1 then
            return tip(player, "Печать не поддаётся. Победи Стража хранилища и забери ключ.")
        end
        if not rootvaultLeverActivated[player] then
            return tip(player, "Сначала активируй древний рычаг.")
        end
        character:PivotTo(rootvaultRewardRoom:GetPivot() * CFrame.new(0, 4, -5))
        tip(player, "Ты открыл путь в зал реликвии!")
    end)
end

if rootvaultRewardReturn and rootvaultMechanismRoom then
    connectTrialPrompt(rootvaultRewardReturn, function(player)
        local session, character = validRootvaultInteraction(player, rootvaultRewardReturn)
        if not session then return end
        character:PivotTo(rootvaultMechanismRoom:GetPivot() * CFrame.new(0, 4, 5))
    end)
end

if rootvaultMechanismExit and rootvaultEntrance then
    connectTrialPrompt(rootvaultMechanismExit, function(player)
        local session, character = validRootvaultInteraction(player, rootvaultMechanismExit)
        if not session then return end
        rootvaultInside[player] = nil
        rootvaultLeverActivated[player] = nil
        player:SetAttribute("InRootvault", false)
        character:PivotTo(rootvaultEntrance.CFrame * CFrame.new(0, 0, -7))
    end)
end

if rootvaultChest then
    connectTrialPrompt(rootvaultChest, function(player)
        local session = validRootvaultInteraction(player, rootvaultChest)
        if not session then return end
        if not rootvaultLeverActivated[player] then
            return tip(player, "Сначала активируй механизм хранилища.")
        end
        if session.completedCombatEncounters.RootvaultSealKeeper01 ~= true then
            return tip(player, "Реликвию охраняет Страж печатей. Победи его, чтобы открыть сундук.")
        end
        if session.completedCombatEncounters.RootvaultChest01 then
            return tip(player, "Реликвия этого хранилища уже у тебя.")
        end
        if rootvaultChestBusy[player] then return end
        rootvaultChestBusy[player] = true
        local ok, granted = pcall(function()
            return combatRewardFunction:Invoke(player, "RootvaultChest01")
        end)
        rootvaultChestBusy[player] = nil
        if not ok or granted ~= true then
            tip(player, "Не удалось сохранить реликвию. Попробуй ещё раз.")
        else
            tip(player, "Хранилище покорено! Получено: Железная руда ×3.")
        end
    end)
end

for _, trap in rootvault and rootvault:GetChildren() or {} do
    if trap:IsA("BasePart") and trap:GetAttribute("TrapDamage") then
        trap.Touched:Connect(function(hit)
            local character = hit:FindFirstAncestorOfClass("Model")
            local player = character and Players:GetPlayerFromCharacter(character)
            if not player or not rootvaultInside[player] then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end
            local now = os.clock()
            if rootvaultTrapCooldown[player] and now - rootvaultTrapCooldown[player] < 1.25 then return end
            rootvaultTrapCooldown[player] = now
            humanoid:TakeDamage(math.clamp(tonumber(trap:GetAttribute("TrapDamage")) or 10, 1, 20))
            tip(player, "Ловушка! Следи за светящимися плитами.")
        end)
    end
end

Players.PlayerRemoving:Connect(function(player)
    rootvaultInside[player] = nil
    rootvaultLeverActivated[player] = nil
    rootvaultTrapCooldown[player] = nil
    rootvaultChestBusy[player] = nil
end)

-- All islands are fixed. Eight personal bridges lead into the shared Grove hub.

-- Each player owns a distinct fixed island; every personal interaction is validated against OwnerUserId.
Players.PlayerAdded:Connect(init)
for _, player in Players:GetPlayers() do task.spawn(init, player) end
Players.PlayerRemoving:Connect(function(player)
    save(player)
    local session = sessions[player]
    if session then
        if session.homeIsland then
            session.homeIsland:Destroy()
        end
        if session.homeSlot then
            occupiedHomeSlots[session.homeSlot] = nil
        end
    end
    sessions[player] = nil
end)
game:BindToClose(function()
    local pending = 0
    for _, player in Players:GetPlayers() do
        pending += 1
        task.spawn(function() save(player) pending -= 1 end)
    end
    while pending > 0 do task.wait() end
end)
task.spawn(function()
    while task.wait(60) do
        for _, player in Players:GetPlayers() do task.spawn(save, player) end
    end
end)
task.spawn(function()
    while task.wait(5) do
        for player, session in sessions do
            if player.Parent and session.cityModel then
                refreshFarmCity(player, session.cityModel)
            end
        end
    end
end)

