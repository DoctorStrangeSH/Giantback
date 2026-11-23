-- Local-only companion sleeping glyphs. Does not change gameplay rest state.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CompanionSleepVisuals = {}

function CompanionSleepVisuals.new(palette)
    local sleepIndicators = {}

    local function setSleepIndicator(model, enabled)
        local current = sleepIndicators[model]
        if not enabled then
            if current then
                sleepIndicators[model] = nil
                current:Destroy()
            end
            return
        end
        if current or not model or not model.Parent then return end

        local anchor = model:FindFirstChild("Body") or model.PrimaryPart
        if not anchor or not anchor:IsA("BasePart") then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "CompanionSleepZLocal"
        billboard.Adornee = anchor
        billboard.Size = UDim2.fromOffset(76, 48)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.65, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = 48
        billboard.Parent = anchor
        sleepIndicators[model] = billboard

        task.spawn(function()
            local glyphs = {"Z", "z", "z"}
            while sleepIndicators[model] == billboard and billboard.Parent and model.Parent do
                for index, glyphText in glyphs do
                    if sleepIndicators[model] ~= billboard or not billboard.Parent then break end
                    local glyph = Instance.new("TextLabel")
                    glyph.Name = "SleepGlyph"
                    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
                    glyph.Position = UDim2.fromScale(0.52, 0.78)
                    glyph.Size = UDim2.fromOffset(24, 24)
                    glyph.BackgroundTransparency = 1
                    glyph.Text = glyphText
                    glyph.TextColor3 = index == 1 and palette.cream or palette.lilac
                    glyph.TextStrokeColor3 = palette.shadow
                    glyph.TextStrokeTransparency = 0.35
                    glyph.TextTransparency = 0.05
                    glyph.Font = Enum.Font.GothamBlack
                    glyph.TextScaled = true
                    glyph.Rotation = (index - 2) * 9
                    glyph.Parent = billboard

                    local tween = TweenService:Create(
                        glyph,
                        TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Position = UDim2.fromScale(0.52 + (index - 2) * 0.17, 0.05),
                            TextTransparency = 1,
                            TextStrokeTransparency = 1,
                            Rotation = (index - 2) * 18,
                        }
                    )
                    tween:Play()
                    task.wait(0.48)
                    Debris:AddItem(glyph, 1.4)
                end
                task.wait(0.28)
            end
            if sleepIndicators[model] == billboard then
                sleepIndicators[model] = nil
                billboard:Destroy()
            end
        end)
    end

    return {setEnabled = setSleepIndicator}
end

return CompanionSleepVisuals
