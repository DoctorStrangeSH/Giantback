-- Server-authoritative first combat slice (C1).
-- Studio setup:
--   * Tag each arena volume BasePart with "GiantbackCombatRegion" and set RegionId
--     to "GroveTraining" or "DuskTraining".
--   * Tag each enemy Model with "GiantbackEnemy". Add a Humanoid and
--     HumanoidRootPart; set EncounterId (currently GroveGrunt01) and RegionId.
-- The server owns target registration, hit checks, damage, enemy attacks and rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local ACTION_RATE_WINDOW = 1
local MAX_ACTIONS_PER_WINDOW = 10
local PLAYER_DAMAGE = 22
local PLAYER_ATTACK_COOLDOWN = 0.65
local PLAYER_ATTACK_RANGE = 8
local PLAYER_ATTACK_BOX = Vector3.new(6, 5, 5)
local ENEMY_AGGRO_RANGE = 34
local ENEMY_ATTACK_RANGE = 6
local ENEMY_ATTACK_DAMAGE = 12
local ENEMY_ATTACK_COOLDOWN = 2.4
local ENEMY_TELEGRAPH_SECONDS = 0.85
local DODGE_DURATION = 0.45
local DODGE_COOLDOWN = 1.5
local BLOCK_DAMAGE_MULTIPLIER = 0.25

local ALLOWED_REGIONS = { GroveTraining = true, DuskTraining = true }
local ALLOWED_WEAPONS = { SwordShield = true }
local REWARD_ENCOUNTERS = { GroveGrunt01 = true }

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

local rewardFunction = ServerStorage:WaitForChild("GiantbackGrantCombatReward", 20)
if not rewardFunction or not rewardFunction:IsA("BindableFunction") then
    warn("Combat rewards are unavailable; enemy rewards will remain disabled.")
    rewardFunction = nil
end

local playerStates = {}
local enemies = {}

local function newPlayerState()
    return {
        windowStartedAt = 0,
        windowActionCount = 0,
        blocking = false,
        dodgingUntil = 0,
        dodgeReadyAt = 0,
        attackReadyAt = 0,
    }
end

local function getCharacterParts(player)
    local character = player.Character
    if not character then return nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then return nil, nil end
    return humanoid, root
end

local function isReady(player)
    return player:GetAttribute("Ready") == true and getCharacterParts(player) ~= nil
end

local function pointInsidePart(part, point)
    local localPoint = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    return math.abs(localPoint.X) <= half.X
        and math.abs(localPoint.Y) <= half.Y
        and math.abs(localPoint.Z) <= half.Z
end

local function getPlayerRegion(player)
    local _, root = getCharacterParts(player)
    if not root then return nil end
    for _, regionPart in CollectionService:GetTagged("GiantbackCombatRegion") do
        if regionPart:IsA("BasePart") and regionPart:IsDescendantOf(Workspace) then
            local regionId = regionPart:GetAttribute("RegionId")
            if ALLOWED_REGIONS[regionId] and pointInsidePart(regionPart, root.Position) then
                player:SetAttribute("CombatRegionId", regionId)
                return regionId
            end
        end
    end
    player:SetAttribute("CombatRegionId", "")
    local state = playerStates[player]
    if state and state.blocking then
        state.blocking = false
        player:SetAttribute("CombatBlocking", false)
    end
    return nil
end

local function clearTransientState(player)
    local state = playerStates[player]
    if not state then return end
    state.blocking = false
    state.dodgingUntil = 0
    state.dodgeReadyAt = 0
    state.attackReadyAt = 0
    player:SetAttribute("CombatBlocking", false)
    player:SetAttribute("CombatDodging", false)
end

local function reject(player, code)
    remote:FireClient(player, "CombatRejected", { code = code })
end

local function sendState(player)
    local state = playerStates[player]
    if not state then return end
    local humanoid = getCharacterParts(player)
    local regionId = getPlayerRegion(player) or ""
    remote:FireClient(player, "CombatState", {
        enabled = true,
        phase = "C1",
        blocking = state.blocking,
        dodging = state.dodgingUntil > os.clock(),
        alive = humanoid ~= nil,
        regionId = regionId,
        weaponId = player:GetAttribute("CombatWeaponId") or "",
    })
end

local function allowRequest(state, now)
    if now - state.windowStartedAt >= ACTION_RATE_WINDOW then
        state.windowStartedAt = now
        state.windowActionCount = 0
    end
    state.windowActionCount += 1
    return state.windowActionCount <= MAX_ACTIONS_PER_WINDOW
end

local function isEnemyModel(instance)
    local current = instance
    while current and current ~= Workspace do
        if enemies[current] then return current end
        current = current.Parent
    end
    return nil
end

local function isEnemyAlive(enemy)
    local entry = enemies[enemy]
    return entry ~= nil
        and enemy:IsDescendantOf(Workspace)
        and entry.humanoid.Parent ~= nil
        and entry.humanoid.Health > 0
end

local function resolveEnemyReward(enemy, entry)
    if entry.rewardResolved then return end
    entry.rewardResolved = true
    if not entry.lastHitBy or not rewardFunction or not REWARD_ENCOUNTERS[entry.encounterId] then return end
    local ok, granted = pcall(function()
        return rewardFunction:Invoke(entry.lastHitBy, entry.encounterId)
    end)
    if not ok or granted ~= true then
        warn("Combat reward was not granted:", entry.encounterId, entry.lastHitBy.UserId)
    end
end

local function registerEnemy(enemy)
    if not enemy:IsA("Model") or enemies[enemy] then return end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    local encounterId = enemy:GetAttribute("EncounterId")
    local regionId = enemy:GetAttribute("RegionId")
    if not humanoid or not root or not root:IsA("BasePart") then
        warn("GiantbackEnemy needs a Humanoid and HumanoidRootPart:", enemy:GetFullName())
        return
    end
    if type(encounterId) ~= "string" or not REWARD_ENCOUNTERS[encounterId]
        or not ALLOWED_REGIONS[regionId] then
        warn("GiantbackEnemy has an unknown EncounterId or RegionId:", enemy:GetFullName())
        return
    end

    local entry = {
        humanoid = humanoid,
        root = root,
        encounterId = encounterId,
        regionId = regionId,
        lastHitBy = nil,
        rewardResolved = false,
        attacking = false,
        nextAttackAt = 0,
    }
    enemies[enemy] = entry
    humanoid.Died:Connect(function()
        resolveEnemyReward(enemy, entry)
        enemy:SetAttribute("CombatState", "Defeated")
    end)
    enemy:SetAttribute("CombatHealth", humanoid.Health)
    enemy:SetAttribute("CombatMaxHealth", humanoid.MaxHealth)

    task.spawn(function()
        while enemy.Parent and isEnemyAlive(enemy) do
            local targetPlayer, targetRoot, targetHumanoid
            local bestDistance = ENEMY_AGGRO_RANGE
            for _, player in Players:GetPlayers() do
                if player:GetAttribute("Ready") == true and getPlayerRegion(player) == entry.regionId then
                    local playerHumanoid, playerRoot = getCharacterParts(player)
                    if playerHumanoid and playerRoot then
                        local distance = (playerRoot.Position - root.Position).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            targetPlayer, targetRoot, targetHumanoid = player, playerRoot, playerHumanoid
                        end
                    end
                end
            end

            if targetPlayer and targetRoot and targetHumanoid then
                if bestDistance > ENEMY_ATTACK_RANGE then
                    enemy:SetAttribute("CombatState", "Approach")
                    humanoid:MoveTo(targetRoot.Position)
                elseif os.clock() >= entry.nextAttackAt and not entry.attacking then
                    entry.attacking = true
                    entry.nextAttackAt = os.clock() + ENEMY_ATTACK_COOLDOWN
                    enemy:SetAttribute("CombatState", "Telegraph")
                    task.wait(ENEMY_TELEGRAPH_SECONDS)
                    if isEnemyAlive(enemy) and targetPlayer.Parent and targetPlayer.Character then
                        local currentHumanoid, currentRoot = getCharacterParts(targetPlayer)
                        if currentHumanoid and currentRoot
                            and getPlayerRegion(targetPlayer) == entry.regionId
                            and (currentRoot.Position - root.Position).Magnitude <= ENEMY_ATTACK_RANGE + 0.75 then
                            local playerState = playerStates[targetPlayer]
                            local dodging = playerState and playerState.dodgingUntil > os.clock()
                            if not dodging then
                                local damage = ENEMY_ATTACK_DAMAGE
                                if playerState and playerState.blocking then
                                    local towardEnemy = (root.Position - currentRoot.Position).Unit
                                    if currentRoot.CFrame.LookVector:Dot(towardEnemy) >= 0.35 then
                                        damage = math.max(1, math.floor(damage * BLOCK_DAMAGE_MULTIPLIER))
                                    end
                                end
                                currentHumanoid:TakeDamage(damage)
                            end
                        end
                    end
                    if enemy.Parent then enemy:SetAttribute("CombatState", "Recover") end
                    task.wait(0.35)
                    entry.attacking = false
                else
                    enemy:SetAttribute("CombatState", "Approach")
                end
            else
                enemy:SetAttribute("CombatState", "Idle")
                humanoid:MoveTo(root.Position)
            end
            task.wait(0.2)
        end
    end)
end

local function performAttack(player, state, now)
    if now < state.attackReadyAt then
        reject(player, "AttackCooldown")
        return
    end
    local _, root = getCharacterParts(player)
    if not root then return end
    state.attackReadyAt = now + PLAYER_ATTACK_COOLDOWN

    local forward = root.CFrame.LookVector
    local hitCFrame = CFrame.lookAt(root.Position + forward * 3.5, root.Position + forward * 4.5)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = { player.Character }

    local hitThisSwing = {}
    for _, part in Workspace:GetPartBoundsInBox(hitCFrame, PLAYER_ATTACK_BOX, overlap) do
        local enemy = isEnemyModel(part)
        if enemy and not hitThisSwing[enemy] and isEnemyAlive(enemy) then
            local entry = enemies[enemy]
            if entry.regionId == getPlayerRegion(player) then
                local offset = entry.root.Position - root.Position
                if offset.Magnitude <= PLAYER_ATTACK_RANGE and root.CFrame.LookVector:Dot(offset.Unit) >= 0.25 then
                    hitThisSwing[enemy] = true
                    entry.lastHitBy = player
                    entry.humanoid:TakeDamage(PLAYER_DAMAGE)
                    enemy:SetAttribute("CombatHealth", math.max(0, entry.humanoid.Health))
                    remote:FireClient(player, "CombatHit", { enemyId = enemy:GetAttribute("EnemyId") or enemy.Name })
                end
            end
        end
    end
end

local function handleAction(player, action, ...)
    local state = playerStates[player]
    if not state then return end
    if type(action) ~= "string" or #action > 32 then
        reject(player, "InvalidAction")
        return
    end
    if select("#", ...) ~= 0 then
        reject(player, "UnexpectedPayload")
        return
    end
    local now = os.clock()
    if not allowRequest(state, now) then
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
    if action == "BlockEnd" then
        state.blocking = false
        player:SetAttribute("CombatBlocking", false)
        return
    end
    if not getPlayerRegion(player) then
        reject(player, "CombatRegionRequired")
        return
    end
    local weaponId = player:GetAttribute("CombatWeaponId")
    if type(weaponId) ~= "string" or not ALLOWED_WEAPONS[weaponId] then
        reject(player, "NoServerEquippedWeapon")
        return
    end

    if action == "Attack" then
        performAttack(player, state, now)
    elseif action == "BlockStart" then
        state.blocking = true
        player:SetAttribute("CombatBlocking", true)
    elseif action == "BlockEnd" then
        state.blocking = false
        player:SetAttribute("CombatBlocking", false)
    elseif action == "Dodge" then
        if now < state.dodgeReadyAt then
            reject(player, "DodgeCooldown")
            return
        end
        local _, root = getCharacterParts(player)
        if not root then return end
        state.dodgingUntil = now + DODGE_DURATION
        state.dodgeReadyAt = now + DODGE_COOLDOWN
        player:SetAttribute("CombatDodging", true)
        root:ApplyImpulse(root.CFrame.LookVector * root.AssemblyMass * 38)
        task.delay(DODGE_DURATION, function()
            if playerStates[player] == state and state.dodgingUntil <= os.clock() then
                player:SetAttribute("CombatDodging", false)
            end
        end)
    end
end

local function registerPlayer(player)
    if playerStates[player] then return end
    playerStates[player] = newPlayerState()
    player:SetAttribute("CombatBlocking", false)
    player:SetAttribute("CombatDodging", false)
    player:SetAttribute("CombatWeaponId", "SwordShield")

    player.CharacterAdded:Connect(function()
        clearTransientState(player)
    end)
    if player.Character then clearTransientState(player) end
end

remote.OnServerEvent:Connect(handleAction)
Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(function(player)
    clearTransientState(player)
    playerStates[player] = nil
end)
CollectionService:GetInstanceAddedSignal("GiantbackEnemy"):Connect(registerEnemy)
for _, enemy in CollectionService:GetTagged("GiantbackEnemy") do
    registerEnemy(enemy)
end
for _, player in Players:GetPlayers() do
    registerPlayer(player)
end
