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
local progress = {"Fox", "Moth", "Seed", "Flower", "Timber", "Lantern", "Lit"}
local inventoryKeys = {"SunPetal", "MoonPetal", "CarrotSeed", "Carrot"}
local farmPlotIds = {"Plot01", "Plot02", "Plot03", "Plot04"}
local cropDefinitions = {
    Carrot = {
        seedItemId = "CarrotSeed",
        harvestItemId = "Carrot",
        growthSeconds = 180,
    },
}
local resourceNodeIds = {
    GroveSunPetal01 = true,
    GroveSunPetal02 = true,
    DuskMoonPetal01 = true,
    DuskMoonPetal02 = true,
}
local sessions = {}
local createPersonalCity

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
    local rawFarm = type(raw.farm) == "table" and raw.farm or {}
    city.farm.level = math.clamp(math.floor(tonumber(rawFarm.level) or 1), 1, 3)
    local rawPlots = type(rawFarm.plots) == "table" and rawFarm.plots or {}

    for _, plotId in farmPlotIds do
        local saved = type(rawPlots[plotId]) == "table" and rawPlots[plotId] or {}
        local cropId = saved.cropId
        local plantedAt = safeTimestamp(saved.plantedAt)
        local readyAt = safeTimestamp(saved.readyAt)

        if cropDefinitions[cropId]
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

        local citySnapshot = normalizeCity(session.city)

        local ok, err = pcall(function()
            store:UpdateAsync(tostring(player.UserId), function(old)
                if type(old) ~= "table" then old = {} end
                for _, key in progress do
                    old[key] = old[key] == true or snapshot[key]
                end
                old.schemaVersion = 5

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

                -- Schema v5 moves the old city payload into the permanent island record.
                -- Keep this migration idempotent and preserve existing farm/building progress.
                local savedIsland = type(old.island) == "table" and old.island
                    or (type(old.city) == "table" and old.city or {})
                savedIsland.level = citySnapshot.level
                local savedFarm = type(savedIsland.farm) == "table" and savedIsland.farm or {}
                savedFarm.level = citySnapshot.farm.level
                savedFarm.plots = citySnapshot.farm.plots
                savedIsland.farm = savedFarm
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
        online = false,
    }
    for _, key in inventoryKeys do session.inventory[key] = 0 end
    session.inventory.CarrotSeed = 3
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
        end
        if not ok then player:SetAttribute("OfflineAlbum", true) end
    else
        player:SetAttribute("OfflineAlbum", true)
    end

    syncInventory(player)
    syncFarm(player)
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
event.OnServerEvent:Connect(function(player, action)
    if typeof(action) ~= "string" or not player:GetAttribute("Ready") then return end

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

local function refreshFarmPlotVisual(cityModel, plotId, farm)
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
            interaction.ObjectText = "Морковь"
        elseif os.time() >= state.readyAt then
            interaction.ActionText = "Собрать"
            interaction.ObjectText = "Морковь созрела"
        else
            interaction.ActionText = "Проверить"
            interaction.ObjectText = "Морковь растёт"
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
        refreshFarmPlotVisual(cityModel, plotId, session.city.farm)
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

    local now = os.time()
    if state.cropId == "" then
        if (session.inventory.CarrotSeed or 0) < 1 then
            return tip(player, "Семена закончились. Новые семена появятся у торговца позже.")
        end
        session.inventory.CarrotSeed -= 1
        state.cropId = "Carrot"
        state.plantedAt = now
        state.readyAt = now + cropDefinitions.Carrot.growthSeconds
        tip(player, "Морковь посажена! Она созреет примерно через 3 минуты.")
    else
        if now < state.readyAt then
            local remaining = state.readyAt - now
            return tip(player, "Морковь ещё растёт: осталось " .. tostring(math.ceil(remaining / 60)) .. " мин.")
        end
        session.inventory.Carrot = (session.inventory.Carrot or 0) + 1
        state.cropId = ""
        state.plantedAt = 0
        state.readyAt = 0
        tip(player, "Урожай собран: морковь ×1!")
    end

    syncInventory(player)
    syncFarm(player)
    refreshFarmCity(player, session.cityModel)
    if session.online and not save(player) then
        warn("Farm save will be retried:", player.UserId, plotId)
        tip(player, "Урожай сохранён в текущей сессии. Сохранение временно задерживается.")
    end
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

    if planter then
        prompt(planter, "Сад у дома", "Разбудить цветок", function(visitor)
            if visitor.UserId ~= player.UserId then return end
            if visitor:GetAttribute("Flower") then return tip(visitor, "Твой лунный цветок уже расцвёл.") end
            if not visitor:GetAttribute("Seed") then return tip(visitor, "Лисёнок чует семя на тропе возле гнезда.") end
            if visitor:GetAttribute("Companion") ~= "Moth" then return tip(visitor, "Позови лунную моль из альбома.") end
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

prompt(workspace.Grove.Trail,"Следы в траве","Попросить лисёнка искать",function(player)
    if player:GetAttribute("Companion") ~= "Fox" then return tip(player,"Позови лисёнка из альбома.") end
    if player:GetAttribute("Seed") then return tip(player,"Семя уже найдено. Лунная моль поможет ему расцвести.") end
    player:SetAttribute("Seed",true)
    tip(player,"Лисёнок выкопал лунное семя! Отправляйся за молью.")
end)

prompt(workspace.Grove.Driftwood,"Коряга на берегу","Искать сухие ветви",function(player)
    if not player:GetAttribute("Flower") then return tip(player,"Сначала вырасти лунный цветок у дома.") end
    if player:GetAttribute("Timber") then return tip(player,"Ветви уже собраны. Площадка рядом с домом.") end
    if player:GetAttribute("Companion") ~= "Fox" then return tip(player,"Позови лисёнка. Он найдёт крепкие ветви.") end
    player:SetAttribute("Timber",true)
    tip(player,"Лисёнок нашёл ветви для садового фонаря!")
end)

-- Islands are fixed. Players walk between them over permanent bridges.
-- The old helm/sailing and shore-call-bell loop is intentionally retired.

-- Per-player city models overlap the shared prototype visually; the client renders
-- only its owner's city while every interaction is validated against OwnerUserId.
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

