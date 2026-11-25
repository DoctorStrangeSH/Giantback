--!strict
-- Server-owned breeding recipes and profile normalization.
-- The module contains no DataStore or RemoteEvent access.
local CompanionBreeding = {}

CompanionBreeding.MAX_ACTIVE_EGGS = 3
CompanionBreeding.RECIPES = {
    LunarFox = {
        id = "LunarFox",
        name = "Лунолис",
        rarity = "Эпический",
        parents = {"Fox", "Moth"},
        bond = 400,
        level = 3,
        incubationSeconds = 90,
        items = {SunPetal = 10, MoonPetal = 10, MoonSeed = 2},
        traits = {"Лунное зрение", "Лесной нюх"},
    },
    PrismFox = {
        id = "PrismFox",
        name = "Призмолис",
        rarity = "Эпический",
        parents = {"Fox", "CrystalWisp"},
        bond = 400,
        level = 3,
        incubationSeconds = 120,
        items = {SunPetal = 10, CrystalShard = 10, RootvaultEssence = 1},
        traits = {"Призматический слух", "Следопыт жил"},
    },
    Starwing = {
        id = "Starwing",
        name = "Звёздокрыл",
        rarity = "Легендарный",
        parents = {"Moth", "CrystalWisp"},
        bond = 500,
        level = 4,
        incubationSeconds = 180,
        items = {MoonPetal = 12, CrystalShard = 12, StarShard = 5},
        traits = {"Звёздная пыльца", "Эхо кристалла"},
    },
}

local recipeById = {}
for id, recipe in CompanionBreeding.RECIPES do
    recipeById[id] = recipe
end

function CompanionBreeding.getRecipe(recipeId)
    if type(recipeId) ~= "string" then return nil end
    return recipeById[recipeId]
end

function CompanionBreeding.normalizeEggs(raw, now)
    local result = {}
    if type(raw) ~= "table" then return result end
    now = math.max(0, math.floor(tonumber(now) or os.time()))
    local seen = {}
    for _, egg in raw do
        if #result >= CompanionBreeding.MAX_ACTIVE_EGGS then break end
        if type(egg) == "table" and type(egg.id) == "string"
            and #egg.id >= 8 and #egg.id <= 64 and not seen[egg.id]
            and recipeById[egg.recipeId] then
            local recipe = recipeById[egg.recipeId]
            local createdAt = math.clamp(math.floor(tonumber(egg.createdAt) or now), 0, now + 60)
            local hatchAt = math.clamp(math.floor(tonumber(egg.hatchAt) or (createdAt + recipe.incubationSeconds)),
                createdAt, createdAt + recipe.incubationSeconds)
            table.insert(result, {
                id = egg.id,
                recipeId = recipe.id,
                createdAt = createdAt,
                hatchAt = hatchAt,
            })
            seen[egg.id] = true
        end
    end
    return result
end

function CompanionBreeding.normalizeDiscoveries(raw)
    local result = {}
    if type(raw) ~= "table" then return result end
    for recipeId, discovered in raw do
        if recipeById[recipeId] and discovered == true then
            result[recipeId] = true
        end
    end
    return result
end

function CompanionBreeding.getResult(egg)
    if type(egg) ~= "table" then return nil end
    local recipe = recipeById[egg.recipeId]
    if not recipe then return nil end
    return {
        id = recipe.id,
        name = recipe.name,
        rarity = recipe.rarity,
        parents = table.clone(recipe.parents),
        traits = table.clone(recipe.traits),
    }
end

return CompanionBreeding
