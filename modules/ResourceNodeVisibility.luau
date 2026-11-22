-- Giantback resource-node client visibility and cooldown scheduler.
-- Each client gets an independent controller. Server resource ownership and
-- cooldown authority remain unchanged; this module changes visuals only.
local ResourceNodeVisibility = {}

local function applyResourceNodeVisibility(model, visible)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = visible and 0 or 1
        elseif descendant:IsA("ProximityPrompt") then
            descendant.Enabled = visible
        end
    end
end

function ResourceNodeVisibility.new(findResourceNode, restoreResourceGrowth)
    assert(type(findResourceNode) == "function", "findResourceNode callback required")
    assert(type(restoreResourceGrowth) == "function", "restoreResourceGrowth callback required")

    local resourceNodeHidden = {}
    local resourceVisibilityGeneration = {}

    local function setResourceNodeVisible(nodeId, visible)
        resourceNodeHidden[nodeId] = not visible
        local model = findResourceNode(nodeId)
        if not model then return false end
        if visible then
            restoreResourceGrowth(model)
        end
        applyResourceNodeVisibility(model, visible)
        return true
    end

    local function hideResourceNodeWhenReady(nodeId, generation, attempts)
        if generation ~= resourceVisibilityGeneration[nodeId] then return end
        if setResourceNodeVisible(nodeId, false) then return end
        if attempts < 40 then
            task.delay(0.25, function()
                hideResourceNodeWhenReady(nodeId, generation, attempts + 1)
            end)
        end
    end

    local function applyResourceNodeState(nodeId, readyAt, unique)
        if type(nodeId) ~= "string" then return end
        local generation = (resourceVisibilityGeneration[nodeId] or 0) + 1
        resourceVisibilityGeneration[nodeId] = generation

        if unique then
            hideResourceNodeWhenReady(nodeId, generation, 0)
            return
        end

        local remaining = (tonumber(readyAt) or 0) - os.time()
        if remaining <= 0 then
            setResourceNodeVisible(nodeId, true)
            return
        end

        hideResourceNodeWhenReady(nodeId, generation, 0)
        task.delay(remaining, function()
            if resourceVisibilityGeneration[nodeId] == generation then
                setResourceNodeVisible(nodeId, true)
            end
        end)
    end

    local controller = {}
    function controller.apply(nodeId, readyAt, unique)
        applyResourceNodeState(nodeId, readyAt, unique)
    end

    function controller.onDescendantAdded(descendant)
        if not descendant:IsA("Model") then return end
        local nodeId = descendant:GetAttribute("ResourceNodeId")
        if nodeId and resourceNodeHidden[nodeId] then
            applyResourceNodeVisibility(descendant, false)
        end
    end

    return controller
end

return ResourceNodeVisibility
