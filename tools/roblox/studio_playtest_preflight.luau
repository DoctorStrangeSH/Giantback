-- Giantback Roblox Studio playtest preflight / read-only.
-- Paste into Studio Command Bar. Use Edit mode for structure, then Play/Test Server
-- for runtime checks. Does not publish, change attributes, spawn objects or delete data.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local failures, warnings, passes, pending = {}, {}, {}, {}
local function record(ok, label, reason)
    if ok then
        table.insert(passes, label)
        print("[Giantback Studio] PASS " .. label)
    else
        local detail = label .. ": " .. reason
        table.insert(failures, detail)
        warn("[Giantback Studio] FAIL " .. detail)
    end
end
local function note(label, reason)
    table.insert(warnings, label .. ": " .. reason)
    warn("[Giantback Studio] REVIEW " .. label .. ": " .. reason)
end
local function later(label, reason)
    table.insert(pending, label .. ": " .. reason)
    print("[Giantback Studio] PENDING " .. label .. ": " .. reason)
end
local function child(parent, name, className)
    local item = parent and parent:FindFirstChild(name)
    if not item then return nil end
    if className and not item:IsA(className) then return nil end
    return item
end
local function scriptEnabled(parent, name, className)
    local item = child(parent, name, className)
    return item ~= nil and item.Enabled
end

local isRunning = RunService:IsRunning()
print("[Giantback Studio] " .. (isRunning and "PLAY MODE" or "EDIT MODE") .. " preflight begins (read-only)")

local world = child(ServerScriptService, "World", "Script")
local worldVisuals = child(ServerScriptService, "WorldVisuals", "Script")
local combat = child(ServerScriptService, "Combat", "Script")
record(scriptEnabled(ServerScriptService, "World", "Script"), "World server script", "Missing or disabled ServerScriptService.World")
record(scriptEnabled(ServerScriptService, "WorldVisuals", "Script"), "WorldVisuals server script", "Missing or disabled ServerScriptService.WorldVisuals")
record(scriptEnabled(ServerScriptService, "Combat", "Script"), "Combat server script", "Missing or disabled ServerScriptService.Combat")

local starterScripts = child(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts")
for _, name in {"Album", "GiantbackHUD", "CombatControls"} do
    record(scriptEnabled(starterScripts, name, "LocalScript"), "StarterPlayerScripts." .. name,
        "Missing or disabled client LocalScript")
end

local expectedModules = {
    "CompanionTemplateResolver", "ResourceNodeVisibility", "HarvestMotion",
    "HarvestFeedback", "CompanionAnimation", "CompanionActivity",
    "CompanionFollow", "CompanionInteractions", "CompanionSleepVisuals",
    "MothStardust", "CompanionAppearance",
}
for _, name in expectedModules do
    record(child(ReplicatedStorage, name, "ModuleScript") ~= nil,
        "ReplicatedStorage." .. name, "ModuleScript absent in generated place")
end

-- AlbumAction is created by World.server.luau at runtime, not written by build.py.
if isRunning then
    record(child(ReplicatedStorage, "AlbumAction", "RemoteEvent") ~= nil,
        "AlbumAction runtime remote", "World server has not created AlbumAction yet")
else
    later("AlbumAction runtime remote", "Created by World script after Play begins")
end
record(child(ReplicatedStorage, "Fox", "Model") ~= nil,
    "Fox fallback", "Working Fox model template missing")
record(child(ReplicatedStorage, "Moth", "Model") ~= nil,
    "Moth fallback", "Working Moth model template missing")
local template = child(ServerStorage, "HomeIslandTemplate", "Model")
record(template ~= nil, "HomeIslandTemplate", "Personal-island template absent")
record(child(template, "HomeSpawn", "SpawnLocation") ~= nil,
    "HomeSpawn template", "Start spawn missing inside island template")

local grove = child(workspace, "Grove", "Model")
local dusk = child(workspace, "Dusk", "Model")
record(grove ~= nil, "Grove world", "Missing shared forest world")
record(dusk ~= nil, "Dusk world", "Missing lunar-biome world")
record(child(grove, "PublicSpawn", "SpawnLocation") ~= nil,
    "Grove public spawn", "Missing or incorrectly imported spawn")
record(child(workspace, "BridgeToGrove", "Model") ~= nil,
    "Grove bridge", "BridgeToGrove world Model missing")
record(child(workspace, "BridgeToDusk", "Model") ~= nil,
    "Dusk bridge", "BridgeToDusk world Model missing")

-- Studio-imported meshes are optional and must never be auto-approved by this checker.
local library = child(ReplicatedStorage, "AssetLibrary", "Folder")
local models = child(library, "Models", "Folder")
local companions = child(models, "Companions", "Folder")
for _, name in {"FoxCompanion", "MothCompanion"} do
    local imported = child(companions, name, "Model")
    if imported then
        if imported:GetAttribute("GiantbackImportStatus") == "Approved"
            and imported:GetAttribute("GiantbackRuntimeReady") == true
            and imported:GetAttribute("GiantbackProceduralAnimationCompatible") == true then
            note(name .. " imported template",
                "Approved flags present; still verify actual animations, pivots, collision and mesh permissions in Play")
        else
            later(name .. " imported template", "Not approved; fallback is intentional")
        end
    else
        later(name .. " imported template", "No imported MeshPart staged; default fallback remains")
    end
end

if isRunning then
    local active = Players:GetPlayers()
    if #active == 0 then
        later("Live player checks",
            "No Player is visible in this Command Bar context. Run in Play Server context with test clients")
    else
        local islands = child(workspace, "PlayerIslands", "Folder")
        record(islands ~= nil, "PlayerIslands runtime folder", "World server did not create folder")
        local distinct = {}
        for _, player in active do
            local islandName = "HomeIsland_" .. tostring(player.UserId)
            local home = child(islands, islandName, "Model")
            record(home ~= nil, "Personal island for " .. tostring(player.UserId),
                "Missing " .. islandName .. "; verify World startup and Output errors")
            if home then
                record(child(home, "HomeSpawn", "SpawnLocation") ~= nil,
                    "Personal HomeSpawn " .. tostring(player.UserId), "SpawnLocation missing")
                if distinct[home] then
                    note("Island isolation", "Two players resolved to the same island instance")
                end
                distinct[home] = true
            end
            if player:GetAttribute("Ready") == true then
                record(true, "Ready flag " .. tostring(player.UserId), "")
            else
                later("Ready flag " .. tostring(player.UserId),
                    "Still loading, failed to initialize or DataStore API unavailable in Studio")
            end
        end
        if #active < 2 then
            later("Multiplayer isolation", "Run Test > Server & Clients with at least two test players")
        else
            record(#active >= 2, "Two-player smoke-test context", "At least two players required")
        end
    end
else
    later("Runtime spawning / save / equipment / rewards",
        "Edit mode cannot prove these systems; run Play and review Output")
end

if world and worldVisuals and combat then
    note("Real gameplay acceptance", "This check cannot verify bridge repair, save/load, combat, petting or mobile controls")
end

print(("[Giantback Studio] SUMMARY: %d PASS, %d FAIL, %d REVIEW, %d PENDING. No changes made."):format(
    #passes, #failures, #warnings, #pending
))
if #failures > 0 then
    warn("[Giantback Studio] Preflight has failures. Fix them before treating this build as playable.")
else
    print("[Giantback Studio] Structural checks passed. Runtime and manual acceptance may still be pending.")
end
