-- Combat input adapter. It sends intent only; the server owns all combat outcomes.
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
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

local function makeHealthBar(parent, width, height, fillColor)
    local background = Instance.new("Frame")
    background.Name = "HealthBackground"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(31, 34, 39)
    background.BackgroundTransparency = 0.12
    background.BorderSizePixel = 0
    background.ClipsDescendants = true
    background.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = background

    local fill = Instance.new("Frame")
    fill.Name = "HealthFill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.Parent = background

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.78
    stroke.Thickness = 1
    stroke.Parent = background

    return fill
end

local bossHud = Instance.new("ScreenGui")
bossHud.Name = "GiantbackBossHud"
bossHud.DisplayOrder = 34
bossHud.IgnoreGuiInset = true
bossHud.ResetOnSpawn = false
bossHud.Enabled = false
bossHud.Parent = playerGui

local bossPanel = Instance.new("Frame")
bossPanel.Name = "BossPanel"
bossPanel.AnchorPoint = Vector2.new(0.5, 0)
bossPanel.Position = UDim2.new(0.5, 0, 0, 28)
bossPanel.Size = UDim2.new(0.72, 0, 0, 78)
bossPanel.BackgroundColor3 = Color3.fromRGB(29, 27, 38)
bossPanel.BackgroundTransparency = 0.12
bossPanel.BorderSizePixel = 0
bossPanel.Parent = bossHud

local bossPanelConstraint = Instance.new("UISizeConstraint")
bossPanelConstraint.MinSize = Vector2.new(260, 78)
bossPanelConstraint.MaxSize = Vector2.new(560, 78)
bossPanelConstraint.Parent = bossPanel

local bossPanelCorner = Instance.new("UICorner")
bossPanelCorner.CornerRadius = UDim.new(0, 12)
bossPanelCorner.Parent = bossPanel

local bossPanelStroke = Instance.new("UIStroke")
bossPanelStroke.Color = Color3.fromRGB(190, 145, 220)
bossPanelStroke.Transparency = 0.32
bossPanelStroke.Thickness = 1.5
bossPanelStroke.Parent = bossPanel

local bossName = Instance.new("TextLabel")
bossName.Name = "BossName"
bossName.BackgroundTransparency = 1
bossName.Position = UDim2.fromOffset(14, 7)
bossName.Size = UDim2.new(0.68, -14, 0, 25)
bossName.Font = Enum.Font.GothamBold
bossName.Text = "СТРАЖ ПЕЧАТЕЙ"
bossName.TextColor3 = Color3.fromRGB(255, 235, 204)
bossName.TextSize = 17
bossName.TextXAlignment = Enum.TextXAlignment.Left
bossName.Parent = bossPanel

local bossPhaseLabel = Instance.new("TextLabel")
bossPhaseLabel.Name = "BossPhase"
bossPhaseLabel.BackgroundTransparency = 1
bossPhaseLabel.Position = UDim2.new(0.68, 0, 0, 8)
bossPhaseLabel.Size = UDim2.new(0.32, -12, 0, 22)
bossPhaseLabel.Font = Enum.Font.GothamBold
bossPhaseLabel.Text = "ФАЗА I"
bossPhaseLabel.TextColor3 = Color3.fromRGB(206, 174, 244)
bossPhaseLabel.TextSize = 13
bossPhaseLabel.TextXAlignment = Enum.TextXAlignment.Right
bossPhaseLabel.Parent = bossPanel

local bossHealthTrack = Instance.new("Frame")
bossHealthTrack.Name = "BossHealthTrack"
bossHealthTrack.Position = UDim2.new(0, 14, 0, 39)
bossHealthTrack.Size = UDim2.new(1, -28, 0, 17)
bossHealthTrack.BackgroundColor3 = Color3.fromRGB(67, 57, 72)
bossHealthTrack.BorderSizePixel = 0
bossHealthTrack.ClipsDescendants = true
bossHealthTrack.Parent = bossPanel
local bossHealthCorner = Instance.new("UICorner")
bossHealthCorner.CornerRadius = UDim.new(0, 7)
bossHealthCorner.Parent = bossHealthTrack
local bossHealthFill = makeHealthBar(bossHealthTrack, 1, 17, Color3.fromRGB(170, 92, 194))
bossHealthFill.Name = "BossHealthFill"
local bossHealthText = Instance.new("TextLabel")
bossHealthText.Name = "BossHealthText"
bossHealthText.BackgroundTransparency = 1
bossHealthText.Position = UDim2.new(0, 0, 0, 57)
bossHealthText.Size = UDim2.new(1, 0, 0, 16)
bossHealthText.Font = Enum.Font.GothamMedium
bossHealthText.Text = "360 / 360"
bossHealthText.TextColor3 = Color3.fromRGB(224, 216, 231)
bossHealthText.TextSize = 11
bossHealthText.Parent = bossPanel

local function updateBossHud(enemy)
    if not enemy or not enemy.Parent then
        bossHud.Enabled = false
        return
    end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local health = math.max(0, tonumber(enemy:GetAttribute("CombatHealth")) or (humanoid and humanoid.Health) or 0)
    local maxHealth = math.max(1, tonumber(enemy:GetAttribute("CombatMaxHealth")) or (humanoid and humanoid.MaxHealth) or 1)
    local phase = math.clamp(tonumber(enemy:GetAttribute("BossPhase")) or 1, 1, 3)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    bossHealthFill.Size = UDim2.fromScale(ratio, 1)
    bossHealthFill.BackgroundColor3 = phase == 1 and Color3.fromRGB(170, 92, 194)
        or (phase == 2 and Color3.fromRGB(190, 104, 255) or Color3.fromRGB(226, 91, 77))
    bossHealthText.Text = string.format("%d / %d", math.ceil(health), math.ceil(maxHealth))
    bossPhaseLabel.Text = phase == 1 and "ФАЗА I" or (phase == 2 and "ФАЗА II" or "ФАЗА III")
    bossHud.Enabled = health > 0
end

local function bindEnemyHealth(enemy)
    if not enemy:IsA("Model") or enemy:GetAttribute("HealthUiBound") == true then return end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    enemy:SetAttribute("HealthUiBound", true)

    local isBoss = enemy:GetAttribute("IsBoss") == true
    local billboard
    local fill
    if not isBoss then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "LocalEnemyHealthBar"
        billboard.Adornee = root
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = 90
        billboard.Size = UDim2.fromOffset(112, 30)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
        billboard.Parent = playerGui

        local name = Instance.new("TextLabel")
        name.Name = "EnemyName"
        name.BackgroundTransparency = 1
        name.Size = UDim2.new(1, 0, 0, 14)
        name.Font = Enum.Font.GothamBold
        name.Text = humanoid.DisplayName
        name.TextColor3 = Color3.fromRGB(244, 238, 222)
        name.TextStrokeTransparency = 0.45
        name.TextSize = 10
        name.Parent = billboard

        local track = Instance.new("Frame")
        track.Name = "EnemyHealthTrack"
        track.Position = UDim2.fromOffset(0, 17)
        track.Size = UDim2.new(1, 0, 0, 9)
        track.BackgroundColor3 = Color3.fromRGB(38, 39, 43)
        track.BorderSizePixel = 0
        track.ClipsDescendants = true
        track.Parent = billboard
        fill = makeHealthBar(track, 1, 9, Color3.fromRGB(108, 190, 126))
    else
        bossName.Text = humanoid.DisplayName
        bossHud.Enabled = true
    end

    local function refresh()
        local health = math.max(0, tonumber(enemy:GetAttribute("CombatHealth")) or humanoid.Health)
        local maxHealth = math.max(1, tonumber(enemy:GetAttribute("CombatMaxHealth")) or humanoid.MaxHealth)
        local ratio = math.clamp(health / maxHealth, 0, 1)
        if fill then
            fill.Size = UDim2.fromScale(ratio, 1)
            fill.BackgroundColor3 = ratio <= 0.25 and Color3.fromRGB(214, 91, 78)
                or (ratio <= 0.55 and Color3.fromRGB(219, 166, 82) or Color3.fromRGB(108, 190, 126))
            if billboard then billboard.Enabled = health > 0 end
        end
        if isBoss then updateBossHud(enemy) end
    end

    humanoid.HealthChanged:Connect(refresh)
    enemy:GetAttributeChangedSignal("CombatHealth"):Connect(refresh)
    enemy:GetAttributeChangedSignal("CombatMaxHealth"):Connect(refresh)
    if isBoss then
        enemy:GetAttributeChangedSignal("BossPhase"):Connect(refresh)
    end
    humanoid.Died:Connect(function()
        if billboard then billboard:Destroy() end
        if isBoss then bossHud.Enabled = false end
    end)
    enemy.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            if billboard then billboard:Destroy() end
            if isBoss then bossHud.Enabled = false end
        end
    end)
    refresh()
end

CollectionService:GetInstanceAddedSignal("GiantbackEnemy"):Connect(bindEnemyHealth)
for _, enemy in CollectionService:GetTagged("GiantbackEnemy") do
    bindEnemyHealth(enemy)
end

local function showBossSlamTelegraph(enemy)
    if not enemy or not enemy:IsA("Model") or not enemy:IsDescendantOf(Workspace) then return end
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local phase = math.clamp(tonumber(enemy:GetAttribute("BossPhase")) or 1, 1, 3)
    local prefix = "Phase" .. tostring(phase)
    local radius = math.clamp(tonumber(enemy:GetAttribute(prefix .. "SlamRadius")) or 16, 8, 28)
    local warning = math.max(tonumber(enemy:GetAttribute(prefix .. "TelegraphSeconds")) or 0.9, 0.9)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {enemy}
    local floorHit = Workspace:Raycast(root.Position, Vector3.new(0, -24, 0), rayParams)
    local floorPosition = floorHit and floorHit.Position or (root.Position - Vector3.new(0, 3, 0))

    local marker = Instance.new("Part")
    marker.Name = "LocalBossSlamTelegraph"
    marker.Shape = Enum.PartType.Cylinder
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.CastShadow = false
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(255, 111, 74)
    marker.Transparency = 0.42
    marker.Size = Vector3.new(0.16, 1, 1)
    marker.CFrame = CFrame.new(floorPosition + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
    marker.Parent = Workspace

    local grow = TweenService:Create(
        marker,
        TweenInfo.new(warning, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(0.16, radius * 2, radius * 2), Transparency = 0.78}
    )
    grow:Play()
    task.delay(warning + 0.45, function()
        if not marker.Parent then return end
        local fade = TweenService:Create(marker, TweenInfo.new(0.22), {Transparency = 1})
        fade:Play()
        fade.Completed:Once(function()
            if marker.Parent then marker:Destroy() end
        end)
    end)
end

local function showBossPhaseTransition(enemy, phase)
    if not enemy or not enemy:IsA("Model") or not enemy:IsDescendantOf(Workspace) then return end
    phase = math.clamp(tonumber(phase) or 1, 1, 3)
    if phase <= 1 then return end

    local root = enemy:FindFirstChild("HumanoidRootPart")
    local core = enemy:FindFirstChild("SealCore", true)
    if not root then return end

    local accent = phase == 2 and Color3.fromRGB(190, 104, 255) or Color3.fromRGB(255, 105, 91)
    local highlight = Instance.new("Highlight")
    highlight.Name = "LocalBossPhaseHighlight"
    highlight.Adornee = enemy
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillColor = accent
    highlight.OutlineColor = Color3.fromRGB(255, 231, 173)
    highlight.FillTransparency = 0.28
    highlight.OutlineTransparency = 0.08
    highlight.Parent = enemy

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {enemy}
    local floorHit = Workspace:Raycast(root.Position, Vector3.new(0, -24, 0), rayParams)
    local floorPosition = floorHit and floorHit.Position or (root.Position - Vector3.new(0, 3, 0))

    local pulse = Instance.new("Part")
    pulse.Name = "LocalBossPhasePulse"
    pulse.Shape = Enum.PartType.Cylinder
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse.CastShadow = false
    pulse.Material = Enum.Material.Neon
    pulse.Color = accent
    pulse.Transparency = 0.18
    pulse.Size = Vector3.new(0.22, 2, 2)
    pulse.CFrame = CFrame.new(floorPosition + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.rad(90))
    pulse.Parent = Workspace

    TweenService:Create(
        pulse,
        TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(0.22, 30 + phase * 5, 30 + phase * 5), Transparency = 1}
    ):Play()

    if core and core:IsA("BasePart") then
        local originalSize = core.Size
        local targetColor = phase == 2 and Color3.fromRGB(194, 112, 255) or Color3.fromRGB(255, 103, 91)
        TweenService:Create(core, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = originalSize * 1.45,
            Color = targetColor,
        }):Play()
        task.delay(0.24, function()
            if core.Parent then
                TweenService:Create(core, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = originalSize,
                }):Play()
            end
        end)
    end

    task.delay(0.95, function()
        if highlight.Parent then highlight:Destroy() end
        if pulse.Parent then pulse:Destroy() end
    end)
end

local function bindBossTelegraph(enemy)
    if not enemy:IsA("Model") or enemy:GetAttribute("IsBoss") ~= true then return end
    enemy:GetAttributeChangedSignal("BossAttack"):Connect(function()
        if enemy:GetAttribute("BossAttack") == "GroundSlam" then
            showBossSlamTelegraph(enemy)
        end
    end)
    enemy:GetAttributeChangedSignal("BossPhase"):Connect(function()
        showBossPhaseTransition(enemy, enemy:GetAttribute("BossPhase"))
    end)
    if enemy:GetAttribute("BossAttack") == "GroundSlam" then
        showBossSlamTelegraph(enemy)
    end
end

CollectionService:GetInstanceAddedSignal("GiantbackEnemy"):Connect(bindBossTelegraph)
for _, enemy in CollectionService:GetTagged("GiantbackEnemy") do
    bindBossTelegraph(enemy)
end

remote:FireServer("RequestCombatState")
