local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
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
local pets = {Fox = "Лисёнок-корешок", Moth = "Лунная моль", CrystalWisp = "Кристальный светляк"}
local progress = {"Fox", "Moth", "CrystalWisp", "Seed", "MoonBloom", "MoonGateTrace", "MoonGateOpen", "MoonRelic", "CrystalGrottoDiscovered", "CrystalHeart", "CrystalRunes", "CrystalCache", "CrystalEchoDiscovered", "PrismSeedFound", "Flower", "Timber", "Lantern", "Lit"}
local inventoryKeys = {"SunPetal", "MoonPetal", "CarrotSeed", "Carrot", "StrawberrySeed", "Strawberry", "PumpkinSeed", "Pumpkin", "CabbageSeed", "Cabbage", "Wood", "Stone", "IronOre", "IronIngot", "MoonSeed", "StarShard", "RootvaultKey", "RootvaultEssence", "RootvaultSigil", "CrystalShard", "CrystalSigil", "PrismSeed"}
local toolIds = {Axe = true, Pickaxe = true, Sword = true}
local swordRecipe = {IronIngot = 2, Wood = 6}
local combatRewardDefinitions = {
    GroveGrunt01 = {itemId = "Wood", amount = 3},
    GroveScout02 = {itemId = "SunPetal", amount = 2},
    GroveMossling01 = {itemId = "Stone", amount = 2},
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
local warehouseItemIds = {"Wood", "Stone", "IronOre", "IronIngot", "Carrot", "Strawberry", "Pumpkin", "Cabbage"}
local WAREHOUSE_CAPACITY = 120
local cropSalePrices = {Carrot = 4, Strawberry = 7, Pumpkin = 12, Cabbage = 9}
local seedShopOffers = {
    Carrot = {amount = 3, cost = 12},
    Strawberry = {amount = 3, cost = 21},
    Pumpkin = {amount = 2, cost = 20},
    Cabbage = {amount = 2, cost = 16},
}
local MAX_SEED_STACK = 999
local farmUpgradeCosts = {[2] = 60, [3] = 150}
local MAX_COINS = 2000000000
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
    CrystalGrottoLumen01 = true,
    CrystalGrottoLumen02 = true,
    CrystalGrottoPrismVein01 = true,
    CrystalGrottoPrismVein02 = true,
}
local sessions = {}
local createPersonalCity
local applyHomeBridgeState
local placeIslandDecoration
local removeIslandDecoration

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
        storage = {},
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
    local rawStorage = type(raw.storage) == "table" and raw.storage or {}
    for _, itemId in ipairs(warehouseItemIds) do
        city.storage[itemId] = math.clamp(math.floor(tonumber(rawStorage[itemId]) or 0), 0, WAREHOUSE_CAPACITY)
    end
    local rawBridges = type(raw.bridges) == "table" and raw.bridges or {}
    city.bridges.homeToGrove = rawBridges.homeToGrove == true
    local rawBuildings = type(raw.buildings) == "table" and raw.buildings or {}
    for _, saved in ipairs(rawBuildings) do
        if #city.buildings >= 24 then break end
        if type(saved) == "table" and (saved.id == "Path" or saved.id == "FlowerBed" or saved.id == "Cottage" or saved.id == "Warehouse") then
            local x = tonumber(saved.x)
            local z = tonumber(saved.z)
            local rotation = tonumber(saved.rotation) or 0
            if x and z and x == x and z == z and math.abs(x) < 100 and math.abs(z) < 100 then
                table.insert(city.buildings, {
                    id = saved.id,
                    x = math.clamp(math.floor(x / 4 + 0.5) * 4, 0, 12),
                    z = math.clamp(math.floor(z / 4 + 0.5) * 4, -4, 4),
                    rotation = (math.floor(rotation / 90 + 0.5) % 4) * 90,
                })
            end
        end
    end
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
    player:SetAttribute("Coins", math.clamp(math.floor(tonumber(session.coins) or 0), 0, MAX_COINS))
    local storedTotal = 0
    for _, itemId in ipairs(warehouseItemIds) do
        local amount = session.city.storage[itemId] or 0
        storedTotal += amount
        player:SetAttribute("Warehouse_" .. itemId, amount)
    end
    player:SetAttribute("Warehouse_Used", storedTotal)
    player:SetAttribute("Warehouse_Capacity", WAREHOUSE_CAPACITY)
    player:SetAttribute("Warehouse_Built", table.find((function()
        local ids = {}
        for _, building in ipairs(session.city.buildings) do table.insert(ids, building.id) end
        return ids
    end)(), "Warehouse") ~= nil)
    player:SetAttribute("City_DecorationCount", #session.city.buildings)
    local occupiedCells = {}
    for _, decoration in ipairs(session.city.buildings) do
        table.insert(occupiedCells, tostring(decoration.x) .. "," .. tostring(decoration.z))
    end
    player:SetAttribute("City_BuildingCells", table.concat(occupiedCells, ";"))
    for index = 1, 12 do
        local decoration = session.city.buildings[index]
        player:SetAttribute("City_Decoration_" .. tostring(index) .. "_Id", decoration and decoration.id or "")
        player:SetAttribute("City_Decoration_" .. tostring(index) .. "_X", decoration and decoration.x or 0)
        player:SetAttribute("City_Decoration_" .. tostring(index) .. "_Z", decoration and decoration.z or 0)
        player:SetAttribute("City_Decoration_" .. tostring(index) .. "_Rotation", decoration and decoration.rotation or 0)
    end
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

local addDailyQuestProgress

local function sellIslandHarvest(player, ownerUserId)
    if player.UserId ~= ownerUserId then return tip(player, "Этот рынок принадлежит другому игроку.") end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if not session.online then return tip(player, "Рынок временно не работает: сохранение профиля недоступно.") end
    if session.economyBusy then return end
    session.economyBusy = true

    local sold = {}
    local totalCoins = 0
    local totalItems = 0
    for cropId, price in pairs(cropSalePrices) do
        local amount = math.max(0, math.floor(tonumber(session.inventory[cropId]) or 0))
        if amount > 0 then
            sold[cropId] = amount
            totalItems += amount
            totalCoins += amount * price
        end
    end
    if totalItems == 0 then
        session.economyBusy = false
        return tip(player, "Пока нечего продавать. Сначала собери урожай на грядках.")
    end

    local previousCoins = session.coins or 0
    local credited = math.min(totalCoins, MAX_COINS - previousCoins)
    if credited <= 0 then
        session.economyBusy = false
        return tip(player, "Кошелёк полон. Потрать немного монет перед следующей продажей.")
    end

    local remainingCredit = credited
    totalItems = 0
    for cropId, amount in pairs(sold) do
        local price = cropSalePrices[cropId]
        local sellAmount = math.min(amount, math.floor(remainingCredit / price))
        if sellAmount > 0 then
            session.inventory[cropId] -= sellAmount
            remainingCredit -= sellAmount * price
            sold[cropId] = sellAmount
            totalItems += sellAmount
        else
            sold[cropId] = 0
        end
    end
    session.coins = previousCoins + credited
    syncInventory(player)
    syncFarm(player)

    if not save(player) then
        for cropId, amount in pairs(sold) do
            session.inventory[cropId] = (session.inventory[cropId] or 0) + amount
        end
        session.coins = previousCoins
        syncInventory(player)
        syncFarm(player)
        session.economyBusy = false
        return tip(player, "Не удалось сохранить продажу. Урожай возвращён в рюкзак.")
    end

    session.economyBusy = false
    addDailyQuestProgress(player, "Sell", totalItems)
    tip(player, "Продано урожая: " .. tostring(totalItems) .. " шт. Получено " .. tostring(credited) .. " монет.")
end

local function buyFarmSeeds(player, cropId)
    local session = sessions[player]
    local offer = seedShopOffers[cropId]
    local definition = cropDefinitions[cropId]
    if not session or not offer or not definition then return end
    if not player:GetAttribute("Ready") then return end
    if not session.online then
        return tip(player, "Магазин временно недоступен: сохранение профиля не работает.")
    end
    if session.economyBusy then return end

    local seedItemId = definition.seedItemId
    local currentSeeds = math.max(0, math.floor(tonumber(session.inventory[seedItemId]) or 0))
    if currentSeeds + offer.amount > MAX_SEED_STACK then
        return tip(player, "В рюкзаке уже слишком много этих семян. Сначала посади часть.")
    end
    local currentCoins = math.clamp(math.floor(tonumber(session.coins) or 0), 0, MAX_COINS)
    if currentCoins < offer.cost then
        return tip(player, "Не хватает монет: нужно " .. tostring(offer.cost) .. ", у тебя " .. tostring(currentCoins) .. ".")
    end

    session.economyBusy = true
    session.coins = currentCoins - offer.cost
    session.inventory[seedItemId] = currentSeeds + offer.amount
    syncInventory(player)
    syncFarm(player)

    if not save(player) then
        session.coins = currentCoins
        session.inventory[seedItemId] = currentSeeds
        syncInventory(player)
        syncFarm(player)
        session.economyBusy = false
        return tip(player, "Покупка не сохранена. Монеты возвращены, семена не списаны.")
    end

    session.economyBusy = false
    tip(player, "Куплено: " .. tostring(offer.amount) .. " • " .. definition.displayName .. ".")
end

local function upgradeFarm(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if not session.online then
        return tip(player, "Улучшение фермы временно недоступно: сохранение профиля не работает.")
    end
    if session.economyBusy then return end

    local currentLevel = math.clamp(math.floor(tonumber(session.city.farm.level) or 1), 1, 3)
    if currentLevel >= 3 then
        return tip(player, "Ферма уже улучшена до максимального уровня.")
    end
    local nextLevel = currentLevel + 1
    local cost = farmUpgradeCosts[nextLevel]
    local currentCoins = math.clamp(math.floor(tonumber(session.coins) or 0), 0, MAX_COINS)
    if currentCoins < cost then
        return tip(player, "Для улучшения фермы нужно " .. tostring(cost) .. " монет. У тебя " .. tostring(currentCoins) .. ".")
    end

    session.economyBusy = true
    session.coins = currentCoins - cost
    session.city.farm.level = nextLevel
    syncFarm(player)

    if not save(player) then
        session.coins = currentCoins
        session.city.farm.level = currentLevel
        syncFarm(player)
        session.economyBusy = false
        return tip(player, "Улучшение не сохранено. Монеты возвращены, уровень фермы восстановлен.")
    end

    session.economyBusy = false
    local unlocked = nextLevel == 2 and "Открыты грядки №2 и №3!" or "Открыта грядка №4!"
    tip(player, "Ферма улучшена до уровня " .. tostring(nextLevel) .. ". " .. unlocked)
end

local function useWarehouse(player, ownerUserId, action)
    if player.UserId ~= ownerUserId then return tip(player, "Этот склад принадлежит другому игроку.") end
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    local warehouseBuilt = false
    for _, building in ipairs(session.city.buildings) do
        if building.id == "Warehouse" then warehouseBuilt = true; break end
    end
    if not warehouseBuilt then return tip(player, "Сначала построй склад на своём острове.") end
    local storage = session.city.storage
    local changed = 0
    if action == "Deposit" then
        local used = 0
        for _, itemId in ipairs(warehouseItemIds) do used += storage[itemId] or 0 end
        local remaining = WAREHOUSE_CAPACITY - used
        for _, itemId in ipairs(warehouseItemIds) do
            if remaining <= 0 then break end
            local available = math.max(0, math.floor(session.inventory[itemId] or 0))
            local amount = math.min(available, remaining)
            if amount > 0 then
                session.inventory[itemId] -= amount
                storage[itemId] = (storage[itemId] or 0) + amount
                remaining -= amount
                changed += amount
            end
        end
        if changed == 0 then return tip(player, used >= WAREHOUSE_CAPACITY and "Склад заполнен." or "Нет материалов для хранения.") end
        tip(player, "На склад помещено предметов: " .. tostring(changed) .. ".")
    elseif action == "Withdraw" then
        for _, itemId in ipairs(warehouseItemIds) do
            local amount = math.max(0, math.floor(storage[itemId] or 0))
            if amount > 0 then
                session.inventory[itemId] = (session.inventory[itemId] or 0) + amount
                storage[itemId] = 0
                changed += amount
            end
        end
        if changed == 0 then return tip(player, "Склад пока пуст.") end
        tip(player, "Со склада забрано предметов: " .. tostring(changed) .. ".")
    else
        return
    end
    syncInventory(player)
    syncFarm(player)
    if session.online then save(player) end
end

local COMPANION_IDS = {"Fox", "Moth", "CrystalWisp"}
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
    CrystalWisp = "Любопытство",
}

local companionPersonalities = {"Любопытный", "Озорной", "Смелый", "Застенчивый"}

local companionPersonalitySet = {}
for _, personality in companionPersonalities do
    companionPersonalitySet[personality] = true
end

local function getDefaultCompanionPersonality(userId, companionId)
    local speciesOffset = companionId == "Moth" and 2 or companionId == "CrystalWisp" and 4 or 0
    local index = ((math.abs(userId) + speciesOffset) % #companionPersonalities) + 1
    return companionPersonalities[index]
end

local function normalizeCompanionPersonalities(raw, userId)
    raw = type(raw) == "table" and raw or {}
    local result = {}
    for _, id in COMPANION_IDS do
        local saved = raw[id]
        result[id] = type(saved) == "string" and companionPersonalitySet[saved]
            and saved or getDefaultCompanionPersonality(userId, id)
    end
    return result
end

local function setCompanionMood(player, companionId, mood)
    local session = sessions[player]
    if not session or table.find(COMPANION_IDS, companionId) == nil then return end
    session.companionMood = session.companionMood or {}
    session.companionMood[companionId] = mood
    player:SetAttribute("Companion_" .. companionId .. "_Mood", mood)
end

local companionMutationDefinitions = {
    Fox = {
        {id = "Mossback", name = "Мшистый", rarity = "Необычный", weight = 140, biome = "Grove"},
        {id = "Sunblessed", name = "Солнечный", rarity = "Редкий", weight = 48, biome = "Grove"},
        {id = "Prismtail", name = "Призматический", rarity = "Эпический", weight = 11, biome = "Grove"},
        {id = "Elderwood", name = "Древесный дух", rarity = "Легендарный", weight = 1, biome = "Grove"},
    },
    Moth = {
        {id = "Moonveil", name = "Лунная вуаль", rarity = "Необычный", weight = 140, biome = "Dusk"},
        {id = "Stardust", name = "Звёздная пыль", rarity = "Редкий", weight = 48, biome = "Dusk"},
        {id = "Aurora", name = "Аврора", rarity = "Эпический", weight = 11, biome = "Dusk"},
        {id = "Eclipse", name = "Затмение", rarity = "Легендарный", weight = 1, biome = "Dusk"},
    },
    CrystalWisp = {
        {id = "PrismGlow", name = "Призматическое сияние", rarity = "Необычный", weight = 140, biome = "CrystalGrotto"},
        {id = "EchoSpark", name = "Искра эха", rarity = "Редкий", weight = 48, biome = "CrystalGrotto"},
        {id = "Starseed", name = "Звёздное семя", rarity = "Эпический", weight = 11, biome = "CrystalGrotto"},
        {id = "HeartOfPrism", name = "Сердце призмы", rarity = "Легендарный", weight = 1, biome = "CrystalGrotto"},
    },
}

local companionMutationLookup = {}
for companionId, definitions in companionMutationDefinitions do
    companionMutationLookup[companionId] = {}
    for _, definition in definitions do
        companionMutationLookup[companionId][definition.id] = definition
    end
end

local function normalizeCompanionMutations(raw)
    raw = type(raw) == "table" and raw or {}
    local result = {}
    for _, id in COMPANION_IDS do
        local saved = raw[id]
        local definition = type(saved) == "string" and companionMutationLookup[id][saved] or nil
        result[id] = definition and definition.id or nil
    end
    return result
end

local function rollCompanionMutation(companionId, biomeId)
    local definitions = companionMutationDefinitions[companionId]
    if not definitions then return nil end

    local eligible = {}
    local totalWeight = 0
    for _, definition in definitions do
        if definition.biome == biomeId then
            table.insert(eligible, definition)
            totalWeight += definition.weight
        end
    end

    -- Legacy profiles may be repaired outside the discovery prompt. In that
    -- case, use the companion's own habitat rather than an unrelated biome.
    if #eligible == 0 then
        for _, definition in definitions do
            if definition.biome == definitions[1].biome then
                table.insert(eligible, definition)
                totalWeight += definition.weight
            end
        end
    end
    if totalWeight <= 0 then return nil end

    local roll = math.random(1, totalWeight)
    for _, definition in eligible do
        roll -= definition.weight
        if roll <= 0 then return definition.id end
    end
    return eligible[1].id
end

local function ensureCompanionMutation(player, companionId)
    local session = sessions[player]
    if not session or player:GetAttribute(companionId) ~= true then return false end
    if session.companionMutations[companionId] then return false end

    local discoveryBiome = session.companionDiscoveryBiomes
        and session.companionDiscoveryBiomes[companionId]
    session.companionMutations[companionId] = rollCompanionMutation(companionId, discoveryBiome)
    local mutationId = session.companionMutations[companionId]
    local definition = mutationId and companionMutationLookup[companionId][mutationId]
    player:SetAttribute("Companion_" .. companionId .. "_Mutation", mutationId or "")
    player:SetAttribute("Companion_" .. companionId .. "_MutationName", definition and definition.name or "")
    player:SetAttribute("Companion_" .. companionId .. "_MutationRarity", definition and definition.rarity or "")
    player:SetAttribute("Companion_" .. companionId .. "_MutationBiome", definition and definition.biome or "")
    if session.online then
        task.defer(function()
            if sessions[player] == session and player.Parent and not save(player) then
                warn("Companion mutation save will be retried:", player.UserId, companionId)
            end
        end)
    end
    return true
end

local function syncCompanionProgress(player)
    local session = sessions[player]
    if not session then return end
    for _, id in COMPANION_IDS do
        ensureCompanionMutation(player, id)
        local mutationId = session.companionMutations[id]
        local mutationDefinition = mutationId and companionMutationLookup[id][mutationId]
        player:SetAttribute("Companion_" .. id .. "_Mutation", mutationId or "")
        player:SetAttribute("Companion_" .. id .. "_MutationName", mutationDefinition and mutationDefinition.name or "")
        player:SetAttribute("Companion_" .. id .. "_MutationRarity", mutationDefinition and mutationDefinition.rarity or "")
        player:SetAttribute("Companion_" .. id .. "_MutationBiome", mutationDefinition and mutationDefinition.biome or "")
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
        local bondStage = progressData.bond >= 900 and 4
            or progressData.bond >= 600 and 3
            or progressData.bond >= 300 and 2
            or progressData.bond >= 100 and 1
            or 0
        player:SetAttribute("Companion_" .. id .. "_BondStage", bondStage)
        local mood = session.companionMood and session.companionMood[id] or companionMoodDefaults[id]
        player:SetAttribute("Companion_" .. id .. "_Mood", mood)
        player:SetAttribute("Companion_" .. id .. "_Personality", session.companionPersonalities[id])
    end
end

local function awardCompanionXp(player, companionId, amount)
    if table.find(COMPANION_IDS, companionId) == nil then return false, "InvalidCompanion" end
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

local companionPlaySymbols = {"●", "◆", "✦"}
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

    addDailyQuestProgress(player, "Play", 1, false)
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
    if table.find(COMPANION_IDS, companionId) == nil then return end
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
    if table.find(COMPANION_IDS, companionId) == nil then return end
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
    local bondStage = progressData.bond >= 900 and 4
        or progressData.bond >= 600 and 3
        or progressData.bond >= 300 and 2
        or progressData.bond >= 100 and 1
        or 0
    event:FireClient(player, "CompanionPetted", {companionId = companionId, bondStage = bondStage})
    tip(player, pets[companionId] .. " довольно прижался к тебе. Дружба +5.")
    if session.online and not save(player) then
        warn("Companion petting save will be retried:", player.UserId, companionId)
    end
end

local function feedCompanion(player, companionId)
    if table.find(COMPANION_IDS, companionId) == nil then return end
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
    addDailyQuestProgress(player, "Feed", 1, false)
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
    tool.Name = toolId == "Axe" and "Топор путешественника" or (toolId == "Sword" and "Меч странника" or "Кирка путешественника")
    tool.ToolTip = toolId == "Sword" and "Меч для тренировок и путешествий" or (level >= 2 and "Усиленный инструмент: добыча быстрее" or (toolId == "Axe" and "Нужен для добычи дерева" or "Нужна для добычи камня"))
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("PetKingdomsToolId", toolId)
    tool:SetAttribute("PetKingdomsToolLevel", level)

    local handle = createToolPart(tool, "Handle", Vector3.new(0.28, 0.28, 2.5), CFrame.new(), Color3.fromRGB(132, 91, 57), Enum.Material.Wood, Enum.PartType.Cylinder)
    handle.CFrame = CFrame.new() * CFrame.Angles(0, 0, math.rad(90))

    if toolId == "Sword" then
        local blade = createToolPart(tool, "SwordBlade", Vector3.new(0.28, 3.25, 0.52), CFrame.new(0, 1.7, 0), Color3.fromRGB(206, 222, 228), Enum.Material.Metal)
        local guard = createToolPart(tool, "SwordGuard", Vector3.new(1.85, 0.28, 0.4), CFrame.new(0, 0.2, 0), Color3.fromRGB(221, 176, 86), Enum.Material.Metal)
        local pommel = createToolPart(tool, "SwordPommel", Vector3.new(0.5, 0.48, 0.5), CFrame.new(0, -0.95, 0), Color3.fromRGB(221, 176, 86), Enum.Material.Metal, Enum.PartType.Ball)
        for _, part in {blade, guard, pommel} do
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = part
            weld.Parent = handle
        end
    elseif toolId == "Axe" then
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
    local toolName = toolId == "Axe" and "Топор путешественника" or (toolId == "Sword" and "Меч странника" or "Кирка путешественника")
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
    player:SetAttribute("Tool_SwordOwned", tools.Sword == true)
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

local DAILY_QUEST_REWARD = 40
local DAILY_QUEST_COUNT = 3
local DAILY_QUEST_DEFINITIONS = {
    Gather = {goal = 4, title = "Собиратель", description = "Собери любые 4 ресурса в мире."},
    GatherWood = {goal = 4, title = "Запас древесины", description = "Добудь 4 единицы древесины."},
    GatherStone = {goal = 4, title = "Каменный запас", description = "Добудь 4 единицы камня."},
    Plant = {goal = 2, title = "Зелёные ростки", description = "Посади 2 культуры на своей ферме."},
    Harvest = {goal = 3, title = "Пора урожая", description = "Собери 3 единицы урожая."},
    Sell = {goal = 3, title = "Торговый день", description = "Продай на рынке 3 единицы урожая."},
    Scout = {goal = 1, title = "Тайник разведчика", description = "Найди и забери один тайник с лисёнком."},
    Feed = {goal = 1, title = "Вкусняшка для друга", description = "Угости одного из своих питомцев."},
    Play = {goal = 1, title = "Время поиграть", description = "Успешно сыграй с питомцем в мини-игру."},
    CraftSword = {goal = 1, title = "Оружейник", description = "Создай меч странника у верстака."},
    UpgradeTool = {goal = 1, title = "Мастер инструментов", description = "Улучши топор или кирку у верстака."},
    WinEncounter = {goal = 1, title = "Храбрый исследователь", description = "Победи противника или босса в приключении."},
}

local function currentDailyQuestDay()
    return os.date("!%Y-%m-%d")
end

local function getEligibleDailyQuestIds(player, session)
    local eligible = {"Gather", "Plant", "Harvest", "Sell"}
    if player:GetAttribute("Fox") == true then table.insert(eligible, "Scout") end

    local ownsCompanion = false
    for _, companionId in COMPANION_IDS do
        if player:GetAttribute(companionId) == true then
            ownsCompanion = true
            break
        end
    end
    if ownsCompanion then
        table.insert(eligible, "Feed")
        table.insert(eligible, "Play")
    end

    if session.tools.Axe == true then
        table.insert(eligible, "GatherWood")
        if (session.toolLevels.Axe or 1) < 2 then table.insert(eligible, "UpgradeTool") end
    end
    if session.tools.Pickaxe == true then
        table.insert(eligible, "GatherStone")
        if (session.toolLevels.Pickaxe or 1) < 2 and not table.find(eligible, "UpgradeTool") then
            table.insert(eligible, "UpgradeTool")
        end
    end
    if session.tools.Sword == true then
        for _, encounterId in {"GroveGrunt01", "GroveScout02", "GroveMossling01"} do
            if combatRewardDefinitions[encounterId] and session.completedCombatEncounters[encounterId] ~= true then
                table.insert(eligible, "WinEncounter")
                break
            end
        end
    else
        table.insert(eligible, "CraftSword")
    end
    return eligible
end

local function rollDailyQuestIds(player, session, day)
    local eligible = getEligibleDailyQuestIds(player, session)
    local daySeed = tonumber(string.gsub(day, "%-", "")) or 0
    local seed = (math.abs(player.UserId) % 1000003 + daySeed) % 2147483647
    local random = Random.new(seed)
    for index = #eligible, 2, -1 do
        local swapIndex = random:NextInteger(1, index)
        eligible[index], eligible[swapIndex] = eligible[swapIndex], eligible[index]
    end

    local selected = {}
    for index = 1, math.min(DAILY_QUEST_COUNT, #eligible) do
        selected[index] = eligible[index]
    end
    return selected
end

local function getDailyStreakReward(dailyQuests, today)
    local currentStreak = math.clamp(math.floor(tonumber(dailyQuests.streak) or 0), 0, 3650)
    local lastCompletedDay = dailyQuests.lastCompletedDay
    if lastCompletedDay == today then return currentStreak, 0 end

    local yesterday = os.date("!%Y-%m-%d", os.time() - 86400)
    local nextStreak = lastCompletedDay == yesterday and currentStreak + 1 or 1
    local bonus = nextStreak == 3 and 20 or (nextStreak > 0 and nextStreak % 7 == 0 and 60 or 0)
    return nextStreak, bonus
end

local function normalizeDailyQuests(raw, player, session)
    local today = currentDailyQuestDay()
    local saved = type(raw) == "table" and raw or {}
    local sameDay = saved.day == today
    local savedProgress = sameDay and type(saved.progress) == "table" and saved.progress or {}
    local selected = {}

    if sameDay and (saved.version == 2 or saved.version == 3) and type(saved.quests) == "table" then
        local seen = {}
        for _, questId in saved.quests do
            if #selected >= DAILY_QUEST_COUNT then break end
            if DAILY_QUEST_DEFINITIONS[questId] and not seen[questId] then
                table.insert(selected, questId)
                seen[questId] = true
            end
        end
    end
    if #selected ~= DAILY_QUEST_COUNT then
        selected = rollDailyQuestIds(player, session, today)
    end

    local progress = {}
    for _, questId in selected do
        local definition = DAILY_QUEST_DEFINITIONS[questId]
        progress[questId] = math.clamp(math.floor(tonumber(savedProgress[questId]) or 0), 0, definition.goal)
    end

    local streak = math.clamp(math.floor(tonumber(saved.streak) or 0), 0, 3650)
    local bestStreak = math.max(streak, math.clamp(math.floor(tonumber(saved.bestStreak) or 0), 0, 3650))
    local lastCompletedDay = type(saved.lastCompletedDay) == "string"
        and string.match(saved.lastCompletedDay, "^%d%d%d%d%-%d%d%-%d%d$") and saved.lastCompletedDay or nil

    return {
        version = 3,
        day = today,
        quests = selected,
        progress = progress,
        claimed = sameDay and saved.claimed == true or false,
        streak = streak,
        bestStreak = bestStreak,
        lastCompletedDay = lastCompletedDay,
    }
end

local function syncDailyQuests(player)
    local session = sessions[player]
    if not session then return end
    local previousDay = session.dailyQuests and session.dailyQuests.day
    session.dailyQuests = normalizeDailyQuests(session.dailyQuests, player, session)
    local dayChanged = previousDay ~= nil and previousDay ~= session.dailyQuests.day
    player:SetAttribute("DailyQuest_Day", session.dailyQuests.day)
    player:SetAttribute("DailyQuest_Reward", DAILY_QUEST_REWARD)
    player:SetAttribute("DailyQuest_Claimed", session.dailyQuests.claimed)
    player:SetAttribute("DailyQuest_Count", #session.dailyQuests.quests)
    local streakAfterToday, streakBonusToday = getDailyStreakReward(session.dailyQuests, session.dailyQuests.day)
    local nextMilestone = session.dailyQuests.streak < 3 and 3 or (math.floor(session.dailyQuests.streak / 7) + 1) * 7
    player:SetAttribute("DailyQuest_Streak", session.dailyQuests.streak)
    player:SetAttribute("DailyQuest_BestStreak", session.dailyQuests.bestStreak)
    player:SetAttribute("DailyQuest_StreakAfterToday", streakAfterToday)
    player:SetAttribute("DailyQuest_StreakBonusToday", streakBonusToday)
    player:SetAttribute("DailyQuest_StreakNextMilestone", nextMilestone)
    player:SetAttribute("DailyQuest_StreakNextBonus", nextMilestone == 3 and 20 or 60)
    for index, questId in session.dailyQuests.quests do
        local definition = DAILY_QUEST_DEFINITIONS[questId]
        local prefix = "DailyQuest_" .. tostring(index) .. "_"
        player:SetAttribute(prefix .. "Id", questId)
        player:SetAttribute(prefix .. "Title", definition.title)
        player:SetAttribute(prefix .. "Description", definition.description)
        player:SetAttribute(prefix .. "Goal", definition.goal)
        player:SetAttribute(prefix .. "Progress", session.dailyQuests.progress[questId] or 0)
    end
    if dayChanged and session.online and player:GetAttribute("Ready") then
        task.defer(function()
            if sessions[player] == session then save(player) end
        end)
    end
end

addDailyQuestProgress = function(player, questId, amount, saveProgress)
    local session = sessions[player]
    local definition = DAILY_QUEST_DEFINITIONS[questId]
    if not session or not definition or not player:GetAttribute("Ready") then return end
    session.dailyQuests = normalizeDailyQuests(session.dailyQuests, player, session)
    if session.dailyQuests.claimed or not table.find(session.dailyQuests.quests, questId) then
        syncDailyQuests(player)
        return
    end
    local previous = session.dailyQuests.progress[questId] or 0
    local nextValue = math.clamp(previous + math.max(0, math.floor(tonumber(amount) or 0)), 0, definition.goal)
    if nextValue == previous then return end
    session.dailyQuests.progress[questId] = nextValue
    syncDailyQuests(player)
    if saveProgress ~= false and session.online and not save(player) then
        warn("Daily quest progress save will be retried:", player.UserId, questId)
    end
end

task.spawn(function()
    while true do
        task.wait(60)
        for _, player in Players:GetPlayers() do
            if player:GetAttribute("Ready") then syncDailyQuests(player) end
        end
    end
end)

local function claimDailyQuestReward(player)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if not session.online then
        return tip(player, "Ежедневные задания временно недоступны: сохранение профиля не работает.")
    end
    if session.economyBusy then return tip(player, "Подожди завершения текущей операции с монетами.") end
    session.dailyQuests = normalizeDailyQuests(session.dailyQuests, player, session)
    if session.dailyQuests.claimed then return tip(player, "Награда за сегодня уже получена. Новые задания появятся после обновления дня.") end
    for _, questId in session.dailyQuests.quests do
        local definition = DAILY_QUEST_DEFINITIONS[questId]
        if (session.dailyQuests.progress[questId] or 0) < definition.goal then
            return tip(player, "Сначала выполни все три ежедневных задания.")
        end
    end
    local previousCoins = math.clamp(math.floor(tonumber(session.coins) or 0), 0, MAX_COINS)
    local today = session.dailyQuests.day
    local previousStreak = session.dailyQuests.streak
    local previousBestStreak = session.dailyQuests.bestStreak
    local previousCompletedDay = session.dailyQuests.lastCompletedDay
    local nextStreak, streakBonus = getDailyStreakReward(session.dailyQuests, today)
    local credited = DAILY_QUEST_REWARD + streakBonus
    if MAX_COINS - previousCoins < credited then
        return tip(player, "Освободи место минимум для " .. tostring(credited) .. " монет, а затем забери награду.")
    end
    session.economyBusy = true
    session.coins = previousCoins + credited
    session.dailyQuests.claimed = true
    session.dailyQuests.streak = nextStreak
    session.dailyQuests.bestStreak = math.max(previousBestStreak, nextStreak)
    session.dailyQuests.lastCompletedDay = today
    syncFarm(player)
    syncDailyQuests(player)
    if not save(player) then
        session.coins = previousCoins
        session.dailyQuests.claimed = false
        session.dailyQuests.streak = previousStreak
        session.dailyQuests.bestStreak = previousBestStreak
        session.dailyQuests.lastCompletedDay = previousCompletedDay
        syncFarm(player)
        syncDailyQuests(player)
        session.economyBusy = false
        return tip(player, "Не удалось сохранить награду. Попробуй забрать её ещё раз.")
    end
    session.economyBusy = false
    local message = "Все ежедневные задания выполнены! Получено " .. tostring(DAILY_QUEST_REWARD) .. " монет."
    if streakBonus > 0 then
        message ..= " Бонус серии: +" .. tostring(streakBonus) .. " Coins (" .. tostring(nextStreak) .. " дней подряд)!"
    else
        message ..= " Серия: " .. tostring(nextStreak) .. " дней подряд."
    end
    tip(player, message)
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
            Sword = session.tools.Sword == true,
            equipped = toolIds[session.equippedTool] and session.equippedTool or "Axe",
            levels = {
                Axe = math.clamp(math.floor(tonumber(session.toolLevels.Axe) or 1), 1, 2),
                Pickaxe = math.clamp(math.floor(tonumber(session.toolLevels.Pickaxe) or 1), 1, 2),
            },
        }
        local citySnapshot = normalizeCity(session.city)
        local coinSnapshot = math.clamp(math.floor(tonumber(session.coins) or 0), 0, MAX_COINS)
        local foxScoutSnapshot = {
            activeCacheId = foxCacheIdSet[session.foxCacheActiveId] and session.foxCacheActiveId or nil,
            readyAt = math.max(0, math.floor(tonumber(session.foxSearchReadyAt) or 0)),
            searchCount = math.max(0, math.floor(tonumber(session.foxSearchCount) or 0)),
        }
        local dailyQuestSnapshot = normalizeDailyQuests(session.dailyQuests, player, session)
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
                old.schemaVersion = math.max(tonumber(old.schemaVersion) or 0, 12)
                old.coins = coinSnapshot

                local savedTools = type(old.tools) == "table" and old.tools or {}
                savedTools.Axe = toolsSnapshot.Axe
                savedTools.Pickaxe = toolsSnapshot.Pickaxe
                savedTools.Sword = savedTools.Sword == true or toolsSnapshot.Sword
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
                old.dailyQuests = dailyQuestSnapshot

                local savedCompanions = type(old.companions) == "table" and old.companions or {}
                for _, companionId in COMPANION_IDS do
                    local savedCompanion = companionProgressSnapshot[companionId]
                    savedCompanion.personality = session.companionPersonalities[companionId]
                    savedCompanion.mutation = session.companionMutations[companionId]
                    savedCompanions[companionId] = savedCompanion
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
                savedIsland.buildings = citySnapshot.buildings
                savedIsland.storage = citySnapshot.storage
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
        coins = 0,
        economyBusy = false,
        tools = {Axe = true, Pickaxe = true, Sword = false},
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
        dailyQuests = nil,
        companionProgress = normalizeCompanionProgress(nil),
        companionMood = {Fox = companionMoodDefaults.Fox, Moth = companionMoodDefaults.Moth, CrystalWisp = companionMoodDefaults.CrystalWisp},
        companionPersonalities = normalizeCompanionPersonalities(nil, player.UserId),
        companionMutations = normalizeCompanionMutations(nil),
        companionDiscoveryBiomes = {},
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
    -- Server-side recovery for players who fall below the playable archipelago.
    -- Preserve the character and current inventory instead of leaving it under the map.
    task.spawn(function()
        while player.Parent and sessions[player] == session do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0
                and root.Position.Y < -80 then
                local recovery = session.homeSpawn
                if recovery and recovery.Parent then
                    character:PivotTo(recovery.CFrame + Vector3.new(0, 6, 0))
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    player:SetAttribute("FallRecoveryCount", (player:GetAttribute("FallRecoveryCount") or 0) + 1)
                else
                    local grove = workspace:FindFirstChild("Grove")
                    local spawn = grove and grove:FindFirstChild("PublicSpawn")
                    if spawn and spawn:IsA("BasePart") then
                        character:PivotTo(spawn.CFrame + Vector3.new(0, 6, 0))
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                task.wait(1.25)
            end
            task.wait(0.35)
        end
    end)

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
                Sword = savedTools.Sword == true,
            }
            local savedLevels = type(savedTools.levels) == "table" and savedTools.levels or {}
            session.toolLevels = {
                Axe = math.clamp(math.floor(tonumber(savedLevels.Axe) or 1), 1, 2),
                Pickaxe = math.clamp(math.floor(tonumber(savedLevels.Pickaxe) or 1), 1, 2),
            }
            local savedEquippedTool = savedTools.equipped
            session.equippedTool = toolIds[savedEquippedTool] and session.tools[savedEquippedTool] and savedEquippedTool or "Axe"
            session.city = normalizeCity(type(data.island) == "table" and data.island or data.city)
            session.coins = math.clamp(math.floor(tonumber(data.coins) or 0), 0, MAX_COINS)
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
            session.dailyQuests = data.dailyQuests

            session.companionProgress = normalizeCompanionProgress(data.companions)
            local savedCompanions = type(data.companions) == "table" and data.companions or {}
            local savedPersonalities = {}
            for _, id in COMPANION_IDS do
                local saved = type(savedCompanions[id]) == "table" and savedCompanions[id] or {}
                savedPersonalities[id] = saved.personality
            end
            session.companionPersonalities = normalizeCompanionPersonalities(savedPersonalities, player.UserId)
            local savedMutations = {}
            for _, id in COMPANION_IDS do
                local saved = type(savedCompanions[id]) == "table" and savedCompanions[id] or {}
                savedMutations[id] = saved.mutation
            end
            session.companionMutations = normalizeCompanionMutations(savedMutations)
        end
        if not ok then player:SetAttribute("OfflineAlbum", true) end
    else
        player:SetAttribute("OfflineAlbum", true)
    end

    session.companionOwnershipConnections = {}
    for _, companionId in COMPANION_IDS do
        table.insert(session.companionOwnershipConnections, player:GetAttributeChangedSignal(companionId):Connect(function()
            if sessions[player] ~= session or player:GetAttribute(companionId) ~= true then return end
            ensureCompanionMutation(player, companionId)
            syncCompanionProgress(player)
        end))
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
    syncDailyQuests(player)
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
    addDailyQuestProgress(player, "WinEncounter", 1)
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
    addDailyQuestProgress(player, "Scout", 1)
    awardCompanionXp(player, "Fox", 30)
end

local explorationMilestoneCoins = {
    MoonGateTrace = 3,
    MoonGateOpen = 5,
    MoonRelic = 6,
    CrystalGrottoDiscovered = 8,
    CrystalHeart = 8,
    CrystalRunes = 5,
    CrystalCache = 10,
    CrystalEchoDiscovered = 8,
    PrismSeedFound = 15,
}

local function grantExplorationCoins(player, milestoneId)
    local session = sessions[player]
    local amount = explorationMilestoneCoins[milestoneId]
    if not session or not player:GetAttribute("Ready") or not amount then return 0 end
    local previousCoins = math.clamp(math.floor(tonumber(session.coins) or 0), 0, MAX_COINS)
    local credited = math.min(amount, MAX_COINS - previousCoins)
    if credited <= 0 then return 0 end
    session.coins = previousCoins + credited
    syncFarm(player)
    return credited
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

    local firstDiscovery = player:GetAttribute("MoonGateTrace") ~= true
    player:SetAttribute("MoonGateTrace", true)
    local coinBonus = firstDiscovery and grantExplorationCoins(player, "MoonGateTrace") or 0
    tip(player, "Лисёнок нашёл древний след под корнями! Теперь позови лунную моль к рунам. +" .. tostring(coinBonus) .. " монет.")
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

    local firstDiscovery = player:GetAttribute("MoonGateOpen") ~= true
    player:SetAttribute("MoonGateOpen", true)
    local coinBonus = firstDiscovery and grantExplorationCoins(player, "MoonGateOpen") or 0
    tip(player, "Лунная моль зажгла древние руны! Тайный проход открылся — за аркой спрятан звёздный осколок. +" .. tostring(coinBonus) .. " монет.")
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

    local firstDiscovery = player:GetAttribute("MoonRelic") ~= true
    player:SetAttribute("MoonRelic", true)
    local coinBonus = firstDiscovery and grantExplorationCoins(player, "MoonRelic") or 0
    session.inventory.StarShard = (session.inventory.StarShard or 0) + 1
    syncInventory(player)
    tip(player, "Редкая находка! Ты получил звёздный осколок ×1 и " .. tostring(coinBonus) .. " монет.")
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

    if action == "ClaimDailyQuests" then
        claimDailyQuestReward(player)
        return
    end

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

    if action == "PlaceIslandDecoration" then
        if placeIslandDecoration then placeIslandDecoration(player, payload) end
        return
    end

    if action == "RemoveIslandDecoration" then
        if removeIslandDecoration then removeIslandDecoration(player, payload) end
        return
    end

    if action == "CraftSword" then
        local session = sessions[player]
        if not session then return end
        if session.tools.Sword == true then return tip(player, "Меч странника уже создан.") end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local city = session.homeIsland and session.homeIsland:FindFirstChild("PersonalCity")
        local station = city and city:FindFirstChild("Workshop")
        local anchor = station and station:FindFirstChild("PromptAnchor")
        if not root or not anchor or (root.Position - anchor.Position).Magnitude > 14 then
            return tip(player, "Меч создаётся только у верстака на своём острове.")
        end
        if (session.inventory.IronIngot or 0) < swordRecipe.IronIngot or (session.inventory.Wood or 0) < swordRecipe.Wood then
            return tip(player, "Для меча нужны 2 железных слитка и 6 дерева.")
        end
        session.inventory.IronIngot -= swordRecipe.IronIngot
        session.inventory.Wood -= swordRecipe.Wood
        session.tools.Sword = true
        session.equippedTool = "Sword"
        addDailyQuestProgress(player, "CraftSword", 1, false)
        syncInventory(player)
        syncTools(player)
        event:FireClient(player, "SwordCrafted")
        tip(player, "Меч странника создан! Проверь оружие в руках и отправляйся на арену.")
        if session.online then save(player) end
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
        addDailyQuestProgress(player, "UpgradeTool", 1, false)
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
        tip(player, payload == "Axe" and "Топор экипирован." or (payload == "Sword" and "Меч странника экипирован." or "Кирка экипирована."))
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

    if action == "UpgradeFarm" then
        upgradeFarm(player)
        return
    end

    if action == "BuySeeds" then
        if type(payload) ~= "string" then return end
        buyFarmSeeds(player, payload)
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

local function renderIslandDecoration(cityModel, meadow, decoration, index, ownerUserId)
    if not cityModel or not meadow or type(decoration) ~= "table" then return end
    local id = decoration.id
    if id ~= "Path" and id ~= "FlowerBed" and id ~= "Cottage" and id ~= "Warehouse" then return end

    local x = math.clamp(tonumber(decoration.x) or 0, 0, 12)
    local z = math.clamp(tonumber(decoration.z) or 0, -4, 4)
    local rotation = (math.floor((tonumber(decoration.rotation) or 0) / 90 + 0.5) % 4) * 90
    local frame = meadow.CFrame * CFrame.new(x, meadow.Size.Y / 2 + 0.16, z) * CFrame.Angles(0, math.rad(rotation), 0)
    local model = Instance.new("Model")
    model.Name = "Decoration_" .. tostring(index)
    model:SetAttribute("OwnerUserId", ownerUserId)
    model:SetAttribute("DecorationId", id)
    model.Parent = cityModel

    if id == "Path" then
        local stoneColor = Color3.fromRGB(137, 143, 133)
        for row = 1, 2 do
            for column = 1, 2 do
                local offset = Vector3.new((column - 1.5) * 1.72, 0.08, (row - 1.5) * 1.72)
                local stone = makeFarmVisualPart(model, "PavingStone", Vector3.new(1.62, 0.24, 1.62),
                    frame * CFrame.new(offset), stoneColor, Enum.PartType.Block, Enum.Material.Slate)
                stone.CanCollide = true
            end
        end
    elseif id == "FlowerBed" then
        local wood = Color3.fromRGB(133, 91, 59)
        makeFarmVisualPart(model, "FlowerBedSoil", Vector3.new(3.35, 0.28, 3.35),
            frame * CFrame.new(0, 0.12, 0), Color3.fromRGB(91, 65, 47), Enum.PartType.Block, Enum.Material.Ground)
        for _, edge in {
            {Vector3.new(3.8, 0.42, 0.28), Vector3.new(0, 0.34, -1.78)},
            {Vector3.new(3.8, 0.42, 0.28), Vector3.new(0, 0.34, 1.78)},
            {Vector3.new(0.28, 0.42, 3.35), Vector3.new(-1.78, 0.34, 0)},
            {Vector3.new(0.28, 0.42, 3.35), Vector3.new(1.78, 0.34, 0)},
        } do
            makeFarmVisualPart(model, "TimberEdge", edge[1], frame * CFrame.new(edge[2]), wood,
                Enum.PartType.Block, Enum.Material.WoodPlanks)
        end
        local flowerColors = {
            Color3.fromRGB(246, 190, 105), Color3.fromRGB(232, 143, 153),
            Color3.fromRGB(195, 164, 224), Color3.fromRGB(246, 224, 157),
        }
        for flowerIndex = 1, 4 do
            local column = (flowerIndex - 1) % 2
            local row = math.floor((flowerIndex - 1) / 2)
            local offset = Vector3.new((column - 0.5) * 1.55, 0.48, (row - 0.5) * 1.55)
            makeFarmVisualPart(model, "FlowerStem", Vector3.new(0.12, 0.52, 0.12),
                frame * CFrame.new(offset + Vector3.new(0, 0.22, 0)),
                Color3.fromRGB(86, 139, 78), Enum.PartType.Block, Enum.Material.Grass)
            makeFarmVisualPart(model, "FlowerBloom", Vector3.new(0.62, 0.42, 0.62),
                frame * CFrame.new(offset + Vector3.new(0, 0.54, 0)),
                flowerColors[flowerIndex], Enum.PartType.Ball, Enum.Material.SmoothPlastic)
        end
    elseif id == "Cottage" then
        local wall = Color3.fromRGB(226, 190, 139)
        local timber = Color3.fromRGB(104, 67, 47)
        local roof = Color3.fromRGB(139, 66, 53)
        local front = frame * CFrame.new(0, 0, -1.72)
        makeFarmVisualPart(model, "CottageFoundation", Vector3.new(3.8, 0.24, 3.8), frame * CFrame.new(0, 0.12, 0), Color3.fromRGB(116, 112, 100), Enum.PartType.Block, Enum.Material.Slate)
        makeFarmVisualPart(model, "CottageWalls", Vector3.new(3.35, 2.25, 3.25), frame * CFrame.new(0, 1.28, 0), wall, Enum.PartType.Block, Enum.Material.WoodPlanks)
        makeFarmVisualPart(model, "CottageFrontDoor", Vector3.new(0.92, 1.72, 0.12), front * CFrame.new(0, 0.98, -0.02), timber, Enum.PartType.Block, Enum.Material.Wood)
        makeFarmVisualPart(model, "CottageDoorHandle", Vector3.new(0.09, 0.09, 0.08), front * CFrame.new(0.29, 0.98, -0.11), Color3.fromRGB(236, 190, 91), Enum.PartType.Ball, Enum.Material.Metal)
        for _, side in {-1, 1} do
            makeFarmVisualPart(model, "CottageWindowFrame", Vector3.new(0.86, 0.82, 0.14), front * CFrame.new(side * 1.12, 1.52, -0.03), timber, Enum.PartType.Block, Enum.Material.Wood)
            makeFarmVisualPart(model, "CottageWindowGlass", Vector3.new(0.62, 0.58, 0.08), front * CFrame.new(side * 1.12, 1.52, -0.12), Color3.fromRGB(144, 205, 215), Enum.PartType.Block, Enum.Material.Glass)
        end
        for _, side in {-1, 1} do
            local roofWedge = Instance.new("WedgePart")
            roofWedge.Name = "CottageRoof"
            roofWedge.Size = Vector3.new(2.15, 1.35, 4.05)
            roofWedge.CFrame = frame * CFrame.new(side * 0.95, 3.05, 0) * CFrame.Angles(0, side == 1 and math.rad(180) or 0, 0)
            roofWedge.Color = roof
            roofWedge.Material = Enum.Material.Slate
            roofWedge.Anchored = true
            roofWedge.CanCollide = true
            roofWedge.CanTouch = false
            roofWedge.CanQuery = false
            roofWedge.Parent = model
        end
        makeFarmVisualPart(model, "CottageChimney", Vector3.new(0.62, 1.55, 0.62), frame * CFrame.new(1.18, 3.2, 0.82), Color3.fromRGB(143, 91, 73), Enum.PartType.Block, Enum.Material.Brick)
        makeFarmVisualPart(model, "CottageChimneyCap", Vector3.new(0.82, 0.18, 0.82), frame * CFrame.new(1.18, 4.0, 0.82), timber, Enum.PartType.Block, Enum.Material.Slate)
        makeFarmVisualPart(model, "CottageStep", Vector3.new(1.3, 0.18, 0.65), front * CFrame.new(0, 0.12, -0.3), Color3.fromRGB(145, 139, 122), Enum.PartType.Block, Enum.Material.Slate)
    else
        local wood = Color3.fromRGB(128, 88, 56)
        local stone = Color3.fromRGB(119, 124, 119)
        makeFarmVisualPart(model, "WarehouseFoundation", Vector3.new(3.8, 0.28, 3.8),
            frame * CFrame.new(0, 0.14, 0), stone, Enum.PartType.Block, Enum.Material.Slate)
        makeFarmVisualPart(model, "WarehouseBody", Vector3.new(3.35, 2.5, 3.25),
            frame * CFrame.new(0, 1.5, 0), Color3.fromRGB(155, 112, 72), Enum.PartType.Block, Enum.Material.WoodPlanks)
        local front = frame * CFrame.new(0, 0, -1.7)
        makeFarmVisualPart(model, "WarehouseDoor", Vector3.new(1.15, 2.05, 0.16),
            front * CFrame.new(0, 1.08, 0), wood, Enum.PartType.Block, Enum.Material.Wood)
        for _, side in {-1, 1} do
            makeFarmVisualPart(model, "WarehouseBeam", Vector3.new(0.22, 2.7, 0.24),
                front * CFrame.new(side * 1.55, 1.4, -0.06), wood, Enum.PartType.Block, Enum.Material.Wood)
        end
        local roof = makeFarmVisualPart(model, "WarehouseRoof", Vector3.new(3.95, 0.3, 3.9),
            frame * CFrame.new(0, 2.95, 0), Color3.fromRGB(104, 65, 48), Enum.PartType.Block, Enum.Material.Slate)
        roof.CFrame *= CFrame.Angles(0, 0, math.rad(0))
        makeFarmVisualPart(model, "WarehouseSign", Vector3.new(1.7, 0.58, 0.14),
            front * CFrame.new(0, 2.25, -0.08), Color3.fromRGB(229, 194, 125), Enum.PartType.Block, Enum.Material.Wood)
        local signText = Instance.new("SurfaceGui")
        signText.Name = "WarehouseSignGui"
        signText.Face = Enum.NormalId.Front
        signText.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        signText.PixelsPerStud = 40
        signText.Parent = model:FindFirstChild("WarehouseSign")
        local signLabel = Instance.new("TextLabel")
        signLabel.Size = UDim2.fromScale(1, 1)
        signLabel.BackgroundTransparency = 1
        signLabel.Text = "СКЛАД"
        signLabel.TextColor3 = Color3.fromRGB(73, 51, 35)
        signLabel.Font = Enum.Font.GothamBold
        signLabel.TextScaled = true
        signLabel.Parent = signText
        local anchor = Instance.new("Part")
        anchor.Name = "WarehousePromptAnchor"
        anchor.Size = Vector3.new(0.5, 0.5, 0.5)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = true
        anchor.CFrame = front * CFrame.new(0, 1.3, -1.0)
        anchor.Parent = model
        prompt(anchor, "Склад", "Сложить материалы", function(visitor)
            useWarehouse(visitor, ownerUserId, "Deposit")
        end)
        local withdrawAnchor = Instance.new("Part")
        withdrawAnchor.Name = "WarehouseWithdrawAnchor"
        withdrawAnchor.Size = Vector3.new(0.5, 0.5, 0.5)
        withdrawAnchor.Transparency = 1
        withdrawAnchor.Anchored = true
        withdrawAnchor.CanCollide = false
        withdrawAnchor.CanTouch = false
        withdrawAnchor.CanQuery = true
        withdrawAnchor.CFrame = front * CFrame.new(1.5, 1.3, -1.0)
        withdrawAnchor.Parent = model
        prompt(withdrawAnchor, "Склад", "Забрать материалы", function(visitor)
            useWarehouse(visitor, ownerUserId, "Withdraw")
        end)
    end
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
        addDailyQuestProgress(player, "Plant", 1, false)
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
        addDailyQuestProgress(player, "Harvest", definition.reward, false)
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

    -- The very first bridge must be accessible after one wood and one stone pickup.
    -- Once repaired, the normal per-node amounts and cooldowns apply unchanged.
    local amount = session.city.bridges.homeToGrove and definition.amount
        or (materialId == "Wood" and 5 or 3)

    local now = os.time()
    local readyAt = session.homeMaterialCooldowns[materialId] or 0
    if readyAt > now then
        return tip(player, definition.title .. " снова появится через " .. tostring(math.ceil((readyAt - now) / 60)) .. " мин.")
    end

    session.inventory[materialId] = (session.inventory[materialId] or 0) + amount
    session.homeMaterialCooldowns[materialId] = now + definition.cooldown
    syncInventory(player)
    tip(player, "Собрано: " .. definition.title .. " ×" .. tostring(amount))
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
        local market = Instance.new("Model")
        market.Name = "HarvestMarket"
        market:SetAttribute("OwnerUserId", ownerUserId)
        market.Parent = cityModel
        local marketFrame = meadow.CFrame * CFrame.new(-5, meadow.Size.Y / 2 + 0.18, -10)
        makeFarmVisualPart(market, "MarketCounter", Vector3.new(4.2, 1.15, 1.35),
            marketFrame * CFrame.new(0, 0.58, 0), Color3.fromRGB(139, 91, 55), Enum.PartType.Block, Enum.Material.WoodPlanks)
        makeFarmVisualPart(market, "MarketCounterTop", Vector3.new(4.5, 0.18, 1.55),
            marketFrame * CFrame.new(0, 1.25, 0), Color3.fromRGB(198, 151, 91), Enum.PartType.Block, Enum.Material.Wood)
        for _, side in {-1, 1} do
            makeFarmVisualPart(market, "MarketPost", Vector3.new(0.18, 3.25, 0.18),
                marketFrame * CFrame.new(side * 2.0, 1.65, 0.48), Color3.fromRGB(111, 75, 49), Enum.PartType.Block, Enum.Material.Wood)
        end
        makeFarmVisualPart(market, "MarketAwning", Vector3.new(4.55, 0.22, 2.0),
            marketFrame * CFrame.new(0, 3.28, 0.38), Color3.fromRGB(226, 157, 91), Enum.PartType.Block, Enum.Material.Fabric)
        local marketSign = makeFarmVisualPart(market, "MarketSign", Vector3.new(2.25, 0.72, 0.16),
            marketFrame * CFrame.new(0, 2.48, -0.72), Color3.fromRGB(244, 218, 161), Enum.PartType.Block, Enum.Material.Wood)
        local marketSignGui = Instance.new("SurfaceGui")
        marketSignGui.Name = "MarketSignGui"
        marketSignGui.Face = Enum.NormalId.Front
        marketSignGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        marketSignGui.PixelsPerStud = 48
        marketSignGui.Parent = marketSign
        local marketSignText = Instance.new("TextLabel")
        marketSignText.Size = UDim2.fromScale(1, 1)
        marketSignText.BackgroundTransparency = 1
        marketSignText.Text = "РЫНОК"
        marketSignText.TextColor3 = Color3.fromRGB(84, 60, 39)
        marketSignText.Font = Enum.Font.GothamBold
        marketSignText.TextScaled = true
        marketSignText.Parent = marketSignGui
        for index, fruitColor in ipairs({
            Color3.fromRGB(231, 91, 74), Color3.fromRGB(242, 170, 72), Color3.fromRGB(137, 190, 103),
        }) do
            makeFarmVisualPart(market, "MarketProduce", Vector3.new(0.48, 0.48, 0.48),
                marketFrame * CFrame.new(-1.0 + (index - 1) * 0.9, 1.62, -0.08), fruitColor, Enum.PartType.Ball, Enum.Material.SmoothPlastic)
        end
        local marketAnchor = Instance.new("Part")
        marketAnchor.Name = "PromptAnchor"
        marketAnchor.Size = Vector3.new(0.5, 0.5, 0.5)
        marketAnchor.Transparency = 1
        marketAnchor.Anchored = true
        marketAnchor.CanCollide = false
        marketAnchor.CanTouch = false
        marketAnchor.CanQuery = true
        marketAnchor.CFrame = marketFrame * CFrame.new(0, 1.7, -1.25)
        marketAnchor.Parent = market
        prompt(marketAnchor, "Фермерский рынок", "Продать весь урожай", function(visitor)
            sellIslandHarvest(visitor, ownerUserId)
        end)

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
    local decorationMeadow = homeIsland:FindFirstChild("Meadow")
    if decorationMeadow then
        for index, decoration in ipairs(session.city.buildings) do
            renderIslandDecoration(cityModel, decorationMeadow, decoration, index, ownerUserId)
        end
    end
    refreshFarmCity(player, cityModel)
end

removeIslandDecoration = function(player, payload)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    local index = tonumber(payload)
    if not index or index % 1 ~= 0 or index < 1 or index > #session.city.buildings then
        return tip(player, "Эту постройку уже нельзя найти.")
    end
    local homeIsland = session.homeIsland
    local cityModel = session.cityModel
    local meadow = homeIsland and homeIsland:FindFirstChild("Meadow")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local decoration = session.city.buildings[index]
    if not meadow or not cityModel or not root or not decoration then return end
    local target = meadow.CFrame * CFrame.new(decoration.x, meadow.Size.Y / 2, decoration.z)
    if (root.Position - meadow.Position).Magnitude > 22 or (root.Position - target.Position).Magnitude > 24 then
        return tip(player, "Подойди ближе к постройке на своём острове.")
    end

    if decoration.id == "Warehouse" then
        for _, itemId in ipairs(warehouseItemIds) do
            if (session.city.storage[itemId] or 0) > 0 then
                return tip(player, "Перед разборкой склада сначала забери все материалы.")
            end
        end
    end
    local model = cityModel:FindFirstChild("Decoration_" .. tostring(index))
    if model then model:Destroy() end
    local refunds = {Path = {Wood = 1, Stone = 0}, FlowerBed = {Wood = 2, Stone = 1}, Cottage = {Wood = 4, Stone = 3}, Warehouse = {Wood = 5, Stone = 4}}
    local refund = refunds[decoration.id]
    if not refund then return tip(player, "Этот объект пока нельзя разобрать.") end
    table.remove(session.city.buildings, index)
    for nextIndex = index, #session.city.buildings do
        local shifted = cityModel:FindFirstChild("Decoration_" .. tostring(nextIndex + 1))
        if shifted then shifted.Name = "Decoration_" .. tostring(nextIndex) end
    end
    session.inventory.Wood = (session.inventory.Wood or 0) + refund.Wood
    session.inventory.Stone = (session.inventory.Stone or 0) + refund.Stone
    syncInventory(player)
    syncFarm(player)
    for currentIndex, current in ipairs(session.city.buildings) do
        local currentModel = cityModel:FindFirstChild("Decoration_" .. tostring(currentIndex))
        if currentModel then currentModel:Destroy() end
        renderIslandDecoration(cityModel, meadow, current, currentIndex, player.UserId)
    end
    tip(player, "Постройка разобрана. Возвращено: дерево ×" .. tostring(refund.Wood) .. ", камень ×" .. tostring(refund.Stone) .. ".")
    if session.online then save(player) end
end

placeIslandDecoration = function(player, payload)
    local session = sessions[player]
    if not session or not player:GetAttribute("Ready") then return end
    if type(payload) ~= "table" then return tip(player, "Не удалось прочитать место постройки.") end

    local decorationId = payload.id
    if decorationId ~= "Path" and decorationId ~= "FlowerBed" and decorationId ~= "Cottage" and decorationId ~= "Warehouse" then
        return tip(player, "Такого предмета пока нет в каталоге строительства.")
    end
    local x = tonumber(payload.x)
    local z = tonumber(payload.z)
    local rotation = tonumber(payload.rotation)
    local moveIndex = tonumber(payload.moveIndex)
    if moveIndex and (moveIndex % 1 ~= 0 or moveIndex < 1 or moveIndex > #session.city.buildings) then
        return tip(player, "Не удалось найти постройку для перемещения.")
    end
    local movingDecoration = moveIndex and session.city.buildings[moveIndex] or nil
    if moveIndex and (not movingDecoration or movingDecoration.id ~= decorationId) then
        return tip(player, "Эта постройка больше не доступна для перемещения.")
    end
    if not x or not z or not rotation
        or x ~= x or z ~= z or rotation ~= rotation
        or math.abs(x) == math.huge or math.abs(z) == math.huge or math.abs(rotation) == math.huge
        or x % 1 ~= 0 or z % 1 ~= 0 or rotation % 1 ~= 0 then
        return tip(player, "Выбери место на строительной площадке.")
    end
    if x < 0 or x > 12 or x % 4 ~= 0 or z < -4 or z > 4 or z % 4 ~= 0
        or rotation < 0 or rotation >= 360 or rotation % 90 ~= 0 then
        return tip(player, "Это место нельзя использовать для строительства.")
    end
    if #session.city.buildings >= 12 and not moveIndex then
        return tip(player, "На площадке пока нет свободных мест. Максимум — 12 украшений.")
    end

    local homeIsland = session.homeIsland
    local cityModel = session.cityModel
    local meadow = homeIsland and homeIsland:FindFirstChild("Meadow")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not meadow or not cityModel or not root then return end
    if (root.Position - meadow.Position).Magnitude > 22 then
        return tip(player, "Строить декор можно только на лужайке своего острова.")
    end

    local targetFrame = meadow.CFrame * CFrame.new(x, meadow.Size.Y / 2, z)
    if (root.Position - targetFrame.Position).Magnitude > 24 then
        return tip(player, "Подойди ближе к выбранному месту строительства.")
    end
    for index, existing in ipairs(session.city.buildings) do
        if index ~= moveIndex and existing.x == x and existing.z == z then
            return tip(player, "Это место уже занято. Выбери другую клетку.")
        end
    end

    if moveIndex then
        local oldModel = cityModel:FindFirstChild("Decoration_" .. tostring(moveIndex))
        if oldModel then oldModel:Destroy() end
        local decoration = {id = decorationId, x = x, z = z, rotation = rotation}
        session.city.buildings[moveIndex] = decoration
        renderIslandDecoration(cityModel, meadow, decoration, moveIndex, player.UserId)
        syncFarm(player)
        tip(player, "Постройка перемещена!")
    else
        local costs = {Path = {Wood = 2, Stone = 0}, FlowerBed = {Wood = 4, Stone = 2}, Cottage = {Wood = 8, Stone = 6}, Warehouse = {Wood = 10, Stone = 8}}
        local cost = costs[decorationId]
        if (session.inventory.Wood or 0) < cost.Wood or (session.inventory.Stone or 0) < cost.Stone then
            return tip(player, "Не хватает материалов: дерево ×" .. tostring(cost.Wood) .. ", камень ×" .. tostring(cost.Stone) .. ".")
        end
        session.inventory.Wood -= cost.Wood
        session.inventory.Stone -= cost.Stone
        local decoration = {id = decorationId, x = x, z = z, rotation = rotation}
        table.insert(session.city.buildings, decoration)
        renderIslandDecoration(cityModel, meadow, decoration, #session.city.buildings, player.UserId)
        syncInventory(player)
        syncFarm(player)
        local placedMessages = {Path = "Каменная дорожка построена!", FlowerBed = "Цветочная клумба украшает твой остров!", Cottage = "Уютный домик построен! На острове стало ещё уютнее.", Warehouse = "Склад построен! Теперь можно хранить материалы."}
    tip(player, placedMessages[decorationId])
    end
    if session.online then save(player) end
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
        local session = sessions[player]
        if session then
            session.companionDiscoveryBiomes = session.companionDiscoveryBiomes or {}
            session.companionDiscoveryBiomes[id] = island.Name
        end
        player:SetAttribute(id,true)
        ensureCompanionMutation(player, id)
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
    elseif def.visual == "crystal" then
        makePart("CrystalBase", Vector3.new(3.2, 1.1, 3.0), CFrame.new(0, 0.45, 0), Color3.fromRGB(75, 76, 103), Enum.Material.Slate)
        makePart("CrystalMain", Vector3.new(1.35, 3.4, 1.35), CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(-7)), Color3.fromRGB(132, 102, 196), Enum.Material.Neon)
        makePart("CrystalLeft", Vector3.new(0.9, 2.3, 0.9), CFrame.new(-0.95, 1.55, 0.35) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(99, 166, 207), Enum.Material.Neon)
        makePart("CrystalRight", Vector3.new(0.82, 1.9, 0.82), CFrame.new(0.92, 1.35, -0.32) * CFrame.Angles(0, 0, math.rad(-15)), Color3.fromRGB(191, 140, 225), Enum.Material.Neon)
        local crystalGlow = Instance.new("PointLight")
        crystalGlow.Color = Color3.fromRGB(160, 132, 238)
        crystalGlow.Range = 11
        crystalGlow.Brightness = 0.65
        crystalGlow.Parent = model:FindFirstChild("CrystalMain")
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
        key = "CrystalGrottoLumen01", amount = 1, requiredTool = "Pickaxe", hitsRequired = 6,
        verb = "Добыть кристалл", itemId = "CrystalShard", displayName = "Люмен-кристалл",
        area = "CrystalGrotto", offset = Vector3.new(-12, 0, 2), visual = "crystal",
        kind = "renewable", respawnSeconds = 900,
    },
    {
        key = "CrystalGrottoLumen02", amount = 1, requiredTool = "Pickaxe", hitsRequired = 6,
        verb = "Добыть кристалл", itemId = "CrystalShard", displayName = "Люмен-кристалл",
        area = "CrystalGrotto", offset = Vector3.new(12, 0, 3), visual = "crystal",
        kind = "renewable", respawnSeconds = 900,
    },
    {
        key = "CrystalGrottoPrismVein01", amount = 2, requiredTool = "Pickaxe", hitsRequired = 5,
        verb = "Добыть скрытый кристалл", itemId = "CrystalShard", displayName = "Скрытая призменная жила",
        area = "CrystalGrotto", offset = Vector3.new(-8, 0, -10), visual = "crystal",
        kind = "renewable", respawnSeconds = 900, hiddenByPrismSense = true,
    },
    {
        key = "CrystalGrottoPrismVein02", amount = 2, requiredTool = "Pickaxe", hitsRequired = 5,
        verb = "Добыть скрытый кристалл", itemId = "CrystalShard", displayName = "Скрытая призменная жила",
        area = "CrystalGrotto", offset = Vector3.new(8, 0, -10), visual = "crystal",
        kind = "renewable", respawnSeconds = 900, hiddenByPrismSense = true,
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

    local island
    local origin
    if def.area == "CrystalGrotto" then
        local glade = workspace:FindFirstChild("CombatTrainingGlade")
        island = glade and glade:FindFirstChild("CrystalGrotto")
        origin = island and island:FindFirstChild("CrystalGrottoFloor")
    else
        island = workspace:FindFirstChild(def.area)
        origin = island and island:FindFirstChild("Bank")
    end
    if not island or not origin or not origin:IsA("BasePart") then return end

    local folder = island:FindFirstChild("ResourceNodes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ResourceNodes"
        folder.Parent = island
    end
    if folder:FindFirstChild(def.key) then return end

    local position = CFrame.new(
        origin.Position + Vector3.new(def.offset.X, origin.Size.Y / 2 + 0.18, def.offset.Z)
    )
    local model, anchor = createResourceFlower(def, position)
    model.Parent = folder
    model:SetAttribute("PrismSenseHidden", def.hiddenByPrismSense == true)

    local resourcePrompt = prompt(anchor, def.displayName, def.verb or "Собрать", function(player)
        local session = sessions[player]
        if not session or not player:GetAttribute("Ready") then return end
        if def.hiddenByPrismSense and (tonumber(player:GetAttribute("PrismSenseUntil")) or 0) < workspace:GetServerTimeNow() then
            return tip(player, "Кристальная жила скрыта. Попроси светляка применить Призменное чутьё.")
        end
        if def.area == "CrystalGrotto" then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if player:GetAttribute("InCrystalGrotto") ~= true
                or not root
                or (root.Position - anchor.Position).Magnitude > 13 then
                return tip(player, "Подойди к кристальной жиле внутри пещеры.")
            end
        end

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
        addDailyQuestProgress(player, "Gather", 1, false)
        if def.itemId == "Wood" then addDailyQuestProgress(player, "GatherWood", rewardAmount, false) end
        if def.itemId == "Stone" then addDailyQuestProgress(player, "GatherStone", rewardAmount, false) end

        if session.online and not save(player) then
            warn("Resource pickup save will be retried:", player.UserId, def.key)
            tip(player, "Предмет получен. Сохранение временно задерживается и будет повторено автоматически.")
        end
    end)

    if def.hiddenByPrismSense then
        for _, descendant in model:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant:SetAttribute("PrismSenseOriginalTransparency", descendant.Transparency)
                descendant.Transparency = 1
            end
        end
        resourcePrompt.Enabled = false
    end
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

-- Crystal Grotto: a small optional exploration pocket unlocked by the Moon Relic.
local crystalGrotto = trial and trial:FindFirstChild("CrystalGrotto")
local crystalEntrance = workspace.Dusk and workspace.Dusk:FindFirstChild("CrystalGrottoEntrance")
local crystalArrival = crystalGrotto and crystalGrotto:FindFirstChild("CrystalGrottoArrival")
local crystalReturn = crystalGrotto and crystalGrotto:FindFirstChild("CrystalGrottoReturn")
local crystalHeart = crystalGrotto and crystalGrotto:FindFirstChild("CrystalGrottoHeart")
local crystalRuneParts = {}
local crystalRuneSequence = {"CrystalRuneMoon", "CrystalRuneDawn", "CrystalRuneTide"}
for _, runeName in crystalRuneSequence do
    crystalRuneParts[runeName] = crystalGrotto and crystalGrotto:FindFirstChild(runeName)
end
local crystalCache = crystalGrotto and crystalGrotto:FindFirstChild("CrystalGrottoCache")
local crystalEchoGate = crystalGrotto and crystalGrotto:FindFirstChild("CrystalEchoGate")
local crystalEchoArrival = crystalGrotto and crystalGrotto:FindFirstChild("CrystalEchoArrival", true)
local crystalEchoReturn = crystalGrotto and crystalGrotto:FindFirstChild("CrystalEchoReturn", true)
local prismSeed = crystalGrotto and crystalGrotto:FindFirstChild("PrismSeed", true)
local crystalEchoInside = {}
local crystalGrottoInside = {}
local crystalRuneProgress = {}

if crystalEntrance and crystalArrival then
    connectTrialPrompt(crystalEntrance, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not session or not player:GetAttribute("Ready") or not root or not humanoid or humanoid.Health <= 0 then return end
        if not player:GetAttribute("MoonRelic") then
            return tip(player, "Сначала найди звёздный осколок в Лунных руинах. Он пробудит кристаллы у входа.")
        end
        if (root.Position - crystalEntrance.Position).Magnitude > 11 then return end
        crystalGrottoInside[player] = true
        player:SetAttribute("InCrystalGrotto", true)
        local firstDiscovery = player:GetAttribute("CrystalGrottoDiscovered") ~= true
        player:SetAttribute("CrystalGrottoDiscovered", true)
        local coinBonus = firstDiscovery and grantExplorationCoins(player, "CrystalGrottoDiscovered") or 0
        character:PivotTo(crystalArrival.CFrame * CFrame.new(0, 4, 0))
        tip(player, "Кристальная пещера открыта! Исследуй зал и найди древнее сердце. +" .. tostring(coinBonus) .. " монет.")
        if session.online then save(player) end
    end)
end

if crystalReturn and crystalEntrance then
    connectTrialPrompt(crystalReturn, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not session or not crystalGrottoInside[player] or not character or not root then return end
        if (root.Position - crystalReturn.Position).Magnitude > 11 then return end
        crystalGrottoInside[player] = nil
        crystalEchoInside[player] = nil
        player:SetAttribute("InCrystalGrotto", false)
        character:PivotTo(crystalEntrance.CFrame * CFrame.new(0, 0, -7))
        tip(player, "Ты вернулся в Сумеречную долину.")
    end)
end

-- Crystal Grotto memory puzzle: progress is per player and the completed seal is persistent.
for expectedIndex, runeName in crystalRuneSequence do
    local runePart = crystalRuneParts[runeName]
    if runePart then
        connectTrialPrompt(runePart, function(player)
            local session = sessions[player]
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not session or not crystalGrottoInside[player] or not root or not humanoid or humanoid.Health <= 0 then return end
            if (root.Position - runePart.Position).Magnitude > 11 then return end
            if player:GetAttribute("CrystalRunes") then
                return tip(player, "Печать уже пробуждена. Тайник открыт.")
            end

            local now = os.clock()
            local state = crystalRuneProgress[player]
            if not state or now - state.lastAt > 25 then
                state = {nextIndex = 1, lastAt = now}
                crystalRuneProgress[player] = state
            end
            state.lastAt = now

            if runeName ~= crystalRuneSequence[state.nextIndex] then
                state.nextIndex = runeName == crystalRuneSequence[1] and 2 or 1
                tip(player, state.nextIndex == 2
                    and "Луна отозвалась! Теперь пробуди Рассвет."
                    or "Руны погасли. Подсказка у входа поможет вспомнить порядок.")
                return
            end

            state.nextIndex += 1
            if state.nextIndex > #crystalRuneSequence then
                crystalRuneProgress[player] = nil
                local firstDiscovery = player:GetAttribute("CrystalRunes") ~= true
                player:SetAttribute("CrystalRunes", true)
                local coinBonus = firstDiscovery and grantExplorationCoins(player, "CrystalRunes") or 0
                tip(player, "Три руны запели в унисон! Древняя печать открыла тайник. +" .. tostring(coinBonus) .. " монет.")
                if session.online then save(player) end
            else
                local nextLabel = state.nextIndex == 2 and "Рассвет" or "Прилив"
                tip(player, "Руна пробуждена. Следующая: " .. nextLabel .. ".")
            end
        end)
    else
        warn("Crystal Grotto puzzle rune is missing:", runeName)
    end
end

if crystalCache then
    connectTrialPrompt(crystalCache, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not session or not crystalGrottoInside[player] or not root or not humanoid or humanoid.Health <= 0 then return end
        if (root.Position - crystalCache.Position).Magnitude > 11 then return end
        if not player:GetAttribute("CrystalRunes") then
            return tip(player, "Тайник запечатан. Сначала пробуди три руны: Луна, Рассвет, Прилив.")
        end
        if player:GetAttribute("CrystalCache") then
            return tip(player, "В тайнике больше нет сокровищ. Печать осталась в твоей коллекции.")
        end
        local firstDiscovery = player:GetAttribute("CrystalCache") ~= true
        player:SetAttribute("CrystalCache", true)
        local coinBonus = firstDiscovery and grantExplorationCoins(player, "CrystalCache") or 0
        session.inventory.CrystalSigil = (session.inventory.CrystalSigil or 0) + 1
        syncInventory(player)
        tip(player, "Сокровище найдено! Получена древняя печать ×1 и " .. tostring(coinBonus) .. " монет.")
        if session.online and not save(player) then
            warn("Crystal Grotto cache save will be retried:", player.UserId)
            tip(player, "Печать получена. Сохранение будет повторено автоматически.")
        end
    end)
end

-- Secret Echo Chamber: the ancient sigil opens a one-way discovery path to a rare seed.
if crystalEchoGate and crystalEchoArrival then
    connectTrialPrompt(crystalEchoGate, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not session or not crystalGrottoInside[player] or not root or not humanoid or humanoid.Health <= 0 then return end
        if (root.Position - crystalEchoGate.Position).Magnitude > 11 then return end
        if not player:GetAttribute("CrystalCache") or (session.inventory.CrystalSigil or 0) < 1 then
            return tip(player, "Дверь шепчет: принеси древнюю печать из тайника с тремя рунами.")
        end
        crystalEchoInside[player] = true
        local firstDiscovery = player:GetAttribute("CrystalEchoDiscovered") ~= true
        player:SetAttribute("CrystalEchoDiscovered", true)
        local coinBonus = firstDiscovery and grantExplorationCoins(player, "CrystalEchoDiscovered") or 0
        character:PivotTo(crystalEchoArrival.CFrame * CFrame.new(0, 4, 0))
        tip(player, "Секретная Эхо-камера открыта! Здесь растёт редкое призматическое семя. +" .. tostring(coinBonus) .. " монет.")
        if session.online then save(player) end
    end)
end

if crystalEchoReturn then
    connectTrialPrompt(crystalEchoReturn, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not session or not crystalEchoInside[player] or not character or not root then return end
        if (root.Position - crystalEchoReturn.Position).Magnitude > 11 then return end
        crystalEchoInside[player] = nil
        character:PivotTo(crystalEchoGate.CFrame * CFrame.new(0, 0, -7))
        tip(player, "Ты вернулся в главный зал Кристальной пещеры.")
    end)
end

if prismSeed then
    connectTrialPrompt(prismSeed, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not session or not crystalEchoInside[player] or not root or not humanoid or humanoid.Health <= 0 then return end
        if (root.Position - prismSeed.Position).Magnitude > 11 then return end
        if player:GetAttribute("PrismSeedFound") then
            return tip(player, "Призматическое семя уже хранится в твоей коллекции.")
        end
        local firstDiscovery = player:GetAttribute("PrismSeedFound") ~= true
        player:SetAttribute("PrismSeedFound", true)
        local coinBonus = firstDiscovery and grantExplorationCoins(player, "PrismSeedFound") or 0
        session.inventory.PrismSeed = (session.inventory.PrismSeed or 0) + 1
        syncInventory(player)
        tip(player, "Невероятная находка! Получено призматическое семя ×1 и " .. tostring(coinBonus) .. " монет.")
        if session.online and not save(player) then
            warn("Prism Seed reward save will be retried:", player.UserId)
            tip(player, "Семя получено. Сохранение будет повторено автоматически.")
        end
    end)
end

local crystalWispNest = crystalGrotto and crystalGrotto:FindFirstChild("CrystalWispNest", true)
if crystalWispNest then
    local crystalWisp = Storage:FindFirstChild("CrystalWisp")
    if crystalWisp and crystalWisp:IsA("Model") then
        local encounterModel = crystalWisp:Clone()
        encounterModel.Name = "CrystalWispEncounter"
        encounterModel:SetAttribute("CompanionId", "CrystalWisp")
        encounterModel.Parent = workspace:FindFirstChild("CombatTrainingGlade") or crystalGrotto
        encounterModel:PivotTo(CFrame.new(crystalWispNest.Position + Vector3.new(0, 2.1, 0)))
        prompt(crystalWispNest, pets.CrystalWisp, "Предложить семя", function(player)
            local session = sessions[player]
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not session or not root or not humanoid or humanoid.Health <= 0 then return end
            if not crystalEchoInside[player] or player:GetAttribute("CrystalEchoDiscovered") ~= true then
                return tip(player, "Светляк прячется глубже Эхо-камеры. Сначала открой её.")
            end
            if player:GetAttribute("CrystalWisp") == true then
                return tip(player, "Кристальный светляк уже стал твоим другом.")
            end
            if (session.inventory.PrismSeed or 0) < 1 then
                return tip(player, "Светляк тянется к призматическому семени. Найди его в центре камеры.")
            end
            session.inventory.PrismSeed -= 1
            session.companionDiscoveryBiomes = session.companionDiscoveryBiomes or {}
            session.companionDiscoveryBiomes.CrystalWisp = "CrystalGrotto"
            player:SetAttribute("CrystalWisp", true)
            ensureCompanionMutation(player, "CrystalWisp")
            player:SetAttribute("Companion", "CrystalWisp")
            syncInventory(player)
            syncCompanionProgress(player)
            tip(player, "Кристальный светляк принял семя! Теперь он будет путешествовать с тобой.")
            if session.online and not save(player) then
                warn("Crystal Wisp adoption save will be retried:", player.UserId)
                tip(player, "Светляк с тобой. Сохранение будет повторено автоматически.")
            end
        end)
    else
        warn("Crystal Wisp model is missing from ReplicatedStorage.")
    end
end

if crystalHeart then
    connectTrialPrompt(crystalHeart, function(player)
        local session = sessions[player]
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not session or not crystalGrottoInside[player] or not root or not humanoid or humanoid.Health <= 0 then return end
        if (root.Position - crystalHeart.Position).Magnitude > 11 then return end
        if player:GetAttribute("CrystalHeart") then
            return tip(player, "Сердце уже пробуждено. Его осколок хранится в твоей коллекции.")
        end
        local firstDiscovery = player:GetAttribute("CrystalHeart") ~= true
        player:SetAttribute("CrystalHeart", true)
        local coinBonus = firstDiscovery and grantExplorationCoins(player, "CrystalHeart") or 0
        session.inventory.CrystalShard = (session.inventory.CrystalShard or 0) + 1
        syncInventory(player)
        tip(player, "Редкая находка! Получен кристальный осколок ×1 и " .. tostring(coinBonus) .. " монет.")
        if session.online and not save(player) then
            warn("Crystal Grotto reward save will be retried:", player.UserId)
            tip(player, "Осколок получен. Сохранение временно задерживается и будет повторено автоматически.")
        end
    end)
end

-- Crystal Grotto environmental event: warn first, then strike a random safe-bounded spot.
local crystalFallRandom = Random.new()
local crystalFallActive = false

local function getCrystalGrottoPlayers()
    local active = {}
    for player, inside in crystalGrottoInside do
        if inside and player.Parent then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root then
                table.insert(active, player)
            end
        end
    end
    return active
end

local function runCrystalFallEvent()
    if crystalFallActive or not crystalGrotto or not crystalGrotto.Parent then return end
    local activePlayers = getCrystalGrottoPlayers()
    if #activePlayers == 0 then return end
    crystalFallActive = true

    local center = crystalGrotto:FindFirstChild("CrystalGrottoFloor")
    if not center or not center:IsA("BasePart") then
        crystalFallActive = false
        return
    end

    local impactPosition = center.Position + Vector3.new(
        crystalFallRandom:NextNumber(-16, 16),
        center.Size.Y / 2 + 0.2,
        crystalFallRandom:NextNumber(-13, 13)
    )
    local warning = Instance.new("Part")
    warning.Name = "CrystalFallWarning"
    warning.Shape = Enum.PartType.Cylinder
    warning.Size = Vector3.new(0.18, 16, 16)
    warning.CFrame = CFrame.new(impactPosition) * CFrame.Angles(0, 0, math.rad(90))
    warning.Anchored = true
    warning.CanCollide = false
    warning.CanTouch = false
    warning.Material = Enum.Material.Neon
    warning.Color = Color3.fromRGB(255, 151, 112)
    warning.Transparency = 0.3
    warning.Parent = crystalGrotto
    Debris:AddItem(warning, 5)

    for _, player in activePlayers do
        tip(player, "Осторожно! Сверху сыплются кристаллы — покинь отмеченную область!")
    end
    task.wait(3)

    local shard = Instance.new("Part")
    shard.Name = "CrystalFallShard"
    shard.Shape = Enum.PartType.Block
    shard.Size = Vector3.new(2.6, 6.5, 2.6)
    shard.CFrame = CFrame.new(impactPosition + Vector3.new(0, 22, 0))
        * CFrame.Angles(math.rad(12), 0, math.rad(18))
    shard.Anchored = true
    shard.CanCollide = false
    shard.Material = Enum.Material.Neon
    shard.Color = Color3.fromRGB(170, 126, 220)
    shard.Parent = crystalGrotto
    Debris:AddItem(shard, 3)

    local fallTween = TweenService:Create(
        shard,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {CFrame = CFrame.new(impactPosition + Vector3.new(0, 3.2, 0))}
    )
    fallTween:Play()
    fallTween.Completed:Wait()

    local impact = Instance.new("Part")
    impact.Name = "CrystalFallImpact"
    impact.Shape = Enum.PartType.Ball
    impact.Size = Vector3.new(1, 1, 1)
    impact.CFrame = CFrame.new(impactPosition + Vector3.new(0, 1, 0))
    impact.Anchored = true
    impact.CanCollide = false
    impact.Material = Enum.Material.Neon
    impact.Color = Color3.fromRGB(211, 164, 245)
    impact.Parent = crystalGrotto
    Debris:AddItem(impact, 0.7)
    TweenService:Create(
        impact,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(12, 1, 12), Transparency = 1}
    ):Play()

    for _, player in getCrystalGrottoPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and root
            and (root.Position - impactPosition).Magnitude <= 8 then
            humanoid:TakeDamage(18)
            tip(player, "Кристальный обвал задел тебя! Уходи от красной отметки заранее.")
        end
    end

    task.wait(0.8)
    crystalFallActive = false
end

task.spawn(function()
    while task.wait(crystalFallRandom:NextInteger(95, 145)) do
        if #getCrystalGrottoPlayers() > 0 then
            local ok, err = pcall(runCrystalFallEvent)
            if not ok then
                crystalFallActive = false
                warn("Crystal Grotto fall event failed:", err)
            end
        end
    end
end)

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
    crystalGrottoInside[player] = nil
    crystalRuneProgress[player] = nil
    crystalEchoInside[player] = nil
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

