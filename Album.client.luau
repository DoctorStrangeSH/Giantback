local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

local gui = Instance.new("ScreenGui")
gui.Name = "GiantbackJournal"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
gui.Enabled = false -- Unified HUD lives in HUD.client.luau; this script keeps companion and resource visuals.
gui.Enabled = false -- Replaced by the unified GiantbackHUD; this script keeps companion and resource visuals.

local function round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 14)
    corner.Parent = instance
    return corner
end

local function outline(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or palette.mint
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.35
    stroke.Parent = instance
    return stroke
end

local function gradient(instance, top, bottom, rotation)
    local fill = Instance.new("UIGradient")
    fill.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, top),
        ColorSequenceKeypoint.new(1, bottom),
    })
    fill.Rotation = rotation or 90
    fill.Parent = instance
    return fill
end

local function label(parent, name, text, size, position, font, color)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.BackgroundTransparency = 1
    item.Position = position
    item.Size = size
    item.Font = font or Enum.Font.GothamMedium
    item.Text = text
    item.TextColor3 = color or palette.cream
    item.TextSize = 14
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Parent = parent
    return item
end

local function styledButton(parent, name, size, position, topColor, bottomColor)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.AutoButtonColor = false
    button.BackgroundColor3 = topColor or palette.surface
    button.Text = ""
    button.Parent = parent
    round(button, 14)
    outline(button, Color3.fromRGB(183, 216, 174), 1, 0.68)
    gradient(button, topColor or palette.surface, bottomColor or palette.deepSoft, 90)
    return button
end

local quest = Instance.new("Frame")
quest.Name = "QuestCard"
quest.Position = UDim2.fromOffset(20, 20)
quest.Size = UDim2.fromOffset(370, 104)
quest.BackgroundColor3 = palette.deep
quest.BackgroundTransparency = 0.04
quest.Parent = gui
round(quest, 18)
outline(quest, Color3.fromRGB(189, 218, 175), 1.2, 0.42)
gradient(quest, Color3.fromRGB(57, 91, 75), palette.deep, 90)

local questAccent = Instance.new("Frame")
questAccent.Name = "Accent"
questAccent.Position = UDim2.fromOffset(0, 16)
questAccent.Size = UDim2.fromOffset(4, 72)
questAccent.BackgroundColor3 = palette.gold
questAccent.BorderSizePixel = 0
questAccent.Parent = quest
round(questAccent, 4)

local questIcon = Instance.new("Frame")
questIcon.Name = "Icon"
questIcon.Position = UDim2.fromOffset(17, 27)
questIcon.Size = UDim2.fromOffset(48, 48)
questIcon.BackgroundColor3 = palette.surfaceLight
questIcon.Parent = quest
round(questIcon, 16)
outline(questIcon, palette.gold, 1.2, 0.38)
local iconText = label(questIcon, "Glyph", "✦", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Enum.Font.GothamBold, palette.gold)
iconText.TextSize = 25
iconText.TextXAlignment = Enum.TextXAlignment.Center

local eyebrow = label(quest, "Eyebrow", "ТВОЁ ПРИКЛЮЧЕНИЕ", UDim2.new(1, -88, 0, 19), UDim2.fromOffset(78, 13), Enum.Font.GothamBold, palette.mint)
eyebrow.TextSize = 10
eyebrow.TextTransparency = 0.06

local questText = label(quest, "Objective", "Открываем альбом…", UDim2.new(1, -90, 0, 55), UDim2.fromOffset(78, 34), Enum.Font.GothamMedium, palette.cream)
questText.TextSize = 13
questText.TextYAlignment = Enum.TextYAlignment.Top

local toggle = styledButton(gui, "CompanionToggle", UDim2.fromOffset(156, 54), UDim2.new(1, -20, 0, 20), palette.surfaceLight, palette.deepSoft)
toggle.AnchorPoint = Vector2.new(1, 0)
local toggleGlyph = label(toggle, "Glyph", "✿", UDim2.fromOffset(28, 36), UDim2.fromOffset(12, 9), Enum.Font.GothamBold, palette.gold)
toggleGlyph.TextSize = 22
toggleGlyph.TextXAlignment = Enum.TextXAlignment.Center
local toggleTitle = label(toggle, "Title", "КОЛЛЕКЦИЯ", UDim2.new(1, -52, 0, 20), UDim2.fromOffset(45, 8), Enum.Font.GothamBold, palette.cream)
toggleTitle.TextSize = 11
local toggleCount = label(toggle, "Count", "0 / 2", UDim2.new(1, -52, 0, 17), UDim2.fromOffset(45, 27), Enum.Font.GothamMedium, palette.mint)
toggleCount.TextSize = 10

local panel = Instance.new("Frame")
panel.Name = "CollectionPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 84)
panel.Size = UDim2.fromOffset(294, 440)
panel.BackgroundColor3 = palette.deep
panel.Visible = false
panel.Parent = gui
round(panel, 18)
outline(panel, Color3.fromRGB(189, 218, 175), 1.2, 0.45)
gradient(panel, Color3.fromRGB(56, 83, 72), palette.deep, 90)

local panelTitle = label(panel, "PanelTitle", "ТВОЯ КОЛЛЕКЦИЯ", UDim2.new(1, -28, 0, 23), UDim2.fromOffset(16, 12), Enum.Font.GothamBold, palette.cream)
panelTitle.TextSize = 12
local panelSubtitle = label(panel, "PanelSubtitle", "Спутники и материалы для твоего города", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(16, 34), Enum.Font.Gotham, palette.muted)
panelSubtitle.TextSize = 10

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(16, 59)
divider.Size = UDim2.new(1, -32, 0, 1)
divider.BackgroundColor3 = palette.mint
divider.BackgroundTransparency = 0.76
divider.BorderSizePixel = 0
divider.Parent = panel

local names = {
    Fox = "Лисёнок-корешок",
    Moth = "Лунная моль",
}
local descriptions = {
    Fox = "Нюх следопыта: находит спрятанные тайники и редкие находки.",
    Moth = "Лунное сияние: раскрывает скрытые цветы и тайники в Лунной роще.",
}
local companionButtons = {}

local function createCompanionCard(id, index)
    local card = styledButton(panel, id .. "Card", UDim2.new(1, -28, 0, 72), UDim2.fromOffset(14, 70 + (index - 1) * 80), palette.surface, palette.deepSoft)
    card.BackgroundTransparency = 0.02

    local icon = Instance.new("Frame")
    icon.Position = UDim2.fromOffset(10, 10)
    icon.Size = UDim2.fromOffset(50, 50)
    icon.BackgroundColor3 = id == "Fox" and Color3.fromRGB(147, 91, 65) or Color3.fromRGB(108, 89, 146)
    icon.Parent = card
    round(icon, 15)
    local glyph = label(icon, "Glyph", id == "Fox" and "❧" or "☾", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Enum.Font.GothamBold, id == "Fox" and palette.gold or palette.lilac)
    glyph.TextSize = 26
    glyph.TextXAlignment = Enum.TextXAlignment.Center

    local name = label(card, "Name", names[id], UDim2.new(1, -145, 0, 20), UDim2.fromOffset(70, 11), Enum.Font.GothamBold, palette.cream)
    name.TextSize = 12
    local description = label(card, "Description", descriptions[id], UDim2.new(1, -145, 0, 30), UDim2.fromOffset(70, 32), Enum.Font.Gotham, palette.muted)
    description.TextSize = 9
    description.TextYAlignment = Enum.TextYAlignment.Top

    local state = label(card, "State", "ЕЩЁ НЕ НАЙДЕН", UDim2.fromOffset(82, 18), UDim2.new(1, -92, 0, 12), Enum.Font.GothamBold, palette.gold)
    state.TextSize = 8
    state.TextXAlignment = Enum.TextXAlignment.Center
    local action = label(card, "Action", "НАЙТИ", UDim2.fromOffset(82, 19), UDim2.new(1, -92, 0, 34), Enum.Font.GothamBold, palette.mint)
    action.TextSize = 10
    action.TextXAlignment = Enum.TextXAlignment.Center

    card.Activated:Connect(function()
        if player:GetAttribute(id) then
            event:FireServer(id)
        end
    end)
    companionButtons[id] = {button = card, state = state, action = action, description = description}
end

createCompanionCard("Fox", 1)
createCompanionCard("Moth", 2)

local resourceHeader = label(
    panel,
    "ResourceHeader",
    "МАТЕРИАЛЫ И ФЕРМА",
    UDim2.new(1, -28, 0, 18),
    UDim2.fromOffset(16, 235),
    Enum.Font.GothamBold,
    palette.mint
)
resourceHeader.TextSize = 10

local function resourceChip(id, title, glyph, position, accent)
    local chip = Instance.new("Frame")
    chip.Name = id .. "Chip"
    chip.Position = position
    chip.Size = UDim2.new(0.5, -9, 0, 56)
    chip.BackgroundColor3 = palette.surface
    chip.Parent = panel
    round(chip, 12)
    outline(chip, accent, 1, 0.72)
    gradient(chip, palette.surface, palette.deepSoft, 90)

    local icon = label(chip, "Glyph", glyph, UDim2.fromOffset(28, 38), UDim2.fromOffset(7, 9), Enum.Font.GothamBold, accent)
    icon.TextSize = 21
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local name = label(chip, "Name", title, UDim2.new(1, -43, 0, 25), UDim2.fromOffset(39, 5), Enum.Font.GothamBold, palette.cream)
    name.TextSize = 9
    name.TextYAlignment = Enum.TextYAlignment.Center

    local count = label(chip, "Count", "0 шт.", UDim2.new(1, -43, 0, 18), UDim2.fromOffset(39, 31), Enum.Font.GothamMedium, accent)
    count.TextSize = 10
    return count
end

local sunResourceCount = resourceChip(
    "SunPetal",
    "Солнечный лепесток",
    "✿",
    UDim2.fromOffset(14, 258),
    palette.gold
)
local moonResourceCount = resourceChip(
    "MoonPetal",
    "Лунный лепесток",
    "✧",
    UDim2.new(0.5, 7, 0, 258),
    palette.lilac
)
local carrotSeedCount = resourceChip(
    "CarrotSeed",
    "Семена моркови",
    "❀",
    UDim2.fromOffset(14, 318),
    palette.mint
)
local carrotCount = resourceChip(
    "Carrot",
    "Морковь",
    "◆",
    UDim2.new(0.5, 7, 0, 318),
    palette.gold
)
local moonSeedCount = resourceChip(
    "MoonSeed",
    "Лунное семя",
    "✦",
    UDim2.fromOffset(14, 378),
    palette.lilac
)
local starShardCount = resourceChip(
    "StarShard",
    "Звёздный осколок",
    "✧",
    UDim2.new(0.5, 7, 0, 378),
    palette.gold
)

toggle.Activated:Connect(function()
    panel.Visible = not panel.Visible
    local target = panel.Visible and 1 or 0
    panel.BackgroundTransparency = 0.18
    TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = panel.Visible and 0 or 0.18,
    }):Play()
end)

local marker = Instance.new("BillboardGui")
marker.Name = "NextGoalMarker"
marker.Size = UDim2.fromOffset(174, 38)
marker.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
marker.AlwaysOnTop = true
marker.LightInfluence = 0
marker.MaxDistance = 150
marker.Enabled = false
marker.Parent = gui

local markerFrame = Instance.new("Frame")
markerFrame.Size = UDim2.fromScale(1, 1)
markerFrame.BackgroundColor3 = palette.deep
markerFrame.Parent = marker
round(markerFrame, 12)
outline(markerFrame, palette.gold, 1.2, 0.2)
gradient(markerFrame, palette.surfaceLight, palette.deep, 90)
local markerText = label(markerFrame, "MarkerText", "СЛЕДУЮЩАЯ ЦЕЛЬ", UDim2.new(1, -14, 1, 0), UDim2.fromOffset(7, 0), Enum.Font.GothamBold, palette.cream)
markerText.TextSize = 10
markerText.TextXAlignment = Enum.TextXAlignment.Center

local function getHomeIsland()
    local folder = workspace:FindFirstChild("PlayerIslands")
    return folder and folder:FindFirstChild("HomeIsland_" .. tostring(player.UserId))
end

local foxCacheIds = {"FoxCache01", "FoxCache02", "FoxCache03"}
local foxCachePrompts = {}
local foxCacheHighlights = {}
local foxSniffUntil = 0
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

local function updateMoonGateBarrier(runeAnchor, gateOpen)
    if gateOpen or not runeAnchor or not runeAnchor:IsA("BasePart") then
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

local function setLocalModelVisibility(model, visible)
    if not model then return end
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = visible and 0 or 1
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

    updateMoonGateBarrier(runeAnchor, gateOpen)
    setLocalModelVisibility(tracksVisual, (foxEquipped and player:GetAttribute("MoonBloom") == true) or traceFound)
    setLocalModelVisibility(runesVisual, gateOpen or (traceFound and mothEquipped))
    setLocalModelVisibility(sealVisual, not gateOpen)
    setLocalModelVisibility(clearingVisual, gateOpen)

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

local route = {
    {flag = "Fox", area = "Grove", part = "Nest", label = "Лисёнок", hint = "Подружись с лисёнком у гнезда в Солнечной роще."},
    {flag = "Seed", area = "Grove", part = "Trail", label = "Следы на тропе", hint = "Позови лисёнка и попроси его обыскать тропу."},
    {flag = "Moth", area = "Dusk", part = "Nest", label = "Лунная моль", hint = "Подружись с молью у гнезда в Лунной роще."},
    {flag = "MoonBloom", area = "Dusk", part = "MoonBloom", label = "Тайный лунный цветок", hint = "Позови лунную моль — её сияние раскроет скрытый цветок."},
    {flag = "MoonGateTrace", area = "Dusk", part = "MoonGateTracks", label = "Следы у корней", hint = "Позови лисёнка и попроси его найти древние следы под корнями."},
    {flag = "MoonGateOpen", area = "Dusk", part = "MoonGateRune", label = "Лунные руны", hint = "Позови лунную моль и освети древние руны у каменной арки."},
    {flag = "MoonRelic", area = "Dusk", part = "MoonRelic", label = "Звёздный осколок", hint = "Пройди через открывшийся проход и забери редкий звёздный осколок."},
    {flag = "Flower", area = "HomeIsland", part = "Planter", label = "Лунный цветок", hint = "Позови моль к клумбе возле дома."},
    {flag = "Timber", area = "Grove", part = "Driftwood", label = "Сухие ветви", hint = "Возьми лисёнка к коряге за ветвями для фонаря."},
    {flag = "Lantern", area = "HomeIsland", part = "LanternBase", label = "Садовый фонарь", hint = "Собери фонарь из ветвей на площадке рядом с домом."},
    {flag = "Lit", area = "HomeIsland", part = "LanternBase", label = "Зажечь фонарь", hint = "Позови моль и зажги садовый фонарь."},
}

local lastTip = 0

local function goal()
    local homeIsland = getHomeIsland()
    if not homeIsland or not player:GetAttribute("Ready") then
        return "Загружаем твой остров…"
    end

    local activeCacheId = player:GetAttribute("FoxCacheSpot")
    if type(activeCacheId) == "string" and activeCacheId ~= "" then
        local grove = workspace:FindFirstChild("Grove")
        local target = grove and grove:FindFirstChild(activeCacheId)
        if player:GetAttribute("Companion") ~= "Fox" then
            return "Позови лисёнка — он уже нашёл тайник. Затем следуй по золотым следам лап.", target, "Тайник лисёнка"
        end
        return "Лисёнок учуял тайник! Следуй по золотым следам лап и забери находку.", target, "Тайник лисёнка"
    end

    for _, step in route do
        if player:GetAttribute(step.flag) then
            continue
        end

        local area = step.area == "HomeIsland" and homeIsland or workspace:FindFirstChild(step.area)
        local target = area and area:FindFirstChild(step.part)
        if step.area == "Grove" and not player:GetAttribute("Fox") then
            return "Пройди по деревянному мосту в Солнечную рощу и найди лисёнка.", target, step.label
        elseif step.area == "Dusk" and not player:GetAttribute("Moth") then
            return "Перейди через рощу по мосту и познакомься с лунной молью.", target, step.label
        end
        return step.hint, target, step.label
    end

    return "Отлично! Теперь развивай свой остров и ферму."
end

local function refresh()
    local found = 0
    for id, entry in companionButtons do
        local owned = player:GetAttribute(id) == true
        local equipped = player:GetAttribute("Companion") == id
        if owned then found += 1 end

        entry.state.Text = not owned and "ЕЩЁ НЕ НАЙДЕН" or equipped and "С ТОБОЙ" or "В КОЛЛЕКЦИИ"
        entry.action.Text = not owned and "НАЙТИ" or equipped and "РЯДОМ" or "ПОЗВАТЬ"
        if id == "Fox" and owned then
            local activeCacheId = player:GetAttribute("FoxCacheSpot")
            local readyAt = tonumber(player:GetAttribute("FoxSearchReadyAt")) or 0
            if type(activeCacheId) == "string" and activeCacheId ~= "" then
                entry.description.Text = "Тайник найден! " .. (equipped and "Следуй по золотым следам лап." or "Позови лисёнка и забери находку.")
            elseif readyAt > os.time() then
                entry.description.Text = "Нюх отдыхает. Скоро снова будет готов."
            else
                entry.description.Text = "Нюх следопыта готов. Ищи следы в Солнечной роще."
            end
        else
            entry.description.Text = descriptions[id]
        end
        if id == "Moth" and owned then
            entry.description.Text = player:GetAttribute("MoonBloom") and "Лунное сияние уже пробудило тайный цветок." or equipped and "Сияние готово. Ищи скрытый цветок в Лунной роще." or "Позови моль, чтобы увидеть скрытый цветок."
        end
        entry.button.BackgroundColor3 = equipped and palette.surfaceLight or palette.surface
        entry.state.TextColor3 = equipped and palette.gold or owned and palette.mint or palette.muted
        entry.action.TextColor3 = owned and palette.mint or palette.gold
    end
    toggleCount.Text = tostring(found) .. " / 2"
    panelTitle.Text = "ТВОЯ КОЛЛЕКЦИЯ  •  " .. tostring(found) .. "/2"
    sunResourceCount.Text = tostring(player:GetAttribute("Resource_SunPetal") or 0) .. " шт."
    moonResourceCount.Text = tostring(player:GetAttribute("Resource_MoonPetal") or 0) .. " шт."
    carrotSeedCount.Text = tostring(player:GetAttribute("Resource_CarrotSeed") or 0) .. " шт."
    carrotCount.Text = tostring(player:GetAttribute("Resource_Carrot") or 0) .. " шт."
    moonSeedCount.Text = tostring(player:GetAttribute("Resource_MoonSeed") or 0) .. " шт."
    starShardCount.Text = tostring(player:GetAttribute("Resource_StarShard") or 0) .. " шт."
    resourceHeader.Text = "МАТЕРИАЛЫ И ФЕРМА • УР. " .. tostring(player:GetAttribute("Farm_Level") or 1)
    updateFoxCacheMarkers()
    updateMothBloomReveal()
    updateMoonGatePuzzle()
end

local function updateRoute()
    local hint, target, markerLabel = goal()
    marker.Adornee = target
    marker.Enabled = target ~= nil
    markerText.Text = string.upper(markerLabel or "СЛЕДУЮЩАЯ ЦЕЛЬ")

    if os.clock() >= lastTip then
        questText.Text = (player:GetAttribute("OfflineAlbum") and "Без сохранения • " or "") .. hint
    end
end

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
    if message == "ResourceState" and type(payload) == "table" then
        for nodeId in payload.collected or {} do
            applyResourceNodeState(nodeId, nil, true)
        end
        for nodeId, readyAt in payload.cooldowns or {} do
            applyResourceNodeState(nodeId, readyAt, false)
        end
        return
    elseif message == "ResourcePicked" and type(payload) == "table" then
        applyResourceNodeState(payload.nodeId, payload.readyAt, payload.unique == true)
        return
    end

    lastTip = os.clock() + 3.5
    questText.Text = message
    TweenService:Create(questAccent, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = palette.coral,
    }):Play()
    task.delay(3.6, function()
        TweenService:Create(questAccent, TweenInfo.new(0.25), {BackgroundColor3 = palette.gold}):Play()
        updateRoute()
    end)
end)

task.spawn(function()
    if not player:GetAttribute("Ready") then
        player:GetAttributeChangedSignal("Ready"):Wait()
    end
    event:FireServer("RequestResourceState")
end)

player.AttributeChanged:Connect(refresh)
refresh()

local function updateLayout()
    local compact = gui.AbsoluteSize.X < 760
    if compact then
        quest.Position = UDim2.fromOffset(16, 16)
        quest.Size = UDim2.new(1, -32, 0, 92)
        toggle.AnchorPoint = Vector2.new(0, 0)
        toggle.Position = UDim2.fromOffset(16, 118)
        toggle.Size = UDim2.fromOffset(144, 48)
        panel.AnchorPoint = Vector2.new(0, 0)
        panel.Position = UDim2.fromOffset(16, 174)
        panel.Size = UDim2.fromOffset(math.min(gui.AbsoluteSize.X - 32, 294), 440)
    else
        quest.Position = UDim2.fromOffset(20, 20)
        quest.Size = UDim2.fromOffset(370, 104)
        toggle.AnchorPoint = Vector2.new(1, 0)
        toggle.Position = UDim2.new(1, -20, 0, 20)
        toggle.Size = UDim2.fromOffset(156, 54)
        panel.AnchorPoint = Vector2.new(1, 0)
        panel.Position = UDim2.new(1, -20, 0, 84)
        panel.Size = UDim2.fromOffset(294, 440)
    end
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
task.defer(updateLayout)

task.spawn(function()
    while gui.Parent do
        updateRoute()
        task.wait(0.3)
    end
end)

-- Companion followers are local visual models. The wild encounter remains available
-- to other players, but is hidden locally once this player has adopted that companion.
local models = {}
local animationStates = {}
local encounterLocations = {
    Fox = "Grove",
    Moth = "Dusk",
}

local function captureAnimation(model, id, isEncounter)
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
    }
    animationStates[model] = state
    return state
end

local function animateModelParts(model, state, time, moving)
    local pivot = model:GetPivot()
    local sniffing = state.id == "Fox" and not state.isEncounter and os.clock() < foxSniffUntil
    for part, offset in state.offsets do
        if part.Parent then
            local transform = CFrame.new()

            if state.id == "Fox" then
                if part.Name == "Muzzle" and sniffing then
                    transform = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.sin(time * 12) * 0.045, 0, 0)
                elseif part.Name == "Tail" then
                    local sway = math.sin(time * (sniffing and 9 or 4.2)) * (sniffing and 0.48 or 0.3)
                    transform = CFrame.Angles(sway * 0.45, sway, sway * 0.2)
                elseif part.Name == "Tail tip" then
                    local sway = math.sin(time * (sniffing and 9 or 4.2) - 0.25) * (sniffing and 0.52 or 0.36)
                    transform = CFrame.Angles(sway * 0.35, sway, 0)
                elseif part.Name == "Paw" then
                    local stride = moving and 0.32 or sniffing and 0.16 or 0.055
                    local phase = (math.abs(offset.Position.X) + math.abs(offset.Position.Z)) * 1.8
                    local step = math.sin(time * (moving and 10 or sniffing and 8 or 2.4) + phase) * stride
                    transform = CFrame.new(0, math.max(0, step) * 0.16, 0) * CFrame.Angles(step, 0, 0)
                elseif part.Name == "Ear" or part.Name == "Inner ear" then
                    local side = offset.Position.X >= 0 and 1 or -1
                    local twitch = math.sin(time * (sniffing and 5 or 2.2) + side) * (sniffing and 0.09 or 0.055)
                    transform = CFrame.Angles(0, 0, twitch * side)
                end
            elseif state.id == "Moth" then
                if part.Name == "Wing" or part.Name == "Wing tip" or part.Name == "Wing jewel" then
                    local side = offset.Position.X >= 0 and 1 or -1
                    local flap = math.sin(time * 11.5) * 0.42
                    transform = CFrame.Angles(0, 0, flap * side)
                elseif part.Name == "Antenna" then
                    local side = offset.Position.X >= 0 and 1 or -1
                    transform = CFrame.Angles(0, 0, math.sin(time * 2.8 + side) * 0.07)
                end
            end

            part.CFrame = pivot * offset * transform
        end
    end
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

    local nest = island:FindFirstChild("Nest")
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
    if instance.Name == "FoxEncounter" or instance.Name == "MothEncounter" or instance:IsA("ProximityPrompt") then
        task.defer(function()
            updateEncounterVisibility("Fox")
            updateEncounterVisibility("Moth")
        end)
    end
end)

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
            model:Destroy()
            models[owner] = nil
            model = nil
        end

        if root and names[id] then
            local phase = now + (owner.UserId % 19) * 0.17
            local bob = math.sin(phase * 2.8) * 0.14
            local target = root.CFrame
                * CFrame.new(2.8, (id == "Fox" and -1.35 or 1.05) + bob, 2.1)
                * CFrame.Angles(0, math.sin(phase * 1.6) * 0.06, 0)

            if not model then
                model = storage[id]:Clone()
                model.Name = id
                model.Parent = workspace
                model:PivotTo(target)
                models[owner] = model
                captureAnimation(model, id, false)
            else
                model:PivotTo(model:GetPivot():Lerp(target, 1 - math.exp(-9 * dt)))
            end

            local state = animationStates[model]
            if state then
                animateModelParts(model, state, phase, humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.08)
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
            animateModelParts(encounter, state, phase, false)
        end
    end
end

Players.PlayerRemoving:Connect(function(owner)
    if models[owner] then
        animationStates[models[owner]] = nil
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
