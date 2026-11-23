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

-- The Harvest Festival is a real seasonal world event, not only a journal counter.
-- Keep its decoration on every personal island so players see the event from spawn.
local festivalYear = tonumber(os.date("!%Y")) or 2026
local festivalNow = DateTime.now().UnixTimestamp
local festivalStart = DateTime.fromUniversalTime(festivalYear, 11, 23, 0, 0, 0).UnixTimestamp
local festivalEnd = DateTime.fromUniversalTime(festivalYear, 12, 8, 0, 0, 0).UnixTimestamp
if festivalNow >= festivalEnd then
    festivalYear += 1
    festivalStart = DateTime.fromUniversalTime(festivalYear, 11, 23, 0, 0, 0).UnixTimestamp
    festivalEnd = DateTime.fromUniversalTime(festivalYear, 12, 8, 0, 0, 0).UnixTimestamp
end

if festivalNow >= festivalStart and festivalNow < festivalEnd then
    local harvestFestival = makeFolder(homeDetails, "HarvestFestival")

    local function addFestivalPumpkin(position, scale, lantern)
        local pumpkin = Instance.new("Model")
        pumpkin.Name = lantern and "HarvestLantern" or "HarvestPumpkin"
        pumpkin.Parent = harvestFestival

        local orange = Color3.fromRGB(226, 126, 61)
        local body = orb(
            pumpkin,
            "Pumpkin body",
            position + Vector3.new(0, 0.72 * scale, 0),
            Vector3.new(1.55, 1.22, 1.42) * scale,
            orange,
            Enum.Material.SmoothPlastic
        )
        for ribIndex = 1, 5 do
            local angle = (ribIndex - 1) * math.pi * 2 / 5
            local rib = orb(
                pumpkin,
                "Pumpkin rib",
                position + Vector3.new(math.cos(angle) * 0.42 * scale, 0.72 * scale, math.sin(angle) * 0.38 * scale),
                Vector3.new(0.62, 1.02, 0.78) * scale,
                ribIndex % 2 == 0 and Color3.fromRGB(238, 145, 72) or orange,
                Enum.Material.SmoothPlastic
            )
            rib.CFrame = CFrame.new(rib.Position) * CFrame.Angles(0, -angle, 0)
        end
        cylinder(
            pumpkin,
            "Pumpkin stem",
            position + Vector3.new(0, 1.42 * scale, 0),
            0.38 * scale,
            0.2 * scale,
            Color3.fromRGB(91, 117, 68),
            Enum.Material.Wood
        )
        local leaf = orb(
            pumpkin,
            "Pumpkin leaf",
            position + Vector3.new(0.28 * scale, 1.34 * scale, 0.12 * scale),
            Vector3.new(0.72, 0.16, 0.42) * scale,
            palette.leafLight,
            Enum.Material.Grass
        )
        leaf.CFrame = leaf.CFrame * CFrame.Angles(0, 0, math.rad(-22))

        if lantern then
            for side = -1, 1, 2 do
                orb(
                    pumpkin,
                    "Lantern eye",
                    position + Vector3.new(side * 0.3 * scale, 0.84 * scale, -0.61 * scale),
                    Vector3.new(0.17, 0.2, 0.12) * scale,
                    palette.cream,
                    Enum.Material.Neon
                )
            end
            local glow = orb(
                pumpkin,
                "Lantern glow",
                position + Vector3.new(0, 0.58 * scale, -0.68 * scale),
                Vector3.new(0.22, 0.16, 0.1) * scale,
                palette.gold,
                Enum.Material.Neon,
                0.12
            )
            addLight(glow, palette.gold, 8 * scale, 0.38)
        end
        body.CastShadow = true
    end

    local function addWheatSheaf(position, scale)
        local sheaf = Instance.new("Model")
        sheaf.Name = "HarvestWheatSheaf"
        sheaf.Parent = harvestFestival
        for stalkIndex = 1, 7 do
            local offset = (stalkIndex - 4) * 0.13 * scale
            local lean = (stalkIndex - 4) * 4
            local stalk = cylinder(
                sheaf,
                "Golden wheat stalk",
                position + Vector3.new(offset, 0.88 * scale, 0),
                1.85 * scale,
                0.075 * scale,
                Color3.fromRGB(190, 151, 74),
                Enum.Material.Grass
            )
            stalk.CFrame = stalk.CFrame * CFrame.Angles(0, 0, math.rad(lean))
            local head = orb(
                sheaf,
                "Wheat head",
                position + Vector3.new(offset * 1.8, (1.85 + math.abs(stalkIndex - 4) * 0.07) * scale, 0),
                Vector3.new(0.2, 0.48, 0.18) * scale,
                Color3.fromRGB(244, 203, 116),
                Enum.Material.Grass
            )
            head.CFrame = head.CFrame * CFrame.Angles(0, 0, math.rad(lean))
        end
        cylinder(
            sheaf,
            "Wheat ribbon",
            position + Vector3.new(0, 0.42 * scale, 0),
            0.16 * scale,
            0.82 * scale,
            palette.coral,
            Enum.Material.Fabric
        )
    end

    -- A readable banner turns the existing garden arch into the festival entrance.
    local banner = makePart(
        harvestFestival,
        "Harvest Festival Banner",
        Vector3.new(6.8, 1.12, 0.24),
        CFrame.new(-12.2, 14.72, 5.78),
        Color3.fromRGB(153, 82, 58),
        Enum.Material.WoodPlanks
    )
    local bannerGui = Instance.new("SurfaceGui")
    bannerGui.Name = "FestivalTitle"
    bannerGui.Face = Enum.NormalId.Front
    bannerGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    bannerGui.PixelsPerStud = 54
    bannerGui.Parent = banner
    local bannerText = Instance.new("TextLabel")
    bannerText.Name = "Title"
    bannerText.Size = UDim2.fromScale(1, 1)
    bannerText.BackgroundTransparency = 1
    bannerText.Text = "ФЕСТИВАЛЬ УРОЖАЯ"
    bannerText.TextColor3 = palette.cream
    bannerText.TextStrokeColor3 = palette.bark
    bannerText.TextStrokeTransparency = 0.55
    bannerText.Font = Enum.Font.GothamBold
    bannerText.TextScaled = true
    bannerText.TextWrapped = true
    bannerText.Parent = bannerGui

    -- A curved leaf-and-berry garland follows the arch instead of blocking the path.
    for index = 1, 9 do
        local alpha = (index - 1) / 8
        local x = -16.0 + alpha * 7.6
        local y = 15.2 - math.sin(alpha * math.pi) * 0.48
        local leaf = orb(
            harvestFestival,
            "Festival garland leaf",
            Vector3.new(x, y, 5.55),
            Vector3.new(0.62, 0.18, 0.34),
            index % 2 == 0 and palette.leafLight or palette.leaf,
            Enum.Material.Grass
        )
        leaf.CFrame = leaf.CFrame * CFrame.Angles(0, 0, math.rad((index % 2 == 0 and 18 or -18)))
        if index % 2 == 0 then
            orb(
                harvestFestival,
                "Festival garland berry",
                Vector3.new(x, y - 0.22, 5.46),
                Vector3.new(0.2, 0.22, 0.2),
                palette.coral,
                Enum.Material.SmoothPlastic
            )
        end
    end

    -- The props frame the arch but stay outside the stepping-stone route.
    addFestivalPumpkin(Vector3.new(-19.0, 12.14, 9.4), 0.9, true)
    addFestivalPumpkin(Vector3.new(-5.5, 12.14, 9.4), 0.82, false)
    addFestivalPumpkin(Vector3.new(-17.3, 12.14, 12.0), 0.58, false)
    addFestivalPumpkin(Vector3.new(-7.0, 12.14, 12.0), 0.62, true)
    addWheatSheaf(Vector3.new(-20.0, 12.14, 6.8), 0.9)
    addWheatSheaf(Vector3.new(-4.3, 12.14, 6.8), 0.9)

    -- A small harvest basket gives the entrance a clear seasonal focal point.
    local basketPosition = Vector3.new(-12.2, 12.14, 11.2)
    local basket = Instance.new("Model")
    basket.Name = "HarvestBasket"
    basket.Parent = harvestFestival
    cylinder(
        basket,
        "Woven basket body",
        basketPosition + Vector3.new(0, 0.48, 0),
        0.92,
        1.65,
        Color3.fromRGB(151, 105, 67),
        Enum.Material.WoodPlanks
    )
    cylinder(
        basket,
        "Basket rim",
        basketPosition + Vector3.new(0, 0.96, 0),
        0.14,
        1.78,
        Color3.fromRGB(190, 139, 83),
        Enum.Material.Wood
    )
    for index = 1, 5 do
        local angle = index * math.pi * 2 / 5
        local cropPosition = basketPosition + Vector3.new(math.cos(angle) * 0.42, 1.22 + (index % 2) * 0.08, math.sin(angle) * 0.36)
        orb(
            basket,
            "Harvest fruit",
            cropPosition,
            Vector3.new(0.55, 0.48, 0.5),
            index % 2 == 0 and palette.coral or Color3.fromRGB(232, 159, 74),
            Enum.Material.SmoothPlastic
        )
        orb(
            basket,
            "Harvest leaf",
            cropPosition + Vector3.new(0, 0.28, 0),
            Vector3.new(0.28, 0.08, 0.2),
            palette.leafLight,
            Enum.Material.Grass
        )
    end
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

-- Passive combat practice target. Hits go through Combat.server.luau, not a client prompt.
local dummy = Instance.new("Model")
dummy.Name = "GroveTrainingDummy01"
dummy:SetAttribute("EnemyId", "GroveTrainingDummy01")
dummy:SetAttribute("EncounterId", "GroveTrainingDummy01")
dummy:SetAttribute("RegionId", "GroveTraining")
dummy:SetAttribute("IsTrainingDummy", true)
dummy:SetAttribute("CombatState", "Ready")
dummy:SetAttribute("TrainingHitCount", 0)
dummy.Parent = arena
local dummyBase = arenaCenter + Vector3.new(13, 0, 9)
local dummyRoot = Instance.new("Part")
dummyRoot.Name = "HumanoidRootPart"
dummyRoot.Size = Vector3.new(2.2, 3.8, 2.2)
dummyRoot.CFrame = CFrame.new(dummyBase + Vector3.new(0, 2.8, 0))
dummyRoot.Transparency = 1
dummyRoot.Anchored = true
dummyRoot.CanCollide = false
dummyRoot.CanTouch = false
dummyRoot.CanQuery = false
dummyRoot.Parent = dummy
dummy.PrimaryPart = dummyRoot
local dummyHumanoid = Instance.new("Humanoid")
dummyHumanoid.MaxHealth = 100
dummyHumanoid.Health = 100
dummyHumanoid.WalkSpeed = 0
dummyHumanoid.RequiresNeck = false
dummyHumanoid.DisplayName = "Тренировочный манекен"
dummyHumanoid.Parent = dummy
for _, detail in {
    {name = "Torso", size = Vector3.new(2.0, 3.2, 1.35), shift = Vector3.new(0, 0, 0)},
    {name = "Head", size = Vector3.new(1.45, 1.5, 1.45), shift = Vector3.new(0, 2.4, 0)},
    {name = "Левая рука", size = Vector3.new(0.65, 2.3, 0.8), shift = Vector3.new(-1.5, 0.15, 0)},
    {name = "Правая рука", size = Vector3.new(0.65, 2.3, 0.8), shift = Vector3.new(1.5, 0.15, 0)},
} do
    local piece = Instance.new("Part")
    piece.Name = detail.name
    piece.Size = detail.size
    piece.CFrame = dummyRoot.CFrame * CFrame.new(detail.shift)
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = true
    piece.Color = Color3.fromRGB(172, 127, 80)
    piece.Material = Enum.Material.Wood
    piece.Parent = dummy
end
local dummySign = Instance.new("BillboardGui")
dummySign.Name = "TrainingTargetLabel"
dummySign.Adornee = dummyRoot
dummySign.Size = UDim2.fromOffset(180, 42)
dummySign.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
dummySign.AlwaysOnTop = false
dummySign.MaxDistance = 55
dummySign.Parent = dummy
local dummyText = Instance.new("TextLabel")
dummyText.Size = UDim2.fromScale(1, 1)
dummyText.BackgroundTransparency = 1
dummyText.Text = "ТРЕНИРОВКА\\nАтакуй, чтобы проверить комбо"
dummyText.Font = Enum.Font.GothamBold
dummyText.TextScaled = true
dummyText.TextColor3 = Color3.fromRGB(255, 232, 166)
dummyText.TextStrokeTransparency = 0.35
dummyText.Parent = dummySign
CollectionService:AddTag(dummy, "GiantbackEnemy")

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
warningBillboard.AlwaysOnTop = false
warningBillboard.MaxDistance = 65
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

-- Mossling is a repeatable, readable live encounter in the existing Grove arena.
-- It uses the same server-owned combat pipeline and a one-time persistent Stone reward.
local mosslingTemplate = scout:Clone()
mosslingTemplate.Name = "GroveMossling01"
local mosslingSpawn = arenaCenter + Vector3.new(-12, 3, 8)

local function spawnMossling()
    if not combatGlade.Parent then return end
    local mossling = mosslingTemplate:Clone()
    mossling.Name = "GroveMossling01"
    mossling:SetAttribute("EnemyId", "GroveMossling01")
    mossling:SetAttribute("EncounterId", "GroveMossling01")
    mossling:SetAttribute("RegionId", "GroveTraining")
    mossling:SetAttribute("ArchetypeId", "Mossling")
    mossling:SetAttribute("CombatState", "Idle")
    mossling:SetAttribute("AggroRange", 25)
    mossling:SetAttribute("AttackRange", 4.5)
    mossling:SetAttribute("AttackDamage", 6)
    mossling:SetAttribute("AttackCooldown", 2.8)
    mossling:SetAttribute("TelegraphSeconds", 1.15)
    mossling:SetAttribute("PollenRadius", 9)
    mossling:SetAttribute("PollenDamage", 8)
    mossling:SetAttribute("PathRefreshSeconds", 1.0)
    mossling:PivotTo(CFrame.lookAt(mosslingSpawn, arenaCenter + Vector3.new(0, 3, 0)))

    local humanoid = mossling:FindFirstChildOfClass("Humanoid")
    if not humanoid then mossling:Destroy() return end
    humanoid.DisplayName = "Моховичок"
    humanoid.MaxHealth = 48
    humanoid.Health = 48
    humanoid.WalkSpeed = 8
    humanoid.BreakJointsOnDeath = false

    local mossHead = mossling:FindFirstChild("Head")
    for _, piece in mossling:GetDescendants() do
        if piece:IsA("BasePart") and piece.Name ~= "HumanoidRootPart" then
            if piece.Name == "Amber eye" then
                piece.Color = Color3.fromRGB(244, 229, 150)
            else
                piece.Color = Color3.fromRGB(72, 145, 91)
                piece.Material = Enum.Material.Grass
            end
        end
    end
    for _, itemName in {"Rootwood club", "Rootwood club cap"} do
        local item = mossling:FindFirstChild(itemName, true)
        if item then item:Destroy() end
    end
    -- Distinctive leaf crown; decorative details are welded and never alter hit rewards.
    if mossHead and mossHead:IsA("BasePart") then
        for side = -1, 1, 2 do
            local leaf = Instance.new("Part")
            leaf.Name = "Mossling leaf"
            leaf.Size = Vector3.new(0.7, 1.35, 0.3)
            leaf.Color = Color3.fromRGB(135, 207, 103)
            leaf.Material = Enum.Material.Grass
            leaf.CanCollide = false
            leaf.CanTouch = false
            leaf.CanQuery = false
            leaf.Massless = true
            leaf.CFrame = mossHead.CFrame * CFrame.new(side * 0.5, 1.0, 0) * CFrame.Angles(0, 0, math.rad(-side * 30))
            leaf.Parent = mossling
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = mossHead
            weld.Part1 = leaf
            weld.Parent = leaf
        end
    end
    local root = mossling:FindFirstChild("HumanoidRootPart")
    local warning = mossling:FindFirstChild("CombatTelegraphWarning")
    local highlight = mossling:FindFirstChild("CombatTelegraphHighlight")
    local warningText = warning and warning:FindFirstChild("WarningText")
    if warningText and warningText:IsA("TextLabel") then
        warningText.Text = "УКЛОНЯЙСЯ!"
    end
    if highlight and highlight:IsA("Highlight") then
        highlight.FillColor = Color3.fromRGB(177, 223, 104)
        highlight.OutlineColor = Color3.fromRGB(244, 236, 148)
    end
    mossling:GetAttributeChangedSignal("CombatState"):Connect(function()
        if not mossling.Parent then return end
        local state = mossling:GetAttribute("CombatState")
        local telegraphing = state == "Telegraph" or state == "PollenTelegraph"
        if highlight then highlight.Enabled = telegraphing end
        if warning then warning.Enabled = telegraphing or state == "Recover" end
        if warningText then
            warningText.Text = telegraphing and "УКЛОНЯЙСЯ!" or "АТАКА!"
        end
    end)
    humanoid.Died:Connect(function()
        task.delay(3, function()
            if mossling.Parent then mossling:Destroy() end
        end)
        task.delay(20, function()
            if combatGlade.Parent then spawnMossling() end
        end)
    end)
    -- Clone inherits Scout tags. Re-add after parenting so combat registration is guaranteed.
    CollectionService:RemoveTag(mossling, "GiantbackEnemy")
    mossling.Parent = combatGlade
    if root and root:IsA("BasePart") then root:SetNetworkOwner(nil) end
    CollectionService:AddTag(mossling, "GiantbackEnemy")
end
spawnMossling()

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

local runeClue = makePart(
    chamber,
    "ForestTrialRuneClue",
    Vector3.new(8, 2.2, 0.35),
    CFrame.new(chamberCenter + Vector3.new(0, 2.2, -10)),
    palette.bark,
    Enum.Material.Wood
)
local clueGui = Instance.new("SurfaceGui")
clueGui.Name = "RuneClueSurface"
clueGui.Face = Enum.NormalId.Front
clueGui.CanvasSize = Vector2.new(700, 180)
clueGui.Parent = runeClue
local clueText = Instance.new("TextLabel")
clueText.Size = UDim2.fromScale(1, 1)
clueText.BackgroundTransparency = 1
clueText.Text = "ПАМЯТЬ ЛЕСА\nЛуна → Рассвет → Прилив"
clueText.TextColor3 = palette.cream
clueText.TextStrokeTransparency = 0.55
clueText.Font = Enum.Font.GothamBold
clueText.TextScaled = true
clueText.Parent = clueGui

-- Three readable, interactable runes form the chamber's small memory puzzle.
local puzzleRunes = {
    {name = "ForestTrialRuneMoon", label = "Луна", color = palette.moon, offset = Vector3.new(-8, 0.55, 0)},
    {name = "ForestTrialRuneDawn", label = "Рассвет", color = palette.gold, offset = Vector3.new(8, 0.55, 0)},
    {name = "ForestTrialRuneTide", label = "Прилив", color = palette.water, offset = Vector3.new(0, 0.55, -3)},
}
for index, definition in puzzleRunes do
    local rune = makePart(
        chamber,
        definition.name,
        Vector3.new(2.4, 0.42, 2.4),
        CFrame.new(chamberCenter + definition.offset),
        definition.color,
        Enum.Material.Neon,
        Enum.PartType.Cylinder
    )
    rune.CanQuery = true
    rune:SetAttribute("PuzzleRuneId", definition.name)
    rune:SetAttribute("PuzzleOrder", index)
    local runePrompt = placeTrialPrompt(rune, "Руна памяти", "Активировать")
    runePrompt.HoldDuration = 0.25
    local label = Instance.new("BillboardGui")
    label.Name = "RuneLabel"
    label.Size = UDim2.fromOffset(120, 28)
    label.StudsOffset = Vector3.new(0, 1.4, 0)
    label.AlwaysOnTop = false
    label.MaxDistance = 34
    label.Parent = rune
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.fromScale(1, 1)
    labelText.BackgroundTransparency = 1
    labelText.Text = definition.label
    labelText.TextColor3 = palette.cream
    labelText.TextStrokeTransparency = 0.35
    labelText.Font = Enum.Font.GothamBold
    labelText.TextScaled = true
    labelText.Parent = label
end

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

-- First compact Rootvault expedition: entrance, trapped passage, mechanism room and reward vault.
local rootvault = Instance.new("Model")
rootvault.Name = "RootvaultDungeon"
rootvault.Parent = combatGlade
local vaultFloorY = 0
local function vaultRoom(name, center, size)
    local room = Instance.new("Model")
    room.Name = name
    room.Parent = rootvault
    local floor = makePart(room, name .. "Floor", Vector3.new(size.X, 2, size.Z), CFrame.new(center.X, vaultFloorY, center.Z), palette.stoneLight, Enum.Material.Slate)
    setSolid(floor)
    local wallHeight = 9
    local wallY = vaultFloorY + wallHeight / 2 + 1
    for _, side in { -1, 1 } do
        local wall = makePart(room, name .. "SideWall", Vector3.new(1.4, wallHeight, size.Z), CFrame.new(center.X + side * (size.X / 2), wallY, center.Z), palette.stone, Enum.Material.Rock)
        setSolid(wall)
    end
    -- Room ends stay open; the trap passage and the sealed door provide the intended route.
    return room
end

local entryRoomCenter = Vector3.new(0, 0, 255)
local mechanismRoomCenter = Vector3.new(0, 0, 300)
local rewardRoomCenter = Vector3.new(0, 0, 345)
local entryRoom = vaultRoom("RootvaultEntryRoom", entryRoomCenter, Vector3.new(28, 0, 28))
local mechanismRoom = vaultRoom("RootvaultMechanismRoom", mechanismRoomCenter, Vector3.new(28, 0, 28))
local rewardRoom = vaultRoom("RootvaultRewardRoom", rewardRoomCenter, Vector3.new(32, 0, 32))

local passage = makePart(rootvault, "RootvaultTrapPassage", Vector3.new(13, 2, 20), CFrame.new(0, vaultFloorY, 277.5), palette.stoneLight, Enum.Material.Slate)
setSolid(passage)
for index, z in {270, 277.5, 285} do
    local plate = makePart(
        rootvault,
        "RootvaultPressurePlate" .. index,
        Vector3.new(8, 0.22, 1.8),
        CFrame.new(0, vaultFloorY + 1.12, z),
        palette.coral,
        Enum.Material.Neon
    )
    plate.CanTouch = true
    plate.CanQuery = true
    plate:SetAttribute("TrapDamage", 10)
    local glow = Instance.new("PointLight")
    glow.Color = palette.coral
    glow.Range = 7
    glow.Brightness = 0.45
    glow.Parent = plate
end

local vaultEntrance = makePart(
    chamber,
    "RootvaultEntrance",
    Vector3.new(4.8, 5.8, 1.2),
    CFrame.new(chamberCenter + Vector3.new(12, 3, 8)),
    palette.lilac,
    Enum.Material.ForceField,
    nil,
    0.3
)
vaultEntrance.CanCollide = false
placeTrialPrompt(vaultEntrance, "Хранилище корней", "Войти")

local vaultArrival = makePart(
    entryRoom,
    "RootvaultArrival",
    Vector3.new(2, 0.5, 2),
    CFrame.new(entryRoomCenter + Vector3.new(0, 0.6, 0)),
    palette.lilacLight,
    Enum.Material.Neon,
    nil,
    1
)
vaultArrival.CanCollide = false

local vaultReturn = makePart(
    entryRoom,
    "RootvaultReturn",
    Vector3.new(4.4, 5.5, 1.2),
    CFrame.new(entryRoomCenter + Vector3.new(0, 3, -10)),
    palette.moon,
    Enum.Material.ForceField,
    nil,
    0.3
)
vaultReturn.CanCollide = false
placeTrialPrompt(vaultReturn, "Лесная комната", "Вернуться")

local leverBase = makePart(
    mechanismRoom,
    "RootvaultLeverBase",
    Vector3.new(3.2, 1.1, 2.5),
    CFrame.new(mechanismRoomCenter + Vector3.new(0, 1.55, 7)),
    palette.bark,
    Enum.Material.Wood
)
setSolid(leverBase)
local leverHandle = makePart(
    mechanismRoom,
    "RootvaultLeverHandle",
    Vector3.new(0.55, 3.2, 0.55),
    CFrame.new(mechanismRoomCenter + Vector3.new(0, 3.4, 7)),
    palette.gold,
    Enum.Material.Metal
)
setSolid(leverHandle)
placeTrialPrompt(leverBase, "Древний механизм", "Потянуть рычаг")

local mechanismExit = makePart(
    mechanismRoom,
    "RootvaultMechanismExit",
    Vector3.new(2, 0.5, 2),
    CFrame.new(mechanismRoomCenter + Vector3.new(-10, 0.6, -8)),
    palette.moon,
    Enum.Material.Neon,
    nil,
    1
)
mechanismExit.CanCollide = false
placeTrialPrompt(mechanismExit, "Начало хранилища", "Вернуться к входу")

local sealedDoor = makePart(
    mechanismRoom,
    "RootvaultSealedDoor",
    Vector3.new(12, 8, 1.4),
    CFrame.new(mechanismRoomCenter + Vector3.new(0, 5, 14)),
    palette.bark,
    Enum.Material.Slate
)
setSolid(sealedDoor)
local doorPrompt = makePart(
    mechanismRoom,
    "RootvaultDoorPrompt",
    Vector3.new(2.2, 2.2, 0.5),
    CFrame.new(mechanismRoomCenter + Vector3.new(0, 2.2, 11.8)),
    palette.gold,
    Enum.Material.Neon,
    nil,
    0.65
)
doorPrompt.CanCollide = false
placeTrialPrompt(doorPrompt, "Печать хранилища", "Открыть проход")

local returnDoorPrompt = makePart(
    rewardRoom,
    "RootvaultReturnDoorPrompt",
    Vector3.new(2.2, 2.2, 0.5),
    CFrame.new(rewardRoomCenter + Vector3.new(0, 2.2, -14)),
    palette.gold,
    Enum.Material.Neon,
    nil,
    0.65
)
returnDoorPrompt.CanCollide = false
placeTrialPrompt(returnDoorPrompt, "Проход в зал механизма", "Вернуться")

local vaultChest = makePart(
    rewardRoom,
    "RootvaultRewardChest",
    Vector3.new(4.5, 2.5, 3),
    CFrame.new(rewardRoomCenter + Vector3.new(0, 1.8, 7)),
    palette.barkLight,
    Enum.Material.Wood
)
setSolid(vaultChest)
local vaultChestGlow = orb(rootvault, "RootvaultRewardGlow", vaultChest.Position + Vector3.new(0, 2.5, 0), Vector3.new(1.2, 1.2, 1.2), palette.lilacLight, Enum.Material.Neon)
addLight(vaultChestGlow, palette.lilacLight, 13, 0.8)
placeTrialPrompt(vaultChest, "Сундук хранилища", "Забрать реликвию")

for _, center in {entryRoomCenter, mechanismRoomCenter, rewardRoomCenter} do
    for index = 1, 4 do
        local x = (index % 2 == 0 and 1 or -1) * 10
        local z = (index <= 2 and -1 or 1) * 10
        local crystal = orb(rootvault, "RootvaultGlowCrystal", center + Vector3.new(x, 2.5, z), Vector3.new(1.1, 2.2, 1.1), palette.lilacLight, Enum.Material.Neon)
        addLight(crystal, palette.lilacLight, 8, 0.35)
    end
end

-- Crystal Grotto: an optional moonlit side-cave reached from the Dusk shoreline.
local crystalGrotto = Instance.new("Model")
crystalGrotto.Name = "CrystalGrotto"
crystalGrotto.Parent = combatGlade
local grottoCenter = Vector3.new(150, 0, 470)
local grottoFloor = makePart(crystalGrotto, "CrystalGrottoFloor", Vector3.new(46, 2, 42), CFrame.new(grottoCenter), palette.stoneLight, Enum.Material.Slate)
setSolid(grottoFloor)

for _, wallSpec in {
    {name = "NorthWall", size = Vector3.new(46, 15, 2), offset = Vector3.new(0, 7.5, -21)},
    {name = "SouthWall", size = Vector3.new(46, 15, 2), offset = Vector3.new(0, 7.5, 21)},
    {name = "WestWall", size = Vector3.new(2, 15, 42), offset = Vector3.new(-23, 7.5, 0)},
    {name = "EastWall", size = Vector3.new(2, 15, 42), offset = Vector3.new(23, 7.5, 0)},
} do
    local wall = makePart(crystalGrotto, "CrystalGrotto" .. wallSpec.name, wallSpec.size, CFrame.new(grottoCenter + wallSpec.offset), palette.stone, Enum.Material.Rock)
    setSolid(wall)
end

local grottoArrival = makePart(crystalGrotto, "CrystalGrottoArrival", Vector3.new(2, 0.5, 2), CFrame.new(grottoCenter + Vector3.new(0, 0.6, -15)), palette.moon, Enum.Material.Neon)
grottoArrival.Transparency = 1
grottoArrival.CanCollide = false
local grottoReturn = makePart(crystalGrotto, "CrystalGrottoReturn", Vector3.new(4.5, 5.5, 1.2), CFrame.new(grottoCenter + Vector3.new(0, 3, -18)), palette.moon, Enum.Material.ForceField)
grottoReturn.CanCollide = false
placeTrialPrompt(grottoReturn, "Сумеречная долина", "Вернуться")

-- Three rune stones teach a short sequence puzzle; the sealed cache is its permanent reward.
local crystalRuneDefinitions = {
    {name = "CrystalRuneMoon", label = "ЛУНА", color = palette.moon, offset = Vector3.new(-11, 1.28, -2)},
    {name = "CrystalRuneDawn", label = "РАССВЕТ", color = palette.gold, offset = Vector3.new(0, 1.28, -5)},
    {name = "CrystalRuneTide", label = "ПРИЛИВ", color = palette.water, offset = Vector3.new(11, 1.28, -2)},
}
for _, definition in crystalRuneDefinitions do
    local rune = makePart(
        crystalGrotto, definition.name, Vector3.new(2.7, 0.48, 2.7),
        CFrame.new(grottoCenter + definition.offset), definition.color, Enum.Material.Neon,
        Enum.PartType.Cylinder
    )
    rune.CanCollide = false
    rune:SetAttribute("CrystalRuneId", definition.name)
    placeTrialPrompt(rune, "Руна памяти · " .. definition.label, "Пробудить")
    addLight(rune, definition.color, 8, 0.35)
end

local crystalClue = makePart(
    crystalGrotto, "CrystalGrottoRuneClue", Vector3.new(10, 2.4, 0.45),
    CFrame.new(grottoCenter + Vector3.new(0, 2.5, -10)), palette.stone, Enum.Material.Slate
)
local crystalClueGui = Instance.new("SurfaceGui")
crystalClueGui.Name = "CrystalRuneClueSurface"
crystalClueGui.Face = Enum.NormalId.Front
crystalClueGui.CanvasSize = Vector2.new(900, 220)
crystalClueGui.Parent = crystalClue
local crystalClueText = Instance.new("TextLabel")
crystalClueText.Size = UDim2.fromScale(1, 1)
crystalClueText.BackgroundTransparency = 1
crystalClueText.Text = "ПЕСНЬ ПЕЩЕРЫ\nЛуна → Рассвет → Прилив"
crystalClueText.TextColor3 = palette.cream
crystalClueText.TextStrokeTransparency = 0.55
crystalClueText.Font = Enum.Font.GothamBold
crystalClueText.TextScaled = true
crystalClueText.Parent = crystalClueGui

local crystalCache = makePart(
    crystalGrotto, "CrystalGrottoCache", Vector3.new(3.8, 2.2, 2.8),
    CFrame.new(grottoCenter + Vector3.new(0, 2.15, 15)), palette.barkLight, Enum.Material.Wood
)
setSolid(crystalCache)
local crystalCacheGlow = orb(
    crystalGrotto, "CrystalGrottoCacheGlow",
    crystalCache.Position + Vector3.new(0, 2.4, 0),
    Vector3.new(1.2, 1.2, 1.2), palette.gold, Enum.Material.Neon
)
addLight(crystalCacheGlow, palette.gold, 12, 0.6)
placeTrialPrompt(crystalCache, "Запечатанный тайник", "Открыть")

-- Hidden Echo Chamber beyond the rune cache; access is gated by the server-side sigil check.
local echoChamber = Instance.new("Model")
echoChamber.Name = "CrystalEchoChamber"
echoChamber.Parent = crystalGrotto
local echoCenter = grottoCenter + Vector3.new(0, 0, 70)
local echoFloor = makePart(echoChamber, "CrystalEchoFloor", Vector3.new(28, 2, 26), CFrame.new(echoCenter), palette.stoneLight, Enum.Material.Slate)
setSolid(echoFloor)
for _, wallSpec in {
    {name = "NorthWall", size = Vector3.new(28, 12, 2), offset = Vector3.new(0, 6, -13)},
    {name = "SouthWall", size = Vector3.new(28, 12, 2), offset = Vector3.new(0, 6, 13)},
    {name = "WestWall", size = Vector3.new(2, 12, 26), offset = Vector3.new(-14, 6, 0)},
    {name = "EastWall", size = Vector3.new(2, 12, 26), offset = Vector3.new(14, 6, 0)},
} do
    local wall = makePart(echoChamber, "CrystalEcho" .. wallSpec.name, wallSpec.size, CFrame.new(echoCenter + wallSpec.offset), palette.stone, Enum.Material.Rock)
    setSolid(wall)
end
local echoGate = makePart(
    crystalGrotto, "CrystalEchoGate", Vector3.new(5, 6, 1.2),
    CFrame.new(grottoCenter + Vector3.new(0, 3, 20)), palette.gold, Enum.Material.ForceField
)
echoGate.Transparency = 0.2
echoGate.CanCollide = false
placeTrialPrompt(echoGate, "Дверь Эхо-камеры", "Коснуться печати")
addLight(echoGate, palette.gold, 14, 0.7)
local echoArrival = makePart(
    echoChamber, "CrystalEchoArrival", Vector3.new(2, 0.5, 2),
    CFrame.new(echoCenter + Vector3.new(0, 0.6, -8)), palette.moon, Enum.Material.Neon
)
echoArrival.Transparency = 1
echoArrival.CanCollide = false
local echoReturn = makePart(
    echoChamber, "CrystalEchoReturn", Vector3.new(4, 5, 1.2),
    CFrame.new(echoCenter + Vector3.new(0, 2.8, -10)), palette.moon, Enum.Material.ForceField
)
echoReturn.CanCollide = false
placeTrialPrompt(echoReturn, "Главный зал пещеры", "Вернуться")
local prismSeed = makePart(
    echoChamber, "PrismSeed", Vector3.new(1.5, 2.2, 1.5),
    CFrame.new(echoCenter + Vector3.new(0, 2.3, 6)), palette.lilacLight, Enum.Material.Neon, Enum.PartType.Ball
)
prismSeed.CanCollide = false
local seedGlow = addLight(prismSeed, palette.lilacLight, 18, 1.1)
local seedHalo = orb(
    echoChamber, "PrismSeedHalo", prismSeed.Position + Vector3.new(0, 1.4, 0),
    Vector3.new(3.2, 0.18, 3.2), palette.gold, Enum.Material.Neon
)
seedHalo.Transparency = 0.35

local wispNest = makePart(
    echoChamber, "CrystalWispNest", Vector3.new(4.8, 0.45, 4.8),
    CFrame.new(echoCenter + Vector3.new(-8, 0.35, 2)), palette.lilac, Enum.Material.Neon, Enum.PartType.Cylinder
)
wispNest.Transparency = 0.24
addLight(wispNest, palette.lilacLight, 13, 0.8)
for index = 1, 4 do
    local angle = math.pi * 2 * index / 4
    local shard = makePart(
        echoChamber, "WispNestShard", Vector3.new(0.55, 2.4, 0.55),
        CFrame.new(wispNest.Position + Vector3.new(math.cos(angle) * 2.1, 1.15, math.sin(angle) * 2.1)) * CFrame.Angles(0, 0, math.rad((index % 2 == 0 and 1 or -1) * 12)),
        palette.lilacLight, Enum.Material.Neon
    )
    addLight(shard, palette.lilacLight, 5, 0.25)
end

-- Procedural companion model shared by the wild encounter and owner followers.
local oldWisp = ReplicatedStorage:FindFirstChild("CrystalWisp")
if oldWisp then oldWisp:Destroy() end
local wispModel = Instance.new("Model")
wispModel.Name = "CrystalWisp"
wispModel.Parent = ReplicatedStorage
local wispBody = orb(wispModel, "Body", Vector3.new(0, 0, 0), Vector3.new(1.7, 1.95, 1.55), palette.lilacLight, Enum.Material.Neon)
wispBody.Transparency = 0.08
wispModel.PrimaryPart = wispBody
orb(wispModel, "Core", Vector3.new(0, -0.05, -0.72), Vector3.new(0.82, 0.92, 0.35), palette.water, Enum.Material.Neon)
orb(wispModel, "EyeLeft", Vector3.new(-0.31, 0.16, -0.88), Vector3.new(0.12, 0.18, 0.08), palette.ink, Enum.Material.SmoothPlastic)
orb(wispModel, "EyeRight", Vector3.new(0.31, 0.16, -0.88), Vector3.new(0.12, 0.18, 0.08), palette.ink, Enum.Material.SmoothPlastic)
orb(wispModel, "CheekLeft", Vector3.new(-0.49, -0.13, -0.83), Vector3.new(0.2, 0.12, 0.08), palette.coral, Enum.Material.Neon)
orb(wispModel, "CheekRight", Vector3.new(0.49, -0.13, -0.83), Vector3.new(0.2, 0.12, 0.08), palette.coral, Enum.Material.Neon)
for index = 1, 3 do
    local angle = (index - 1) * math.pi * 2 / 3
    local shard = orb(wispModel, "OrbitCrystal" .. tostring(index), Vector3.new(math.cos(angle) * 0.95, 0.38 + (index % 2) * 0.18, math.sin(angle) * 0.58), Vector3.new(0.36, 0.72, 0.36), index == 2 and palette.gold or palette.water, Enum.Material.Neon)
    shard.CFrame *= CFrame.Angles(0, 0, math.rad(index * 18))
end
addLight(wispBody, palette.lilacLight, 12, 1.1)
local wispParticles = Instance.new("ParticleEmitter")
wispParticles.Name = "WispSparkles"
wispParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
wispParticles.Color = ColorSequence.new(palette.lilacLight, palette.water)
wispParticles.LightEmission = 0.9
wispParticles.Rate = 7
wispParticles.Lifetime = NumberRange.new(0.45, 0.9)
wispParticles.Speed = NumberRange.new(0.1, 0.45)
wispParticles.SpreadAngle = Vector2.new(180, 180)
wispParticles.Size = NumberSequence.new(0.18, 0)
wispParticles.Parent = wispBody


local crystalHeart = makePart(crystalGrotto, "CrystalGrottoHeart", Vector3.new(2.2, 2.2, 2.2), CFrame.new(grottoCenter + Vector3.new(0, 2.3, 8)), palette.lilacLight, Enum.Material.Neon, Enum.PartType.Ball)
crystalHeart.CanCollide = false
local heartGlow = Instance.new("PointLight")
heartGlow.Color = palette.lilacLight
heartGlow.Range = 20
heartGlow.Brightness = 1.2
heartGlow.Parent = crystalHeart
placeTrialPrompt(crystalHeart, "Сердце кристальной пещеры", "Собрать осколок")

for index = 1, 12 do
    local angle = index * math.pi * 2 / 12
    local radius = index % 2 == 0 and 15 or 18
    local position = grottoCenter + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local height = 3.5 + (index % 3) * 1.4
    local crystal = makePart(
        crystalGrotto, "CrystalGrottoCluster" .. tostring(index),
        Vector3.new(1.7, height, 1.7),
        CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(math.rad((index % 2 == 0 and 1 or -1) * 9), angle, math.rad((index % 3 - 1) * 8)),
        index % 3 == 0 and palette.moon or palette.lilacLight,
        Enum.Material.Neon
    )
    crystal.CanCollide = false
    local glow = Instance.new("PointLight")
    glow.Color = crystal.Color
    glow.Range = 9
    glow.Brightness = 0.45
    glow.Parent = crystal
end

-- A dedicated combat volume keeps the Crystal Grotto encounter isolated from Grove and Rootvault.
local grottoCombatRegion = makePart(
    crystalGrotto,
    "CrystalGrottoCombatRegion",
    Vector3.new(46, 24, 42),
    CFrame.new(grottoCenter + Vector3.new(0, 12, 0)),
    palette.lilac,
    Enum.Material.ForceField,
    nil,
    1
)
grottoCombatRegion.CanCollide = false
grottoCombatRegion.CanTouch = false
grottoCombatRegion.CanQuery = true
grottoCombatRegion:SetAttribute("RegionId", "CrystalGrotto")
CollectionService:AddTag(grottoCombatRegion, "GiantbackCombatRegion")

-- Crystal Warden: a compact but unmistakable crystal-armoured guardian of the grotto.
local function spawnCrystalWarden()

-- Shardling: a fast crystal scavenger that feints before committing to a damaging dash.
local function spawnCrystalShardling()
    if not crystalGrotto.Parent then return end
    local shardling = Instance.new("Model")
    shardling.Name = "CrystalGrottoShardling01"
    shardling:SetAttribute("EnemyId", "CrystalGrottoShardling01")
    shardling:SetAttribute("EncounterId", "CrystalGrottoShardling01")
    shardling:SetAttribute("RegionId", "CrystalGrotto")
    shardling:SetAttribute("ArchetypeId", "Shardling")
    shardling:SetAttribute("CombatState", "Idle")
    shardling:SetAttribute("AggroRange", 28)
    shardling:SetAttribute("AttackRange", 6)
    shardling:SetAttribute("AttackDamage", 7)
    shardling:SetAttribute("AttackCooldown", 2.65)
    shardling:SetAttribute("TelegraphSeconds", 0.9)
    shardling:SetAttribute("PathRefreshSeconds", 0.72)
    shardling:SetAttribute("ShardlingDashRange", 14)
    shardling:SetAttribute("ShardlingDashDamage", 13)
    shardling.Parent = crystalGrotto

    local spawnPosition = grottoCenter + Vector3.new(-13, 3, 8)
    local root = makeEnemyPart(
        shardling, "HumanoidRootPart", Vector3.new(1.7, 1.9, 1),
        CFrame.lookAt(spawnPosition, spawnPosition + Vector3.new(1, 0, -0.4)), palette.ink
    )
    root.Transparency = 1
    root.Massless = false
    local torso = makeEnemyPart(
        shardling, "Torso", Vector3.new(1.65, 1.8, 1.2),
        root.CFrame, palette.lilac, Enum.Material.Slate, Enum.PartType.Ball
    )
    torso.CanCollide = true
    local head = makeEnemyPart(
        shardling, "Head", Vector3.new(1.15, 1.05, 1.05),
        root.CFrame * CFrame.new(0, 1.35, -0.08), palette.lilacLight, Enum.Material.Slate, Enum.PartType.Ball
    )
    local rightArm = makeEnemyPart(
        shardling, "Right Arm", Vector3.new(0.55, 1.45, 0.65),
        root.CFrame * CFrame.new(1.0, 0.05, 0), palette.stone, Enum.Material.Slate, Enum.PartType.Ball
    )
    local leftArm = makeEnemyPart(
        shardling, "Left Arm", Vector3.new(0.55, 1.45, 0.65),
        root.CFrame * CFrame.new(-1.0, 0.05, 0), palette.stone, Enum.Material.Slate, Enum.PartType.Ball
    )
    local rightLeg = makeEnemyPart(
        shardling, "Right Leg", Vector3.new(0.62, 1.25, 0.72),
        root.CFrame * CFrame.new(0.43, -1.25, 0), palette.ink, Enum.Material.Slate, Enum.PartType.Ball
    )
    local leftLeg = makeEnemyPart(
        shardling, "Left Leg", Vector3.new(0.62, 1.25, 0.72),
        root.CFrame * CFrame.new(-0.43, -1.25, 0), palette.ink, Enum.Material.Slate, Enum.PartType.Ball
    )

    joinRig(shardling, "RootJoint", root, torso, CFrame.new(), CFrame.new())
    joinRig(shardling, "Neck", torso, head, CFrame.new(0, 0.9, 0), CFrame.new(0, -0.55, 0))
    joinRig(shardling, "Right Shoulder", torso, rightArm, CFrame.new(0.82, 0.48, 0), CFrame.new(0, 0.48, 0))
    joinRig(shardling, "Left Shoulder", torso, leftArm, CFrame.new(-0.82, 0.48, 0), CFrame.new(0, 0.48, 0))
    joinRig(shardling, "Right Hip", torso, rightLeg, CFrame.new(0.42, -0.75, 0), CFrame.new(0, 0.6, 0))
    joinRig(shardling, "Left Hip", torso, leftLeg, CFrame.new(-0.42, -0.75, 0), CFrame.new(0, 0.6, 0))

    local function addShardlingCrystal(name, size, frame, color, parentPart, shape)
        local shard = makeEnemyPart(shardling, name, size, frame, color, Enum.Material.Neon, shape or Enum.PartType.Wedge)
        shard.CanQuery = false
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = parentPart
        weld.Part1 = shard
        weld.Parent = shard
        return shard
    end

    local core = addShardlingCrystal(
        "Shardling core", Vector3.new(0.48, 0.58, 0.3),
        torso.CFrame * CFrame.new(0, 0.02, -0.59), palette.water, torso, Enum.PartType.Ball
    )
    addLight(core, palette.water, 8, 0.6)
    for index = 1, 4 do
        local side = index % 2 == 0 and 1 or -1
        local shard = addShardlingCrystal(
            "Back shard " .. tostring(index),
            Vector3.new(0.48, 1.25 + (index % 2) * 0.35, 0.5),
            torso.CFrame * CFrame.new(side * (0.42 + math.floor((index - 1) / 2) * 0.22), 0.72 - (index % 2) * 0.24, 0.42)
                * CFrame.Angles(math.rad(-18), 0, math.rad(side * 18)),
            index % 2 == 0 and palette.moon or palette.lilacLight,
            torso
        )
        addLight(shard, shard.Color, 4, 0.2)
    end
    for side = -1, 1, 2 do
        local eye = addShardlingCrystal(
            side < 0 and "Left eye" or "Right eye",
            Vector3.new(0.12, 0.16, 0.08),
            head.CFrame * CFrame.new(side * 0.25, 0.06, -0.49),
            palette.gold, head, Enum.PartType.Ball
        )
        addLight(eye, palette.gold, 3, 0.2)
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "Осколочник"
    humanoid.MaxHealth = 72
    humanoid.Health = 72
    humanoid.WalkSpeed = 12
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = shardling
    shardling.PrimaryPart = root
    humanoid.Died:Connect(function()
        task.delay(3, function()
            if shardling.Parent then shardling:Destroy() end
        end)
        task.delay(25, function()
            if crystalGrotto.Parent then spawnCrystalShardling() end
        end)
    end)

    CollectionService:AddTag(shardling, "GiantbackEnemy")
    root:SetNetworkOwner(nil)
end
spawnCrystalShardling()
    if not crystalGrotto.Parent then return end
    local warden = Instance.new("Model")
    warden.Name = "CrystalGrottoWarden01"
    warden:SetAttribute("EnemyId", "CrystalGrottoWarden01")
    warden:SetAttribute("EncounterId", "CrystalGrottoWarden01")
    warden:SetAttribute("RegionId", "CrystalGrotto")
    warden:SetAttribute("ArchetypeId", "CrystalWarden")
    warden:SetAttribute("CombatState", "Idle")
    warden:SetAttribute("AggroRange", 30)
    warden:SetAttribute("AttackRange", 16)
    warden:SetAttribute("AttackDamage", 10)
    warden:SetAttribute("AttackCooldown", 3.2)
    warden:SetAttribute("TelegraphSeconds", 1.2)
    warden:SetAttribute("PathRefreshSeconds", 1.0)
    warden:SetAttribute("CrystalFanRange", 16)
    warden:SetAttribute("CrystalFanDamage", 16)
    warden:SetAttribute("CrystalFanDot", 0.72)
    warden.Parent = crystalGrotto

    local spawnPosition = grottoCenter + Vector3.new(0, 3, 3)
    local root = makeEnemyPart(warden, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.lookAt(spawnPosition, spawnPosition + Vector3.new(0, 0, -1)), palette.ink)
    root.Transparency = 1
    root.Massless = false
    local torso = makeEnemyPart(warden, "Torso", Vector3.new(2.5, 2.6, 1.65), root.CFrame, palette.stone, Enum.Material.Slate, Enum.PartType.Ball)
    torso.CanCollide = true
    local head = makeEnemyPart(warden, "Head", Vector3.new(1.55, 1.5, 1.45), root.CFrame * CFrame.new(0, 1.9, -0.04), palette.lilac, Enum.Material.Slate, Enum.PartType.Ball)
    local rightArm = makeEnemyPart(warden, "Right Arm", Vector3.new(0.9, 2.1, 1), root.CFrame * CFrame.new(1.55, 0, 0), palette.stone, Enum.Material.Slate)
    local leftArm = makeEnemyPart(warden, "Left Arm", Vector3.new(0.9, 2.1, 1), root.CFrame * CFrame.new(-1.55, 0, 0), palette.stone, Enum.Material.Slate)
    local rightLeg = makeEnemyPart(warden, "Right Leg", Vector3.new(0.95, 1.9, 1), root.CFrame * CFrame.new(0.58, -2, 0), palette.ink, Enum.Material.Slate)
    local leftLeg = makeEnemyPart(warden, "Left Leg", Vector3.new(0.95, 1.9, 1), root.CFrame * CFrame.new(-0.58, -2, 0), palette.ink, Enum.Material.Slate)
    rightLeg.CanCollide = true
    leftLeg.CanCollide = true

    joinRig(warden, "RootJoint", root, torso, CFrame.new(), CFrame.new())
    joinRig(warden, "Neck", torso, head, CFrame.new(0, 1.25, 0), CFrame.new(0, -0.72, 0))
    joinRig(warden, "Right Shoulder", torso, rightArm, CFrame.new(1.2, 0.7, 0), CFrame.new(0, 0.7, 0))
    joinRig(warden, "Left Shoulder", torso, leftArm, CFrame.new(-1.2, 0.7, 0), CFrame.new(0, 0.7, 0))
    joinRig(warden, "Right Hip", torso, rightLeg, CFrame.new(0.58, -1.05, 0), CFrame.new(0, 0.95, 0))
    joinRig(warden, "Left Hip", torso, leftLeg, CFrame.new(-0.58, -1.05, 0), CFrame.new(0, 0.95, 0))

    local function addWardenCrystal(name, size, frame, color, parentPart, shape)
        local shard = makeEnemyPart(warden, name, size, frame, color, Enum.Material.Neon, shape or Enum.PartType.Wedge)
        shard.CanQuery = false
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = parentPart
        weld.Part1 = shard
        weld.Parent = shard
        return shard
    end

    local core = addWardenCrystal("Warden prism core", Vector3.new(0.72, 0.95, 0.35), torso.CFrame * CFrame.new(0, 0.05, -0.82), palette.moon, torso, Enum.PartType.Ball)
    addLight(core, palette.moon, 12, 0.9)
    for index = 1, 5 do
        local angle = math.rad(-48 + (index - 1) * 24)
        local shard = addWardenCrystal(
            "Crown crystal " .. tostring(index),
            Vector3.new(0.62, 1.9 + (index % 2) * 0.45, 0.58),
            head.CFrame * CFrame.new(math.sin(angle) * 0.72, 0.95 + (index == 3 and 0.22 or 0), 0) * CFrame.Angles(0, 0, -angle),
            index % 2 == 0 and palette.water or palette.lilacLight,
            head
        )
        addLight(shard, shard.Color, 5, 0.25)
    end
    for side = -1, 1, 2 do
        addWardenCrystal(
            side < 0 and "Left shoulder prism" or "Right shoulder prism",
            Vector3.new(0.8, 1.65, 1.1),
            torso.CFrame * CFrame.new(side * 1.05, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-side * 18)),
            palette.lilacLight,
            torso
        )
        local eye = addWardenCrystal(
            side < 0 and "Left cyan eye" or "Right cyan eye",
            Vector3.new(0.16, 0.2, 0.1),
            head.CFrame * CFrame.new(side * 0.34, 0.05, -0.68),
            palette.water,
            head,
            Enum.PartType.Ball
        )
        addLight(eye, palette.water, 4, 0.35)
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "Кристальный страж"
    humanoid.MaxHealth = 130
    humanoid.Health = 130
    humanoid.WalkSpeed = 7.5
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = warden
    warden.PrimaryPart = root
    humanoid.Died:Connect(function()
        task.delay(3, function()
            if warden.Parent then warden:Destroy() end
        end)
        task.delay(30, function()
            if crystalGrotto.Parent then spawnCrystalWarden() end
        end)
    end)

    CollectionService:AddTag(warden, "GiantbackEnemy")
    root:SetNetworkOwner(nil)
end
spawnCrystalWarden()


local grottoEntrance = makePart(
    workspace.Dusk, "CrystalGrottoEntrance", Vector3.new(5.5, 6.5, 1.5),
    CFrame.new(83, 15, -190), palette.lilacLight, Enum.Material.ForceField
)
grottoEntrance.CanCollide = false
grottoEntrance.Transparency = 0.22
placeTrialPrompt(grottoEntrance, "Запечатанная кристальная пещера", "Исследовать")
local entranceGlow = Instance.new("PointLight")
entranceGlow.Color = palette.lilacLight
entranceGlow.Range = 14
entranceGlow.Brightness = 0.8
entranceGlow.Parent = grottoEntrance

-- Rootvault is its own combat region; players do not need to stand in the Grove arena.
local rootvaultRegion = makePart(
    rootvault,
    "RootvaultCombatRegion",
    Vector3.new(38, 24, 112),
    CFrame.new(0, 13, 300),
    palette.lilac,
    Enum.Material.ForceField,
    nil,
    1
)
rootvaultRegion.CanCollide = false
rootvaultRegion.CanTouch = false
rootvaultRegion.CanQuery = true
rootvaultRegion:SetAttribute("RegionId", "Rootvault")
CollectionService:AddTag(rootvaultRegion, "GiantbackCombatRegion")

-- A distinct R6 Rootvault sentinel guards the mechanism room and drops its key.
local sentinel = Instance.new("Model")
sentinel.Name = "RootvaultSentinel01"
sentinel:SetAttribute("EnemyId", "RootvaultSentinel01")
sentinel:SetAttribute("EncounterId", "RootvaultSentinel01")
sentinel:SetAttribute("RegionId", "Rootvault")
sentinel:SetAttribute("ArchetypeId", "VaultWarden")
sentinel:SetAttribute("AggroRange", 28)
sentinel:SetAttribute("AttackRange", 5.5)
sentinel:SetAttribute("AttackDamage", 16)
sentinel:SetAttribute("AttackCooldown", 2.8)
sentinel:SetAttribute("TelegraphSeconds", 1.05)
sentinel:SetAttribute("PathRefreshSeconds", 1.0)
sentinel.Parent = rootvault
local sentinelSpawn = mechanismRoomCenter + Vector3.new(0, 3, -4)
local sentinelRoot = makeEnemyPart(sentinel, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.lookAt(sentinelSpawn, sentinelSpawn + Vector3.new(0, 0, 1)), palette.ink)
sentinelRoot.Transparency = 1
sentinelRoot.Massless = false
local sentinelTorso = makeEnemyPart(sentinel, "Torso", Vector3.new(2.3, 2.5, 1.35), sentinelRoot.CFrame, palette.stone, Enum.Material.Slate)
local sentinelHead = makeEnemyPart(sentinel, "Head", Vector3.new(1.6, 1.5, 1.5), sentinelRoot.CFrame * CFrame.new(0, 1.9, 0), palette.lilac, Enum.Material.Slate, Enum.PartType.Ball)
local sentinelRightArm = makeEnemyPart(sentinel, "Right Arm", Vector3.new(0.9, 2.1, 1), sentinelRoot.CFrame * CFrame.new(1.5, 0, 0), palette.stone, Enum.Material.Slate)
local sentinelLeftArm = makeEnemyPart(sentinel, "Left Arm", Vector3.new(0.9, 2.1, 1), sentinelRoot.CFrame * CFrame.new(-1.5, 0, 0), palette.stone, Enum.Material.Slate)
local sentinelRightLeg = makeEnemyPart(sentinel, "Right Leg", Vector3.new(0.95, 2, 1), sentinelRoot.CFrame * CFrame.new(0.55, -2, 0), palette.ink, Enum.Material.Slate)
local sentinelLeftLeg = makeEnemyPart(sentinel, "Left Leg", Vector3.new(0.95, 2, 1), sentinelRoot.CFrame * CFrame.new(-0.55, -2, 0), palette.ink, Enum.Material.Slate)
joinRig(sentinel, "RootJoint", sentinelRoot, sentinelTorso, CFrame.new(), CFrame.new())
joinRig(sentinel, "Neck", sentinelTorso, sentinelHead, CFrame.new(0, 1.2, 0), CFrame.new(0, -0.75, 0))
joinRig(sentinel, "Right Shoulder", sentinelTorso, sentinelRightArm, CFrame.new(1.15, 0.7, 0), CFrame.new(0, 0.7, 0))
joinRig(sentinel, "Left Shoulder", sentinelTorso, sentinelLeftArm, CFrame.new(-1.15, 0.7, 0), CFrame.new(0, 0.7, 0))
joinRig(sentinel, "Right Hip", sentinelTorso, sentinelRightLeg, CFrame.new(0.55, -1.1, 0), CFrame.new(0, 1, 0))
joinRig(sentinel, "Left Hip", sentinelTorso, sentinelLeftLeg, CFrame.new(-0.55, -1.1, 0), CFrame.new(0, 1, 0))
local sentinelEyes = {}
for side = -1, 1, 2 do
    local eye = makeEnemyPart(sentinel, "VioletEye", Vector3.new(0.22, 0.22, 0.12), sentinelHead.CFrame * CFrame.new(side * 0.36, 0.1, -0.68), palette.lilacLight, Enum.Material.Neon, Enum.PartType.Ball)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = sentinelHead
    weld.Part1 = eye
    weld.Parent = eye
    addLight(eye, palette.lilacLight, 5, 0.35)
end
local sentinelHumanoid = Instance.new("Humanoid")
sentinelHumanoid.DisplayName = "Страж хранилища"
sentinelHumanoid.MaxHealth = 145
sentinelHumanoid.Health = 145
sentinelHumanoid.WalkSpeed = 8
sentinelHumanoid.JumpPower = 0
sentinelHumanoid.BreakJointsOnDeath = false
sentinelHumanoid.RequiresNeck = true
sentinelHumanoid.Parent = sentinel
sentinel.PrimaryPart = sentinelRoot
sentinelRoot:SetNetworkOwner(nil)
CollectionService:AddTag(sentinel, "GiantbackEnemy")

-- A quick Rootvault prowler pressures players in the entry chamber.
local stalker = Instance.new("Model")
stalker.Name = "RootvaultStalker01"
stalker:SetAttribute("EnemyId", "RootvaultStalker01")
stalker:SetAttribute("EncounterId", "RootvaultStalker01")
stalker:SetAttribute("RegionId", "Rootvault")
stalker:SetAttribute("ArchetypeId", "VaultStalker")
stalker:SetAttribute("AggroRange", 26)
stalker:SetAttribute("AttackRange", 4.5)
stalker:SetAttribute("AttackDamage", 8)
stalker:SetAttribute("AttackCooldown", 1.8)
stalker:SetAttribute("TelegraphSeconds", 0.55)
stalker:SetAttribute("PathRefreshSeconds", 0.7)
stalker.Parent = rootvault

local stalkerSpawn = entryRoomCenter + Vector3.new(-8, 3, 5)
local stalkerRoot = makeEnemyPart(stalker, "HumanoidRootPart", Vector3.new(1.6, 1.8, 0.9), CFrame.lookAt(stalkerSpawn, stalkerSpawn + Vector3.new(1, 0, 0)), palette.ink)
stalkerRoot.Transparency = 1
stalkerRoot.Massless = false
local stalkerTorso = makeEnemyPart(stalker, "Torso", Vector3.new(1.55, 1.9, 0.9), stalkerRoot.CFrame, palette.moss, Enum.Material.Grass)
local stalkerHead = makeEnemyPart(stalker, "Head", Vector3.new(1.15, 1.05, 1.05), stalkerRoot.CFrame * CFrame.new(0, 1.35, 0), palette.mossLight, Enum.Material.Grass, Enum.PartType.Ball)
local stalkerRightArm = makeEnemyPart(stalker, "Right Arm", Vector3.new(0.55, 1.5, 0.65), stalkerRoot.CFrame * CFrame.new(1.0, 0, 0), palette.moss, Enum.Material.Grass)
local stalkerLeftArm = makeEnemyPart(stalker, "Left Arm", Vector3.new(0.55, 1.5, 0.65), stalkerRoot.CFrame * CFrame.new(-1.0, 0, 0), palette.moss, Enum.Material.Grass)
local stalkerRightLeg = makeEnemyPart(stalker, "Right Leg", Vector3.new(0.62, 1.45, 0.7), stalkerRoot.CFrame * CFrame.new(0.38, -1.55, 0), palette.stone, Enum.Material.Slate)
local stalkerLeftLeg = makeEnemyPart(stalker, "Left Leg", Vector3.new(0.62, 1.45, 0.7), stalkerRoot.CFrame * CFrame.new(-0.38, -1.55, 0), palette.stone, Enum.Material.Slate)
joinRig(stalker, "RootJoint", stalkerRoot, stalkerTorso, CFrame.new(), CFrame.new())
joinRig(stalker, "Neck", stalkerTorso, stalkerHead, CFrame.new(0, 0.95, 0), CFrame.new(0, -0.52, 0))
joinRig(stalker, "Right Shoulder", stalkerTorso, stalkerRightArm, CFrame.new(0.8, 0.55, 0), CFrame.new(0, 0.55, 0))
joinRig(stalker, "Left Shoulder", stalkerTorso, stalkerLeftArm, CFrame.new(-0.8, 0.55, 0), CFrame.new(0, 0.55, 0))
joinRig(stalker, "Right Hip", stalkerTorso, stalkerRightLeg, CFrame.new(0.38, -0.85, 0), CFrame.new(0, 0.72, 0))
joinRig(stalker, "Left Hip", stalkerTorso, stalkerLeftLeg, CFrame.new(-0.38, -0.85, 0), CFrame.new(0, 0.72, 0))

for side = -1, 1, 2 do
    local eye = makeEnemyPart(stalker, "MintEye", Vector3.new(0.16, 0.16, 0.1), stalkerHead.CFrame * CFrame.new(side * 0.25, 0.05, -0.49), palette.moon, Enum.Material.Neon, Enum.PartType.Ball)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = stalkerHead
    weld.Part1 = eye
    weld.Parent = eye
    addLight(eye, palette.moon, 3, 0.25)
end

for index = 1, 3 do
    local thorn = makeEnemyPart(stalker, "BackRootThorn", Vector3.new(0.22, 0.9, 0.25), stalkerTorso.CFrame * CFrame.new((index - 2) * 0.42, 0.35, 0.55) * CFrame.Angles(math.rad(-18), 0, math.rad(12)), palette.barkLight, Enum.Material.Wood)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = stalkerTorso
    weld.Part1 = thorn
    weld.Parent = thorn
end

local stalkerHumanoid = Instance.new("Humanoid")
stalkerHumanoid.DisplayName = "Корневой охотник"
stalkerHumanoid.MaxHealth = 75
stalkerHumanoid.Health = 75
stalkerHumanoid.WalkSpeed = 15
stalkerHumanoid.JumpPower = 0
stalkerHumanoid.BreakJointsOnDeath = false
stalkerHumanoid.RequiresNeck = true
stalkerHumanoid.Parent = stalker
stalker.PrimaryPart = stalkerRoot
stalkerRoot:SetNetworkOwner(nil)
CollectionService:AddTag(stalker, "GiantbackEnemy")


-- Final guardian of the first Rootvault expedition: a three-phase Seal Keeper.
local sealKeeper = Instance.new("Model")
sealKeeper.Name = "RootvaultSealKeeper01"
sealKeeper:SetAttribute("EnemyId", "RootvaultSealKeeper01")
sealKeeper:SetAttribute("EncounterId", "RootvaultSealKeeper01")
sealKeeper:SetAttribute("RegionId", "Rootvault")
sealKeeper:SetAttribute("ArchetypeId", "SealKeeper")
sealKeeper:SetAttribute("IsBoss", true)
sealKeeper:SetAttribute("AggroRange", 34)
sealKeeper:SetAttribute("AttackRange", 7)
sealKeeper:SetAttribute("AttackDamage", 14)
sealKeeper:SetAttribute("AttackCooldown", 3.1)
sealKeeper:SetAttribute("TelegraphSeconds", 1.15)
sealKeeper:SetAttribute("PathRefreshSeconds", 1.1)
sealKeeper:SetAttribute("Phase2WalkSpeed", 9)
sealKeeper:SetAttribute("Phase2AttackDamage", 18)
sealKeeper:SetAttribute("Phase2AttackCooldown", 2.5)
sealKeeper:SetAttribute("Phase2TelegraphSeconds", 0.9)
sealKeeper:SetAttribute("Phase2PathRefreshSeconds", 0.85)
sealKeeper:SetAttribute("Phase2SlamRadius", 15)
sealKeeper:SetAttribute("Phase2SlamDamage", 16)
sealKeeper:SetAttribute("Phase3WalkSpeed", 12)
sealKeeper:SetAttribute("Phase3AttackDamage", 22)
sealKeeper:SetAttribute("Phase3AttackCooldown", 1.9)
sealKeeper:SetAttribute("Phase3TelegraphSeconds", 0.65)
sealKeeper:SetAttribute("Phase3PathRefreshSeconds", 0.65)
sealKeeper:SetAttribute("Phase3SlamRadius", 19)
sealKeeper:SetAttribute("Phase3SlamDamage", 22)
sealKeeper.Parent = rootvault

local keeperSpawn = rewardRoomCenter + Vector3.new(0, 4, -2)
local keeperRoot = makeEnemyPart(sealKeeper, "HumanoidRootPart", Vector3.new(3, 3, 2), CFrame.lookAt(keeperSpawn, keeperSpawn + Vector3.new(0, 0, 1)), palette.ink)
keeperRoot.Transparency = 1
keeperRoot.Massless = false
local keeperTorso = makeEnemyPart(sealKeeper, "Torso", Vector3.new(4, 4.2, 2.5), keeperRoot.CFrame, palette.stone, Enum.Material.Slate)
local keeperHead = makeEnemyPart(sealKeeper, "Head", Vector3.new(2.4, 2.3, 2.2), keeperRoot.CFrame * CFrame.new(0, 3.1, 0), palette.lilac, Enum.Material.Slate, Enum.PartType.Ball)
local keeperRightArm = makeEnemyPart(sealKeeper, "Right Arm", Vector3.new(1.5, 3.6, 1.6), keeperRoot.CFrame * CFrame.new(2.6, 0, 0), palette.stone, Enum.Material.Slate)
local keeperLeftArm = makeEnemyPart(sealKeeper, "Left Arm", Vector3.new(1.5, 3.6, 1.6), keeperRoot.CFrame * CFrame.new(-2.6, 0, 0), palette.stone, Enum.Material.Slate)
local keeperRightLeg = makeEnemyPart(sealKeeper, "Right Leg", Vector3.new(1.6, 3, 1.7), keeperRoot.CFrame * CFrame.new(1.0, -3.1, 0), palette.ink, Enum.Material.Slate)
local keeperLeftLeg = makeEnemyPart(sealKeeper, "Left Leg", Vector3.new(1.6, 3, 1.7), keeperRoot.CFrame * CFrame.new(-1.0, -3.1, 0), palette.ink, Enum.Material.Slate)
joinRig(sealKeeper, "RootJoint", keeperRoot, keeperTorso, CFrame.new(), CFrame.new())
joinRig(sealKeeper, "Neck", keeperTorso, keeperHead, CFrame.new(0, 2.0, 0), CFrame.new(0, -1.15, 0))
joinRig(sealKeeper, "Right Shoulder", keeperTorso, keeperRightArm, CFrame.new(2.0, 1.25, 0), CFrame.new(0, 1.25, 0))
joinRig(sealKeeper, "Left Shoulder", keeperTorso, keeperLeftArm, CFrame.new(-2.0, 1.25, 0), CFrame.new(0, 1.25, 0))
joinRig(sealKeeper, "Right Hip", keeperTorso, keeperRightLeg, CFrame.new(1.0, -1.9, 0), CFrame.new(0, 1.45, 0))
joinRig(sealKeeper, "Left Hip", keeperTorso, keeperLeftLeg, CFrame.new(-1.0, -1.9, 0), CFrame.new(0, 1.45, 0))

local keeperCore = makeEnemyPart(sealKeeper, "SealCore", Vector3.new(1.45, 1.45, 0.45), keeperTorso.CFrame * CFrame.new(0, 0.15, -1.35), palette.lilacLight, Enum.Material.Neon, Enum.PartType.Ball)
local coreWeld = Instance.new("WeldConstraint")
coreWeld.Part0 = keeperTorso
coreWeld.Part1 = keeperCore
coreWeld.Parent = keeperCore
addLight(keeperCore, palette.lilacLight, 12, 0.9)

for side = -1, 1, 2 do
    local eye = makeEnemyPart(sealKeeper, "SealEye", Vector3.new(0.28, 0.28, 0.16), keeperHead.CFrame * CFrame.new(side * 0.55, 0.18, -1.02), palette.gold, Enum.Material.Neon, Enum.PartType.Ball)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = keeperHead
    weld.Part1 = eye
    weld.Parent = eye
    addLight(eye, palette.gold, 6, 0.4)
end

for side = -1, 1, 2 do
    local shoulder = makeEnemyPart(sealKeeper, "SealShoulderPlate", Vector3.new(2.0, 1.0, 2.0), keeperTorso.CFrame * CFrame.new(side * 2.0, 1.55, 0), palette.bark, Enum.Material.Slate)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = keeperTorso
    weld.Part1 = shoulder
    weld.Parent = shoulder
end

local keeperHumanoid = Instance.new("Humanoid")
keeperHumanoid.DisplayName = "Страж печатей"
keeperHumanoid.MaxHealth = 360
keeperHumanoid.Health = 360
keeperHumanoid.WalkSpeed = 7
keeperHumanoid.JumpPower = 0
keeperHumanoid.BreakJointsOnDeath = false
keeperHumanoid.RequiresNeck = true
keeperHumanoid.Parent = sealKeeper
sealKeeper.PrimaryPart = keeperRoot
keeperRoot:SetNetworkOwner(nil)
CollectionService:AddTag(sealKeeper, "GiantbackEnemy")

-- Two dormant seal fragments awaken only when the keeper reaches phase three.
for index, side in {-1, 1} do
    local minion = Instance.new("Model")
    minion.Name = "RootvaultSealMinion0" .. tostring(index)
    minion:SetAttribute("EnemyId", minion.Name)
    minion:SetAttribute("EncounterId", "RootvaultSealMinion")
    minion:SetAttribute("RegionId", "Rootvault")
    minion:SetAttribute("ArchetypeId", "SealMinion")
    minion:SetAttribute("AggroRange", 28)
    minion:SetAttribute("AttackRange", 4)
    minion:SetAttribute("AttackDamage", 6)
    minion:SetAttribute("AttackCooldown", 1.7)
    minion:SetAttribute("TelegraphSeconds", 0.55)
    minion:SetAttribute("PathRefreshSeconds", 0.7)
    minion:SetAttribute("Activated", false)
    minion.Parent = rootvault

    local spawn = keeperSpawn + Vector3.new(side * 8, 0, 7)
    local minionRoot = makeEnemyPart(minion, "HumanoidRootPart", Vector3.new(1.5, 1.8, 1.2), CFrame.lookAt(spawn, keeperSpawn), palette.ink)
    minionRoot.Transparency = 1
    minionRoot.Massless = false
    local minionTorso = makeEnemyPart(minion, "Torso", Vector3.new(1.5, 1.7, 1.0), minionRoot.CFrame, palette.stone, Enum.Material.Slate)
    local minionHead = makeEnemyPart(minion, "Head", Vector3.new(1.05, 1.0, 0.95), minionRoot.CFrame * CFrame.new(0, 1.25, 0), palette.mossLight, Enum.Material.Slate, Enum.PartType.Ball)
    local minionRightArm = makeEnemyPart(minion, "Right Arm", Vector3.new(0.45, 1.2, 0.5), minionRoot.CFrame * CFrame.new(0.9, 0, 0), palette.stone, Enum.Material.Slate)
    local minionLeftArm = makeEnemyPart(minion, "Left Arm", Vector3.new(0.45, 1.2, 0.5), minionRoot.CFrame * CFrame.new(-0.9, 0, 0), palette.stone, Enum.Material.Slate)
    local minionRightLeg = makeEnemyPart(minion, "Right Leg", Vector3.new(0.5, 1.15, 0.55), minionRoot.CFrame * CFrame.new(0.35, -1.35, 0), palette.bark, Enum.Material.Wood)
    local minionLeftLeg = makeEnemyPart(minion, "Left Leg", Vector3.new(0.5, 1.15, 0.55), minionRoot.CFrame * CFrame.new(-0.35, -1.35, 0), palette.bark, Enum.Material.Wood)
    joinRig(minion, "RootJoint", minionRoot, minionTorso, CFrame.new(), CFrame.new())
    joinRig(minion, "Neck", minionTorso, minionHead, CFrame.new(0, 0.85, 0), CFrame.new(0, -0.48, 0))
    joinRig(minion, "Right Shoulder", minionTorso, minionRightArm, CFrame.new(0.75, 0.45, 0), CFrame.new(0, 0.45, 0))
    joinRig(minion, "Left Shoulder", minionTorso, minionLeftArm, CFrame.new(-0.75, 0.45, 0), CFrame.new(0, 0.45, 0))
    joinRig(minion, "Right Hip", minionTorso, minionRightLeg, CFrame.new(0.35, -0.75, 0), CFrame.new(0, 0.58, 0))
    joinRig(minion, "Left Hip", minionTorso, minionLeftLeg, CFrame.new(-0.35, -0.75, 0), CFrame.new(0, 0.58, 0))

    local shard = makeEnemyPart(minion, "DormantSealShard", Vector3.new(0.55, 0.55, 0.25), minionTorso.CFrame * CFrame.new(0, 0.1, -0.58), palette.lilac, Enum.Material.Neon, Enum.PartType.Ball)
    local shardWeld = Instance.new("WeldConstraint")
    shardWeld.Part0 = minionTorso
    shardWeld.Part1 = shard
    shardWeld.Parent = shard

    local minionHumanoid = Instance.new("Humanoid")
    minionHumanoid.DisplayName = "Осколок печати"
    minionHumanoid.MaxHealth = 52
    minionHumanoid.Health = 52
    minionHumanoid.WalkSpeed = 13
    minionHumanoid.JumpPower = 0
    minionHumanoid.BreakJointsOnDeath = false
    minionHumanoid.RequiresNeck = true
    minionHumanoid.Parent = minion
    minion.PrimaryPart = minionRoot
    minionRoot:SetNetworkOwner(nil)
    CollectionService:AddTag(minion, "GiantbackDormantBossMinion")
end


-- Harvest Sprite companion template: an original, seasonal creature with its own silhouette.
local harvestSprite = ReplicatedStorage:FindFirstChild("HarvestSprite")
if harvestSprite then harvestSprite:Destroy() end
harvestSprite = Instance.new("Model")
harvestSprite.Name = "HarvestSprite"
harvestSprite:SetAttribute("CompanionId", "HarvestSprite")
harvestSprite:SetAttribute("GiantbackSeasonalCompanion", true)
harvestSprite.Parent = ReplicatedStorage

local spriteBody = orb(
    harvestSprite,
    "Body",
    Vector3.new(0, 0, 0),
    Vector3.new(2.0, 1.72, 1.72),
    Color3.fromRGB(226, 130, 62),
    Enum.Material.SmoothPlastic
)
harvestSprite.PrimaryPart = spriteBody

for ribIndex = 1, 5 do
    local angle = (ribIndex - 1) * math.pi * 2 / 5
    local rib = orb(
        harvestSprite,
        "Pumpkin rib",
        Vector3.new(math.cos(angle) * 0.38, 0, math.sin(angle) * 0.34),
        Vector3.new(0.62, 1.48, 0.72),
        ribIndex % 2 == 0 and Color3.fromRGB(242, 155, 78) or Color3.fromRGB(211, 113, 54),
        Enum.Material.SmoothPlastic
    )
    rib.CFrame = CFrame.new(rib.Position) * CFrame.Angles(0, -angle, 0)
end

local spriteStem = cylinder(
    harvestSprite,
    "Stem",
    Vector3.new(0, 0.88, 0),
    0.42,
    0.22,
    Color3.fromRGB(94, 125, 70),
    Enum.Material.Wood
)
local spriteLeaf = orb(
    harvestSprite,
    "Leaf",
    Vector3.new(0.28, 1.0, 0.05),
    Vector3.new(0.82, 0.16, 0.42),
    Color3.fromRGB(145, 190, 113),
    Enum.Material.Grass
)
spriteLeaf.CFrame = spriteLeaf.CFrame * CFrame.Angles(0, 0, math.rad(-25))

local spriteEyeLeft = orb(
    harvestSprite,
    "Eye left",
    Vector3.new(-0.42, 0.2, -0.77),
    Vector3.new(0.17, 0.21, 0.1),
    Color3.fromRGB(57, 57, 43),
    Enum.Material.SmoothPlastic
)
local spriteEyeRight = orb(
    harvestSprite,
    "Eye right",
    Vector3.new(0.42, 0.2, -0.77),
    Vector3.new(0.17, 0.21, 0.1),
    Color3.fromRGB(57, 57, 43),
    Enum.Material.SmoothPlastic
)
local spriteGlow = orb(
    harvestSprite,
    "Lantern core",
    Vector3.new(0, -0.3, -0.82),
    Vector3.new(0.26, 0.26, 0.12),
    Color3.fromRGB(255, 218, 126),
    Enum.Material.Neon,
    0.08
)
addLight(spriteGlow, Color3.fromRGB(255, 184, 91), 8, 0.8)

local spriteVine = cylinder(
    harvestSprite,
    "Vine tail",
    Vector3.new(0.98, -0.24, 0.24),
    0.8,
    0.13,
    Color3.fromRGB(94, 143, 82),
    Enum.Material.Grass,
    CFrame.Angles(math.rad(90), 0, math.rad(32))
)
local spriteBerry = orb(
    harvestSprite,
    "Berry tail",
    Vector3.new(1.32, -0.24, 0.24),
    Vector3.new(0.28, 0.28, 0.28),
    Color3.fromRGB(202, 91, 73),
    Enum.Material.SmoothPlastic
)


-- Five original Harvest Festival hatchlings. Each has a distinct silhouette and a
-- named Body anchor so the shared follower, friendship and growth systems can use it.
local function beginFestivalHatchling(id, bodyColor, bodySize)
    local existing = ReplicatedStorage:FindFirstChild(id)
    if existing then existing:Destroy() end
    local model = Instance.new("Model")
    model.Name = id
    model:SetAttribute("CompanionId", id)
    model:SetAttribute("GiantbackSeasonalCompanion", true)
    model.Parent = ReplicatedStorage
    local body = orb(model, "Body", Vector3.new(0, 0, 0), bodySize, bodyColor, Enum.Material.SmoothPlastic)
    model.PrimaryPart = body
    return model, body
end

local brambleBun = beginFestivalHatchling("BrambleBun", Color3.fromRGB(178, 130, 91), Vector3.new(1.65, 1.35, 1.65))
orb(brambleBun, "Head", Vector3.new(0, 0.28, -0.67), Vector3.new(1.0, 0.92, 0.82), Color3.fromRGB(205, 163, 119), Enum.Material.SmoothPlastic)
for index = 1, 7 do
    local angle = index * math.pi * 2 / 7
    local spike = orb(brambleBun, "Bramble quill", Vector3.new(math.cos(angle) * 0.62, 0.38 + (index % 2) * 0.2, math.sin(angle) * 0.58), Vector3.new(0.28, 0.42, 0.28), Color3.fromRGB(112, 91, 70), Enum.Material.Wood)
    spike.CFrame *= CFrame.Angles(0, 0, math.cos(angle) * 0.45)
end
orb(brambleBun, "Ear left", Vector3.new(-0.34, 0.83, -0.78), Vector3.new(0.25, 0.68, 0.28), Color3.fromRGB(194, 137, 121), Enum.Material.SmoothPlastic)
orb(brambleBun, "Ear right", Vector3.new(0.34, 0.83, -0.78), Vector3.new(0.25, 0.68, 0.28), Color3.fromRGB(194, 137, 121), Enum.Material.SmoothPlastic)
for _, x in {-0.22, 0.22} do orb(brambleBun, "Eye", Vector3.new(x, 0.34, -1.03), Vector3.new(0.13, 0.16, 0.08), Color3.fromRGB(45, 48, 42), Enum.Material.SmoothPlastic) end
orb(brambleBun, "Acorn cap", Vector3.new(0, 0.94, -0.28), Vector3.new(0.54, 0.3, 0.5), Color3.fromRGB(126, 83, 54), Enum.Material.Wood)
orb(brambleBun, "Acorn leaf", Vector3.new(0.3, 1.08, -0.24), Vector3.new(0.48, 0.12, 0.26), Color3.fromRGB(132, 181, 105), Enum.Material.Grass)

local mossTurtle = beginFestivalHatchling("MossTurtle", Color3.fromRGB(124, 171, 123), Vector3.new(1.9, 0.95, 1.6))
orb(mossTurtle, "Shell", Vector3.new(0, 0.45, 0.06), Vector3.new(1.8, 1.12, 1.56), Color3.fromRGB(89, 127, 91), Enum.Material.Slate)
for index = 1, 5 do
    local angle = index * math.pi * 2 / 5
    orb(mossTurtle, "Shell moss", Vector3.new(math.cos(angle) * 0.55, 0.83, math.sin(angle) * 0.48), Vector3.new(0.35, 0.12, 0.32), Color3.fromRGB(155, 190, 116), Enum.Material.Grass)
end
orb(mossTurtle, "Head", Vector3.new(0, 0.12, -0.98), Vector3.new(0.82, 0.72, 0.78), Color3.fromRGB(149, 190, 137), Enum.Material.SmoothPlastic)
for _, x in {-0.24, 0.24} do orb(mossTurtle, "Eye", Vector3.new(x, 0.28, -1.34), Vector3.new(0.12, 0.14, 0.08), Color3.fromRGB(44, 58, 45), Enum.Material.SmoothPlastic) end
for _, x in {-0.72, 0.72} do
    for _, z in {-0.48, 0.48} do
        orb(mossTurtle, "Foot", Vector3.new(x, -0.34, z), Vector3.new(0.54, 0.34, 0.5), Color3.fromRGB(130, 171, 122), Enum.Material.SmoothPlastic)
    end
end
orb(mossTurtle, "Tail", Vector3.new(0, -0.12, 0.94), Vector3.new(0.34, 0.26, 0.48), Color3.fromRGB(114, 157, 110), Enum.Material.SmoothPlastic)

local glowcap = beginFestivalHatchling("Glowcap", Color3.fromRGB(232, 220, 187), Vector3.new(1.12, 1.28, 1.12))
cylinder(glowcap, "Mushroom stalk", Vector3.new(0, 0.62, 0), 1.0, 0.72, Color3.fromRGB(240, 225, 193), Enum.Material.SmoothPlastic)
orb(glowcap, "Mushroom cap", Vector3.new(0, 1.24, 0), Vector3.new(1.9, 0.78, 1.9), Color3.fromRGB(139, 105, 191), Enum.Material.SmoothPlastic)
for index = 1, 6 do
    local angle = index * math.pi * 2 / 6
    orb(glowcap, "Glowcap spot", Vector3.new(math.cos(angle) * 0.56, 1.53, math.sin(angle) * 0.56), Vector3.new(0.22, 0.1, 0.22), Color3.fromRGB(255, 231, 171), Enum.Material.Neon)
end
for _, x in {-0.22, 0.22} do orb(glowcap, "Eye", Vector3.new(x, 0.38, -0.49), Vector3.new(0.12, 0.15, 0.08), Color3.fromRGB(57, 54, 68), Enum.Material.SmoothPlastic) end
local glowcapCore = orb(glowcap, "Glow core", Vector3.new(0, 0.05, -0.54), Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(205, 238, 169), Enum.Material.Neon)
addLight(glowcapCore, Color3.fromRGB(188, 240, 159), 8, 0.7)

local dewdrop = beginFestivalHatchling("Dewdrop", Color3.fromRGB(117, 195, 205), Vector3.new(1.85, 1.08, 1.28))
orb(dewdrop, "Head", Vector3.new(0, 0.2, -0.54), Vector3.new(1.15, 0.98, 1.0), Color3.fromRGB(145, 218, 220), Enum.Material.SmoothPlastic)
orb(dewdrop, "Fin left", Vector3.new(-0.83, 0.15, 0.08), Vector3.new(0.52, 0.2, 0.56), Color3.fromRGB(94, 177, 192), Enum.Material.SmoothPlastic)
orb(dewdrop, "Fin right", Vector3.new(0.83, 0.15, 0.08), Vector3.new(0.52, 0.2, 0.56), Color3.fromRGB(94, 177, 192), Enum.Material.SmoothPlastic)
for _, x in {-0.25, 0.25} do orb(dewdrop, "Eye", Vector3.new(x, 0.36, -0.98), Vector3.new(0.13, 0.17, 0.08), Color3.fromRGB(42, 73, 83), Enum.Material.SmoothPlastic) end
orb(dewdrop, "Water jewel", Vector3.new(0, 0.84, -0.32), Vector3.new(0.34, 0.42, 0.28), Color3.fromRGB(202, 248, 244), Enum.Material.Neon)
local dewLight = dewdrop:FindFirstChild("Water jewel")
if dewLight then addLight(dewLight, Color3.fromRGB(153, 231, 239), 7, 0.45) end
orb(dewdrop, "Tail fin", Vector3.new(0, 0.12, 0.76), Vector3.new(0.48, 0.22, 0.66), Color3.fromRGB(105, 184, 197), Enum.Material.SmoothPlastic)

local starling = beginFestivalHatchling("Starling", Color3.fromRGB(83, 103, 151), Vector3.new(1.42, 1.62, 1.32))
orb(starling, "Head", Vector3.new(0, 0.78, -0.16), Vector3.new(1.14, 1.0, 1.05), Color3.fromRGB(116, 135, 184), Enum.Material.SmoothPlastic)
orb(starling, "Wing left", Vector3.new(-0.86, 0.05, 0.08), Vector3.new(0.54, 0.94, 0.3), Color3.fromRGB(65, 83, 132), Enum.Material.SmoothPlastic)
orb(starling, "Wing right", Vector3.new(0.86, 0.05, 0.08), Vector3.new(0.54, 0.94, 0.3), Color3.fromRGB(65, 83, 132), Enum.Material.SmoothPlastic)
for _, x in {-0.25, 0.25} do orb(starling, "Eye", Vector3.new(x, 0.88, -0.62), Vector3.new(0.17, 0.2, 0.1), Color3.fromRGB(34, 38, 58), Enum.Material.SmoothPlastic) end
orb(starling, "Beak", Vector3.new(0, 0.57, -0.72), Vector3.new(0.25, 0.25, 0.28), Color3.fromRGB(248, 190, 99), Enum.Material.SmoothPlastic)
orb(starling, "Crest", Vector3.new(0, 1.37, -0.12), Vector3.new(0.34, 0.48, 0.28), Color3.fromRGB(239, 203, 135), Enum.Material.SmoothPlastic)
local starHalo = orb(starling, "Star halo", Vector3.new(0, 1.45, 0.18), Vector3.new(0.16, 0.16, 0.16), Color3.fromRGB(255, 221, 144), Enum.Material.Neon)
addLight(starHalo, Color3.fromRGB(255, 213, 133), 7, 0.5)

-- Let the gameplay bootstrap wait until the collectible models are fully decorated.
local ready = ReplicatedStorage:FindFirstChild("GiantbackVisualsReady") or Instance.new("BoolValue")
ready.Name = "GiantbackVisualsReady"
ready.Value = true
ready.Parent = ReplicatedStorage
