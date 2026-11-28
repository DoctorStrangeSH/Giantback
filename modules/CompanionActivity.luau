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
                nextAttentionAt = now + math.random(16, 26),
                nextExploreAt = now + math.random(11, 18),
                nextPlayfulAt = now + math.random(18, 32),
            }
            companionActivity[owner] = activity
        end

        local sniff = false
        local attention = false
        local curious = false
        if moving then
            activity.curiosityUntil = 0
            activity.idleSince = now
            activity.nextCuriosityAt = now + math.random(9, 16)
            activity.nextAttentionAt = now + math.random(24, 38)
            activity.nextExploreAt = now + math.random(18, 28)
            activity.nextPlayfulAt = now + math.random(24, 40)
            activity.playfulUntil = 0
            activity.worldInterestUntil = 0
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

        if isLocal and not moving and now >= (activity.nextExploreAt or now + 15) then
            activity.curiosityUntil = now + 2.6
            local personality = owner:GetAttribute("Companion_" .. id .. "_Personality")
            local exploreWindows = {
                ["Любопытный"] = {12, 18},
                ["Озорной"] = {14, 21},
                ["Смелый"] = {16, 24},
                ["Застенчивый"] = {23, 32},
            }
            local window = exploreWindows[personality] or {17, 25}
            local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_" .. id .. "_BondStage")) or 0, 0, 4)
            local reduction = bondStage * 1.5
            local minDelay = math.max(9, window[1] - reduction)
            local maxDelay = math.max(minDelay + 2, window[2] - reduction)
            activity.nextExploreAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))
        end

        curious = isLocal and not moving and now < (activity.curiosityUntil or 0)

        if isLocal and not moving and now >= (activity.nextAttentionAt or now + 20) then
            attention = true
            local personality = owner:GetAttribute("Companion_" .. id .. "_Personality")
            local attentionWindows = {
                ["Любопытный"] = {34, 48},
                ["Озорной"] = {28, 40},
                ["Смелый"] = {40, 55},
                ["Застенчивый"] = {48, 66},
            }
            local window = attentionWindows[personality] or {38, 54}
            local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_" .. id .. "_BondStage")) or 0, 0, 4)
            local reduction = bondStage * 2
            local minDelay = math.max(22, window[1] - reduction)
            local maxDelay = math.max(minDelay + 2, window[2] - reduction)
            activity.nextAttentionAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))
        end

        local playful = false
        if isLocal and not moving and (id == "Fox" or id == "Moth")
            and now >= (activity.nextPlayfulAt or now + 24) then
            local personality = owner:GetAttribute("Companion_" .. id .. "_Personality")
            local playfulWindows = {
                ["Любопытный"] = {24, 38},
                ["Озорной"] = {14, 24},
                ["Смелый"] = {28, 42},
                ["Застенчивый"] = {38, 54},
            }
            local window = playfulWindows[personality] or {24, 38}
            local bondStage = math.clamp(tonumber(owner:GetAttribute("Companion_" .. id .. "_BondStage")) or 0, 0, 4)
            local minDelay = math.max(12, window[1] - bondStage * 1.5)
            local maxDelay = math.max(minDelay + 2, window[2] - bondStage * 2)
            activity.playfulUntil = now + 2.4
            activity.nextPlayfulAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))
        end
        playful = isLocal and not moving and now < (activity.playfulUntil or 0)

        local worldInterest = nil
        if isLocal and not moving and (id == "Fox" or id == "Moth")
            and now >= (activity.nextWorldCheckAt or 0) then
            activity.nextWorldCheckAt = now + 0.4
            local islands = workspace:FindFirstChild("PlayerIslands")
            local island = islands and islands:FindFirstChild("HomeIsland_" .. tostring(owner.UserId))
            local city = island and island:FindFirstChild("PersonalCity")
            local wantedDecoration = id == "Fox" and "DecorativeTree" or "FlowerBed"
            local nearestDistance = 8
            local nearestPosition = nil
            if city then
                for _, decoration in city:GetChildren() do
                    if decoration:IsA("Model") and decoration:GetAttribute("DecorationId") == wantedDecoration then
                        local distance = (decoration:GetPivot().Position - companionPosition).Magnitude
                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearestPosition = decoration:GetPivot().Position
                        end
                    end
                end
            end
            if nearestPosition then
                activity.worldInterestUntil = now + 0.7
                activity.worldInterestPosition = nearestPosition
            end
        end
        if isLocal and not moving and now < (activity.worldInterestUntil or 0) then
            worldInterest = id == "Fox" and "Tree" or "Flowers"
        end

        local idleSeconds = now - activity.idleSince
        local resting = not moving and idleSeconds >= 12
        local sleeping = not moving and idleSeconds >= 45
        return resting, sleeping, sniff, attention, curious, playful, worldInterest
    end

    local function forget(owner)
        companionActivity[owner] = nil
    end

    return {update = update, forget = forget}
end

return CompanionActivity
