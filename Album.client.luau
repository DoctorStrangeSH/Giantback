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
local toggleTitle = label(toggle, "Title", "СПУТНИКИ", UDim2.new(1, -52, 0, 20), UDim2.fromOffset(45, 8), Enum.Font.GothamBold, palette.cream)
toggleTitle.TextSize = 11
local toggleCount = label(toggle, "Count", "0 / 2", UDim2.new(1, -52, 0, 17), UDim2.fromOffset(45, 27), Enum.Font.GothamMedium, palette.mint)
toggleCount.TextSize = 10

local panel = Instance.new("Frame")
panel.Name = "CompanionPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 84)
panel.Size = UDim2.fromOffset(294, 246)
panel.BackgroundColor3 = palette.deep
panel.Visible = false
panel.Parent = gui
round(panel, 18)
outline(panel, Color3.fromRGB(189, 218, 175), 1.2, 0.45)
gradient(panel, Color3.fromRGB(56, 83, 72), palette.deep, 90)

local panelTitle = label(panel, "PanelTitle", "ТВОЯ КОМАНДА", UDim2.new(1, -28, 0, 23), UDim2.fromOffset(16, 12), Enum.Font.GothamBold, palette.cream)
panelTitle.TextSize = 12
local panelSubtitle = label(panel, "PanelSubtitle", "Спутники помогают находить секреты", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(16, 34), Enum.Font.Gotham, palette.muted)
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
    Fox = "Чует спрятанные семена и ветви",
    Moth = "Пробуждает цветы и свет",
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
    companionButtons[id] = {button = card, state = state, action = action}
end

createCompanionCard("Fox", 1)
createCompanionCard("Moth", 2)

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

local route = {
    {flag = "Fox", area = "Grove", part = "Nest", label = "Лисёнок", hint = "Подружись с лисёнком у гнезда в Солнечной роще."},
    {flag = "Seed", area = "Grove", part = "Trail", label = "Следы на тропе", hint = "Позови лисёнка и попроси его обыскать тропу."},
    {flag = "Moth", area = "Dusk", part = "Nest", label = "Лунная моль", hint = "Подружись с молью у гнезда в Лунной роще."},
    {flag = "Flower", area = "Mossback", part = "Planter", label = "Лунный цветок", hint = "Позови моль к клумбе возле дома."},
    {flag = "Timber", area = "Grove", part = "Driftwood", label = "Сухие ветви", hint = "Возьми лисёнка к коряге за ветвями для фонаря."},
    {flag = "Lantern", area = "Mossback", part = "LanternBase", label = "Садовый фонарь", hint = "Собери фонарь из ветвей рядом со штурвалом."},
    {flag = "Lit", area = "Mossback", part = "LanternBase", label = "Зажечь фонарь", hint = "Позови моль и зажги садовый фонарь."},
}

local lastTip = 0

local function goal()
    local giant = workspace:FindFirstChild("Mossback")
    if not giant or not player:GetAttribute("Ready") then
        return "Открываем альбом…"
    end

    local dock = giant:GetAttribute("Dock")
    if dock == "Sailing" then
        return "Мохоспин в пути. Скоро причалим!"
    end

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for _, step in route do
        if player:GetAttribute(step.flag) then
            continue
        end

        for _, shore in {"Grove", "Dusk"} do
            local island = workspace:FindFirstChild(shore)
            local bank = island and island:FindFirstChild("Bank")
            if root and bank and shore ~= dock and step.area ~= shore then
                local localPosition = bank.CFrame:PointToObjectSpace(root.Position)
                if math.abs(localPosition.X) <= bank.Size.X / 2 and math.abs(localPosition.Z) <= bank.Size.Z / 2 then
                    return "Позвони в береговой колокольчик, чтобы вернуться домой.", island:FindFirstChild("CallBell"), "Колокольчик"
                end
            end
        end

        local area = workspace:FindFirstChild(step.area)
        local bank = area and area:FindFirstChild("Bank")
        local onTargetShore = false
        if root and bank then
            local localPosition = bank.CFrame:PointToObjectSpace(root.Position)
            onTargetShore = math.abs(localPosition.X) <= bank.Size.X / 2 and math.abs(localPosition.Z) <= bank.Size.Z / 2
        end

        if step.area ~= "Mossback" and step.area ~= dock and not onTargetShore then
            local destination = step.area == "Grove" and "Солнечной роще" or "Лунной роще"
            return "У штурвала задай курс к " .. destination .. ".", giant:FindFirstChild("Helm"), "Штурвал"
        end
        return step.hint, area and area:FindFirstChild(step.part), step.label
    end

    return "Садовый фонарь горит • Коллекция 2/2"
end

local function refresh()
    local found = 0
    for id, entry in companionButtons do
        local owned = player:GetAttribute(id) == true
        local equipped = player:GetAttribute("Companion") == id
        if owned then found += 1 end

        entry.state.Text = not owned and "ЕЩЁ НЕ НАЙДЕН" or equipped and "С ТОБОЙ" or "В КОЛЛЕКЦИИ"
        entry.action.Text = not owned and "НАЙТИ" or equipped and "РЯДОМ" or "ПОЗВАТЬ"
        entry.button.BackgroundColor3 = equipped and palette.surfaceLight or palette.surface
        entry.state.TextColor3 = equipped and palette.gold or owned and palette.mint or palette.muted
        entry.action.TextColor3 = owned and palette.mint or palette.gold
    end
    toggleCount.Text = tostring(found) .. " / 2"
    panelTitle.Text = "ТВОЯ КОМАНДА  •  " .. tostring(found) .. "/2"
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

event.OnClientEvent:Connect(function(message)
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
        panel.Size = UDim2.fromOffset(math.min(gui.AbsoluteSize.X - 32, 294), 246)
    else
        quest.Position = UDim2.fromOffset(20, 20)
        quest.Size = UDim2.fromOffset(370, 104)
        toggle.AnchorPoint = Vector2.new(1, 0)
        toggle.Position = UDim2.new(1, -20, 0, 20)
        toggle.Size = UDim2.fromOffset(156, 54)
        panel.AnchorPoint = Vector2.new(1, 0)
        panel.Position = UDim2.new(1, -20, 0, 84)
        panel.Size = UDim2.fromOffset(294, 246)
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
    for part, offset in state.offsets do
        if part.Parent then
            local transform = CFrame.new()

            if state.id == "Fox" then
                if part.Name == "Tail" then
                    local sway = math.sin(time * 4.2) * 0.3
                    transform = CFrame.Angles(sway * 0.45, sway, sway * 0.2)
                elseif part.Name == "Tail tip" then
                    local sway = math.sin(time * 4.2 - 0.25) * 0.36
                    transform = CFrame.Angles(sway * 0.35, sway, 0)
                elseif part.Name == "Paw" then
                    local stride = moving and 0.32 or 0.055
                    local phase = (math.abs(offset.Position.X) + math.abs(offset.Position.Z)) * 1.8
                    local step = math.sin(time * (moving and 10 or 2.4) + phase) * stride
                    transform = CFrame.new(0, math.max(0, step) * 0.16, 0) * CFrame.Angles(step, 0, 0)
                elseif part.Name == "Ear" or part.Name == "Inner ear" then
                    local side = offset.Position.X >= 0 and 1 or -1
                    local twitch = math.sin(time * 2.2 + side) * 0.055
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

-- The flower is assembled locally for its owner and travels with the moving home.
local planter = workspace:WaitForChild("Mossback"):WaitForChild("Planter")
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
    planter:GetPropertyChangedSignal("CFrame"):Connect(placeFlower)
end

player:GetAttributeChangedSignal("Flower"):Connect(bloom)
bloom()

-- The garden lantern follows the deck and becomes luminous when the moth helps.
local base = workspace.Mossback:WaitForChild("LanternBase")
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
