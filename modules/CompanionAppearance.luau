-- Companion scale and mutation presentation; progression remains server authoritative.
-- The caller owns capture/animation state so growth changes refresh live rig offsets.
local CompanionAppearance = {}

function CompanionAppearance.new(player, animationStates, captureAnimation)
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
        AmberGlow = {color = Color3.fromRGB(226, 142, 66), outline = Color3.fromRGB(255, 220, 145)},
        CloverCrown = {color = Color3.fromRGB(116, 176, 105), outline = Color3.fromRGB(196, 238, 156)},
        GoldenHarvest = {color = Color3.fromRGB(255, 193, 86), outline = Color3.fromRGB(255, 236, 166)},
        AutumnHeart = {color = Color3.fromRGB(193, 93, 74), outline = Color3.fromRGB(255, 214, 160), legendary = true},
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

    return {
        growth = applyCompanionGrowth,
        mutation = applyCompanionMutation,
    }
end

return CompanionAppearance
