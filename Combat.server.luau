-- Server-owned combat protocol foundation. C0 intentionally exposes no damaging gameplay yet.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ACTION_RATE_WINDOW = 1
local MAX_ACTIONS_PER_WINDOW = 10
local COMBAT_REGIONS = {
    GroveTraining = true,
    DuskTraining = true,
}
local COMBAT_WEAPONS = {
    SwordShield = true,
    Bow = true,
    Staff = true,
}

local remote = ReplicatedStorage:FindFirstChild("CombatAction")
if remote and not remote:IsA("RemoteEvent") then
    remote:Destroy()
    remote = nil
end
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "CombatAction"
    remote.Parent = ReplicatedStorage
end

local playerStates = {}

local function newState()
    return {
        windowStartedAt = 0,
        windowActionCount = 0,
        blocking = false,
        dodgingUntil = 0,
        attackReadyAt = 0,
    }
end

local function clearTransientState(player)
    local state = playerStates[player]
    if not state then return end
    state.blocking = false
    state.dodgingUntil = 0
    state.attackReadyAt = 0
    player:SetAttribute("CombatBlocking", false)
    player:SetAttribute("CombatDodging", false)
end

local function sendState(player)
    local state = playerStates[player]
    if not state then return end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    remote:FireClient(player, "CombatState", {
        enabled = false,
        phase = "C0",
        blocking = state.blocking,
        dodging = state.dodgingUntil > os.clock(),
        alive = humanoid ~= nil and humanoid.Health > 0,
        regionId = player:GetAttribute("CombatRegionId") or "",
        weaponId = player:GetAttribute("CombatWeaponId") or "",
    })
end

local function reject(player, code)
    remote:FireClient(player, "CombatRejected", {code = code})
end

local function isAlive(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

local function isReady(player)
    return player:GetAttribute("Ready") == true and isAlive(player)
end

local function isAllowedRegion(player)
    local regionId = player:GetAttribute("CombatRegionId")
    return type(regionId) == "string" and COMBAT_REGIONS[regionId] == true
end

local function hasServerEquippedWeapon(player)
    local weaponId = player:GetAttribute("CombatWeaponId")
    return type(weaponId) == "string" and COMBAT_WEAPONS[weaponId] == true
end

local function allowRequest(player, state, now)
    if now - state.windowStartedAt >= ACTION_RATE_WINDOW then
        state.windowStartedAt = now
        state.windowActionCount = 0
    end
    state.windowActionCount += 1
    if state.windowActionCount > MAX_ACTIONS_PER_WINDOW then
        return false
    end
    return true
end

local function handleAction(player, action, payload)
    local state = playerStates[player]
    if not state then return end

    if type(action) ~= "string" or #action > 32 then
        reject(player, "InvalidAction")
        return
    end
    if payload ~= nil then
        reject(player, "UnexpectedPayload")
        return
    end

    local now = os.clock()
    if not allowRequest(player, state, now) then
        reject(player, "RateLimited")
        return
    end

    if action == "RequestCombatState" then
        sendState(player)
        return
    end

    if action ~= "Attack" and action ~= "BlockStart" and action ~= "BlockEnd" and action ~= "Dodge" then
        reject(player, "UnknownAction")
        return
    end

    if not isReady(player) then
        reject(player, "PlayerNotReady")
        return
    end
    if not isAllowedRegion(player) then
        reject(player, "CombatRegionRequired")
        return
    end
    if not hasServerEquippedWeapon(player) then
        reject(player, "NoServerEquippedWeapon")
        return
    end

    -- C0 establishes and validates the remote contract only.
    -- C1 will implement server-owned hit detection and combat state transitions.
    reject(player, "CombatNotEnabled")
end

local function registerPlayer(player)
    if playerStates[player] then return end
    playerStates[player] = newState()
    player:SetAttribute("CombatBlocking", false)
    player:SetAttribute("CombatDodging", false)

    player.CharacterAdded:Connect(function(character)
        clearTransientState(player)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.Died:Connect(function()
                clearTransientState(player)
            end)
        end
    end)

    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                clearTransientState(player)
            end)
        end
    end
end

remote.OnServerEvent:Connect(handleAction)
Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(function(player)
    clearTransientState(player)
    playerStates[player] = nil
end)

for _, player in Players:GetPlayers() do
    registerPlayer(player)
end
