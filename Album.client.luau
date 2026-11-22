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
    lilac = Color3.fromRGB(204, 181, 238),
    shadow = Color3.fromRGB(19, 35, 32),
}

-- Shared companion names are still used by proximity prompts and visual followers.
local names = {
    Fox = "Лисёнок-корешок",
    Moth = "Лунная моль",
    CrystalWisp = "Кристальный светляк",
}

local function getHomeIsland()
    local folder = workspace:FindFirstChild("PlayerIslands")
    return folder and folder:FindFirstChild("HomeIsland_" .. tostring(player.UserId))
end

local foxCacheIds = {"FoxCache01", "FoxCache02", "FoxCache03"}
local foxCachePrompts = {}
local foxCacheHighlights = {}
local foxSniffUntil = 0
local pettingUntil = {Fox = 0, Moth = 0, CrystalWisp = 0}
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
local resourceHitBars = {}
local resourceHitEffects = {}
local lastToolSwingAt = 0
local toolSwingGeneration = 0
local cameraShakeGeneration = 0
local cameraShakeBinding = "PetKingdomsHarvestCamera_" .. tostring(player.UserId)

local function playHarvestCameraShake(intensity)
    if player:GetAttribute("HarvestCameraShakeEnabled") == false then return end
    local camera = workspace.CurrentCamera
    if not camera then return end

    cameraShakeGeneration += 1
    local generation = cameraShakeGeneration
    local startedAt = os.clock()
    local duration = 0.13
    local strength = math.clamp(tonumber(intensity) or 0.35, 0.12, 0.7)

    RunService:UnbindFromRenderStep(cameraShakeBinding)
    RunService:BindToRenderStep(cameraShakeBinding, Enum.RenderPriority.Camera.Value + 1, function()
        if generation ~= cameraShakeGeneration then
            RunService:UnbindFromRenderStep(cameraShakeBinding)
            return
        end
        local currentCamera = workspace.CurrentCamera
        if not currentCamera then
            RunService:UnbindFromRenderStep(cameraShakeBinding)
            return
        end
        local elapsed = os.clock() - startedAt
        if elapsed >= duration then
            RunService:UnbindFromRenderStep(cameraShakeBinding)
            return
        end

        local fade = 1 - elapsed / duration
        local offset = Vector3.new(
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 2,
            0
        ) * strength * fade * 0.045
        currentCamera.CFrame = currentCamera.CFrame * CFrame.new(offset)
    end)
end

local function playHarvestCharacterSwing(character, nodeId, generation)
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end

    local shoulder
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("Motor6D") and (descendant.Name == "RightShoulder" or descendant.Name == "Right Shoulder") then
            shoulder = descendant
            break
        end
    end
    if not shoulder then return end

    local elbow
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("Motor6D") and descendant.Name == "RightElbow" then
            elbow = descendant
            break
        end
    end

    local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
    local windup = CFrame.Angles(math.rad(isWood and -58 or -42), 0, math.rad(-18))
    local impact = CFrame.Angles(math.rad(isWood and 48 or 64), 0, math.rad(12))
    local elbowBend = math.rad(isWood and 24 or 34)
    local startedAt = os.clock()
    local bindingName = "PetKingdomsHarvestSwing_" .. tostring(player.UserId)

    RunService:UnbindFromRenderStep(bindingName)
    RunService:BindToRenderStep(bindingName, Enum.RenderPriority.Last.Value, function()
        if generation ~= toolSwingGeneration or player.Character ~= character or not character.Parent or not shoulder.Parent then
            RunService:UnbindFromRenderStep(bindingName)
            return
        end

        local elapsed = os.clock() - startedAt
        local phase
        local pose
        local bend
        if elapsed < 0.11 then
            phase = math.clamp(elapsed / 0.11, 0, 1)
            phase = phase * phase * (3 - 2 * phase)
            pose = CFrame.identity:Lerp(windup, phase)
            bend = elbowBend * phase
        elseif elapsed < 0.21 then
            phase = math.clamp((elapsed - 0.11) / 0.10, 0, 1)
            phase = phase * phase * (3 - 2 * phase)
            pose = windup:Lerp(impact, phase)
            bend = elbowBend * (1 - phase * 0.35)
        elseif elapsed < 0.39 then
            phase = math.clamp((elapsed - 0.21) / 0.18, 0, 1)
            phase = 1 - (1 - phase) * (1 - phase)
            pose = impact:Lerp(CFrame.identity, phase)
            bend = elbowBend * 0.65 * (1 - phase)
        else
            RunService:UnbindFromRenderStep(bindingName)
            return
        end

        -- Add the swing after the default Animator pose; this is a local-only presentation layer.
        shoulder.Transform = shoulder.Transform * pose
        if elbow and elbow.Parent then
            elbow.Transform = elbow.Transform * CFrame.Angles(-bend, 0, 0)
        end
    end)
end

local function playHarvestToolSwing(nodeId)
    local character = player.Character
    if not character then return end
    local tool
    for _, child in character:GetChildren() do
        if child:IsA("Tool") and child:GetAttribute("PetKingdomsToolId") then
            tool = child
            break
        end
    end
    if not tool then return end

    local now = os.clock()
    if now - lastToolSwingAt < 0.12 then return end
    lastToolSwingAt = now
    toolSwingGeneration += 1
    local generation = toolSwingGeneration
    local originalGrip = tool.Grip
    playHarvestCharacterSwing(character, nodeId, generation)
    local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
    local raise = originalGrip * CFrame.Angles(math.rad(18), 0, math.rad(isWood and 8 or -8))
    local impact = originalGrip * CFrame.Angles(isWood and math.rad(-52) or math.rad(-68), 0, math.rad(isWood and -12 or 10))

    local first = TweenService:Create(tool, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Grip = raise})
    local second = TweenService:Create(tool, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Grip = impact})
    local recover = TweenService:Create(tool, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Grip = originalGrip})
    first:Play()
    first.Completed:Once(function()
        if generation ~= toolSwingGeneration or not tool.Parent then return end
        second:Play()
    end)
    second.Completed:Once(function()
        if generation ~= toolSwingGeneration or not tool.Parent then return end
        recover:Play()
    end)
end

local function ensureHarvestDamageOverlay(node, nodeId, hits, maximum)
    local targetName = nodeId:find("Wood", 1, true) and "Trunk" or "StoneMain"
    local target = node:FindFirstChild(targetName)
    if not target or not target:IsA("BasePart") then return end

    local gui = target:FindFirstChild("LocalHarvestCracks")
    if not gui then
        gui = Instance.new("SurfaceGui")
        gui.Name = "LocalHarvestCracks"
        gui.Face = Enum.NormalId.Front
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 48
        gui.LightInfluence = 0.25
        gui.AlwaysOnTop = false
        gui.Parent = target
    end

    for _, child in gui:GetChildren() do child:Destroy() end
    local count = math.clamp(math.floor(hits), 0, math.max(1, maximum))
    local crackColor = nodeId:find("Wood", 1, true)
        and Color3.fromRGB(62, 39, 27)
        or Color3.fromRGB(55, 62, 64)
    local paths = {
        {x = 0.42, y = 0.18, w = 0.035, h = 0.35, r = -28},
        {x = 0.53, y = 0.39, w = 0.03, h = 0.3, r = 36},
        {x = 0.32, y = 0.55, w = 0.028, h = 0.28, r = -48},
        {x = 0.62, y = 0.65, w = 0.025, h = 0.24, r = 22},
    }
    local visibleCracks = math.clamp(math.ceil(count / math.max(1, maximum) * #paths), 1, #paths)
    for index = 1, visibleCracks do
        local path = paths[index]
        local line = Instance.new("Frame")
        line.Name = "Crack" .. tostring(index)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromScale(path.x, path.y)
        line.Size = UDim2.fromScale(path.w, path.h)
        line.Rotation = path.r
        line.BackgroundColor3 = crackColor
        line.BackgroundTransparency = 0.08
        line.BorderSizePixel = 0
        line.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = line
    end
end

local function playResourceRewardPickup(payload)
    if type(payload) ~= "table" then return end
    local itemId = payload.itemId
    if itemId ~= "Wood" and itemId ~= "Stone" then return end
    local node = findResourceNode(payload.nodeId)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not node or not root then return end

    local origin = node:GetPivot().Position + Vector3.new(0, 1.1, 0)
    local count = math.clamp(math.floor(tonumber(payload.amount) or 1), 1, 5)
    for index = 1, count do
        local pickup = Instance.new("Part")
        pickup.Name = "LocalResourceReward"
        pickup.Anchored = true
        pickup.CanCollide = false
        pickup.CanTouch = false
        pickup.CanQuery = false
        pickup.CastShadow = false
        pickup.Material = itemId == "Wood" and Enum.Material.Wood or Enum.Material.Slate
        pickup.Color = itemId == "Wood" and Color3.fromRGB(151, 101, 63) or Color3.fromRGB(151, 164, 169)
        pickup.Shape = itemId == "Wood" and Enum.PartType.Cylinder or Enum.PartType.Block
        pickup.Size = itemId == "Wood" and Vector3.new(0.34, 0.72, 0.34) or Vector3.new(0.48, 0.42, 0.46)
        local angle = (index - 1) * math.pi * 2 / count
        local spread = Vector3.new(math.cos(angle) * 0.5, 0.15 + index * 0.04, math.sin(angle) * 0.5)
        pickup.CFrame = CFrame.new(origin + spread) * CFrame.Angles(math.rad(20 + index * 13), angle, math.rad(18))
        pickup.Parent = workspace

        local start = pickup.CFrame
        local bounce = TweenService:Create(pickup, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            CFrame = start + Vector3.new(0, 0.65 + index * 0.06, 0),
        })
        bounce:Play()
        task.delay(0.2, function()
            if not pickup.Parent then return end
            local currentRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not currentRoot then pickup:Destroy() return end
            local destination = currentRoot.Position + Vector3.new(0, 1.1, 0)
            local collect = TweenService:Create(pickup, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                CFrame = CFrame.new(destination),
                Transparency = 1,
                Size = pickup.Size * 0.35,
            })
            collect:Play()
            collect.Completed:Once(function()
                if pickup.Parent then pickup:Destroy() end
            end)
        end)
    end
end

local function playResourceFinalBreakBurst(anchor, nodeId)
    if not anchor or not anchor:IsA("BasePart") then return end
    local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
    local accent = isWood and Color3.fromRGB(239, 190, 112) or Color3.fromRGB(190, 220, 232)

    -- A short expanding ground ring makes the final hit read differently from ordinary hits.
    local ring = Instance.new("Part")
    ring.Name = "LocalHarvestFinalBurst"
    ring.Shape = Enum.PartType.Cylinder
    ring.Material = Enum.Material.Neon
    ring.Color = accent
    ring.Transparency = 0.22
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Size = Vector3.new(0.08, 0.9, 0.9)
    ring.CFrame = CFrame.new(anchor.Position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = workspace
    local expand = TweenService:Create(ring, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.035, 4.2, 4.2),
        Transparency = 1,
    })
    expand:Play()
    Debris:AddItem(ring, 0.42)

    -- Extra local-only debris gives the completed harvest a stronger material-specific payoff.
    for index = 1, 9 do
        local angle = (index - 1) * math.pi * 2 / 9
        local fragment = Instance.new("Part")
        fragment.Name = "LocalHarvestFinalFragment"
        fragment.Material = isWood and Enum.Material.Wood or Enum.Material.Slate
        fragment.Color = isWood
            and (index % 2 == 0 and Color3.fromRGB(190, 145, 91) or Color3.fromRGB(112, 78, 52))
            or (index % 2 == 0 and Color3.fromRGB(163, 174, 177) or Color3.fromRGB(91, 104, 110))
        fragment.Size = isWood and Vector3.new(0.13, 0.09, 0.32) or Vector3.new(0.17, 0.16, 0.18)
        fragment.Anchored = true
        fragment.CanCollide = false
        fragment.CanTouch = false
        fragment.CanQuery = false
        fragment.CastShadow = false
        fragment.CFrame = CFrame.new(anchor.Position + Vector3.new(0, 0.65, 0))
        fragment.Parent = workspace

        local direction = Vector3.new(math.cos(angle), 0.65 + (index % 3) * 0.16, math.sin(angle))
        local target = fragment.CFrame + direction * (1.1 + (index % 2) * 0.35)
        local spin = CFrame.Angles(math.rad(index * 31), math.rad(index * 47), math.rad(index * 23))
        TweenService:Create(fragment, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = target * spin,
            Transparency = 1,
            Size = fragment.Size * 0.3,
        }):Play()
        Debris:AddItem(fragment, 0.46)
    end
end

local function playResourceBreakFeedback(nodeId)
    local node = findResourceNode(nodeId)
    if not node then return end
    local anchor = node.PrimaryPart or node:FindFirstChild("PromptAnchor")
    if not anchor or not anchor:IsA("BasePart") then return end
    local emitter = anchor:FindFirstChild("HarvestImpact")
    if emitter and emitter:IsA("ParticleEmitter") then
        emitter:Emit(20)
    end
    playResourceFinalBreakBurst(anchor, nodeId)
end

local function spawnHarvestChips(anchor, nodeId)
    if not anchor or not anchor:IsA("BasePart") then return end
    local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
    local material = isWood and Enum.Material.Wood or Enum.Material.Slate
    local colors = isWood
        and {Color3.fromRGB(151, 105, 66), Color3.fromRGB(190, 145, 91), Color3.fromRGB(112, 78, 52)}
        or {Color3.fromRGB(122, 137, 143), Color3.fromRGB(163, 174, 177), Color3.fromRGB(91, 104, 110)}

    for index = 1, 5 do
        local chip = Instance.new("Part")
        chip.Name = "LocalHarvestChip"
        chip.Size = isWood
            and Vector3.new(0.12 + math.random() * 0.12, 0.08, 0.22 + math.random() * 0.16)
            or Vector3.new(0.12 + math.random() * 0.1, 0.12 + math.random() * 0.1, 0.12 + math.random() * 0.1)
        chip.Material = material
        chip.Color = colors[math.random(1, #colors)]
        chip.Anchored = true
        chip.CanCollide = false
        chip.CanTouch = false
        chip.CanQuery = false
        chip.CastShadow = false
        chip.CFrame = anchor.CFrame * CFrame.new(
            (math.random() - 0.5) * 0.7,
            (math.random() - 0.5) * 0.55,
            (math.random() - 0.5) * 0.5
        )
        chip.Parent = workspace

        local drift = Vector3.new((math.random() - 0.5) * 1.8, 0.45 + math.random() * 0.9, (math.random() - 0.5) * 1.8)
        local destination = chip.CFrame + drift
        local rotation = CFrame.Angles(math.rad(math.random(-150, 150)), math.rad(math.random(-150, 150)), math.rad(math.random(-150, 150)))
        local tween = TweenService:Create(chip, TweenInfo.new(0.28 + math.random() * 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = destination * rotation,
            Transparency = 1,
            Size = chip.Size * 0.35,
        })
        tween:Play()
        Debris:AddItem(chip, 0.5)
    end
end

local function showResourceHitFeedback(payload)
    local nodeId = payload.nodeId
    if type(nodeId) ~= "string" then return end
    local node = findResourceNode(nodeId)
    if not node then return end
    playHarvestToolSwing(nodeId)

    local anchor = node.PrimaryPart or node:FindFirstChild("PromptAnchor")
    if not anchor or not anchor:IsA("BasePart") then return end
    spawnHarvestChips(anchor, nodeId)

    local bar = resourceHitBars[nodeId]
    if not bar or not bar.Parent then
        bar = Instance.new("BillboardGui")
        bar.Name = "LocalHarvestProgress"
        bar.Adornee = anchor
        bar.AlwaysOnTop = true
        bar.LightInfluence = 0
        bar.MaxDistance = 70
        bar.Size = UDim2.fromOffset(142, 34)
        bar.StudsOffset = nodeId:find("Wood") and Vector3.new(0, 5.1, 0) or Vector3.new(0, 3.1, 0)
        bar.Parent = player:WaitForChild("PlayerGui")

        local background = Instance.new("Frame")
        background.Name = "Background"
        background.Size = UDim2.fromScale(1, 1)
        background.BackgroundColor3 = Color3.fromRGB(31, 45, 39)
        background.BackgroundTransparency = 0.12
        background.BorderSizePixel = 0
        background.Parent = bar
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = background

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundColor3 = nodeId:find("Wood") and Color3.fromRGB(128, 190, 116) or Color3.fromRGB(151, 190, 207)
        fill.BorderSizePixel = 0
        fill.Parent = background
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 9)
        fillCorner.Parent = fill

        local label = Instance.new("TextLabel")
        label.Name = "Count"
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(255, 248, 224)
        label.TextStrokeTransparency = 0.65
        label.TextSize = 13
        label.ZIndex = 2
        label.Parent = background
        resourceHitBars[nodeId] = bar
    end

    local background = bar:FindFirstChild("Background")
    local fill = background and background:FindFirstChild("Fill")
    local label = background and background:FindFirstChild("Count")
    local hits = math.max(0, math.floor(tonumber(payload.hits) or 0))
    local maximum = math.max(1, math.floor(tonumber(payload.maxHits) or 1))
    playHarvestCameraShake(0.22 + 0.2 * math.clamp(hits / maximum, 0, 1))
    ensureHarvestDamageOverlay(node, nodeId, hits, maximum)
    if fill then
        TweenService:Create(fill, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(math.clamp(hits / maximum, 0, 1), 1),
        }):Play()
    end
    if label then label.Text = "Добыча " .. tostring(hits) .. "/" .. tostring(maximum) end

    local effectGeneration = (resourceHitEffects[nodeId] or 0) + 1
    resourceHitEffects[nodeId] = effectGeneration
    local origin = node:GetPivot()
    task.spawn(function()
        for _, offset in {Vector3.new(0, 0.13, 0), Vector3.new(0, -0.09, 0), Vector3.zero} do
            if resourceHitEffects[nodeId] ~= effectGeneration or not node.Parent then return end
            node:PivotTo(origin * CFrame.new(offset))
            task.wait(0.04)
        end
        if resourceHitEffects[nodeId] == effectGeneration and node.Parent then
            node:PivotTo(origin)
        end
    end)

    local emitter = anchor:FindFirstChild("HarvestImpact")
    if not emitter then
        emitter = Instance.new("ParticleEmitter")
        emitter.Name = "HarvestImpact"
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Rate = 0
        emitter.Lifetime = NumberRange.new(0.18, 0.38)
        emitter.Speed = NumberRange.new(2, 4)
        emitter.SpreadAngle = Vector2.new(150, 150)
        emitter.RotSpeed = NumberRange.new(-90, 90)
        emitter.LightEmission = 0.35
        emitter.Color = nodeId:find("Wood") and ColorSequence.new(Color3.fromRGB(183, 133, 83), Color3.fromRGB(235, 202, 139))
            or ColorSequence.new(Color3.fromRGB(151, 164, 169), Color3.fromRGB(220, 229, 226))
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Parent = anchor
    end
    emitter:Emit(7)
end

local function clearResourceHitFeedback(nodeId)
    local node = findResourceNode(nodeId)
    if node then
        for _, name in {"Trunk", "StoneMain"} do
            local target = node:FindFirstChild(name)
            local overlay = target and target:FindFirstChild("LocalHarvestCracks")
            if overlay then overlay:Destroy() end
        end
    end
    local bar = resourceHitBars[nodeId]
    resourceHitBars[nodeId] = nil
    resourceHitEffects[nodeId] = (resourceHitEffects[nodeId] or 0) + 1
    if bar then bar:Destroy() end
end

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

local resourceNodeHidden = {}
local resourceVisibilityGeneration = {}

local function findResourceNode(nodeId)
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

local function applyResourceNodeVisibility(model, visible)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = visible and 0 or 1
        elseif descendant:IsA("ProximityPrompt") then
            descendant.Enabled = visible
        end
    end
end

local function setResourceNodeVisible(nodeId, visible)
    resourceNodeHidden[nodeId] = not visible
    local model = findResourceNode(nodeId)
    if not model then return false end
    if visible then
        restoreResourceGrowth(model)
    end
    applyResourceNodeVisibility(model, visible)
    return true
end

local function hideResourceNodeWhenReady(nodeId, generation, attempts)
    if generation ~= resourceVisibilityGeneration[nodeId] then return end
    if setResourceNodeVisible(nodeId, false) then return end
    if attempts < 40 then
        task.delay(0.25, function()
            hideResourceNodeWhenReady(nodeId, generation, attempts + 1)
        end)
    end
end

local function applyResourceNodeState(nodeId, readyAt, unique)
    if type(nodeId) ~= "string" then return end
    local generation = (resourceVisibilityGeneration[nodeId] or 0) + 1
    resourceVisibilityGeneration[nodeId] = generation

    if unique then
        hideResourceNodeWhenReady(nodeId, generation, 0)
        return
    end

    local remaining = (tonumber(readyAt) or 0) - os.time()
    if remaining <= 0 then
        setResourceNodeVisible(nodeId, true)
        return
    end

    hideResourceNodeWhenReady(nodeId, generation, 0)
    task.delay(remaining, function()
        if resourceVisibilityGeneration[nodeId] == generation then
            setResourceNodeVisible(nodeId, true)
        end
    end)
end

workspace.DescendantAdded:Connect(function(descendant)
    if not descendant:IsA("Model") then return end
    local nodeId = descendant:GetAttribute("ResourceNodeId")
    if nodeId and resourceNodeHidden[nodeId] then
        applyResourceNodeVisibility(descendant, false)
    end
end)

event.OnClientEvent:Connect(function(message, payload)
    if message == "CompanionPetted" and type(payload) == "table" then
        local companionId = payload.companionId
        if companionId == "Fox" or companionId == "Moth" then
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
local companionActivity = {}
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

local function captureAnimation(model, id, isEncounter, isLocal)
    local pivot = model:GetPivot()
    local offsets = {}
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            offsets[part] = pivot:ToObjectSpace(part.CFrame)
        end
    end

    local state = {
        id = id,
        origin = pivot,
        offsets = offsets,
        isEncounter = isEncounter == true,
        isLocal = isLocal == true,
    }
    animationStates[model] = state
    return state
end

local function aroundPoint(point, rotation)
    return CFrame.new(point) * rotation * CFrame.new(-point)
end

local function animateModelParts(model, state, time, moving, resting)
    local pivot = model:GetPivot()
    local now = os.clock()
    local growthStage = math.clamp(math.floor(tonumber(model:GetAttribute("AppliedGrowthStage")) or 1), 1, 3)
    local sniffing = state.id == "Fox" and not state.isEncounter and now < foxSniffUntil
    local mothAbility = state.id == "Moth" and state.isLocal and now < mothAbilityUntil
    local prismSenseActive = state.id == "CrystalWisp" and state.isLocal
        and workspace:GetServerTimeNow() < (tonumber(player:GetAttribute("PrismSenseUntil")) or 0)
    local petting = not state.isEncounter and now < (pettingUntil[state.id] or 0)
    local body = model:FindFirstChild("Body")
    local bodyOffset = body and state.offsets[body]
    local rigOrigin = bodyOffset and bodyOffset.Position or Vector3.zero

    for part, offset in state.offsets do
        if part.Parent then
            local transform = CFrame.new()

            if state.id == "Fox" then
                if part.Name == "Body" and petting then
                    local affectionateDip = math.sin(time * 6.5) * 0.025
                    transform = CFrame.new(0, -0.09 + affectionateDip, 0.06)
                        * aroundPoint(offset.Position, CFrame.Angles(math.rad(-4), 0, 0))
                elseif part.Name == "Body" and resting then
                    transform = CFrame.new(0, math.sin(time * 1.8) * 0.035, 0)
                elseif part.Name == "Muzzle" and sniffing then
                    transform = CFrame.new(0, -0.14, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 12) * 0.045, 0, 0))
                elseif part.Name == "Tail" or part.Name == "Tail tip" then
                    local swaySpeed = sniffing and 9 or 4.2
                    local growthSway = ({[1] = 0.82, [2] = 1, [3] = 1.22})[growthStage]
                    local swayStrength = (sniffing and 0.48 or 0.3) * growthSway
                    if resting then
                        swaySpeed = 1.6
                        swayStrength = 0.12
                    end
                    if petting then
                        swaySpeed = 10.5
                        swayStrength = 0.72
                    end
                    local sway = math.sin(time * swaySpeed) * swayStrength
                    local tailHinge = rigOrigin + Vector3.new(0, 0.25, 0.95)
                    local tailRotation = part.Name == "Tail tip"
                        and CFrame.Angles(sway * 0.35, sway * 0.8, 0)
                        or CFrame.Angles(sway * 0.45, sway, sway * 0.2)
                    transform = aroundPoint(tailHinge, tailRotation)
                elseif part.Name == "Paw" or part.Name == "Paw toe" then
                    local growthStride = ({[1] = 0.82, [2] = 1, [3] = 1.12})[growthStage]
                    local stride = resting and 0 or moving and 0.32 or sniffing and 0.16 or petting and 0.11 or 0.055
                    stride *= growthStride
                    local phase = (math.abs(offset.Position.X) + math.abs(offset.Position.Z)) * 1.8
                    local step = math.sin(time * (moving and 10 or sniffing and 8 or petting and 7 or 2.4) + phase) * stride
                    transform = CFrame.new(0, math.max(0, step) * 0.16, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(step, 0, 0))
                elseif part.Name == "Ear" or part.Name == "Inner ear" then
                    local side = offset.Position.X >= rigOrigin.X and 1 or -1
                    local twitch = math.sin(time * (sniffing and 5 or petting and 6.5 or 2.2) + side)
                        * (sniffing and 0.09 or petting and 0.13 or 0.055)
                    local earHinge = rigOrigin + Vector3.new(side * 0.8, 0.55, -0.4)
                    transform = aroundPoint(earHinge, CFrame.Angles(0, 0, twitch * side))
                end
            elseif state.id == "Moth" then
                local side = offset.Position.X >= rigOrigin.X and 1 or -1
                if part.Name == "Wing" or part.Name == "Wing lower" or part.Name == "Wing tip"
                    or part.Name == "Wing lower tip" or part.Name == "Wing jewel" or part.Name == "Wing spot" then
                    local growthFlap = ({[1] = 0.88, [2] = 1, [3] = 1.16})[growthStage]
                    local flapSpeed = (mothAbility and 21 or 11.5) * growthFlap
                    local flapStrength = (mothAbility and 0.76 or 0.42) * growthFlap
                    if resting and not mothAbility then
                        flapSpeed = 3.2
                        flapStrength = 0.13
                    end
                    if petting and not mothAbility then
                        flapSpeed = 17
                        flapStrength = 0.62
                    end
                    local lowerPhase = string.find(part.Name, "lower") and 0.38 or 0
                    local flap = math.sin(time * flapSpeed + lowerPhase) * flapStrength
                    local wingHinge = rigOrigin + Vector3.new(side * 0.42, 0.28, 0)
                    transform = aroundPoint(wingHinge, CFrame.Angles(0, 0, flap * side))
                elseif part.Name == "Moth head" and petting then
                    local affectionateNod = math.sin(time * 7) * 0.055
                    transform = aroundPoint(offset.Position, CFrame.Angles(math.rad(5) + affectionateNod, 0, 0))
                elseif part.Name == "Antenna" or part.Name == "Antenna tip" then
                    local twitchSpeed = mothAbility and 7 or resting and 1.1 or 2.8
                    local twitchStrength = mothAbility and 0.14 or resting and 0.025 or 0.07
                    local antennaHinge = rigOrigin + Vector3.new(side * 0.34, 0.9, -0.55)
                    transform = aroundPoint(antennaHinge, CFrame.Angles(0, 0, math.sin(time * twitchSpeed + side) * twitchStrength * side))
                elseif part.Name == "Moonlight glow" then
                    local adultGlow = growthStage == 3 and 1.18 or growthStage == 2 and 1.06 or 1
                    local pulse = (mothAbility and (1.15 + math.sin(time * 12) * 0.35) or resting and 0.38 or 0.65) * adultGlow
                    if petting and not mothAbility then
                        pulse = 0.95 + math.sin(time * 8) * 0.2
                    end
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = pulse
                        light.Range = mothAbility and 14 or 9
                    end
                    transform = CFrame.new(0, math.sin(time * (mothAbility and 9 or 2.8)) * (mothAbility and 0.12 or 0.035), 0)
                        * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 3.2) * 0.08))
                end
            elseif state.id == "CrystalWisp" then
                local bobSpeed = resting and 1.35 or moving and 4.2 or 2.4
                local bobAmount = resting and 0.035 or moving and 0.1 or 0.065
                if petting then bobAmount += 0.025 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                local sway = math.sin(time * (prismSenseActive and 4.8 or 1.8)) * (prismSenseActive and 0.11 or 0.045)
                if string.match(part.Name, "^OrbitCrystal") then
                    local shardIndex = tonumber(string.match(part.Name, "(%d+)$")) or 1
                    local orbitSpeed = prismSenseActive and 1.85 or resting and 0.28 or 0.82
                    local phase = time * orbitSpeed + (shardIndex - 1) * (math.pi * 2 / 3)
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(rigOrigin, CFrame.Angles(math.sin(phase) * 0.12, phase, math.cos(phase) * 0.1))
                elseif part.Name == "Body" then
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(sway * 0.45, 0, sway))
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = prismSenseActive and (1.8 + math.sin(time * 9) * 0.45) or resting and 0.55 or 1.1
                        light.Range = prismSenseActive and 18 or 12
                    end
                elseif part.Name == "Core" then
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 2.8) * 0.08))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            end

            part.CFrame = pivot * transform * offset
        end
    end
end

local sleepIndicators = {}

local function setSleepIndicator(model, enabled)
    local current = sleepIndicators[model]
    if not enabled then
        if current then
            sleepIndicators[model] = nil
            current:Destroy()
        end
        return
    end
    if current or not model or not model.Parent then return end

    local anchor = model:FindFirstChild("Body") or model.PrimaryPart
    if not anchor or not anchor:IsA("BasePart") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CompanionSleepZLocal"
    billboard.Adornee = anchor
    billboard.Size = UDim2.fromOffset(76, 48)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.65, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 48
    billboard.Parent = anchor
    sleepIndicators[model] = billboard

    task.spawn(function()
        local glyphs = {"Z", "z", "z"}
        while sleepIndicators[model] == billboard and billboard.Parent and model.Parent do
            for index, glyphText in glyphs do
                if sleepIndicators[model] ~= billboard or not billboard.Parent then break end
                local glyph = Instance.new("TextLabel")
                glyph.Name = "SleepGlyph"
                glyph.AnchorPoint = Vector2.new(0.5, 0.5)
                glyph.Position = UDim2.fromScale(0.52, 0.78)
                glyph.Size = UDim2.fromOffset(24, 24)
                glyph.BackgroundTransparency = 1
                glyph.Text = glyphText
                glyph.TextColor3 = index == 1 and palette.cream or palette.lilac
                glyph.TextStrokeColor3 = palette.shadow
                glyph.TextStrokeTransparency = 0.35
                glyph.TextTransparency = 0.05
                glyph.Font = Enum.Font.GothamBlack
                glyph.TextScaled = true
                glyph.Rotation = (index - 2) * 9
                glyph.Parent = billboard

                local tween = TweenService:Create(
                    glyph,
                    TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Position = UDim2.fromScale(0.52 + (index - 2) * 0.17, 0.05),
                        TextTransparency = 1,
                        TextStrokeTransparency = 1,
                        Rotation = (index - 2) * 18,
                    }
                )
                tween:Play()
                task.wait(0.48)
                Debris:AddItem(glyph, 1.4)
            end
            task.wait(0.28)
        end
        if sleepIndicators[model] == billboard then
            sleepIndicators[model] = nil
            billboard:Destroy()
        end
    end)
end

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

local function playCompanionPettingBurst(model, companionId, bondStage)
    if not model or not model.Parent then return end
    bondStage = math.clamp(math.floor(tonumber(bondStage) or 0), 0, 4)
    local sparkCount = 5 + bondStage * 2
    local baseColor = companionId == "Fox" and palette.coral or companionId == "CrystalWisp" and palette.water or palette.lilac
    local sparkColor = baseColor:Lerp(palette.gold, bondStage / 4)
    local origin = model:GetPivot().Position + Vector3.new(0, companionId == "Fox" and 1.2 or companionId == "CrystalWisp" and 0.9 or 1.5, 0)
    local folder = Instance.new("Folder")
    folder.Name = "CompanionPettingBurstLocal"
    folder.Parent = workspace

    for index = 1, sparkCount do
        local anchor = Instance.new("Part")
        anchor.Name = "PettingSpark"
        anchor.Size = Vector3.new(0.1, 0.1, 0.1)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CFrame = CFrame.new(origin + Vector3.new((index - (sparkCount + 1) / 2) * 0.28, 0, 0))
        anchor.Parent = folder

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.fromOffset(34, 34)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.Parent = anchor

        local glyph = Instance.new("TextLabel")
        glyph.Size = UDim2.fromScale(1, 1)
        glyph.BackgroundTransparency = 1
        glyph.Text = bondStage >= 4 and (index % 2 == 0 and "♥" or "✧")
            or companionId == "Fox" and (index % 2 == 0 and "♥" or "✦")
            or (index % 2 == 0 and "✧" or "☾")
        glyph.TextColor3 = sparkColor
        glyph.TextStrokeTransparency = 0.55
        glyph.Font = Enum.Font.GothamBold
        glyph.TextScaled = true
        glyph.Parent = billboard

        local drift = Vector3.new((index - (sparkCount + 1) / 2) * 0.12, 1.05 + (index % 2) * 0.28 + bondStage * 0.08, 0)
        TweenService:Create(anchor, TweenInfo.new(0.78, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = anchor.CFrame + drift,
        }):Play()
        TweenService:Create(glyph, TweenInfo.new(0.78, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1,
            TextStrokeTransparency = 1,
            Rotation = (index % 2 == 0 and 1 or -1) * 22,
        }):Play()
    end

    Debris:AddItem(folder, 0.9)
end

local function attachWorldPetPrompt(model, companionId)
    if not model or not model.Parent then return end
    local anchor = model:FindFirstChild("Body") or model.PrimaryPart
    if not anchor or not anchor:IsA("BasePart") then return end
    if anchor:FindFirstChild("WorldPetPrompt") then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WorldPetPrompt"
    prompt.ObjectText = names[companionId] or "Питомец"
    prompt.ActionText = "Погладить"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 7
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    prompt.Parent = anchor

    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer and triggeringPlayer ~= player then return end
        if player:GetAttribute("Companion") ~= companionId then return end
        event:FireServer("PetCompanion", companionId)
    end)
end

local function attachMothStardust(model)
    if not model or not model.Parent then return end
    local glow = model:FindFirstChild("Moonlight glow", true)
    if not glow or not glow:IsA("BasePart") or glow:FindFirstChild("CompanionStardust") then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "CompanionStardustAttachment"
    attachment.Parent = glow

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "CompanionStardust"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(palette.lilacLight, palette.moon)
    emitter.LightEmission = 0.8
    local personality = player:GetAttribute("Companion_Moth_Personality")
    local personalityRates = {
        ["Любопытный"] = 9,
        ["Озорной"] = 12,
        ["Смелый"] = 7,
        ["Застенчивый"] = 4,
    }
    local bondStage = math.clamp(tonumber(player:GetAttribute("Companion_Moth_BondStage")) or 0, 0, 4)
    emitter.Rate = math.min(16, (personalityRates[personality] or 7) + math.floor(bondStage / 2))
    emitter.Lifetime = NumberRange.new(0.28, 0.55)
    emitter.Speed = NumberRange.new(0.12, 0.42)
    emitter.SpreadAngle = Vector2.new(150, 150)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-70, 70)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.12),
        NumberSequenceKeypoint.new(0.55, 0.075),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.12),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
end

local function updateMothStardust(model, owner)
    local glow = model and model:FindFirstChild("Moonlight glow", true)
    local emitter = glow and glow:FindFirstChild("CompanionStardust")
    if not emitter or not emitter:IsA("ParticleEmitter") then return end

    local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_Moth_BondStage")) or 0, 0, 4)
    if emitter:GetAttribute("AppliedBondStage") == bondStage then return end

    local personality = owner:GetAttribute("Companion_Moth_Personality")
    local personalityRates = {
        ["Любопытный"] = 9,
        ["Озорной"] = 12,
        ["Смелый"] = 7,
        ["Застенчивый"] = 4,
    }
    emitter.Rate = math.min(16, (personalityRates[personality] or 7) + math.floor(bondStage / 2))
    emitter:SetAttribute("AppliedBondStage", bondStage)
end

local function companionGrowthForLevel(level)
    level = math.clamp(math.floor(tonumber(level) or 1), 1, 5)
    if level >= 5 then
        return "Взрослый", 1.1, 3
    elseif level >= 3 then
        return "Подросток", 1, 2
    end
    return "Малыш", 0.9, 1
end

local function applyCompanionGrowth(model, owner, companionId)
    if not model or not model.Parent then return end
    local level = owner:GetAttribute("Companion_" .. companionId .. "_Level")
    local stageName, scale, stageId = companionGrowthForLevel(level)
    if model:GetAttribute("AppliedGrowthStage") == stageId then return end

    local currentState = animationStates[model]
    if currentState then
        local pivot = model:GetPivot()
        for part, offset in currentState.offsets do
            if part.Parent then
                part.CFrame = pivot * offset
            end
        end
    end

    model:ScaleTo(scale)
    model:SetAttribute("AppliedGrowthStage", stageId)
    model:SetAttribute("GrowthStageName", stageName)
    captureAnimation(model, companionId, false, owner == player)
end

local companionMutationVisuals = {
    Mossback = {color = Color3.fromRGB(117, 176, 112), outline = Color3.fromRGB(168, 218, 143)},
    Sunblessed = {color = Color3.fromRGB(255, 190, 93), outline = Color3.fromRGB(255, 220, 145)},
    Prismtail = {color = Color3.fromRGB(205, 151, 255), outline = Color3.fromRGB(241, 204, 255)},
    Moonveil = {color = Color3.fromRGB(151, 169, 255), outline = Color3.fromRGB(205, 215, 255)},
    Stardust = {color = Color3.fromRGB(177, 145, 255), outline = Color3.fromRGB(224, 204, 255)},
    Aurora = {color = Color3.fromRGB(117, 235, 215), outline = Color3.fromRGB(205, 255, 240)},
    Elderwood = {color = Color3.fromRGB(116, 194, 112), outline = Color3.fromRGB(225, 255, 173), legendary = true},
    Eclipse = {color = Color3.fromRGB(79, 62, 132), outline = Color3.fromRGB(255, 222, 151), legendary = true},
    PrismGlow = {color = Color3.fromRGB(187, 160, 255), outline = Color3.fromRGB(223, 214, 255)},
    EchoSpark = {color = Color3.fromRGB(99, 204, 219), outline = Color3.fromRGB(191, 248, 255)},
    Starseed = {color = Color3.fromRGB(255, 204, 124), outline = Color3.fromRGB(255, 238, 190)},
    HeartOfPrism = {color = Color3.fromRGB(143, 91, 230), outline = Color3.fromRGB(255, 224, 255), legendary = true},
}
local mutationOriginalColors = setmetatable({}, {__mode = "k"})

local function applyCompanionMutation(model, owner, companionId)
    if not model or not model.Parent then return end
    local mutationId = owner:GetAttribute("Companion_" .. companionId .. "_Mutation")
    local visual = type(mutationId) == "string" and companionMutationVisuals[mutationId] or nil
    local normalizedId = visual and mutationId or ""
    if model:GetAttribute("AppliedMutation") == normalizedId then return end

    local originals = mutationOriginalColors[model]
    if not originals then
        originals = {}
        mutationOriginalColors[model] = originals
    end
    for part, originalColor in originals do
        if part.Parent then part.Color = originalColor end
    end
    table.clear(originals)

    local highlight = model:FindFirstChild("CompanionMutationHighlight")
    if highlight then highlight:Destroy() end
    local oldAura = model:FindFirstChild("LegendaryMutationAttachment", true)
    if oldAura then oldAura:Destroy() end

    if visual then
        for _, descendant in model:GetDescendants() do
            if descendant:IsA("BasePart") then
                originals[descendant] = descendant.Color
                local accent = string.find(string.lower(descendant.Name), "tip")
                    or string.find(string.lower(descendant.Name), "jewel")
                    or string.find(string.lower(descendant.Name), "glow")
                    or string.find(string.lower(descendant.Name), "spot")
                descendant.Color = descendant.Color:Lerp(visual.color, accent and 0.58 or 0.24)
            end
        end

        highlight = Instance.new("Highlight")
        highlight.Name = "CompanionMutationHighlight"
        highlight.Adornee = model
        highlight.FillColor = visual.color
        highlight.OutlineColor = visual.outline
        highlight.FillTransparency = 0.94
        highlight.OutlineTransparency = 0.18
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = model

        if visual.legendary then
            local auraPart = model.PrimaryPart
            if not auraPart then
                for _, descendant in model:GetDescendants() do
                    if descendant:IsA("BasePart") then
                        auraPart = descendant
                        break
                    end
                end
            end
            if auraPart then
                local attachment = Instance.new("Attachment")
                attachment.Name = "LegendaryMutationAttachment"
                attachment.Parent = auraPart

                local particles = Instance.new("ParticleEmitter")
                particles.Name = "LegendaryMutationParticles"
                particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                particles.Color = ColorSequence.new(visual.color, visual.outline)
                particles.LightEmission = 0.8
                particles.Rate = 4
                particles.Lifetime = NumberRange.new(0.8, 1.4)
                particles.Speed = NumberRange.new(0.25, 0.65)
                particles.SpreadAngle = Vector2.new(180, 180)
                particles.Rotation = NumberRange.new(0, 360)
                particles.RotSpeed = NumberRange.new(-45, 45)
                particles.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.12),
                    NumberSequenceKeypoint.new(0.55, 0.2),
                    NumberSequenceKeypoint.new(1, 0),
                })
                particles.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.12),
                    NumberSequenceKeypoint.new(1, 1),
                })
                particles.Parent = attachment
            end
        end
    end
    model:SetAttribute("AppliedMutation", normalizedId)
end

-- Imported companion meshes opt in only after Studio visual/rig acceptance.
-- Unapproved or incomplete imports never replace the playable blockout.
local importedCompanionNames = {Fox = "FoxCompanion", Moth = "MothCompanion"}

local function companionTemplate(id)
    local fallback = storage:FindFirstChild(id)
    local importedName = importedCompanionNames[id]
    if not importedName then return fallback end
    local library = storage:FindFirstChild("AssetLibrary")
    local modelFolder = library and library:FindFirstChild("Models")
    local companions = modelFolder and modelFolder:FindFirstChild("Companions")
    local imported = companions and companions:FindFirstChild(importedName)
    if not imported or not imported:IsA("Model") then return fallback end

    -- Importing OBJ/MTL is not the same as completing a runtime-compatible rig.
    if imported:GetAttribute("GiantbackImportStatus") ~= "Approved" then return fallback end
    if imported:GetAttribute("GiantbackRuntimeReady") ~= true then return fallback end
    if imported:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true then return fallback end
    if imported:GetAttribute("GiantbackAssetKey") ~= (id == "Fox" and "fox_companion" or "moth_companion") then
        return fallback
    end
    local body = imported:FindFirstChild("Body", true)
    if not body or not body:IsA("MeshPart") then return fallback end
    local movingPartName = id == "Fox" and "Tail" or "Wing"
    local movingPart = imported:FindFirstChild(movingPartName, true)
    if not movingPart or not movingPart:IsA("MeshPart") then return fallback end

    return imported
end

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
            local phase = now + (owner.UserId % 19) * 0.17
            local bob = math.sin(phase * 2.8) * 0.14
            local followOffset
            if id == "Moth" and owner == player then
                local personality = owner:GetAttribute("Companion_Moth_Personality")
                local orbitSpeeds = {
                    ["Любопытный"] = 0.9,
                    ["Озорной"] = 1.18,
                    ["Смелый"] = 0.78,
                    ["Застенчивый"] = 0.52,
                }
                local orbitAngle = phase * (orbitSpeeds[personality] or 0.72)
                local personalityRadius = personality == "Застенчивый" and 0.24 or personality == "Озорной" and 0.52 or 0.38
                local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_Moth_BondStage")) or 0, 0, 4)
                local orbitRadius = math.max(0.2, personalityRadius - bondStage * 0.035)
                followOffset = CFrame.new(
                    2.25 + math.cos(orbitAngle) * orbitRadius,
                    1.05 + bob + math.sin(orbitAngle * 1.35) * (personality == "Застенчивый" and 0.09 or 0.16),
                    1.75 + math.sin(orbitAngle) * orbitRadius * 1.1
                )
            else
                followOffset = CFrame.new(2.8, (id == "Fox" and -1.35 or 1.05) + bob, 2.1)
            end
            local target = root.CFrame
                * followOffset
                * CFrame.Angles(0, math.sin(phase * 1.6) * 0.06, 0)

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
                model:PivotTo(model:GetPivot():Lerp(target, 1 - math.exp(-9 * dt)))
            end

            if owner == player and pendingPetBurst[id] ~= nil then
                local bondStage = pendingPetBurst[id]
                pendingPetBurst[id] = nil
                playCompanionPettingBurst(model, id, bondStage)
            end

            local activity = companionActivity[owner]
            if not activity or activity.companionId ~= id then
                local personality = owner:GetAttribute("Companion_" .. id .. "_Personality")
                local curiosityWindows = {
                    ["Любопытный"] = {5, 10},
                    ["Озорной"] = {6, 11},
                    ["Смелый"] = {9, 15},
                    ["Застенчивый"] = {15, 23},
                }
                local window = curiosityWindows[personality] or {7, 14}
                local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_" .. id .. "_BondStage")) or 0, 0, 4)
                local minDelay = math.max(4, window[1] - bondStage * 1.5)
                local maxDelay = math.max(minDelay + 1, window[2] - bondStage * 2)
                activity = {
                    companionId = id,
                    idleSince = now,
                    nextCuriosityAt = now + math.random(math.floor(minDelay), math.floor(maxDelay)),
                }
                companionActivity[owner] = activity
            end
            local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.08
            if moving then
                activity.idleSince = now
                activity.nextCuriosityAt = now + math.random(9, 16)
            elseif owner == player and id == "Fox" and now >= (activity.nextCuriosityAt or now + 10) then
                foxSniffUntil = os.clock() + 2.2
                local personality = owner:GetAttribute("Companion_Fox_Personality")
                local curiosityWindows = {
                    ["Любопытный"] = {7, 12},
                    ["Озорной"] = {8, 14},
                    ["Смелый"] = {12, 18},
                    ["Застенчивый"] = {20, 29},
                }
                local window = curiosityWindows[personality] or {13, 23}
                local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_Fox_BondStage")) or 0, 0, 4)
                local minDelay = math.max(5, window[1] - bondStage * 1.5)
                local maxDelay = math.max(minDelay + 1, window[2] - bondStage * 2)
                activity.nextCuriosityAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))
            end
            local idleSeconds = now - activity.idleSince
            local resting = not moving and idleSeconds >= 12
            local sleeping = not moving and idleSeconds >= 45
            setSleepIndicator(model, sleeping)

            local state = animationStates[model]
            if state then
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
    companionActivity[owner] = nil
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
