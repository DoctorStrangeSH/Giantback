-- Giantback Asset Pipeline 1.0
-- Roblox Studio Command Bar script. Select imported Models (not raw OBJ files).
-- Default is DRY RUN: no Instances are created or moved until APPLY = true.
-- Never replaces existing templates or gameplay rigs.
local APPLY = false

local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local definitions = {
    fox_companion = {name = "FoxCompanion", service = ReplicatedStorage, category = "Companions"},
    moth_companion = {name = "MothCompanion", service = ReplicatedStorage, category = "Companions"},
    home_cottage = {name = "HomeCottage", service = ServerStorage, category = "Buildings"},
    farm_bed = {name = "FarmBed", service = ServerStorage, category = "Buildings"},
    bridge_segment = {name = "BridgeSegment", service = ServerStorage, category = "Environment"},
    home_island = {name = "HomeIsland", service = ServerStorage, category = "Environment"},
}

local function normalizedKey(model)
    local attr = model:GetAttribute("GiantbackAssetKey")
    if typeof(attr) == "string" and definitions[attr] then
        return attr
    end
    local name = model.Name:lower():gsub("%.obj$", ""):gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    return name
end

local function findDestination(service, category)
    local library = service:FindFirstChild("AssetLibrary")
    local models = library and library:FindFirstChild("Models")
    return models and models:FindFirstChild(category)
end

local function createDestination(service, category)
    local library = service:FindFirstChild("AssetLibrary")
    if not library then
        library = Instance.new("Folder")
        library.Name = "AssetLibrary"
        library.Parent = service
    end
    local models = library:FindFirstChild("Models")
    if not models then
        models = Instance.new("Folder")
        models.Name = "Models"
        models.Parent = library
    end
    local folder = models:FindFirstChild(category)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = category
        folder.Parent = models
    end
    return folder
end

local selected = Selection:Get()
assert(#selected > 0, "[Giantback] Select the imported Model(s) in Explorer first.")
local planned, rejected, seen = {}, 0, {}
for _, item in selected do
    if not item:IsA("Model") then
        warn("[Giantback] Skipping non-Model: " .. item:GetFullName())
        rejected += 1
        continue
    end
    local key = normalizedKey(item)
    local definition = definitions[key]
    if not definition then
        warn("[Giantback] Unknown model key: " .. item.Name .. " (expected source name or GiantbackAssetKey attribute)")
        rejected += 1
        continue
    end
    if not item:FindFirstChildWhichIsA("MeshPart", true) then
        warn("[Giantback] No MeshPart in: " .. item.Name .. "; source OBJ may not have been imported")
        rejected += 1
        continue
    end
    local identity = definition.service.Name .. "/" .. definition.category .. "/" .. definition.name
    if seen[identity] then
        warn("[Giantback] Duplicate selected asset: " .. identity)
        rejected += 1
        continue
    end
    seen[identity] = true
    local dest = findDestination(definition.service, definition.category)
    if dest and dest:FindFirstChild(definition.name) and dest[definition.name] ~= item then
        warn("[Giantback] Destination already occupied; skipping: " .. identity)
        rejected += 1
        continue
    end
    table.insert(planned, {model = item, key = key, definition = definition})
    print("[Giantback] " .. (APPLY and "MOVE " or "PREVIEW ") .. item.Name .. " -> " .. definition.service.Name .. "/AssetLibrary/Models/" .. definition.category .. "/" .. definition.name)
end

if APPLY then
    for _, entry in planned do
        local definition = entry.definition
        local dest = createDestination(definition.service, definition.category)
        -- Recheck at execution time to prevent replacing a previously imported model.
        local existing = dest:FindFirstChild(definition.name)
        if existing and existing ~= entry.model then
            warn("[Giantback] Destination became occupied: " .. definition.name)
            rejected += 1
            continue
        end
        entry.model.Name = definition.name
        entry.model:SetAttribute("GiantbackAssetKey", entry.key)
        entry.model:SetAttribute("GiantbackImportStatus", "NeedsStudioReview")
        entry.model.Parent = dest
    end
end
print(string.format("[Giantback] %s: %d planned model(s), %d rejected. No gameplay model has been replaced.",
    APPLY and "Applied" or "Dry run", #planned, rejected))
