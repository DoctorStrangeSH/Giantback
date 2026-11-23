-- Cosmetic lunar moth stardust. Pet affinity values remain server-owned.
-- The particle emitter is parented to the attachment; updates must resolve it there.
local MothStardust = {}

function MothStardust.new(player, palette)
    -- Single source of truth for moth stardust personality and friendship intensity.
    local mothStardustRates = {
        ["Любопытный"] = 9,
        ["Озорной"] = 12,
        ["Смелый"] = 7,
        ["Застенчивый"] = 4,
    }

    local function mothStardustRate(personality, bondStage)
        local stage = math.clamp(math.floor(tonumber(bondStage) or 0), 0, 4)
        return math.min(16, (mothStardustRates[personality] or 7) + math.floor(stage / 2))
    end

    local function attachMothStardust(model)
        if not model or not model.Parent then return end
        local glow = model:FindFirstChild("Moonlight glow", true)
        if not glow or not glow:IsA("BasePart") or glow:FindFirstChild("CompanionStardustAttachment") then return end

        local attachment = Instance.new("Attachment")
        attachment.Name = "CompanionStardustAttachment"
        attachment.Parent = glow

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "CompanionStardust"
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(palette.lilacLight, palette.moon)
        emitter.LightEmission = 0.8
        local personality = player:GetAttribute("Companion_Moth_Personality")
        local bondStage = math.clamp(tonumber(player:GetAttribute("Companion_Moth_BondStage")) or 0, 0, 4)
        emitter.Rate = mothStardustRate(personality, bondStage)
        emitter.Lifetime = NumberRange.new(0.28, 0.55)
        emitter.Speed = NumberRange.new(0.12, 0.42)
        emitter.SpreadAngle = Vector2.new(150, 150)
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = NumberRange.new(-70, 70)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(0.55, 0.075),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter:SetAttribute("AppliedBondStage", bondStage)
        emitter:SetAttribute("AppliedPersonality", personality or "")
        emitter.Parent = attachment
    end

    local function updateMothStardust(model, owner)
        local glow = model and model:FindFirstChild("Moonlight glow", true)
        local attachment = glow and glow:FindFirstChild("CompanionStardustAttachment")
        local emitter = attachment and attachment:FindFirstChild("CompanionStardust")
        if not emitter or not emitter:IsA("ParticleEmitter") then return end

        local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_Moth_BondStage")) or 0, 0, 4)
        local personality = owner:GetAttribute("Companion_Moth_Personality")
        if emitter:GetAttribute("AppliedBondStage") == bondStage
            and emitter:GetAttribute("AppliedPersonality") == (personality or "") then return end

        emitter.Rate = mothStardustRate(personality, bondStage)
        emitter:SetAttribute("AppliedBondStage", bondStage)
        emitter:SetAttribute("AppliedPersonality", personality or "")
    end

    return {
        attach = attachMothStardust,
        update = updateMothStardust,
    }
end

return MothStardust
