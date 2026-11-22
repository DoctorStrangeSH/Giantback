-- Combat input adapter. It sends intent only; the server owns all combat outcomes.
local ContextActionService = game:GetService("ContextActionService")
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

remote.OnClientEvent:Connect(function(message, data)
    if message == "CombatRejected" and type(data) == "table" then
        -- Cooldown/region feedback is deliberately non-blocking; the main HUD
        -- remains owned by the existing GiantbackHUD and Album interfaces.
        if data.code == "CombatRegionRequired" then
            return
        end
    end
end)

remote:FireServer("RequestCombatState")
