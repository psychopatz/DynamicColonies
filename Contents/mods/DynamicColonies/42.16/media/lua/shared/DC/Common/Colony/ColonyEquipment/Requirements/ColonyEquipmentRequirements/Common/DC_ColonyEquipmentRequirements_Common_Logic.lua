DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

-- ------------------------------------------------
-- Helpers (Internal)
-- ------------------------------------------------

Config.Common = Config.Common or {}

function Config.Common.AppendUniqueStrings(target, values)
    target = type(target) == "table" and target or {}

    local seen = {}
    for _, existing in ipairs(target) do
        local key = tostring(existing or "")
        if key ~= "" then
            seen[key] = true
        end
    end

    for _, value in ipairs(values or {}) do
        local key = tostring(value or "")
        if key ~= "" and not seen[key] then
            target[#target + 1] = key
            seen[key] = true
        end
    end

    return target
end

function Config.Common.CloneStringArray(values)
    return Config.Common.AppendUniqueStrings({}, values)
end

function Config.Common.GetWorkerSkillLevel(worker, skillID)
    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

function Config.Common.FilterDefinitionsForWorker(definitions, worker)
    if type(worker) ~= "table" then
        return definitions or {}
    end

    local filtered = {}
    for _, definition in ipairs(definitions or {}) do
        if Config.CanWorkerUseEquipmentRequirement == nil
            or Config.CanWorkerUseEquipmentRequirement(worker, definition and definition.requirementKey) then
            filtered[#filtered + 1] = definition
        end
    end
    return filtered
end

function Config.Common.GetEquipmentRequirementCache()
    local cache = Config.__equipmentRequirementCache or {}
    cache.definitionByKey = cache.definitionByKey or {}
    cache.definitionsByJob = cache.definitionsByJob or {}
    cache.autoEquipByJob = cache.autoEquipByJob or {}
    cache.matchesByJobAndType = cache.matchesByJobAndType or {}
    cache.knownEquipmentFullTypes = cache.knownEquipmentFullTypes or nil
    cache.knownTypeHandlers = cache.knownTypeHandlers or {}
    Config.__equipmentRequirementCache = cache
    return cache
end

function Config.Common.IsDefinitionRelevantToJob(definition, normalizedJobType)
    if not normalizedJobType then
        return true
    end

    if type(definition) == "table" and definition.allJobTypes == true then
        return true
    end

    local jobTypes = type(definition) == "table" and definition.jobTypes or nil
    if type(jobTypes) ~= "table" or #jobTypes <= 0 then
        return false
    end

    for _, jobType in ipairs(jobTypes) do
        if Config.NormalizeJobType(jobType) == normalizedJobType then
            return true
        end
    end

    return false
end

function Config.Common.CollectKnownEquipmentFullTypes()
    local cache = Config.Common.GetEquipmentRequirementCache()
    if cache.knownEquipmentFullTypes then
        return cache.knownEquipmentFullTypes
    end

    local fullTypes = {}

    -- Base Definitions
    for _, definition in pairs(Config.EquipmentRequirementDefinitions or {}) do
        Config.Common.AppendUniqueStrings(fullTypes, definition and definition.supportedFullTypes or nil)
        if definition and definition.iconFullType then
            Config.Common.AppendUniqueStrings(fullTypes, { definition.iconFullType })
        end
    end

    -- Registered Handlers (Decoupled Logic)
    for _, handler in ipairs(cache.knownTypeHandlers or {}) do
        local handlerTypes = handler()
        if type(handlerTypes) == "table" then
            Config.Common.AppendUniqueStrings(fullTypes, handlerTypes)
        end
    end

    -- Core / Backpacks (Generic)
    Config.Common.AppendUniqueStrings(fullTypes, Config.GetKnownBackpackFullTypes and Config.GetKnownBackpackFullTypes() or nil)

    -- Master List (Trading Integration)
    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or nil
    if masterList then
        -- This is a bit slow to scan everything, but it's done once per cache invalidation
        -- For now we just mark it as something that could be optimized
    end

    cache.knownEquipmentFullTypes = fullTypes
    return fullTypes
end

function Config.Common.RegisterEquipmentRequirementKnownTypeHandler(handler)
    local cache = Config.Common.GetEquipmentRequirementCache()
    table.insert(cache.knownTypeHandlers, handler)
    cache.knownEquipmentFullTypes = nil -- Invalidate
end

function Config.Common.DefinitionSupportsFullType(definition, fullType)
    local itemType = tostring(fullType or "")
    if itemType == "" or type(definition) ~= "table" then
        return false
    end

    for _, supportedFullType in ipairs(definition.supportedFullTypes or {}) do
        if tostring(supportedFullType or "") == itemType then
            return true
        end
    end

    for _, requirementTag in ipairs(definition.requirementTags or {}) do
        if Config.ItemMatchesEquipmentRequirement(itemType, requirementTag) then
            return true
        end
    end

    return false
end

-- ------------------------------------------------
-- Public API (Config)
-- ------------------------------------------------

function Config.ItemMatchesEquipmentRequirement(fullType, requirementKey)
    local itemType = tostring(fullType or "")
    local key = tostring(requirementKey or "")
    if itemType == "" or key == "" then
        return false
    end

    local tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(itemType))
        or (Config.FindItemTags and Config.FindItemTags(itemType))
        or {}

    for _, itemTag in ipairs(tags or {}) do
        if tostring(itemTag or "") == key then
            return true
        end
        if Config.TagMatches and Config.TagMatches(itemTag, key) then
            return true
        end
    end

    return false
end

function Config.GetEquipmentRequirementDefinition(requirementKey)
    local key = tostring(requirementKey or "")
    if key == "" then
        return nil
    end

    local cache = Config.Common.GetEquipmentRequirementCache()
    if cache.definitionByKey[key] then
        return cache.definitionByKey[key]
    end

    local source = (Config.EquipmentRequirementDefinitions and Config.EquipmentRequirementDefinitions[key]) or {}
    local definition = {
        requirementKey = key,
        label = tostring(source.label or key),
        hintText = tostring(source.hintText or source.hint or key),
        reasonText = source.reasonText,
        searchText = tostring(source.searchText or key),
        iconFullType = source.iconFullType,
        supportedFullTypes = Config.Common.CloneStringArray(source.supportedFullTypes),
        requirementTags = Config.Common.CloneStringArray(source.requirementTags),
        jobTypes = Config.Common.CloneStringArray(source.jobTypes),
        allJobTypes = source.allJobTypes == true,
        autoEquip = source.autoEquip == true,
        combatCapability = source.combatCapability and tostring(source.combatCapability) or nil,
        sortOrder = tonumber(source.sortOrder) or 1000,
    }

    Config.Common.AppendUniqueStrings(definition.requirementTags, { key })

    for _, fullType in ipairs(Config.Common.CollectKnownEquipmentFullTypes()) do
        if Config.ItemMatchesEquipmentRequirement(fullType, key) then
            Config.Common.AppendUniqueStrings(definition.supportedFullTypes, { fullType })
            if not definition.iconFullType then
                definition.iconFullType = fullType
            end
        end
    end

    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or nil
    for fullType, _ in pairs(masterList or {}) do
        for _, requirementTag in ipairs(definition.requirementTags or {}) do
            if Config.ItemMatchesEquipmentRequirement(fullType, requirementTag) then
                Config.Common.AppendUniqueStrings(definition.supportedFullTypes, { fullType })
                if not definition.iconFullType then
                    definition.iconFullType = fullType
                end
                break
            end
        end
    end

    cache.definitionByKey[key] = definition
    return definition
end

function Config.GetEquipmentRequirementDefinitions(jobType)
    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local cacheKey = normalizedJobType or "__all"
    local cache = Config.Common.GetEquipmentRequirementCache()
    if cache.definitionsByJob[cacheKey] then
        return cache.definitionsByJob[cacheKey]
    end

    local definitions = {}
    local seen = {}
    local profile = normalizedJobType and Config.GetJobProfile(normalizedJobType) or nil

    for _, requiredTag in ipairs(profile and profile.requiredToolTags or {}) do
        local key = tostring(requiredTag or "")
        if key ~= "" and not seen[key] then
            local definition = Config.GetEquipmentRequirementDefinition(key)
            if definition then
                definitions[#definitions + 1] = definition
                seen[key] = true
            end
        end
    end

    for requirementKey, rawDefinition in pairs(Config.EquipmentRequirementDefinitions or {}) do
        local key = tostring(requirementKey or "")
        if key ~= "" and not seen[key] and Config.Common.IsDefinitionRelevantToJob(rawDefinition, normalizedJobType) then
            local definition = Config.GetEquipmentRequirementDefinition(key)
            if definition then
                definitions[#definitions + 1] = definition
                seen[key] = true
            end
        end
    end

    table.sort(definitions, function(a, b)
        local orderA = tonumber(a and a.sortOrder) or 1000
        local orderB = tonumber(b and b.sortOrder) or 1000
        if orderA == orderB then
            return tostring(a and a.label or a and a.requirementKey or "")
                < tostring(b and b.label or b and b.requirementKey or "")
        end
        return orderA < orderB
    end)

    cache.definitionsByJob[cacheKey] = definitions
    return definitions
end

function Config.GetAutoEquipRequirementDefinitions(jobType)
    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local cacheKey = normalizedJobType or "__all"
    local cache = Config.Common.GetEquipmentRequirementCache()
    if cache.autoEquipByJob[cacheKey] then
        return cache.autoEquipByJob[cacheKey]
    end

    local definitions = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitions(jobType)) do
        if definition.autoEquip == true then
            definitions[#definitions + 1] = definition
        end
    end

    cache.autoEquipByJob[cacheKey] = definitions
    return definitions
end

function Config.CanWorkerUseEquipmentRequirement(worker, requirementKey)
    local definition = Config.GetEquipmentRequirementDefinition(requirementKey)
    local capability = definition and definition.combatCapability or nil
    if not capability or type(worker) ~= "table" then
        return true
    end

    if capability == "melee" then
        return Config.Common.GetWorkerSkillLevel(worker, "Melee") > 0
    end

    if capability == "shooting" then
        return Config.Common.GetWorkerSkillLevel(worker, "Shooting") > 0
    end

    return true
end

function Config.GetWorkerEquipmentRequirementDefinitions(worker)
    return Config.Common.FilterDefinitionsForWorker(Config.GetEquipmentRequirementDefinitions(worker and worker.jobType or nil), worker)
end

function Config.GetMatchingEquipmentRequirementDefinitions(fullType, jobType)
    local itemType = tostring(fullType or "")
    if itemType == "" then
        return {}
    end

    local normalizedJobType = jobType and Config.NormalizeJobType(jobType) or nil
    local cacheKey = (normalizedJobType or "__all") .. "|" .. itemType
    local cache = Config.Common.GetEquipmentRequirementCache()
    if cache.matchesByJobAndType[cacheKey] then
        return cache.matchesByJobAndType[cacheKey]
    end

    local matches = {}
    for _, definition in ipairs(Config.GetEquipmentRequirementDefinitions(normalizedJobType)) do
        if Config.Common.DefinitionSupportsFullType(definition, itemType) then
            matches[#matches + 1] = definition
        end
    end

    cache.matchesByJobAndType[cacheKey] = matches
    return matches
end

function Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker)
    return Config.Common.FilterDefinitionsForWorker(
        Config.GetMatchingEquipmentRequirementDefinitions(fullType, worker and worker.jobType or nil),
        worker
    )
end

function Config.ResolveWorkerEquipmentRequirementKey(worker, fullType, preferredRequirementKey)
    local preferredKey = tostring(preferredRequirementKey or "")
    if preferredKey ~= "" then
        local matches = Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker)
        for _, definition in ipairs(matches or {}) do
            if tostring(definition and definition.requirementKey or "") == preferredKey then
                return preferredKey
            end
        end
    end

    local matches = Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker)
    return matches[1] and tostring(matches[1].requirementKey or "") or nil
end

function Config.ItemMatchesWorkerEquipmentRequirement(fullType, requirementKey, worker)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return false
    end

    for _, definition in ipairs(Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker)) do
        if tostring(definition and definition.requirementKey or "") == targetKey then
            return true
        end
    end

    return false
end

function Config.IsRequiredEquipmentFullType(fullType, jobType)
    return #(Config.GetMatchingEquipmentRequirementDefinitions(fullType, jobType) or {}) > 0
end

function Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
    return #(Config.GetMatchingEquipmentRequirementDefinitionsForWorker(fullType, worker) or {}) > 0
end

return Config
