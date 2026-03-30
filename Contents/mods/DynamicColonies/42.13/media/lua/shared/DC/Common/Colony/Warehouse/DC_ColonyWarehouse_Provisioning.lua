DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse

local function takeFirstEquipmentEntry(ownerUsername, predicate)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    for index, entry in ipairs(warehouse.ledgers.equipment or {}) do
        local usable = Registry.Internal.IsEquipmentEntryUsable and Registry.Internal.IsEquipmentEntryUsable(entry) or true
        if usable and predicate(entry) then
            local removed = Registry.Internal.CopyShallow(entry)
            removed.qty = 1
            table.remove(warehouse.ledgers.equipment, index)
            Warehouse.TouchItemsVersion(ownerUsername)
            Warehouse.TouchSummaryVersion(ownerUsername)
            Warehouse.Recalculate(warehouse)
            return removed
        end
    end
    return nil
end

local function getRequirementDefinitionsForRestock(worker, includeOptional)
    local definitions = {}
    local source = nil

    if includeOptional == true and Config.GetWorkerEquipmentRequirementDefinitions then
        source = Config.GetWorkerEquipmentRequirementDefinitions(worker)
    elseif Config.GetAutoEquipRequirementDefinitions then
        source = Config.GetAutoEquipRequirementDefinitions(worker and worker.jobType)
    end

    for _, definition in ipairs(source or {}) do
        if includeOptional == true
            or definition.autoEquip == true then
            definitions[#definitions + 1] = definition
        end
    end

    return definitions
end

local function workerHasRequirement(worker, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return true
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if entry and entry.fullType and Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(entry.fullType, targetKey, worker) then
            return true
        end
    end

    return false
end

local function takeFirstEquipmentEntryForRequirement(ownerUsername, worker, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return nil
    end

    return takeFirstEquipmentEntry(ownerUsername, function(candidate)
        return candidate
            and candidate.fullType
            and Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(candidate.fullType, targetKey, worker)
    end)
end

function Warehouse.RestockWorkerEquipment(worker, options)
    if not worker then
        return 0
    end

    options = type(options) == "table" and options or {}
    local added = 0
    local includeOptional = options.includeOptional == true
    local requirementDefinitions = getRequirementDefinitionsForRestock(worker, includeOptional)

    Registry.RecalculateWorker(worker)

    for _, definition in ipairs(requirementDefinitions) do
        local requirementKey = tostring(definition and definition.requirementKey or "")
        if requirementKey ~= "" and not workerHasRequirement(worker, requirementKey) then
            if Registry.GetInventoryRemainingCapacity(worker) <= 0 then
                break
            end
            local entry = takeFirstEquipmentEntryForRequirement(worker.ownerUsername, worker, requirementKey)
            if entry then
                if Registry.AddToolEntryForRequirement and Registry.AddToolEntryForRequirement(worker, entry, requirementKey) then
                    added = added + 1
                    Registry.RecalculateWorker(worker)
                else
                    Warehouse.DepositEquipmentEntry(worker.ownerUsername, entry)
                    break
                end
            end
        end
    end

    return added
end

local function findBestProvisionIndex(warehouse, needCalories, needHydration)
    local bestIndex = nil
    local bestScore = -1

    for index, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.provisions or {}) do
        if not (Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry)) then
            local calories = math.max(0, tonumber(entry.caloriesRemaining) or 0)
            local hydration = math.max(0, tonumber(entry.hydrationRemaining) or 0)
            local score = 0

            if needCalories > 0 then
                score = score + math.min(needCalories, calories)
            end
            if needHydration > 0 then
                score = score + math.min(needHydration, hydration)
            end
            if score > bestScore then
                bestIndex = index
                bestScore = score
            end
        end
    end

    return bestIndex
end

local function recordProvisionName(sampleNames, entry, hiddenCount)
    local displayName = tostring(entry and (entry.displayName or entry.fullType) or "provisions")
    if #sampleNames < 2 then
        sampleNames[#sampleNames + 1] = displayName
        return hiddenCount
    end
    return hiddenCount + 1
end

local function restockProvisions(worker, dailyCaloriesNeed, dailyHydrationNeed)
    if not worker then
        return 0, 0, 0, {}, 0
    end

    local targetCalories = math.max(0, tonumber(dailyCaloriesNeed) or 0) * 2
    local targetHydration = math.max(0, tonumber(dailyHydrationNeed) or 0) * 2
    local totalCalories, totalHydration = Nutrition.GetTotalAvailableAmounts(worker)
    local warehouse = Warehouse.GetOwnerWarehouse(worker.ownerUsername)
    local movedCalories = 0
    local movedHydration = 0
    local movedCount = 0
    local sampleNames = {}
    local hiddenCount = 0
    local safetyCounter = 0

    while safetyCounter < 512 and (totalCalories < targetCalories or totalHydration < targetHydration) do
        if Registry.GetInventoryRemainingCapacity(worker) <= 0 then
            break
        end
        local index = findBestProvisionIndex(
            warehouse,
            math.max(0, targetCalories - totalCalories),
            math.max(0, targetHydration - totalHydration)
        )
        if not index then
            break
        end

        local entry = warehouse.ledgers.provisions[index]
        if not entry then
            break
        end

        local removed = Registry.Internal.CopyShallow(entry)
        removed.qty = 1
        entry.qty = math.max(1, math.floor(tonumber(entry.qty) or 1)) - 1
        if entry.qty <= 0 then
            table.remove(warehouse.ledgers.provisions, index)
        end

        if not Registry.AddNutritionEntry(worker, removed) then
            Warehouse.DepositProvisionEntry(worker.ownerUsername, removed)
            break
        end
        movedCalories = movedCalories + math.max(0, tonumber(removed.caloriesRemaining) or 0)
        movedHydration = movedHydration + math.max(0, tonumber(removed.hydrationRemaining) or 0)
        movedCount = movedCount + 1
        hiddenCount = recordProvisionName(sampleNames, removed, hiddenCount)
        totalCalories = totalCalories + math.max(0, tonumber(removed.caloriesRemaining) or 0)
        totalHydration = totalHydration + math.max(0, tonumber(removed.hydrationRemaining) or 0)
        safetyCounter = safetyCounter + 1
    end

    if movedCount > 0 then
        Warehouse.TouchItemsVersion(worker.ownerUsername)
        Warehouse.TouchSummaryVersion(worker.ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return movedCalories, movedHydration, movedCount, sampleNames, hiddenCount
end

function Warehouse.RestockWorker(worker, dailyCaloriesNeed, dailyHydrationNeed)
    if not worker then
        return {
            calories = 0,
            hydration = 0,
            tools = 0,
            provisionCount = 0,
            provisionSampleNames = {},
            provisionHiddenCount = 0,
        }
    end

    local calories, hydration, provisionCount, provisionSampleNames, provisionHiddenCount =
        restockProvisions(worker, dailyCaloriesNeed, dailyHydrationNeed)
    local tools = Warehouse.GetAutoEquipEnabled and Warehouse.GetAutoEquipEnabled(worker.ownerUsername)
        and Warehouse.RestockWorkerEquipment(worker, { includeOptional = true })
        or 0
    Registry.RecalculateWorker(worker)
    return {
        calories = calories,
        hydration = hydration,
        tools = tools,
        provisionCount = provisionCount,
        provisionSampleNames = provisionSampleNames,
        provisionHiddenCount = provisionHiddenCount,
    }
end

return Warehouse
