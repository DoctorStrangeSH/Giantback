-- Client-only positioning for visible companion followers.
-- Keeps the owner's character as the sole anchor; changes no inventory or progression.
local CompanionFollow = {}

function CompanionFollow.target(root, owner, id, now, isLocal)
    local phase = now + (owner.UserId % 19) * 0.17
    local bob = math.sin(phase * 2.8) * 0.14
    local followOffset

    if id == "Moth" and isLocal then
        local personality = owner:GetAttribute("Companion_Moth_Personality")
        local orbitSpeeds = {
            ["Любопытный"] = 0.9,
            ["Озорной"] = 1.18,
            ["Смелый"] = 0.78,
            ["Застенчивый"] = 0.52,
        }
        local orbitAngle = phase * (orbitSpeeds[personality] or 0.72)
        local personalityRadius = personality == "Застенчивый" and 0.24 or personality == "Озорной" and 0.52 or 0.38
        local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_Moth_BondStage")) or 0, 0, 4)
        local orbitRadius = math.max(0.2, personalityRadius - bondStage * 0.035)
        followOffset = CFrame.new(
            2.25 + math.cos(orbitAngle) * orbitRadius,
            1.05 + bob + math.sin(orbitAngle * 1.35) * (personality == "Застенчивый" and 0.09 or 0.16),
            1.75 + math.sin(orbitAngle) * orbitRadius * 1.1
        )
    else
        followOffset = CFrame.new(2.8, (id == "Fox" and -1.35 or 1.05) + bob, 2.1)
    end

    local target = root.CFrame
        * followOffset
        * CFrame.Angles(0, math.sin(phase * 1.6) * 0.06, 0)
    return target, phase
end

function CompanionFollow.smooth(model, target, dt)
    model:PivotTo(model:GetPivot():Lerp(target, 1 - math.exp(-9 * dt)))
end

return CompanionFollow
