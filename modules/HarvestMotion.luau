-- Giantback: client-side harvest motion only, never awards resources.
-- Each LocalScript obtains independent state for tool swings and camera feedback.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HarvestMotion = {}

function HarvestMotion.new(player)
    local lastToolSwingAt = 0
    local toolSwingGeneration = 0
    local cameraShakeGeneration = 0
    local cameraShakeBinding = "PetKingdomsHarvestCamera_" .. tostring(player.UserId)

    local function playHarvestCameraShake(intensity)
        if player:GetAttribute("HarvestCameraShakeEnabled") == false then return end
        local camera = workspace.CurrentCamera
        if not camera then return end

        cameraShakeGeneration += 1
        local generation = cameraShakeGeneration
        local startedAt = os.clock()
        local duration = 0.13
        local strength = math.clamp(tonumber(intensity) or 0.35, 0.12, 0.7)

        RunService:UnbindFromRenderStep(cameraShakeBinding)
        RunService:BindToRenderStep(cameraShakeBinding, Enum.RenderPriority.Camera.Value + 1, function()
            if generation ~= cameraShakeGeneration then
                RunService:UnbindFromRenderStep(cameraShakeBinding)
                return
            end
            local currentCamera = workspace.CurrentCamera
            if not currentCamera then
                RunService:UnbindFromRenderStep(cameraShakeBinding)
                return
            end
            local elapsed = os.clock() - startedAt
            if elapsed >= duration then
                RunService:UnbindFromRenderStep(cameraShakeBinding)
                return
            end

            local fade = 1 - elapsed / duration
            local offset = Vector3.new(
                (math.random() - 0.5) * 2,
                (math.random() - 0.5) * 2,
                0
            ) * strength * fade * 0.045
            currentCamera.CFrame = currentCamera.CFrame * CFrame.new(offset)
        end)
    end

    local function playHarvestCharacterSwing(character, nodeId, generation)
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if not torso then return end

        local shoulder
        for _, descendant in character:GetDescendants() do
            if descendant:IsA("Motor6D") and (descendant.Name == "RightShoulder" or descendant.Name == "Right Shoulder") then
                shoulder = descendant
                break
            end
        end
        if not shoulder then return end

        local elbow
        for _, descendant in character:GetDescendants() do
            if descendant:IsA("Motor6D") and descendant.Name == "RightElbow" then
                elbow = descendant
                break
            end
        end

        local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
        local windup = CFrame.Angles(math.rad(isWood and -58 or -42), 0, math.rad(-18))
        local impact = CFrame.Angles(math.rad(isWood and 48 or 64), 0, math.rad(12))
        local elbowBend = math.rad(isWood and 24 or 34)
        local startedAt = os.clock()
        local bindingName = "PetKingdomsHarvestSwing_" .. tostring(player.UserId)

        RunService:UnbindFromRenderStep(bindingName)
        RunService:BindToRenderStep(bindingName, Enum.RenderPriority.Last.Value, function()
            if generation ~= toolSwingGeneration or player.Character ~= character or not character.Parent or not shoulder.Parent then
                RunService:UnbindFromRenderStep(bindingName)
                return
            end

            local elapsed = os.clock() - startedAt
            local phase
            local pose
            local bend
            if elapsed < 0.11 then
                phase = math.clamp(elapsed / 0.11, 0, 1)
                phase = phase * phase * (3 - 2 * phase)
                pose = CFrame.identity:Lerp(windup, phase)
                bend = elbowBend * phase
            elseif elapsed < 0.21 then
                phase = math.clamp((elapsed - 0.11) / 0.10, 0, 1)
                phase = phase * phase * (3 - 2 * phase)
                pose = windup:Lerp(impact, phase)
                bend = elbowBend * (1 - phase * 0.35)
            elseif elapsed < 0.39 then
                phase = math.clamp((elapsed - 0.21) / 0.18, 0, 1)
                phase = 1 - (1 - phase) * (1 - phase)
                pose = impact:Lerp(CFrame.identity, phase)
                bend = elbowBend * 0.65 * (1 - phase)
            else
                RunService:UnbindFromRenderStep(bindingName)
                return
            end

            -- Add the swing after the default Animator pose; this is a local-only presentation layer.
            shoulder.Transform = shoulder.Transform * pose
            if elbow and elbow.Parent then
                elbow.Transform = elbow.Transform * CFrame.Angles(-bend, 0, 0)
            end
        end)
    end

    local function playHarvestToolSwing(nodeId)
        local character = player.Character
        if not character then return end
        local tool
        for _, child in character:GetChildren() do
            if child:IsA("Tool") and child:GetAttribute("PetKingdomsToolId") then
                tool = child
                break
            end
        end
        if not tool then return end

        local now = os.clock()
        if now - lastToolSwingAt < 0.12 then return end
        lastToolSwingAt = now
        toolSwingGeneration += 1
        local generation = toolSwingGeneration
        local originalGrip = tool.Grip
        playHarvestCharacterSwing(character, nodeId, generation)
        local isWood = string.find(nodeId, "Wood", 1, true) ~= nil
        local raise = originalGrip * CFrame.Angles(math.rad(18), 0, math.rad(isWood and 8 or -8))
        local impact = originalGrip * CFrame.Angles(isWood and math.rad(-52) or math.rad(-68), 0, math.rad(isWood and -12 or 10))

        local first = TweenService:Create(tool, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Grip = raise})
        local second = TweenService:Create(tool, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Grip = impact})
        local recover = TweenService:Create(tool, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Grip = originalGrip})
        first:Play()
        first.Completed:Once(function()
            if generation ~= toolSwingGeneration or not tool.Parent then return end
            second:Play()
        end)
        second.Completed:Once(function()
            if generation ~= toolSwingGeneration or not tool.Parent then return end
            recover:Play()
        end)
    end


    return {
        playCameraShake = playHarvestCameraShake,
        playToolSwing = playHarvestToolSwing,
    }
end

return HarvestMotion
