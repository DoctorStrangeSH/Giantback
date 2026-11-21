-- Giantback visual pass: handcrafted details, warm lighting and bioluminescent accents.
-- All geometry is original and generated from Roblox primitives; no external asset dependency.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local giant = workspace:WaitForChild("Mossback")
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

local lagoon = workspace:FindFirstChild("Lagoon")
if lagoon and lagoon:IsA("BasePart") then
    lagoon.Material = Enum.Material.Glass
    lagoon.Color = palette.water
    lagoon.Transparency = 0.2
    lagoon.Reflectance = 0.12
end

local details = makeFolder(workspace, "GiantbackWorldDetails")

-- Give the giant a recognisable silhouette and a lived-in home.
local giantDetails = makeFolder(giant, "HandcraftedDetails")
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
    orb(giantDetails, "Shell mosaic", position, Vector3.new(8.2, 1.15, 8.1), shellColors[(i - 1) % #shellColors + 1], Enum.Material.Grass)
end
for i = 1, 12 do
    local angle = (math.pi * 2 * i / 12)
    local position = Vector3.new(math.cos(angle) * 17.5, 6.1, math.sin(angle) * 14)
    orb(giantDetails, "Shell moss", position, Vector3.new(3.2, 1.2, 3.2), i % 2 == 0 and palette.mossLight or palette.moss, Enum.Material.Grass)
end
orb(giantDetails, "Mossback tail", Vector3.new(-22, 3.8, 0), Vector3.new(7, 4, 5), palette.moss, Enum.Material.SmoothPlastic)
orb(giantDetails, "Mossback snout", Vector3.new(27, 6.4, 0), Vector3.new(5.2, 3.8, 6.8), palette.mossLight, Enum.Material.SmoothPlastic)
orb(giantDetails, "Nose", Vector3.new(29.5, 7.1, 0), Vector3.new(1.05, 0.8, 1.8), palette.ink, Enum.Material.SmoothPlastic)
for _, side in {-1, 1} do
    orb(giantDetails, "Cheek", Vector3.new(25.2, 5.7, side * 5.4), Vector3.new(2.3, 1.4, 1.2), Color3.fromRGB(151, 190, 143), Enum.Material.SmoothPlastic)
    orb(giantDetails, "Flipper toe", Vector3.new(13, -0.8, side * 14), Vector3.new(3.2, 1.7, 2.2), palette.mossLight, Enum.Material.SmoothPlastic)
end

-- Cottage details: door, shutters, porch, chimney and warm windows.
local cottage = makeFolder(giantDetails, "CottageDetails")
makePart(cottage, "Front door", Vector3.new(2, 4.2, 0.3), CFrame.new(-9, 14.2, -2.25), Color3.fromRGB(121, 83, 63), Enum.Material.WoodPlanks)
makePart(cottage, "Door inset", Vector3.new(1.25, 2.6, 0.12), CFrame.new(-9, 14.2, -2.08), Color3.fromRGB(153, 108, 75), Enum.Material.Wood)
orb(cottage, "Door handle", Vector3.new(-8.25, 14.2, -1.98), Vector3.new(0.22, 0.22, 0.22), palette.gold, Enum.Material.Metal)
for _, x in {-11.6, -6.4} do
    makePart(cottage, "Window shutter", Vector3.new(0.8, 2.8, 0.3), CFrame.new(x, 15.1, -2.38), palette.coral, Enum.Material.WoodPlanks)
    makePart(cottage, "Shutter hinge", Vector3.new(0.12, 2.8, 0.12), CFrame.new(x, 15.1, -2.2), palette.bark, Enum.Material.Wood)
end
makePart(cottage, "Porch step", Vector3.new(4.8, 0.45, 1.6), CFrame.new(-9, 12.45, -1.1), palette.barkLight, Enum.Material.WoodPlanks)
for _, x in {-11.8, -6.2} do
    cylinder(cottage, "Porch post", Vector3.new(x, 14, -0.8), 3.2, 0.35, palette.barkLight, Enum.Material.Wood)
    orb(cottage, "Porch post cap", Vector3.new(x, 15.7, -0.8), Vector3.new(0.6, 0.35, 0.6), palette.gold, Enum.Material.Wood)
end
makePart(cottage, "Chimney", Vector3.new(2, 4.8, 2), CFrame.new(-5.6, 21, -8.2), Color3.fromRGB(166, 104, 83), Enum.Material.Brick)
makePart(cottage, "Chimney cap", Vector3.new(2.5, 0.35, 2.5), CFrame.new(-5.6, 23.45, -8.2), palette.cream, Enum.Material.Slate)
local windowGlow = orb(cottage, "Window glow", Vector3.new(-9, 15, -2.25), Vector3.new(1.9, 1.4, 0.12), palette.gold, Enum.Material.Neon, 0.12)
addLight(windowGlow, palette.gold, 9, 0.65)

-- A clear, welcoming deck with small details that make the home feel inhabited.
local deck = makeFolder(giantDetails, "DeckDetails")
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

-- Turn the two simple banks into distinct little places.
local function decorateIsland(island, isDusk)
    local islandDetails = makeFolder(island, "HandcraftedDetails")
    local centerX = island.Bank.Position.X
    local groundColor = isDusk and Color3.fromRGB(154, 143, 177) or Color3.fromRGB(143, 181, 126)
    makePart(islandDetails, "Soft ground cover", Vector3.new(43.5, 0.18, 38.5), CFrame.new(centerX, 11.62, -40), groundColor, Enum.Material.Grass)

    -- Rock shelves soften the rectangular island silhouette.
    for i = 1, 9 do
        local angle = i * math.pi * 2 / 9
        local x = centerX + math.cos(angle) * 20
        local z = -40 + math.sin(angle) * 16
        orb(islandDetails, "Weathered cliff rock", Vector3.new(x, 4.1, z), Vector3.new(7, 5.5, 6), isDusk and Color3.fromRGB(104, 97, 132) or palette.stone, Enum.Material.Rock)
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
            addFlower(islandDetails, item.Position, isDusk and palette.lilacLight or palette.coral, 0.56, math.floor(item.Position.X * 10 + item.Position.Z * 10))
            item.Transparency = 1
        end
    end

    -- Stone pavers make the route readable without turning it into a straight corridor.
    for i = 1, 7 do
        local z = -29 - i * 2.8
        local x = centerX + math.sin(i * 0.8) * 1.6
        local stone = orb(islandDetails, "Trail paver", Vector3.new(x, 11.78, z), Vector3.new(2.3, 0.22, 1.7), Color3.fromRGB(205, 193, 157), Enum.Material.Slate)
        stone.Shape = Enum.PartType.Block
        stone.CFrame = CFrame.new(x, 11.78, z) * CFrame.Angles(0, math.rad(i * 9), 0)
    end

    local treePositions = {
        Vector3.new(centerX - 17, 11.7, -53),
        Vector3.new(centerX + 17, 11.7, -54),
        Vector3.new(centerX - 19, 11.7, -39),
        Vector3.new(centerX + 19, 11.7, -39),
    }
    for i, position in treePositions do
        local leaves = isDusk and (i % 2 == 0 and palette.lilac or palette.lilacLight) or (i % 2 == 0 and palette.leaf or palette.leafLight)
        addTree(islandDetails, position, i % 2 == 0 and 0.82 or 0.68, leaves, 400 + i + (isDusk and 20 or 0))
    end

    for i = 1, 12 do
        local x = centerX + math.sin(i * 2.1) * 16
        local z = -31 - i * 2.05
        local color = isDusk and (i % 2 == 0 and palette.lilacLight or palette.moon) or (i % 2 == 0 and palette.gold or palette.coral)
        addFlower(islandDetails, Vector3.new(x, 11.7, z), color, 0.48 + (i % 3) * 0.08, 700 + i)
    end

    if isDusk then
        for i = 1, 7 do
            local x = centerX + math.cos(i * 1.4) * 16
            local z = -33 - i * 3.1
            addMushroom(islandDetails, Vector3.new(x, 11.7, z), i % 2 == 0 and palette.lilac or palette.moon, 0.8 + (i % 2) * 0.18, true)
        end
        for i = 1, 5 do
            local x = centerX + (i - 3) * 5
            local crystal = makePart(islandDetails, "Moon crystal", Vector3.new(0.7, 3.1 + (i % 2), 0.7), CFrame.new(x, 13.2, -55 + (i % 2) * 2) * CFrame.Angles(0, 0, math.rad((i % 2 == 0 and 10 or -12))), palette.lilacLight, Enum.Material.Neon)
            addLight(crystal, palette.lilacLight, 10, 0.5)
        end
        for i = 1, 8 do
            addFirefly(islandDetails, Vector3.new(centerX + math.sin(i * 1.8) * 15, 14 + (i % 3), -34 - i * 2.4), palette.gold, 900 + i)
        end
    else
        for i = 1, 5 do
            addMushroom(islandDetails, Vector3.new(centerX + (i - 3) * 5.2, 11.7, -51 + (i % 2) * 3), palette.coral, 0.72, false)
        end
        for i = 1, 5 do
            local x = centerX + (i - 3) * 5
            local bell = makePart(islandDetails, "Wayfinder bell", Vector3.new(0.35, 2.2, 0.35), CFrame.new(x, 12.8, -27), palette.gold, Enum.Material.Metal, Enum.PartType.Cylinder)
            orb(islandDetails, "Bell clapper", Vector3.new(x, 11.6, -27), Vector3.new(0.65, 0.65, 0.65), palette.coral, Enum.Material.Metal)
        end
    end
end

decorateIsland(grove, false)
decorateIsland(dusk, true)

-- Small visual details for the collectible companions.
local fox = ReplicatedStorage:FindFirstChild("Fox")
if fox then
    local foxDetails = makeFolder(fox, "HandcraftedDetails")
    for _, side in {-1, 1} do
        orb(foxDetails, "Inner ear", Vector3.new(side * 0.8, 1.2, -0.78), Vector3.new(0.32, 0.82, 0.22), Color3.fromRGB(246, 172, 151), Enum.Material.SmoothPlastic)
        orb(foxDetails, "Eye shine", Vector3.new(side * 0.62, 0.34, -1.43), Vector3.new(0.12, 0.12, 0.08), palette.cream, Enum.Material.Neon)
        orb(foxDetails, "Paw", Vector3.new(side * 0.78, -0.85, -0.65), Vector3.new(0.72, 0.55, 0.82), palette.coral, Enum.Material.SmoothPlastic)
        orb(foxDetails, "Paw", Vector3.new(side * 0.78, -0.85, 0.85), Vector3.new(0.72, 0.55, 0.82), palette.coral, Enum.Material.SmoothPlastic)
    end
    orb(foxDetails, "Tail tip", Vector3.new(0, 0.3, 2.72), Vector3.new(1.15, 1.1, 0.9), palette.cream, Enum.Material.SmoothPlastic)
    orb(foxDetails, "Leaf charm", Vector3.new(0, -0.85, -0.5), Vector3.new(0.8, 0.22, 0.55), palette.leafLight, Enum.Material.Grass)
end

local moth = ReplicatedStorage:FindFirstChild("Moth")
if moth then
    local mothDetails = makeFolder(moth, "HandcraftedDetails")
    for _, side in {-1, 1} do
        orb(mothDetails, "Wing jewel", Vector3.new(side * 1.3, 0.45, -0.43), Vector3.new(0.62, 0.62, 0.2), palette.gold, Enum.Material.Neon)
        orb(mothDetails, "Wing tip", Vector3.new(side * 1.85, 0.05, 0.08), Vector3.new(0.6, 0.7, 0.25), palette.lilacLight, Enum.Material.Neon)
        cylinder(mothDetails, "Antenna", Vector3.new(side * 0.34, 1.12, -0.55), 0.8, 0.08, palette.cream, Enum.Material.SmoothPlastic, CFrame.Angles(0, 0, math.rad(side * 24)))
        orb(mothDetails, "Eye shine", Vector3.new(side * 0.2, 0.2, -0.92), Vector3.new(0.13, 0.16, 0.08), palette.cream, Enum.Material.Neon)
    end
    local glow = orb(mothDetails, "Moonlight glow", Vector3.new(0, 0.1, 0), Vector3.new(0.18, 0.18, 0.18), palette.moon, Enum.Material.Neon)
    addLight(glow, palette.lilacLight, 9, 0.65)
end
