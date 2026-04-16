DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local DEFAULT_LOOT_RADIUS = 10

local function clampRadius(value)
    local number = math.floor(tonumber(value) or DEFAULT_LOOT_RADIUS)
    if number < 2 then
        return 2
    end
    if number > 25 then
        return 25
    end
    return number
end

local function normalizeStringArray(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local normalized = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            result[#result + 1] = normalized
        end
    end
    table.sort(result)
    return result
end

function Internal.GetCompanionData(worker)
    if type(worker) ~= "table" then
        return nil
    end

    worker.companion = type(worker.companion) == "table" and worker.companion or {}
    return worker.companion
end

function Internal.GetCompanionUUID(worker)
    local companionData = Internal.GetCompanionData(worker)
    local uuid = companionData and tostring(companionData.uuid or "") or ""
    return uuid ~= "" and uuid or nil
end

function Internal.GetCommandVersion(companionData)
    return math.max(0, math.floor(tonumber(companionData and companionData.commandVersion) or 0))
end

function Internal.NormalizeCompanionLootConfig(config)
    local source = type(config) == "table" and config or {}
    local profileID = tostring(source.profileID or source.selectedProfileID or source.presetID or "")
    if profileID == "" then
        profileID = nil
    end

    local includeWorldContainers = source.includeWorldContainers ~= false
    local includeLooseWorldItems = source.includeLooseWorldItems ~= nil
        and source.includeLooseWorldItems ~= false
        or (source.includeLooseWorldItems == nil and includeWorldContainers)
    local includeGroundContainers = source.includeGroundContainers ~= nil
        and source.includeGroundContainers ~= false
        or (source.includeGroundContainers == nil and includeWorldContainers)
    local includeFurnitureContainers = source.includeFurnitureContainers ~= nil
        and source.includeFurnitureContainers ~= false
        or (source.includeFurnitureContainers == nil and includeWorldContainers)

    return {
        radius = clampRadius(source.radius),
        includeWorldContainers = includeWorldContainers,
        includeLooseWorldItems = includeLooseWorldItems,
        includeGroundContainers = includeGroundContainers,
        includeFurnitureContainers = includeFurnitureContainers,
        includeCorpseContainers = source.includeCorpseContainers ~= false,
        includeVehicleContainers = source.includeVehicleContainers ~= false,
        profileID = profileID,
        rawTags = normalizeStringArray(source.rawTags or source.tags or {})
    }
end

function Internal.CloneCompanionLootConfig(config)
    local normalized = Internal.NormalizeCompanionLootConfig(config)
    return {
        radius = normalized.radius,
        includeWorldContainers = normalized.includeWorldContainers,
        includeLooseWorldItems = normalized.includeLooseWorldItems,
        includeGroundContainers = normalized.includeGroundContainers,
        includeFurnitureContainers = normalized.includeFurnitureContainers,
        includeCorpseContainers = normalized.includeCorpseContainers,
        includeVehicleContainers = normalized.includeVehicleContainers,
        profileID = normalized.profileID,
        rawTags = normalizeStringArray(normalized.rawTags)
    }
end

function Internal.GetCompanionLootConfig(worker)
    local companionData = Internal.GetCompanionData(worker)
    companionData.lootConfig = Internal.NormalizeCompanionLootConfig(companionData and companionData.lootConfig)
    return companionData.lootConfig
end
