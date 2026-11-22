-- Giantback / read-only Roblox Studio companion import diagnostics.
-- Select one or more imported FoxCompanion/MothCompanion Models and run in Command Bar.
-- This script NEVER moves, destroys, renames or approves anything.
local Selection = game:GetService("Selection")

local expected = {
    FoxCompanion = {key = "fox_companion", movers = {"Tail"}, details = {"Body", "Muzzle", "Tail"}},
    MothCompanion = {key = "moth_companion", movers = {"Wing"}, details = {"Body", "Wing"}},
}
local results = {}

local function examine(model)
    local problems, notices = {}, {}
    local def = expected[model.Name]
    if not def then
        table.insert(problems, "Unknown companion name; expected FoxCompanion or MothCompanion")
        return false, problems, notices
    end

    if model:GetAttribute("GiantbackAssetKey") ~= def.key then
        table.insert(problems, "GiantbackAssetKey does not match " .. def.key)
    end

    local body = model:FindFirstChild("Body")
    if not body or not body:IsA("MeshPart") then
        table.insert(problems, "Body must be a direct MeshPart child (procedural animation uses model:FindFirstChild)")
    end

    local meshCount, jointCount, anchoredCount, collidableCount, missingMeshIds = 0, 0, 0, 0, 0
    local names = {}
    for _, desc in model:GetDescendants() do
        if desc:IsA("BasePart") then
            names[desc.Name] = (names[desc.Name] or 0) + 1
            if desc:IsA("MeshPart") then
                meshCount += 1
                if desc.MeshId == "" then missingMeshIds += 1 end
            else
                table.insert(notices, "Non-MeshPart geometry: " .. desc.Name)
            end
            if desc.Anchored then anchoredCount += 1 end
            if desc.CanCollide then collidableCount += 1 end
        elseif desc:IsA("JointInstance") or desc:IsA("WeldConstraint")
            or desc:IsA("Bone") or desc:IsA("SkinnedMeshPart") then
            -- Part-CFrame animator cannot safely drive rigidly linked or skinned assemblies.
            jointCount += 1
        end
    end
    if meshCount < 2 then table.insert(problems, "Need at least two MeshParts for separate body and animated details") end
    if missingMeshIds > 0 then table.insert(problems, tostring(missingMeshIds) .. " MeshParts have no MeshId") end
    if jointCount > 0 then
        table.insert(problems, tostring(jointCount) .. " joints/bones/skin components detected; this animator moves parts directly")
    end
    if collidableCount > 0 then
        table.insert(problems, tostring(collidableCount) .. " collidable pieces; follower must not interfere with player movement")
    end
    if anchoredCount > 0 then
        table.insert(notices, tostring(anchoredCount) .. " anchored pieces; verify Studio motion and CFrame-driven animation")
    end
    for _, partName in def.details do
        if not names[partName] then
            table.insert(problems, "Missing expected MeshPart role: " .. partName)
        end
    end
    local minSize, maxSize = model:GetExtentsSize().Magnitude, model:GetExtentsSize().Magnitude
    if minSize < 0.2 or maxSize > 50 then
        table.insert(problems, ("Unusual model size: %.2f studs (review scale and import units)"):format(maxSize))
    end
    if model:GetAttribute("GiantbackImportStatus") ~= "Approved" then
        table.insert(notices, "Model not Approved; current game will retain blockout fallback")
    end
    if model:GetAttribute("GiantbackRuntimeReady") ~= true then
        table.insert(notices, "GiantbackRuntimeReady is not true")
    end
    if model:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true then
        table.insert(notices, "GiantbackProceduralAnimationCompatible is not true")
    end
    return #problems == 0, problems, notices
end

local selected = Selection:Get()
assert(#selected > 0, "[Giantback] Select imported companion Model(s) in Explorer.")
for _, model in selected do
    if not model:IsA("Model") then
        warn("[Giantback] Skipping non-Model selection: " .. model:GetFullName())
        continue
    end
    local ok, problems, notices = examine(model)
    results[model.Name] = ok
    print(("[Giantback] %s — %s"):format(model:GetFullName(), ok and "STRUCTURAL PASS" or "STRUCTURAL FAIL"))
    for _, issue in problems do warn("  FAIL: " .. issue) end
    for _, note in notices do print("  NOTE: " .. note) end
    print("  This is a read-only structural check; appearance, orientation, pivots, animation and mobile performance still need Studio playtest.")
end
print("[Giantback] Diagnostics complete. No assets or approval flags were changed.")
