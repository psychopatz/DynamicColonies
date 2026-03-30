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

local function canAssignRequirement(worker, fullType, requirementKey)
    local targetKey = tostring(requirementKey or "")
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
    if not args or not args.workerID or not args.itemID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local invItem = Internal.getInventoryItemByID(player, args.itemID)
    if not worker or not invItem then return end

    local fullType = invItem:getFullType()
    local requirementKey = args.requirementKey and tostring(args.requirementKey) or nil
    local isRequiredEquipment = canAssignRequirement(worker, fullType, requirementKey)
    if not isRequiredEquipment then return end

    local toolEntry = buildInventoryToolEntry(invItem)
    if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
        Internal.syncNotice(player, "That tool is broken or empty and cannot be assigned.", "error", true)
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    local stored = storeWorkerToolEntry(worker, toolEntry, requirementKey)
    if not stored then
        Internal.syncNotice(player, "NPC inventory is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker)
        return
    end
    Internal.removeInventoryItem(invItem)

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.AssignWarehouseToolset = function(player, args)
    if not args or not args.workerID or not args.itemID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local invItem = Internal.getInventoryItemByID(player, args.itemID)
    if not worker or not invItem then return end

    local fullType = invItem:getFullType()
    local isRequiredEquipment = Config.IsRequiredEquipmentFullTypeForWorker
        and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
        or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker.jobType))
    if not isRequiredEquipment then return end

    local toolEntry = buildInventoryToolEntry(invItem)
    if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
        Internal.syncNotice(player, "That tool is broken or empty and cannot be assigned.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    local stored = Warehouse.DepositEquipmentEntry(owner, toolEntry)
    if not stored then
        Internal.syncNotice(player, "Warehouse is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    Internal.removeInventoryItem(invItem)
    Shared.saveAndRefreshProcessed(player, worker, true)
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

    local taken = Warehouse.TakeEquipmentEntries(owner, Shared.normalizeLedgerIndexes(args))
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
