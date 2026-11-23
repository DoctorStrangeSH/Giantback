--!strict
-- Giantback companion art resolver.
-- Only Studio-approved MeshPart templates may replace playable blockouts.
-- No mutation, cloning, publishing, or destructive actions occur here.
local CompanionTemplateResolver = {}

local importedCompanionNames = {Fox = "FoxCompanion", Moth = "MothCompanion"}

local function usablePart(model, name)
    local part = model:FindFirstChild(name)
    return part ~= nil and part:IsA("MeshPart")
end

function CompanionTemplateResolver.resolve(storage, id)
    local fallback = storage:FindFirstChild(id)
    local importedName = importedCompanionNames[id]
    if not importedName then return fallback end

    local library = storage:FindFirstChild("AssetLibrary")
    local modelFolder = library and library:FindFirstChild("Models")
    local companions = modelFolder and modelFolder:FindFirstChild("Companions")
    local imported = companions and companions:FindFirstChild(importedName)
    if not imported or not imported:IsA("Model") then return fallback end

    if imported:GetAttribute("GiantbackImportStatus") ~= "Approved" then return fallback end
    if imported:GetAttribute("GiantbackRuntimeReady") ~= true then return fallback end
    if imported:GetAttribute("GiantbackProceduralAnimationCompatible") ~= true then return fallback end
    if imported:GetAttribute("GiantbackAssetKey") ~= (id == "Fox" and "fox_companion" or "moth_companion") then
        return fallback
    end

    -- The current CFrame animator accesses only direct model children.
    if not usablePart(imported, "Body") then return fallback end
    local movingPartName = id == "Fox" and "Tail" or "Wing"
    if not usablePart(imported, movingPartName) then return fallback end

    return imported
end

return CompanionTemplateResolver
