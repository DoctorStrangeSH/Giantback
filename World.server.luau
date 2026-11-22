local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
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
local inventoryKeys = {"SunPetal", "MoonPetal", "CarrotSeed", "Carrot", "StrawberrySeed", "Strawberry", "PumpkinSeed", "Pumpkin", "CabbageSeed", "Cabbage", "Wood", "Stone", "MoonSeed", "StarShard"}
local foxCacheIds = {"FoxCache01", "FoxCache02", "FoxCache03"}
local foxCacheIdSet = {}
for _, cacheId in foxCacheIds do
    foxCacheIdSet[cacheId] = true
end
local FOX_SCOUT_COOLDOWN_SECONDS = 120
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

local function save(player)
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

        local citySnapshot = normalizeCity(session.city)
        local foxScoutSnapshot = {
            activeCacheId = foxCacheIdSet[session.foxCacheActiveId] and session.foxCacheActiveId or nil,
            readyAt = math.max(0, math.floor(tonumber(session.foxSearchReadyAt) or 0)),
            searchCount = math.max(0, math.floor(tonumber(session.foxSearchCount) or 0)),
        }

        local ok, err = pcall(function()
            store:UpdateAsync(tostring(player.UserId), function(old)
                if type(old) ~= "table" then old = {} end
                for _, key in progress do
                    old[key] = old[key] == true or snapshot[key]
                end
                old.schemaVersion = 6

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

                -- Schema v5 moves the old city payload into the permanent island record.
                -- Schema v6 adds persistent companion scouting and the MoonSeed inventory item.
                -- Keep this migration idempotent and preserve existing farm/building progress.
                local savedIsland = type(old.island) == "table" and old.island
                    or (type(old.city) == "table" and old.city or {})
                savedIsland.level = citySnapshot.level
                local savedFarm = type(savedIsland.farm) == "table" and savedIsland.farm or {}
                savedFarm.level = citySnapshot.farm.level
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
        resourceCooldowns = {},
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
            session.city = normalizeCity(type(data.island) == "table" and data.island or data.city)

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
        end
        if not ok then player:SetAttribute("OfflineAlbum", true) end
    else
        player:SetAttribute("OfflineAlbum", true)
    end

    syncInventory(player)
    syncFarm(player)
    syncBridge(player)
    syncFoxScout(player)
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
    session.foxSearchReadyAt = os.time() + FOX_SCOUT_COOLDOWN_SECONDS
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
        syncFarm(player)
        tip(player, "Выбрано для посадки: " .. definition.displayName .. ". Подойди к свободной грядке.")
        return
    end

    if pets[action] and player:GetAttribute(action) then
        player:SetAttribute("Companion",action)
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

    if not cropVisual then
        cropVisual = Instance.new("Model")
        cropVisual.Name = "CropVisual"
        cropVisual.Parent = plotModel
        makeFarmVisualPart(cropVisual, "Stem", Vector3.new(0.2, 0.4, 0.2), CFrame.new(), Color3.fromRGB(101, 158, 89), Enum.PartType.Cylinder)
        makeFarmVisualPart(cropVisual, "LeafLeft", Vector3.new(0.65, 0.16, 0.32), CFrame.new(), Color3.fromRGB(120, 181, 101), Enum.PartType.Ball)
        makeFarmVisualPart(cropVisual, "LeafRight", Vector3.new(0.65, 0.16, 0.32), CFrame.new(), Color3.fromRGB(94, 151, 86), Enum.PartType.Ball)
        makeFarmVisualPart(cropVisual, "Root", Vector3.new(0.8, 0.34, 0.34), CFrame.new(), Color3.fromRGB(231, 139, 75), Enum.PartType.Cylinder)
    end

    local now = os.time()
    local duration = math.max(1, state.readyAt - state.plantedAt)
    local growth = math.clamp((now - state.plantedAt) / duration, 0, 1)
    local ready = now >= state.readyAt
    local stem = cropVisual:FindFirstChild("Stem")
    local leftLeaf = cropVisual:FindFirstChild("LeafLeft")
    local rightLeaf = cropVisual:FindFirstChild("LeafRight")
    local root = cropVisual:FindFirstChild("Root")

    if soil and stem and leftLeaf and rightLeaf and root then
        local height = 0.25 + growth * 0.62
        stem.Size = Vector3.new(height, 0.2, 0.2)
        stem.CFrame = soil.CFrame * CFrame.new(0, soil.Size.Y / 2 + height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
        leftLeaf.Size = Vector3.new(0.55 + growth * 0.2, 0.16, 0.3 + growth * 0.12)
        rightLeaf.Size = leftLeaf.Size
        leftLeaf.CFrame = soil.CFrame * CFrame.new(-0.34, soil.Size.Y / 2 + height * 0.8, 0) * CFrame.Angles(0, 0, math.rad(-24))
        rightLeaf.CFrame = soil.CFrame * CFrame.new(0.34, soil.Size.Y / 2 + height * 0.8, 0) * CFrame.Angles(0, 0, math.rad(24))
        root.Transparency = ready and 0 or 1
        root.CFrame = soil.CFrame * CFrame.new(0, soil.Size.Y / 2 + 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
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

    prompt(anchor, def.displayName, "Собрать", function(player)
        local session = sessions[player]
        if not session or not player:GetAttribute("Ready") then return end

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
            nextReadyAt = now + math.max(1, math.floor(def.respawnSeconds or 300))
            session.resourceCooldowns[def.key] = nextReadyAt
        end

        session.inventory[def.itemId] = (session.inventory[def.itemId] or 0) + 1
        syncInventory(player)
        event:FireClient(player, "ResourcePicked", {
            nodeId = def.key,
            unique = def.kind == "unique",
            readyAt = nextReadyAt,
        })
        tip(player, "Получено: " .. def.displayName .. " ×1")

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

