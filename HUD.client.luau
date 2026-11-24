updatePlayOverlayLayout = function()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width = math.max(240, math.min(340, viewport.X - 24))
    local height = math.max(180, math.min(210, viewport.Y - 24))
    playOverlay.Size = UDim2.fromOffset(width, height)
    playOverlay.Position = UDim2.fromScale(0.5, 0.5)
    local buttonWidth = math.min(88, math.floor((width - 56) / 3))
    local gap = (width - buttonWidth * 3) / 4
    for index, item in playButtons do
        item.Size = UDim2.fromOffset(buttonWidth, 58)
        item.Position = UDim2.fromOffset(gap + (index - 1) * (buttonWidth + gap), height - 72)
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local companionTemplateResolver = require(ReplicatedStorage:WaitForChild("CompanionTemplateResolver"))

local homeVisualsAddedConnection
local homeIslandAddedConnection
local function refreshHomeInteriorView()
    if homeVisualsAddedConnection then
        homeVisualsAddedConnection:Disconnect()
        homeVisualsAddedConnection = nil
    end
    if homeIslandAddedConnection then
        homeIslandAddedConnection:Disconnect()
        homeIslandAddedConnection = nil
    end

    local active = player:GetAttribute("HomeInteriorActive") == true
    local islands = workspace:FindFirstChild("PlayerIslands")
    local ownerUserId = tonumber(player:GetAttribute("HomeInteriorIslandOwnerUserId")) or player.UserId
    if ownerUserId <= 0 then ownerUserId = player.UserId end
    local island = islands and islands:FindFirstChild("HomeIsland_" .. tostring(ownerUserId))
    if not island then return end

    local roofNames = {
        RoofSlope = true,
        ManorGable = true,
        TowerRoof = true,
        FrontCanopy = true,
    }
    local function bindVisuals(visuals)
        if homeVisualsAddedConnection then
            homeVisualsAddedConnection:Disconnect()
            homeVisualsAddedConnection = nil
        end
        local function updatePart(item)
            if item:IsA("BasePart") and roofNames[item.Name] then
                item.LocalTransparencyModifier = active and 1 or 0
            end
        end
        for _, item in ipairs(visuals:GetDescendants()) do
            updatePart(item)
        end
        if active then
            homeVisualsAddedConnection = visuals.DescendantAdded:Connect(updatePart)
        end
    end

    local visuals = island:FindFirstChild("HomeHouseVisuals")
    if visuals then bindVisuals(visuals) end
    homeIslandAddedConnection = island.ChildAdded:Connect(function(child)
        if child.Name == "HomeHouseVisuals" then
            bindVisuals(child)
        end
    end)
end

player:GetAttributeChangedSignal("HomeInteriorActive"):Connect(refreshHomeInteriorView)
task.defer(refreshHomeInteriorView)

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
    water = Color3.fromRGB(122, 191, 204),
    white = Color3.fromRGB(255, 253, 244),
}

local gui = Instance.new("ScreenGui")
gui.Name = "GiantbackHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
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

-- Only display imported hero meshes after the same Studio approval gates used by
-- the live follower. Blockout fallbacks are deliberately never presented as hero art.
local function createApprovedCompanionPreview(parent, companionId, objectName, size, position)
    local expectedName = companionId == "Fox" and "FoxCompanion"
        or companionId == "Moth" and "MothCompanion" or nil
    if not expectedName then return false end

    local template = companionTemplateResolver.resolve(ReplicatedStorage, companionId)
    if not template or template.Name ~= expectedName
        or template:GetAttribute("GiantbackImportStatus") ~= "Approved"
        or template:GetAttribute("GiantbackRuntimeReady") ~= true
        or template:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true then
        return false
    end

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = objectName
    viewport.Size = size
    viewport.Position = position
    viewport.BackgroundColor3 = Color3.fromRGB(235, 239, 220)
    viewport.BackgroundTransparency = 0.08
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(190, 190, 190)
    viewport.LightColor = Color3.fromRGB(255, 244, 220)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.Parent = parent
    corner(viewport, 18)
    stroke(viewport, palette.gold, 0.28, 1.5)

    local worldModel = Instance.new("WorldModel")
    worldModel.Name = "PreviewWorld"
    worldModel.Parent = viewport
    local clone = template:Clone()
    clone.Name = "ApprovedPreview"
    for _, descendant in clone:GetDescendants() do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end
    clone.Parent = worldModel

    local boundsCFrame, boundsSize = clone:GetBoundingBox()
    local focus = boundsCFrame.Position
    local extent = math.max(boundsSize.X, boundsSize.Y, boundsSize.Z, 1)
    local camera = Instance.new("Camera")
    camera.Name = "PreviewCamera"
    camera.FieldOfView = 34
    camera.CFrame = CFrame.lookAt(
        focus + Vector3.new(extent * 0.82, extent * 0.32, extent * 2.15),
        focus + Vector3.new(0, boundsSize.Y * 0.06, 0)
    )
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    return true
end

-- Native GUI pictograms: no emoji/font dependency, so icons render consistently on all devices.
local function createPictogram(parent, name, kind, size, tint)
    local root = Instance.new("Frame")
    root.Name = name
    root.Size = UDim2.fromOffset(size, size)
    root.BackgroundTransparency = 1
    root.Parent = parent
    local color = tint or palette.gold
    local function part(id, x, y, w, h, fill, rotation, round)
        local p = Instance.new("Frame")
        p.Name = id
        p.Position = UDim2.fromScale(x, y)
        p.Size = UDim2.fromScale(w, h)
        p.BackgroundColor3 = fill or color
        p.BorderSizePixel = 0
        p.Rotation = rotation or 0
        p.Parent = root
        local c = Instance.new("UICorner")
        c.CornerRadius = round and UDim.new(1, 0) or UDim.new(0.2, 0)
        c.Parent = p
    end
    if kind == "house" or kind == "cottage" or kind == "warehouse" then
        part("RoofL", 0.06, 0.18, 0.54, 0.14, color, -34)
        part("RoofR", 0.40, 0.18, 0.54, 0.14, color, 34)
        part("Walls", 0.18, 0.38, 0.64, 0.48, palette.paper)
        part("Door", 0.43, 0.59, 0.16, 0.27, palette.ink)
        part("WindowL", 0.25, 0.48, 0.14, 0.14, palette.water, nil, true)
        part("WindowR", 0.62, 0.48, 0.14, 0.14, palette.water, nil, true)
    elseif kind == "farm" or kind == "leaf" then
        part("Stem", 0.45, 0.30, 0.12, 0.58, palette.ink)
        part("LeafL", 0.10, 0.12, 0.43, 0.27, color, -28, true)
        part("LeafR", 0.48, 0.08, 0.42, 0.27, color, 28, true)
    elseif kind == "paw" then
        part("ToeL", 0.08, 0.14, 0.24, 0.24, color, nil, true)
        part("ToeM", 0.35, 0.03, 0.24, 0.24, color, nil, true)
        part("ToeR", 0.65, 0.14, 0.24, 0.24, color, nil, true)
        part("Pad", 0.20, 0.43, 0.60, 0.48, color, nil, true)
    elseif kind == "egg" then
        part("Shell", 0.24, 0.08, 0.52, 0.82, palette.paper, nil, true)
        part("Spot1", 0.34, 0.30, 0.12, 0.12, color, nil, true)
        part("Spot2", 0.55, 0.56, 0.10, 0.10, color, nil, true)
    elseif kind == "turtle" then
        part("Shell", 0.12, 0.25, 0.70, 0.62, color, nil, true)
        part("Head", 0.70, 0.48, 0.24, 0.24, palette.paper, nil, true)
        part("LegL", 0.08, 0.64, 0.20, 0.20, palette.ink, nil, true)
        part("LegR", 0.62, 0.78, 0.20, 0.18, palette.ink, nil, true)
    elseif kind == "owl" then
        part("EarL", 0.12, 0.10, 0.28, 0.30, color, -14)
        part("EarR", 0.60, 0.10, 0.28, 0.30, color, 14)
        part("Body", 0.18, 0.24, 0.64, 0.68, color, nil, true)
        part("EyeL", 0.28, 0.42, 0.22, 0.22, palette.paper, nil, true)
        part("EyeR", 0.50, 0.42, 0.22, 0.22, palette.paper, nil, true)
        part("PupilL", 0.35, 0.49, 0.08, 0.08, palette.ink, nil, true)
        part("PupilR", 0.57, 0.49, 0.08, 0.08, palette.ink, nil, true)
    elseif kind == "backpack" then
        part("Body", 0.18, 0.12, 0.64, 0.78, color)
        part("Pocket", 0.28, 0.52, 0.44, 0.28, palette.paper)
        part("StrapL", 0.08, 0.24, 0.13, 0.60, palette.ink)
        part("StrapR", 0.79, 0.24, 0.13, 0.60, palette.ink)
    elseif kind == "map" then
        part("PanelL", 0.05, 0.20, 0.28, 0.64, color)
        part("PanelC", 0.36, 0.12, 0.28, 0.72, palette.paper)
        part("PanelR", 0.67, 0.20, 0.28, 0.64, color)
        part("Pin", 0.58, 0.22, 0.20, 0.20, palette.coral, nil, true)
    elseif kind == "journal" then
        part("Cover", 0.12, 0.10, 0.76, 0.80, palette.paper)
        part("Spine", 0.42, 0.12, 0.12, 0.76, color)
        part("Line1", 0.61, 0.32, 0.18, 0.06, color)
        part("Line2", 0.61, 0.50, 0.18, 0.06, color)
        part("Line3", 0.61, 0.68, 0.18, 0.06, color)
    elseif kind == "axe" then
        part("Handle", 0.43, 0.30, 0.14, 0.64, Color3.fromRGB(139, 92, 58), -18)
        part("Blade", 0.12, 0.10, 0.62, 0.36, palette.paperDark, -18)
    elseif kind == "pickaxe" then
        part("Handle", 0.44, 0.28, 0.12, 0.68, Color3.fromRGB(139, 92, 58), 18)
        part("Head", 0.08, 0.18, 0.84, 0.18, color, -12)
    elseif kind == "sword" then
        part("Blade", 0.43, 0.06, 0.14, 0.62, palette.paper, -8)
        part("Guard", 0.16, 0.62, 0.68, 0.12, color)
        part("Grip", 0.43, 0.72, 0.14, 0.22, Color3.fromRGB(139, 92, 58))
    elseif kind == "wood" then
        part("Plank1", 0.10, 0.15, 0.80, 0.22, Color3.fromRGB(172, 117, 73))
        part("Plank2", 0.10, 0.42, 0.80, 0.22, Color3.fromRGB(197, 145, 91))
        part("Plank3", 0.10, 0.69, 0.80, 0.18, Color3.fromRGB(145, 94, 59))
    elseif kind == "stone" or kind == "stonepath" or kind == "crystal" then
        part("Stone1", 0.08, 0.34, 0.48, 0.48, color, -12)
        part("Stone2", 0.48, 0.18, 0.44, 0.62, palette.paperDark, 12)
        if kind == "crystal" then part("Core", 0.38, 0.34, 0.24, 0.30, palette.lilac, 45) end
    elseif kind == "fox" then
        part("EarL", 0.10, 0.04, 0.34, 0.44, color, -16)
        part("EarR", 0.56, 0.04, 0.34, 0.44, color, 16)
        part("Face", 0.17, 0.30, 0.66, 0.62, color, nil, true)
        part("Muzzle", 0.38, 0.62, 0.24, 0.17, palette.paper, nil, true)
    elseif kind == "moth" then
        part("WingL", 0.04, 0.12, 0.40, 0.62, color, -18, true)
        part("WingR", 0.56, 0.12, 0.40, 0.62, color, 18, true)
        part("Body", 0.44, 0.22, 0.12, 0.62, palette.paper, nil, true)
    elseif kind == "carrot" or kind == "berry" or kind == "pumpkin" or kind == "cabbage" or kind == "droplet" or kind == "mushroom" then
        local fill = kind == "carrot" and Color3.fromRGB(239, 143, 65)
            or kind == "berry" and palette.coral or kind == "pumpkin" and Color3.fromRGB(239, 143, 61)
            or kind == "cabbage" and palette.mint or kind == "droplet" and palette.water or palette.lilac
        part("Body", 0.18, 0.20, 0.64, 0.68, fill, nil, true)
        if kind == "pumpkin" then part("Stem", 0.43, 0.06, 0.16, 0.20, palette.ink) end
        if kind == "berry" then part("Leaf", 0.34, 0.12, 0.34, 0.16, palette.forest) end
    elseif kind == "flower" or kind == "arch" then
        part("PetalTop", 0.38, 0.04, 0.24, 0.30, color, nil, true)
        part("PetalL", 0.10, 0.34, 0.30, 0.30, color, nil, true)
        part("PetalR", 0.60, 0.34, 0.30, 0.30, color, nil, true)
        part("PetalBottom", 0.38, 0.62, 0.24, 0.30, color, nil, true)
        part("Center", 0.38, 0.36, 0.24, 0.24, palette.paper, nil, true)
    elseif kind == "greenhouse" then
        part("WallL", 0.12, 0.30, 0.14, 0.56, color)
        part("WallR", 0.74, 0.30, 0.14, 0.56, color)
        part("Roof", 0.08, 0.16, 0.84, 0.14, palette.paper)
        part("Floor", 0.12, 0.82, 0.76, 0.10, palette.ink)
    elseif kind == "lamp" then
        part("Post", 0.43, 0.30, 0.14, 0.60, palette.ink)
        part("Light", 0.24, 0.10, 0.52, 0.34, palette.gold, nil, true)
        part("Cap", 0.18, 0.06, 0.64, 0.12, color)
    elseif kind == "fence" then
        part("PostL", 0.10, 0.12, 0.16, 0.78, color)
        part("PostR", 0.74, 0.12, 0.16, 0.78, color)
        part("Rail1", 0.12, 0.30, 0.76, 0.14, palette.paper)
        part("Rail2", 0.12, 0.62, 0.76, 0.14, palette.paper)
    elseif kind == "bench" then
        part("Seat", 0.12, 0.40, 0.76, 0.18, color)
        part("Back", 0.12, 0.18, 0.76, 0.16, palette.paper)
        part("LegL", 0.22, 0.58, 0.12, 0.32, palette.ink)
        part("LegR", 0.66, 0.58, 0.12, 0.32, palette.ink)
    elseif kind == "tree" then
        part("Trunk", 0.43, 0.46, 0.16, 0.48, palette.ink)
        part("CrownL", 0.08, 0.20, 0.52, 0.52, color, nil, true)
        part("CrownR", 0.42, 0.12, 0.52, 0.56, color, nil, true)
    elseif kind == "birdbath" then
        part("Pedestal", 0.42, 0.38, 0.16, 0.52, palette.ink)
        part("Bowl", 0.12, 0.20, 0.76, 0.22, color, nil, true)
        part("Water", 0.26, 0.24, 0.48, 0.10, palette.water, nil, true)
    elseif kind == "lock" then
        part("Shackle", 0.26, 0.08, 0.48, 0.48, color, nil, true)
        part("LockBody", 0.16, 0.40, 0.68, 0.48, color)
    else
        -- Unknown future IDs still render a visible neutral badge, never an empty slot.
        part("FallbackBadge", 0.16, 0.16, 0.68, 0.68, color, nil, true)
        part("FallbackMark", 0.43, 0.30, 0.14, 0.40, palette.paper)
    end
    return root
end

local function setPictogramColor(root, color)
    for _, child in root:GetDescendants() do
        if child:IsA("Frame") then child.BackgroundColor3 = color end
    end
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
createPictogram(resources, "WoodIcon", "wood", 18, Color3.fromRGB(164, 108, 66)).Position = UDim2.fromOffset(8, 20)
createPictogram(resources, "StoneIcon", "stone", 18, Color3.fromRGB(126, 145, 145)).Position = UDim2.new(0.5, 7, 0, 20)
local woodLabel = label(resources, "Wood", "0", UDim2.new(0.5, -30, 1, 0), UDim2.fromOffset(29, 0), 13, palette.ink, Enum.Font.GothamBold)
local stoneLabel = label(resources, "Stone", "0", UDim2.new(0.5, -30, 1, 0), UDim2.new(0.5, 28, 0, 0), 13, palette.ink, Enum.Font.GothamBold)

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
local objectiveGlyph = label(objectiveIcon, "Glyph", "1", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 28, palette.ink, Enum.Font.GothamBlack)
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
local navIcons = {}
local navLabels = {}
local navDefinitions = {}
local closeActivePanel
local applyPanelLayer
local refreshActiveTab
local lastCompactLayout
local updatePlayOverlayLayout

local function updateResponsiveLayout()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local compact = viewport.X < 620
    local narrow = viewport.X < 480
    local shortScreen = viewport.Y < 440

    topBar.Position = UDim2.fromOffset(compact and 8 or 16, compact and 8 or 16)
    topBar.Size = UDim2.new(1, compact and -16 or -32, 0, compact and 48 or 58)
    brand.Size = UDim2.fromOffset(compact and (narrow and 104 or 132) or 178, compact and 48 or 58)
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

    nav.Position = UDim2.new(0.5, 0, 1, compact and -8 or -14)
    nav.Size = UDim2.new(1, compact and -16 or -32, 0, compact and (shortScreen and 48 or 56) or 72)
    navLayout.Padding = UDim.new(0, narrow and 1 or compact and 3 or 7)
    panelTitle.TextSize = compact and 16 or 20
    panelSubtitle.TextSize = compact and 10 or 12
    closeButton.Size = UDim2.fromOffset(compact and 36 or 42, compact and 36 or 42)
    closeButton.Position = UDim2.new(1, compact and -44 or -58, 0, compact and 8 or 12)
    for _, definition in navDefinitions do
        local navButton = navButtons[definition.id]
        local iconRoot = navIcons[definition.id]
        local titleLabel = navLabels[definition.id]
        if navButton then
            navButton.Size = UDim2.new(1 / #navDefinitions, narrow and -1 or compact and -4 or -8, 1, -8)
            local iconSize = narrow and 18 or compact and 20 or 24
            if iconRoot then
                iconRoot.Size = UDim2.fromOffset(iconSize, iconSize)
                iconRoot.Position = narrow and UDim2.new(0.5, -iconSize / 2, 0.5, -iconSize / 2)
                    or UDim2.new(0.5, -iconSize / 2, 0, 4)
            end
            if titleLabel then
                titleLabel.Visible = true
                titleLabel.TextSize = narrow and 9 or compact and 9 or 11
                titleLabel.Position = UDim2.new(0, 1, 1, -20)
                titleLabel.Size = UDim2.new(1, -2, 0, 16)
            end
        
        end
    end

    local panelWidth = math.max(240, math.min(560, viewport.X - 16))
    local panelHeight = math.max(210, math.min(560, viewport.Y - (shortScreen and 64 or compact and 112 or 160)))
    panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
    panelTitle.TextSize = compact and 16 or 20
    panelSubtitle.TextSize = compact and 10 or 12
    closeButton.Size = UDim2.fromOffset(compact and 36 or 42, compact and 36 or 42)
    closeButton.Position = UDim2.new(1, compact and -44 or -58, 0, compact and 8 or 12)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panelTitle.TextSize = compact and 16 or 20
    panelSubtitle.TextSize = compact and 10 or 12
    panelSubtitle.Visible = viewport.X >= 400 and viewport.Y >= 440
    body.Position = UDim2.fromOffset(12, compact and 66 or 76)
    body.Size = UDim2.new(1, -24, 1, compact and -78 or -88)
    toast.Size = UDim2.fromOffset(math.min(380, math.max(190, viewport.X - 24)), 48)
    toast.Position = UDim2.new(0.5, 0, 1, compact and -68 or -96)
    if updatePlayOverlayLayout then updatePlayOverlayLayout() end

    if lastCompactLayout ~= nil and lastCompactLayout ~= compact and refreshActiveTab then
        refreshActiveTab()
    end
    lastCompactLayout = compact
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
    {id = "Carrot", name = "Морковь", seed = "CarrotSeed", icon = "carrot", grow = "5 мин", sale = 4, color = palette.gold},
    {id = "Strawberry", name = "Клубника", seed = "StrawberrySeed", icon = "berry", grow = "12 мин · повторный сбор 8 мин", sale = 3, color = palette.coral},
    {id = "Pumpkin", name = "Тыква", seed = "PumpkinSeed", icon = "pumpkin", grow = "30 мин", sale = 18, color = palette.gold},
    {id = "Cabbage", name = "Капуста", seed = "CabbageSeed", icon = "cabbage", grow = "20 мин", sale = 12, color = palette.mint},
}
local cropById = {}
for _, crop in cropCatalog do cropById[crop.id] = crop end

local farmUpgradeCosts = {[2] = 60, [3] = 150}

local seedShopOffers = {
    Carrot = {amount = 3, cost = 12},
    Strawberry = {amount = 3, cost = 21},
    Pumpkin = {amount = 2, cost = 20},
    Cabbage = {amount = 2, cost = 16},
}

local festivalShopOffers = {
    {id = "HarvestEgg", name = "Призовое яйцо", description = "Ещё одна попытка открыть нового питомца", amount = 1, cost = 10, limit = 1, icon = "egg"},
    {id = "StarShard", name = "Звёздный осколок", description = "Редкий материал для магических открытий", amount = 1, cost = 4, limit = 2, icon = "crystal"},
    {id = "MoonPetal", name = "Лунные лепестки", description = "Три лепестка для особых находок", amount = 3, cost = 2, limit = 3, icon = "flower"},
    {id = "PumpkinSeed", name = "Семена тыквы", description = "Пять семян для осеннего урожая", amount = 5, cost = 1, limit = 3, icon = "pumpkin"},
}

local function addSeedChoice(crop, selectedCrop)
    local seeds = tonumber(player:GetAttribute("Resource_" .. crop.seed)) or 0
    local coins = tonumber(player:GetAttribute("Coins")) or 0
    local offer = seedShopOffers[crop.id]
    local selected = selectedCrop == crop.id
    local compact = gui.AbsoluteSize.X < 620
    local item = card(body, "Seed_" .. crop.id, compact and 122 or 82)
    item.BackgroundColor3 = selected and Color3.fromRGB(235, 241, 218) or palette.paper
    createPictogram(item, "CropIcon", crop.icon, 38, crop.color).Position = UDim2.fromOffset(12, compact and 10 or 21)
    label(item, "Name", crop.name,
        compact and UDim2.new(1, -68, 0, 24) or UDim2.new(1, -174, 0, 22),
        UDim2.fromOffset(60, 8), 15, palette.ink, Enum.Font.GothamBold)
    label(item, "Details", crop.grow .. "  •  семян: " .. tostring(seeds),
        compact and UDim2.new(1, -68, 0, 22) or UDim2.new(1, -174, 0, 38),
        UDim2.fromOffset(60, 33), 10, palette.muted)
    local chooseSize = compact and UDim2.new(0.5, -18, 0, 34) or UDim2.fromOffset(102, 29)
    local choosePosition = compact and UDim2.fromOffset(12, 78) or UDim2.new(1, -112, 0, 7)
    local choose = button(item, "Choose", selected and "ВЫБРАНО" or "ВЫБРАТЬ",
        chooseSize, choosePosition, selected and palette.gold or palette.forest)
    choose.TextSize = 10
    choose.Activated:Connect(function()
        if seeds < 1 then
            showToast("Семян нет. Купи набор ниже, а затем выбери культуру.")
            return
        end
        event:FireServer("SelectCrop", crop.id)
    end)
    local buy = button(item, "BuySeeds", "КУПИТЬ ×" .. tostring(offer.amount) .. " · " .. tostring(offer.cost) .. " мон.",
        compact and UDim2.new(0.5, -18, 0, 34) or UDim2.fromOffset(102, 29),
        compact and UDim2.new(0.5, 6, 0, 78) or UDim2.new(1, -112, 0, 44),
        coins >= offer.cost and palette.gold or palette.paperDark)
    buy.TextColor3 = coins >= offer.cost and palette.ink or palette.muted
    buy.TextSize = 8
    buy.Activated:Connect(function()
        event:FireServer("BuySeeds", crop.id)
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
    local compact = gui.AbsoluteSize.X < 620
    local item = card(body, "Plot" .. tostring(index), compact and 88 or 66)
    createPictogram(item, "PlotIcon", not unlocked and "lock" or (crop and crop.icon or "farm"), 34, palette.forest)
        .Position = UDim2.fromOffset(14, compact and 26 or 16)
    label(item, "Title", "Грядка " .. tostring(index),
        UDim2.new(1, -72, 0, 22), UDim2.fromOffset(60, 8), 15, palette.ink, Enum.Font.GothamBold)
    local state = label(item, "State", stateText,
        UDim2.new(1, -72, 0, compact and 46 or 30), UDim2.fromOffset(60, 31), compact and 11 or 12, palette.muted)
    state.TextYAlignment = Enum.TextYAlignment.Top
end

local showToast
local getObjective

local placementState = nil
local placementMoveIndex = nil
local placementGhost = nil
local placementOverlay = nil
local placementStatus = nil
local placementButtons = {}
local placementRotation = 0
local placementTarget = nil
local placementValid = false
local placementPointer = nil
local placementConnection = nil
local placementParts = {}

local function clearPlacementGhost()
    for _, part in ipairs(placementParts) do
        if part and part.Parent then part:Destroy() end
    end
    table.clear(placementParts)
    placementGhost = nil
end

local function makePlacementPart(name, size, offset, shape, rotation)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Shape = shape or Enum.PartType.Block
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Transparency = 1
    part.Parent = workspace
    table.insert(placementParts, {part = part, offset = offset, rotation = rotation})
    return part
end

local function createPlacementGhost(decorationId)
    clearPlacementGhost()
    if decorationId == "Path" then
        for row = 1, 2 do
            for column = 1, 2 do
                local offset = Vector3.new((column - 1.5) * 1.72, 0.2, (row - 1.5) * 1.72)
                makePlacementPart("PathPreview", Vector3.new(1.62, 0.24, 1.62), offset)
            end
        end
    elseif decorationId == "FlowerBed" then
        makePlacementPart("FlowerBedPreviewSoil", Vector3.new(3.35, 0.28, 3.35), Vector3.new(0, 0.18, 0))
        for _, edge in {
            {Vector3.new(3.8, 0.42, 0.28), Vector3.new(0, 0.34, -1.78)},
            {Vector3.new(3.8, 0.42, 0.28), Vector3.new(0, 0.34, 1.78)},
            {Vector3.new(0.28, 0.42, 3.35), Vector3.new(-1.78, 0.34, 0)},
            {Vector3.new(0.28, 0.42, 3.35), Vector3.new(1.78, 0.34, 0)},
        } do
            makePlacementPart("FlowerBedPreviewEdge", edge[1], edge[2])
        end
        local colors = {
            Color3.fromRGB(246, 190, 105), Color3.fromRGB(232, 143, 153),
            Color3.fromRGB(195, 164, 224), Color3.fromRGB(246, 224, 157),
        }
        for index = 1, 4 do
            local column = (index - 1) % 2
            local row = math.floor((index - 1) / 2)
            local offset = Vector3.new((column - 0.5) * 1.55, 0.72, (row - 0.5) * 1.55)
            local flower = makePlacementPart("FlowerPreview", Vector3.new(0.62, 0.42, 0.62),
                offset, Enum.PartType.Ball)
            flower.Color = colors[index]
        end
    elseif decorationId == "Cottage" then
        makePlacementPart("CottagePreviewFoundation", Vector3.new(3.8, 0.24, 3.8), Vector3.new(0, 0.12, 0))
        makePlacementPart("CottagePreviewWalls", Vector3.new(3.35, 2.25, 3.25), Vector3.new(0, 1.28, 0))
        makePlacementPart("CottagePreviewRoof", Vector3.new(3.9, 1.2, 3.8), Vector3.new(0, 3.0, 0))
        makePlacementPart("CottagePreviewDoor", Vector3.new(0.92, 1.72, 0.12), Vector3.new(0, 1.0, -1.68))
        for _, side in {-1, 1} do
            makePlacementPart("CottagePreviewWindow", Vector3.new(0.82, 0.72, 0.12), Vector3.new(side * 1.12, 1.52, -1.72))
        end
        makePlacementPart("CottagePreviewChimney", Vector3.new(0.62, 1.55, 0.62), Vector3.new(1.18, 3.2, 0.82))
    elseif decorationId == "Warehouse" then
        makePlacementPart("WarehousePreviewFoundation", Vector3.new(3.8, 0.28, 3.8), Vector3.new(0, 0.14, 0))
        makePlacementPart("WarehousePreviewBody", Vector3.new(3.35, 2.5, 3.25), Vector3.new(0, 1.5, 0))
        makePlacementPart("WarehousePreviewRoof", Vector3.new(3.95, 0.3, 3.9), Vector3.new(0, 2.95, 0))
        makePlacementPart("WarehousePreviewDoor", Vector3.new(1.15, 2.05, 0.16), Vector3.new(0, 1.08, -1.7))
    elseif decorationId == "GardenLamp" then
        local base = makePlacementPart("GardenLampPreviewBase", Vector3.new(1.55, 0.28, 1.55), Vector3.new(0, 0.14, 0))
        base.Color = Color3.fromRGB(119, 127, 116)
        local post = makePlacementPart("GardenLampPreviewPost", Vector3.new(0.3, 2.35, 0.3), Vector3.new(0, 1.75, 0))
        post.Color = Color3.fromRGB(105, 75, 50)
        local arm = makePlacementPart("GardenLampPreviewArm", Vector3.new(1.1, 0.18, 0.18), Vector3.new(0, 2.78, 0))
        arm.Color = Color3.fromRGB(207, 169, 91)
        local lantern = makePlacementPart("GardenLampPreviewLantern", Vector3.new(0.82, 0.88, 0.82), Vector3.new(0, 3.22, 0), Enum.PartType.Ball)
        lantern.Color = Color3.fromRGB(255, 221, 151)
        lantern.Transparency = 0.3
        local cap = makePlacementPart("GardenLampPreviewCap", Vector3.new(1.05, 0.18, 1.05), Vector3.new(0, 3.75, 0))
        cap.Color = Color3.fromRGB(207, 169, 91)
    elseif decorationId == "Fence" or decorationId == "WhiteFence" or decorationId == "StoneFence" or decorationId == "HedgeFence" then
        local color = decorationId == "WhiteFence" and Color3.fromRGB(244, 237, 214) or decorationId == "StoneFence" and Color3.fromRGB(151, 157, 149) or decorationId == "HedgeFence" and Color3.fromRGB(84, 145, 73) or Color3.fromRGB(164, 119, 77)
        for _, xOffset in {-1.78, 1.78} do
            local post = makePlacementPart("FencePreviewPost", Vector3.new(0.34, 1.42, 0.34), Vector3.new(xOffset, 0.72, 0))
            post.Color = color
        end
        for _, yOffset in {0.55, 1.12} do
            local rail = makePlacementPart("FencePreviewRail", Vector3.new(3.9, 0.2, 0.24), Vector3.new(0, yOffset, 0))
            rail.Color = color
        end
        if decorationId == "HedgeFence" then
            for index = 1, 5 do
                local leaf = makePlacementPart("HedgeFencePreviewLeaf", Vector3.new(0.92, 0.82, 0.72), Vector3.new((index - 3) * 0.67, 1.12, 0), Enum.PartType.Ball)
                leaf.Color = Color3.fromRGB(91, 158, 76)
            end
        end
    elseif decorationId == "Bench" then
        makePlacementPart("BenchPreviewSeat", Vector3.new(3.15, 0.22, 1.05), Vector3.new(0, 0.88, 0))
        makePlacementPart("BenchPreviewBack", Vector3.new(3.12, 0.26, 0.18), Vector3.new(0, 1.55, 0.48))
        for _, xOffset in {-1.25, 1.25} do makePlacementPart("BenchPreviewLeg", Vector3.new(0.22, 0.82, 0.82), Vector3.new(xOffset, 0.42, 0)) end
    elseif decorationId == "DecorativeTree" then
        makePlacementPart("TreePreviewTrunk", Vector3.new(0.62, 2.5, 0.62), Vector3.new(0, 1.34, 0))
        for _, offset in {Vector3.new(0, 3.0, 0), Vector3.new(-0.9, 2.65, 0.15), Vector3.new(0.88, 2.7, 0.08), Vector3.new(0.1, 3.75, 0.08)} do
            local crown = makePlacementPart("TreePreviewCrown", Vector3.new(1.72, 1.68, 1.72), offset, Enum.PartType.Ball)
            crown.Color = Color3.fromRGB(104, 166, 88)
        end
    elseif decorationId == "WoodenPath" then
        for index = 1, 5 do
            local plank = makePlacementPart("WoodenPathPreviewPlank", Vector3.new(3.25, 0.2, 0.58), Vector3.new(0, 0.12, (index - 3) * 0.72))
            plank.Color = Color3.fromRGB(148, 104, 68)
        end
    elseif decorationId == "GardenArch" then
        for _, xOffset in {-1.42, 1.42} do makePlacementPart("GardenArchPreviewPost", Vector3.new(0.34, 3.35, 0.34), Vector3.new(xOffset, 1.7, 0)) end
        makePlacementPart("GardenArchPreviewTop", Vector3.new(3.2, 0.42, 0.42), Vector3.new(0, 3.38, 0))
        for index = 1, 5 do
            local flower = makePlacementPart("GardenArchPreviewFlower", Vector3.new(0.46, 0.42, 0.46), Vector3.new((index - 3) * 0.58, 3.42, -0.02), Enum.PartType.Ball)
            flower.Color = Color3.fromRGB(232, 143, 153)
        end
    elseif decorationId == "BirdBath" then
        makePlacementPart("BirdBathPreviewFoot", Vector3.new(0.28, 1.55, 1.55), Vector3.new(0, 0.14, 0), Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(90)))
        makePlacementPart("BirdBathPreviewPedestal", Vector3.new(1.48, 0.48, 0.48), Vector3.new(0, 0.98, 0), Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(90)))
        local bowl = makePlacementPart("BirdBathPreviewBowl", Vector3.new(0.3, 2.2, 2.2), Vector3.new(0, 1.82, 0), Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(90)))
        bowl.Color = Color3.fromRGB(157, 160, 148)
        local water = makePlacementPart("BirdBathPreviewWater", Vector3.new(0.08, 1.72, 1.72), Vector3.new(0, 2.0, 0), Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.rad(90)))
        water.Color = Color3.fromRGB(116, 190, 207)
    elseif decorationId == "Greenhouse" then
        makePlacementPart("GreenhousePreviewFoundation", Vector3.new(3.8, 0.22, 3.8), Vector3.new(0, 0.11, 0))
        makePlacementPart("GreenhousePreviewSoil", Vector3.new(2.85, 0.12, 2.45), Vector3.new(0, 0.29, 0.12))
        for _, xOffset in {-1.72, 1.72} do
            for _, zOffset in {-1.72, 1.72} do
                makePlacementPart("GreenhousePreviewPost", Vector3.new(0.2, 2.8, 0.2), Vector3.new(xOffset, 1.48, zOffset))
            end
        end
        for _, side in {-1, 1} do
            makePlacementPart("GreenhousePreviewGlass", Vector3.new(0.08, 2.5, 3.25), Vector3.new(side * 1.72, 1.48, 0))
            makePlacementPart("GreenhousePreviewEndGlass", Vector3.new(3.25, 2.5, 0.08), Vector3.new(0, 1.48, side * 1.72))
        end
        makePlacementPart("GreenhousePreviewRoof", Vector3.new(3.72, 0.16, 3.72), Vector3.new(0, 2.86, 0))
        makePlacementPart("GreenhousePreviewDoor", Vector3.new(0.95, 2.2, 0.12), Vector3.new(0, 1.18, -1.76))
    end
end

local function finishPlacement()
    if placementConnection then placementConnection:Disconnect(); placementConnection = nil end
    if placementOverlay then placementOverlay:Destroy(); placementOverlay = nil end
    clearPlacementGhost()
    placementState = nil
    placementMoveIndex = nil
    placementTarget = nil
    placementPointer = nil
    placementValid = false
    table.clear(placementButtons)
end

local function getPlacementMeadow()
    local islands = workspace:FindFirstChild("PlayerIslands")
    local island = islands and islands:FindFirstChild("HomeIsland_" .. tostring(player.UserId))
    return island and island:FindFirstChild("Meadow")
end

local function getOccupiedPlacementCells(excludedIndex)
    local result = {}
    local encoded = player:GetAttribute("City_BuildingCells")
    if type(encoded) ~= "string" then return result end
    local index = 0
    for cell in string.gmatch(encoded, "[^;]+") do
        index += 1
        if index ~= excludedIndex then result[cell] = true end
    end
    return result
end

local placementCosts = {
    Path = {Wood = 2, Stone = 0}, FlowerBed = {Wood = 4, Stone = 2},
    Cottage = {Wood = 8, Stone = 6}, Warehouse = {Wood = 10, Stone = 8},
    Greenhouse = {Wood = 18, Stone = 12}, GardenLamp = {Wood = 6, Stone = 4},
    Fence = {Wood = 6, Stone = 2}, WhiteFence = {Wood = 8, Stone = 2},
    StoneFence = {Wood = 2, Stone = 8}, HedgeFence = {Wood = 6, Stone = 4},
    Bench = {Wood = 8, Stone = 2}, DecorativeTree = {Wood = 6, Stone = 4},
    WoodenPath = {Wood = 4, Stone = 0}, GardenArch = {Wood = 10, Stone = 6},
    BirdBath = {Wood = 4, Stone = 6},
}

local function updatePlacementGhost()
    if not placementState then return end
    local meadow = getPlacementMeadow()
    local camera = workspace.CurrentCamera
    if not meadow or not camera then
        placementValid = false
        placementTarget = nil
        placementStatus.Text = "Не удалось найти лужайку твоего острова"
        for _, entry in ipairs(placementParts) do
            if entry.part and entry.part.Parent then entry.part.Transparency = 1 end
        end
        if placementButtons.Confirm then
            placementButtons.Confirm.Active = false
            placementButtons.Confirm.AutoButtonColor = false
            placementButtons.Confirm.BackgroundColor3 = palette.muted
        end
        return
    end

    local pointer = placementPointer or UserInputService:GetMouseLocation()
    local ray = camera:ScreenPointToRay(pointer.X, pointer.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {meadow}
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
    if not hit then
        placementValid = false
        placementTarget = nil
        placementStatus.Text = UserInputService.TouchEnabled
            and "Коснись свободного места на лужайке"
            or "Наведи курсор на лужайку"
        for _, entry in ipairs(placementParts) do
            if entry.part and entry.part.Parent then entry.part.Transparency = 1 end
        end
        if placementButtons.Confirm then
            placementButtons.Confirm.Active = false
            placementButtons.Confirm.AutoButtonColor = false
            placementButtons.Confirm.BackgroundColor3 = palette.muted
        end
        return
    end

    local localPoint = meadow.CFrame:PointToObjectSpace(hit.Position)
    local x = math.clamp(math.floor(localPoint.X / 4 + 0.5) * 4, 0, 12)
    local z = math.clamp(math.floor(localPoint.Z / 4 + 0.5) * 4, -4, 8)
    local inBounds = localPoint.X >= -2 and localPoint.X <= 14
        and localPoint.Z >= -6 and localPoint.Z <= 10
    local cellKey = tostring(x) .. "," .. tostring(z)
    local occupied = getOccupiedPlacementCells(placementMoveIndex)[cellKey] == true
    local wood = tonumber(player:GetAttribute("Resource_Wood")) or 0
    local stone = tonumber(player:GetAttribute("Resource_Stone")) or 0
    local farmLevel = tonumber(player:GetAttribute("Farm_Level")) or 1
    local requiredCost = placementCosts[placementState] or {Wood = 18, Stone = 12}
    local enough = placementMoveIndex ~= nil or (
        wood >= requiredCost.Wood and stone >= requiredCost.Stone
        and (placementState ~= "Greenhouse" or farmLevel >= 3)
    )
    local count = tonumber(player:GetAttribute("City_DecorationCount")) or 0
    local hasSpace = placementMoveIndex ~= nil or count < 16
    placementValid = inBounds and not occupied and enough and hasSpace
    placementTarget = {x = x, z = z, rotation = placementRotation}

    local frame = meadow.CFrame * CFrame.new(x, meadow.Size.Y / 2 + 0.16, z)
        * CFrame.Angles(0, math.rad(placementRotation), 0)
    for _, entry in ipairs(placementParts) do
        local part = entry.part
        if part and part.Parent then
            part.CFrame = frame * CFrame.new(entry.offset) * (entry.rotation or CFrame.new())
            part.Transparency = 0.42
            part.Color = placementValid and Color3.fromRGB(105, 235, 145)
                or Color3.fromRGB(235, 100, 92)
        end
    end

    if not inBounds then
        placementStatus.Text = "За пределами строительной площадки"
    elseif occupied then
        placementStatus.Text = "Это место уже занято"
    elseif placementState == "Greenhouse" and farmLevel < 3 then
        placementStatus.Text = "Теплица откроется на 3 уровне фермы"
    elseif not enough then
        placementStatus.Text = "Не хватает материалов: дерево ×" .. tostring(requiredCost.Wood)
            .. ", камень ×" .. tostring(requiredCost.Stone)
    elseif not hasSpace then
        placementStatus.Text = "Достигнут лимит: 16 построек"
    else
        placementStatus.Text = "Место свободно • Поворот: " .. tostring(placementRotation) .. "°"
    end
    placementButtons.Confirm.Active = placementValid
    placementButtons.Confirm.AutoButtonColor = placementValid
    placementButtons.Confirm.BackgroundColor3 = placementValid and palette.forest or palette.muted
end

local function beginIslandPlacement(decorationId, moveIndex)
    if decorationId ~= "Path" and decorationId ~= "FlowerBed" and decorationId ~= "Cottage" and decorationId ~= "Warehouse" and decorationId ~= "Greenhouse" and decorationId ~= "GardenLamp" and decorationId ~= "Fence" and decorationId ~= "WhiteFence" and decorationId ~= "StoneFence" and decorationId ~= "HedgeFence" and decorationId ~= "Bench" and decorationId ~= "DecorativeTree" and decorationId ~= "WoodenPath" and decorationId ~= "GardenArch" and decorationId ~= "BirdBath" then return end
    finishPlacement()
    placementState = decorationId
    placementMoveIndex = moveIndex
    placementRotation = moveIndex
        and (tonumber(player:GetAttribute("City_Decoration_" .. tostring(moveIndex) .. "_Rotation")) or 0)
        or 0
    createPlacementGhost(decorationId)
    closeActivePanel()
    placementOverlay = Instance.new("Frame")
    placementOverlay.Name = "BuildPlacementControls"
    placementOverlay.AnchorPoint = Vector2.new(0.5, 1)
    placementOverlay.Position = UDim2.new(0.5, 0, 1, -88)
    placementOverlay.Size = UDim2.new(1, -24, 0, 112)
    placementOverlay.BackgroundColor3 = palette.ink
    placementOverlay.BorderSizePixel = 0
    placementOverlay.ZIndex = 45
    placementOverlay.Parent = gui
    corner(placementOverlay, 18)
    stroke(placementOverlay, palette.gold, 0.2, 1.5)

    placementStatus = label(placementOverlay, "Status", "Наведи на лужайку и выбери место",
        UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 7), 12, palette.white, Enum.Font.GothamBold)
    placementStatus.TextXAlignment = Enum.TextXAlignment.Center
    placementStatus.ZIndex = 46

    local rotate = button(placementOverlay, "Rotate", "↻ ПОВОРОТ",
        UDim2.new(0.32, -8, 0, 42), UDim2.new(0, 8, 0, 54), palette.forestLight)
    local cancel = button(placementOverlay, "Cancel", "ОТМЕНА",
        UDim2.new(0.32, -8, 0, 42), UDim2.new(0.34, 0, 0, 54), palette.coral)
    local confirm = button(placementOverlay, "Confirm", "ПОСТРОИТЬ",
        UDim2.new(0.32, -8, 0, 42), UDim2.new(0.68, 0, 0, 54), palette.forest)
    for _, control in {rotate, cancel, confirm} do
        control.ZIndex = 46
        control.TextSize = 11
    end
    placementButtons.Confirm = confirm
    confirm.Active = false
    confirm.AutoButtonColor = false
    confirm.BackgroundColor3 = palette.muted

    rotate.Activated:Connect(function()
        placementRotation = (placementRotation + 90) % 360
        updatePlacementGhost()
    end)
    cancel.Activated:Connect(finishPlacement)
    confirm.Activated:Connect(function()
        if not placementValid or not placementTarget or not placementState then return end
        event:FireServer("PlaceIslandDecoration", {
            id = placementState,
            x = placementTarget.x,
            z = placementTarget.z,
            rotation = placementTarget.rotation,
            moveIndex = placementMoveIndex,
        })
        finishPlacement()
    end)

    if placementConnection then placementConnection:Disconnect() end
    placementConnection = RunService.RenderStepped:Connect(updatePlacementGhost)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not placementState or processed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        placementPointer = Vector2.new(input.Position.X, input.Position.Y)
        task.defer(updatePlacementGhost)
    elseif input.KeyCode == Enum.KeyCode.R then
        placementRotation = (placementRotation + 90) % 360
        updatePlacementGhost()
    elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
        finishPlacement()
    end
end)

UserInputService.InputChanged:Connect(function(input, processed)
    if not placementState or processed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        placementPointer = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

local function renderCity()
    local cityLevel = tonumber(player:GetAttribute("City_Level")) or 1
    local homeLevel = tonumber(player:GetAttribute("Home_Level")) or 1
    local farmLevel = tonumber(player:GetAttribute("Farm_Level")) or 1
    local homeSlot = tonumber(player:GetAttribute("HomeIslandSlot")) or 0
    addInfo("Добро пожаловать домой!", "Это твой личный остров. Друзья могут приходить в гости, но строить и менять что-либо здесь можешь только ты.", 84)
    local coins = tonumber(player:GetAttribute("Coins")) or 0
    addInfo("Кошелёк • " .. tostring(coins) .. " монет", "Выращивай морковь, клубнику, тыкву и капусту, а затем продавай весь урожай на фермерском рынке.", 68)
    addInfo("Домашний остров №" .. tostring(homeSlot), "На сервере восемь личных островов. Дом и ферма на твоём участке принадлежат только тебе.", 76)
    addInfo("Уровень города: " .. tostring(cityLevel), "Строй и улучшай свой остров, собирай материалы и открывай новые места.", 76)
    local houseHint = homeLevel == 1
        and "Собери дерево ×20 и камень ×12, чтобы добавить второй этаж, балкон и пристройку."
        or (homeLevel == 2
            and "Собери дерево ×45 и камень ×30, чтобы превратить дом в большую сказочную усадьбу."
            or "Дом достиг максимального уровня. Теперь это твоя сказочная усадьба!")
    addInfo("Дом • уровень " .. tostring(homeLevel) .. " / 3", houseHint .. " Подойди к дому и нажми «Улучшить дом».", 82)
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
        .. "   •   Солнечные лепестки: " .. tostring(sunPetals) .. "   •   Лунные лепестки: " .. tostring(moonPetals), 98)
    addInfo("Ферма: уровень " .. tostring(farmLevel), "На острове четыре грядки. Открой раздел «Ферма», чтобы выбрать семена, посадить растения и собрать урожай.", 76)
    addInfo("Твой следующий шаг", getObjective(), 76)
    local decorationCount = tonumber(player:GetAttribute("City_DecorationCount")) or 0
    addInfo("Свободное строительство", "Построек: " .. tostring(decorationCount) .. "/16. Выбери объект, найди свободную клетку и подтверди размещение.", 82)
    local warehouseUsed = tonumber(player:GetAttribute("Warehouse_Used")) or 0
    local warehouseCapacity = tonumber(player:GetAttribute("Warehouse_Capacity")) or 120
    if player:GetAttribute("Warehouse_Built") then
        addInfo("Склад • " .. tostring(warehouseUsed) .. " / " .. tostring(warehouseCapacity),
            "Дерево: " .. tostring(player:GetAttribute("Warehouse_Wood") or 0)
            .. " • Камень: " .. tostring(player:GetAttribute("Warehouse_Stone") or 0)
            .. " • Руда: " .. tostring(player:GetAttribute("Warehouse_IronOre") or 0)
            .. " • Слитки: " .. tostring(player:GetAttribute("Warehouse_IronIngot") or 0)
            .. ". У склада можно сложить или забрать материалы.", 78)
    else
        addInfo("Склад ещё не построен", "Построй склад, чтобы хранить до 120 единиц дерева, камня, руды, слитков и урожая.", 66)
    end
    local compact = gui.AbsoluteSize.X < 620
    local catalog = {
        {id = "Path", title = "Каменная дорожка", description = "Четыре каменные плиты. Цена: 2 дерева.", cost = "2 ДЕРЕВА", icon = "stonepath"},
        {id = "FlowerBed", title = "Цветочная клумба", description = "Деревянная рамка и четыре цветка. Цена: 4 дерева и 2 камня.", cost = "4 ДЕРЕВА · 2 КАМНЯ", icon = "flower"},
        {id = "Cottage", title = "Уютный домик", description = "Домик с крышей, дверью, окнами и дымоходом. Цена: 8 дерева и 6 камня.", cost = "8 ДЕРЕВА · 6 КАМНЯ", icon = "cottage"},
        {id = "Warehouse", title = "Склад", description = "Храни до 120 единиц дерева, камня, руды, слитков и урожая. Цена: 10 дерева и 8 камня.", cost = "10 ДЕРЕВА · 8 КАМНЯ", icon = "warehouse"},
        {id = "Greenhouse", title = "Теплица", description = "На 3 уровне фермы. Новые посадки и повторный рост клубники на 15% быстрее. Цена: 18 дерева и 12 камня.", cost = "18 ДЕРЕВА · 12 КАМНЯ", icon = "greenhouse"},
        {id = "GardenLamp", title = "Садовый фонарь", description = "Тёплый свет для вечернего сада. Включай и выключай у самого фонаря. Цена: 6 дерева и 4 камня.", cost = "6 ДЕРЕВА · 4 КАМНЯ", icon = "lamp"},
        {id = "Fence", title = "Деревянная ограда", description = "Классический забор из тёплого дерева. Цена: 6 дерева и 2 камня.", cost = "6 ДЕРЕВА · 2 КАМНЯ", icon = "fence"},
        {id = "WhiteFence", title = "Белая ограда", description = "Светлый аккуратный забор с фигурными столбиками. Цена: 8 дерева и 2 камня.", cost = "8 ДЕРЕВА · 2 КАМНЯ", icon = "fence"},
        {id = "StoneFence", title = "Каменная ограда", description = "Прочная ограда из светлого камня. Цена: 2 дерева и 8 камня.", cost = "2 ДЕРЕВА · 8 КАМНЯ", icon = "stone"},
        {id = "HedgeFence", title = "Живая изгородь", description = "Плотная зелёная изгородь из кустов. Цена: 6 дерева и 4 камня.", cost = "6 ДЕРЕВА · 4 КАМНЯ", icon = "leaf"},
        {id = "Bench", title = "Садовая скамейка", description = "Уютная деревянная скамейка со спинкой. Цена: 8 дерева и 2 камня.", cost = "8 ДЕРЕВА · 2 КАМНЯ", icon = "bench"},
        {id = "DecorativeTree", title = "Цветущее дерево", description = "Небольшое дерево с пышной кроной и цветами. Цена: 6 дерева и 4 камня.", cost = "6 ДЕРЕВА · 4 КАМНЯ", icon = "tree"},
        {id = "WoodenPath", title = "Деревянная дорожка", description = "Пять деревянных настилов для уютных тропинок. Цена: 4 дерева.", cost = "4 ДЕРЕВА", icon = "wood"},
        {id = "GardenArch", title = "Цветочная арка", description = "Деревянная арка с цветами и зелёными побегами. Цена: 10 дерева и 6 камня.", cost = "10 ДЕРЕВА · 6 КАМНЯ", icon = "arch"},
        {id = "BirdBath", title = "Купальня для птиц", description = "Каменная чаша с чистой водой. Цена: 4 дерева и 6 камня.", cost = "4 ДЕРЕВА · 6 КАМНЯ", icon = "birdbath"},
    }
    for index = 1, decorationCount do
        local decorationId = player:GetAttribute("City_Decoration_" .. tostring(index) .. "_Id")
        local x = player:GetAttribute("City_Decoration_" .. tostring(index) .. "_X")
        local z = player:GetAttribute("City_Decoration_" .. tostring(index) .. "_Z")
        local rotation = player:GetAttribute("City_Decoration_" .. tostring(index) .. "_Rotation")
        if decorationId == "Path" or decorationId == "FlowerBed" or decorationId == "Cottage" or decorationId == "Warehouse" or decorationId == "Greenhouse" or decorationId == "GardenLamp" or decorationId == "Fence" or decorationId == "WhiteFence" or decorationId == "StoneFence" or decorationId == "HedgeFence" or decorationId == "Bench" or decorationId == "DecorativeTree" or decorationId == "WoodenPath" or decorationId == "GardenArch" or decorationId == "BirdBath" then
            local titles = {
                Path = "Каменная дорожка",
                FlowerBed = "Цветочная клумба",
                Cottage = "Уютный домик",
                Warehouse = "Склад",
                Greenhouse = "Теплица",
                GardenLamp = "Садовый фонарь",
                Fence = "Деревянная ограда",
                WhiteFence = "Белая ограда",
                StoneFence = "Каменная ограда",
                HedgeFence = "Живая изгородь",
                Bench = "Садовая скамейка",
                DecorativeTree = "Цветущее дерево",
                WoodenPath = "Деревянная дорожка",
                GardenArch = "Цветочная арка",
                BirdBath = "Купальня для птиц",
            }
            local title = titles[decorationId] or "Постройка"
            local item = card(body, "PlacedDecoration_" .. tostring(index), compact and 112 or 86)
            label(item, "Title", title .. " №" .. tostring(index),
                UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 7), 13, palette.ink, Enum.Font.GothamBold)
            label(item, "Position", "Клетка: " .. tostring(x) .. ", " .. tostring(z)
                .. " • Поворот: " .. tostring(rotation) .. "°",
                UDim2.new(1, -20, 0, 18), UDim2.fromOffset(12, 29), 10, palette.muted)
            local move = button(item, "Move", compact and "ПЕРЕМЕСТИТЬ" or "ПЕРЕМЕСТИТЬ",
                UDim2.new(0.48, -16, 0, 30), UDim2.new(0, 10, 1, -38), palette.forestLight)
            local remove = button(item, "Remove", "РАЗОБРАТЬ",
                UDim2.new(0.48, -16, 0, 30), UDim2.new(0.52, 6, 1, -38), palette.coral)
            move.TextSize = 10
            remove.TextSize = 10
            move.Activated:Connect(function()
                beginIslandPlacement(decorationId, index)
            end)
            remove.Activated:Connect(function()
                event:FireServer("RemoveIslandDecoration", index)
            end)
        end
    end
    addInfo("Управление постройками", "Перемещай предметы без повторной оплаты или разбирай их. При разборе возвращается половина материалов.", 68)
    for _, definition in catalog do
        local item = card(body, "Build_" .. definition.id, compact and 116 or 86)
        createPictogram(item, "BuildIcon", definition.icon, 38, palette.forestLight).Position =
            UDim2.fromOffset(12, compact and 8 or 20)
        local title = label(item, "Title", definition.title,
            compact and UDim2.new(1, -68, 0, 22) or UDim2.new(1, -150, 0, 22),
            UDim2.fromOffset(60, 8), 13, palette.ink, Enum.Font.GothamBold)
        title.TextWrapped = true
        local description = label(item, "Description", definition.description,
            compact and UDim2.new(1, -28, 0, 32) or UDim2.new(1, -150, 0, 38),
            UDim2.fromOffset(compact and 14 or 60, compact and 34 or 34), 10, palette.muted)
        description.TextWrapped = true
        description.TextYAlignment = Enum.TextYAlignment.Top
        local action = button(item, "Place", compact and "ВЫБРАТЬ МЕСТО" or "ПОСТРОИТЬ",
            compact and UDim2.new(1, -24, 0, 28) or UDim2.fromOffset(124, 32),
            compact and UDim2.fromOffset(12, 78) or UDim2.new(1, -136, 0, 26),
            palette.forest)
        action.TextSize = compact and 9 or 10
        local greenhouseBuilt = player:GetAttribute("Greenhouse_Built") == true
        local greenhouseLocked = definition.id == "Greenhouse" and farmLevel < 3
        if definition.id == "Greenhouse" and greenhouseBuilt then
            action.Text = "УЖЕ ПОСТРОЕНА"
            action.Active = false
            action.AutoButtonColor = false
            action.BackgroundColor3 = palette.paperDark
        elseif greenhouseLocked then
            action.Text = "ОТКРОЕТСЯ НА УР. 3"
            action.Active = false
            action.AutoButtonColor = false
            action.BackgroundColor3 = palette.paperDark
        else
            action.Activated:Connect(function()
                beginIslandPlacement(definition.id)
            end)
        end
    end
end

local function addFarmUpgrade(farmLevel)
    local coins = tonumber(player:GetAttribute("Coins")) or 0
    local nextLevel = farmLevel + 1
    local cost = farmUpgradeCosts[nextLevel]
    local item = card(body, "FarmUpgrade", 82)
    local title = farmLevel >= 3 and "Ферма • максимальный уровень" or ("Улучшение фермы → уровень " .. tostring(nextLevel))
    label(item, "Name", title, UDim2.new(1, -142, 0, 24), UDim2.fromOffset(12, 8), 14, palette.ink, Enum.Font.GothamBold)
    local description = farmLevel == 1 and "Откроет две дополнительные грядки" or "Откроет последнюю грядку"
    label(item, "Details", farmLevel >= 3 and "Все четыре грядки доступны" or description,
        UDim2.new(1, -142, 0, 30), UDim2.fromOffset(12, 36), 10, palette.muted)
    local action = button(item, "UpgradeFarm",
        farmLevel >= 3 and "МАКС." or (tostring(cost) .. " МОН."),
        UDim2.fromOffset(112, 38), UDim2.new(1, -122, 0.5, -19),
        farmLevel >= 3 and palette.paperDark or (coins >= cost and palette.gold or palette.paperDark))
    if farmLevel >= 3 or coins < cost then
        action.TextColor3 = palette.muted
    else
        action.TextColor3 = palette.ink
    end
    action.TextSize = 10
    action.Active = farmLevel < 3
    action.AutoButtonColor = farmLevel < 3 and coins >= cost
    action.Activated:Connect(function()
        if farmLevel >= 3 then return end
        if coins < cost then
            showToast("Нужно ещё " .. tostring(cost - coins) .. " монет. Продай собранный урожай на рынке.")
            return
        end
        event:FireServer("UpgradeFarm")
    end)
end

local function renderFarm()
    local farmLevel = tonumber(player:GetAttribute("Farm_Level")) or 1
    local selectedCrop = player:GetAttribute("Farm_SelectedCrop") or "Carrot"
    local totalSeeds = 0
    local harvestSummary = {}
    local marketPriceSummary = {}
    for _, crop in cropCatalog do
        totalSeeds += tonumber(player:GetAttribute("Resource_" .. crop.seed)) or 0
        local amount = tonumber(player:GetAttribute("Resource_" .. crop.id)) or 0
        if amount > 0 then table.insert(harvestSummary, crop.name .. " ×" .. tostring(amount)) end
        table.insert(marketPriceSummary, crop.name .. " — " .. tostring(crop.sale) .. " мон.")
    end
    addInfo("Ферма • уровень " .. tostring(farmLevel), "Семян всего: " .. tostring(totalSeeds) .. ( #harvestSummary > 0 and "   •   Урожай: " .. table.concat(harvestSummary, ", ") or "   •   Урожай пока не собран"), 78)
    if player:GetAttribute("Greenhouse_Built") == true then
        addInfo("Теплица построена • +15% к скорости роста", "Бонус действует на новые посадки и повторное созревание клубники. Уже растущие культуры не меняют своё время.", 68)
    elseif farmLevel >= 3 then
        addInfo("Открыта теплица", "Построй её в разделе «Остров»: новые посадки и повторный рост клубники будут созревать на 15% быстрее.", 68)
    else
        addInfo("Теплица • открывается на 3 уровне", "Улучши ферму до максимального уровня, чтобы построить стеклянную теплицу.", 68)
    end
    addInfo("1. Развитие фермы", "Улучшай ферму за монеты, чтобы открывать новые грядки. Сейчас доступно: " .. tostring(farmLevel == 1 and 1 or (farmLevel == 2 and 3 or 4)) .. " из 4.", 68)
    addFarmUpgrade(farmLevel)
    addInfo("2. Семена и магазин", "Монеты: " .. tostring(tonumber(player:GetAttribute("Coins")) or 0) .. ". Выбери культуру для посадки или купи набор семян. Покупка сохраняется в рюкзаке.", 76)
    addInfo("3. Цены на рынке", table.concat(marketPriceSummary, "   •   ") .. ". Подойди к стойке «РЫНОК» на своём острове и продай собранный урожай. Семена и материалы рынок не покупает.", 92)
    for _, crop in cropCatalog do addSeedChoice(crop, selectedCrop) end
    addInfo("4. Посади и собери", "Подойди к свободной грядке и выбери «Посадить». Когда урожай созреет, возвращайся за ним. Растения растут, даже если ты вышел из игры.", 86)
    for index = 1, 4 do
        addPlot(string.format("Plot%02d", index), index)
    end
end

local function renderPets()
    local pets = {
        {id = "Fox", name = "Лисёнок", role = "Разведчик", description = "Находит тайники и древние следы скрытых проходов.", location = "Ищи его в Солнечной роще.", icon = "fox"},
        {id = "Moth", name = "Лунная моль", role = "Хранитель света", description = "Пробуждает цветы и открывает древние лунные руны.", location = "Ищи её в Лунной роще.", icon = "moth"},
        {id = "CrystalWisp", name = "Кристальный светляк", role = "Проводник пещеры", description = "Призменное чутьё помогает находить скрытые кристальные жилы.", location = "Ищи его в кристальной пещере у тренировочной поляны.", icon = "crystal"},
        {id = "HarvestSprite", name = "Тыквик", role = "Спутник урожая", description = "Редкий праздничный дух с тёплым светом и осенней магией.", location = "Получи его за 100 очков Фестиваля урожая.", icon = "pumpkin"},
        {id = "BrambleBun", name = "Колючка", role = "Редкий • Лесной ёжик", description = "Собирает упавшие жёлуди и любит исследовать кусты.", location = "Вылупляется из призового яйца Фестиваля урожая.", icon = "paw"},
        {id = "MossTurtle", name = "Мохопанцирь", role = "Редкий • Тихий хранитель", description = "Маленькая черепаха с живым мхом на панцире.", location = "Вылупляется из призового яйца Фестиваля урожая.", icon = "turtle"},
        {id = "Glowcap", name = "Светошляп", role = "Эпический • Грибной огонёк", description = "Освещает путь мягким светом своей шляпки.", location = "Вылупляется из призового яйца Фестиваля урожая.", icon = "mushroom"},
        {id = "Dewdrop", name = "Росинка", role = "Эпический • Капля ручья", description = "Игривый водный малыш с сияющей каплей на лбу.", location = "Вылупляется из призового яйца Фестиваля урожая.", icon = "droplet"},
        {id = "Starling", name = "Звёздокрыл", role = "Легендарный • Ночной совёнок", description = "Самый редкий питомец яйца, хранит крошечный звёздный свет.", location = "Редчайшая находка призового яйца Фестиваля урожая.", icon = "owl"},
    }
    local compact = gui.AbsoluteSize.X < 620
    for _, pet in pets do
        local owned = player:GetAttribute(pet.id) == true
        local equipped = player:GetAttribute("Companion") == pet.id
        local item = card(body, pet.id .. "Card", compact and 330 or 214)
        local iconPlate = Instance.new("Frame")
        iconPlate.Name = "IconPlate"
        iconPlate.Size = UDim2.fromOffset(58, 58)
        iconPlate.Position = UDim2.fromOffset(10, compact and 10 or 24)
        iconPlate.BackgroundColor3 = pet.id == "Fox" and Color3.fromRGB(244, 215, 171)
            or pet.id == "Moth" and Color3.fromRGB(222, 215, 244)
            or pet.id == "HarvestSprite" and Color3.fromRGB(255, 220, 158)
            or pet.id == "BrambleBun" and Color3.fromRGB(239, 211, 177)
            or pet.id == "MossTurtle" and Color3.fromRGB(199, 226, 181)
            or pet.id == "Glowcap" and Color3.fromRGB(220, 203, 239)
            or pet.id == "Dewdrop" and Color3.fromRGB(181, 226, 235)
            or pet.id == "Starling" and Color3.fromRGB(199, 211, 243)
            or Color3.fromRGB(198, 229, 224)
        iconPlate.BorderSizePixel = 0
        iconPlate.Parent = item
        corner(iconPlate, 18)
        stroke(iconPlate, palette.gold, 0.55, 1)
        local petTint = pet.id == "Fox" and Color3.fromRGB(205, 125, 66)
            or pet.id == "Moth" and Color3.fromRGB(139, 119, 190)
            or pet.id == "MossTurtle" and Color3.fromRGB(91, 143, 84)
            or pet.id == "Dewdrop" and palette.water
            or pet.id == "Starling" and Color3.fromRGB(100, 126, 184)
            or palette.forestLight
        createPictogram(iconPlate, "PetPictogram", pet.icon, 42, petTint).Position = UDim2.fromOffset(8, 8)
        local nameLabel = label(item, "Name", pet.name .. " • " .. pet.role,
            compact and UDim2.new(1, -96, 0, 58) or UDim2.new(1, -210, 0, 24),
            UDim2.fromOffset(76, 8), 14, palette.ink, Enum.Font.GothamBold)
        nameLabel.TextWrapped = true
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        local desc = owned and pet.description or pet.location
        local descriptionLabel = label(item, "Description", desc,
            compact and UDim2.new(1, -28, 0, 32) or UDim2.new(1, -210, 0, 25),
            UDim2.fromOffset(compact and 14 or 76, compact and 78 or 33),
            compact and 11 or 11, palette.muted)
        descriptionLabel.TextWrapped = true
        descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
        local mood = player:GetAttribute("Companion_" .. pet.id .. "_Mood") or (pet.id == "Fox" and "Любопытство" or pet.id == "Moth" and "Спокойствие" or "Сияние")
        local moodLine = pet.id == "Fox" and "Любопытный исследователь" or pet.id == "Moth" and "Нежная хранительница света" or pet.id == "HarvestSprite" and "Добрый хранитель урожая" or pet.id == "BrambleBun" and "Осторожный собиратель" or pet.id == "MossTurtle" and "Спокойный защитник" or pet.id == "Glowcap" and "Светлый мечтатель" or pet.id == "Dewdrop" and "Весёлый непоседа" or pet.id == "Starling" and "Звёздный наблюдатель" or "Кристальный проводник"
        local moodText = mood == "Довольство" and "Довольство" or mood == "Радость" and "Радость" or mood
        local moodLabel = label(item, "Mood", owned and (moodLine .. " · " .. moodText) or "Характер откроется при знакомстве",
            compact and UDim2.new(1, -28, 0, 22) or UDim2.new(1, -220, 0, 18),
            UDim2.fromOffset(compact and 14 or 76, compact and 114 or 60), 10, palette.forest, Enum.Font.GothamBold)
        moodLabel.TextWrapped = true
        local bond = math.clamp(math.floor(tonumber(player:GetAttribute("Companion_" .. pet.id .. "_Bond")) or 0), 0, 1000)
        local bondRank = player:GetAttribute("Companion_" .. pet.id .. "_BondRank") or "Знакомство"
        label(item, "Friendship", owned and ("Дружба " .. tostring(bond) .. "/1000 · " .. bondRank) or "Сначала найди питомца",
            compact and UDim2.new(1, -28, 0, 18) or UDim2.new(1, -220, 0, 18),
            UDim2.fromOffset(compact and 14 or 76, compact and 138 or 84), 10, palette.forest, Enum.Font.GothamBold)

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
            and (" · Особая форма: " .. mutationName .. " (" .. tostring(mutationRarity or "Необычный") .. ")") or ""
        local progressionLabel = label(item, "Progression", owned and (growthStage .. " · " .. levelText .. mutationText) or "Уровень и мутация откроются при знакомстве",
            UDim2.new(1, -28, 0, compact and 34 or 20),
            UDim2.fromOffset(16, compact and 162 or 151), compact and 10 or 11, palette.ink, Enum.Font.GothamBold)
        progressionLabel.TextWrapped = true
        progressionLabel.TextYAlignment = Enum.TextYAlignment.Top
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
        local harvestTalent = "Осенний огонёк: уникальный сезонный спутник."
        local festivalTalent = "Питомец Фестиваля урожая: развивай дружбу и открывай его характер."
        local isFestivalHatchling = pet.id == "BrambleBun" or pet.id == "MossTurtle" or pet.id == "Glowcap" or pet.id == "Dewdrop" or pet.id == "Starling"
        local talentLabel = label(item, "Talent", owned and (pet.id == "Fox" and foxTalent or pet.id == "Moth" and mothTalent or pet.id == "HarvestSprite" and harvestTalent or isFestivalHatchling and festivalTalent or wispTalent) or "Найди питомца, чтобы открыть талант",
            UDim2.new(1, -28, 0, compact and 34 or 20),
            UDim2.fromOffset(16, compact and 202 or 179), 10, palette.forest)
        talentLabel.TextWrapped = true
        talentLabel.TextYAlignment = Enum.TextYAlignment.Top

        local actionSize = compact and UDim2.new(0.5, -18, 0, 36) or UDim2.fromOffset(108, 32)
        local actionPosition = compact and UDim2.fromOffset(12, 242) or UDim2.new(1, -120, 0, 8)
        local action = button(item, "Action", owned and (equipped and "РЯДОМ" or "ПОЗВАТЬ") or "НЕ НАЙДЕН", actionSize, actionPosition, equipped and palette.gold or palette.forest)
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
        local feed = button(item, "Feed", feedText, actionSize,
            compact and UDim2.new(0.5, 6, 0, 242) or UDim2.new(1, -120, 0, 46), palette.forestLight)
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
            actionSize, compact and UDim2.fromOffset(12, 284) or UDim2.new(1, -120, 0, 84), palette.gold)
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
            actionSize, compact and UDim2.new(0.5, 6, 0, 284) or UDim2.new(1, -120, 0, 122), palette.lilac)
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
    local compact = gui.AbsoluteSize.X < 620
    local wood = tonumber(player:GetAttribute("Resource_Wood")) or 0
    local stone = tonumber(player:GetAttribute("Resource_Stone")) or 0
    local ore = tonumber(player:GetAttribute("Resource_IronOre")) or 0
    local ingots = tonumber(player:GetAttribute("Resource_IronIngot")) or 0
    local smeltReadyAt = tonumber(player:GetAttribute("Smelter_ReadyAt")) or 0
    local smeltPending = tonumber(player:GetAttribute("Smelter_Pending")) or 0
    addInfo("Твой рюкзак", "Здесь собраны ресурсы, находки и снаряжение. Инструменты можно взять в руки прямо из этого раздела.", 78)
    addInfo("Материалы", "Дерево: " .. tostring(wood) .. "   •   Камень: " .. tostring(stone) .. "   •   Железная руда: " .. tostring(ore) .. "   •   Слитки: " .. tostring(ingots), 72)
    local seedSummary = {}
    local harvestSummary = {}
    for _, crop in cropCatalog do
        local seeds = tonumber(player:GetAttribute("Resource_" .. crop.seed)) or 0
        local harvest = tonumber(player:GetAttribute("Resource_" .. crop.id)) or 0
        if seeds > 0 then table.insert(seedSummary, crop.name .. " ×" .. tostring(seeds)) end
        if harvest > 0 then table.insert(harvestSummary, crop.name .. " ×" .. tostring(harvest)) end
    end
    addInfo("Семена и урожай",
        (#seedSummary > 0 and "Семена: " .. table.concat(seedSummary, ", ") or "Семян пока нет")
        .. "   •   "
        .. (#harvestSummary > 0 and "Урожай: " .. table.concat(harvestSummary, ", ") or "Урожай не собран"),
        72)
    local moonSeeds = tonumber(player:GetAttribute("Resource_MoonSeed")) or 0
    local starShards = tonumber(player:GetAttribute("Resource_StarShard")) or 0
    local sunPetals = tonumber(player:GetAttribute("Resource_SunPetal")) or 0
    local moonPetals = tonumber(player:GetAttribute("Resource_MoonPetal")) or 0
    addInfo("Редкие находки", "Лунные семена: " .. tostring(moonSeeds) .. "   •   Звёздные осколки: " .. tostring(starShards)
        .. "   •   Солнечные лепестки: " .. tostring(sunPetals) .. "   •   Лунные лепестки: " .. tostring(moonPetals), 76)
    local harvestEggs = tonumber(player:GetAttribute("Resource_HarvestEgg")) or 0
    addInfo("Праздничное яйцо", harvestEggs > 0 and ("В рюкзаке: " .. tostring(harvestEggs) .. " шт. Открой раздел «Экспедиции», чтобы вылупить нового питомца.") or "Яйцо можно получить за 50 очков Фестиваля урожая.", 54)
    local smeltStatus = smeltPending > 0 and (smeltReadyAt > os.time() and ("Плавится · " .. tostring(math.max(1, smeltReadyAt - os.time())) .. " сек.") or "Готово к сбору у плавильни") or "Рецепт: 3 железной руды + 2 дерева · 60 сек."
    addInfo("Плавильня на острове", smeltStatus, 58)
    local catalog = {
        {id = "Axe", name = "Топор путешественника", icon = "axe", purpose = "Рубит деревья", cost = "8 дерева · 6 камня"},
        {id = "Pickaxe", name = "Кирка путешественника", icon = "pickaxe", purpose = "Добывает камень", cost = "6 дерева · 8 камня"},
    }
    for _, definition in catalog do
        local level = tonumber(player:GetAttribute("Tool_" .. definition.id .. "Level")) or 1
        local owned = player:GetAttribute("Tool_" .. definition.id .. "Owned") == true
        local equipped = player:GetAttribute("Tool_Equipped") == definition.id
        local item = card(body, "Tool_" .. definition.id, compact and 132 or 106)
        createPictogram(item, "ToolIcon", definition.icon, 38, palette.gold).Position =
            UDim2.fromOffset(13, compact and 12 or 26)
        local nameLabel = label(item, "Name", definition.name,
            compact and UDim2.new(1, -72, 0, 24) or UDim2.new(1, -156, 0, 22),
            UDim2.fromOffset(62, 8), 14, palette.ink, Enum.Font.GothamBold)
        nameLabel.TextWrapped = true
        local detailsLabel = label(item, "Details", definition.purpose .. " · уровень " .. tostring(level),
            compact and UDim2.new(1, -28, 0, 22) or UDim2.new(1, -156, 0, 25),
            UDim2.fromOffset(compact and 14 or 62, compact and 58 or 33), 11, palette.muted)
        detailsLabel.TextWrapped = true
        local actionSize = compact and UDim2.new(0.5, -18, 0, 28) or UDim2.fromOffset(102, 30)
        local equipPosition = compact and UDim2.fromOffset(12, 94) or UDim2.new(1, -114, 0, 8)
        local equip = button(item, "Equip", equipped and "В РУКАХ" or "ВЗЯТЬ", actionSize, equipPosition, equipped and palette.gold or palette.forest)
        equip.TextSize = 10
        equip.Activated:Connect(function()
            if owned then event:FireServer("EquipTool", definition.id) end
        end)
        local upgradeText = level >= 2 and "МАКС. УРОВЕНЬ" or "УЛУЧШИТЬ"
        local upgrade = button(item, "Upgrade", upgradeText, actionSize,
            compact and UDim2.new(0.5, 6, 0, 94) or UDim2.new(1, -114, 0, 52), level >= 2 and palette.muted or palette.coral)
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
    local swordCard = card(body, "Tool_Sword", compact and 148 or 124)
    createPictogram(swordCard, "SwordIcon", "sword", 38, palette.gold).Position =
        UDim2.fromOffset(13, compact and 12 or 26)
    local swordName = label(swordCard, "SwordName", "Меч странника",
        compact and UDim2.new(1, -72, 0, 24) or UDim2.new(1, -156, 0, 24),
        UDim2.fromOffset(62, 8), 14, palette.ink, Enum.Font.GothamBold)
    swordName.TextWrapped = true
    local swordStatus = label(swordCard, "SwordStatus",
        swordOwned and "Создан · можно сражаться на арене" or "Рецепт: 2 слитка + 6 дерева · свой верстак",
        compact and UDim2.new(1, -28, 0, 30) or UDim2.new(1, -156, 0, 46),
        UDim2.fromOffset(compact and 14 or 62, compact and 54 or 35), 11, palette.muted)
    swordStatus.TextWrapped = true
    local swordActionSize = compact and UDim2.new(0.5, -18, 0, 28) or UDim2.fromOffset(102, 30)
    local swordEquip = button(swordCard, "SwordEquip", swordEquipped and "В РУКАХ" or "ВЗЯТЬ",
        swordActionSize, compact and UDim2.fromOffset(12, 108) or UDim2.new(1, -114, 0, 8),
        swordEquipped and palette.gold or palette.forest)
    swordEquip.TextSize = 10
    swordEquip.Activated:Connect(function()
        if swordOwned then event:FireServer("EquipTool", "Sword") end
    end)
    local canCraftSword = not swordOwned and ingots >= 2 and wood >= 6
    local swordCraft = button(swordCard, "SwordCraft", swordOwned and "СОЗДАН" or "СОЗДАТЬ",
        swordActionSize, compact and UDim2.new(0.5, 6, 0, 108) or UDim2.new(1, -114, 0, 52),
        canCraftSword and palette.coral or palette.muted)
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
        icon = "fox", color = palette.mint,
        steps = {
            {key = "Fox", title = "Познакомиться с лисёнком", hint = "Найди гнездо лисёнка в Солнечной роще."},
            {key = "Seed", title = "Найти лунное семя", hint = "Позови лисёнка у следов на тропе."},
            {key = "FoxCaches", title = "Открыть три тайника", hint = "Попроси лисёнка искать тайники и забери три находки."},
        },
    },
    {
        id = "Dusk", title = "СУМЕРЕЧНАЯ ДОЛИНА", subtitle = "Лунные цветы и древние руны",
        icon = "moth", color = palette.lilac,
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

local function renderDailyQuests()
    local day = player:GetAttribute("DailyQuest_Day") or "—"
    local claimed = player:GetAttribute("DailyQuest_Claimed") == true
    local reward = tonumber(player:GetAttribute("DailyQuest_Reward")) or 40
    local streak = tonumber(player:GetAttribute("DailyQuest_Streak")) or 0
    local bestStreak = tonumber(player:GetAttribute("DailyQuest_BestStreak")) or 0
    local streakAfterToday = tonumber(player:GetAttribute("DailyQuest_StreakAfterToday")) or 0
    local streakBonusToday = tonumber(player:GetAttribute("DailyQuest_StreakBonusToday")) or 0
    local nextMilestone = tonumber(player:GetAttribute("DailyQuest_StreakNextMilestone")) or 3
    local nextBonus = tonumber(player:GetAttribute("DailyQuest_StreakNextBonus")) or 20
    local count = math.clamp(math.floor(tonumber(player:GetAttribute("DailyQuest_Count")) or 0), 0, 3)
    addInfo("ЕЖЕДНЕВНЫЕ ЗАДАНИЯ", "Каждый день выбираются 3 задания из доступного тебе набора. Выполни их все и забери " .. tostring(reward) .. " монет. День: " .. tostring(day), 82)

    local completed = 0
    for index = 1, count do
        local prefix = "DailyQuest_" .. tostring(index) .. "_"
        local title = player:GetAttribute(prefix .. "Title") or "Задание путешественника"
        local description = player:GetAttribute(prefix .. "Description") or "Выполни игровую цель."
        local progress = tonumber(player:GetAttribute(prefix .. "Progress")) or 0
        local goal = math.max(1, tonumber(player:GetAttribute(prefix .. "Goal")) or 1)
        local questReward = math.max(0, math.floor(tonumber(player:GetAttribute(prefix .. "Reward")) or 0))
        local difficulty = player:GetAttribute(prefix .. "Difficulty") or "medium"
        local done = progress >= goal
        if done then completed += 1 end

        local compact = gui.AbsoluteSize.X < 620
        local item = card(body, "DailyQuest_" .. tostring(index), compact and 112 or 78)
        item.BackgroundColor3 = done and Color3.fromRGB(235, 242, 224) or palette.paper
        label(item, "Number", tostring(index), UDim2.fromOffset(36, 42),
            UDim2.fromOffset(10, compact and 8 or 14), 19, done and palette.forestLight or palette.gold, Enum.Font.GothamBlack)
        label(item, "Title", title,
            compact and UDim2.new(1, -126, 0, 36) or UDim2.new(1, -118, 0, 22),
            UDim2.fromOffset(54, 8), 13, palette.ink, Enum.Font.GothamBold)
        local hint = label(item, "Hint", done and "Задание выполнено!" or description,
            compact and UDim2.new(1, -28, 0, 30) or UDim2.new(1, -118, 0, 20),
            UDim2.fromOffset(compact and 14 or 54, compact and 48 or 30), 10, palette.muted)
        hint.TextYAlignment = Enum.TextYAlignment.Top
        local difficultyNames = {easy = "ЛЕГКО", medium = "СРЕДНЕ", hard = "СЛОЖНО"}
        local rewardText = label(item, "Reward", (difficultyNames[difficulty] or "СРЕДНЕ") .. "  •  +" .. tostring(questReward) .. " монет",
            compact and UDim2.new(1, -90, 0, 18) or UDim2.new(1, -118, 0, 16),
            UDim2.fromOffset(compact and 14 or 54, compact and 86 or 53), 9, difficulty == "hard" and palette.gold or palette.muted, Enum.Font.GothamBold)
        local countLabel = label(item, "Progress", tostring(math.min(progress, goal)) .. "/" .. tostring(goal),
            UDim2.fromOffset(56, 24), UDim2.new(1, -66, 0, compact and 8 or 27), 13, done and palette.forest or palette.ink, Enum.Font.GothamBlack)
        countLabel.TextXAlignment = Enum.TextXAlignment.Center
    end

    local totalReward = reward + streakBonusToday
    local claim = button(body, "ClaimDailyQuests", claimed and "НАГРАДА ПОЛУЧЕНА" or "ЗАБРАТЬ " .. tostring(totalReward) .. " МОНЕТ", UDim2.new(1, 0, 0, 46), UDim2.new(), claimed and palette.forestLight or palette.gold)
    claim.TextColor3 = claimed and palette.white or palette.ink
    claim.TextSize = 13
    claim.AutoButtonColor = not claimed
    claim.Activated:Connect(function()
        if claimed then
            showToast("Награда за сегодня уже получена.")
        elseif count == 0 or completed < count then
            showToast("Выполни все три задания, чтобы забрать награду.")
        else
            event:FireServer("ClaimDailyQuests")
        end
    end)
    addInfo("ПРОГРЕСС ДНЯ", tostring(completed) .. " из " .. tostring(count) .. " заданий выполнено" .. (claimed and " • награда получена" or ""), 52)
    local streakText = "Серия: " .. tostring(streak) .. " дн. • рекорд: " .. tostring(bestStreak) .. " дн."
    if not claimed then
        streakText ..= " • сегодня: " .. tostring(streakAfterToday) .. " дн."
        if streakBonusToday > 0 then
            streakText ..= " • бонус +" .. tostring(streakBonusToday) .. " Coins"
        else
            streakText ..= " • следующий бонус +" .. tostring(nextBonus) .. " на " .. tostring(nextMilestone) .. " днях"
        end
    else
        streakText ..= " • следующий бонус +" .. tostring(nextBonus) .. " на " .. tostring(nextMilestone) .. " днях"
    end
    addInfo("СЕРИЯ ЗАДАНИЙ", streakText, 54)

    local weeklyWeek = player:GetAttribute("WeeklyChallenge_Week") or "—"
    local weeklyClaimed = player:GetAttribute("WeeklyChallenge_Claimed") == true
    local weeklyReward = tonumber(player:GetAttribute("WeeklyChallenge_Reward")) or 0
    local weeklyCount = math.clamp(math.floor(tonumber(player:GetAttribute("WeeklyChallenge_Count")) or 0), 0, 3)
    addInfo("НЕДЕЛЬНЫЕ ИСПЫТАНИЯ", "Три особые цели на неделю • " .. tostring(weeklyWeek) .. ". Выполни их все, чтобы получить сундук с монетами и звёздным осколком.", 78)

    local weeklyCompleted = 0
    for index = 1, weeklyCount do
        local prefix = "WeeklyChallenge_" .. tostring(index) .. "_"
        local title = player:GetAttribute(prefix .. "Title") or "Испытание путешественника"
        local description = player:GetAttribute(prefix .. "Description") or "Выполняй приключения на этой неделе."
        local progress = tonumber(player:GetAttribute(prefix .. "Progress")) or 0
        local goal = math.max(1, tonumber(player:GetAttribute(prefix .. "Goal")) or 1)
        local challengeReward = math.max(0, math.floor(tonumber(player:GetAttribute(prefix .. "Reward")) or 0))
        local done = progress >= goal
        if done then weeklyCompleted += 1 end

        local compact = gui.AbsoluteSize.X < 620
        local item = card(body, "WeeklyChallenge_" .. tostring(index), compact and 112 or 72)
        item.BackgroundColor3 = done and Color3.fromRGB(235, 242, 224) or palette.paper
        label(item, "Number", tostring(index), UDim2.fromOffset(36, 42),
            UDim2.fromOffset(10, compact and 8 or 12), 18, done and palette.forestLight or palette.gold, Enum.Font.GothamBlack)
        label(item, "Title", title,
            compact and UDim2.new(1, -126, 0, 36) or UDim2.new(1, -118, 0, 22),
            UDim2.fromOffset(54, 7), 13, palette.ink, Enum.Font.GothamBold)
        local hint = label(item, "Hint", done and "Испытание выполнено!" or description,
            compact and UDim2.new(1, -28, 0, 30) or UDim2.new(1, -118, 0, 20),
            UDim2.fromOffset(compact and 14 or 54, compact and 46 or 29), 10, palette.muted)
        hint.TextYAlignment = Enum.TextYAlignment.Top
        label(item, "Reward", "+" .. tostring(challengeReward) .. " монет",
            compact and UDim2.new(1, -90, 0, 18) or UDim2.new(1, -118, 0, 16),
            UDim2.fromOffset(compact and 14 or 54, compact and 84 or 51), 9, palette.gold, Enum.Font.GothamBold)
        local progressLabel = label(item, "Progress", tostring(math.min(progress, goal)) .. "/" .. tostring(goal),
            UDim2.fromOffset(56, 24), UDim2.new(1, -66, 0, compact and 80 or 24), 13, done and palette.forest or palette.ink, Enum.Font.GothamBlack)
        progressLabel.TextXAlignment = Enum.TextXAlignment.Center
    end

    local weeklyClaim = button(body, "ClaimWeeklyChallenges", weeklyClaimed and "НЕДЕЛЬНАЯ НАГРАДА ПОЛУЧЕНА" or "ОТКРЫТЬ НЕДЕЛЬНЫЙ СУНДУК", UDim2.new(1, 0, 0, 46), UDim2.new(), weeklyClaimed and palette.forestLight or palette.gold)
    weeklyClaim.TextColor3 = weeklyClaimed and palette.white or palette.ink
    weeklyClaim.TextSize = 12
    weeklyClaim.AutoButtonColor = not weeklyClaimed
    weeklyClaim.Activated:Connect(function()
        if weeklyClaimed then
            showToast("Недельная награда уже получена.")
        elseif weeklyCount == 0 or weeklyCompleted < weeklyCount then
            showToast("Выполни все три недельных испытания.")
        else
            event:FireServer("ClaimWeeklyChallenges")
        end
    end)
    addInfo("НАГРАДА НЕДЕЛИ", tostring(weeklyCompleted) .. " из " .. tostring(weeklyCount) .. " испытаний • " .. tostring(weeklyReward) .. " Coins + 1 звёздный осколок", 52)

    local eventActive = player:GetAttribute("SeasonalEvent_Active") == true
    local eventTitle = player:GetAttribute("SeasonalEvent_Title") or "Сезонное событие"
    local eventDescription = player:GetAttribute("SeasonalEvent_Description") or "Выполняй особые задания и собирай награды."
    local eventPeriod = player:GetAttribute("SeasonalEvent_Period") or "23 ноября — 8 декабря • UTC"
    local eventPoints = math.clamp(math.floor(tonumber(player:GetAttribute("SeasonalEvent_Points")) or 0), 0, 100)
    local eventClaimable = math.clamp(math.floor(tonumber(player:GetAttribute("SeasonalEvent_ClaimableCount")) or 0), 0, 3)
    local eventCoins = math.max(0, math.floor(tonumber(player:GetAttribute("SeasonalEvent_RewardCoins")) or 0))
    local eventShards = math.max(0, math.floor(tonumber(player:GetAttribute("SeasonalEvent_RewardStarShards")) or 0))
    local eventStatus = eventActive and "СОБЫТИЕ ИДЁТ" or "СЛЕДУЮЩИЙ ФЕСТИВАЛЬ СКОРО"
    addInfo("СЕЗОННОЕ СОБЫТИЕ • " .. eventStatus, eventTitle .. " — " .. eventDescription .. " Период: " .. eventPeriod .. ".", 82)

    local eventCard = card(body, "SeasonalHarvestFestival", 142)
    eventCard.BackgroundColor3 = Color3.fromRGB(244, 235, 207)
    createPictogram(eventCard, "FestivalIcon", "flower", 34, palette.forest).Position = UDim2.fromOffset(14, 13)
    label(eventCard, "FestivalTitle", "ПУТЬ УРОЖАЯ", UDim2.new(1, -70, 0, 22), UDim2.fromOffset(58, 8), 13, palette.ink, Enum.Font.GothamBold)
    label(eventCard, "FestivalPoints", tostring(eventPoints) .. " / 100 очков фестиваля", UDim2.new(1, -70, 0, 20), UDim2.fromOffset(58, 31), 11, palette.forest, Enum.Font.GothamBold)
    local milestoneLines = {
        {points = 20, text = "20 очков • 30 Coins"},
        {points = 50, text = "50 очков • 1 звёздный осколок"},
        {points = 100, text = "100 очков • 80 Coins + 2 осколка"},
    }
    for index, milestone in milestoneLines do
        local claimed = player:GetAttribute("SeasonalEvent_Milestone_" .. tostring(milestone.points) .. "_Claimed") == true
        local reached = eventPoints >= milestone.points
        local status = claimed and "✓" or (reached and "●" or "○")
        label(eventCard, "Milestone" .. tostring(index), status .. "  " .. milestone.text, UDim2.new(1, -20, 0, 17), UDim2.fromOffset(14, 57 + (index - 1) * 19), 10, claimed and palette.forest or (reached and palette.gold or palette.muted), Enum.Font.GothamBold)
    end

    local eventClaim = button(body, "ClaimSeasonalEventRewards", eventClaimable > 0 and "ЗАБРАТЬ ПРАЗДНИЧНЫЕ НАГРАДЫ" or "СОБИРАЙ ОЧКИ ФЕСТИВАЛЯ", UDim2.new(1, 0, 0, 44), UDim2.new(), eventClaimable > 0 and palette.gold or palette.forestLight)
    eventClaim.TextColor3 = eventClaimable > 0 and palette.ink or palette.white
    eventClaim.TextSize = 12
    eventClaim.AutoButtonColor = eventActive and eventClaimable > 0
    eventClaim.Activated:Connect(function()
        if not eventActive then
            showToast("Фестиваль урожая проходит с 23 ноября по 8 декабря по UTC.")
        elseif eventClaimable <= 0 then
            showToast("Набери ещё очков, чтобы открыть праздничные награды.")
        else
            event:FireServer("ClaimSeasonalEventRewards")
        end
    end)
    local spriteClaimed = player:GetAttribute("SeasonalEvent_HarvestSpriteClaimed") == true or player:GetAttribute("HarvestSprite") == true
    local spriteClaim = button(body, "ClaimHarvestSprite", spriteClaimed and "ТЫКВИК УЖЕ С ТОБОЙ" or "ПОЛУЧИТЬ ТЫКВИКА • 100 ОЧКОВ", UDim2.new(1, 0, 0, 44), UDim2.new(), spriteClaimed and palette.forestLight or palette.gold)
    spriteClaim.TextColor3 = spriteClaimed and palette.white or palette.ink
    spriteClaim.TextSize = 12
    spriteClaim.AutoButtonColor = eventActive and eventPoints >= 100 and not spriteClaimed
    spriteClaim.Activated:Connect(function()
        if spriteClaimed then
            showToast("Тыквик уже путешествует с тобой!")
        elseif not eventActive then
            showToast("Тыквика можно получить во время Фестиваля урожая.")
        elseif eventPoints < 100 then
            showToast("Набери 100 очков фестиваля, чтобы познакомиться с Тыквиком.")
        else
            event:FireServer("ClaimHarvestSprite")
        end
    end)
    local eggClaimed = player:GetAttribute("SeasonalEvent_FestivalEggClaimed") == true
    local eggCount = math.max(0, math.floor(tonumber(player:GetAttribute("Resource_HarvestEgg")) or 0))
    local eggClaim = button(body, "ClaimFestivalEgg", eggClaimed and "ПРИЗОВОЕ ЯЙЦО УЖЕ ПОЛУЧЕНО" or "ПОЛУЧИТЬ ПРИЗОВОЕ ЯЙЦО • 50 ОЧКОВ", UDim2.new(1, 0, 0, 44), UDim2.new(), eggClaimed and palette.forestLight or palette.gold)
    eggClaim.TextColor3 = eggClaimed and palette.white or palette.ink
    eggClaim.TextSize = 12
    eggClaim.AutoButtonColor = eventActive and eventPoints >= 50 and not eggClaimed
    eggClaim.Activated:Connect(function()
        if eggClaimed then
            showToast("Призовое яйцо этого фестиваля уже получено.")
        elseif not eventActive then
            showToast("Призовое яйцо доступно во время Фестиваля урожая.")
        elseif eventPoints < 50 then
            showToast("Набери 50 очков фестиваля, чтобы получить яйцо.")
        else
            event:FireServer("ClaimFestivalEgg")
        end
    end)
    local hatchEgg = button(body, "HatchFestivalEgg", eggCount > 0 and ("ВЫЛУПИТЬ ЯЙЦО • " .. tostring(eggCount) .. " ШТ.") or "ЯЙЦО ПОКА НЕ ПОЛУЧЕНО", UDim2.new(1, 0, 0, 44), UDim2.new(), eggCount > 0 and palette.forest or palette.forestLight)
    hatchEgg.TextColor3 = palette.white
    hatchEgg.TextSize = 12
    hatchEgg.AutoButtonColor = eggCount > 0
    hatchEgg.Activated:Connect(function()
        if eggCount > 0 then
            event:FireServer("HatchFestivalEgg")
        else
            showToast("Сначала набери 50 очков и забери призовое яйцо.")
        end
    end)
    addInfo("ПРИЗОВОЕ ЯЙЦО • ШАНСЫ", "Колючка — 40% • Мохопанцирь — 32% • Светошляп — 18% • Росинка — 8% • Звёздокрыл — 2%. Шансы указаны для полного набора; уже открытые виды исключаются, их вес перераспределяется между оставшимися.", 76)

    local shopTokens = math.max(0, math.floor(tonumber(player:GetAttribute("SeasonalEvent_ShopTokens")) or 0))
    addInfo("ЛАВКА ФЕСТИВАЛЯ", "За каждые 5 очков события ты получаешь 1 листочек. Листочки не списывают очки прогресса и сохраняются до конца фестиваля.", 68)
    local tokenCard = card(body, "FestivalTokenWallet", 56)
    tokenCard.BackgroundColor3 = Color3.fromRGB(232, 240, 218)
    createPictogram(tokenCard, "TokenIcon", "flower", 30, palette.forest).Position = UDim2.fromOffset(16, 13)
    label(tokenCard, "TokenTitle", "ЛИСТОЧКИ", UDim2.new(1, -120, 0, 20), UDim2.fromOffset(58, 6), 11, palette.forest, Enum.Font.GothamBold)
    label(tokenCard, "TokenCount", tostring(shopTokens) .. " доступно", UDim2.new(1, -120, 0, 22), UDim2.fromOffset(58, 27), 14, palette.ink, Enum.Font.GothamBlack)
    for _, offer in festivalShopOffers do
        local purchased = math.max(0, math.floor(tonumber(player:GetAttribute("SeasonalEvent_ShopPurchase_" .. offer.id)) or 0))
        local soldOut = purchased >= offer.limit
        local allPetsOwned = player:GetAttribute("BrambleBun") == true
            and player:GetAttribute("MossTurtle") == true
            and player:GetAttribute("Glowcap") == true
            and player:GetAttribute("Dewdrop") == true
            and player:GetAttribute("Starling") == true
        local unavailable = offer.id == "HarvestEgg" and allPetsOwned
        local canBuy = eventActive and not soldOut and not unavailable and shopTokens >= offer.cost
        local item = card(body, "FestivalShop_" .. offer.id, 82)
        item.BackgroundColor3 = canBuy and Color3.fromRGB(250, 241, 218) or Color3.fromRGB(239, 234, 218)
        local offerTint = offer.id == "HarvestEgg" and palette.gold or offer.id == "StarShard" and palette.lilac or palette.forestLight
        createPictogram(item, "OfferIcon", offer.icon, 34, offerTint).Position = UDim2.fromOffset(12, 22)
        label(item, "Name", offer.name .. " ×" .. tostring(offer.amount), UDim2.new(1, -154, 0, 22), UDim2.fromOffset(54, 8), 12, palette.ink, Enum.Font.GothamBold)
        label(item, "Details", offer.description .. " · " .. tostring(purchased) .. "/" .. tostring(offer.limit), UDim2.new(1, -154, 0, 36), UDim2.fromOffset(54, 34), 9, palette.muted)
        local buyText = soldOut and "ЛИМИТ" or unavailable and "НЕ НУЖНО" or ("КУПИТЬ · " .. tostring(offer.cost) .. " лист.")
        local buy = button(item, "Buy", buyText, UDim2.fromOffset(112, 34), UDim2.new(1, -120, 0.5, -17), canBuy and palette.gold or palette.paperDark)
        buy.TextColor3 = canBuy and palette.ink or palette.muted
        buy.TextSize = 9
        buy.AutoButtonColor = canBuy
        buy.Activated:Connect(function()
            if soldOut then
                showToast("Лимит этой покупки на фестиваль уже исчерпан.")
            elseif unavailable then
                showToast("Ты уже собрал всех пяти питомцев.")
            elseif not eventActive then
                showToast("Лавка работает только во время Фестиваля урожая.")
            elseif shopTokens < offer.cost then
                showToast("Нужно ещё " .. tostring(offer.cost - shopTokens) .. " листочков.")
            else
                event:FireServer("BuyFestivalShopItem", offer.id)
            end
        end)
    end
    addInfo("ПРАВИЛА ЛАВКИ", "Лимиты покупок действуют на один фестиваль. При ошибке сохранения покупка и листочки автоматически возвращаются.", 58)
    addInfo("ПРАЗДНИЧНЫЕ НАГРАДЫ", tostring(eventPoints) .. "/100 очков • доступно рубежей: " .. tostring(eventClaimable) .. " • " .. tostring(eventCoins) .. " Coins + " .. tostring(eventShards) .. " осколков", 48)
end

local companionAlbumFilter = "Все"
local companionAlbumSort = "Редкость"
local companionAlbumSearch = ""
local companionAlbumSelected = nil

local function renderExpeditions()
    renderDailyQuests()
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
        createPictogram(header, "TrackIcon", track.icon, 34, track.color).Position = UDim2.fromOffset(16, 18)
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

    local relics = {
        {id = "Discovered_StarPrism", name = "Звёздная призма", rarity = "ЛЕГЕНДАРНАЯ", color = palette.gold, description = "Золотой кристалл, хранящий свет далёких звёзд."},
        {id = "Discovered_MoonGlass", name = "Лунное стекло", rarity = "РЕДКАЯ", color = palette.water, description = "Хрупкий осколок, отражающий лунное сияние."},
        {id = "Discovered_VoidGeode", name = "Пустотная жеода", rarity = "МИФИЧЕСКАЯ", color = palette.lilac, description = "Тёмная жеода с мерцающей энергией Эхо-камеры."},
    }
    local foundRelics = 0
    for _, relic in relics do
        if player:GetAttribute(relic.id) == true then foundRelics += 1 end
    end
    addInfo("КОЛЛЕКЦИЯ ЭХО-КАМЕРЫ", "Найди три древние реликвии в скрытой комнате Кристальной пещеры. Открытые находки сохраняются навсегда.", 76)
    local collectionHeader = card(body, "CrystalRelicCollection", 62)
    collectionHeader.BackgroundColor3 = Color3.fromRGB(232, 239, 218)
    createPictogram(collectionHeader, "CollectionIcon", "crystal", 30, palette.lilac).Position = UDim2.fromOffset(16, 15)
    label(collectionHeader, "CollectionTitle", "РЕЛИКВИИ ДРЕВНЕЙ ПЕЩЕРЫ", UDim2.new(1, -128, 0, 22), UDim2.fromOffset(58, 8), 12, palette.ink, Enum.Font.GothamBlack)
    label(collectionHeader, "CollectionCount", tostring(foundRelics) .. "/3", UDim2.fromOffset(52, 28), UDim2.new(1, -62, 0.5, -14), 15, palette.forest, Enum.Font.GothamBlack)
    for index, relic in relics do
        local found = player:GetAttribute(relic.id) == true
        local item = card(body, "CrystalRelic_" .. tostring(index), 78)
        item.BackgroundColor3 = found and Color3.fromRGB(235, 242, 224) or palette.paper
        createPictogram(item, "RelicIcon", "crystal", 28, found and relic.color or palette.muted).Position = UDim2.fromOffset(13, 23)
        label(item, "RelicName", found and relic.name or "Неизвестная реликвия", UDim2.new(1, -62, 0, 21), UDim2.fromOffset(52, 7), 12, palette.ink, Enum.Font.GothamBold)
        label(item, "RelicRarity", found and relic.rarity or "РЕДКОСТЬ НЕИЗВЕСТНА", UDim2.new(1, -62, 0, 16), UDim2.fromOffset(52, 29), 9, found and relic.color or palette.muted, Enum.Font.GothamBlack)
        label(item, "RelicHint", found and relic.description or "Ищи сияющие жилы в Эхо-камере.", UDim2.new(1, -62, 0, 22), UDim2.fromOffset(52, 48), 9, palette.muted)
    end
    local rewardClaimed = player:GetAttribute("CrystalRelicSetRewardClaimed") == true
    local rewardButton = button(
        body,
        "ClaimCrystalRelicSet",
        rewardClaimed and "НАГРАДА ПОЛУЧЕНА" or (foundRelics == 3 and "ЗАБРАТЬ НАГРАДУ • 150 МОНЕТ" or "СОБЕРИ ВСЕ 3 РЕЛИКВИИ"),
        UDim2.new(1, 0, 0, 44),
        UDim2.new(),
        rewardClaimed and palette.forestLight or (foundRelics == 3 and palette.gold or palette.muted)
    )
    rewardButton.TextColor3 = rewardClaimed and palette.white or palette.ink
    rewardButton.TextSize = 12
    rewardButton.Active = foundRelics == 3 and not rewardClaimed
    rewardButton.AutoButtonColor = rewardButton.Active
    rewardButton.Activated:Connect(function()
        if foundRelics == 3 and not rewardClaimed then
            event:FireServer("ClaimCrystalRelicSet")
        end
    end)

    -- The pet mutation codex reads only server-replicated, saved companion discoveries.
    -- A companion has one permanently rolled mutation, not sixteen collectible copies.
    local mutationPets = {
        {id = "Fox", title = "Лисёнок", biome = "Солнечная роща", icon = "fox", color = palette.gold},
        {id = "Moth", title = "Лунная моль", biome = "Сумеречная долина", icon = "moth", color = palette.lilac},
        {id = "CrystalWisp", title = "Кристальный светляк", biome = "Кристальная пещера", icon = "crystal", color = palette.water},
        {id = "HarvestSprite", title = "Тыквик", biome = "Фестиваль урожая", icon = "pumpkin", color = palette.coral},
        {id = "BrambleBun", title = "Колючка", biome = "Призовое яйцо Фестиваля урожая", icon = "paw", color = palette.gold},
        {id = "MossTurtle", title = "Мохопанцирь", biome = "Призовое яйцо Фестиваля урожая", icon = "turtle", color = palette.forest},
        {id = "Glowcap", title = "Светошляп", biome = "Призовое яйцо Фестиваля урожая", icon = "mushroom", color = palette.lilac},
        {id = "Dewdrop", title = "Росинка", biome = "Призовое яйцо Фестиваля урожая", icon = "droplet", color = palette.water},
        {id = "Starling", title = "Звёздокрыл", biome = "Призовое яйцо Фестиваля урожая", icon = "owl", color = palette.lilac},
    }
    local discoveredMutations = 0
    for _, pet in mutationPets do
        local owned = player:GetAttribute(pet.id) == true
        local mutationId = player:GetAttribute("Companion_" .. pet.id .. "_Mutation")
        if owned and type(mutationId) == "string" and mutationId ~= "" then
            discoveredMutations += 1
        end
    end
    addInfo("АЛЬБОМ РЕДКИХ ФОРМ", "У каждого питомца есть собственная особая форма. Находи друзей, открывай их мутации и заполняй альбом. Неизвестные записи подскажут, где искать следующего питомца.", 76)
    local compactAlbum = gui.AbsoluteSize.X < 620
    local mutationHeader = card(body, "CompanionMutationCodexHeader", 82)
    mutationHeader.BackgroundColor3 = Color3.fromRGB(232, 239, 218)
    createPictogram(mutationHeader, "CodexMark", "paw", 34, palette.lilac).Position = UDim2.fromOffset(14, 12)
    label(mutationHeader, "CodexTitle", "АЛЬБОМ РЕДКИХ ФОРМ", UDim2.new(1, -126, 0, 22), UDim2.fromOffset(58, 9), 12, palette.ink, Enum.Font.GothamBlack)
    label(mutationHeader, "CodexSubtitle", "Открыто особых форм", UDim2.new(1, -126, 0, 18), UDim2.fromOffset(58, 34), 10, palette.muted)
    local codexCount = label(mutationHeader, "CodexCount", tostring(discoveredMutations) .. "/" .. tostring(#mutationPets), UDim2.fromOffset(54, 28), UDim2.new(1, -62, 0, 10), 14, palette.forest, Enum.Font.GothamBlack)
    codexCount.TextXAlignment = Enum.TextXAlignment.Center
    local codexTrack = Instance.new("Frame")
    codexTrack.Name = "CodexProgressTrack"
    codexTrack.Position = UDim2.fromOffset(14, 67)
    codexTrack.Size = UDim2.new(1, -28, 0, 5)
    codexTrack.BackgroundColor3 = palette.paperDark
    codexTrack.BorderSizePixel = 0
    codexTrack.Parent = mutationHeader
    corner(codexTrack, 4)
    local codexFill = Instance.new("Frame")
    codexFill.Name = "CodexProgressFill"
    codexFill.Size = UDim2.fromScale(discoveredMutations / #mutationPets, 1)
    codexFill.BackgroundColor3 = palette.forestLight
    codexFill.BorderSizePixel = 0
    codexFill.Parent = codexTrack
    corner(codexFill, 4)

    local filterRow = Instance.new("Frame")
    filterRow.Name = "CompanionAlbumFilters"
    filterRow.Size = UDim2.new(1, 0, 0, 36)
    filterRow.BackgroundTransparency = 1
    filterRow.Parent = body
    local filters = {
        {id = "Все", title = "ВСЕ"},
        {id = "Найдены", title = "НАЙДЕНЫ"},
        {id = "Не найдены", title = "НЕ НАЙДЕНЫ"},
    }
    for index, filter in filters do
        local active = companionAlbumFilter == filter.id
        local filterButton = button(filterRow, "Filter_" .. tostring(index), filter.title,
            UDim2.new(1 / 3, -6, 1, 0), UDim2.new((index - 1) / 3, (index - 1) * 3, 0, 0),
            active and palette.forest or palette.paperDark)
        filterButton.TextColor3 = active and palette.white or palette.ink
        filterButton.TextSize = 9
        filterButton.Activated:Connect(function()
            companionAlbumFilter = filter.id
            refreshActiveTab()
        end)
    end

    local searchRow = Instance.new("Frame")
    searchRow.Name = "CompanionAlbumSearchRow"
    searchRow.Size = UDim2.new(1, 0, 0, 38)
    searchRow.BackgroundTransparency = 1
    searchRow.Parent = body
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "CompanionAlbumSearch"
    searchBox.Size = UDim2.new(1, -168, 1, 0)
    searchBox.Position = UDim2.new()
    searchBox.BackgroundColor3 = palette.white
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 12
    searchBox.TextColor3 = palette.ink
    searchBox.PlaceholderColor3 = palette.muted
    searchBox.PlaceholderText = "Найти питомца или биом…"
    searchBox.Text = companionAlbumSearch
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchRow
    corner(searchBox, 12)
    stroke(searchBox, palette.paperDark, 0.15, 1)
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 12)
    searchPadding.PaddingRight = UDim.new(0, 8)
    searchPadding.Parent = searchBox
    local searchButton = button(searchRow, "SearchAlbum", "ПОИСК",
        UDim2.fromOffset(48, 38), UDim2.new(1, -160, 0, 0), palette.forestLight)
    searchButton.TextSize = 8
    searchButton.Activated:Connect(function()
        companionAlbumSearch = string.sub(searchBox.Text, 1, 48)
        refreshActiveTab()
    end)
    local sortButton = button(searchRow, "SortByRarity", companionAlbumSort == "Редкость" and "РЕДКОСТЬ ↓" or "ИМЯ А–Я",
        UDim2.fromOffset(104, 38), UDim2.new(1, -104, 0, 0), palette.lilac)
    sortButton.TextColor3 = palette.ink
    sortButton.TextSize = 9
    sortButton.Activated:Connect(function()
        companionAlbumSort = companionAlbumSort == "Редкость" and "Имя" or "Редкость"
        refreshActiveTab()
    end)
    searchBox.FocusLost:Connect(function(enterPressed)
        companionAlbumSearch = string.sub(searchBox.Text, 1, 48)
        if enterPressed then refreshActiveTab() end
    end)

    local rarityOrder = {
        ["мифическая"] = 6,
        ["легендарная"] = 5,
        ["эпическая"] = 4,
        ["редкая"] = 3,
        ["необычная"] = 2,
        ["обычная"] = 1,
    }
    local visiblePets = {}
    local normalizedSearch = string.lower(companionAlbumSearch)
    for _, pet in mutationPets do
        local owned = player:GetAttribute(pet.id) == true
        local mutationId = player:GetAttribute("Companion_" .. pet.id .. "_Mutation")
        local found = owned and type(mutationId) == "string" and mutationId ~= ""
        local mutationName = player:GetAttribute("Companion_" .. pet.id .. "_MutationName")
        local matchesFilter = companionAlbumFilter == "Все"
            or (companionAlbumFilter == "Найдены" and found)
            or (companionAlbumFilter == "Не найдены" and not found)
        local searchable = string.lower(pet.title .. " " .. pet.biome .. " " .. tostring(mutationName or ""))
        if matchesFilter and (normalizedSearch == "" or string.find(searchable, normalizedSearch, 1, true)) then
            table.insert(visiblePets, pet)
        end
    end
    table.sort(visiblePets, function(a, b)
        if companionAlbumSort == "Имя" then
            return a.title < b.title
        end
        local aRarity = string.lower(tostring(player:GetAttribute("Companion_" .. a.id .. "_MutationRarity") or ""))
        local bRarity = string.lower(tostring(player:GetAttribute("Companion_" .. b.id .. "_MutationRarity") or ""))
        local aRank = rarityOrder[aRarity] or 0
        local bRank = rarityOrder[bRarity] or 0
        if aRank == bRank then return a.title < b.title end
        return aRank > bRank
    end)
    local selectedVisible = false
    for _, pet in visiblePets do
        if pet.id == companionAlbumSelected then selectedVisible = true break end
    end
    if not selectedVisible then companionAlbumSelected = nil end

    local resultCount = label(body, "AlbumResultCount",
        tostring(#visiblePets) .. " из " .. tostring(#mutationPets) .. " записей",
        UDim2.new(1, 0, 0, 18), UDim2.new(), 10, palette.muted, Enum.Font.GothamBold)
    resultCount.TextXAlignment = Enum.TextXAlignment.Right

    for index, pet in visiblePets do
        local owned = player:GetAttribute(pet.id) == true
        local mutationId = player:GetAttribute("Companion_" .. pet.id .. "_Mutation")
        local found = owned and type(mutationId) == "string" and mutationId ~= ""
        local mutationName = player:GetAttribute("Companion_" .. pet.id .. "_MutationName")
        local mutationRarity = player:GetAttribute("Companion_" .. pet.id .. "_MutationRarity")
        local item = card(body, "CompanionMutationCodex_" .. tostring(index), compactAlbum and 116 or 104)
        item.BackgroundColor3 = found and Color3.fromRGB(235, 242, 224) or Color3.fromRGB(242, 237, 222)
        local iconPlate = Instance.new("Frame")
        iconPlate.Name = "MutationIconPlate"
        iconPlate.Size = UDim2.fromOffset(48, 48)
        iconPlate.Position = UDim2.fromOffset(10, compactAlbum and 10 or 17)
        iconPlate.BackgroundColor3 = found and pet.color or palette.paperDark
        iconPlate.BackgroundTransparency = found and 0.72 or 0.12
        iconPlate.BorderSizePixel = 0
        iconPlate.Parent = item
        corner(iconPlate, 15)
        stroke(iconPlate, found and pet.color or palette.muted, 0.58, 1)
        createPictogram(iconPlate, "PetMark", found and pet.icon or "lock", 32,
            found and pet.color or palette.muted).Position = UDim2.fromOffset(8, 8)
        local titleText = found and (pet.title .. " • " .. (type(mutationName) == "string" and mutationName ~= "" and mutationName or mutationId))
            or (pet.title .. " • Неизвестная форма")
        local titleLabel = label(item, "MutationTitle", titleText,
            UDim2.new(1, -116, 0, compactAlbum and 38 or 24), UDim2.fromOffset(68, 7),
            12, palette.ink, Enum.Font.GothamBold)
        titleLabel.TextWrapped = true
        titleLabel.TextYAlignment = Enum.TextYAlignment.Top
        local rarityText = found and (string.upper(tostring(mutationRarity or "Необычная")) .. " ФОРМА") or "ЕЩЁ НЕ ОТКРЫТО"
        label(item, "MutationRarity", rarityText, UDim2.new(1, -116, 0, 17),
            UDim2.fromOffset(68, compactAlbum and 47 or 34), 9,
            found and pet.color or palette.muted, Enum.Font.GothamBlack)
        local hintText = found and ("Найдено: " .. pet.biome) or ("Место поиска: " .. pet.biome)
        local hintLabel = label(item, "MutationBiome", hintText,
            UDim2.new(1, -158, 0, 20), UDim2.fromOffset(68, compactAlbum and 67 or 55), 9, palette.muted)
        hintLabel.TextWrapped = true
        local state = label(item, "MutationState", found and "ОТКРЫТО" or "ИСКАТЬ",
            UDim2.fromOffset(64, 20), UDim2.new(1, -72, 0, compactAlbum and 8 or 12),
            8, found and palette.forest or palette.muted, Enum.Font.GothamBlack)
        state.TextXAlignment = Enum.TextXAlignment.Center
        local detailsButton = button(item, "Details",
            companionAlbumSelected == pet.id and "ВЫБРАНО" or "ПОДРОБНЕЕ",
            UDim2.fromOffset(76, 24), UDim2.new(1, -84, 1, -31),
            companionAlbumSelected == pet.id and palette.gold or palette.forestLight)
        detailsButton.TextColor3 = palette.white
        detailsButton.TextSize = 8
        detailsButton.Activated:Connect(function()
            companionAlbumSelected = pet.id
            refreshActiveTab()
        end)
    end
    if companionAlbumSelected then
        local selectedPet
        for _, pet in mutationPets do
            if pet.id == companionAlbumSelected then selectedPet = pet break end
        end
        if selectedPet then
            local selectedOwned = player:GetAttribute(selectedPet.id) == true
            local selectedMutation = player:GetAttribute("Companion_" .. selectedPet.id .. "_Mutation")
            local selectedFound = selectedOwned and type(selectedMutation) == "string" and selectedMutation ~= ""
            local detail = card(body, "CompanionAlbumDetail", compactAlbum and 164 or 144)
            detail.BackgroundColor3 = Color3.fromRGB(232, 239, 218)
            local hasHeroPreview = createApprovedCompanionPreview(
                detail, selectedPet.id, "CompanionHeroPreview",
                UDim2.fromOffset(compactAlbum and 88 or 104, compactAlbum and 88 or 104),
                UDim2.fromOffset(12, 12)
            )
            if not hasHeroPreview then
                local portraitPlate = Instance.new("Frame")
                portraitPlate.Name = "PortraitInArtReview"
                portraitPlate.Size = UDim2.fromOffset(72, 72)
                portraitPlate.Position = UDim2.fromOffset(12, 18)
                portraitPlate.BackgroundColor3 = selectedFound and selectedPet.color or palette.paperDark
                portraitPlate.BackgroundTransparency = selectedFound and 0.78 or 0.18
                portraitPlate.BorderSizePixel = 0
                portraitPlate.Parent = detail
                corner(portraitPlate, 20)
                stroke(portraitPlate, selectedFound and selectedPet.color or palette.muted, 0.45, 1)
                createPictogram(portraitPlate, "DetailIcon", selectedFound and selectedPet.icon or "lock",
                    46, selectedFound and selectedPet.color or palette.muted).Position = UDim2.fromOffset(13, 13)
            end
            local textOffset = hasHeroPreview and (compactAlbum and 110 or 128) or 96
            label(detail, "DetailTitle", selectedPet.title,
                UDim2.new(1, -textOffset - 12, 0, 26), UDim2.fromOffset(textOffset, 10), 13, palette.ink, Enum.Font.GothamBlack)
            local detailMutation = selectedFound
                and tostring(player:GetAttribute("Companion_" .. selectedPet.id .. "_MutationName") or "Особая форма")
                or "Форма пока неизвестна"
            local detailMutationLabel = label(detail, "DetailMutation", detailMutation,
                UDim2.new(1, -textOffset - 12, 0, 32), UDim2.fromOffset(textOffset, 39), 11,
                selectedFound and selectedPet.color or palette.muted, Enum.Font.GothamBold)
            detailMutationLabel.TextYAlignment = Enum.TextYAlignment.Top
            detailMutationLabel.TextWrapped = true
            local detailRarity = selectedFound
                and ("Редкость: " .. tostring(player:GetAttribute("Companion_" .. selectedPet.id .. "_MutationRarity") or "Необычная"))
                or ("Где искать: " .. selectedPet.biome)
            local detailHint = label(detail, "DetailHint", detailRarity,
                UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, compactAlbum and 112 or 108), 10, palette.muted)
            detailHint.TextWrapped = true
            detailHint.TextYAlignment = Enum.TextYAlignment.Top
        end
    end
    if #visiblePets == 0 then
        addInfo("НИЧЕГО НЕ НАШЛОСЬ", "Измени запрос или выбери другой фильтр — альбом покажет подходящие записи.", 58)
    end
    local codexClaimed = player:GetAttribute("CompanionCodexRewardClaimed") == true
    local codexComplete = discoveredMutations == #mutationPets
    local codexClaimButton = button(
        body,
        "ClaimCompanionCodex",
        codexClaimed and "НАГРАДА ЗА АЛЬБОМ ПОЛУЧЕНА"
            or (codexComplete and "ЗАБРАТЬ НАГРАДУ • 250 МОНЕТ"
                or "СОБЕРИ 9 ФОРМ • +250 МОНЕТ"),
        UDim2.new(1, 0, 0, 44),
        UDim2.new(),
        codexClaimed and palette.forestLight or (codexComplete and palette.gold or palette.muted)
    )
    codexClaimButton.TextColor3 = codexClaimed and palette.white or palette.ink
    codexClaimButton.TextSize = 12
    codexClaimButton.Active = codexComplete and not codexClaimed
    codexClaimButton.AutoButtonColor = codexClaimButton.Active
    codexClaimButton.Activated:Connect(function()
        if codexComplete and not codexClaimed then
            event:FireServer("ClaimCompanionCodexReward")
        end
    end)
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
    Tools = {"МОЙ РЮКЗАК", "Ресурсы, находки и снаряжение путешественника"},
    World = {"КАРТА МИРА", "Исследуй архипелаг и открывай новые земли"},
    Expeditions = {"ДНЕВНИК", "Ежедневные задания и открытия мира"},
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

refreshActiveTab = function()
    if not panel.Visible or not activeTab or not renderers[activeTab] then return end
    clearBody()
    renderers[activeTab]()
    applyPanelLayer()
end

closeActivePanel = function()
    panel.Visible = false
    modalBackdrop.Visible = false
    activeTab = nil
    for name, navButton in navButtons do
        navButton.BackgroundColor3 = palette.forestLight
        if navLabels[name] then navLabels[name].TextColor3 = palette.white end
        if navIcons[name] then setPictogramColor(navIcons[name], palette.white) end
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
        local selected = name == tabName
        navButton.BackgroundColor3 = selected and palette.gold or palette.forestLight
        if navLabels[name] then navLabels[name].TextColor3 = selected and palette.ink or palette.white end
        if navIcons[name] then setPictogramColor(navIcons[name], selected and palette.ink or palette.white) end
    end
end

navDefinitions = {
    {id = "City", title = "Дом", icon = "house"},
    {id = "Farm", title = "Ферма", icon = "farm"},
    {id = "Pets", title = "Питомцы", icon = "paw"},
    {id = "Tools", title = "Сумка", icon = "backpack"},
    {id = "World", title = "Карта", icon = "map"},
    {id = "Expeditions", title = "Дневник", icon = "journal"},
}

for _, definition in navDefinitions do
    local navButton = button(nav, definition.id, "", UDim2.new(1 / #navDefinitions, -8, 1, -12), UDim2.new(), palette.forestLight)
    navButton.TextTransparency = 1
    navButton.ClipsDescendants = true
    local iconRoot = createPictogram(navButton, "Icon", definition.icon, 24, palette.white)
    iconRoot.Position = UDim2.new(0.5, -12, 0, 4)
    local titleLabel = label(navButton, "Title", definition.title, UDim2.new(1, -4, 0, 18),
        UDim2.new(0, 2, 1, -23), 11, palette.white, Enum.Font.GothamBold)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center

    navButton.Activated:Connect(function()
        openTab(definition.id)
    end)
    navButtons[definition.id] = navButton
    navIcons[definition.id] = iconRoot
    navLabels[definition.id] = titleLabel
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
    woodLabel.Text = tostring(player:GetAttribute("Resource_Wood") or 0)
    stoneLabel.Text = tostring(player:GetAttribute("Resource_Stone") or 0)
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
        objectiveGlyph.Text = completed >= total and "✓" or tostring(completed + 1)
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

local playSymbols = {"1", "2", "3"}
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

updatePlayOverlayLayout()

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
