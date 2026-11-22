-- Giantback visual pass: handcrafted details, warm lighting and bioluminescent accents.
-- All geometry is original and generated from Roblox primitives; no external asset dependency.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local homeIslandTemplate = ServerStorage:WaitForChild("HomeIslandTemplate")
local grove = workspace:WaitForChild("Grove")
local dusk = workspace:WaitForChild("Dusk")

local palette = {
    ink = Color3.fromRGB(42, 62, 58),
    moss = Color3.fromRGB(89, 132, 104),
    mossLight = Color3.fromRGB(128, 166, 125),
    leaf = Color3.fromRGB(113, 164, 111),
    leafLight = Color3.fromRGB(158, 192, 133),
    bark = Color3.fromRGB(111, 79, 60),
    barkLight = Color3.fromRGB(151, 111, 76),
    cream = Color3.fromRGB(250, 229, 187),
    gold = Color3.fromRGB(255, 198, 112),
    coral = Color3.fromRGB(222, 133, 105),
    lilac = Color3.fromRGB(174, 145, 207),
    lilacLight = Color3.fromRGB(216, 191, 237),
    moon = Color3.fromRGB(195, 222, 222),
    water = Color3.fromRGB(76, 157, 164),
    stone = Color3.fromRGB(93, 111, 106),
    stoneLight = Color3.fromRGB(133, 148, 139),
}

local function makeFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then existing:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function makePart(parent, name, size, frame, color, material, shape, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = true
    part.Size = size
    part.CFrame = frame
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.Transparency = transparency or 0
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function orb(parent, name, position, size, color, material, transparency)
    return makePart(parent, name, size, CFrame.new(position), color, material, Enum.PartType.Ball, transparency)
end

local function cylinder(parent, name, position, height, width, color, material, rotation)
    local frame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) * (rotation or CFrame.new())
    return makePart(parent, name, Vector3.new(height, width, width), frame, color, material, Enum.PartType.Cylinder)
end

local function addLight(parent, color, range, brightness)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Shadows = true
    light.Parent = parent
    return light
end

local function addTree(parent, position, scale, leafColor, seed)
    local random = Random.new(seed)
    local height = 7 * scale
    cylinder(parent, "Ancient trunk", position + Vector3.new(0, height / 2, 0), height, 1.25 * scale, palette.bark, Enum.Material.Wood)
    local crownCenter = position + Vector3.new(0, height + 1.5 * scale, 0)
    orb(parent, "Leaf crown", crownCenter, Vector3.new(7, 6, 7) * scale, leafColor, Enum.Material.Grass)
    for i = 1, 4 do
        local angle = (math.pi * 2 * i / 4) + random:NextNumber(-0.25, 0.25)
        local offset = Vector3.new(math.cos(angle) * 2.8, random:NextNumber(-0.3, 1.2), math.sin(angle) * 2.8) * scale
        orb(parent, "Leaf cluster", crownCenter + offset, Vector3.new(4.4, 4.2, 4.4) * scale, i % 2 == 0 and palette.leafLight or leafColor, Enum.Material.Grass)
    end
    orb(parent, "Moss at roots", position + Vector3.new(0, 0.35, 0), Vector3.new(3.4, 0.8, 3.4) * scale, palette.moss, Enum.Material.Grass)
end

local function addFlower(parent, position, petalColor, scale, seed)
    local random = Random.new(seed)
    cylinder(parent, "Flower stem", position + Vector3.new(0, 0.42 * scale, 0), 0.9 * scale, 0.13 * scale, palette.leaf, Enum.Material.Grass)
    local bloom = position + Vector3.new(0, 0.95 * scale, 0)
    for i = 1, 5 do
        local angle = (math.pi * 2 * i / 5) + random:NextNumber(-0.08, 0.08)
        local offset = Vector3.new(math.cos(angle) * 0.42, 0.02, math.sin(angle) * 0.42) * scale
        orb(parent, "Soft petal", bloom + offset, Vector3.new(0.62, 0.25, 0.48) * scale, petalColor, Enum.Material.SmoothPlastic)
    end
    orb(parent, "Flower heart", bloom, Vector3.new(0.3, 0.28, 0.3) * scale, palette.gold, Enum.Material.Neon)
end

local function addMushroom(parent, position, capColor, scale, glow)
    cylinder(parent, "Mushroom stem", position + Vector3.new(0, 0.38 * scale, 0), 0.8 * scale, 0.34 * scale, palette.cream, Enum.Material.SmoothPlastic)
    local cap = orb(parent, "Mushroom cap", position + Vector3.new(0, 0.86 * scale, 0), Vector3.new(1.45, 0.62, 1.45) * scale, capColor, glow and Enum.Material.Neon or Enum.Material.SmoothPlastic)
    if glow then addLight(cap, capColor, 8, 0.55) end
    for i = 1, 3 do
        local angle = i * math.pi * 2 / 3
        orb(parent, "Mushroom speck", position + Vector3.new(math.cos(angle) * 0.36, 1.02 * scale, math.sin(angle) * 0.36), Vector3.new(0.16, 0.09, 0.16) * scale, palette.cream, Enum.Material.Neon)
    end
end

local function addFirefly(parent, position, color, seed)
    local mote = orb(parent, "Wandering light", position, Vector3.new(0.28, 0.28, 0.28), color, Enum.Material.Neon)
    addLight(mote, color, 7, 0.65)
    local random = Random.new(seed)
    local destination = position + Vector3.new(random:NextNumber(-3, 3), random:NextNumber(1, 3), random:NextNumber(-3, 3))
    local tween = TweenService:Create(mote, TweenInfo.new(random:NextNumber(2.5, 4.5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        CFrame = CFrame.new(destination),
    })
    tween:Play()
end

-- Warm, readable lighting with a gentle storybook atmosphere.
Lighting.ClockTime = 15.4
Lighting.Brightness = 2.1
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.42
Lighting.Ambient = Color3.fromRGB(116, 137, 128)
Lighting.OutdoorAmbient = Color3.fromRGB(164, 183, 161)
Lighting.ExposureCompensation = 0.05
Lighting.FogColor = Color3.fromRGB(183, 215, 207)
Lighting.FogStart = 180
Lighting.FogEnd = 620
pcall(function() Lighting.Technology = Enum.Technology.Future end)

local atmosphere = Lighting:FindFirstChild("GiantbackAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "GiantbackAtmosphere"
atmosphere.Density = 0.24
atmosphere.Offset = 0.12
atmosphere.Color = Color3.fromRGB(199, 226, 211)
atmosphere.Decay = Color3.fromRGB(255, 194, 143)
atmosphere.Glare = 0.22
atmosphere.Haze = 1.1
atmosphere.Parent = Lighting

local bloom = Lighting:FindFirstChild("GiantbackBloom") or Instance.new("BloomEffect")
bloom.Name = "GiantbackBloom"
bloom.Intensity = 0.22
bloom.Size = 28
bloom.Threshold = 1.15
bloom.Parent = Lighting

local grade = Lighting:FindFirstChild("GiantbackColor") or Instance.new("ColorCorrectionEffect")
grade.Name = "GiantbackColor"
grade.Brightness = 0.025
grade.Contrast = 0.07
grade.Saturation = 0.1
grade.TintColor = Color3.fromRGB(255, 244, 225)
grade.Parent = Lighting

local rays = Lighting:FindFirstChild("GiantbackSunRays") or Instance.new("SunRaysEffect")
rays.Name = "GiantbackSunRays"
rays.Intensity = 0.055
rays.Spread = 0.78
rays.Parent = Lighting

local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
    terrain.WaterColor = palette.water
    terrain.WaterTransparency = 0.24
    terrain.WaterReflectance = 0.16
    terrain.WaterWaveSize = 0.18
    terrain.WaterWaveSpeed = 9
    local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
    clouds.Cover = 0.34
    clouds.Density = 0.38
    clouds.Color = Color3.fromRGB(244, 239, 219)
    clouds.Parent = terrain
end

-- Give the prototype geometry consistent materials and remove collision from foliage.
local visualParts = homeIslandTemplate:GetDescendants()
for _, item in workspace:GetDescendants() do
    table.insert(visualParts, item)
end
for _, item in visualParts do
    if item:IsA("BasePart") then
        if item.Name == "Meadow" then
            item.Material = Enum.Material.Grass
        elseif item.Name == "Shell" or item.Name == "Head" or item.Name == "Flipper" then
            item.Material = Enum.Material.SmoothPlastic
        elseif item.Name == "Cottage" then
            item.Material = Enum.Material.WoodPlanks
        elseif item.Name == "Roof" then
            item.Material = Enum.Material.Slate
        elseif item.Name == "Bank" then
            item.Material = Enum.Material.Grass
        elseif item.Name == "Trunk" then
            item.Material = Enum.Material.Wood
            item.CanCollide = false
        elseif item.Name == "Crown" then
            item.Material = Enum.Material.Grass
            item.CanCollide = false
        elseif item.Name == "Bloom" then
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
        elseif item.Name == "BridgeDeck" or item.Name == "BridgeRail" or item.Name == "BridgePost" then
            item.Material = Enum.Material.WoodPlanks
        elseif item.Name == "BridgeLamp" then
            item.Material = Enum.Material.Metal
            addLight(item, palette.gold, 12, 0.7)
        elseif item.Name == "Trail" then
            item.Material = Enum.Material.Sand
        elseif item.Name == "WoodPile" then
            item.Material = Enum.Material.WoodPlanks
        elseif item.Name == "StonePile" then
            item.Material = Enum.Material.Rock
        elseif item.Name == "Nest" or item.Name == "Driftwood" or item.Name == "Gangway" or item.Name == "Planter" then
            item.Material = Enum.Material.WoodPlanks
        elseif item.Name == "Glint" or item.Name == "Window" then
            item.Material = Enum.Material.Neon
        end
    end
end

local lagoon = workspace:FindFirstChild("Lagoon")
if lagoon and lagoon:IsA("BasePart") then
    lagoon.Material = Enum.Material.Glass
    lagoon.Color = palette.water
    lagoon.Transparency = 0.2
    lagoon.Reflectance = 0.12
end

local details = makeFolder(workspace, "GiantbackWorldDetails")

-- Give the homeIslandTemplate a recognisable silhouette and a lived-in home.
local homeDetails = makeFolder(homeIslandTemplate, "HandcraftedDetails")
local shellColors = {
    Color3.fromRGB(104, 151, 117),
    Color3.fromRGB(119, 163, 127),
    Color3.fromRGB(91, 139, 111),
    Color3.fromRGB(139, 174, 129),
}
local shellPlates = {
    Vector3.new(-12, 12.35, -8), Vector3.new(0, 12.65, -9), Vector3.new(12, 12.35, -8),
    Vector3.new(-12, 12.35, 5), Vector3.new(0, 12.65, 5), Vector3.new(12, 12.35, 5),
}
for i, position in shellPlates do
    orb(homeDetails, "Shell mosaic", position, Vector3.new(8.2, 1.15, 8.1), shellColors[(i - 1) % #shellColors + 1], Enum.Material.Grass)
end
for i = 1, 12 do
    local angle = (math.pi * 2 * i / 12)
    local position = Vector3.new(math.cos(angle) * 17.5, 6.1, math.sin(angle) * 14)
    orb(homeDetails, "Shell moss", position, Vector3.new(3.2, 1.2, 3.2), i % 2 == 0 and palette.mossLight or palette.moss, Enum.Material.Grass)
end
orb(homeDetails, "Mossback tail", Vector3.new(-22, 3.8, 0), Vector3.new(7, 4, 5), palette.moss, Enum.Material.SmoothPlastic)
orb(homeDetails, "Mossback snout", Vector3.new(27, 6.4, 0), Vector3.new(5.2, 3.8, 6.8), palette.mossLight, Enum.Material.SmoothPlastic)
orb(homeDetails, "Nose", Vector3.new(29.5, 7.1, 0), Vector3.new(1.05, 0.8, 1.8), palette.ink, Enum.Material.SmoothPlastic)

-- Harvestable materials are clearly readable on every personal island.
local woodPile = homeIslandTemplate:FindFirstChild("WoodPile")
if woodPile then
    woodPile.Transparency = 1
    for i = 1, 3 do
        local log = cylinder(
            homeDetails,
            "Gatherable timber",
            Vector3.new(12, 13.0 + (i % 2) * 0.42, -8 + (i - 2) * 0.55),
            3.2,
            0.68,
            i % 2 == 0 and palette.barkLight or palette.bark,
            Enum.Material.Wood
        )
        log.CFrame = CFrame.new(log.Position) * CFrame.Angles(0, math.rad(i * 34), 0)
    end
end
local stonePile = homeIslandTemplate:FindFirstChild("StonePile")
if stonePile then
    stonePile.Transparency = 1
    orb(homeDetails, "Gatherable stone", Vector3.new(11.1, 13.05, 7.8), Vector3.new(1.35, 1.05, 1.25), palette.stone, Enum.Material.Rock)
    orb(homeDetails, "Gatherable stone", Vector3.new(12.6, 13.0, 8.3), Vector3.new(1.1, 0.9, 1.0), palette.stoneLight, Enum.Material.Rock)
    orb(homeDetails, "Gatherable stone", Vector3.new(12.0, 13.65, 7.7), Vector3.new(0.9, 0.8, 0.9), palette.stone, Enum.Material.Rock)
end
for _, side in {-1, 1} do
    orb(homeDetails, "Cheek", Vector3.new(25.2, 5.7, side * 5.4), Vector3.new(2.3, 1.4, 1.2), Color3.fromRGB(151, 190, 143), Enum.Material.SmoothPlastic)
    orb(homeDetails, "Flipper toe", Vector3.new(13, -0.8, side * 14), Vector3.new(3.2, 1.7, 2.2), palette.mossLight, Enum.Material.SmoothPlastic)
end

-- Cottage details: door, shutters, porch, chimney and warm windows.
local cottage = makeFolder(homeDetails, "CottageDetails")
makePart(cottage, "Front door", Vector3.new(1.8, 4.2, 0.3), CFrame.new(-12.2, 14.2, -2.25), Color3.fromRGB(121, 83, 63), Enum.Material.WoodPlanks)
makePart(cottage, "Door inset", Vector3.new(1.1, 2.6, 0.12), CFrame.new(-12.2, 14.2, -2.08), Color3.fromRGB(153, 108, 75), Enum.Material.Wood)
orb(cottage, "Door handle", Vector3.new(-11.55, 14.2, -1.98), Vector3.new(0.22, 0.22, 0.22), palette.gold, Enum.Material.Metal)
for _, x in {-10.9, -7.1} do
    makePart(cottage, "Window shutter", Vector3.new(0.8, 2.8, 0.3), CFrame.new(x, 15.1, -2.38), palette.coral, Enum.Material.WoodPlanks)
    makePart(cottage, "Shutter hinge", Vector3.new(0.12, 2.8, 0.12), CFrame.new(x, 15.1, -2.2), palette.bark, Enum.Material.Wood)
end
makePart(cottage, "Porch step", Vector3.new(4.8, 0.45, 1.6), CFrame.new(-12.2, 12.45, -1.1), palette.barkLight, Enum.Material.WoodPlanks)
for _, x in {-14.1, -10.3} do
    cylinder(cottage, "Porch post", Vector3.new(x, 14, -0.8), 3.2, 0.35, palette.barkLight, Enum.Material.Wood)
    orb(cottage, "Porch post cap", Vector3.new(x, 15.7, -0.8), Vector3.new(0.6, 0.35, 0.6), palette.gold, Enum.Material.Wood)
end
makePart(cottage, "Chimney", Vector3.new(2, 4.8, 2), CFrame.new(-5.6, 21, -8.2), Color3.fromRGB(166, 104, 83), Enum.Material.Brick)
makePart(cottage, "Chimney cap", Vector3.new(2.5, 0.35, 2.5), CFrame.new(-5.6, 23.45, -8.2), palette.cream, Enum.Material.Slate)
local windowGlow = orb(cottage, "Window glow", Vector3.new(-9, 15, -2.25), Vector3.new(1.9, 1.4, 0.12), palette.gold, Enum.Material.Neon, 0.12)
addLight(windowGlow, palette.gold, 9, 0.65)

-- A clear, welcoming deck with small details that make the home feel inhabited.
local deck = makeFolder(homeDetails, "DeckDetails")
for i = -2, 2 do
    local z = i * 4.6
    makePart(deck, "Garden stepping stone", Vector3.new(2.6, 0.18, 2.2), CFrame.new(3, 12.08, z), Color3.fromRGB(191, 183, 145), Enum.Material.Slate)
end
for _, side in {-1, 1} do
    for i = -1, 0, 1 do
        local x = side * 15.7
        local z = i * 8
        makePart(deck, "Deck rail post", Vector3.new(0.55, 2.3, 0.55), CFrame.new(x, 13.1, z), palette.barkLight, Enum.Material.Wood)
        orb(deck, "Rail post cap", Vector3.new(x, 14.35, z), Vector3.new(0.8, 0.55, 0.8), palette.gold, Enum.Material.Wood)
    end
    makePart(deck, "Deck rail", Vector3.new(0.35, 0.35, 18), CFrame.new(side * 15.7, 13.8, 0), palette.barkLight, Enum.Material.Wood)
end
for i = 1, 5 do
    local angle = i * math.pi * 2 / 5
    local pos = Vector3.new(-8 + math.cos(angle) * 3.2, 13.15, 5 + math.sin(angle) * 2.2)
    addFlower(deck, pos, i % 2 == 0 and palette.coral or palette.lilacLight, 0.72, 100 + i)
end
local deckLantern = orb(deck, "Porch lantern glass", Vector3.new(4.5, 15, -5), Vector3.new(0.8, 1.2, 0.8), palette.gold, Enum.Material.Neon)
addLight(deckLantern, palette.gold, 13, 0.8)

-- A readable garden path and a small enchanted arch guide new players to their first crops.
local gardenApproach = makeFolder(homeDetails, "GardenApproach")
local pathStones = {
    Vector3.new(-12.2, 12.12, -0.1),
    Vector3.new(-12.0, 12.12, 1.9),
    Vector3.new(-12.35, 12.12, 3.9),
    Vector3.new(-12.1, 12.12, 5.9),
    Vector3.new(-12.2, 12.12, 7.9),
}
for index, position in pathStones do
    local stone = orb(
        gardenApproach,
        "Garden path stone",
        position,
        Vector3.new(1.55 + (index % 2) * 0.18, 0.22, 1.25),
        index % 2 == 0 and palette.stoneLight or Color3.fromRGB(190, 181, 151),
        Enum.Material.Slate
    )
    stone.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad((index % 2 == 0 and 8 or -9)), 0)
end

local archLeft = Vector3.new(-16.7, 12.15, 6.2)
local archRight = Vector3.new(-7.7, 12.15, 6.2)
for index, position in {archLeft, archRight} do
    cylinder(
        gardenApproach,
        "Garden arch post",
        position + Vector3.new(0, 1.75, 0),
        3.5,
        0.42,
        palette.barkLight,
        Enum.Material.Wood
    )
    orb(
        gardenApproach,
        "Garden arch cap",
        position + Vector3.new(0, 3.55, 0),
        Vector3.new(0.82, 0.48, 0.82),
        palette.gold,
        Enum.Material.Wood
    )
    for leafIndex = 1, 3 do
        local side = index == 1 and 1 or -1
        orb(
            gardenApproach,
            "Arch climbing leaf",
            position + Vector3.new(side * (0.22 + leafIndex * 0.12), 0.7 + leafIndex * 0.72, 0.22),
            Vector3.new(0.72, 0.36, 0.48),
            leafIndex % 2 == 0 and palette.leafLight or palette.leaf,
            Enum.Material.Grass
        )
    end
end
makePart(
    gardenApproach,
    "Garden arch lintel",
    Vector3.new(9.5, 0.48, 0.55),
    CFrame.new(-12.2, 15.85, 6.2),
    palette.barkLight,
    Enum.Material.Wood
)
local archMoon = orb(
    gardenApproach,
    "Garden arch moon charm",
    Vector3.new(-12.2, 16.55, 6.2),
    Vector3.new(0.82, 0.82, 0.42),
    palette.gold,
    Enum.Material.Neon
)
addLight(archMoon, palette.gold, 7, 0.28)
for index = 1, 4 do
    local x = -15.2 + index * 2
    addFlower(
        gardenApproach,
        Vector3.new(x, 12.12, 7.1 + (index % 2) * 0.45),
        index % 2 == 0 and palette.lilacLight or palette.coral,
        0.58,
        180 + index
    )
end

-- A dedicated, readable rest nook gives collected companions a visible home.
local petSanctuary = makeFolder(homeDetails, "PetSanctuary")
local sanctuaryCenter = Vector3.new(-23, 12.16, -8.5)
orb(
    petSanctuary,
    "Companion sanctuary moss pad",
    sanctuaryCenter,
    Vector3.new(9.4, 0.34, 8.2),
    Color3.fromRGB(115, 151, 119),
    Enum.Material.Grass
)
cylinder(
    petSanctuary,
    "Companion sanctuary stone dais",
    sanctuaryCenter + Vector3.new(0, 0.12, 0),
    0.24,
    6.8,
    Color3.fromRGB(167, 157, 132),
    Enum.Material.Slate
)
local restSpots = {
    {position = Vector3.new(-25.1, 12.48, -8.5), color = palette.lilacLight},
    {position = Vector3.new(-20.9, 12.48, -8.5), color = palette.coral},
    {position = Vector3.new(-23.0, 12.48, -6.1), color = palette.cream},
}
for index, spot in restSpots do
    cylinder(
        petSanctuary,
        "Companion resting cushion base",
        spot.position,
        0.22,
        1.85,
        palette.barkLight,
        Enum.Material.Wood
    )
    orb(
        petSanctuary,
        "Companion resting cushion",
        spot.position + Vector3.new(0, 0.18, 0),
        Vector3.new(1.9, 0.34, 1.55),
        spot.color,
        Enum.Material.Fabric
    )
end
local sanctuaryLantern = orb(
    petSanctuary,
    "Sanctuary moon lantern",
    sanctuaryCenter + Vector3.new(0, 1.0, 1.65),
    Vector3.new(0.62, 0.86, 0.62),
    palette.moon,
    Enum.Material.Neon
)
addLight(sanctuaryLantern, palette.moon, 10, 0.48)
for index = 1, 7 do
    local angle = math.pi * 2 * index / 7
    local position = sanctuaryCenter + Vector3.new(math.cos(angle) * 4.3, 0.18, math.sin(angle) * 3.7)
    orb(
        petSanctuary,
        "Sanctuary border pebble",
        position,
        Vector3.new(0.78, 0.3, 0.72),
        index % 2 == 0 and palette.stoneLight or palette.stone,
        Enum.Material.Slate
    )
end
for index = 1, 4 do
    local x = -17.1 - index * 1.55
    local stone = orb(
        petSanctuary,
        "Companion nook stepping stone",
        Vector3.new(x, 12.18, -8.5 + (index % 2) * 0.35),
        Vector3.new(1.2, 0.2, 1.0),
        index % 2 == 0 and palette.stoneLight or Color3.fromRGB(190, 181, 151),
        Enum.Material.Slate
    )
    stone.CFrame = CFrame.new(stone.Position) * CFrame.Angles(0, math.rad(index % 2 == 0 and 7 or -8), 0)
end
for index = 1, 5 do
    local angle = math.pi * 2 * index / 5
    addFlower(
        petSanctuary,
        sanctuaryCenter + Vector3.new(math.cos(angle) * 5.0, 0.16, math.sin(angle) * 4.3),
        index % 2 == 0 and palette.lilacLight or palette.coral,
        0.52,
        900 + index
    )
end

-- A small home-island canopy creates a layered silhouette without crowding
-- the cottage, four farm plots, resource piles or companion sanctuary.
local homeCanopy = makeFolder(homeDetails, "HomeCanopy")
local homeTreeSites = {
    {position = Vector3.new(-28.0, 12.0, 15.5), scale = 0.86, color = Color3.fromRGB(119, 164, 112), seed = 1201},
    {position = Vector3.new(1.5, 12.0, -23.0), scale = 0.92, color = Color3.fromRGB(145, 181, 126), seed = 1202},
    {position = Vector3.new(22.0, 12.0, -16.5), scale = 0.78, color = Color3.fromRGB(105, 151, 110), seed = 1203},
}
for _, treeSite in homeTreeSites do
    addTree(homeCanopy, treeSite.position, treeSite.scale, treeSite.color, treeSite.seed)
    local crownTop = treeSite.position + Vector3.new(0, 9.2 * treeSite.scale, 0)
    for berryIndex = 1, 3 do
        local angle = berryIndex * math.pi * 2 / 3
        local berry = orb(
            homeCanopy,
            "Canopy glow berry",
            crownTop + Vector3.new(math.cos(angle) * 2.0 * treeSite.scale, -0.7, math.sin(angle) * 2.0 * treeSite.scale),
            Vector3.new(0.34, 0.42, 0.34) * treeSite.scale,
            berryIndex == 2 and palette.gold or palette.coral,
            Enum.Material.Neon
        )
        if berryIndex == 2 then addLight(berry, palette.gold, 5, 0.16) end
    end
end

-- Low shrubs and flower pockets soften the paths while leaving the farm readable.
local homeGardenPockets = {
    {center = Vector3.new(-24.0, 12.12, 15.0), color = palette.lilacLight, seed = 1301},
    {center = Vector3.new(7.0, 12.12, -20.0), color = palette.coral, seed = 1302},
    {center = Vector3.new(20.0, 12.12, -8.0), color = palette.gold, seed = 1303},
    {center = Vector3.new(4.0, 12.12, 21.0), color = palette.lilac, seed = 1304},
}
for _, pocket in homeGardenPockets do
    for shrubIndex = 1, 2 do
        local offset = Vector3.new((shrubIndex - 1.5) * 1.25, 0.32, (shrubIndex % 2 == 0 and 0.45 or -0.45))
        orb(
            homeCanopy,
            "Rounded berry shrub",
            pocket.center + offset,
            Vector3.new(1.55, 0.95, 1.35),
            shrubIndex == 1 and palette.mossLight or palette.leaf,
            Enum.Material.Grass
        )
    end
    addFlower(homeCanopy, pocket.center + Vector3.new(0, 0.12, 1.35), pocket.color, 0.54, pocket.seed)
end

-- Small mushroom groups add a second scale of detail beneath the trees.
local homeMushroomSites = {
    Vector3.new(-25.2, 12.12, 19.0),
    Vector3.new(5.5, 12.12, -26.0),
    Vector3.new(24.0, 12.12, -20.0),
}
for index, position in homeMushroomSites do
    addMushroom(
        homeCanopy,
        position,
        index == 2 and palette.lilac or palette.coral,
        0.58 + (index % 2) * 0.12,
        index == 2
    )
end

-- Turn the two simple banks into distinct little places.
local function decorateIsland(island, isDusk)
    local islandDetails = makeFolder(island, "HandcraftedDetails")
    local bank = island:WaitForChild("Bank")
    local centerX, centerZ = bank.Position.X, bank.Position.Z
    local groundColor = isDusk and Color3.fromRGB(154, 143, 177) or Color3.fromRGB(143, 181, 126)
    makePart(
        islandDetails,
        "Soft ground cover",
        Vector3.new(bank.Size.X - 3, 0.18, bank.Size.Z - 3),
        CFrame.new(centerX, bank.Position.Y + bank.Size.Y / 2 + 0.12, centerZ),
        groundColor,
        Enum.Material.Grass
    )

    -- A ring of rock shelves gives both shared islands a soft, organic coastline.
    for i = 1, 12 do
        local angle = i * math.pi * 2 / 12
        local x = centerX + math.cos(angle) * bank.Size.X * 0.43
        local z = centerZ + math.sin(angle) * bank.Size.Z * 0.43
        orb(
            islandDetails,
            "Weathered cliff rock",
            Vector3.new(x, 4.1, z),
            Vector3.new(7, 5.5, 6),
            isDusk and Color3.fromRGB(104, 97, 132) or palette.stone,
            Enum.Material.Rock
        )
    end

    -- Extra foliage makes the existing trees read as a canopy rather than single spheres.
    for _, item in island:GetChildren() do
        if item:IsA("BasePart") and item.Name == "Crown" then
            for i = 1, 4 do
                local angle = i * math.pi * 2 / 4
                local offset = Vector3.new(math.cos(angle) * 2.4, -0.35, math.sin(angle) * 2.4)
                local color = isDusk and (i % 2 == 0 and palette.lilac or palette.lilacLight) or (i % 2 == 0 and palette.leaf or palette.leafLight)
                orb(islandDetails, "Canopy cluster", item.Position + offset, Vector3.new(4.6, 4.1, 4.6), color, Enum.Material.Grass)
            end
        elseif item:IsA("BasePart") and item.Name == "Bloom" then
            addFlower(islandDetails, item.Position, isDusk and palette.lilacLight or palette.coral, 0.56, math.abs(math.floor(item.Position.X * 10 + item.Position.Z * 10)) + 1)
            item.Transparency = 1
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
        end
    end

    -- Stone pavers lead from the home-bridge landing into the shared biome.
    for i = 1, 9 do
        local z = centerZ + 9 - i * 2.8
        local x = centerX + math.sin(i * 0.8) * 1.6
        local stone = orb(islandDetails, "Trail paver", Vector3.new(x, bank.Position.Y + bank.Size.Y / 2 + 0.28, z), Vector3.new(2.3, 0.22, 1.7), Color3.fromRGB(205, 193, 157), Enum.Material.Slate)
        stone.Shape = Enum.PartType.Block
        stone.CFrame = CFrame.new(x, bank.Position.Y + bank.Size.Y / 2 + 0.28, z) * CFrame.Angles(0, math.rad(i * 9), 0)
    end

    local treeCount = isDusk and 6 or 14
    for i = 1, treeCount do
        local angle = i * math.pi * 2 / treeCount
        local x = centerX + math.cos(angle) * bank.Size.X * 0.31
        local z = centerZ + math.sin(angle) * bank.Size.Z * 0.31
        local position = Vector3.new(x, bank.Position.Y + bank.Size.Y / 2 + 0.2, z)
        local leaves = isDusk and (i % 2 == 0 and palette.lilac or palette.lilacLight) or (i % 2 == 0 and palette.leaf or palette.leafLight)
        addTree(islandDetails, position, isDusk and 0.72 or 0.82, leaves, 400 + i + (isDusk and 20 or 0))
    end

    for i = 1, 18 do
        local angle = i * 2.399
        local radius = isDusk and 18 or 54
        local x = centerX + math.cos(angle) * radius
        local z = centerZ + math.sin(angle) * radius
        local color = isDusk and (i % 2 == 0 and palette.lilacLight or palette.moon) or (i % 2 == 0 and palette.gold or palette.coral)
        addFlower(islandDetails, Vector3.new(x, bank.Position.Y + bank.Size.Y / 2 + 0.22, z), color, 0.48 + (i % 3) * 0.08, 700 + i)
    end

    if isDusk then
        for i = 1, 7 do
            local angle = i * 1.4
            local x = centerX + math.cos(angle) * 17
            local z = centerZ + math.sin(angle) * 17
            addMushroom(islandDetails, Vector3.new(x, bank.Position.Y + bank.Size.Y / 2 + 0.2, z), i % 2 == 0 and palette.lilac or palette.moon, 0.8 + (i % 2) * 0.18, true)
        end
        for i = 1, 5 do
            local x = centerX + (i - 3) * 5
            local crystal = makePart(islandDetails, "Moon crystal", Vector3.new(0.7, 3.1 + (i % 2), 0.7), CFrame.new(x, 13.2, centerZ - 15 + (i % 2) * 2) * CFrame.Angles(0, 0, math.rad((i % 2 == 0 and 10 or -12))), palette.lilacLight, Enum.Material.Neon)
            addLight(crystal, palette.lilacLight, 10, 0.5)
        end
        for i = 1, 8 do
            addFirefly(islandDetails, Vector3.new(centerX + math.sin(i * 1.8) * 15, 14 + (i % 3), centerZ + 6 - i * 2.4), palette.gold, 900 + i)
        end
    else
        for i = 1, 5 do
            addMushroom(islandDetails, Vector3.new(centerX + (i - 3) * 5.2, bank.Position.Y + bank.Size.Y / 2 + 0.2, centerZ - 11 + (i % 2) * 3), palette.coral, 0.72, false)
        end
        for i = 1, 5 do
            local x = centerX + (i - 3) * 5
            cylinder(islandDetails, "Wayfinder bell", Vector3.new(x, 12.8, centerZ + 13), 2.2, 0.35, palette.gold, Enum.Material.Metal)
            orb(islandDetails, "Bell clapper", Vector3.new(x, 11.6, centerZ + 13), Vector3.new(0.65, 0.65, 0.65), palette.coral, Enum.Material.Metal)
        end
    end
end

decorateIsland(grove, false)
decorateIsland(dusk, true)

-- Camouflaged caches are always part of the forest; only the owner's Fox Scout
-- highlight and local prompt reveal which one currently contains a find.
local foxCacheVisuals = makeFolder(grove, "FoxCacheVisuals")
local foxCacheAnchors = {"FoxCache01", "FoxCache02", "FoxCache03"}
for index, cacheId in foxCacheAnchors do
    local anchor = grove:FindFirstChild(cacheId)
    if anchor then
        local visual = Instance.new("Model")
        visual.Name = "FoxCacheVisual" .. string.format("%02d", index)
        visual.Parent = foxCacheVisuals

        orb(visual, "Mossy cache mound", anchor.Position + Vector3.new(0, 0.22, 0), Vector3.new(2.8, 0.62, 2.5), palette.moss, Enum.Material.Grass)
        orb(visual, "Leaf cover", anchor.Position + Vector3.new(0.48, 0.52, 0.22), Vector3.new(1.65, 0.28, 0.95), palette.leafLight, Enum.Material.Grass)
        orb(visual, "Stone cover", anchor.Position + Vector3.new(-0.62, 0.32, -0.28), Vector3.new(0.92, 0.58, 0.84), palette.stone, Enum.Material.Rock)
        orb(visual, "Buried glimmer", anchor.Position + Vector3.new(0, 0.62, 0), Vector3.new(0.16, 0.16, 0.16), palette.gold, Enum.Material.Neon, 0.78)
    end
end

-- The Moon Moth reveals this hidden flower locally; its light and prompt are
-- enabled only for players who have equipped the Moth or already awakened it.
local moonBloomVisuals = makeFolder(dusk, "MoonBloomVisuals")
local moonBloomAnchor = dusk:FindFirstChild("MoonBloom")
if moonBloomAnchor and moonBloomAnchor:IsA("BasePart") then
    local moonBloom = Instance.new("Model")
    moonBloom.Name = "MoonBloomVisual"
    moonBloom.Parent = moonBloomVisuals

    local position = moonBloomAnchor.Position
    for index = 1, 4 do
        local angle = index * math.pi / 2
        orb(
            moonBloom,
            "Moonstone",
            position + Vector3.new(math.cos(angle) * 1.35, 0.22, math.sin(angle) * 1.35),
            Vector3.new(0.72, 0.52, 0.68),
            palette.stone,
            Enum.Material.Rock
        )
    end
    cylinder(moonBloom, "Moon bloom stem", position + Vector3.new(0, 0.48, 0), 0.95, 0.12, palette.leaf, Enum.Material.Grass)
    for index = 1, 6 do
        local angle = (index - 1) * math.pi / 3
        orb(
            moonBloom,
            "Moon petal",
            position + Vector3.new(math.cos(angle) * 0.56, 1.12, math.sin(angle) * 0.56),
            Vector3.new(0.72, 0.28, 0.48),
            palette.lilacLight,
            Enum.Material.Neon
        )
    end
    orb(moonBloom, "Moon leaves", position + Vector3.new(0, 0.55, 0.38), Vector3.new(0.9, 0.2, 0.5), palette.leafLight, Enum.Material.Grass)
    local heart = orb(moonBloom, "Moon heart", position + Vector3.new(0, 1.2, 0), Vector3.new(0.34, 0.34, 0.34), palette.cream, Enum.Material.Neon)
    local moonLight = addLight(heart, palette.lilacLight, 13, 0.85)
    moonLight.Enabled = false
    for index = 1, 3 do
        local angle = index * math.pi * 2 / 3
        orb(
            moonBloom,
            "Moon mote",
            position + Vector3.new(math.cos(angle) * 1.05, 1.55 + index * 0.12, math.sin(angle) * 1.05),
            Vector3.new(0.13, 0.13, 0.13),
            palette.gold,
            Enum.Material.Neon,
            0.28
        )
    end
end

-- The first joint expedition: the Fox finds an ancient trail, then the Moth
-- lights the runes to reveal a personal moonlit clearing and its rare relic.
local moonGateVisuals = makeFolder(dusk, "MoonGateVisuals")
local bank = dusk:FindFirstChild("Bank")
local gateTracks = dusk:FindFirstChild("MoonGateTracks")
local gateRune = dusk:FindFirstChild("MoonGateRune")
local relicAnchor = dusk:FindFirstChild("MoonRelic")
if bank and gateTracks and gateRune and relicAnchor then
    local groundY = bank.Position.Y + bank.Size.Y / 2 + 0.13
    local gatePosition = Vector3.new(gateRune.Position.X, groundY, gateRune.Position.Z - 2.2)

    local tracks = Instance.new("Model")
    tracks.Name = "MoonGateTracksVisual"
    tracks.Parent = moonGateVisuals
    local trackStart = Vector3.new(gateTracks.Position.X, groundY, gateTracks.Position.Z)
    local trackFinish = gatePosition + Vector3.new(0, 0, 3)
    for index = 1, 7 do
        local alpha = index / 8
        local position = trackStart:Lerp(trackFinish, alpha)
        local direction = (trackFinish - trackStart).Unit
        local side = index % 2 == 0 and 1 or -1
        local sideVector = Vector3.new(-direction.Z, 0, direction.X)
        local frame = CFrame.lookAt(position + sideVector * (0.28 * side), position + sideVector * (0.28 * side) + direction)
        makePart(tracks, "Fox paw pad", Vector3.new(0.34, 0.07, 0.28), frame * CFrame.new(0, 0.04, 0.08), palette.gold, Enum.Material.Neon, Enum.PartType.Ball, 0.18)
        for toeIndex = 1, 3 do
            local toeX = (toeIndex - 2) * 0.14
            makePart(tracks, "Fox paw toe", Vector3.new(0.12, 0.06, 0.12), frame * CFrame.new(toeX, 0.045, -0.13), palette.gold, Enum.Material.Neon, Enum.PartType.Ball, 0.22)
        end
    end
    for index = 1, 3 do
        local alpha = index / 4
        local motePosition = trackStart:Lerp(trackFinish, alpha) + Vector3.new(0, 0.8 + (index % 2) * 0.15, 0)
        local mote = orb(tracks, "Scent mote", motePosition, Vector3.new(0.16, 0.16, 0.16), palette.gold, Enum.Material.Neon, 0.2)
        addLight(mote, palette.gold, 4, 0.22)
    end

    local gateShell = Instance.new("Model")
    gateShell.Name = "MoonGateShell"
    gateShell.Parent = moonGateVisuals
    for side = -1, 1, 2 do
        local pillarPosition = gatePosition + Vector3.new(side * 4.1, 2.7, 0)
        orb(gateShell, "Ancient gate stone", pillarPosition, Vector3.new(2.15, 5.8, 2.2), palette.stone, Enum.Material.Rock)
        orb(gateShell, "Moss on gate stone", pillarPosition + Vector3.new(-side * 0.2, 1.35, -0.45), Vector3.new(1.8, 0.7, 1.5), palette.moss, Enum.Material.Grass)
        for rootIndex = 1, 3 do
            local rootOffset = Vector3.new(side * (0.6 + rootIndex * 0.25), 1.3 - rootIndex * 0.8, 0.82)
            local root = orb(gateShell, "Old tree root", pillarPosition + rootOffset, Vector3.new(0.42, 2.1, 0.48), palette.bark, Enum.Material.Wood)
            root.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(side * (18 + rootIndex * 12)))
        end
    end
    orb(gateShell, "Ancient gate crown", gatePosition + Vector3.new(0, 5.9, 0), Vector3.new(10.4, 1.7, 2.35), palette.stone, Enum.Material.Rock)
    for index = 1, 5 do
        local x = -3.4 + (index - 1) * 1.7
        orb(gateShell, "Crown moss", gatePosition + Vector3.new(x, 6.65, -0.25), Vector3.new(1.5, 0.42, 1.3), palette.mossLight, Enum.Material.Grass)
    end
    for index = 1, 4 do
        local step = makePart(
            gateShell,
            "Worn moonstone step",
            Vector3.new(2.5, 0.28, 1.25),
            CFrame.new(gatePosition + Vector3.new(0, 0.16, 2.2 + index * 1.05)) * CFrame.Angles(0, math.rad((index % 2 == 0 and 1 or -1) * 4), 0),
            palette.stone,
            Enum.Material.Slate
        )
    end

    local seal = Instance.new("Model")
    seal.Name = "MoonGateSeal"
    seal.Parent = moonGateVisuals
    orb(seal, "Sealed stone", gatePosition + Vector3.new(0, 2.55, -0.05), Vector3.new(6.7, 5.1, 1.25), Color3.fromRGB(79, 84, 103), Enum.Material.Rock)
    for index = 1, 3 do
        local rune = makePart(
            seal,
            "Dormant seal rune",
            Vector3.new(0.18, 1.35, 0.12),
            CFrame.new(gatePosition + Vector3.new((index - 2) * 1.55, 3.0, -0.7)) * CFrame.Angles(0, 0, math.rad(18 * (index - 2))),
            palette.lilac,
            Enum.Material.Neon
        )
        addLight(rune, palette.lilac, 5, 0.12)
    end

    local runes = Instance.new("Model")
    runes.Name = "MoonGateRunesVisual"
    runes.Parent = moonGateVisuals
    local runeStone = orb(runes, "Moon rune stone", gateRune.Position + Vector3.new(0, 0.8, 0), Vector3.new(2.5, 2.0, 1.0), palette.stone, Enum.Material.Rock)
    runeStone.CFrame = CFrame.new(runeStone.Position) * CFrame.Angles(0, math.rad(12), math.rad(-8))
    for index = 1, 3 do
        local x = (index - 2) * 0.62
        local rune = makePart(
            runes,
            "Awakening rune",
            Vector3.new(0.18, 0.95, 0.14),
            CFrame.new(gateRune.Position + Vector3.new(x, 1.05, -0.58)) * CFrame.Angles(0, 0, math.rad((index - 2) * 18)),
            palette.lilacLight,
            Enum.Material.Neon
        )
        addLight(rune, palette.lilacLight, 7, 0.32)
    end

    local clearing = Instance.new("Model")
    clearing.Name = "MoonGateClearingVisual"
    clearing.Parent = moonGateVisuals
    local relicBase = Vector3.new(relicAnchor.Position.X, groundY, relicAnchor.Position.Z)
    local relicPosition = relicBase + Vector3.new(0, 1.9, 0)
    for index = 1, 8 do
        local angle = index * math.pi / 4
        local stonePosition = relicBase + Vector3.new(math.cos(angle) * 5.0, 0.18, math.sin(angle) * 4.2)
        orb(clearing, "Clearing moonstone", stonePosition, Vector3.new(1.15, 0.48, 1.0), palette.stone, Enum.Material.Rock)
        local flowerPosition = relicBase + Vector3.new(math.cos(angle) * 3.3, 0.25, math.sin(angle) * 2.8)
        addFlower(clearing, flowerPosition, index % 2 == 0 and palette.lilacLight or palette.moon, 0.72, 1200 + index)
    end
    cylinder(clearing, "Relic pedestal", relicBase + Vector3.new(0, 0.45, 0), 0.9, 2.0, palette.stone, Enum.Material.Slate)
    cylinder(clearing, "Pedestal gold ring", relicBase + Vector3.new(0, 0.94, 0), 0.16, 1.65, palette.gold, Enum.Material.Metal)
    local relic = makePart(
        clearing,
        "MoonRelicGem",
        Vector3.new(0.78, 1.8, 0.72),
        CFrame.new(relicPosition) * CFrame.Angles(math.rad(12), math.rad(18), math.rad(12)),
        palette.lilacLight,
        Enum.Material.Neon
    )
    addLight(relic, palette.lilacLight, 16, 1.0)
    for index = 1, 4 do
        local angle = index * math.pi / 2
        local mote = orb(
            clearing,
            "Relic mote",
            relicPosition + Vector3.new(math.cos(angle) * 1.7, 0.55 + (index % 2) * 0.25, math.sin(angle) * 1.7),
            Vector3.new(0.16, 0.16, 0.16),
            palette.gold,
            Enum.Material.Neon,
            0.18
        )
        addLight(mote, palette.gold, 5, 0.2)
    end
end

-- Enriched, rig-friendly companion blockouts. Final OBJ imports remain pending Studio approval.
local fox = ReplicatedStorage:FindFirstChild("Fox")
if fox then
    local foxDetails = makeFolder(fox, "HandcraftedDetails")
    orb(foxDetails, "Chest bib", Vector3.new(0, -0.48, -0.82), Vector3.new(1.18, 1.16, 0.34), palette.cream, Enum.Material.SmoothPlastic)
    for _, side in {-1, 1} do
        orb(foxDetails, "Inner ear", Vector3.new(side * 0.8, 1.2, -0.78), Vector3.new(0.32, 0.82, 0.22), Color3.fromRGB(246, 172, 151), Enum.Material.SmoothPlastic)
        orb(foxDetails, "Cheek fluff", Vector3.new(side * 0.69, -0.12, -1.27), Vector3.new(0.48, 0.42, 0.34), palette.cream, Enum.Material.SmoothPlastic)
        orb(foxDetails, "Eye shine", Vector3.new(side * 0.62, 0.34, -1.43), Vector3.new(0.12, 0.12, 0.08), palette.cream, Enum.Material.Neon)

        local frontPaw = Vector3.new(side * 0.78, -0.85, -0.65)
        local backPaw = Vector3.new(side * 0.78, -0.85, 0.85)
        orb(foxDetails, "Paw", frontPaw, Vector3.new(0.72, 0.55, 0.82), palette.coral, Enum.Material.SmoothPlastic)
        orb(foxDetails, "Paw", backPaw, Vector3.new(0.72, 0.55, 0.82), palette.coral, Enum.Material.SmoothPlastic)
        for toe = 1, 2 do
            local toeOffset = (toe == 1 and -0.16 or 0.16)
            orb(foxDetails, "Paw toe", frontPaw + Vector3.new(toeOffset, -0.06, -0.28), Vector3.new(0.2, 0.17, 0.25), palette.cream, Enum.Material.SmoothPlastic)
            orb(foxDetails, "Paw toe", backPaw + Vector3.new(toeOffset, -0.06, -0.28), Vector3.new(0.2, 0.17, 0.25), palette.cream, Enum.Material.SmoothPlastic)
        end
    end
    orb(foxDetails, "Nose", Vector3.new(0, -0.23, -1.78), Vector3.new(0.25, 0.18, 0.18), Color3.fromRGB(55, 43, 42), Enum.Material.SmoothPlastic)
    orb(foxDetails, "Nose shine", Vector3.new(0, -0.18, -1.88), Vector3.new(0.075, 0.055, 0.035), palette.cream, Enum.Material.Neon)
    orb(foxDetails, "Tail tip", Vector3.new(0, 0.3, 2.72), Vector3.new(1.15, 1.1, 0.9), palette.cream, Enum.Material.SmoothPlastic)
    orb(foxDetails, "Leaf charm", Vector3.new(0, -0.72, -0.92), Vector3.new(0.8, 0.22, 0.55), palette.leafLight, Enum.Material.Grass)
end

local moth = ReplicatedStorage:FindFirstChild("Moth")
if moth then
    local mothDetails = makeFolder(moth, "HandcraftedDetails")
    orb(mothDetails, "Moth head", Vector3.new(0, 0.72, -0.72), Vector3.new(0.88, 0.82, 0.82), palette.cream, Enum.Material.SmoothPlastic)
    orb(mothDetails, "Abdomen band", Vector3.new(0, -0.34, -0.36), Vector3.new(0.58, 0.2, 0.36), palette.gold, Enum.Material.SmoothPlastic)
    orb(mothDetails, "Abdomen tip", Vector3.new(0, -0.67, -0.28), Vector3.new(0.42, 0.22, 0.3), palette.coral, Enum.Material.SmoothPlastic)

    for _, side in {-1, 1} do
        orb(mothDetails, "Wing lower", Vector3.new(side * 0.92, -0.52, 0.16), Vector3.new(1.55, 1.2, 0.46), Color3.fromRGB(221, 157, 202), Enum.Material.SmoothPlastic)
        orb(mothDetails, "Wing lower tip", Vector3.new(side * 1.36, -0.72, -0.02), Vector3.new(0.46, 0.5, 0.22), palette.moon, Enum.Material.Neon)
        orb(mothDetails, "Wing jewel", Vector3.new(side * 1.3, 0.45, -0.43), Vector3.new(0.62, 0.62, 0.2), palette.gold, Enum.Material.Neon)
        orb(mothDetails, "Wing tip", Vector3.new(side * 1.85, 0.05, 0.08), Vector3.new(0.6, 0.7, 0.25), palette.lilacLight, Enum.Material.Neon)
        orb(mothDetails, "Wing spot", Vector3.new(side * 1.12, 0.78, -0.46), Vector3.new(0.28, 0.34, 0.12), palette.moon, Enum.Material.Neon)
        cylinder(mothDetails, "Antenna", Vector3.new(side * 0.34, 1.12, -0.55), 0.8, 0.08, palette.cream, Enum.Material.SmoothPlastic, CFrame.Angles(0, 0, math.rad(side * 24)))
        orb(mothDetails, "Antenna tip", Vector3.new(side * 0.54, 1.55, -0.55), Vector3.new(0.18, 0.2, 0.18), palette.gold, Enum.Material.Neon)
        orb(mothDetails, "Moth eye", Vector3.new(side * 0.22, 0.75, -1.1), Vector3.new(0.16, 0.18, 0.1), Color3.fromRGB(50, 43, 62), Enum.Material.SmoothPlastic)
        orb(mothDetails, "Eye shine", Vector3.new(side * 0.2, 0.8, -1.17), Vector3.new(0.065, 0.075, 0.045), palette.cream, Enum.Material.Neon)
    end

    local glow = orb(mothDetails, "Moonlight glow", Vector3.new(0, 0.1, -0.08), Vector3.new(0.2, 0.2, 0.2), palette.moon, Enum.Material.Neon)
    addLight(glow, palette.lilacLight, 9, 0.65)
    for index = 1, 3 do
        local angle = index * math.pi * 2 / 3
        orb(mothDetails, "Glow mote", Vector3.new(math.cos(angle) * 0.58, 0.1 + index * 0.14, math.sin(angle) * 0.42), Vector3.new(0.11, 0.11, 0.11), palette.gold, Enum.Material.Neon, 0.12)
    end
end


-- First playable combat destination: a small training glade beyond the Grove.
-- The bridge, arena and enemy are generated here so a fresh place build is playable
-- without manually tagging parts or importing a placeholder NPC in Studio.
local oldCombatGlade = workspace:FindFirstChild("CombatTrainingGlade")
if oldCombatGlade then oldCombatGlade:Destroy() end

local combatGlade = Instance.new("Model")
combatGlade.Name = "CombatTrainingGlade"
combatGlade.Parent = workspace

local arenaCenter = Vector3.new(0, 12, 113)
local bridgeFolder = Instance.new("Model")
bridgeFolder.Name = "GroveApproach"
bridgeFolder.Parent = combatGlade

local function setSolid(part)
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = true
    part.CanQuery = true
    return part
end

-- A continuous, broad timber path connects the Grove shoreline to the arena.
for index = 1, 9 do
    local z = 28 + (index - 1) * 7.5
    local plank = makePart(
        bridgeFolder,
        "Approach plank",
        Vector3.new(6.2, 0.48, 8.0),
        CFrame.new(0, 12.0, z) * CFrame.Angles(0, math.rad((index % 2 == 0 and 1 or -1) * 1.5), 0),
        index % 2 == 0 and palette.barkLight or palette.bark,
        Enum.Material.WoodPlanks
    )
    setSolid(plank)
    for side = -1, 1, 2 do
        if index == 1 or index == 5 or index == 9 then
            local post = makePart(
                bridgeFolder,
                "Approach lantern post",
                Vector3.new(0.42, 2.4, 0.42),
                CFrame.new(side * 3.05, 13.2, z),
                palette.barkLight,
                Enum.Material.Wood
            )
            setSolid(post)
            local lamp = orb(bridgeFolder, "Approach lantern", Vector3.new(side * 3.05, 14.55, z), Vector3.new(0.62, 0.62, 0.62), palette.gold, Enum.Material.Neon)
            addLight(lamp, palette.gold, 8, 0.5)
        end
    end
end
for side = -1, 1, 2 do
    local rail = makePart(
        bridgeFolder,
        "Approach handrail",
        Vector3.new(0.35, 1.15, 66),
        CFrame.new(side * 3.15, 13.0, 61),
        palette.bark,
        Enum.Material.Wood
    )
    setSolid(rail)
end

local arena = Instance.new("Model")
arena.Name = "TrainingRing"
arena.Parent = combatGlade
local platform = makePart(
    arena,
    "Training stone platform",
    Vector3.new(2.4, 46, 46),
    CFrame.new(arenaCenter.X, arenaCenter.Y - 1.2, arenaCenter.Z) * CFrame.Angles(0, 0, math.rad(90)),
    Color3.fromRGB(103, 119, 105),
    Enum.Material.Slate,
    Enum.PartType.Cylinder
)
setSolid(platform)

-- Warm stone inlays make the combat boundary readable from the approach.
for index = 1, 16 do
    local angle = index * math.pi * 2 / 16
    local position = arenaCenter + Vector3.new(math.cos(angle) * 17.5, 0.28, math.sin(angle) * 17.5)
    local marker = makePart(
        arena,
        "Ring marker",
        Vector3.new(2.2, 0.42, 1.05),
        CFrame.new(position) * CFrame.Angles(0, -angle, 0),
        index % 2 == 0 and palette.gold or palette.mossLight,
        Enum.Material.Slate
    )
    setSolid(marker)
    if index % 2 == 0 then
        local rune = makePart(
            arena,
            "Glowing ring rune",
            Vector3.new(0.22, 0.12, 0.52),
            CFrame.new(position + Vector3.new(0, 0.28, 0)),
            palette.gold,
            Enum.Material.Neon
        )
        addLight(rune, palette.gold, 5, 0.16)
    end
end

for index = 1, 4 do
    local angle = (index - 1) * math.pi / 2 + math.pi / 4
    local position = arenaCenter + Vector3.new(math.cos(angle) * 19.5, 0, math.sin(angle) * 19.5)
    local pillar = makePart(
        arena,
        "Training glade pillar",
        Vector3.new(1.35, 4.2, 1.35),
        CFrame.new(position + Vector3.new(0, 2.1, 0)),
        palette.barkLight,
        Enum.Material.Wood
    )
    setSolid(pillar)
    local cap = orb(arena, "Pillar moonstone", position + Vector3.new(0, 4.35, 0), Vector3.new(1.05, 0.85, 1.05), palette.moon, Enum.Material.Neon)
    addLight(cap, palette.moon, 9, 0.45)
end

-- Entrance arch and a short, legible sign identify this as the combat tutorial area.
for side = -1, 1, 2 do
    local post = makePart(
        arena,
        "Glade entrance post",
        Vector3.new(0.9, 5.0, 1.0),
        CFrame.new(arenaCenter + Vector3.new(side * 5.2, 2.5, -21)),
        palette.bark,
        Enum.Material.Wood
    )
    setSolid(post)
end
local arch = makePart(
    arena,
    "Glade entrance arch",
    Vector3.new(11.2, 0.9, 1.1),
    CFrame.new(arenaCenter + Vector3.new(0, 5.0, -21)),
    palette.barkLight,
    Enum.Material.Wood
)
setSolid(arch)

local region = Instance.new("Part")
region.Name = "GroveTrainingRegion"
region.Size = Vector3.new(42, 22, 42)
region.CFrame = CFrame.new(arenaCenter + Vector3.new(0, 9, 0))
region.Anchored = true
region.Transparency = 1
region.CanCollide = false
region.CanTouch = false
region.CanQuery = false
region.Parent = arena
region:SetAttribute("RegionId", "GroveTraining")
CollectionService:AddTag(region, "GiantbackCombatRegion")

local function makeEnemyPart(model, name, size, frame, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = frame
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = true
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    return part
end

local function joinRig(model, name, part0, part1, c0, c1)
    local joint = Instance.new("Motor6D")
    joint.Name = name
    joint.Part0 = part0
    joint.Part1 = part1
    joint.C0 = c0
    joint.C1 = c1
    joint.Parent = part0
    return joint
end

local enemy = Instance.new("Model")
enemy.Name = "GroveGrunt01"
enemy:SetAttribute("EnemyId", "GroveGrunt01")
enemy:SetAttribute("EncounterId", "GroveGrunt01")
enemy:SetAttribute("RegionId", "GroveTraining")
enemy:SetAttribute("CombatState", "Idle")
enemy:SetAttribute("ArchetypeId", "Guardian")
enemy:SetAttribute("AggroRange", 34)
enemy:SetAttribute("AttackRange", 6)
enemy:SetAttribute("AttackDamage", 12)
enemy:SetAttribute("AttackCooldown", 2.4)
enemy:SetAttribute("TelegraphSeconds", 0.85)
enemy:SetAttribute("PathRefreshSeconds", 1.15)
enemy.Parent = combatGlade

local enemySpawn = arenaCenter + Vector3.new(0, 3, -3)
local enemyRoot = makeEnemyPart(enemy, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.lookAt(enemySpawn, enemySpawn + Vector3.new(0, 0, -1)), palette.ink)
enemyRoot.Massless = false
enemyRoot.Transparency = 1
local torso = makeEnemyPart(enemy, "Torso", Vector3.new(2.1, 2.25, 1.25), enemyRoot.CFrame, Color3.fromRGB(100, 111, 78), Enum.Material.Wood)
torso.CanCollide = true
local head = makeEnemyPart(enemy, "Head", Vector3.new(1.55, 1.5, 1.45), enemyRoot.CFrame * CFrame.new(0, 1.8, -0.03), Color3.fromRGB(133, 148, 94), Enum.Material.Wood, Enum.PartType.Ball)
local rightArm = makeEnemyPart(enemy, "Right Arm", Vector3.new(0.95, 2.0, 1.0), enemyRoot.CFrame * CFrame.new(1.45, 0.05, 0), Color3.fromRGB(111, 126, 82), Enum.Material.Wood)
local leftArm = makeEnemyPart(enemy, "Left Arm", Vector3.new(0.95, 2.0, 1.0), enemyRoot.CFrame * CFrame.new(-1.45, 0.05, 0), Color3.fromRGB(111, 126, 82), Enum.Material.Wood)
local rightLeg = makeEnemyPart(enemy, "Right Leg", Vector3.new(0.95, 2.0, 1.0), enemyRoot.CFrame * CFrame.new(0.53, -2.0, 0), Color3.fromRGB(82, 91, 68), Enum.Material.Wood)
local leftLeg = makeEnemyPart(enemy, "Left Leg", Vector3.new(0.95, 2.0, 1.0), enemyRoot.CFrame * CFrame.new(-0.53, -2.0, 0), Color3.fromRGB(82, 91, 68), Enum.Material.Wood)
rightLeg.CanCollide = true
leftLeg.CanCollide = true

joinRig(enemy, "RootJoint", enemyRoot, torso, CFrame.new(), CFrame.new())
joinRig(enemy, "Neck", torso, head, CFrame.new(0, 1.1, 0), CFrame.new(0, -0.72, 0))
local rightShoulder = joinRig(enemy, "Right Shoulder", torso, rightArm, CFrame.new(1.05, 0.65, 0), CFrame.new(0, 0.65, 0))
joinRig(enemy, "Left Shoulder", torso, leftArm, CFrame.new(-1.05, 0.65, 0), CFrame.new(0, 0.65, 0))
joinRig(enemy, "Right Hip", torso, rightLeg, CFrame.new(0.53, -1.0, 0), CFrame.new(0, 1.0, 0))
joinRig(enemy, "Left Hip", torso, leftLeg, CFrame.new(-0.53, -1.0, 0), CFrame.new(0, 1.0, 0))

local function addEnemyDetail(name, size, frame, color, material, parentPart, shape)
    local detail = makeEnemyPart(enemy, name, size, frame, color, material, shape)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = parentPart
    weld.Part1 = detail
    weld.Parent = detail
    return detail
end

addEnemyDetail("Bark crown left", Vector3.new(0.28, 1.35, 0.32), head.CFrame * CFrame.new(-0.48, 0.92, 0), palette.barkLight, Enum.Material.Wood, head)
addEnemyDetail("Bark crown right", Vector3.new(0.28, 1.35, 0.32), head.CFrame * CFrame.new(0.48, 0.92, 0), palette.barkLight, Enum.Material.Wood, head)
for side = -1, 1, 2 do
    local eye = addEnemyDetail("Amber eye", Vector3.new(0.2, 0.2, 0.12), head.CFrame * CFrame.new(side * 0.36, 0.12, -0.68), palette.gold, Enum.Material.Neon, head, Enum.PartType.Ball)
    addLight(eye, palette.gold, 4, 0.2)
end
addEnemyDetail("Moss shoulder mantle", Vector3.new(2.65, 0.45, 1.55), torso.CFrame * CFrame.new(0, 0.78, 0), palette.moss, Enum.Material.Grass, torso)
local club = addEnemyDetail("Rootwood club", Vector3.new(0.55, 2.8, 0.55), rightArm.CFrame * CFrame.new(0.15, -0.8, -0.15) * CFrame.Angles(0, 0, math.rad(-18)), palette.barkLight, Enum.Material.Wood, rightArm)
local clubCap = addEnemyDetail("Rootwood club cap", Vector3.new(0.9, 0.85, 0.9), club.CFrame * CFrame.new(0, 1.35, 0), palette.gold, Enum.Material.Wood, club, Enum.PartType.Ball)

local enemyHumanoid = Instance.new("Humanoid")
enemyHumanoid.Name = "Humanoid"
enemyHumanoid.DisplayName = "Корневой страж"
enemyHumanoid.MaxHealth = 100
enemyHumanoid.Health = 100
enemyHumanoid.WalkSpeed = 9
enemyHumanoid.JumpPower = 0
enemyHumanoid.BreakJointsOnDeath = false
enemyHumanoid.RequiresNeck = true
enemyHumanoid.NameDisplayDistance = 55
enemyHumanoid.HealthDisplayDistance = 55
enemyHumanoid.Parent = enemy
enemy.PrimaryPart = enemyRoot
enemyRoot:SetNetworkOwner(nil)
CollectionService:AddTag(enemy, "GiantbackEnemy")

local enemyHighlight = Instance.new("Highlight")
enemyHighlight.Name = "CombatTelegraphHighlight"
enemyHighlight.Adornee = enemy
enemyHighlight.FillColor = palette.coral
enemyHighlight.FillTransparency = 0.72
enemyHighlight.OutlineColor = palette.gold
enemyHighlight.OutlineTransparency = 0.08
enemyHighlight.Enabled = false
enemyHighlight.Parent = enemy

local warningBillboard = Instance.new("BillboardGui")
warningBillboard.Name = "CombatTelegraphWarning"
warningBillboard.Adornee = head
warningBillboard.Size = UDim2.fromOffset(190, 42)
warningBillboard.StudsOffset = Vector3.new(0, 2.1, 0)
warningBillboard.AlwaysOnTop = true
warningBillboard.Enabled = false
warningBillboard.Parent = enemy

local warningText = Instance.new("TextLabel")
warningText.Name = "WarningText"
warningText.Size = UDim2.fromScale(1, 1)
warningText.BackgroundColor3 = Color3.fromRGB(61, 43, 48)
warningText.BackgroundTransparency = 0.18
warningText.BorderSizePixel = 0
warningText.Text = "ВНИМАНИЕ!"
warningText.TextColor3 = palette.cream
warningText.TextStrokeTransparency = 0.35
warningText.Font = Enum.Font.GothamBold
warningText.TextScaled = true
warningText.Parent = warningBillboard

enemy:GetAttributeChangedSignal("CombatState"):Connect(function()
    local state = enemy:GetAttribute("CombatState")
    local telegraphing = state == "Telegraph"
    enemyHighlight.Enabled = telegraphing
    warningBillboard.Enabled = telegraphing
    if telegraphing then
        warningText.Text = "БЕРЕГИСЬ!"
        warningText.BackgroundColor3 = Color3.fromRGB(132, 67, 59)
        TweenService:Create(rightShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Transform = CFrame.Angles(math.rad(-118), 0, math.rad(-10)),
        }):Play()
    elseif state == "Recover" then
        warningText.Text = "АТАКА!"
        warningText.BackgroundColor3 = Color3.fromRGB(91, 105, 82)
        warningBillboard.Enabled = true
        TweenService:Create(rightShoulder, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transform = CFrame.Angles(math.rad(62), 0, math.rad(8)),
        }):Play()
        task.delay(0.25, function()
            if enemy.Parent and enemy:GetAttribute("CombatState") == "Recover" then
                TweenService:Create(rightShoulder, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Transform = CFrame.new(),
                }):Play()
                warningBillboard.Enabled = false
            end
        end)
    else
        warningBillboard.Enabled = false
        TweenService:Create(rightShoulder, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Transform = CFrame.new(),
        }):Play()
    end
end)

-- A faster, lighter scout makes the first arena encounter readable but less repetitive.
-- It reuses the authored rig and telegraph components while receiving its own server profile.
local scout = enemy:Clone()
scout.Name = "GroveScout02"
scout:SetAttribute("EnemyId", "GroveScout02")
scout:SetAttribute("EncounterId", "GroveScout02")
scout:SetAttribute("RegionId", "GroveTraining")
scout:SetAttribute("ArchetypeId", "Scout")
scout:SetAttribute("CombatState", "Idle")
scout:SetAttribute("AggroRange", 42)
scout:SetAttribute("AttackRange", 5)
scout:SetAttribute("AttackDamage", 8)
scout:SetAttribute("AttackCooldown", 1.75)
scout:SetAttribute("TelegraphSeconds", 0.58)
scout:SetAttribute("PathRefreshSeconds", 0.85)
scout.Parent = combatGlade
scout:PivotTo(CFrame.lookAt(arenaCenter + Vector3.new(9, 3, 7), arenaCenter + Vector3.new(0, 3, -3)))
local scoutHumanoid = scout:FindFirstChildOfClass("Humanoid")
if scoutHumanoid then
    scoutHumanoid.DisplayName = "Мшистый разведчик"
    scoutHumanoid.MaxHealth = 65
    scoutHumanoid.Health = 65
    scoutHumanoid.WalkSpeed = 14
end
local scoutRoot = scout:FindFirstChild("HumanoidRootPart")
if scoutRoot and scoutRoot:IsA("BasePart") then
    scoutRoot:SetNetworkOwner(nil)
end
for _, descendant in scout:GetDescendants() do
    if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
        if descendant.Name == "Amber eye" then
            descendant.Color = Color3.fromRGB(154, 225, 211)
            descendant.Material = Enum.Material.Neon
        elseif descendant.Name == "Rootwood club cap" then
            descendant.Color = Color3.fromRGB(130, 190, 173)
        elseif descendant.Name == "Rootwood club" or descendant.Name:find("Bark crown") then
            descendant.Color = Color3.fromRGB(76, 111, 92)
        else
            descendant.Color = Color3.fromRGB(92, 126, 103)
        end
    end
end
local scoutTorso = scout:FindFirstChild("Torso")
local scoutShoulder = scoutTorso and scoutTorso:FindFirstChild("Right Shoulder")
local scoutHighlight = scout:FindFirstChild("CombatTelegraphHighlight")
local scoutWarning = scout:FindFirstChild("CombatTelegraphWarning")
local scoutWarningText = scoutWarning and scoutWarning:FindFirstChild("WarningText")
if scoutWarningText and scoutWarningText:IsA("TextLabel") then
    scoutWarningText.Text = "БЕРЕГИСЬ!"
    scoutWarningText.BackgroundColor3 = Color3.fromRGB(63, 112, 100)
end
if scoutHighlight and scoutHighlight:IsA("Highlight") then
    scoutHighlight.FillColor = Color3.fromRGB(110, 203, 176)
    scoutHighlight.OutlineColor = Color3.fromRGB(187, 244, 219)
end
if scoutShoulder and scoutShoulder:IsA("Motor6D") and scoutHighlight and scoutWarning and scoutWarningText then
    scout:GetAttributeChangedSignal("CombatState"):Connect(function()
        local state = scout:GetAttribute("CombatState")
        local telegraphing = state == "Telegraph"
        scoutHighlight.Enabled = telegraphing
        scoutWarning.Enabled = telegraphing
        if telegraphing then
            scoutWarningText.Text = "БЕРЕГИСЬ!"
            TweenService:Create(scoutShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Transform = CFrame.Angles(math.rad(-105), 0, math.rad(-14)),
            }):Play()
        elseif state == "Recover" then
            scoutWarningText.Text = "РЫВОК!"
            scoutWarning.Enabled = true
            TweenService:Create(scoutShoulder, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Transform = CFrame.Angles(math.rad(72), 0, math.rad(12)),
            }):Play()
            task.delay(0.22, function()
                if scout.Parent and scout:GetAttribute("CombatState") == "Recover" then
                    TweenService:Create(scoutShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Transform = CFrame.new(),
                    }):Play()
                    scoutWarning.Enabled = false
                end
            end)
        else
            scoutWarning.Enabled = false
            TweenService:Create(scoutShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Transform = CFrame.new(),
            }):Play()
        end
    end)
end
CollectionService:AddTag(scout, "GiantbackEnemy")

local entranceGlow = orb(arena, "Training glade welcome light", arenaCenter + Vector3.new(0, 6.4, -21), Vector3.new(0.65, 0.65, 0.65), palette.gold, Enum.Material.Neon)
addLight(entranceGlow, palette.gold, 12, 0.55)

-- A first-clear reward chamber, generated alongside the training ring.
-- This is a short discovery loop, not yet the full dungeon promised for 1.0.
local trialPortal = makePart(
    arena,
    "ForestTrialGate",
    Vector3.new(6.5, 6, 1.4),
    CFrame.new(arenaCenter + Vector3.new(0, 3.5, 19)),
    palette.moon,
    Enum.Material.ForceField,
    nil,
    0.38
)
trialPortal.CanCollide = false
local gateFrame = makePart(
    arena,
    "ForestTrialGateFrame",
    Vector3.new(8.1, 7.1, 1.1),
    trialPortal.CFrame,
    palette.stone,
    Enum.Material.Slate
)
gateFrame.CanCollide = false
gateFrame.Transparency = 0.68

local function placeTrialPrompt(parent, objectText, actionText)
    local p = Instance.new("ProximityPrompt")
    p.ObjectText = objectText
    p.ActionText = actionText
    p.MaxActivationDistance = 10
    p.HoldDuration = 0.5
    p.RequiresLineOfSight = false
    p.Parent = parent
    return p
end
placeTrialPrompt(trialPortal, "Зал лесных испытаний", "Войти")

local chamber = Instance.new("Model")
chamber.Name = "ForestTrialChamber"
chamber.Parent = combatGlade
local chamberCenter = Vector3.new(0, 12, 205)
local chamberFloor = makePart(
    chamber,
    "ForestTrialFloor",
    Vector3.new(2.4, 34, 34),
    CFrame.new(chamberCenter + Vector3.new(0, -1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
    palette.stoneLight,
    Enum.Material.Slate,
    Enum.PartType.Cylinder
)
setSolid(chamberFloor)

local arrival = makePart(
    chamber,
    "ForestTrialArrival",
    Vector3.new(2, 0.5, 2),
    CFrame.new(chamberCenter + Vector3.new(0, 0.6, -8)),
    palette.gold,
    Enum.Material.Neon,
    nil,
    1
)
arrival.CanCollide = false

local returnPortal = makePart(
    chamber,
    "ForestTrialReturn",
    Vector3.new(4.5, 5.4, 1.4),
    CFrame.new(chamberCenter + Vector3.new(0, 3, -13)),
    palette.moon,
    Enum.Material.ForceField,
    nil,
    0.4
)
returnPortal.CanCollide = false
placeTrialPrompt(returnPortal, "Лесная роща", "Вернуться")

local trialChest = makePart(
    chamber,
    "ForestTrialChest",
    Vector3.new(4, 2.2, 2.5),
    CFrame.new(chamberCenter + Vector3.new(0, 1.25, 7)),
    palette.barkLight,
    Enum.Material.Wood
)
setSolid(trialChest)
local chestLid = makePart(
    chamber,
    "ForestTrialChestLid",
    Vector3.new(4.4, 0.75, 2.9),
    trialChest.CFrame * CFrame.new(0, 1.4, 0),
    palette.gold,
    Enum.Material.Metal
)
setSolid(chestLid)
local chestGlow = orb(
    chamber,
    "ForestTrialChestGlow",
    trialChest.Position + Vector3.new(0, 2.5, 0),
    Vector3.new(1.1, 1.1, 1.1),
    palette.moon,
    Enum.Material.Neon
)
addLight(chestGlow, palette.moon, 12, 0.7)
placeTrialPrompt(trialChest, "Сундук двух стражей", "Забрать награду")

for i = 1, 8 do
    local angle = math.pi * 2 * i / 8
    local pos = chamberCenter + Vector3.new(math.cos(angle) * 13, 0.5, math.sin(angle) * 13)
    local rune = makePart(
        chamber, "ForestTrialRune", Vector3.new(1.4, 0.2, 1.4),
        CFrame.new(pos), i % 2 == 0 and palette.moon or palette.gold,
        Enum.Material.Neon
    )
    rune.CanCollide = false
end

-- Let the gameplay bootstrap wait until the collectible models are fully decorated.
local ready = ReplicatedStorage:FindFirstChild("GiantbackVisualsReady") or Instance.new("BoolValue")
ready.Name = "GiantbackVisualsReady"
ready.Value = true
ready.Parent = ReplicatedStorage
