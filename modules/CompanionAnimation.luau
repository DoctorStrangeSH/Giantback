-- Giantback cosmetic procedural companion animation.
-- Does not own pet lifecycle, remote events, inventory or approved mesh selection.
-- Parameters are sampled by the caller each frame to preserve live abilities and petting.
local CompanionAnimation = {}

function CompanionAnimation.capture(model, id, isEncounter, isLocal)
    local pivot = model:GetPivot()
    local offsets = {}
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            offsets[part] = pivot:ToObjectSpace(part.CFrame)
        end
    end

    local state = {
        id = id,
        origin = pivot,
        offsets = offsets,
        isEncounter = isEncounter == true,
        isLocal = isLocal == true,
    }
    return state
end

local function aroundPoint(point, rotation)
    return CFrame.new(point) * rotation * CFrame.new(-point)
end

function CompanionAnimation.animate(model, state, time, moving, resting, player, foxSniffUntil, mothAbilityUntil, pettingUntil, searching)
    local pivot = model:GetPivot()
    local now = os.clock()
    local growthStage = math.clamp(math.floor(tonumber(model:GetAttribute("AppliedGrowthStage")) or 1), 1, 3)
    local sniffing = state.id == "Fox" and not state.isEncounter and now < foxSniffUntil
    local mothAbility = state.id == "Moth" and state.isLocal and now < mothAbilityUntil
    local prismSenseActive = state.id == "CrystalWisp" and state.isLocal
        and workspace:GetServerTimeNow() < (tonumber(player:GetAttribute("PrismSenseUntil")) or 0)
    local petting = not state.isEncounter and now < (pettingUntil[state.id] or 0)
    local body = model:FindFirstChild("Body")
    local bodyOffset = body and state.offsets[body]
    local rigOrigin = bodyOffset and bodyOffset.Position or Vector3.zero

    for part, offset in state.offsets do
        if part.Parent then
            local transform = CFrame.new()

            if searching and (part.Name == "Body" or part.Name == "Head" or part.Name == "Muzzle" or part.Name == "Paw" or part.Name == "Paw toe") then
                local searchPulse = math.sin(time * 10)
                if part.Name == "Body" then
                    transform = CFrame.new(0, -0.045 + math.abs(searchPulse) * 0.025, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(math.rad(3), 0, 0))
                elseif part.Name == "Head" or part.Name == "Muzzle" then
                    transform = CFrame.new(0, -0.11 - math.abs(searchPulse) * 0.035, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(math.rad(9) + searchPulse * 0.035, 0, 0))
                else
                    local side = offset.Position.X >= rigOrigin.X and 1 or -1
                    local dig = math.max(0, searchPulse) * 0.09
                    transform = CFrame.new(0, dig, 0) * aroundPoint(offset.Position, CFrame.Angles(-dig * 1.4, 0, side * dig))
                end
            elseif searching and (part.Name == "Head" or part.Name == "Moth head" or part.Name == "Core"
                or part.Name == "Body" or part.Name == "Shell" or part.Name == "Mushroom cap"
                or part.Name == "Crest" or part.Name == "Water jewel") then
                local searchPulse = math.sin(time * 7.5)
                transform = CFrame.new(0, -0.035 + math.abs(searchPulse) * 0.045, 0)
                    * aroundPoint(offset.Position, CFrame.Angles(math.rad(5) + searchPulse * 0.025, 0, searchPulse * 0.045))
            elseif state.id == "Fox" then
                if part.Name == "Body" and petting then
                    local affectionateDip = math.sin(time * 6.5) * 0.025
                    transform = CFrame.new(0, -0.09 + affectionateDip, 0.06)
                        * aroundPoint(offset.Position, CFrame.Angles(math.rad(-4), 0, 0))
                elseif part.Name == "Body" and resting then
                    transform = CFrame.new(0, math.sin(time * 1.8) * 0.035, 0)
                elseif part.Name == "Muzzle" and sniffing then
                    transform = CFrame.new(0, -0.14, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 12) * 0.045, 0, 0))
                elseif part.Name == "Tail" or part.Name == "Tail tip" then
                    local swaySpeed = sniffing and 9 or 4.2
                    local growthSway = ({[1] = 0.82, [2] = 1, [3] = 1.22})[growthStage]
                    local swayStrength = (sniffing and 0.48 or 0.3) * growthSway
                    if resting then
                        swaySpeed = 1.6
                        swayStrength = 0.12
                    end
                    if petting then
                        swaySpeed = 10.5
                        swayStrength = 0.72
                    end
                    local sway = math.sin(time * swaySpeed) * swayStrength
                    local tailHinge = rigOrigin + Vector3.new(0, 0.25, 0.95)
                    local tailRotation = part.Name == "Tail tip"
                        and CFrame.Angles(sway * 0.35, sway * 0.8, 0)
                        or CFrame.Angles(sway * 0.45, sway, sway * 0.2)
                    transform = aroundPoint(tailHinge, tailRotation)
                elseif part.Name == "Paw" or part.Name == "Paw toe" then
                    local growthStride = ({[1] = 0.82, [2] = 1, [3] = 1.12})[growthStage]
                    local stride = resting and 0 or moving and 0.32 or sniffing and 0.16 or petting and 0.11 or 0.055
                    stride *= growthStride
                    local phase = (math.abs(offset.Position.X) + math.abs(offset.Position.Z)) * 1.8
                    local step = math.sin(time * (moving and 10 or sniffing and 8 or petting and 7 or 2.4) + phase) * stride
                    transform = CFrame.new(0, math.max(0, step) * 0.16, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(step, 0, 0))
                elseif part.Name == "Ear" or part.Name == "Inner ear" then
                    local side = offset.Position.X >= rigOrigin.X and 1 or -1
                    local twitch = math.sin(time * (sniffing and 5 or petting and 6.5 or 2.2) + side)
                        * (sniffing and 0.09 or petting and 0.13 or 0.055)
                    local earHinge = rigOrigin + Vector3.new(side * 0.8, 0.55, -0.4)
                    transform = aroundPoint(earHinge, CFrame.Angles(0, 0, twitch * side))
                end
            elseif state.id == "Moth" then
                local side = offset.Position.X >= rigOrigin.X and 1 or -1
                if part.Name == "Wing" or part.Name == "Wing lower" or part.Name == "Wing tip"
                    or part.Name == "Wing lower tip" or part.Name == "Wing jewel" or part.Name == "Wing spot" then
                    local growthFlap = ({[1] = 0.88, [2] = 1, [3] = 1.16})[growthStage]
                    local flapSpeed = (mothAbility and 21 or 11.5) * growthFlap
                    local flapStrength = (mothAbility and 0.76 or 0.42) * growthFlap
                    if resting and not mothAbility then
                        flapSpeed = 3.2
                        flapStrength = 0.13
                    end
                    if petting and not mothAbility then
                        flapSpeed = 17
                        flapStrength = 0.62
                    end
                    local lowerPhase = string.find(part.Name, "lower") and 0.38 or 0
                    local flap = math.sin(time * flapSpeed + lowerPhase) * flapStrength
                    local wingHinge = rigOrigin + Vector3.new(side * 0.42, 0.28, 0)
                    transform = aroundPoint(wingHinge, CFrame.Angles(0, 0, flap * side))
                elseif part.Name == "Moth head" and petting then
                    local affectionateNod = math.sin(time * 7) * 0.055
                    transform = aroundPoint(offset.Position, CFrame.Angles(math.rad(5) + affectionateNod, 0, 0))
                elseif part.Name == "Antenna" or part.Name == "Antenna tip" then
                    local twitchSpeed = mothAbility and 7 or resting and 1.1 or 2.8
                    local twitchStrength = mothAbility and 0.14 or resting and 0.025 or 0.07
                    local antennaHinge = rigOrigin + Vector3.new(side * 0.34, 0.9, -0.55)
                    transform = aroundPoint(antennaHinge, CFrame.Angles(0, 0, math.sin(time * twitchSpeed + side) * twitchStrength * side))
                elseif part.Name == "Moonlight glow" then
                    local adultGlow = growthStage == 3 and 1.18 or growthStage == 2 and 1.06 or 1
                    local pulse = (mothAbility and (1.15 + math.sin(time * 12) * 0.35) or resting and 0.38 or 0.65) * adultGlow
                    if petting and not mothAbility then
                        pulse = 0.95 + math.sin(time * 8) * 0.2
                    end
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = pulse
                        light.Range = mothAbility and 14 or 9
                    end
                    transform = CFrame.new(0, math.sin(time * (mothAbility and 9 or 2.8)) * (mothAbility and 0.12 or 0.035), 0)
                        * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 3.2) * 0.08))
                end
            elseif state.id == "HarvestSprite" then
                local bobSpeed = resting and 1.4 or moving and 4.0 or 2.3
                local bobAmount = resting and 0.025 or moving and 0.085 or 0.055
                if petting then bobAmount += 0.035 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                if part.Name == "Body" then
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 1.8) * 0.035, 0, math.sin(time * 2.2) * 0.045))
                elseif part.Name == "Leaf" then
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * (petting and 7 or 2.6)) * (petting and 0.22 or 0.12)))
                elseif part.Name == "Lantern core" then
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = resting and 0.45 or 0.8 + math.sin(time * (petting and 9 or 3.5)) * 0.25
                        light.Range = petting and 11 or 8
                    end
                    transform = CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, math.sin(time * 3.2) * 0.08)
                else
                    transform = CFrame.new(0, bob, 0)
                end
            elseif state.id == "CrystalWisp" then
                local bobSpeed = resting and 1.35 or moving and 4.2 or 2.4
                local bobAmount = resting and 0.035 or moving and 0.1 or 0.065
                if petting then bobAmount += 0.025 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                local sway = math.sin(time * (prismSenseActive and 4.8 or 1.8)) * (prismSenseActive and 0.11 or 0.045)
                if string.match(part.Name, "^OrbitCrystal") then
                    local shardIndex = tonumber(string.match(part.Name, "(%d+)$")) or 1
                    local orbitSpeed = prismSenseActive and 1.85 or resting and 0.28 or 0.82
                    local phase = time * orbitSpeed + (shardIndex - 1) * (math.pi * 2 / 3)
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(rigOrigin, CFrame.Angles(math.sin(phase) * 0.12, phase, math.cos(phase) * 0.1))
                elseif part.Name == "Body" then
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(sway * 0.45, 0, sway))
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = prismSenseActive and (1.8 + math.sin(time * 9) * 0.45) or resting and 0.55 or 1.1
                        light.Range = prismSenseActive and 18 or 12
                    end
                elseif part.Name == "Core" then
                    transform = CFrame.new(0, bob, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 2.8) * 0.08))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            elseif state.id == "BrambleBun" then
                local happy = state.mood == "Радость" or petting
                local personality = state.personality
                local earEnergy = personality == "Озорной" and 1.3 or personality == "Застенчивый" and 0.7 or 1
                local bobSpeed = moving and 7.5 or happy and 4.8 or resting and 1.2 or 2.1
                local bobAmount = moving and 0.13 or happy and 0.095 or resting and 0.018 or 0.045
                if state.sleeping then bobAmount = 0.012 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                if part.Name == "Body" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 2.4) * 0.035, 0, math.sin(time * 3.1) * (happy and 0.09 or 0.035)))
                elseif part.Name == "Head" then
                    local curiousDip = state.curious and 0.18 or not moving and not resting and math.sin(time * 0.72) > 0.94 and 0.12 or 0
                    local nod = petting and math.sin(time * 8) * 0.12 or math.sin(time * 2.2) * 0.035
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(-curiousDip + nod, 0, math.sin(time * 1.7) * 0.035))
                elseif string.find(part.Name, "Ear") then
                    local side = string.find(part.Name, "left") and -1 or 1
                    local twitch = math.sin(time * (petting and 9 or resting and 1.1 or 3.2) + side) * (petting and 0.22 or 0.07) * earEnergy
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, twitch * side))
                elseif part.Name == "Acorn leaf" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 3.6) * 0.12))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            elseif state.id == "MossTurtle" then
                local happy = state.mood == "Радость" or petting
                local bobSpeed = moving and 5.2 or happy and 3.1 or resting and 0.8 or 1.45
                local bobAmount = moving and 0.07 or happy and 0.055 or resting and 0.012 or 0.026
                if state.sleeping then bobAmount = 0.008 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                if part.Name == "Body" or part.Name == "Shell" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 1.35) * 0.018, 0, math.sin(time * 1.1) * 0.025))
                elseif part.Name == "Head" then
                    local peek = state.sleeping and -0.16 or state.curious and 0.13 or math.sin(time * (petting and 6 or 1.8)) * (petting and 0.11 or 0.045)
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(peek, 0, math.sin(time * 1.2) * 0.025))
                elseif part.Name == "Foot" then
                    local side = offset.Position.X >= 0 and 1 or -1
                    local front = offset.Position.Z < 0 and 1 or -1
                    local paddle = moving and math.sin(time * 6.5 + side * front) * 0.16
                        or petting and math.sin(time * 4.5 + side * front) * 0.055 or 0
                    transform = CFrame.new(0, bob + math.max(0, paddle) * 0.12, 0) * aroundPoint(offset.Position, CFrame.Angles(paddle, 0, side * paddle * 0.25))
                elseif part.Name == "Tail" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, math.sin(time * 2.4) * (happy and 0.28 or 0.1), 0))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            elseif state.id == "Glowcap" then
                local happy = state.mood == "Радость" or petting
                local bobSpeed = moving and 4.2 or happy and 3.5 or resting and 1 or 1.9
                local bobAmount = moving and 0.09 or happy and 0.075 or resting and 0.015 or 0.04
                if state.sleeping then bobAmount = 0.008 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                if part.Name == "Body" or part.Name == "Mushroom stalk" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 1.7) * 0.025, 0, math.sin(time * 2.1) * 0.045))
                elseif part.Name == "Mushroom cap" then
                    local wobble = math.sin(time * (state.curious and 5.2 or petting and 7 or 2.2)) * (state.curious and 0.14 or petting and 0.17 or 0.07)
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, math.sin(time * 1.4) * 0.04, wobble))
                elseif part.Name == "Glow core" or part.Name == "Glowcap spot" then
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = state.sleeping and 0.2 or happy and (1.05 + math.sin(time * 8) * 0.3) or 0.55 + math.sin(time * 2.6) * 0.18
                    end
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 2.8) * 0.035))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            elseif state.id == "Dewdrop" then
                local happy = state.mood == "Радость" or petting
                local bobSpeed = moving and 6.2 or happy and 4.4 or resting and 1.1 or 2.2
                local bobAmount = moving and 0.12 or happy and 0.09 or resting and 0.018 or 0.05
                if state.sleeping then bobAmount = 0.01 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                if part.Name == "Body" or part.Name == "Head" then
                    local headNod = part.Name == "Head" and (state.curious and math.sin(time * 5.5) * 0.12 or petting and math.sin(time * 7) * 0.13 or math.sin(time * 2.3) * 0.045) or 0
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(headNod, 0, math.sin(time * 1.8) * 0.035))
                elseif string.find(part.Name, "Fin") or part.Name == "Tail fin" then
                    local side = string.find(part.Name, "left") and -1 or string.find(part.Name, "right") and 1 or 0
                    local flapSpeed = moving and 9 or petting and 8 or resting and 1 or 3.2
                    local flap = math.sin(time * flapSpeed + side) * (moving and 0.25 or happy and 0.2 or 0.09)
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(flap * 0.35, 0, flap * (side == 0 and 1 or side)))
                elseif part.Name == "Water jewel" then
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Brightness = state.sleeping and 0.15 or happy and (0.95 + math.sin(time * 9) * 0.25) or 0.45 + math.sin(time * 3) * 0.12
                    end
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 2.4) * 0.07))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            elseif state.id == "Starling" then
                local happy = state.mood == "Радость" or petting
                local flapSpeed = moving and 8 or happy and 6 or resting and 0.8 or 2.1
                local flapStrength = moving and 0.3 or happy and 0.22 or resting and 0.025 or 0.075
                if state.sleeping then flapStrength = 0.008 end
                local bob = math.sin(time * (moving and 5 or 2.2)) * (moving and 0.1 or resting and 0.012 or 0.045)
                if part.Name == "Body" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 1.8) * 0.025, 0, math.sin(time * 2.1) * 0.035))
                elseif part.Name == "Head" then
                    local curiousTilt = state.curious and 0.22 or math.sin(time * 0.85) > 0.72 and 0.12 or 0
                    local nod = petting and math.sin(time * 7) * 0.1 or math.sin(time * 2.3) * 0.035
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(nod, 0, curiousTilt + math.sin(time * 1.1) * 0.035))
                elseif string.find(part.Name, "Wing") then
                    local side = string.find(part.Name, "left") and -1 or 1
                    local flap = math.sin(time * flapSpeed + side) * flapStrength
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, flap * side))
                elseif part.Name == "Crest" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, math.sin(time * 3.4) * (happy and 0.16 or 0.07)))
                elseif part.Name == "Star halo" then
                    local light = part:FindFirstChildOfClass("PointLight")
                    if light then light.Brightness = state.sleeping and 0.2 or happy and 0.95 or 0.5 + math.sin(time * 2.5) * 0.18 end
                    transform = CFrame.new(0, bob + math.sin(time * 1.8) * 0.025, 0)
                        * aroundPoint(offset.Position, CFrame.Angles(0, math.sin(time * 0.8) * 0.12, math.sin(time * 1.2) * 0.08))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            else
                local bobSpeed = resting and 1.45 or moving and 4.1 or 2.35
                local bobAmount = resting and 0.025 or moving and 0.085 or 0.055
                if petting then bobAmount += 0.025 end
                local bob = math.sin(time * bobSpeed) * bobAmount
                if part.Name == "Body" then
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(math.sin(time * 1.8) * 0.025, 0, math.sin(time * 2.1) * 0.035))
                elseif string.find(string.lower(part.Name), "wing") or string.find(string.lower(part.Name), "fin") or string.find(string.lower(part.Name), "ear") or string.find(string.lower(part.Name), "leaf") or string.find(string.lower(part.Name), "crest") then
                    local side = offset.Position.X >= rigOrigin.X and 1 or -1
                    local sway = math.sin(time * (petting and 6.5 or resting and 1.1 or 2.8) + side) * (petting and 0.18 or resting and 0.035 or 0.09)
                    transform = CFrame.new(0, bob, 0) * aroundPoint(offset.Position, CFrame.Angles(0, 0, sway * side))
                else
                    transform = CFrame.new(0, bob, 0)
                end
            end

            part.CFrame = pivot * transform * offset
        end
    end
end

return CompanionAnimation
