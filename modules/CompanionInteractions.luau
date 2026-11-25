-- Cosmetic companion affection FX and local proximity interaction.
-- Server validates ownership, equipment, range and petting rewards.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CompanionInteractions = {}

function CompanionInteractions.new(player, event, names, palette, onSearch)
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

    local function showCompanionAttention(model, companionId)
        if not model or not model.Parent then return end
        local anchor = model:FindFirstChild("Body") or model.PrimaryPart
        if not anchor or not anchor:IsA("BasePart") then return end
        if anchor:FindFirstChild("CompanionAttentionBubble") then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "CompanionAttentionBubble"
        billboard.Size = UDim2.fromOffset(48, 48)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.15, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = 70
        billboard.Parent = anchor

        local bubble = Instance.new("Frame")
        bubble.Name = "Bubble"
        bubble.Size = UDim2.fromScale(0.82, 0.82)
        bubble.Position = UDim2.fromScale(0.09, 0.09)
        bubble.BackgroundColor3 = Color3.fromRGB(255, 246, 224)
        bubble.BackgroundTransparency = 0.08
        bubble.Parent = billboard
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = bubble
        local stroke = Instance.new("UIStroke")
        stroke.Color = palette.gold
        stroke.Thickness = 2
        stroke.Transparency = 0.12
        stroke.Parent = bubble

        local glyph = Instance.new("TextLabel")
        glyph.Name = "Glyph"
        glyph.Size = UDim2.fromScale(1, 1)
        glyph.BackgroundTransparency = 1
        glyph.Text = companionId == "Fox" and "♥"
            or companionId == "Moth" and "✦"
            or companionId == "CrystalWisp" and "✧"
            or companionId == "Starling" and "♪"
            or "?"
        glyph.TextColor3 = palette.ink
        glyph.Font = Enum.Font.GothamBold
        glyph.TextScaled = true
        glyph.Parent = bubble

        billboard.StudsOffsetWorldSpace += Vector3.new(0, 0.35, 0)
        bubble.Size = UDim2.fromScale(0.55, 0.55)
        TweenService:Create(billboard, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0),
        }):Play()
        TweenService:Create(bubble, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(0.82, 0.82),
        }):Play()

        task.delay(2.1, function()
            if not billboard.Parent then return end
            TweenService:Create(bubble, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(glyph, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
            Debris:AddItem(billboard, 0.35)
        end)
    end


    local function playCompanionSearchStart(model, companionId)
        if not model or not model.Parent then return end
        local origin = model:GetPivot().Position + Vector3.new(0, 0.8, 0)
        local folder = Instance.new("Folder")
        folder.Name = "CompanionSearchStartLocal"
        folder.Parent = workspace
        local color = companionId == "Fox" and palette.coral
            or companionId == "CrystalWisp" and palette.water or palette.lilac
        for index = 1, 5 do
            local mote = Instance.new("Part")
            mote.Name = "SearchSpark"
            mote.Shape = Enum.PartType.Ball
            mote.Size = Vector3.new(0.12, 0.12, 0.12)
            mote.Anchored = true
            mote.CanCollide = false
            mote.CanTouch = false
            mote.CanQuery = false
            mote.CastShadow = false
            mote.Material = Enum.Material.Neon
            mote.Color = color
            mote.CFrame = CFrame.new(origin + Vector3.new((index - 3) * 0.22, 0, 0))
            mote.Parent = folder
            TweenService:Create(mote, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                CFrame = mote.CFrame + Vector3.new((index - 3) * 0.14, 0.75 + (index % 2) * 0.16, 0),
                Transparency = 1,
                Size = Vector3.new(0.025, 0.025, 0.025),
            }):Play()
        end
        Debris:AddItem(folder, 0.75)
    end

    local function playCompanionGiftDiscovery(model, companionId, rarity)
        if not model or not model.Parent then return end
        local origin = model:GetPivot().Position + Vector3.new(0, 1.05, 0)
        local folder = Instance.new("Folder")
        folder.Name = "CompanionGiftDiscoveryLocal"
        folder.Parent = workspace
        local colors = {
            common = Color3.fromRGB(164, 210, 160),
            rare = Color3.fromRGB(105, 190, 255),
            epic = Color3.fromRGB(194, 130, 255),
        }
        local color = colors[rarity] or colors.common
        local count = rarity == "epic" and 14 or rarity == "rare" and 10 or 6
        for index = 1, count do
            local angle = (index - 1) * math.pi * 2 / count
            local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local mote = Instance.new("Part")
            mote.Name = "GiftDiscoverySpark"
            mote.Shape = Enum.PartType.Ball
            mote.Size = Vector3.new(rarity == "epic" and 0.2 or 0.14, rarity == "epic" and 0.2 or 0.14, rarity == "epic" and 0.2 or 0.14)
            mote.Anchored = true
            mote.CanCollide = false
            mote.CanTouch = false
            mote.CanQuery = false
            mote.CastShadow = false
            mote.Material = Enum.Material.Neon
            mote.Color = color
            mote.CFrame = CFrame.new(origin + direction * 0.3)
            mote.Parent = folder
            TweenService:Create(mote, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                CFrame = CFrame.new(origin + direction * (rarity == "epic" and 1.8 or 1.25) + Vector3.new(0, 0.9 + (index % 3) * 0.12, 0)),
                Size = Vector3.new(0.025, 0.025, 0.025),
                Transparency = 1,
            }):Play()
        end
        Debris:AddItem(folder, 1.0)
        showCompanionAttention(model, companionId)
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

        local searchPrompt = Instance.new("ProximityPrompt")
        searchPrompt.Name = "WorldPetSearchPrompt"
        searchPrompt.ObjectText = names[companionId] or "Питомец"
        searchPrompt.ActionText = "Искать подарок"
        searchPrompt.KeyboardKeyCode = Enum.KeyCode.F
        searchPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
        searchPrompt.HoldDuration = 0.65
        searchPrompt.MaxActivationDistance = 7
        searchPrompt.RequiresLineOfSight = false
        searchPrompt.ClickablePrompt = true
        searchPrompt.Parent = anchor

        searchPrompt.Triggered:Connect(function(triggeringPlayer)
            if triggeringPlayer and triggeringPlayer ~= player then return end
            if player:GetAttribute("Companion") ~= companionId then return end
            if onSearch then onSearch(companionId) end
            playCompanionSearchStart(model, companionId)
            event:FireServer("SearchCompanionGift", companionId)
        end)
    end

    return {
        attachWorldPetPrompt = attachWorldPetPrompt,
        showCompanionAttention = showCompanionAttention,
        playCompanionSearchStart = playCompanionSearchStart,
        playCompanionGiftDiscovery = playCompanionGiftDiscovery,
        playCompanionPettingBurst = playCompanionPettingBurst,
    }
end

return CompanionInteractions
