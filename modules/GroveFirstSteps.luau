-- Giantback: first Grove discovery markers, shown only to the local player.
-- Uses existing Nest/Trail parts. No duplicate prompts and no server-owned state changes.
local GroveFirstSteps = {}

function GroveFirstSteps.new(player)
    local marker
    local targetPart
    local groveConnection

    local function clear()
        if marker then
            marker:Destroy()
            marker = nil
        end
        targetPart = nil
    end

    local function desiredTarget()
        if player:GetAttribute("Ready") ~= true
            or player:GetAttribute("Bridge_HomeToGrove") ~= true then
            return nil
        end
        local grove = workspace:FindFirstChild("Grove")
        if not grove then return nil end
        if player:GetAttribute("Fox") ~= true then
            return grove:FindFirstChild("Nest"), "🦊 ЛИСЁНОК", "Подойди и нажми «Подружиться»"
        end
        if player:GetAttribute("Seed") ~= true
            and player:GetAttribute("Companion") == "Fox" then
            local cache = player:GetAttribute("FoxCacheSpot")
            if type(cache) ~= "string" or cache == "" then
                return grove:FindFirstChild("Trail"), "🐾 СЛЕДЫ В ТРАВЕ", "Попроси лисёнка искать"
            end
        end
        return nil
    end

    local function update()
        local part, title, hint = desiredTarget()
        if not part or not part:IsA("BasePart") then
            clear()
            return
        end
        if marker and targetPart == part and marker.Parent then return end
        clear()
        targetPart = part
        marker = Instance.new("Folder")
        marker.Name = "GiantbackFirstStepsLocal"
        marker.Parent = part

        local highlight = Instance.new("Highlight")
        highlight.Name = "FirstStepHighlight"
        highlight.Adornee = part
        highlight.FillColor = Color3.fromRGB(255, 207, 115)
        highlight.OutlineColor = Color3.fromRGB(255, 243, 192)
        highlight.FillTransparency = 0.84
        highlight.OutlineTransparency = 0.16
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = marker

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "FirstStepGuide"
        billboard.Adornee = part
        billboard.AlwaysOnTop = false
        billboard.MaxDistance = 60
        billboard.Size = UDim2.fromOffset(235, 66)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
        billboard.Parent = marker

        local backdrop = Instance.new("Frame")
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundColor3 = Color3.fromRGB(36, 60, 49)
        backdrop.BackgroundTransparency = 0.1
        backdrop.Parent = billboard
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = backdrop

        local function text(name, content, y, size, color)
            local label = Instance.new("TextLabel")
            label.Name = name
            label.BackgroundTransparency = 1
            label.Position = UDim2.fromOffset(8, y)
            label.Size = UDim2.new(1, -16, 0, 24)
            label.Text = content
            label.TextColor3 = color
            label.TextSize = size
            label.TextScaled = false
            label.TextWrapped = true
            label.Font = Enum.Font.GothamBold
            label.Parent = backdrop
        end
        text("Title", title, 7, 14, Color3.fromRGB(255, 220, 142))
        text("Hint", hint, 33, 12, Color3.fromRGB(255, 249, 230))
    end

    local function connectGrove(grove)
        if groveConnection then
            groveConnection:Disconnect()
            groveConnection = nil
        end
        if grove and grove:IsA("Model") then
            groveConnection = grove.ChildAdded:Connect(function(child)
                if child.Name == "Nest" or child.Name == "Trail" then update() end
            end)
        end
        update()
    end

    for _, key in {"Ready", "Bridge_HomeToGrove", "Fox", "Seed", "Companion", "FoxCacheSpot"} do
        player:GetAttributeChangedSignal(key):Connect(update)
    end
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "Grove" then connectGrove(child) end
    end)
    workspace.ChildRemoved:Connect(function(child)
        if child.Name == "Grove" then connectGrove(nil) end
    end)
    connectGrove(workspace:FindFirstChild("Grove"))
    return {update = update}
end

return GroveFirstSteps
