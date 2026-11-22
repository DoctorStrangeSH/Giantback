-- Combat input adapter. It sends intent only; the server owns all combat outcomes.
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("CombatAction")
if not remote:IsA("RemoteEvent") then
    warn("CombatAction RemoteEvent is unavailable.")
    return
end

local function attackAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        remote:FireServer("Attack")
    end
    return Enum.ContextActionResult.Sink
end

local function blockAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        remote:FireServer("BlockStart")
    elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
        remote:FireServer("BlockEnd")
    end
    return Enum.ContextActionResult.Sink
end

local function dodgeAction(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        remote:FireServer("Dodge")
    end
    return Enum.ContextActionResult.Sink
end

-- Mouse/keyboard + gamepad + ContextActionService touch buttons.
ContextActionService:BindAction(
    "GiantbackAttack",
    attackAction,
    true,
    Enum.UserInputType.MouseButton1,
    Enum.KeyCode.ButtonR2
)
ContextActionService:BindAction(
    "GiantbackBlock",
    blockAction,
    true,
    Enum.KeyCode.F,
    Enum.KeyCode.ButtonL2
)
ContextActionService:BindAction(
    "GiantbackDodge",
    dodgeAction,
    true,
    Enum.KeyCode.Q,
    Enum.KeyCode.ButtonB
)

ContextActionService:SetTitle("GiantbackAttack", "УДАР")
ContextActionService:SetTitle("GiantbackBlock", "БЛОК")
ContextActionService:SetTitle("GiantbackDodge", "УКЛОН")
ContextActionService:SetPosition("GiantbackAttack", UDim2.new(1, -92, 1, -190))
ContextActionService:SetPosition("GiantbackBlock", UDim2.new(1, -188, 1, -112))
ContextActionService:SetPosition("GiantbackDodge", UDim2.new(1, -92, 1, -92))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local feedbackGui = Instance.new("ScreenGui")
feedbackGui.Name = "GiantbackCombatFeedback"
feedbackGui.DisplayOrder = 35
feedbackGui.IgnoreGuiInset = true
feedbackGui.ResetOnSpawn = false
feedbackGui.Parent = playerGui

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "Feedback"
feedbackLabel.AnchorPoint = Vector2.new(0.5, 0)
feedbackLabel.Position = UDim2.new(0.5, 0, 0, 82)
feedbackLabel.Size = UDim2.fromOffset(310, 44)
feedbackLabel.BackgroundColor3 = Color3.fromRGB(43, 65, 57)
feedbackLabel.BackgroundTransparency = 0.12
feedbackLabel.BorderSizePixel = 0
feedbackLabel.Font = Enum.Font.GothamBold
feedbackLabel.TextColor3 = Color3.fromRGB(255, 231, 183)
feedbackLabel.TextSize = 17
feedbackLabel.TextStrokeTransparency = 0.8
feedbackLabel.Text = ""
feedbackLabel.Visible = false
feedbackLabel.Parent = feedbackGui

local feedbackCorner = Instance.new("UICorner")
feedbackCorner.CornerRadius = UDim.new(0, 12)
feedbackCorner.Parent = feedbackLabel

local feedbackStroke = Instance.new("UIStroke")
feedbackStroke.Color = Color3.fromRGB(215, 177, 112)
feedbackStroke.Transparency = 0.35
feedbackStroke.Thickness = 1
feedbackStroke.Parent = feedbackLabel

local feedbackSequence = 0
local feedbackTweens = {}
local function showFeedback(message, color)
    for _, tween in feedbackTweens do tween:Cancel() end
    table.clear(feedbackTweens)
    feedbackSequence += 1
    local sequence = feedbackSequence
    feedbackLabel.Text = message
    feedbackLabel.TextColor3 = color or Color3.fromRGB(255, 231, 183)
    feedbackLabel.TextTransparency = 0
    feedbackLabel.BackgroundTransparency = 0.12
    feedbackStroke.Transparency = 0.35
    feedbackLabel.Visible = true
    task.delay(1.15, function()
        if sequence ~= feedbackSequence or not feedbackLabel.Parent then return end
        local fade = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local labelTween = TweenService:Create(feedbackLabel, fade, {TextTransparency = 1, BackgroundTransparency = 1})
        local strokeTween = TweenService:Create(feedbackStroke, fade, {Transparency = 1})
        feedbackTweens = {labelTween, strokeTween}
        labelTween:Play()
        strokeTween:Play()
        task.delay(0.28, function()
            if sequence == feedbackSequence and feedbackLabel.Parent then
                feedbackLabel.Visible = false
            end
        end)
    end)
end

local rejectionMessages = {
    AttackCooldown = "Удар ещё восстанавливается",
    DodgeCooldown = "Уклонение ещё восстанавливается",
    CombatRegionRequired = "Войди на тренировочную арену",
    NoServerEquippedWeapon = "Оружие пока не экипировано",
    RateLimited = "Не торопись — попробуй чуть позже",
    PlayerNotReady = "Подожди, пока мир загрузится",
}

remote.OnClientEvent:Connect(function(message, data)
    if message == "CombatRejected" and type(data) == "table" then
        local copy = rejectionMessages[data.code]
        if copy then showFeedback(copy, Color3.fromRGB(255, 207, 153)) end
    elseif message == "CombatHit" then
        showFeedback("ПОПАЛ!", Color3.fromRGB(187, 236, 164))
    end
end)

remote:FireServer("RequestCombatState")
