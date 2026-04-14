DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Sites = DC_Colony.Sites
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

local function buildInventoryToolEntry(invItem)
    local fullType = invItem and invItem.getFullType and invItem:getFullType() or nil
    return Registry.Internal.BuildEquipmentEntryFromInventoryItem and Registry.Internal.BuildEquipmentEntryFromInventoryItem(invItem, invItem:getDisplayName()) or {
        fullType = fullType,
        displayName = invItem and invItem.getDisplayName and invItem:getDisplayName() or fullType,
        tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType)) or Config.FindItemTags(fullType)
    }
end

local function getAmmoTypeForWeapon(fullType)
    local key = tostring(fullType or "")
    if key == "" or not getScriptManager then
        return nil
    end
    local scriptItem = getScriptManager():getItem(key)
    local ammoType = scriptItem and scriptItem.getAmmoType and scriptItem:getAmmoType() or nil
    ammoType = tostring(ammoType or "")
    return ammoType ~= "" and ammoType or nil
end

local function getWorkerRangedAmmoType(worker)
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if tostring(entry and entry.assignedRequirementKey or "") == "Colony.Combat.Ranged" then
            return getAmmoTypeForWeapon(entry.fullType)
        end
    end
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(entry and entry.fullType, "Colony.Combat.Ranged", worker) then
            return getAmmoTypeForWeapon(entry.fullType)
        end
    end
    return nil
end

local function itemMatchesWorkerRangedAmmo(worker, fullType)
    local ammoType = tostring(getWorkerRangedAmmoType(worker) or "")
    local itemType = tostring(fullType or "")
    if ammoType == "" or itemType == "" then
        return false
    end
    return itemType == ammoType or itemType == ammoType .. "Box" or itemType:gsub("Box$", "") == ammoType
end

local function canAssignRequirement(worker, fullType, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "Colony.Combat.Ammo" then
        return itemMatchesWorkerRangedAmmo(worker, fullType)
    end
    if targetKey ~= "" then
        return Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(fullType, targetKey, worker)
    end

    return Config.IsRequiredEquipmentFullTypeForWorker
        and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
        or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker and worker.jobType))
end

local function storeWorkerToolEntry(worker, toolEntry, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey ~= "" and Registry.AddToolEntryForRequirement then
        return Registry.AddToolEntryForRequirement(worker, toolEntry, targetKey)
    end

    return Registry.AddToolEntry(worker, toolEntry)
end

local function rejectItem(rejected, itemID, reason)
    rejected[#rejected + 1] = {
        itemID = itemID,
        reason = tostring(reason or "rejected"),
    }
end

local function buildEquipmentTransferMessage(targetLabel, movedCount, rejectedCount)
    if movedCount > 0 and rejectedCount > 0 then
        return "Assigned " .. tostring(movedCount) .. " equipment item" .. (movedCount == 1 and "" or "s")
            .. " to " .. tostring(targetLabel) .. "; " .. tostring(rejectedCount) .. " failed."
    end
    if movedCount > 0 then
        return "Assigned " .. tostring(movedCount) .. " equipment item" .. (movedCount == 1 and "" or "s")
            .. " to " .. tostring(targetLabel) .. "."
    end
    return tostring(rejectedCount) .. " equipment item" .. (rejectedCount == 1 and "" or "s") .. " could not be assigned."
end

local function resolveWarehouseEquipmentIndexes(owner, args)
    if args and args.entryID then
        local targetID = tostring(args.entryID or "")
        local warehouse = Warehouse.GetOwnerWarehouse(owner)
        for index, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.equipment or {}) do
            if tostring(entry and entry.entryID or "") == targetID then
                return { index }
            end
        end
    end

    return Shared.normalizeLedgerIndexes(args)
end

Network.Handlers.AssignWorkerSite = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local x = args.x or (player and player:getX()) or nil
    local y = args.y or (player and player:getY()) or nil
    local z = args.z or (player and player:getZ()) or 0
    Sites.AssignSiteForWorker(worker, x, y, z, args.radius)
    if worker.homeX == nil or worker.homeY == nil then
        Registry.SetWorkerHome(worker, player and player:getX() or x, player and player:getY() or y, player and player:getZ() or z)
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.AssignWorkerToolset = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local requirementKey = args.requirementKey and tostring(args.requirementKey) or nil
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}
    local movedCount = 0

    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            if canAssignRequirement(worker, fullType, requirementKey) then
                local toolEntry = buildInventoryToolEntry(invItem)
                if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
                    rejectItem(rejected, itemID, "broken")
                elseif storeWorkerToolEntry(worker, toolEntry, requirementKey) then
                    Internal.removeInventoryItem(invItem)
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    movedCount = movedCount + 1
                else
                    rejectItem(rejected, itemID, "capacity")
                end
            else
                rejectItem(rejected, itemID, "not_required_equipment")
            end
        else
            rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = buildEquipmentTransferMessage("NPC inventory", movedCount, #rejected),
    })

    if movedCount > 0 then
        Shared.saveAndRefreshSupplyTransfer(player, worker)
    else
        if #rejected > 0 then
            Internal.syncNotice(player, "No selected equipment could be assigned.", "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker)
    end
end

Network.Handlers.AssignWarehouseToolset = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}
    local movedCount = 0

    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            local isRequiredEquipment = Config.IsRequiredEquipmentFullTypeForWorker
                and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
                or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker.jobType))
            if isRequiredEquipment then
                local toolEntry = buildInventoryToolEntry(invItem)
                if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
                    rejectItem(rejected, itemID, "broken")
                elseif Warehouse.DepositEquipmentEntry(owner, toolEntry) then
                    Internal.removeInventoryItem(invItem)
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    movedCount = movedCount + 1
                else
                    rejectItem(rejected, itemID, "capacity")
                end
            else
                rejectItem(rejected, itemID, "not_required_equipment")
            end
        else
            rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = buildEquipmentTransferMessage("warehouse", movedCount, #rejected),
    })

    if movedCount > 0 then
        Shared.saveAndRefreshSupplyTransfer(player, worker, true)
    else
        if #rejected > 0 then
            Internal.syncNotice(player, "No selected equipment could be stored.", "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker, true)
    end
end

Network.Handlers.AssignWarehouseToolToWorker = function(player, args)
    if not args or not args.workerID or not args.ledgerIndex or not args.requirementKey then
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        return
    end

    local requirementKey = tostring(args.requirementKey or "")
    if requirementKey == "" then
        return
    end

    local taken = Warehouse.TakeEquipmentEntries(owner, resolveWarehouseEquipmentIndexes(owner, args))
    local toolEntry = taken and taken[1] or nil
    if not toolEntry or not toolEntry.fullType then
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    local fullType = tostring(toolEntry.fullType or "")
    if fullType == ""
        or not canAssignRequirement(worker, fullType, requirementKey)
        or (Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry)) then
        Warehouse.DepositEquipmentEntry(owner, toolEntry, true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if not storeWorkerToolEntry(worker, toolEntry, requirementKey) then
        Warehouse.DepositEquipmentEntry(owner, toolEntry, true)
        Internal.syncNotice(player, "NPC inventory is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    Shared.saveAndRefreshProcessed(player, worker, true)
end

Network.Handlers.SetWarehouseAutoEquipEnabled = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    local enabled = args and args.enabled == true or false
    Warehouse.SetAutoEquipEnabled(owner, enabled)
    if Registry.Save then
        Registry.Save()
    end
    Internal.syncWarehouse(player, nil, true)
end

Network.Handlers.AutoEquipWorkerFromWarehouse = function(player, args)
    if not args or not args.workerID then
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        return
    end

    local added = Warehouse.RestockWorkerEquipment and Warehouse.RestockWorkerEquipment(worker, {
        includeOptional = true
    }) or 0
    Registry.RecalculateWorker(worker)
    Shared.saveAndRefreshBasic(player, worker, true)

    if added > 0 then
        Internal.syncNotice(player, "Auto-equipped " .. tostring(added) .. " warehouse item" .. (added == 1 and "" or "s") .. ".", "info", false)
    else
        Internal.syncNotice(player, "No matching warehouse equipment was available for this worker.", "info", false)
    end
end

return Network
