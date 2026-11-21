local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local store
if not RunService:IsStudio() then
    store = game:GetService("DataStoreService"):GetDataStore("GiantbackAlbum_v1")
end
local event = Instance.new("RemoteEvent")
event.Name = "AlbumAction"
event.Parent = Storage
local giant = workspace.Mossback
if not Storage:WaitForChild("GiantbackVisualsReady", 12) then
    warn("Giantback visual layer did not finish in time; continuing with base models.")
end
local pets = {Fox = "Лисёнок-корешок", Moth = "Лунная моль"}
local progress = {"Fox", "Moth", "Seed", "Flower", "Timber", "Lantern", "Lit"}
local sessions = {}
local atDusk, sailing = false, false
giant:SetAttribute("Dock", "Grove")
local homePivot = giant:GetPivot()

local function tip(player, message)
    event:FireClient(player, message)
end

local function save(player)
    local session = sessions[player]
    if not session or not session.online then return end
    local snapshot = {}
    for _, key in progress do snapshot[key] = player:GetAttribute(key) == true end
    local ok, err = pcall(function()
        store:UpdateAsync(tostring(player.UserId), function(old)
            old = old or {}
            for _, key in progress do old[key] = old[key] or snapshot[key] end
            return old
        end)
    end)
    if not ok then warn("Album save:", err) end
end

local function init(player)
    if sessions[player] then return end
    local session = {}
    sessions[player] = session
    player.RespawnLocation = giant.HomeSpawn
    if not RunService:IsStudio() then
        local ok, data = pcall(function() return store:GetAsync(tostring(player.UserId)) end)
        if sessions[player] ~= session then return end
        session.online = ok
        if ok and type(data) == "table" then
            for _, key in progress do player:SetAttribute(key, data[key] == true) end
        end
        if not ok then player:SetAttribute("OfflineAlbum", true) end
    end
    player:SetAttribute("Ready", true)
end
Players.PlayerAdded:Connect(init)
for _, player in Players:GetPlayers() do task.spawn(init, player) end
Players.PlayerRemoving:Connect(function(player)
    save(player)
    sessions[player] = nil
end)
game:BindToClose(function()
    local pending = 0
    for _, player in Players:GetPlayers() do
        pending += 1
        task.spawn(function() save(player) pending -= 1 end)
    end
    while pending > 0 do task.wait() end
end)
task.spawn(function()
    while task.wait(60) do
        for _, player in Players:GetPlayers() do task.spawn(save, player) end
    end
end)

local function prompt(part, title, verb, callback)
    local p = Instance.new("ProximityPrompt")
    p.ObjectText, p.ActionText = title, verb
    p.RequiresLineOfSight = false
    p.MaxActivationDistance = 9
    p.Parent = part
    p.Triggered:Connect(function(player)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and player:GetAttribute("Ready") and (root.Position-part.Position).Magnitude <= 12 then
            callback(player)
        end
    end)
    return p
end

local function encounter(id, island, height)
    local nest = island.Nest
    local model = Storage[id]:Clone()
    model.Parent = island
    model:PivotTo(CFrame.new(nest.Position + Vector3.new(0,height,0)) * CFrame.Angles(0,math.pi,0))
    prompt(nest,pets[id],"Подружиться",function(player)
        player:SetAttribute(id,true)
        player:SetAttribute("Companion",id)
        tip(player,pets[id] .. " теперь с тобой!")
    end)
end
encounter("Fox",workspace.Grove,1.8)
encounter("Moth",workspace.Dusk,3.5)

event.OnServerEvent:Connect(function(player, action)
    if typeof(action) ~= "string" or not player:GetAttribute("Ready") then return end
    if pets[action] and player:GetAttribute(action) then player:SetAttribute("Companion",action) end
end)
prompt(workspace.Grove.Trail,"Следы в траве","Попросить лисёнка искать",function(player)
    if player:GetAttribute("Companion") ~= "Fox" then return tip(player,"Позови лисёнка из альбома.") end
    if player:GetAttribute("Seed") then return tip(player,"Семя уже найдено. Лунная моль поможет ему расцвести.") end
    player:SetAttribute("Seed",true)
    tip(player,"Лисёнок выкопал лунное семя! Отправляйся за молью.")
end)
prompt(giant.Planter,"Сад у дома","Разбудить цветок",function(player)
    if player:GetAttribute("Flower") then return tip(player,"Твой лунный цветок уже расцвёл.") end
    if not player:GetAttribute("Seed") then return tip(player,"Лисёнок чует семя на тропе возле гнезда.") end
    if player:GetAttribute("Companion") ~= "Moth" then return tip(player,"Позови лунную моль из альбома.") end
    player:SetAttribute("Flower",true)
    tip(player,"Моль расправила крылья. Твой первый лунный цветок расцвёл!")
end)

prompt(workspace.Grove.Driftwood,"Коряга на берегу","Искать сухие ветви",function(player)
    if not player:GetAttribute("Flower") then return tip(player,"Сначала вырасти лунный цветок у дома.") end
    if player:GetAttribute("Timber") then return tip(player,"Ветви уже собраны. Площадка рядом со штурвалом.") end
    if player:GetAttribute("Companion") ~= "Fox" then return tip(player,"Позови лисёнка. Он найдёт крепкие ветви.") end
    player:SetAttribute("Timber",true)
    tip(player,"Лисёнок нашёл ветви для садового фонаря!")
end)
prompt(giant.LanternBase,"Садовый фонарь","Осмотреть площадку",function(player)
    if not player:GetAttribute("Timber") then return tip(player,"После цветения возьми лисёнка к коряге в Солнечной роще.") end
    if not player:GetAttribute("Lantern") then
        player:SetAttribute("Lantern",true)
        return tip(player,"Фонарь построен! Позови моль, чтобы зажечь его.")
    end
    if player:GetAttribute("Lit") then return tip(player,"Фонарь освещает твой сад.") end
    if player:GetAttribute("Companion") ~= "Moth" then return tip(player,"Позови лунную моль из альбома.") end
    player:SetAttribute("Lit",true)
    tip(player,"Моль зажгла твой первый садовый фонарь!")
end)

local helm
helm = prompt(giant.Helm,"Мохоспин","К Лунной роще",function()
    if sailing then return end
    sailing = true
    giant:SetAttribute("Dock", "Sailing")
    helm.Enabled = false
    local origin = giant:GetPivot()
    local deck = giant.Meadow
    local riders = {}
    for _, player in Players:GetPlayers() do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and not root.Anchored then
            local pos = deck.CFrame:PointToObjectSpace(root.Position)
            if math.abs(pos.X) <= 17 and math.abs(pos.Z) <= 14 and pos.Y >= 0 and pos.Y < 20 then
                riders[root] = origin:ToObjectSpace(root.CFrame)
                root.Anchored = true
            end
        end
    end
    local target = homePivot + Vector3.new(atDusk and 0 or 100,0,0)
    local elapsed = 0
    while elapsed < 5 do
        elapsed += RunService.Heartbeat:Wait()
        local t = math.min(elapsed/5,1)
        local frame = origin:Lerp(target,t*t*(3-2*t))
        giant:PivotTo(frame)
        for root, offset in riders do
            if root.Parent then root.CFrame = frame * offset end
        end
    end
    for root in riders do if root.Parent then root.Anchored = false end end
    atDusk = not atDusk
    giant:SetAttribute("Dock", atDusk and "Dusk" or "Grove")
    helm.ActionText = atDusk and "К Солнечной роще" or "К Лунной роще"
    sailing = false
    helm.Enabled = true
end)

-- A shore-side call bell prevents riders left ashore from becoming stranded.
for _, island in {workspace.Grove,workspace.Dusk} do
    local bell = Instance.new("Part")
    bell.Name = "CallBell"
    bell.Anchored = true
    bell.Size = Vector3.new(2,3,2)
    bell.Color = Color3.fromRGB(237,185,101)
    bell.Position = island.Bank.Position + Vector3.new(5,6,-1+17)
    bell.Parent = island
    prompt(bell,"Дом на спине","Вернуться домой",function(player)
        if sailing then return tip(player,"Мохоспин в пути. Дождись прибытия.") end
        player.Character:PivotTo(giant.HomeSpawn.CFrame + Vector3.new(0,4,0))
    end)
end
