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

function CompanionAnimation.animate(model, state, time, moving, resting, player, foxSniffUntil, mothAbilityUntil, pettingUntil)
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

            if state.id == "Fox" then
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
            end

            part.CFrame = pivot * transform * offset
        end
    end
end

return CompanionAnimation
