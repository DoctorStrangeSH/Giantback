-- Giantback cosmetic harvest effects. Never grants inventory or modifies server-owned state.
-- Each client retains its own hit counters, tween state, and UI progress bars.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local HarvestFeedback = {}

function HarvestFeedback.new(player, findNode, harvestMotion)
    assert(type(findNode) == "function", "harvest node callback required")
    assert(harvestMotion, "harvest motion controller required")
    local playHarvestCameraShake = harvestMotion.playCameraShake
    local playHarvestToolSwing = harvestMotion.playToolSwing

    local resourceHitBars = {}
    local resourceHitEffects = {}
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
        local node = findNode(payload.nodeId)
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
        local node = findNode(nodeId)
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
        local node = findNode(nodeId)
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
        local node = findNode(nodeId)
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


    return {
        onHit = showResourceHitFeedback,
        clearHit = clearResourceHitFeedback,
        rewardPickup = playResourceRewardPickup,
        breakFeedback = playResourceBreakFeedback,
    }
end

return HarvestFeedback
