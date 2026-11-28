local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local storage = ReplicatedStorage
local event = storage:WaitForChild("AlbumAction")

local palette = {
    deep = Color3.fromRGB(31, 54, 49),
    deepSoft = Color3.fromRGB(43, 69, 61),
    surface = Color3.fromRGB(57, 88, 76),
    surfaceLight = Color3.fromRGB(76, 111, 91),
    cream = Color3.fromRGB(255, 244, 216),
    muted = Color3.fromRGB(193, 211, 188),
    mint = Color3.fromRGB(169, 218, 169),
    gold = Color3.fromRGB(255, 202, 119),
    coral = Color3.fromRGB(232, 146, 117),
    water = Color3.fromRGB(135, 211, 231),
    lilac = Color3.fromRGB(204, 181, 238),
    lilacLight = Color3.fromRGB(230, 213, 252),
    moon = Color3.fromRGB(255, 242, 190),
    shadow = Color3.fromRGB(19, 35, 32),
}

-- Shared companion names are still used by proximity prompts and visual followers.
local names = {
    Fox = "Лисёнок-корешок",
    Moth = "Лунная моль",
    CrystalWisp = "Кристальный светляк",
    HarvestSprite = "Тыквик",
    BrambleBun = "Колючка",
    MossTurtle = "Мохопанцирь",
    Glowcap = "Светошляп",
    Dewdrop = "Росинка",
    Starling = "Звёздокрыл",
}

-- One clear discovery marker at a time; personal quest progress remains server-owned.
local GroveFirstSteps = require(storage:WaitForChild("GroveFirstSteps"))
local groveFirstSteps = GroveFirstSteps.new(player)

local function getHomeIsland()
    local folder = workspace:FindFirstChild("PlayerIslands")
    return folder and folder:FindFirstChild("HomeIsland_" .. tostring(player.UserId))
end

local foxCacheIds = {"FoxCache01", "FoxCache02", "FoxCache03"}
local foxCachePrompts = {}
local foxCacheHighlights = {}
local foxSniffUntil = 0
local pettingUntil = {Fox = 0, Moth = 0, CrystalWisp = 0, HarvestSprite = 0, BrambleBun = 0, MossTurtle = 0, Glowcap = 0, Dewdrop = 0, Starling = 0}
local companionSearchUntil = 0
local pendingGiftDiscovery = nil
local pendingPetBurst = {}
local lastFoxCacheSpot = ""
local foxScentTrailFolder = nil
local foxScentTrailCacheId = ""

local function clearFoxScentTrail()
    if foxScentTrailFolder then
        foxScentTrailFolder:Destroy()
        foxScentTrailFolder = nil
    end
    foxScentTrailCacheId = ""
end

local function makeFoxScentPart(parent, name, size, frame, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = Enum.PartType.Ball
    part.Size = size
    part.CFrame = frame
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(255, 198, 112)
    part.Transparency = transparency or 0.24
    part.Parent = parent
    return part
end

local function createFoxPawPrint(parent, position, direction, index)
    local side = index % 2 == 0 and 1 or -1
    local sideVector = Vector3.new(-direction.Z, 0, direction.X)
    local printPosition = position + sideVector * (0.38 * side)
    local frame = CFrame.lookAt(printPosition, printPosition + direction)
    local print = Instance.new("Model")
    print.Name = "FoxScentPaw" .. string.format("%02d", index)
    print.Parent = parent

    makeFoxScentPart(print, "Pad", Vector3.new(0.42, 0.07, 0.34), frame * CFrame.new(0, 0.04, 0.12), 0.24)
    local toes = {
        {x = -0.17, z = -0.11},
        {x = -0.055, z = -0.19},
        {x = 0.055, z = -0.19},
        {x = 0.17, z = -0.11},
    }
    for toeIndex, toe in toes do
        makeFoxScentPart(
            print,
            "Toe" .. tostring(toeIndex),
            Vector3.new(0.16, 0.07, 0.16),
            frame * CFrame.new(toe.x, 0.045, toe.z),
            0.18
        )
    end
end

local function updateFoxScentTrail(grove, activeCacheId, foxEquipped)
    if not foxEquipped or type(activeCacheId) ~= "string" or activeCacheId == "" then
        clearFoxScentTrail()
        return
    end

    local anchor = grove:FindFirstChild(activeCacheId)
    local trail = grove:FindFirstChild("Trail")
    local bank = grove:FindFirstChild("Bank")
    if not anchor or not anchor:IsA("BasePart") or not trail or not trail:IsA("BasePart") or not bank or not bank:IsA("BasePart") then
        clearFoxScentTrail()
        return
    end
    if foxScentTrailCacheId == activeCacheId and foxScentTrailFolder and foxScentTrailFolder.Parent then
        return
    end

    clearFoxScentTrail()
    local folder = Instance.new("Folder")
    folder.Name = "FoxScentTrailLocal"
    folder.Parent = workspace
    foxScentTrailFolder = folder
    foxScentTrailCacheId = activeCacheId

    local groundY = bank.Position.Y + bank.Size.Y / 2 + 0.13
    local groveCenter = bank.Position
    local startPosition = Vector3.new(trail.Position.X, groundY, trail.Position.Z + math.min(6, trail.Size.Z * 0.35))
    local finishPosition = Vector3.new(anchor.Position.X, groundY, anchor.Position.Z)
    local scentRouteOffsets = {
        FoxCache02 = {
            Vector3.new(10, 0, 16),
            Vector3.new(20, 0, 2),
            Vector3.new(27, 0, -5),
        },
        FoxCache03 = {
            Vector3.new(10, 0, 16),
            Vector3.new(20, 0, 0),
            Vector3.new(22, 0, -18),
            Vector3.new(5, 0, -32),
        },
    }
    local routePoints = {startPosition}
    for _, offset in scentRouteOffsets[activeCacheId] or {} do
        table.insert(routePoints, Vector3.new(groveCenter.X + offset.X, groundY, groveCenter.Z + offset.Z))
    end
    table.insert(routePoints, finishPosition)

    local printIndex = 0
    local moteIndex = 0
    for segmentIndex = 1, #routePoints - 1 do
        local segmentStart = routePoints[segmentIndex]
        local segmentEnd = routePoints[segmentIndex + 1]
        local segmentVector = segmentEnd - segmentStart
        local segmentDistance = segmentVector.Magnitude
        if segmentDistance > 2 then
            local direction = segmentVector.Unit
            local printCount = math.max(1, math.floor(segmentDistance / 3.8))
            for step = 1, printCount do
                printIndex += 1
                local alpha = step / (printCount + 1)
                local position = segmentStart:Lerp(segmentEnd, alpha)
                createFoxPawPrint(folder, position, direction, printIndex)
            end

            if segmentDistance > 8 then
                moteIndex += 1
                local motePosition = segmentStart:Lerp(segmentEnd, 0.5) + Vector3.new(0, 0.72 + (moteIndex % 2) * 0.12, 0)
                makeFoxScentPart(folder, "ScentMote" .. tostring(moteIndex), Vector3.new(0.14, 0.14, 0.14), CFrame.new(motePosition), 0.42)
            end
        end
    end
end

local function updateFoxCacheMarkers()
    local grove = workspace:FindFirstChild("Grove")
    if not grove then
        clearFoxScentTrail()
        return
    end
    local visuals = grove:FindFirstChild("FoxCacheVisuals")
    local activeCacheId = player:GetAttribute("FoxCacheSpot")
    local foxEquipped = player:GetAttribute("Companion") == "Fox"
    updateFoxScentTrail(grove, activeCacheId, foxEquipped)
    local currentCacheSpot = type(activeCacheId) == "string" and activeCacheId or ""
    if currentCacheSpot ~= "" and currentCacheSpot ~= lastFoxCacheSpot then
        foxSniffUntil = os.clock() + 2.2
    end
    lastFoxCacheSpot = currentCacheSpot

    for index, cacheId in foxCacheIds do
        local anchor = grove:FindFirstChild(cacheId)
        if anchor and anchor:IsA("BasePart") then
            local localPrompt = foxCachePrompts[cacheId]
            if not localPrompt or not localPrompt.Parent then
                local cacheIdForPrompt = cacheId
                localPrompt = Instance.new("ProximityPrompt")
                localPrompt.Name = "FoxCacheLocalPrompt"
                localPrompt.ObjectText = "Тайник лисёнка"
                localPrompt.ActionText = "Забрать находку"
                localPrompt.HoldDuration = 0.25
                localPrompt.MaxActivationDistance = 8
                localPrompt.RequiresLineOfSight = false
                localPrompt.Enabled = false
                localPrompt.Parent = anchor
                localPrompt.Triggered:Connect(function()
                    event:FireServer("CollectFoxCache", cacheIdForPrompt)
                end)
                foxCachePrompts[cacheId] = localPrompt
            end
            localPrompt.Enabled = activeCacheId == cacheId and foxEquipped
        end

        local visual = visuals and visuals:FindFirstChild("FoxCacheVisual" .. string.format("%02d", index))
        if visual then
            local highlight = foxCacheHighlights[cacheId]
            if not highlight or not highlight.Parent then
                highlight = Instance.new("Highlight")
                highlight.Name = "FoxCacheHighlight"
                highlight.Adornee = visual
                highlight.FillColor = Color3.fromRGB(255, 205, 112)
                highlight.OutlineColor = Color3.fromRGB(255, 239, 190)
                highlight.FillTransparency = 0.52
                highlight.OutlineTransparency = 0.04
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Enabled = false
                highlight.Parent = visual
                foxCacheHighlights[cacheId] = highlight
            end
            highlight.Enabled = activeCacheId == cacheId
        end
    end
end

local mothBloomPrompt = nil
local mothBloomHighlight = nil

local function updateMothBloomReveal()
    local dusk = workspace:FindFirstChild("Dusk")
    if not dusk then
        if mothBloomPrompt then mothBloomPrompt.Enabled = false end
        return
    end

    local anchor = dusk:FindFirstChild("MoonBloom")
    local visualFolder = dusk:FindFirstChild("MoonBloomVisuals")
    local visual = visualFolder and visualFolder:FindFirstChild("MoonBloomVisual")
    local mothEquipped = player:GetAttribute("Companion") == "Moth"
    local found = player:GetAttribute("MoonBloom") == true
    local revealed = mothEquipped or found

    if visual then
        for _, descendant in visual:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.LocalTransparencyModifier = revealed and 0 or 1
            elseif descendant:IsA("PointLight") then
                descendant.Enabled = revealed
            end
        end

        if not mothBloomHighlight or mothBloomHighlight.Parent ~= visual then
            mothBloomHighlight = Instance.new("Highlight")
            mothBloomHighlight.Name = "MoonBloomHighlight"
            mothBloomHighlight.Adornee = visual
            mothBloomHighlight.FillColor = Color3.fromRGB(199, 174, 239)
            mothBloomHighlight.OutlineColor = Color3.fromRGB(239, 224, 255)
            mothBloomHighlight.FillTransparency = 0.62
            mothBloomHighlight.OutlineTransparency = 0.08
            mothBloomHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            mothBloomHighlight.Parent = visual
        end
        mothBloomHighlight.Enabled = mothEquipped and not found
    end

    if anchor and anchor:IsA("BasePart") then
        if not mothBloomPrompt or mothBloomPrompt.Parent ~= anchor then
            mothBloomPrompt = Instance.new("ProximityPrompt")
            mothBloomPrompt.Name = "MoonBloomLocalPrompt"
            mothBloomPrompt.ObjectText = "Скрытый лунный цветок"
            mothBloomPrompt.ActionText = "Пробудить цветок"
            mothBloomPrompt.HoldDuration = 0.35
            mothBloomPrompt.MaxActivationDistance = 8
            mothBloomPrompt.RequiresLineOfSight = false
            mothBloomPrompt.Enabled = false
            mothBloomPrompt.Parent = anchor
            mothBloomPrompt.Triggered:Connect(function()
                event:FireServer("CollectMoonBloom")
            end)
        end
        mothBloomPrompt.Enabled = mothEquipped and not found
    end

end

local moonGatePrompts = {}
local moonGateHighlights = {}
local moonGateBarrier = nil
local lastMoonGateOpen = nil

local function updateMoonGateBarrier(runeAnchor, gateOpen)
    if gateOpen then
        if moonGateBarrier then
            local barrier = moonGateBarrier
            moonGateBarrier = nil
            task.delay(0.8, function()
                if barrier.Parent then barrier:Destroy() end
            end)
        end
        return
    end
    if not runeAnchor or not runeAnchor:IsA("BasePart") then
        if moonGateBarrier then
            moonGateBarrier:Destroy()
            moonGateBarrier = nil
        end
        return
    end

    if not moonGateBarrier or not moonGateBarrier.Parent then
        moonGateBarrier = Instance.new("Part")
        moonGateBarrier.Name = "MoonGateLocalBarrier"
        moonGateBarrier.Size = Vector3.new(6.35, 5.1, 1.25)
        moonGateBarrier.Anchored = true
        moonGateBarrier.Transparency = 1
        moonGateBarrier.CanCollide = true
        moonGateBarrier.CanTouch = false
        moonGateBarrier.CanQuery = false
        moonGateBarrier.CastShadow = false
        moonGateBarrier.Parent = workspace
    end
    local dusk = runeAnchor.Parent
    local bank = dusk and dusk:FindFirstChild("Bank")
    local floorY = bank and bank.Position.Y + bank.Size.Y / 2 + 0.13 or runeAnchor.Position.Y - 0.42
    moonGateBarrier.CFrame = CFrame.new(runeAnchor.Position.X, floorY + 2.55, runeAnchor.Position.Z - 2.25)
end

local function setLocalModelVisibility(model, visible, fadeDuration)
    if not model then return end
    local transparency = visible and 0 or 1
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            if fadeDuration and fadeDuration > 0 then
                TweenService:Create(
                    descendant,
                    TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {LocalTransparencyModifier = transparency}
                ):Play()
            else
                descendant.LocalTransparencyModifier = transparency
            end
        elseif descendant:IsA("PointLight") then
            descendant.Enabled = visible
        end
    end
end

local function setMoonGateHighlight(model, key, color, enabled)
    if not model then
        local existing = moonGateHighlights[key]
        if existing then existing.Enabled = false end
        return
    end
    local highlight = moonGateHighlights[key]
    if not highlight or highlight.Parent ~= model then
        if highlight then highlight:Destroy() end
        highlight = Instance.new("Highlight")
        highlight.Name = "MoonGate" .. key .. "Highlight"
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.OutlineColor = Color3.fromRGB(245, 230, 255)
        highlight.FillTransparency = 0.64
        highlight.OutlineTransparency = 0.08
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        moonGateHighlights[key] = highlight
    end
    highlight.Enabled = enabled
end

local function configureMoonGatePrompt(key, anchor, objectText, actionText, action, enabled)
    local prompt = moonGatePrompts[key]
    if anchor and (not prompt or prompt.Parent ~= anchor) then
        if prompt then prompt:Destroy() end
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "MoonGate" .. key .. "LocalPrompt"
        prompt.ObjectText = objectText
        prompt.ActionText = actionText
        prompt.HoldDuration = 0.35
        prompt.MaxActivationDistance = 8
        prompt.RequiresLineOfSight = false
        prompt.Enabled = false
        prompt.Parent = anchor
        prompt.Triggered:Connect(function()
            event:FireServer(action)
        end)
        moonGatePrompts[key] = prompt
    end
    if prompt then
        prompt.Enabled = anchor ~= nil and enabled
    end
end

local function updateMoonGatePuzzle()
    local dusk = workspace:FindFirstChild("Dusk")
    if not dusk then
        for _, prompt in moonGatePrompts do prompt.Enabled = false end
        for _, highlight in moonGateHighlights do highlight.Enabled = false end
        updateMoonGateBarrier(nil, false)
        return
    end

    local visuals = dusk:FindFirstChild("MoonGateVisuals")
    local tracksVisual = visuals and visuals:FindFirstChild("MoonGateTracksVisual")
    local runesVisual = visuals and visuals:FindFirstChild("MoonGateRunesVisual")
    local sealVisual = visuals and visuals:FindFirstChild("MoonGateSeal")
    local clearingVisual = visuals and visuals:FindFirstChild("MoonGateClearingVisual")
    local foxEquipped = player:GetAttribute("Companion") == "Fox"
    local mothEquipped = player:GetAttribute("Companion") == "Moth"
    local traceFound = player:GetAttribute("MoonGateTrace") == true
    local gateOpen = player:GetAttribute("MoonGateOpen") == true
    local relicCollected = player:GetAttribute("MoonRelic") == true
    local runeAnchor = dusk:FindFirstChild("MoonGateRune")

    local gateJustOpened = lastMoonGateOpen == false and gateOpen
    lastMoonGateOpen = gateOpen

    updateMoonGateBarrier(runeAnchor, gateOpen)
    setLocalModelVisibility(tracksVisual, (foxEquipped and player:GetAttribute("MoonBloom") == true) or traceFound)
    setLocalModelVisibility(runesVisual, gateOpen or (traceFound and mothEquipped))
    setLocalModelVisibility(sealVisual, not gateOpen, gateJustOpened and 0.8 or nil)
    setLocalModelVisibility(clearingVisual, gateOpen, gateJustOpened and 0.95 or nil)

    if clearingVisual then
        for _, descendant in clearingVisual:GetDescendants() do
            if descendant.Name == "MoonRelicGem" and descendant:IsA("BasePart") then
                descendant.LocalTransparencyModifier = relicCollected and 1 or 0
                local light = descendant:FindFirstChildOfClass("PointLight")
                if light then light.Enabled = not relicCollected end
            end
        end
    end

    setMoonGateHighlight(tracksVisual, "Tracks", Color3.fromRGB(255, 202, 119), foxEquipped and not traceFound)
    setMoonGateHighlight(runesVisual, "Runes", Color3.fromRGB(204, 181, 238), traceFound and mothEquipped and not gateOpen)
    setMoonGateHighlight(clearingVisual, "Relic", Color3.fromRGB(239, 184, 91), gateOpen and not relicCollected)

    configureMoonGatePrompt(
        "Tracks",
        dusk:FindFirstChild("MoonGateTracks"),
        "Следы под корнями",
        "Попросить лисёнка искать",
        "SearchMoonGate",
        foxEquipped and player:GetAttribute("MoonBloom") == true and not traceFound
    )
    configureMoonGatePrompt(
        "Runes",
        dusk:FindFirstChild("MoonGateRune"),
        "Древние лунные руны",
        "Осветить руны",
        "RevealMoonGate",
        traceFound and mothEquipped and not gateOpen
    )
    configureMoonGatePrompt(
        "Relic",
        dusk:FindFirstChild("MoonRelic"),
        "Звёздный осколок",
        "Забрать реликвию",
        "CollectMoonRelic",
        gateOpen and not relicCollected
    )
end

player:GetAttributeChangedSignal("FoxCacheSpot"):Connect(updateFoxCacheMarkers)
player:GetAttributeChangedSignal("Companion"):Connect(updateFoxCacheMarkers)
player:GetAttributeChangedSignal("Companion"):Connect(updateMothBloomReveal)
player:GetAttributeChangedSignal("MoonBloom"):Connect(updateMothBloomReveal)
player:GetAttributeChangedSignal("Companion"):Connect(updateMoonGatePuzzle)
player:GetAttributeChangedSignal("MoonGateTrace"):Connect(updateMoonGatePuzzle)
player:GetAttributeChangedSignal("MoonGateOpen"):Connect(updateMoonGatePuzzle)
player:GetAttributeChangedSignal("MoonRelic"):Connect(updateMoonGatePuzzle)
-- Cosmetic harvest events live in a dedicated module; game inventory stays server-owned.
local findResourceNode
local HarvestMotion = require(storage:WaitForChild("HarvestMotion"))
local harvestMotion = HarvestMotion.new(player)
local playHarvestCameraShake = harvestMotion.playCameraShake
local HarvestFeedback = require(storage:WaitForChild("HarvestFeedback"))
local harvestFeedback = HarvestFeedback.new(player, function(nodeId)
    return findResourceNode(nodeId)
end, harvestMotion)
local showResourceHitFeedback = harvestFeedback.onHit
local clearResourceHitFeedback = harvestFeedback.clearHit
local playResourceRewardPickup = harvestFeedback.rewardPickup
local playResourceBreakFeedback = harvestFeedback.breakFeedback

workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "FoxCache01" or descendant.Name == "FoxCache02" or descendant.Name == "FoxCache03" or descendant.Name == "FoxCacheVisuals" or descendant.Name == "FoxCacheVisual01" or descendant.Name == "FoxCacheVisual02" or descendant.Name == "FoxCacheVisual03" or descendant.Name == "Trail" or descendant.Name == "Bank" then
        task.defer(updateFoxCacheMarkers)
    end
    if descendant.Name == "Dusk" or descendant.Name == "MoonBloom" or descendant.Name == "MoonBloomVisuals" or descendant.Name == "MoonBloomVisual" then
        task.defer(updateMothBloomReveal)
    end
    if descendant.Name == "Dusk" or descendant.Name == "MoonGateTracks" or descendant.Name == "MoonGateRune" or descendant.Name == "MoonRelic" or descendant.Name == "MoonGateVisuals" or descendant.Name == "MoonGateTracksVisual" or descendant.Name == "MoonGateRunesVisual" or descendant.Name == "MoonGateSeal" or descendant.Name == "MoonGateClearingVisual" then
        task.defer(updateMoonGatePuzzle)
    end
end)
updateFoxCacheMarkers()
updateMothBloomReveal()
updateMoonGatePuzzle()

findResourceNode = function(nodeId)
    for _, islandName in {"Grove", "Dusk"} do
        local island = workspace:FindFirstChild(islandName)
        local folder = island and island:FindFirstChild("ResourceNodes")
        local node = folder and folder:FindFirstChild(nodeId)
        if node and node:IsA("Model") then return node end
    end
    return nil
end

local resourceOriginalGeometry = setmetatable({}, {__mode = "k"})

local function captureResourceGeometry(model)
    local saved = resourceOriginalGeometry[model]
    if saved then return saved end
    saved = {}
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") and descendant.Name ~= "PromptAnchor" then
            saved[descendant] = {size = descendant.Size, cframe = descendant.CFrame}
        end
    end
    resourceOriginalGeometry[model] = saved
    return saved
end

local function playResourceBreakAnimation(nodeId)
    local model = findResourceNode(nodeId)
    if not model then return end
    local saved = captureResourceGeometry(model)
    local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
    for part, geometry in saved do
        if part.Parent then
            local targetCFrame = geometry.cframe * CFrame.new(
                isWood and 0 or (math.random() - 0.5) * 0.7,
                isWood and -0.7 or -0.45,
                isWood and 0 or (math.random() - 0.5) * 0.7
            ) * CFrame.Angles(math.rad(isWood and 12 or math.random(-24, 24)), 0, math.rad(math.random(-20, 20)))
            TweenService:Create(part, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = geometry.size * 0.12,
                CFrame = targetCFrame,
                LocalTransparencyModifier = 1,
            }):Play()
        end
    end
end

local function playResourceRegrowthBurst(model)
    local anchor = model.PrimaryPart or model:FindFirstChild("PromptAnchor")
    if not anchor or not anchor:IsA("BasePart") then return end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "LocalResourceRegrowth"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.35, 0.7)
    emitter.Speed = NumberRange.new(1.2, 2.8)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.RotSpeed = NumberRange.new(-70, 70)
    emitter.LightEmission = 0.7
    emitter.Color = string.find(model.Name, "Wood", 1, true)
        and ColorSequence.new(Color3.fromRGB(145, 207, 123), Color3.fromRGB(226, 231, 153))
        or ColorSequence.new(Color3.fromRGB(155, 193, 205), Color3.fromRGB(221, 226, 215))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.16),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Parent = anchor
    emitter:Emit(12)
    task.delay(1.1, function()
        if emitter.Parent then emitter:Destroy() end
    end)
end

local function restoreResourceGrowth(model)
    local saved = captureResourceGeometry(model)
    playResourceRegrowthBurst(model)
    for part, geometry in saved do
        if part.Parent then
            part.Size = geometry.size * 0.12
            part.CFrame = geometry.cframe * CFrame.new(0, -0.45, 0)
            part.LocalTransparencyModifier = 1
            TweenService:Create(part, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = geometry.size,
                CFrame = geometry.cframe,
                LocalTransparencyModifier = 0,
            }):Play()
        end
    end
end

-- Client-only visibility state is isolated; server cooldowns remain authoritative.
local ResourceNodeVisibility = require(storage:WaitForChild("ResourceNodeVisibility"))
local resourceVisibility = ResourceNodeVisibility.new(findResourceNode, restoreResourceGrowth)
local function applyResourceNodeState(nodeId, readyAt, unique)
    resourceVisibility.apply(nodeId, readyAt, unique)
end

workspace.DescendantAdded:Connect(resourceVisibility.onDescendantAdded)

event.OnClientEvent:Connect(function(message, payload)
    if message == "CompanionPetted" and type(payload) == "table" then
        local companionId = payload.companionId
        if companionId == "Fox" or companionId == "Moth" or companionId == "HarvestSprite" then
            pettingUntil[companionId] = os.clock() + 2.8
            pendingPetBurst[companionId] = math.clamp(math.floor(tonumber(payload.bondStage) or 0), 0, 4)
        end
        return
    elseif message == "ResourceState" and type(payload) == "table" then
        for nodeId in payload.collected or {} do
            applyResourceNodeState(nodeId, nil, true)
        end
        for nodeId, readyAt in payload.cooldowns or {} do
            applyResourceNodeState(nodeId, readyAt, false)
        end
        return
    elseif message == "ResourcePicked" and type(payload) == "table" then
        clearResourceHitFeedback(payload.nodeId)
        if payload.itemId ~= nil and payload.amount ~= nil then
            playResourceRewardPickup(payload)
            playHarvestCameraShake(0.58)
            playResourceBreakFeedback(payload.nodeId)
            playResourceBreakAnimation(payload.nodeId)
            task.delay(0.3, function()
                applyResourceNodeState(payload.nodeId, payload.readyAt, payload.unique == true)
            end)
        else
            -- Cooldown and already-collected responses only synchronize visibility;
            -- they must never replay a reward or a destruction animation.
            applyResourceNodeState(payload.nodeId, payload.readyAt, payload.unique == true)
        end
        return
    elseif message == "ResourceHit" and type(payload) == "table" then
        showResourceHitFeedback(payload)
        return
    end

    -- The unified GiantbackHUD owns visible notifications and quest navigation.
end)

task.spawn(function()
    if not player:GetAttribute("Ready") then
        player:GetAttributeChangedSignal("Ready"):Wait()
    end
    event:FireServer("RequestResourceState")
end)

-- Companion followers are local visual models. The wild encounter remains available
-- to other players, but is hidden locally once this player has adopted that companion.
local models = {}
local animationStates = {}
local CompanionActivity = require(storage:WaitForChild("CompanionActivity"))
local companionActivity = CompanionActivity.new()
local encounterLocations = {
    Fox = "Grove",
    Moth = "Dusk",
    CrystalWisp = "CombatTrainingGlade",
}

local mothAbilityUntil = 0
local pendingMothBurst = false

local function playMothAbilityBurst(model)
    mothAbilityUntil = os.clock() + 2.4
    if not model or not model.Parent then
        pendingMothBurst = true
        return
    end

    pendingMothBurst = false
    local origin = model:GetPivot().Position + Vector3.new(0, 0.55, 0)
    local burst = Instance.new("Folder")
    burst.Name = "MothAbilityBurstLocal"
    burst.Parent = workspace

    for index = 1, 12 do
        local angle = (index - 1) * math.pi * 2 / 12
        local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local startPosition = origin + direction * 0.48 + Vector3.new(0, (index % 3) * 0.12, 0)
        local mote = Instance.new("Part")
        mote.Name = "LunarSpark"
        mote.Shape = Enum.PartType.Ball
        mote.Size = Vector3.new(0.2, 0.2, 0.2)
        mote.CFrame = CFrame.new(startPosition)
        mote.Anchored = true
        mote.CanCollide = false
        mote.CanTouch = false
        mote.CanQuery = false
        mote.CastShadow = false
        mote.Material = Enum.Material.Neon
        mote.Color = index % 3 == 0 and palette.gold or palette.lilac
        mote.Transparency = 0.08
        mote.Parent = burst

        local finishPosition = startPosition + direction * (1.45 + (index % 3) * 0.22) + Vector3.new(0, 1.0 + (index % 4) * 0.16, 0)
        local tween = TweenService:Create(
            mote,
            TweenInfo.new(0.82, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = CFrame.new(finishPosition),
                Size = Vector3.new(0.035, 0.035, 0.035),
                Transparency = 1,
            }
        )
        tween:Play()
    end

    Debris:AddItem(burst, 1.0)
end

local function celebrateMothAbility()
    if player:GetAttribute("Companion") ~= "Moth" then return end
    playMothAbilityBurst(models[player])
end

-- All species-specific part animation lives in a standalone cosmetic module.
-- Lifecycle and per-model state remain here; live ability timers are passed each frame.
local CompanionAnimation = require(storage:WaitForChild("CompanionAnimation"))

local function captureAnimation(model, id, isEncounter, isLocal)
    local state = CompanionAnimation.capture(model, id, isEncounter, isLocal)
    animationStates[model] = state
    return state
end

local function animateModelParts(model, state, time, moving, resting)
    CompanionAnimation.animate(model, state, time, moving, resting,
        player, foxSniffUntil, mothAbilityUntil, pettingUntil, state.searching == true)
end

-- Sleep glyphs are client-only; the activity module owns idle thresholds.
local CompanionSleepVisuals = require(storage:WaitForChild("CompanionSleepVisuals"))
local sleepVisuals = CompanionSleepVisuals.new(palette)
local setSleepIndicator = sleepVisuals.setEnabled

local function updateEncounterVisibility(id)
    local islandName = encounterLocations[id]
    local island = islandName and workspace:FindFirstChild(islandName)
    if not island then return end

    local owned = player:GetAttribute(id) == true
    local encounter = island:FindFirstChild(id .. "Encounter")
    if encounter then
        for _, part in encounter:GetDescendants() do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = owned and 1 or 0
            end
        end
    end

    local grotto = id == "CrystalWisp" and island:FindFirstChild("CrystalGrotto")
    local nest = id == "CrystalWisp" and grotto and grotto:FindFirstChild("CrystalWispNest") or island:FindFirstChild("Nest")
    local prompt = nest and nest:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        prompt.Enabled = not owned
    end
end

for id in encounterLocations do
    player:GetAttributeChangedSignal(id):Connect(function()
        updateEncounterVisibility(id)
    end)
    updateEncounterVisibility(id)
end

workspace.DescendantAdded:Connect(function(instance)
    if instance.Name == "FoxEncounter" or instance.Name == "MothEncounter" or instance.Name == "CrystalWispEncounter" or instance:IsA("ProximityPrompt") then
        task.defer(function()
            for id in encounterLocations do updateEncounterVisibility(id) end
        end)
    end
end)

-- World pet prompts and friendship particles share one client presentation module.
local CompanionInteractions = require(storage:WaitForChild("CompanionInteractions"))
local interactions = CompanionInteractions.new(player, event, names, palette, function(companionId)
    if player:GetAttribute("Companion") == companionId then
        companionSearchUntil = os.clock() + 3.8
    end
end)
local playCompanionPettingBurst = interactions.playCompanionPettingBurst
local playCompanionGiftDiscovery = interactions.playCompanionGiftDiscovery

local function showPendingGiftDiscovery()
    if not pendingGiftDiscovery then return end
    local model = models[player]
    if not model or model.Name ~= pendingGiftDiscovery.companionId then return end
    playCompanionGiftDiscovery(model, pendingGiftDiscovery.companionId, pendingGiftDiscovery.rarity)
    pendingGiftDiscovery = nil
end

player:GetAttributeChangedSignal("CompanionGiftSearchSerial"):Connect(function()
    local result = player:GetAttribute("CompanionGiftSearchResult")
    if type(result) ~= "string" then return end
    local itemId, amount, rarity = string.match(result, "^([^|]+)|(%d+)|([^|]+)$")
    if not itemId or not amount then return end
    local companionId = player:GetAttribute("Companion")
    if not names[companionId] then return end
    pendingGiftDiscovery = {companionId = companionId, rarity = rarity or "common"}
    showPendingGiftDiscovery()
end)
local attachWorldPetPrompt = interactions.attachWorldPetPrompt
local showCompanionAttention = interactions.showCompanionAttention

-- The moth stardust appearance is a local presentation system.
local MothStardust = require(storage:WaitForChild("MothStardust"))
local mothStardust = MothStardust.new(player, palette)
local attachMothStardust = mothStardust.attach
local updateMothStardust = mothStardust.update

-- Companion visuals are local; mutation rolls and levels remain server-owned.
local CompanionAppearance = require(storage:WaitForChild("CompanionAppearance"))
local appearance = CompanionAppearance.new(player, animationStates, captureAnimation)
local applyCompanionGrowth = appearance.growth
local applyCompanionMutation = appearance.mutation

-- Art selection is an isolated, read-only policy. Followers keep working with
-- the bundled Fox/Moth blockouts until a Studio-approved mesh rig is installed.
local CompanionTemplateResolver = require(storage:WaitForChild("CompanionTemplateResolver"))

local function companionTemplate(id)
    return CompanionTemplateResolver.resolve(storage, id)
end

local CompanionFollow = require(storage:WaitForChild("CompanionFollow"))

local function follow(dt)
    local now = workspace:GetServerTimeNow()

    for _, owner in Players:GetPlayers() do
        local character = owner.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local id = owner:GetAttribute("Companion")
        local model = models[owner]

        if model and (model.Name ~= id or not root) then
            animationStates[model] = nil
            setSleepIndicator(model, false)
            model:Destroy()
            models[owner] = nil
            model = nil
        end

        if root and names[id] then
            local target, phase = CompanionFollow.target(root, owner, id, now, owner == player)

            if model then
                applyCompanionMutation(model, owner, id)
            end

            if owner == player and id == "Moth" and model then
                updateMothStardust(model, owner)
            end

            if not model then
                local template = companionTemplate(id)
                if not template then continue end
                model = template:Clone()
                model.Name = id
                model.Parent = workspace
                applyCompanionGrowth(model, owner, id)
                applyCompanionMutation(model, owner, id)
                model:PivotTo(target)
                models[owner] = model
                captureAnimation(model, id, false, owner == player)
                if owner == player then
                    attachWorldPetPrompt(model, id)
                    showPendingGiftDiscovery()
                    if id == "Moth" then
                        attachMothStardust(model)
                    end
                end
                if owner == player and id == "Moth" and pendingMothBurst then
                    playMothAbilityBurst(model)
                end
            else
                applyCompanionGrowth(model, owner, id)
                applyCompanionMutation(model, owner, id)
                CompanionFollow.smooth(model, target, dt)
            end

            if owner == player and pendingPetBurst[id] ~= nil then
                local bondStage = pendingPetBurst[id]
                pendingPetBurst[id] = nil
                playCompanionPettingBurst(model, id, bondStage)
            end

            local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.08
            local resting, sleeping, sniff, attention, curious, playful, worldInterest = companionActivity.update(owner, id, now, moving, owner == player, model:GetPivot().Position)
            if sniff then foxSniffUntil = os.clock() + 2.2 end
            if attention and owner == player then showCompanionAttention(model, id) end
            setSleepIndicator(model, sleeping)

            local state = animationStates[model]
            if state then
                state.sleeping = sleeping
                state.curious = curious
                state.playful = playful
                state.worldInterest = worldInterest
                state.searching = owner == player and os.clock() < companionSearchUntil
                state.mood = owner:GetAttribute("Companion_" .. id .. "_Mood") or "Спокойствие"
                state.personality = owner:GetAttribute("Companion_" .. id .. "_Personality") or "Любопытный"
                animateModelParts(model, state, phase, moving, resting)
            end
        end
    end

    -- Wild companions gently idle at their nests. They remain visible to players
    -- who have not met them, while owners see only their own following companion.
    for id, islandName in encounterLocations do
        local island = workspace:FindFirstChild(islandName)
        local encounter = island and island:FindFirstChild(id .. "Encounter")
        if encounter then
            local state = animationStates[encounter] or captureAnimation(encounter, id, true)
            local phase = now + (id == "Fox" and 0 or 1.7)
            local bob = math.sin(phase * 2.5) * (id == "Fox" and 0.11 or 0.18)
            encounter:PivotTo(
                state.origin
                * CFrame.new(0, bob, 0)
                * CFrame.Angles(0, math.sin(phase * 0.7) * 0.045, math.sin(phase * 1.4) * 0.025)
            )
            animateModelParts(encounter, state, phase, false, false)
        end
    end
end

player:GetAttributeChangedSignal("MoonBloom"):Connect(function()
    if player:GetAttribute("MoonBloom") then celebrateMothAbility() end
end)
player:GetAttributeChangedSignal("MoonGateOpen"):Connect(function()
    if player:GetAttribute("MoonGateOpen") then celebrateMothAbility() end
end)
player:GetAttributeChangedSignal("Companion"):Connect(function()
    if player:GetAttribute("Companion") ~= "Moth" then
        pendingMothBurst = false
    end
end)

Players.PlayerRemoving:Connect(function(owner)
    companionActivity.forget(owner)
    if models[owner] then
        animationStates[models[owner]] = nil
        setSleepIndicator(models[owner], false)
        models[owner]:Destroy()
        models[owner] = nil
    end
end)

RunService.RenderStepped:Connect(follow)

-- The moonflower is a local visual attached to this player's permanent home island.
local function waitForHomePart(name)
    while player.Parent do
        local homeIsland = getHomeIsland()
        local part = homeIsland and homeIsland:FindFirstChild(name)
        if part then return part end
        task.wait(0.1)
    end
    return nil
end

local planter = waitForHomePart("Planter")
if not planter then return end
local flower

local function flowerPart(parent, name, size, frame, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Size = size
    part.CFrame = frame
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function bloom()
    if flower or not player:GetAttribute("Flower") then return end

    flower = Instance.new("Model")
    flower.Name = "Moonflower"

    local stem = flowerPart(flower, "Stem", Vector3.new(1.7, 0.16, 0.16), CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90)), palette.leaf, Enum.Material.Grass, Enum.PartType.Cylinder)
    flower.PrimaryPart = stem

    for i = 1, 2 do
        local side = i == 1 and -1 or 1
        flowerPart(flower, "Leaf", Vector3.new(0.9, 0.24, 0.52), CFrame.new(side * 0.42, 0.55, 0) * CFrame.Angles(0, 0, math.rad(side * 28)), palette.mint, Enum.Material.Grass, Enum.PartType.Ball)
    end

    for i = 1, 7 do
        local angle = (i - 1) * math.pi * 2 / 6
        local position = i == 7 and Vector3.new(0, 1.85, 0) or Vector3.new(math.cos(angle) * 0.62, 1.75, math.sin(angle) * 0.62)
        local size = i == 7 and Vector3.new(0.72, 0.62, 0.72) or Vector3.new(1.05, 0.48, 0.72)
        flowerPart(flower, "Moon petal", size, CFrame.new(position), i == 7 and palette.gold or palette.lilac, Enum.Material.Neon, Enum.PartType.Ball)
    end

    local glow = flowerPart(flower, "Flower glow", Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 1.92, 0), palette.cream, Enum.Material.Neon, Enum.PartType.Ball)
    local light = Instance.new("PointLight")
    light.Color = palette.lilac
    light.Range = 12
    light.Brightness = 0.9
    light.Parent = glow

    flower.Parent = workspace
    local function placeFlower()
        if flower then flower:PivotTo(planter.CFrame * CFrame.new(0, 1.05, 0)) end
    end
    placeFlower()
end

player:GetAttributeChangedSignal("Flower"):Connect(bloom)
bloom()

-- The garden lantern belongs to the player's own permanent island.
local base = waitForHomePart("LanternBase")
if not base then return end
local lantern
local lamp
local light

local function updateLantern()
    if not player:GetAttribute("Lantern") then return end

    if not lantern then
        lantern = Instance.new("Model")
        lantern.Name = "GardenLantern"

        local function piece(name, height, size, color, material)
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Size = size
            part.Color = color
            part.Material = material or Enum.Material.Wood
            part.CFrame = base.CFrame * CFrame.new(0, height, 0)
            part.Parent = lantern
            return part
        end

        local wood = Color3.fromRGB(129, 87, 62)
        local post = piece("Post", 1.8, Vector3.new(0.5, 3, 0.5), wood)
        piece("Shelf", 3.4, Vector3.new(1.7, 0.3, 1.7), wood)
        lamp = piece("Glass", 4.25, Vector3.new(1.3, 1.45, 1.3), Color3.fromRGB(242, 198, 127), Enum.Material.Glass)
        piece("Cap", 5.1, Vector3.new(1.85, 0.3, 1.85), Color3.fromRGB(79, 115, 101), Enum.Material.WoodPlanks)

        light = Instance.new("PointLight")
        light.Color = palette.gold
        light.Range = 16
        light.Brightness = 2
        light.Parent = lamp

        lantern.PrimaryPart = post
        lantern.Parent = workspace

        RunService.RenderStepped:Connect(function()
            if lantern and lantern.Parent then
                local target = base.CFrame * CFrame.new(0, 1.8, 0)
                if post.CFrame ~= target then
                    lantern:PivotTo(target)
                end
            end
        end)
    end

    light.Enabled = player:GetAttribute("Lit") == true
    lamp.Material = light.Enabled and Enum.Material.Neon or Enum.Material.Glass
    lamp.Transparency = light.Enabled and 0.08 or 0.22
end

player:GetAttributeChangedSignal("Lantern"):Connect(updateLantern)
player:GetAttributeChangedSignal("Lit"):Connect(updateLantern)
updateLantern()
