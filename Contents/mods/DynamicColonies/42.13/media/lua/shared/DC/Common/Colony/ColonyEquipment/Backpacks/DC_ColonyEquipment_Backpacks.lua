DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

local function getScriptManagerInstance()
    if getScriptManager then
        return getScriptManager()
    end

    if ScriptManager and ScriptManager.instance then
        return ScriptManager.instance
    end

    return nil
end

local function getScriptItem(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local manager = getScriptManagerInstance()
    return manager and manager.getItem and manager:getItem(fullType) or nil
end

local function trim(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function normalizeEquippedSlot(value)
    local text = trim(value):lower()
    if text == "" then
        return nil
    end
    return text
end

local function collectEquippedSlots(scriptItem)
    local slots = {}
    if not scriptItem then
        return slots
    end

    local function appendRaw(raw)
        local text = trim(raw)
        if text == "" then
            return
        end

        text = text:gsub(";", ",")
        for token in string.gmatch(text, "([^,]+)") do
            local normalized = normalizeEquippedSlot(token)
            if normalized then
                slots[#slots + 1] = normalized
            end
        end
    end

    if scriptItem.getCanBeEquipped then
        appendRaw(scriptItem:getCanBeEquipped())
    end
    if scriptItem.getBodyLocation then
        appendRaw(scriptItem:getBodyLocation())
    end

    return slots
end

local function hasWearableBackpackSignals(fullType, scriptItem)
    local tags = Config.FindItemTags and Config.FindItemTags(fullType) or {}
    if Config.HasMatchingTag and (
        Config.HasMatchingTag(tags, "Container.Wearable")
        or Config.HasMatchingTag(tags, "Container.Bag")
        or Config.HasMatchingTag(tags, "Container.Bag.Backpack")
        or Config.HasMatchingTag(tags, "Container.Bag.Duffel")
        or Config.HasMatchingTag(tags, "Container.Bag.Satchel")
    ) then
        return true
    end

    local slots = collectEquippedSlots(scriptItem)
    for _, slot in ipairs(slots) do
        if slot ~= "primary" and slot ~= "secondary" and slot ~= "twohands" and slot ~= "none" then
            return true
        end
    end

    return false
end

local function iterateJavaLikeCollection(collection, visitor)
    if not collection or not visitor then
        return false
    end

    if collection.size and collection.get then
        local size = tonumber(collection:size()) or 0
        for index = 0, size - 1 do
            if visitor(collection:get(index)) == false then
                return true
            end
        end
        return true
    end

    if collection.values then
        return iterateJavaLikeCollection(collection:values(), visitor)
    end

    if type(collection) == "table" then
        for _, value in pairs(collection) do
            if visitor(value) == false then
                return true
            end
        end
        return true
    end

    return false
end

function Config.GetBackpackItemProfile(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local containerProfile = Config.GetCarryContainerProfile and Config.GetCarryContainerProfile(fullType) or nil
    if not containerProfile then
        return nil
    end

    local scriptItem = getScriptItem(fullType)
    if not hasWearableBackpackSignals(fullType, scriptItem) then
        return nil
    end

    return {
        labourTags = { "Colony.Carry.Backpack" },
        capabilities = { "Colony.Carry.Backpack" },
        isBackpack = true,
        capacity = tonumber(containerProfile.capacity) or 0,
        weightReduction = tonumber(containerProfile.weightReduction) or 0,
    }
end

function Config.GetKnownBackpackFullTypes()
    local cache = Config.__backpackProfileCache or {}
    if cache.knownFullTypes then
        return cache.knownFullTypes
    end

    local known = {}
    local seen = {}

    local function append(fullType)
        local key = tostring(fullType or "")
        if key == "" or seen[key] then
            return
        end
        if Config.GetBackpackItemProfile and Config.GetBackpackItemProfile(key) then
            seen[key] = true
            known[#known + 1] = key
        end
    end

    local manager = getScriptManagerInstance()
    if manager then
        local iterated = iterateJavaLikeCollection(manager.getAllItems and manager:getAllItems() or nil, function(scriptItem)
            local fullType = scriptItem and scriptItem.getFullName and scriptItem:getFullName() or nil
            if not fullType or fullType == "" then
                local module = scriptItem and scriptItem.getModule and scriptItem:getModule() or nil
                local moduleName = module and module.getName and module:getName() or nil
                local itemName = scriptItem and scriptItem.getName and scriptItem:getName() or nil
                if moduleName and itemName then
                    fullType = tostring(moduleName) .. "." .. tostring(itemName)
                end
            end
            append(fullType)
            return true
        end)
        if not iterated then
            iterateJavaLikeCollection(manager.getItems and manager:getItems() or nil, function(scriptItem)
                local fullType = scriptItem and scriptItem.getFullName and scriptItem:getFullName() or nil
                if not fullType or fullType == "" then
                    local module = scriptItem and scriptItem.getModule and scriptItem:getModule() or nil
                    local moduleName = module and module.getName and module:getName() or nil
                    local itemName = scriptItem and scriptItem.getName and scriptItem:getName() or nil
                    if moduleName and itemName then
                        fullType = tostring(moduleName) .. "." .. tostring(itemName)
                    end
                end
                append(fullType)
                return true
            end)
        end
    end

    cache.knownFullTypes = known
    Config.__backpackProfileCache = cache
    return known
end

function Config.GetWorkerBackpackCarryProfile(worker)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    local containers = {}

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local usable = not registryInternal or not registryInternal.IsEquipmentEntryUsable or registryInternal.IsEquipmentEntryUsable(entry)
        local profile = usable and Config.GetBackpackItemProfile and Config.GetBackpackItemProfile(entry and entry.fullType or nil) or nil
        if profile then
            local container = Config.GetCarryContainerProfile and Config.GetCarryContainerProfile(entry.fullType) or nil
            if container then
                containers[#containers + 1] = container
            end
        end
    end

    if Config.BuildCarryProfile then
        return Config.BuildCarryProfile(worker, containers)
    end

    return nil
end

Config.__backpackProfileCache = nil
if Config.__equipmentRequirementCache then
    Config.__equipmentRequirementCache.definitionByKey = {}
    Config.__equipmentRequirementCache.definitionsByJob = {}
    Config.__equipmentRequirementCache.autoEquipByJob = {}
    Config.__equipmentRequirementCache.matchesByJobAndType = {}
    Config.__equipmentRequirementCache.knownEquipmentFullTypes = nil
end

return Config
