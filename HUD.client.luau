local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("AlbumAction")

local palette = {
    ink = Color3.fromRGB(38, 58, 51),
    forest = Color3.fromRGB(54, 83, 68),
    forestLight = Color3.fromRGB(79, 112, 84),
    paper = Color3.fromRGB(250, 241, 218),
    paperDark = Color3.fromRGB(230, 218, 188),
    muted = Color3.fromRGB(116, 132, 111),
    mint = Color3.fromRGB(168, 205, 150),
    gold = Color3.fromRGB(239, 184, 91),
    coral = Color3.fromRGB(216, 121, 94),
    lilac = Color3.fromRGB(174, 151, 207),
    white = Color3.fromRGB(255, 253, 244),
}

local gui = Instance.new("ScreenGui")
gui.Name = "GiantbackHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(target, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius or 16)
    item.Parent = target
    return item
end

local function stroke(target, color, transparency, thickness)
    local item = Instance.new("UIStroke")
    item.Color = color or palette.gold
    item.Transparency = transparency or 0.5
    item.Thickness = thickness or 1
    item.Parent = target
    return item
end

local function gradient(target, top, bottom)
    local item = Instance.new("UIGradient")
    item.Color = ColorSequence.new(top, bottom)
    item.Rotation = 90
    item.Parent = target
    return item
end

local function label(parent, name, text, size, position, textSize, color, font)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.BackgroundTransparency = 1
    item.Size = size
    item.Position = position
    item.Font = font or Enum.Font.GothamMedium
    item.Text = text
    item.TextColor3 = color or palette.ink
    item.TextSize = textSize or 16
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Parent = parent
    return item
end

local function button(parent, name, text, size, position, color)
    local item = Instance.new("TextButton")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundColor3 = color or palette.forest
    item.Text = text
    item.TextColor3 = palette.white
    item.TextSize = 16
    item.Font = Enum.Font.GothamBold
    item.AutoButtonColor = true
    item.TextWrapped = true
    item.Parent = parent
    corner(item, 14)
    stroke(item, palette.gold, 0.65, 1)
    return item
end

local function card(parent, name, height)
    local item = Instance.new("Frame")
    item.Name = name
    item.Size = UDim2.new(1, 0, 0, height or 76)
    item.BackgroundColor3 = palette.paper
    item.BorderSizePixel = 0
    item.Parent = parent
    corner(item, 16)
    stroke(item, palette.paperDark, 0.15, 1)
    return item
end

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Position = UDim2.fromOffset(16, 16)
topBar.Size = UDim2.new(1, -32, 0, 58)
topBar.BackgroundTransparency = 1
topBar.Parent = gui

local brand = Instance.new("Frame")
brand.Name = "Brand"
brand.Size = UDim2.fromOffset(178, 58)
brand.BackgroundColor3 = palette.forest
brand.Parent = topBar
corner(brand, 18)
stroke(brand, palette.gold, 0.4, 1.2)
gradient(brand, palette.forestLight, palette.ink)
local brandTitle = label(brand, "Title", "GIANTBACK", UDim2.new(1, -20, 0, 25), UDim2.fromOffset(12, 5), 18, palette.white, Enum.Font.GothamBlack)
local brandSubtitle = label(brand, "Subtitle", "ТВОЙ МИР • ТВОИ ПРАВИЛА", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(12, 32), 9, palette.mint, Enum.Font.GothamBold)

local resources = Instance.new("Frame")
resources.Name = "QuickResources"
resources.AnchorPoint = Vector2.new(1, 0)
resources.Position = UDim2.new(1, 0, 0, 0)
resources.Size = UDim2.fromOffset(214, 58)
resources.BackgroundColor3 = palette.paper
resources.Parent = topBar
corner(resources, 18)
stroke(resources, palette.paperDark, 0.1, 1)
local woodLabel = label(resources, "Wood", "ДЕР.  0", UDim2.new(0.5, -8, 1, 0), UDim2.fromOffset(10, 0), 13, palette.ink, Enum.Font.GothamBold)
local stoneLabel = label(resources, "Stone", "КАМ.  0", UDim2.new(0.5, -8, 1, 0), UDim2.new(0.5, 2, 0, 0), 13, palette.ink, Enum.Font.GothamBold)

local objective = Instance.new("Frame")
objective.Name = "ObjectiveCard"
objective.Position = UDim2.fromOffset(16, 84)
objective.Size = UDim2.fromOffset(352, 138)
objective.BackgroundColor3 = palette.paper
objective.Parent = gui
corner(objective, 18)
stroke(objective, palette.gold, 0.22, 1.4)

local objectiveIcon = Instance.new("Frame")
objectiveIcon.Position = UDim2.fromOffset(12, 13)
objectiveIcon.Size = UDim2.fromOffset(54, 54)
objectiveIcon.BackgroundColor3 = palette.gold
objectiveIcon.Parent = objective
corner(objectiveIcon, 16)
local objectiveGlyph = label(objectiveIcon, "Glyph", "✦", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 28, palette.ink, Enum.Font.GothamBlack)
objectiveGlyph.TextXAlignment = Enum.TextXAlignment.Center

local objectiveEyebrow = label(objective, "Eyebrow", "ТВОЯ СЛЕДУЮЩАЯ ЦЕЛЬ", UDim2.new(1, -82, 0, 18), UDim2.fromOffset(76, 10), 10, palette.forestLight, Enum.Font.GothamBold)
local objectiveText = label(objective, "Objective", "Загружаем твой остров…", UDim2.new(1, -86, 0, 34), UDim2.fromOffset(76, 29), 14, palette.ink, Enum.Font.GothamBold)
objectiveText.TextYAlignment = Enum.TextYAlignment.Top
local objectiveHint = label(objective, "Hint", "", UDim2.new(1, -88, 0, 32), UDim2.fromOffset(76, 66), 11, palette.forestLight, Enum.Font.GothamBold)
objectiveHint.TextYAlignment = Enum.TextYAlignment.Top

local progressTrack = Instance.new("Frame")
progressTrack.Name = "AdventureProgressTrack"
progressTrack.Position = UDim2.new(0, 76, 1, -13)
progressTrack.Size = UDim2.new(1, -92, 0, 6)
progressTrack.BackgroundColor3 = palette.paperDark
progressTrack.Parent = objective
corner(progressTrack, 6)

local progressFill = Instance.new("Frame")
progressFill.Name = "AdventureProgressFill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = palette.gold
progressFill.Parent = progressTrack
corner(progressFill, 6)

local progressCount = label(objective, "ProgressCount", "0 / 11", UDim2.new(1, -92, 0, 12), UDim2.new(0, 76, 1, -29), 9, palette.forestLight, Enum.Font.GothamBold)
progressCount.TextXAlignment = Enum.TextXAlignment.Right
local progressTween = nil

local nav = Instance.new("Frame")
nav.Name = "MainNavigation"
nav.AnchorPoint = Vector2.new(0.5, 1)
nav.Position = UDim2.new(0.5, 0, 1, -14)
nav.Size = UDim2.new(1, -32, 0, 68)
nav.BackgroundColor3 = palette.ink
nav.Parent = gui
corner(nav, 20)
stroke(nav, palette.gold, 0.35, 1.2)
gradient(nav, palette.forest, palette.ink)

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.Padding = UDim.new(0, 7)
navLayout.Parent = nav

local modalBackdrop = Instance.new("TextButton")
modalBackdrop.Name = "ModalBackdrop"
modalBackdrop.Size = UDim2.fromScale(1, 1)
modalBackdrop.BackgroundColor3 = Color3.fromRGB(15, 25, 21)
modalBackdrop.BackgroundTransparency = 0.42
modalBackdrop.BorderSizePixel = 0
modalBackdrop.Text = ""
modalBackdrop.AutoButtonColor = false
modalBackdrop.Visible = false
modalBackdrop.ZIndex = 20
modalBackdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(470, 420)
panel.BackgroundColor3 = palette.forest
panel.ZIndex = 21
panel.Visible = false
panel.Parent = gui
corner(panel, 22)
stroke(panel, palette.gold, 0.22, 1.5)
gradient(panel, palette.forestLight, palette.ink)

local panelTitle = label(panel, "PanelTitle", "МОЙ ОСТРОВ", UDim2.new(1, -82, 0, 30), UDim2.fromOffset(20, 15), 20, palette.white, Enum.Font.GothamBlack)
local panelSubtitle = label(panel, "PanelSubtitle", "Развивай свой дом и открывай новые места", UDim2.new(1, -40, 0, 20), UDim2.fromOffset(20, 46), 12, palette.mint)
local closeButton = button(panel, "Close", "✕", UDim2.fromOffset(42, 42), UDim2.new(1, -58, 0, 12), palette.coral)
closeButton.TextSize = 20

local body = Instance.new("ScrollingFrame")
body.Name = "Content"
body.Position = UDim2.fromOffset(16, 78)
body.Size = UDim2.new(1, -32, 1, -94)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 5
body.ScrollBarImageColor3 = palette.gold
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.new()
body.Parent = panel

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 9)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = body

local bodyPadding = Instance.new("UIPadding")
bodyPadding.PaddingBottom = UDim.new(0, 8)
bodyPadding.Parent = body

local toast = Instance.new("Frame")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -96)
toast.Size = UDim2.fromOffset(380, 48)
toast.BackgroundColor3 = palette.ink
toast.ZIndex = 40
toast.Visible = false
toast.Parent = gui
corner(toast, 15)
stroke(toast, palette.gold, 0.3, 1)
local toastText = label(toast, "Text", "", UDim2.new(1, -24, 1, -8), UDim2.fromOffset(12, 4), 14, palette.white, Enum.Font.GothamBold)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toastText.ZIndex = 41
local toastGeneration = 0
local toastTween = nil
local navButtons = {}
local navDefinitions = {}
local closeActivePanel
local applyPanelLayer

local function updateResponsiveLayout()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local compact = viewport.X < 620
    local narrow = viewport.X < 420

    topBar.Position = UDim2.fromOffset(compact and 8 or 16, compact and 8 or 16)
    topBar.Size = UDim2.new(1, compact and -16 or -32, 0, compact and 48 or 58)
    brand.Size = UDim2.fromOffset(compact and (narrow and 112 or 132) or 178, compact and 48 or 58)
    brandTitle.TextSize = compact and 14 or 18
    brandSubtitle.Visible = not compact
    resources.Size = UDim2.fromOffset(compact and (narrow and 150 or 174) or 214, compact and 48 or 58)
    woodLabel.TextSize = compact and 10 or 13
    stoneLabel.TextSize = compact and 10 or 13
    objective.Position = UDim2.fromOffset(compact and 8 or 16, compact and 64 or 84)
    objective.Size = UDim2.fromOffset(compact and (narrow and 210 or 250) or 352, compact and 112 or 138)
    objectiveIcon.Size = UDim2.fromOffset(compact and 38 or 54, compact and 38 or 54)
    objectiveIcon.Position = UDim2.fromOffset(10, 10)
    objectiveEyebrow.Position = UDim2.fromOffset(compact and 56 or 76, 8)
    objectiveText.Position = UDim2.fromOffset(compact and 56 or 76, 27)
    objectiveHint.Visible = not compact
    objectiveText.Size = UDim2.new(1, compact and -64 or -86, 0, compact and 30 or 34)
    progressTrack.Position = UDim2.new(0, compact and 56 or 76, 1, -12)
    progressTrack.Size = UDim2.new(1, compact and -68 or -92, 0, 5)
    progressCount.Visible = not compact

    nav.Position = UDim2.new(0.5, 0, 1, compact and -6 or -14)
    nav.Size = UDim2.new(1, compact and -16 or -32, 0, compact and 54 or 68)
    navLayout.Padding = UDim.new(0, compact and 2 or 7)
    panelTitle.TextSize = compact and 16 or 20
    panelSubtitle.TextSize = compact and 10 or 12
    closeButton.Size = UDim2.fromOffset(compact and 36 or 42, compact and 36 or 42)
    closeButton.Position = UDim2.new(1, compact and -44 or -58, 0, compact and 8 or 12)
    for _, definition in navDefinitions do
        local navButton = navButtons[definition.id]
        if navButton then
            navButton.Size = UDim2.new(1 / #navDefinitions, compact and -2 or -6, 1, -8)
            navButton.Text = compact and definition.glyph or (definition.glyph .. "\\n" .. definition.title)
            navButton.TextSize = compact and 20 or 13
        end
    end

    local panelWidth = math.max(240, math.min(470, viewport.X - (compact and 16 or 48)))
    local panelHeight = math.max(160, math.min(420, viewport.Y - (compact and 140 or 220)))
    panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
    panelTitle.TextSize = compact and 16 or 20
    panelSubtitle.TextSize = compact and 10 or 12
    closeButton.Size = UDim2.fromOffset(compact and 36 or 42, compact and 36 or 42)
    closeButton.Position = UDim2.new(1, compact and -44 or -58, 0, compact and 8 or 12)
    panel.Position = UDim2.new(0.5, 0, 0.5, compact and -18 or 0)
    panelTitle.TextSize = compact and 16 or 20
    panelSubtitle.TextSize = compact and 10 or 12
    body.Position = UDim2.fromOffset(12, 72)
    body.Size = UDim2.new(1, -24, 1, -84)
    toast.Size = UDim2.fromOffset(math.min(380, math.max(190, viewport.X - 24)), 48)
    toast.Position = UDim2.new(0.5, 0, 1, compact and -68 or -96)
end


local function clearBody()
    for _, child in body:GetChildren() do
        if child ~= bodyLayout and child ~= bodyPadding then
            child:Destroy()
        end
    end
end

local function addInfo(titleText, description, height)
    local availableWidth = math.max(180, body.AbsoluteSize.X - 28)
    local compact = gui.AbsoluteSize.X < 620
    local titleSize = compact and 14 or 15
    local detailSize = compact and 12 or 13
    local titleBounds = TextService:GetTextSize(
        titleText, titleSize, Enum.Font.GothamBold, Vector2.new(availableWidth, 1000)
    )
    local detailBounds = TextService:GetTextSize(
        description, detailSize, Enum.Font.GothamMedium, Vector2.new(availableWidth, 1000)
    )
    local titleHeight = math.max(22, math.ceil(titleBounds.Y))
    local detailHeight = math.max(18, math.ceil(detailBounds.Y))
    local contentHeight = titleHeight + detailHeight + 34
    local finalHeight = math.max(height or 82, contentHeight)

    local item = card(body, "InfoCard", finalHeight)
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 4, 1, -20)
    accent.Position = UDim2.fromOffset(0, 10)
    accent.BackgroundColor3 = palette.gold
    accent.BorderSizePixel = 0
    accent.Parent = item
    corner(accent, 4)

    label(item, "Title", titleText, UDim2.new(1, -32, 0, titleHeight),
        UDim2.fromOffset(14, 10), titleSize, palette.ink, Enum.Font.GothamBold)
    local detail = label(item, "Description", description,
        UDim2.new(1, -32, 0, detailHeight),
        UDim2.fromOffset(14, 10 + titleHeight + 4), detailSize, palette.muted, Enum.Font.GothamMedium)
    detail.TextYAlignment = Enum.TextYAlignment.Top
    return item
end

local cropCatalog = {
    {id = "Carrot", name = "Морковь", seed = "CarrotSeed", glyph = "◆", grow = "5 мин", color = palette.gold},
    {id = "Strawberry", name = "Клубника", seed = "StrawberrySeed", glyph = "♥", grow = "12 мин · повторный сбор 8 мин", color = palette.coral},
    {id = "Pumpkin", name = "Тыква", seed = "PumpkinSeed", glyph = "●", grow = "30 мин", color = palette.gold},
    {id = "Cabbage", name = "Капуста", seed = "CabbageSeed", glyph = "✿", grow = "20 мин", color = palette.mint},
}
local cropById = {}
for _, crop in cropCatalog do cropById[crop.id] = crop end

local function addSeedChoice(crop, selectedCrop)
    local seeds = tonumber(player:GetAttribute("Resource_" .. crop.seed)) or 0
    local selected = selectedCrop == crop.id
    local item = card(body, "Seed_" .. crop.id, 66)
    item.BackgroundColor3 = selected and Color3.fromRGB(235, 241, 218) or palette.paper
    local icon = label(item, "Icon", crop.glyph, UDim2.fromOffset(42, 42), UDim2.fromOffset(10, 12), 25, crop.color, Enum.Font.GothamBold)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    label(item, "Name", crop.name, UDim2.new(1, -166, 0, 22), UDim2.fromOffset(60, 7), 15, palette.ink, Enum.Font.GothamBold)
    label(item, "Details", crop.grow .. "  •  семян: " .. tostring(seeds), UDim2.new(1, -166, 0, 27), UDim2.fromOffset(60, 31), 11, palette.muted)
    local choose = button(item, "Choose", selected and "ВЫБРАНО" or "ВЫБРАТЬ", UDim2.fromOffset(94, 34), UDim2.new(1, -106, 0.5, -17), selected and palette.gold or palette.forest)
    choose.TextSize = 10
    choose.Activated:Connect(function()
        if seeds < 1 then
            showToast("Семена закончились. Найди или получи новые семена.")
            return
        end
        event:FireServer("SelectCrop", crop.id)
    end)
end

local function addPlot(plotId, index)
    local unlocked = player:GetAttribute("Farm_" .. plotId .. "_Unlocked") == true
    local cropId = player:GetAttribute("Farm_" .. plotId .. "_CropId") or ""
    local readyAt = tonumber(player:GetAttribute("Farm_" .. plotId .. "_ReadyAt")) or 0
    local crop = cropById[cropId]
    local stateText
    if not unlocked then
        stateText = "Закрыта — откроется после улучшения фермы"
    elseif cropId == "" then
        local selected = cropById[player:GetAttribute("Farm_SelectedCrop") or "Carrot"]
        stateText = "Свободна — выбрано: " .. (selected and selected.name or "морковь")
    elseif readyAt <= os.time() then
        stateText = (crop and crop.name or "Растение") .. ": урожай готов! Подойди и собери"
    else
        local remaining = math.max(0, readyAt - os.time())
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        stateText = string.format("%s растёт — осталось %02d:%02d", crop and crop.name or "Растение", minutes, seconds)
    end
    local item = card(body, "Plot" .. tostring(index), 66)
    local icon = label(item, "Icon", not unlocked and "З" or (crop and crop.glyph or "＋"), UDim2.fromOffset(42, 42), UDim2.fromOffset(10, 12), 23, palette.forest, Enum.Font.GothamBlack)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    label(item, "Title", "Грядка " .. tostring(index), UDim2.new(1, -72, 0, 22), UDim2.fromOffset(60, 8), 15, palette.ink, Enum.Font.GothamBold)
    label(item, "State", stateText, UDim2.new(1, -72, 0, 30), UDim2.fromOffset(60, 31), 12, palette.muted)
end

local showToast
local getObjective

local function renderCity()
    local cityLevel = tonumber(player:GetAttribute("City_Level")) or 1
    local farmLevel = tonumber(player:GetAttribute("Farm_Level")) or 1
    local homeSlot = tonumber(player:GetAttribute("HomeIslandSlot")) or 0
    addInfo("Добро пожаловать домой!", "Это твой личный остров. Друзья могут приходить в гости, но строить и менять что-либо здесь можешь только ты.", 84)
    addInfo("Домашний остров №" .. tostring(homeSlot), "На сервере восемь личных островов. Дом и ферма на твоём участке принадлежат только тебе.", 76)
    addInfo("Уровень города: " .. tostring(cityLevel), "Строй и улучшай свой остров, собирай материалы и открывай новые места.", 76)
    local wood = tonumber(player:GetAttribute("Resource_Wood")) or 0
    local stone = tonumber(player:GetAttribute("Resource_Stone")) or 0
    local ore = tonumber(player:GetAttribute("Resource_IronOre")) or 0
    local ingots = tonumber(player:GetAttribute("Resource_IronIngot")) or 0
    local smeltReadyAt = tonumber(player:GetAttribute("Smelter_ReadyAt")) or 0
    local smeltPending = tonumber(player:GetAttribute("Smelter_Pending")) or 0
    addInfo("Материалы для моста", "Дерево: " .. tostring(wood) .. " / 5    •    Камень: " .. tostring(stone) .. " / 3", 66)
    local sunPetals = tonumber(player:GetAttribute("Resource_SunPetal")) or 0
    local moonPetals = tonumber(player:GetAttribute("Resource_MoonPetal")) or 0
    local moonSeeds = tonumber(player:GetAttribute("Resource_MoonSeed")) or 0
    local starShards = tonumber(player:GetAttribute("Resource_StarShard")) or 0
    local carrotSeeds = tonumber(player:GetAttribute("Resource_CarrotSeed")) or 0
    local carrots = tonumber(player:GetAttribute("Resource_Carrot")) or 0
    addInfo("Находки и ферма", "Лунные семена: " .. tostring(moonSeeds) .. "   •   Звёздный осколок: " .. tostring(starShards)
        .. "   •   Семена моркови: " .. tostring(carrotSeeds) .. "   •   Урожай: " .. tostring(carrots)
        .. "   •   ☀ Солнечные лепестки: " .. tostring(sunPetals) .. "   •   ☾ Лунные лепестки: " .. tostring(moonPetals), 98)
    addInfo("Ферма: уровень " .. tostring(farmLevel), "На острове четыре грядки. Открой раздел «Ферма», чтобы выбрать семена, посадить растения и собрать урожай.", 76)
    addInfo("Твой следующий шаг", getObjective(), 76)
end

local function renderFarm()
    local farmLevel = tonumber(player:GetAttribute("Farm_Level")) or 1
    local selectedCrop = player:GetAttribute("Farm_SelectedCrop") or "Carrot"
    local totalSeeds = 0
    local harvestSummary = {}
    for _, crop in cropCatalog do
        totalSeeds += tonumber(player:GetAttribute("Resource_" .. crop.seed)) or 0
        local amount = tonumber(player:GetAttribute("Resource_" .. crop.id)) or 0
        if amount > 0 then table.insert(harvestSummary, crop.name .. " ×" .. tostring(amount)) end
    end
    addInfo("Ферма • уровень " .. tostring(farmLevel), "Семян всего: " .. tostring(totalSeeds) .. ( #harvestSummary > 0 and "   •   Урожай: " .. table.concat(harvestSummary, ", ") or "   •   Урожай пока не собран"), 78)
    addInfo("1. Выбери семена", "Выбери культуру — её можно будет посадить на любой свободной грядке.", 64)
    for _, crop in cropCatalog do addSeedChoice(crop, selectedCrop) end
    addInfo("2. Посади и собери", "Подойди к свободной грядке и выбери «Посадить». Когда урожай созреет, возвращайся за ним. Растения растут, даже если ты вышел из игры.", 86)
    for index = 1, 4 do
        addPlot(string.format("Plot%02d", index), index)
    end
end

local function renderPets()
    local pets = {
        {id = "Fox", name = "Лисёнок", role = "Разведчик", description = "Находит тайники и древние следы скрытых проходов.", location = "Ищи его в Солнечной роще.", icon = "Л"},
        {id = "Moth", name = "Лунная моль", role = "Хранитель света", description = "Пробуждает цветы и открывает древние лунные руны.", location = "Ищи её в Лунной роще.", icon = "М"},
        {id = "CrystalWisp", name = "Кристальный светляк", role = "Проводник пещеры", description = "Призменное чутьё помогает находить скрытые кристальные жилы.", location = "Ищи его в кристальной пещере у тренировочной поляны.", icon = "С"},
    }
    for _, pet in pets do
        local owned = player:GetAttribute(pet.id) == true
        local equipped = player:GetAttribute("Companion") == pet.id
        local item = card(body, pet.id .. "Card", 214)
        local icon = label(item, "Icon", pet.icon, UDim2.fromOffset(58, 58), UDim2.fromOffset(10, 24), 34, palette.ink)
        icon.TextXAlignment = Enum.TextXAlignment.Center
        label(item, "Name", pet.name .. " • " .. pet.role, UDim2.new(1, -210, 0, 24), UDim2.fromOffset(76, 8), 14, palette.ink, Enum.Font.GothamBold)
        local desc = owned and pet.description or pet.location
        label(item, "Description", desc, UDim2.new(1, -210, 0, 25), UDim2.fromOffset(76, 33), 11, palette.muted)
        local mood = player:GetAttribute("Companion_" .. pet.id .. "_Mood") or (pet.id == "Fox" and "Любопытство" or pet.id == "Moth" and "Спокойствие" or "Сияние")
        local moodLine = pet.id == "Fox" and "Любопытный исследователь" or pet.id == "Moth" and "Нежная хранительница света" or "Кристальный проводник"
        local moodGlyph = mood == "Радость" and "✦" or mood == "Довольство" and "♡" or pet.id == "Fox" and "⌕" or "☾"
        label(item, "Mood", owned and (moodGlyph .. " " .. moodLine .. " · " .. mood) or "Характер откроется при знакомстве",
            UDim2.new(1, -220, 0, 18), UDim2.fromOffset(76, 60), 10, palette.forest, Enum.Font.GothamBold)
        local bond = math.clamp(math.floor(tonumber(player:GetAttribute("Companion_" .. pet.id .. "_Bond")) or 0), 0, 1000)
        local bondRank = player:GetAttribute("Companion_" .. pet.id .. "_BondRank") or "Знакомство"
        label(item, "Friendship", owned and ("Дружба " .. tostring(bond) .. "/1000 · " .. bondRank) or "Сначала найди питомца", UDim2.new(1, -220, 0, 18), UDim2.fromOffset(76, 84), 10, palette.forest, Enum.Font.GothamBold)

        local companionLevel = math.clamp(math.floor(tonumber(player:GetAttribute("Companion_" .. pet.id .. "_Level")) or 1), 1, 5)
        local companionXP = math.max(0, math.floor(tonumber(player:GetAttribute("Companion_" .. pet.id .. "_XP")) or 0))
        local companionXPToNext = math.max(0, math.floor(tonumber(player:GetAttribute("Companion_" .. pet.id .. "_XPToNext")) or 0))
        local mutationName = player:GetAttribute("Companion_" .. pet.id .. "_MutationName")
        local mutationRarity = player:GetAttribute("Companion_" .. pet.id .. "_MutationRarity")
        local growthStage = companionLevel >= 5 and "ВЗРОСЛЫЙ"
            or companionLevel >= 3 and "ПОДРОСТОК" or "МАЛЫШ"
        local levelText = companionLevel >= 5 and "УР. 5 · МАКСИМУМ"
            or ("УР. " .. tostring(companionLevel) .. " · " .. tostring(companionXP) .. "/" .. tostring(companionXPToNext) .. " XP")
        local mutationText = owned and type(mutationName) == "string" and mutationName ~= ""
            and (" · ✦ " .. mutationName .. " (" .. tostring(mutationRarity or "Необычный") .. ")") or ""
        label(item, "Progression", owned and (growthStage .. " · " .. levelText .. mutationText) or "Уровень и мутация откроются при знакомстве",
            UDim2.new(1, -28, 0, 20), UDim2.fromOffset(16, 151), 11, palette.ink, Enum.Font.GothamBold)
        local foxTalent = companionLevel >= 5 and "Острый нюх: поиск каждые 60 сек."
            or companionLevel >= 3 and "Чуткий нюх: поиск каждые 90 сек."
            or "Следопыт: найди тайники в роще."
        local mothTalent = companionLevel >= 5 and "Лунная аура: радиус лечения +4."
            or companionLevel >= 3 and "Лунная аура: радиус лечения +2."
            or "Лунная аура развивается вместе с дружбой."
        if owned and pet.id == "Fox" then
            local foxReadyAt = tonumber(player:GetAttribute("FoxSearchReadyAt")) or 0
            if foxReadyAt <= os.time() then
                foxTalent = foxTalent .. " · Нюх следопыта готов"
            else
                foxTalent = foxTalent .. " · Нюх отдыхает"
            end
        end
        local wispTalent = "Призменное чутьё: скрытые жилы на " .. tostring(16 + (companionLevel - 1) * 3) .. " сек."
        label(item, "Talent", owned and (pet.id == "Fox" and foxTalent or pet.id == "Moth" and mothTalent or wispTalent) or "Найди питомца, чтобы открыть талант",
            UDim2.new(1, -28, 0, 20), UDim2.fromOffset(16, 179), 10, palette.forest)

        local action = button(item, "Action", owned and (equipped and "РЯДОМ" or "ПОЗВАТЬ") or "НЕ НАЙДЕН", UDim2.fromOffset(108, 28), UDim2.new(1, -120, 0, 8), equipped and palette.gold or palette.forest)
        action.TextSize = 10
        action.Activated:Connect(function()
            if owned then
                event:FireServer(pet.id)
            else
                showToast(pet.location)
            end
        end)

        local foodCount = (tonumber(player:GetAttribute("Resource_Pumpkin")) or 0)
            + (tonumber(player:GetAttribute("Resource_Strawberry")) or 0)
            + (tonumber(player:GetAttribute("Resource_Cabbage")) or 0)
            + (tonumber(player:GetAttribute("Resource_Carrot")) or 0)
        local feedText = not owned and "НЕТ ПИТОМЦА" or not equipped and "СНАЧАЛА ПОЗОВИ" or foodCount <= 0 and "НЕТ УРОЖАЯ" or "УГОСТИТЬ"
        local feed = button(item, "Feed", feedText, UDim2.fromOffset(108, 28), UDim2.new(1, -120, 0, 44), palette.forestLight)
        feed.TextSize = 9
        feed.Active = owned and equipped and foodCount > 0
        feed.AutoButtonColor = feed.Active
        feed.BackgroundTransparency = feed.Active and 0 or 0.35
        feed.Activated:Connect(function()
            if owned and equipped and foodCount > 0 then
                event:FireServer("FeedCompanion", pet.id)
            end
        end)

        local play = button(item, "Play", owned and (equipped and "ИГРАТЬ" or "ПОЗОВИ") or "НЕТ ПИТОМЦА",
            UDim2.fromOffset(108, 28), UDim2.new(1, -120, 0, 80), palette.gold)
        play.TextColor3 = palette.ink
        play.TextSize = 10
        play.Active = owned and equipped
        play.AutoButtonColor = play.Active
        play.BackgroundTransparency = play.Active and 0 or 0.35
        play.Activated:Connect(function()
            if owned and equipped then
                event:FireServer("StartCompanionPlay", pet.id)
            end
        end)

        local petButton = button(item, "Pet", owned and (equipped and "ПОГЛАДИТЬ" or "ПОЗОВИ") or "НЕТ ПИТОМЦА",
            UDim2.fromOffset(108, 28), UDim2.new(1, -120, 0, 116), palette.lilac)
        petButton.TextColor3 = palette.ink
        petButton.TextSize = 9
        petButton.Active = owned and equipped
        petButton.AutoButtonColor = petButton.Active
        petButton.BackgroundTransparency = petButton.Active and 0 or 0.35
        petButton.Activated:Connect(function()
            if owned and equipped then
                event:FireServer("PetCompanion", pet.id)
            end
        end)
    end
end

local function renderTools()
    local wood = tonumber(player:GetAttribute("Resource_Wood")) or 0
    local stone = tonumber(player:GetAttribute("Resource_Stone")) or 0
    local ore = tonumber(player:GetAttribute("Resource_IronOre")) or 0
    local ingots = tonumber(player:GetAttribute("Resource_IronIngot")) or 0
    local smeltReadyAt = tonumber(player:GetAttribute("Smelter_ReadyAt")) or 0
    local smeltPending = tonumber(player:GetAttribute("Smelter_Pending")) or 0
    addInfo("Инструменты путешественника", "Выбери инструмент в этом меню или на панели быстрого доступа. Для каждого ресурса нужен подходящий инструмент.", 78)
    addInfo("Материалы", "Дерево: " .. tostring(wood) .. "   •   Камень: " .. tostring(stone) .. "   •   Железная руда: " .. tostring(ore) .. "   •   Слитки: " .. tostring(ingots), 72)
    local smeltStatus = smeltPending > 0 and (smeltReadyAt > os.time() and ("Плавится · " .. tostring(math.max(1, smeltReadyAt - os.time())) .. " сек.") or "Готово к сбору у плавильни") or "Рецепт: 3 железной руды + 2 дерева · 60 сек."
    addInfo("Плавильня на острове", smeltStatus, 58)
    local catalog = {
        {id = "Axe", name = "Топор путешественника", glyph = "Т", purpose = "Рубит деревья", cost = "8 дерева · 6 камня"},
        {id = "Pickaxe", name = "Кирка путешественника", glyph = "К", purpose = "Добывает камень", cost = "6 дерева · 8 камня"},
    }
    for _, definition in catalog do
        local level = tonumber(player:GetAttribute("Tool_" .. definition.id .. "Level")) or 1
        local owned = player:GetAttribute("Tool_" .. definition.id .. "Owned") == true
        local equipped = player:GetAttribute("Tool_Equipped") == definition.id
        local item = card(body, "Tool_" .. definition.id, 106)
        local icon = label(item, "Icon", definition.glyph, UDim2.fromOffset(44, 48), UDim2.fromOffset(10, 22), 28, palette.gold)
        icon.TextXAlignment = Enum.TextXAlignment.Center
        label(item, "Name", definition.name, UDim2.new(1, -156, 0, 22), UDim2.fromOffset(62, 8), 14, palette.ink, Enum.Font.GothamBold)
        label(item, "Details", definition.purpose .. " · уровень " .. tostring(level), UDim2.new(1, -156, 0, 25), UDim2.fromOffset(62, 33), 11, palette.muted)
        local equip = button(item, "Equip", equipped and "В РУКАХ" or "ВЗЯТЬ", UDim2.fromOffset(102, 30), UDim2.new(1, -114, 0, 8), equipped and palette.gold or palette.forest)
        equip.TextSize = 10
        equip.Activated:Connect(function()
            if owned then event:FireServer("EquipTool", definition.id) end
        end)
        local upgradeText = level >= 2 and "МАКС. УРОВЕНЬ" or "УЛУЧШИТЬ"
        local upgrade = button(item, "Upgrade", upgradeText, UDim2.fromOffset(102, 30), UDim2.new(1, -114, 0, 52), level >= 2 and palette.muted or palette.coral)
        upgrade.TextSize = 10
        upgrade.Activated:Connect(function()
            if level < 2 then
                event:FireServer("UpgradeTool", definition.id)
                showToast("Улучшение доступно у верстака на твоём острове: " .. definition.cost .. ".")
            end
        end)
    end
    local swordOwned = player:GetAttribute("Tool_SwordOwned") == true
    local swordEquipped = player:GetAttribute("Tool_Equipped") == "Sword"
    local swordCard = card(body, "Tool_Sword", 124)
    label(swordCard, "SwordIcon", "М", UDim2.fromOffset(44, 48), UDim2.fromOffset(10, 22), 28, palette.gold)
    label(swordCard, "SwordName", "Меч странника", UDim2.new(1, -156, 0, 24), UDim2.fromOffset(62, 8), 14, palette.ink, Enum.Font.GothamBold)
    label(swordCard, "SwordStatus", swordOwned and "Создан · можно сражаться на арене" or "Рецепт: 2 слитка + 6 дерева · свой верстак", UDim2.new(1, -156, 0, 46), UDim2.fromOffset(62, 35), 11, palette.muted)
    local swordEquip = button(swordCard, "SwordEquip", swordEquipped and "В РУКАХ" or "ВЗЯТЬ", UDim2.fromOffset(102, 30), UDim2.new(1, -114, 0, 8), swordEquipped and palette.gold or palette.forest)
    swordEquip.TextSize = 10
    swordEquip.Activated:Connect(function()
        if swordOwned then event:FireServer("EquipTool", "Sword") end
    end)
    local canCraftSword = not swordOwned and ingots >= 2 and wood >= 6
    local swordCraft = button(swordCard, "SwordCraft", swordOwned and "СОЗДАН" or "СОЗДАТЬ", UDim2.fromOffset(102, 30), UDim2.new(1, -114, 0, 52), canCraftSword and palette.coral or palette.muted)
    swordCraft.TextSize = 10
    swordCraft.Activated:Connect(function()
        if not swordOwned then
            event:FireServer("CraftSword")
            if not canCraftSword then showToast("Нужно 2 слитка и 6 дерева. Меч создаётся у своего верстака.") end
        end
    end)
    addInfo("Как добывать", "Добывай дерево, камень и железную руду. Переплавь руду в слитки и создай меч у верстака. На арене попробуй обычные удары и комбо.", 90)
end

local function renderWorld()
    addInfo("Твой архипелаг", "Восемь домашних островов соединены мостами с общей Солнечной рощей. Все острова остаются на своих местах.", 84)
    local bridgeHome = workspace:FindFirstChild("BridgeToGrove")
    local bridgeForest = workspace:FindFirstChild("BridgeToDusk")
    addInfo("Домашний остров", "Твой отдельный дом и ферма. Соседи могут прийти в гости, но не могут менять твои вещи.", 68)
    local homeBridgeBuilt = player:GetAttribute("Bridge_HomeToGrove") == true
    addInfo("Солнечная роща", bridgeHome and (homeBridgeBuilt and "Твой мост восстановлен. Можно идти в общий лес." or "Твой мост пока ждёт ремонта: нужно дерево ×5 и камень ×3.") or "Мосты пока не построены.", 68)
    addInfo("Лунная роща", bridgeForest and "От Солнечной рощи ведёт отдельный постоянный мост к волшебному острову." or "Мост пока закрыт.", 68)
    addInfo("Скоро новые земли", "Каменный кряж, древние руины и кристальная пещера станут следующими большими открытиями.", 78)
end

local expeditionTracks = {
    {
        id = "Grove", title = "СОЛНЕЧНАЯ РОЩА", subtitle = "Следопытство и первые тайники",
        icon = "Р", color = palette.mint,
        steps = {
            {key = "Fox", title = "Познакомиться с лисёнком", hint = "Найди гнездо лисёнка в Солнечной роще."},
            {key = "Seed", title = "Найти лунное семя", hint = "Позови лисёнка у следов на тропе."},
            {key = "FoxCaches", title = "Открыть три тайника", hint = "Попроси лисёнка искать тайники и забери три находки."},
        },
    },
    {
        id = "Dusk", title = "СУМЕРЕЧНАЯ ДОЛИНА", subtitle = "Лунные цветы и древние руны",
        icon = "С", color = palette.lilac,
        steps = {
            {key = "Moth", title = "Познакомиться с лунной молью", hint = "Найди её в Сумеречной долине."},
            {key = "MoonBloom", title = "Пробудить лунный цветок", hint = "Позови моль к скрытому цветку."},
            {key = "MoonGateTrace", title = "Найти след древних корней", hint = "Вернись с лисёнком к древним корням."},
            {key = "MoonGateOpen", title = "Зажечь древние руны", hint = "Позови моль к рунам у тайного прохода."},
            {key = "MoonRelic", title = "Забрать звёздный осколок", hint = "Пройди через открытую арку."},
            {key = "CrystalGrottoDiscovered", title = "Открыть Кристальную пещеру", hint = "Вернись к сияющему входу в Сумеречной долине."},
            {key = "CrystalHeart", title = "Собрать сердце пещеры", hint = "Исследуй зал и забери кристальный осколок."},
            {key = "CrystalRunes", title = "Пробудить три руны", hint = "Найди подсказку и повтори песнь пещеры."},
            {key = "CrystalCache", title = "Открыть древний тайник", hint = "После пробуждения рун открой запечатанный сундук."},
            {key = "CrystalEchoDiscovered", title = "Найти Эхо-камеру", hint = "Используй древнюю печать у золотой двери за тайником."},
            {key = "PrismSeedFound", title = "Собрать призматическое семя", hint = "Исследуй скрытую комнату и найди редкое семя."},
            {key = "CrystalWisp", title = "Подружиться с кристальным светляком", hint = "Предложи призматическое семя обитателю Эхо-камеры."},
        },
    },
}

local function isExpeditionStepComplete(step)
    if step.key == "FoxCaches" then
        return (tonumber(player:GetAttribute("FoxSearchCount")) or 0) >= 3
    end
    return player:GetAttribute(step.key) == true
end

local function renderExpeditions()
    addInfo("ДНЕВНИК ЭКСПЕДИЦИЙ", "Записывай новые находки и выполненные задания. Все открытия сохраняются в твоём дневнике.", 78)
    local totalCompleted = 0
    local totalSteps = 0
    for _, track in expeditionTracks do
        local completed = 0
        for _, step in track.steps do
            totalSteps += 1
            if isExpeditionStepComplete(step) then
                completed += 1
                totalCompleted += 1
            end
        end

        local header = card(body, track.id .. "Expedition", 70)
        header.BackgroundColor3 = Color3.fromRGB(232, 239, 218)
        label(header, "Icon", track.icon, UDim2.fromOffset(42, 46), UDim2.fromOffset(12, 12), 27, track.color, Enum.Font.GothamBold)
        label(header, "Title", track.title, UDim2.new(1, -130, 0, 22), UDim2.fromOffset(60, 10), 13, palette.ink, Enum.Font.GothamBlack)
        label(header, "Subtitle", track.subtitle, UDim2.new(1, -130, 0, 18), UDim2.fromOffset(60, 34), 10, palette.muted)
        local count = label(header, "Count", tostring(completed) .. "/" .. tostring(#track.steps), UDim2.fromOffset(52, 28), UDim2.new(1, -62, 0.5, -14), 14, track.color, Enum.Font.GothamBlack)
        count.TextXAlignment = Enum.TextXAlignment.Center

        for index, step in track.steps do
            local done = isExpeditionStepComplete(step)
            local item = card(body, track.id .. "Step" .. tostring(index), 58)
            item.BackgroundColor3 = done and Color3.fromRGB(235, 242, 224) or palette.paper
            label(item, "State", done and "✓" or tostring(index), UDim2.fromOffset(30, 34), UDim2.fromOffset(12, 12), 18, done and palette.forestLight or palette.muted, Enum.Font.GothamBlack)
            label(item, "Title", step.title, UDim2.new(1, -62, 0, 22), UDim2.fromOffset(48, 6), 13, palette.ink, Enum.Font.GothamBold)
            label(item, "Hint", done and "Открытие записано в дневник." or step.hint, UDim2.new(1, -62, 0, 23), UDim2.fromOffset(48, 29), 10, palette.muted)
        end
    end
    addInfo("ПРОГРЕСС ИССЛЕДОВАНИЯ", "Открыто " .. tostring(totalCompleted) .. " из " .. tostring(totalSteps) .. " записей. Новые экспедиции появятся вместе с неизведанными землями.", 66)
end

local renderers = {
    City = renderCity,
    Farm = renderFarm,
    Pets = renderPets,
    Tools = renderTools,
    World = renderWorld,
    Expeditions = renderExpeditions,
}

local panelTitles = {
    City = {"МОЙ ОСТРОВ", "Твой дом и будущий город"},
    Farm = {"МОЯ ФЕРМА", "Сажай, выращивай и собирай урожай"},
    Pets = {"МОИ ПИТОМЦЫ", "Друзья, которые помогают в приключениях"},
    Tools = {"ИНСТРУМЕНТЫ", "Добывай материалы и готовься к путешествиям"},
    World = {"КАРТА МИРА", "Исследуй архипелаг и открывай новые земли"},
    Expeditions = {"ДНЕВНИК", "Твои открытия в Солнечной роще и Сумеречной долине"},
}

local activeTab = nil

applyPanelLayer = function()
    panel.ZIndex = 21
    for _, descendant in panel:GetDescendants() do
        if descendant:IsA("GuiObject") then
            descendant.ZIndex = 22
        end
    end
end

closeActivePanel = function()
    panel.Visible = false
    modalBackdrop.Visible = false
    activeTab = nil
    for _, navButton in navButtons do
        navButton.BackgroundColor3 = palette.forestLight
        navButton.TextColor3 = palette.white
    end
end

modalBackdrop.Activated:Connect(function()
    if panel.Visible then closeActivePanel() end
end)

local function openTab(tabName)
    if not panelTitles[tabName] or not renderers[tabName] then return end
    if activeTab == tabName and panel.Visible then
        closeActivePanel()
        return
    end
    activeTab = tabName
    panelTitle.Text = panelTitles[tabName][1]
    panelSubtitle.Text = panelTitles[tabName][2]
    clearBody()
    renderers[tabName]()
    applyPanelLayer()
    modalBackdrop.Visible = true
    panel.Visible = true
    for name, navButton in navButtons do
        navButton.BackgroundColor3 = name == tabName and palette.gold or palette.forestLight
        navButton.TextColor3 = name == tabName and palette.ink or palette.white
    end
end

navDefinitions = {
    {id = "City", title = "ОСТРОВ", glyph = "О"},
    {id = "Farm", title = "ФЕРМА", glyph = "Ф"},
    {id = "Pets", title = "ПИТОМЦЫ", glyph = "П"},
    {id = "Tools", title = "ИНСТРУМЕНТЫ", glyph = "И"},
    {id = "World", title = "КАРТА", glyph = "М"},
    {id = "Expeditions", title = "ДНЕВНИК", glyph = "Д"},
}

for _, definition in navDefinitions do
    local navButton = button(nav, definition.id, definition.glyph .. "\n" .. definition.title, UDim2.new(1 / #navDefinitions, -6, 1, -12), UDim2.new(), palette.forestLight)
    navButton.TextSize = 13
    navButton.TextYAlignment = Enum.TextYAlignment.Center
    navButton.Activated:Connect(function()
        openTab(definition.id)
    end)
    navButtons[definition.id] = navButton
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayout)
updateResponsiveLayout()
local function watchCamera(camera)
    if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout) end
    task.defer(updateResponsiveLayout)
end
watchCamera(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    watchCamera(workspace.CurrentCamera)
end)

closeButton.Activated:Connect(function()
    closeActivePanel()
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not panel.Visible then return end
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
        closeActivePanel()
    end
end)

showToast = function(message)
    if type(message) ~= "string" or message == "" then return end
    toastGeneration += 1
    local currentGeneration = toastGeneration
    if toastTween then
        toastTween:Cancel()
        toastTween = nil
    end
    toastText.Text = message
    toast.Visible = true
    toast.Size = UDim2.fromOffset(math.min(380, math.max(180, gui.AbsoluteSize.X - 32)), 48)
    toast.BackgroundTransparency = 0.08
    toast.Position = UDim2.new(0.5, 0, 1, -96)
    toastTween = TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 1, -106),
    })
    toastTween:Play()
    task.delay(3, function()
        if currentGeneration ~= toastGeneration or not toast.Parent then return end
        toastTween = TweenService:Create(toast, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        toastTween:Play()
        task.wait(0.22)
        if currentGeneration == toastGeneration and toast.Parent then
            toast.Visible = false
            toastTween = nil
        end
    end)
end

local tutorialMilestones = {
    {key = "Fox", title = "Знакомство с лисёнком"},
    {key = "Seed", title = "Лунное семя"},
    {key = "Moth", title = "Знакомство с молью"},
    {key = "MoonBloom", title = "Первый лунный цветок"},
    {key = "MoonGateTrace", title = "След древних корней"},
    {key = "MoonGateOpen", title = "Открытие тайного прохода"},
    {key = "MoonRelic", title = "Звёздный осколок"},
    {key = "Flower", title = "Цветок у дома"},
    {key = "Timber", title = "Ветви для фонаря"},
    {key = "Lantern", title = "Постройка фонаря"},
    {key = "Lit", title = "Пробуждение фонаря"},
}

local function getTutorialProgress()
    local completed = 0
    for _, milestone in tutorialMilestones do
        if player:GetAttribute(milestone.key) == true then
            completed += 1
        else
            break
        end
    end
    local total = #tutorialMilestones
    return completed, total
end

local function bridgeResourceProgress()
    local wood = math.max(0, math.floor(tonumber(player:GetAttribute("Resource_Wood")) or 0))
    local stone = math.max(0, math.floor(tonumber(player:GetAttribute("Resource_Stone")) or 0))
    return wood, stone
end

getObjective = function()
    if not player:GetAttribute("Ready") then return "Загружаем твой остров…" end
    if not player:GetAttribute("Bridge_HomeToGrove") then
        local wood, stone = bridgeResourceProgress()
        if wood < 5 or stone < 3 then
            return "Собери материалы для первого моста"
        end
        return "Материалы готовы! Восстанови мост."
    end
    if not player:GetAttribute("Fox") then
        return "Найди лисёнка в Солнечной роще"
    end
    if not player:GetAttribute("Seed") and player:GetAttribute("Companion") ~= "Fox" then
        return "Позови лисёнка из коллекции питомцев"
    end
    local activeCacheId = player:GetAttribute("FoxCacheSpot")
    if type(activeCacheId) == "string" and activeCacheId ~= "" then
        if player:GetAttribute("Companion") ~= "Fox" then
            return "Позови лисёнка, чтобы увидеть следы к тайнику."
        end
        return "Лисёнок нашёл тайник! Иди по золотым следам."
    end
    if not player:GetAttribute("Seed") then return "Попроси лисёнка искать: он найдёт лунное семя." end
    if not player:GetAttribute("Moth") then return "Перейди через лесной мост в Лунную рощу и найди моль." end
    if not player:GetAttribute("MoonBloom") then return "Позови лунную моль в Лунной роще — её сияние раскроет скрытый цветок." end
    if not player:GetAttribute("MoonGateTrace") then return "Позови лисёнка у древних корней в Лунной роще — он найдёт скрытый проход." end
    if not player:GetAttribute("MoonGateOpen") then return "Позови лунную моль у древних рун — её свет откроет тайный проход." end
    if not player:GetAttribute("MoonRelic") then return "Пройди через открывшуюся арку и забери редкий звёздный осколок." end
    if not player:GetAttribute("Flower") then return "Позови лунную моль к клумбе возле дома." end
    if not player:GetAttribute("Timber") then return "Возьми лисёнка к коряге и найди крепкие ветви." end
    if not player:GetAttribute("Lantern") then return "Заверши постройку садового фонаря у дома." end
    if not player:GetAttribute("Lit") then return "Позови лунную моль и зажги садовый фонарь." end
    return "Посади морковь на ферме и собери первый урожай!"
end

local function refresh()
    woodLabel.Text = "ДЕРЕВО  " .. tostring(player:GetAttribute("Resource_Wood") or 0)
    stoneLabel.Text = "КАМЕНЬ  " .. tostring(player:GetAttribute("Resource_Stone") or 0)
    objectiveText.Text = getObjective()
    local completed, total = getTutorialProgress()
    local bridgeBuilt = player:GetAttribute("Bridge_HomeToGrove") == true
    if player:GetAttribute("Ready") and not bridgeBuilt then
        local wood, stone = bridgeResourceProgress()
        objectiveEyebrow.Text = "НАЧНИ ЗДЕСЬ • ПЕРВЫЙ МОСТ"
        objectiveGlyph.Text = "М"
        objectiveHint.Text = wood >= 5 and stone >= 3
            and "Подойди к мосту у края острова и нажми E или кнопку действия."
            or ("Дерево " .. tostring(math.min(wood, 5)) .. "/5   Камень " .. tostring(math.min(stone, 3)) .. "/3\nПодойди к кучам у дома и нажми кнопку сбора")
        progressCount.Text = tostring(completed) .. " / " .. tostring(total)
    else
        objectiveEyebrow.Text = completed >= total
            and "ПРИКЛЮЧЕНИЕ ПРОДОЛЖАЕТСЯ"
            or ("ПУТЕШЕСТВИЕ • ШАГ " .. tostring(completed + 1) .. " ИЗ " .. tostring(total))
        objectiveGlyph.Text = completed >= total and "★" or tostring(completed + 1)
        if not bridgeBuilt then
            objectiveHint.Text = "Подготавливаем остров…"
        elseif not player:GetAttribute("Fox") then
            objectiveHint.Text = "Перейди мост → найди гнездо в роще → нажми «Подружиться»."
        elseif player:GetAttribute("Companion") ~= "Fox" and not player:GetAttribute("Seed") then
            objectiveHint.Text = "Открой «ПИТОМЦЫ» внизу и выбери лисёнка."
        elseif type(player:GetAttribute("FoxCacheSpot")) == "string"
            and player:GetAttribute("FoxCacheSpot") ~= "" then
            objectiveHint.Text = player:GetAttribute("Companion") == "Fox"
                and "Ищи золотые следы лап возле тропы в роще."
                or "Открой «ПИТОМЦЫ» и позови лисёнка к следам."
        elseif not player:GetAttribute("Seed") then
            objectiveHint.Text = "Пройди с лисёнком по тропе рощи: ищи находку."
        elseif not player:GetAttribute("Moth") then
            objectiveHint.Text = "По мосту из рощи иди в Сумеречную долину."
        else
            objectiveHint.Text = "Следуй цели, а открытия смотри в «ДНЕВНИКЕ»."
        end
        progressCount.Text = tostring(completed) .. " / " .. tostring(total)
    end
    if progressTween then progressTween:Cancel() end
    progressTween = TweenService:Create(progressFill, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(math.clamp(completed / total, 0, 1), 1),
    })
    progressTween:Play()
    brandSubtitle.Text = "УРОВЕНЬ ГОРОДА " .. tostring(player:GetAttribute("City_Level") or 1)
    if panel.Visible and activeTab and renderers[activeTab] then
        clearBody()
        renderers[activeTab]()
        applyPanelLayer()
    end
end

local playOverlay = Instance.new("Frame")
playOverlay.Name = "CompanionPlayOverlay"
playOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
playOverlay.Position = UDim2.fromScale(0.5, 0.5)
playOverlay.Size = UDim2.fromOffset(340, 210)
playOverlay.BackgroundColor3 = palette.paper
playOverlay.BorderSizePixel = 0
playOverlay.Visible = false
playOverlay.ZIndex = 50
playOverlay.Parent = gui
corner(playOverlay, 20)
stroke(playOverlay, palette.gold, 0.12, 2)

local playTitle = label(playOverlay, "Title", "ИГРА С ПИТОМЦЕМ", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 12), 17, palette.ink, Enum.Font.GothamBlack)
playTitle.TextXAlignment = Enum.TextXAlignment.Center
playTitle.ZIndex = 51
local playHint = label(playOverlay, "Hint", "Запомни огоньки!", UDim2.new(1, -28, 0, 48), UDim2.fromOffset(14, 44), 14, palette.muted, Enum.Font.GothamBold)
playHint.TextXAlignment = Enum.TextXAlignment.Center
playHint.ZIndex = 51

local playSymbols = {"●", "◆", "✦"}
local playButtons = {}
local activePlay = nil
local playNextIndex = 1

for index, symbol in playSymbols do
    local playButton = button(playOverlay, "Symbol" .. tostring(index), symbol,
        UDim2.fromOffset(88, 58), UDim2.fromOffset(24 + (index - 1) * 108, 126), index == 1 and palette.gold or index == 2 and palette.mint or palette.lilac)
    playButton.TextColor3 = palette.ink
    playButton.TextSize = 25
    playButton.ZIndex = 51
    playButton.Active = false
    playButton.AutoButtonColor = false
    playButtons[index] = playButton
    playButton.Activated:Connect(function()
        if not activePlay or not activePlay.inputEnabled then return end
        local expected = activePlay.sequence[playNextIndex]
        event:FireServer("CompanionPlayInput", {
            token = activePlay.token,
            index = playNextIndex,
            symbol = index,
        })
        if expected ~= index then
            activePlay.inputEnabled = false
            playHint.Text = "Ой! Попробуй ещё раз."
            for _, item in playButtons do item.Active = false end
            return
        end
        playNextIndex += 1
        if playNextIndex > #activePlay.sequence then
            activePlay.inputEnabled = false
            playHint.Text = "Ура! Проверяем результат..."
            for _, item in playButtons do item.Active = false end
        else
            playHint.Text = "Верно! Ещё " .. tostring(#activePlay.sequence - playNextIndex + 1) .. "!"
        end
    end)
end

local function beginCompanionPlay(payload)
    if type(payload) ~= "table" or type(payload.token) ~= "string"
        or type(payload.sequence) ~= "table" or type(payload.symbols) ~= "table" then return end
    activePlay = {
        token = payload.token,
        sequence = payload.sequence,
        inputEnabled = false,
    }
    playNextIndex = 1
    local sequenceText = {}
    for _, symbolIndex in payload.sequence do
        local symbol = payload.symbols[symbolIndex]
        if type(symbol) ~= "string" then return end
        table.insert(sequenceText, symbol)
    end
    playTitle.Text = payload.companionId == "Fox" and "СЛЕДЫ ЛИСЁНКА" or "ЛУННЫЕ ОГОНЬКИ"
    playHint.Text = "Запомни: " .. table.concat(sequenceText, "  ")
    playOverlay.Visible = true
    for _, item in playButtons do
        item.Active = false
        item.AutoButtonColor = false
    end
    task.delay(1.8, function()
        if not activePlay or activePlay.token ~= payload.token or not playOverlay.Parent then return end
        playHint.Text = "Теперь повтори последовательность!"
        activePlay.inputEnabled = true
        for _, item in playButtons do
            item.Active = true
            item.AutoButtonColor = true
        end
    end)
end

local function finishCompanionPlay(payload)
    playOverlay.Visible = false
    activePlay = nil
    if type(payload) == "table" and type(payload.message) == "string" then
        showToast(payload.message)
    end
end

event.OnClientEvent:Connect(function(message, payload)
    if message == "CompanionPlayStarted" then
        beginCompanionPlay(payload)
        return
    elseif message == "CompanionPlayFinished" then
        finishCompanionPlay(payload)
        return
    elseif message == "SwordCrafted" then
        showToast("Меч странника готов! Оружие появилось в инвентаре.")
        refresh()
        return
    end
    if type(message) == "string" and message ~= "ResourceState" and message ~= "ResourcePicked" then
        showToast(message)
    end
end)

player.AttributeChanged:Connect(refresh)
task.spawn(function()
    while gui.Parent do
        refresh()
        task.wait(1)
    end
end)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayout)
task.defer(updateResponsiveLayout)
refresh()
