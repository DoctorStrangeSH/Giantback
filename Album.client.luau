local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local event = Storage:WaitForChild("AlbumAction")
local gui = Instance.new("ScreenGui")
gui.Name = "GiantbackJournal"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local function card(kind, parent, text, pos, size)
    local c = Instance.new(kind)
    c.Position, c.Size = pos, size
    c.Text = text
    c.Font = Enum.Font.GothamMedium
    c.TextSize = 15
    c.TextWrapped = true
    c.TextColor3 = Color3.fromRGB(255,243,210)
    c.BackgroundColor3 = Color3.fromRGB(37,66,60)
    c.BackgroundTransparency = 0.08
    c.BorderSizePixel = 0
    Instance.new("UICorner",c).CornerRadius = UDim.new(0,10)
    c.Parent = parent
    return c
end
local status = card("TextLabel",gui,"",UDim2.fromOffset(10,8),UDim2.new(1,-115,0,56))
local limit = Instance.new("UISizeConstraint",status)
limit.MaxSize = Vector2.new(500,56)
local toggle = card("TextButton",gui,"Альбом",UDim2.new(1,-95,0,8),UDim2.fromOffset(85,48))
local panel = Instance.new("Frame")
panel.Position = UDim2.new(1,-242,0,69)
panel.Size = UDim2.fromOffset(232,132)
panel.BackgroundTransparency = 1
panel.Visible = false
panel.Parent = gui
toggle.Activated:Connect(function() panel.Visible = not panel.Visible end)
local rows = {}
local names = {Fox="Лисёнок-корешок",Moth="Лунная моль"}
for i,id in {"Fox","Moth"} do
    rows[id] = card("TextButton",panel,"",UDim2.fromOffset(0,(i-1)*60),UDim2.fromOffset(232,56))
    rows[id].Activated:Connect(function()
        if player:GetAttribute(id) then event:FireServer(id) end
    end)
end
local route = {
    {flag="Fox", area="Grove", part="Nest", label="Лисёнок", hint="Подружись с лисёнком у гнезда в Солнечной роще."},
    {flag="Seed", area="Grove", part="Trail", label="Следы на тропе", hint="Позови лисёнка и попроси его обыскать тропу."},
    {flag="Moth", area="Dusk", part="Nest", label="Лунная моль", hint="Подружись с молью у гнезда в Лунной роще."},
    {flag="Flower", area="Mossback", part="Planter", label="Клумба", hint="Позови моль к клумбе возле дома."},
    {flag="Timber", area="Grove", part="Driftwood", label="Коряга", hint="Возьми лисёнка к коряге за ветвями для фонаря."},
    {flag="Lantern", area="Mossback", part="LanternBase", label="Площадка", hint="Собери фонарь из ветвей рядом со штурвалом."},
    {flag="Lit", area="Mossback", part="LanternBase", label="Садовый фонарь", hint="Позови моль и зажги садовый фонарь."},
}
local marker = Instance.new("BillboardGui")
marker.Size = UDim2.fromOffset(140, 26)
marker.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
marker.AlwaysOnTop = true
marker.Enabled = false
marker.Parent = gui
local caption = card("TextLabel", marker, "", UDim2.fromScale(0,0), UDim2.fromScale(1,1))

local function goal()
    local giant = workspace:FindFirstChild("Mossback")
    if not giant or not player:GetAttribute("Ready") then return "Открываем альбом…" end
    local dock = giant:GetAttribute("Dock")
    if dock == "Sailing" then return "Мохоспин в пути. Скоро причалим!" end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for _, step in route do
        if player:GetAttribute(step.flag) then continue end
        for _, shore in {"Grove", "Dusk"} do
            local island = workspace:FindFirstChild(shore)
            local bank = island and island:FindFirstChild("Bank")
            if root and bank and shore ~= dock and step.area ~= shore then
                local pos = bank.CFrame:PointToObjectSpace(root.Position)
                if math.abs(pos.X) <= bank.Size.X/2 and math.abs(pos.Z) <= bank.Size.Z/2 then
                    return "Позвони в береговой колокольчик, чтобы вернуться домой.", island:FindFirstChild("CallBell"), "Колокольчик"
                end
            end
        end
        local area = workspace:FindFirstChild(step.area)
        local onTargetShore = false
        local bank = area and area:FindFirstChild("Bank")
        if root and bank then
            local pos = bank.CFrame:PointToObjectSpace(root.Position)
            onTargetShore = math.abs(pos.X) <= bank.Size.X/2 and math.abs(pos.Z) <= bank.Size.Z/2
        end
        if step.area ~= "Mossback" and step.area ~= dock and not onTargetShore then
            local destination = step.area == "Grove" and "Солнечной роще" or "Лунной роще"
            return "У штурвала задай курс к " .. destination .. ".", giant:FindFirstChild("Helm"), "Штурвал"
        end
        return step.hint, area and area:FindFirstChild(step.part), step.label
    end
    return "Садовый фонарь горит • Коллекция 2/2"
end
local lastTip = 0
local function refresh()
    for id,row in rows do
        local owned = player:GetAttribute(id)
        local equipped = player:GetAttribute("Companion") == id
        row.Text = names[id] .. "\n" .. (equipped and "✓ Рядом" or owned and "Позвать" or "Ещё не найден")
    end
end
local function updateRoute()
    local hint, target, label = goal()
    marker.Adornee = target
    marker.Enabled = target ~= nil
    caption.Text = label or ""
    if os.clock() >= lastTip then
        status.Text = (player:GetAttribute("OfflineAlbum") and "Без сохранения • " or "") .. hint
    end
end
event.OnClientEvent:Connect(function(message)
    lastTip = os.clock()+3.5
    status.Text = message
    task.delay(3.6,updateRoute)
end)
player.AttributeChanged:Connect(refresh)
refresh()
task.spawn(function()
    while gui.Parent do
        updateRoute()
        task.wait(0.3)
    end
end)

local models = {}
local function follow(dt)
    for _, owner in Players:GetPlayers() do
        local root = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
        local id = owner:GetAttribute("Companion")
        local model = models[owner]
        if model and (model.Name ~= id or not root) then
            model:Destroy()
            models[owner] = nil
            model = nil
        end
        if root and names[id] then
            local bob = math.sin(workspace:GetServerTimeNow()*3)*.22
            local target = root.CFrame * CFrame.new(2.8,(id=="Fox" and -1.6 or 1)+bob,2)
            if not model then
                model = Storage[id]:Clone()
                model:PivotTo(target)
                model.Parent = workspace
                models[owner] = model
            else
                model:PivotTo(model:GetPivot():Lerp(target,1-math.exp(-10*dt)))
            end
        end
    end
end
Players.PlayerRemoving:Connect(function(owner)
    if models[owner] then models[owner]:Destroy() models[owner] = nil end
end)
RunService.RenderStepped:Connect(follow)

local planter = workspace:WaitForChild("Mossback"):WaitForChild("Planter")
local flower
local function bloom()
    if flower or not player:GetAttribute("Flower") then return end
    flower = Instance.new("Model")
    flower.Name = "Moonflower"
    for i=0,6 do
        local petal = Instance.new("Part")
        petal.Anchored,petal.CanCollide = true,false
        petal.Shape = Enum.PartType.Ball
        petal.Size = i==0 and Vector3.new(1.1,1.1,1.1) or Vector3.new(1.45,.65,1.45)
        local angle = i*math.pi/3
        petal.Position = i==0 and Vector3.new(0,.35,0) or Vector3.new(math.cos(angle),0,math.sin(angle))
        petal.Color = i==0 and Color3.fromRGB(255,202,115) or Color3.fromRGB(216,173,246)
        petal.Material = Enum.Material.Neon
        petal.Parent = flower
    end
    flower.Parent = workspace
    local function placeFlower() flower:PivotTo(planter.CFrame * CFrame.new(0,1,0)) end
    placeFlower()
    planter:GetPropertyChangedSignal("CFrame"):Connect(placeFlower)
end
player:GetAttributeChangedSignal("Flower"):Connect(bloom)
bloom()

local base = workspace.Mossback:WaitForChild("LanternBase")
local lantern
local lamp
local light
local function updateLantern()
    if not player:GetAttribute("Lantern") then return end
    if not lantern then
        lantern = Instance.new("Model")
        lantern.Name = "GardenLantern"
        local function piece(name, height, size, color)
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.Size = size
            part.Color = color
            part.CFrame = base.CFrame * CFrame.new(0,height,0)
            part.Parent = lantern
            return part
        end
        local wood = Color3.fromRGB(129,87,62)
        local post = piece("Post",1.8,Vector3.new(.5,3,.5),wood)
        piece("Shelf",3.4,Vector3.new(1.7,.3,1.7),wood)
        lamp = piece("Glass",4.25,Vector3.new(1.3,1.45,1.3),Color3.fromRGB(242,198,127))
        piece("Cap",5.1,Vector3.new(1.85,.3,1.85),Color3.fromRGB(79,115,101))
        light = Instance.new("PointLight",lamp)
        light.Color = lamp.Color
        light.Range,light.Brightness = 16,2
        lantern.PrimaryPart = post
        lantern.Parent = workspace
        RunService.RenderStepped:Connect(function()
            local target = base.CFrame * CFrame.new(0,1.8,0)
            if post.CFrame ~= target then lantern:PivotTo(target) end
        end)
    end
    light.Enabled = player:GetAttribute("Lit") == true
    lamp.Material = light.Enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
end
player:GetAttributeChangedSignal("Lantern"):Connect(updateLantern)
player:GetAttributeChangedSignal("Lit"):Connect(updateLantern)
updateLantern()
