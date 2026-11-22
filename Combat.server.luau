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
local PathfindingService = game:GetService("PathfindingService")

local ACTION_RATE_WINDOW = 1
local MAX_ACTIONS_PER_WINDOW = 10
local COMBO_DAMAGE = {18, 22, 32}
local COMBO_COOLDOWN = {0.48, 0.48, 0.72}
local COMBO_WINDOW_SECONDS = 1.15
local PLAYER_ATTACK_RANGE = 8
local PLAYER_FINISHER_RANGE = 8.5
local PLAYER_ATTACK_BOX = Vector3.new(6, 5, 5)
local PLAYER_FINISHER_BOX = Vector3.new(7, 6, 6)
local CHARGE_MIN_SECONDS = 0.45
local CHARGE_MAX_SECONDS = 1.6
local CHARGE_DAMAGE_MIN = 30
local CHARGE_DAMAGE_MAX = 52
local CHARGE_COOLDOWN = 1.35
local CHARGE_ATTACK_BOX = Vector3.new(8, 6, 7)
local CHARGE_ATTACK_RANGE = 9
local ENEMY_AGGRO_RANGE = 34
local ENEMY_PATH_REFRESH_SECONDS = 1.15
local ENEMY_PATH_AGENT = {AgentRadius = 2, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 4}
local ENEMY_ATTACK_RANGE = 6
local ENEMY_ATTACK_DAMAGE = 12
local ENEMY_ATTACK_COOLDOWN = 2.4
local ENEMY_TELEGRAPH_SECONDS = 0.85
local DODGE_DURATION = 0.45
local DODGE_COOLDOWN = 1.5
local BLOCK_DAMAGE_MULTIPLIER = 0.25

local ALLOWED_REGIONS = { GroveTraining = true, DuskTraining = true, Rootvault = true }
local ALLOWED_WEAPONS = { SwordShield = true }
local KNOWN_ENCOUNTERS = {
    GroveGrunt01 = true,
    GroveScout02 = true,
    RootvaultSentinel01 = true,
    RootvaultStalker01 = true,
    RootvaultSealKeeper01 = true,
    RootvaultSealMinion = true,
}
local REWARD_ENCOUNTERS = {
    GroveGrunt01 = true,
    GroveScout02 = true,
    RootvaultSentinel01 = true,
    RootvaultStalker01 = true,
    RootvaultSealKeeper01 = true,
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
        comboStep = 0,
        comboExpiresAt = 0,
        chargingStartedAt = 0,
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
    state.comboStep = 0
    state.comboExpiresAt = 0
    state.chargingStartedAt = 0
    player:SetAttribute("CombatCharging", false)
    player:SetAttribute("CombatComboStep", 0)
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
    if not rewardFunction or not REWARD_ENCOUNTERS[entry.encounterId] then return end

    -- Every player who landed a server-validated hit earns their own first-clear reward.
    -- This keeps co-op fair without trusting client-supplied party or damage data.
    for contributor in entry.contributors do
        if contributor.Parent == Players then
            local granted = false
            local lastError = nil
            -- DataStore writes can fail transiently. The reward callback is idempotent,
            -- so retrying is safe; an already-completed encounter is treated as success.
            for attempt = 1, 5 do
                local ok, result = pcall(function()
                    return rewardFunction:Invoke(contributor, entry.encounterId)
                end)
                if ok and result == true then
                    granted = true
                    break
                end
                lastError = ok and "RewardSaveRejected" or tostring(result)
                if contributor.Parent ~= Players then break end
                if attempt < 5 then
                    task.wait(0.75 * (2 ^ (attempt - 1)))
                end
            end
            if not granted then
                warn("Combat reward retries exhausted:", entry.encounterId, contributor.UserId, lastError)
            end
        end
    end
end

local function activateRootvaultBossMinions()
    local activated = 0
    for _, minion in CollectionService:GetTagged("GiantbackDormantBossMinion") do
        if minion:IsA("Model") and minion:IsDescendantOf(Workspace)
            and minion:GetAttribute("RegionId") == "Rootvault"
            and minion:GetAttribute("Activated") ~= true then
            minion:SetAttribute("Activated", true)
            minion:SetAttribute("CombatState", "Idle")
            for _, descendant in minion:GetDescendants() do
                if descendant:IsA("BasePart") then
                    descendant.Transparency = descendant.Name == "HumanoidRootPart" and 1 or 0
                end
            end
            CollectionService:RemoveTag(minion, "GiantbackDormantBossMinion")
            CollectionService:AddTag(minion, "GiantbackEnemy")
            activated += 1
        end
    end
    return activated
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
    if type(encounterId) ~= "string" or not KNOWN_ENCOUNTERS[encounterId]
        or not ALLOWED_REGIONS[regionId] then
        warn("GiantbackEnemy has an unknown EncounterId or RegionId:", enemy:GetFullName())
        return
    end

    local entry = {
        humanoid = humanoid,
        root = root,
        encounterId = encounterId,
        regionId = regionId,
        contributors = {},
        rewardResolved = false,
        attacking = false,
        nextAttackAt = 0,
        nextPathAt = 0,
        lastMoveGoal = nil,
        aggroRange = math.clamp(tonumber(enemy:GetAttribute("AggroRange")) or ENEMY_AGGRO_RANGE, 8, 80),
        attackRange = math.clamp(tonumber(enemy:GetAttribute("AttackRange")) or ENEMY_ATTACK_RANGE, 3, 10),
        attackDamage = math.clamp(math.floor(tonumber(enemy:GetAttribute("AttackDamage")) or ENEMY_ATTACK_DAMAGE), 1, 30),
        attackCooldown = math.clamp(tonumber(enemy:GetAttribute("AttackCooldown")) or ENEMY_ATTACK_COOLDOWN, 1, 8),
        telegraphSeconds = math.clamp(tonumber(enemy:GetAttribute("TelegraphSeconds")) or ENEMY_TELEGRAPH_SECONDS, 0.35, 2),
        pathRefreshSeconds = math.clamp(tonumber(enemy:GetAttribute("PathRefreshSeconds")) or ENEMY_PATH_REFRESH_SECONDS, 0.5, 3),
    }
    enemies[enemy] = entry
    entry.isBoss = enemy:GetAttribute("IsBoss") == true
    entry.bossPhase = 1
    if entry.isBoss then
        enemy:SetAttribute("BossPhase", 1)
        humanoid.HealthChanged:Connect(function(health)
            enemy:SetAttribute("CombatHealth", math.max(0, health))
            local ratio = health / math.max(1, humanoid.MaxHealth)
            local nextPhase = ratio <= 0.25 and 3 or (ratio <= 0.6 and 2 or 1)
            if nextPhase <= entry.bossPhase or not isEnemyAlive(enemy) then return end
            entry.bossPhase = nextPhase
            local prefix = "Phase" .. tostring(nextPhase)
            humanoid.WalkSpeed = math.clamp(tonumber(enemy:GetAttribute(prefix .. "WalkSpeed")) or humanoid.WalkSpeed, 4, 20)
            entry.attackDamage = math.clamp(math.floor(tonumber(enemy:GetAttribute(prefix .. "AttackDamage")) or entry.attackDamage), 1, 30)
            entry.attackCooldown = math.clamp(tonumber(enemy:GetAttribute(prefix .. "AttackCooldown")) or entry.attackCooldown, 1, 8)
            entry.telegraphSeconds = math.clamp(tonumber(enemy:GetAttribute(prefix .. "TelegraphSeconds")) or entry.telegraphSeconds, 0.35, 2)
            entry.pathRefreshSeconds = math.clamp(tonumber(enemy:GetAttribute(prefix .. "PathRefreshSeconds")) or entry.pathRefreshSeconds, 0.5, 3)
            enemy:SetAttribute("BossPhase", nextPhase)
            enemy:SetAttribute("CombatState", "PhaseTransition")
            if nextPhase == 3 and not entry.minionsSummoned then
                entry.minionsSummoned = true
                local activated = activateRootvaultBossMinions()
                enemy:SetAttribute("SummonedMinions", activated)
            end
        end)
    else
        humanoid.HealthChanged:Connect(function(health)
            enemy:SetAttribute("CombatHealth", math.max(0, health))
        end)
    end
    humanoid.Died:Connect(function()
        resolveEnemyReward(enemy, entry)
        enemy:SetAttribute("CombatState", "Defeated")
    end)
    enemy:SetAttribute("CombatHealth", humanoid.Health)
    enemy:SetAttribute("CombatMaxHealth", humanoid.MaxHealth)

    task.spawn(function()
        while enemy.Parent and isEnemyAlive(enemy) do
            local targetPlayer, targetRoot, targetHumanoid
            local bestDistance = entry.aggroRange
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
                if bestDistance > entry.attackRange then
                    enemy:SetAttribute("CombatState", "Approach")
                    local now = os.clock()
                    if now >= entry.nextPathAt then
                        entry.nextPathAt = now + entry.pathRefreshSeconds
                        local path = PathfindingService:CreatePath(ENEMY_PATH_AGENT)
                        local pathOk = pcall(function()
                            path:ComputeAsync(root.Position, targetRoot.Position)
                        end)
                        if pathOk and path.Status == Enum.PathStatus.Success then
                            local waypoints = path:GetWaypoints()
                            local nextWaypoint = waypoints[2] or waypoints[1]
                            if nextWaypoint then
                                entry.lastMoveGoal = nextWaypoint.Position
                                humanoid:MoveTo(nextWaypoint.Position)
                            else
                                entry.lastMoveGoal = targetRoot.Position
                                humanoid:MoveTo(targetRoot.Position)
                            end
                        else
                            -- The arena is intentionally open; direct pursuit is a safe fallback
                            -- when Roblox pathfinding has no route or is temporarily unavailable.
                            entry.lastMoveGoal = targetRoot.Position
                            humanoid:MoveTo(targetRoot.Position)
                        end
                    end
                elseif os.clock() >= entry.nextAttackAt and not entry.attacking then
                    entry.attacking = true
                    entry.nextAttackAt = os.clock() + entry.attackCooldown
                    entry.attackSequence = (entry.attackSequence or 0) + 1
                    local useGroundSlam = entry.isBoss and entry.bossPhase >= 2 and entry.attackSequence % 2 == 0

                    if useGroundSlam then
                        local phasePrefix = "Phase" .. tostring(entry.bossPhase)
                        local slamRadius = math.clamp(tonumber(enemy:GetAttribute(phasePrefix .. "SlamRadius")) or 16, 8, 28)
                        local slamDamage = math.clamp(math.floor(tonumber(enemy:GetAttribute(phasePrefix .. "SlamDamage")) or entry.attackDamage), 1, 30)
                        enemy:SetAttribute("BossAttack", "GroundSlam")
                        enemy:SetAttribute("CombatState", "BossSlamTelegraph")
                        task.wait(math.max(entry.telegraphSeconds, 0.9))

                        if isEnemyAlive(enemy) then
                            for _, player in Players:GetPlayers() do
                                if player:GetAttribute("Ready") == true and getPlayerRegion(player) == entry.regionId then
                                    local currentHumanoid, currentRoot = getCharacterParts(player)
                                    if currentHumanoid and currentRoot
                                        and (currentRoot.Position - root.Position).Magnitude <= slamRadius then
                                        local playerState = playerStates[player]
                                        local dodging = playerState and playerState.dodgingUntil > os.clock()
                                        if not dodging then
                                            local damage = slamDamage
                                            if playerState and playerState.blocking then
                                                local towardBoss = root.Position - currentRoot.Position
                                                if towardBoss.Magnitude > 0
                                                    and currentRoot.CFrame.LookVector:Dot(towardBoss.Unit) >= 0.35 then
                                                    damage = math.max(1, math.floor(damage * BLOCK_DAMAGE_MULTIPLIER))
                                                end
                                            end
                                            currentHumanoid:TakeDamage(damage)
                                        end
                                    end
                                end
                            end
                        end
                        enemy:SetAttribute("BossAttack", "")
                    else
                        enemy:SetAttribute("CombatState", "Telegraph")
                        task.wait(entry.telegraphSeconds)
                        if isEnemyAlive(enemy) and targetPlayer.Parent and targetPlayer.Character then
                            local currentHumanoid, currentRoot = getCharacterParts(targetPlayer)
                            if currentHumanoid and currentRoot
                                and getPlayerRegion(targetPlayer) == entry.regionId
                                and (currentRoot.Position - root.Position).Magnitude <= entry.attackRange + 0.75 then
                                local playerState = playerStates[targetPlayer]
                                local dodging = playerState and playerState.dodgingUntil > os.clock()
                                if not dodging then
                                    local damage = entry.attackDamage
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
                    end
                    if enemy.Parent then
                        enemy:SetAttribute("BossAttack", "")
                        enemy:SetAttribute("CombatState", "Recover")
                    end
                    task.wait(0.35)
                    entry.attacking = false
                else
                    enemy:SetAttribute("CombatState", "Approach")
                end
            else
                enemy:SetAttribute("CombatState", "Idle")
                entry.lastMoveGoal = nil
                entry.nextPathAt = 0
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
    -- Three deliberate server-timed strikes. Missing the input window resets to strike one.
    if now > state.comboExpiresAt then
        state.comboStep = 0
    end
    state.comboStep = state.comboStep % #COMBO_DAMAGE + 1
    local comboStep = state.comboStep
    local isFinisher = comboStep == #COMBO_DAMAGE
    state.comboExpiresAt = now + COMBO_WINDOW_SECONDS
    state.attackReadyAt = now + COMBO_COOLDOWN[comboStep]
    player:SetAttribute("CombatComboStep", comboStep)

    local forward = root.CFrame.LookVector
    local hitCFrame = CFrame.lookAt(root.Position + forward * 3.5, root.Position + forward * 4.5)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = { player.Character }

    local hitThisSwing = {}
    local attackBox = isFinisher and PLAYER_FINISHER_BOX or PLAYER_ATTACK_BOX
    local attackRange = isFinisher and PLAYER_FINISHER_RANGE or PLAYER_ATTACK_RANGE
    for _, part in Workspace:GetPartBoundsInBox(hitCFrame, attackBox, overlap) do
        local enemy = isEnemyModel(part)
        if enemy and not hitThisSwing[enemy] and isEnemyAlive(enemy) then
            local entry = enemies[enemy]
            if entry.regionId == getPlayerRegion(player) then
                local offset = entry.root.Position - root.Position
                if offset.Magnitude <= attackRange and root.CFrame.LookVector:Dot(offset.Unit) >= 0.25 then
                    hitThisSwing[enemy] = true
                    entry.contributors[player] = true
                    entry.humanoid:TakeDamage(COMBO_DAMAGE[comboStep])
                    if isFinisher and entry.root.Parent then
                        -- Server-owned impact push: ordinary enemies are displaced clearly;
                        -- bosses resist the launch so the finisher never skips their phase loop.
                        local pushDirection = Vector3.new(forward.X, 0, forward.Z)
                        if pushDirection.Magnitude > 0 then
                            local resistance = entry.isBoss and 0.28 or 1
                            local impulse = pushDirection.Unit * entry.root.AssemblyMass * 24 * resistance
                                + Vector3.new(0, entry.root.AssemblyMass * 5 * resistance, 0)
                            entry.root:ApplyImpulse(impulse)
                        end
                    end
                    enemy:SetAttribute("CombatHealth", math.max(0, entry.humanoid.Health))
                    remote:FireClient(player, "CombatHit", {
                        enemyId = enemy:GetAttribute("EnemyId") or enemy.Name,
                        comboStep = comboStep,
                        finisher = isFinisher,
                    })
                end
            end
        end
    end
end

local function performChargedAttack(player, state, now)
    local startedAt = state.chargingStartedAt
    state.chargingStartedAt = 0
    player:SetAttribute("CombatCharging", false)
    if startedAt <= 0 then
        reject(player, "ChargeNotStarted")
        return
    end
    local chargeSeconds = math.clamp(now - startedAt, 0, CHARGE_MAX_SECONDS)
    if chargeSeconds < CHARGE_MIN_SECONDS then
        reject(player, "ChargeTooShort")
        return
    end
    if now < state.attackReadyAt then
        reject(player, "AttackCooldown")
        return
    end
    if state.blocking then
        reject(player, "CannotChargeWhileBlocking")
        return
    end

    local _, root = getCharacterParts(player)
    if not root then return end
    local chargeRatio = (chargeSeconds - CHARGE_MIN_SECONDS)
        / (CHARGE_MAX_SECONDS - CHARGE_MIN_SECONDS)
    local damage = math.floor(CHARGE_DAMAGE_MIN
        + (CHARGE_DAMAGE_MAX - CHARGE_DAMAGE_MIN) * chargeRatio + 0.5)
    state.attackReadyAt = now + CHARGE_COOLDOWN
    state.comboStep = 0
    state.comboExpiresAt = 0
    player:SetAttribute("CombatComboStep", 0)

    local forward = root.CFrame.LookVector
    local hitCFrame = CFrame.lookAt(root.Position + forward * 4, root.Position + forward * 5)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = { player.Character }
    local hitThisSwing = {}
    for _, part in Workspace:GetPartBoundsInBox(hitCFrame, CHARGE_ATTACK_BOX, overlap) do
        local enemy = isEnemyModel(part)
        if enemy and not hitThisSwing[enemy] and isEnemyAlive(enemy) then
            local entry = enemies[enemy]
            if entry.regionId == getPlayerRegion(player) then
                local offset = entry.root.Position - root.Position
                if offset.Magnitude <= CHARGE_ATTACK_RANGE
                    and root.CFrame.LookVector:Dot(offset.Unit) >= 0.2 then
                    hitThisSwing[enemy] = true
                    entry.contributors[player] = true
                    entry.humanoid:TakeDamage(damage)
                    if entry.root.Parent then
                        local pushDirection = Vector3.new(forward.X, 0, forward.Z)
                        if pushDirection.Magnitude > 0 then
                            local resistance = entry.isBoss and 0.2 or 1
                            local impulse = pushDirection.Unit * entry.root.AssemblyMass * 34 * resistance
                                + Vector3.new(0, entry.root.AssemblyMass * 7 * resistance, 0)
                            entry.root:ApplyImpulse(impulse)
                        end
                    end
                    enemy:SetAttribute("CombatHealth", math.max(0, entry.humanoid.Health))
                    remote:FireClient(player, "CombatHit", {
                        enemyId = enemy:GetAttribute("EnemyId") or enemy.Name,
                        charged = true,
                        chargeRatio = chargeRatio,
                        damage = damage,
                    })
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
    if action ~= "Attack" and action ~= "BlockStart" and action ~= "BlockEnd" and action ~= "Dodge"
        and action ~= "ChargeStart" and action ~= "ChargeRelease" then
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
    if action == "ChargeStart" then
        if state.blocking then
            reject(player, "CannotChargeWhileBlocking")
            return
        end
        if state.chargingStartedAt > 0 then return end
        if now < state.attackReadyAt then
            reject(player, "AttackCooldown")
            return
        end
        state.chargingStartedAt = now
        state.comboStep = 0
        state.comboExpiresAt = 0
        player:SetAttribute("CombatComboStep", 0)
        player:SetAttribute("CombatCharging", true)
        return
    elseif action == "ChargeRelease" then
        performChargedAttack(player, state, now)
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
    player:SetAttribute("CombatComboStep", 0)
    player:SetAttribute("CombatCharging", false)

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
