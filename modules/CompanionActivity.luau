-- Giantback: client-only companion curiosity and rest scheduler.
-- This module does not own pets or grant rewards; the follower loop owns presentation.
local CompanionActivity = {}

function CompanionActivity.new()
    local companionActivity = setmetatable({}, {__mode = "k"})

    local function update(owner, id, now, moving, isLocal)
        local activity = companionActivity[owner]
        if not activity or activity.companionId ~= id then
            local personality = owner:GetAttribute("Companion_" .. id .. "_Personality")
            local curiosityWindows = {
                ["Любопытный"] = {5, 10},
                ["Озорной"] = {6, 11},
                ["Смелый"] = {9, 15},
                ["Застенчивый"] = {15, 23},
            }
            local window = curiosityWindows[personality] or {7, 14}
            local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_" .. id .. "_BondStage")) or 0, 0, 4)
            local minDelay = math.max(4, window[1] - bondStage * 1.5)
            local maxDelay = math.max(minDelay + 1, window[2] - bondStage * 2)
            activity = {
                companionId = id,
                idleSince = now,
                nextCuriosityAt = now + math.random(math.floor(minDelay), math.floor(maxDelay)),
            }
            companionActivity[owner] = activity
        end

        local sniff = false
        if moving then
            activity.idleSince = now
            activity.nextCuriosityAt = now + math.random(9, 16)
        elseif isLocal and id == "Fox" and now >= (activity.nextCuriosityAt or now + 10) then
            sniff = true
            local personality = owner:GetAttribute("Companion_Fox_Personality")
            local curiosityWindows = {
                ["Любопытный"] = {7, 12},
                ["Озорной"] = {8, 14},
                ["Смелый"] = {12, 18},
                ["Застенчивый"] = {20, 29},
            }
            local window = curiosityWindows[personality] or {13, 23}
            local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_Fox_BondStage")) or 0, 0, 4)
            local minDelay = math.max(5, window[1] - bondStage * 1.5)
            local maxDelay = math.max(minDelay + 1, window[2] - bondStage * 2)
            activity.nextCuriosityAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))
        end

        local idleSeconds = now - activity.idleSince
        local resting = not moving and idleSeconds >= 12
        local sleeping = not moving and idleSeconds >= 45
        return resting, sleeping, sniff
    end

    local function forget(owner)
        companionActivity[owner] = nil
    end

    return {update = update, forget = forget}
end

return CompanionActivity
