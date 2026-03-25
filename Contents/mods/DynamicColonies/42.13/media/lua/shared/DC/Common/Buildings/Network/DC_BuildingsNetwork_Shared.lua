require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local ColonyConfig = DC_Colony.Config
local Network = DC_Colony.Network
local Registry = DC_Colony.Registry
local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

function Internal.canUseDebug(player)
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if player and player.getAccessLevel then
        local accessLevel = player:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
end

function Internal.sendResponse(player, module, command, args)
    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.SendResponse then
        DynamicTrading.ServerHelpers.SendResponse(player, module, command, args)
        return
    end

    if isServer() then
        sendServerCommand(player, module, command, args)
    else
        triggerEvent("OnServerCommand", module, command, args)
    end
end

function Internal.syncBuildingsSnapshot(player, ownerUsername)
    local owner = ColonyConfig.GetOwnerUsername(ownerUsername or player)
    if Buildings.EnsureInitialHeadquartersProject then
        Buildings.EnsureInitialHeadquartersProject(owner)
    end
    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingsSnapshot", {
        snapshot = Buildings.BuildOwnerSnapshot(owner, player)
    })
end

function Internal.syncProjectPreview(player, ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = ColonyConfig.GetOwnerUsername(ownerUsername or player)
    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncBuildingProjectPreview", {
        preview = Buildings.BuildProjectPreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey, player),
        buildingType = buildingType,
        mode = mode,
        plotX = plotX,
        plotY = plotY,
        buildingID = buildingID,
        installKey = installKey
    })
end

function Internal.syncWorkerList(player)
    local owner = ColonyConfig.GetOwnerUsername(player)
    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncPlayerWorkers", {
        workers = Registry.GetWorkerSummariesForOwner(owner)
    })
end

function Internal.removeInventoryItem(item)
    if not item then
        return
    end

    local container = item:getContainer()
    if container then
        container:DoRemoveItem(item)
    end
end

function Internal.addInventoryItem(container, fullType, count)
    if not container or not fullType then
        return nil
    end

    return container:AddItems(fullType, count or 1)
end

function Internal.getInventoryItemQuantity(item)
    if not item then
        return 0
    end

    local count = item.getCount and item:getCount() or nil
    count = math.floor(tonumber(count) or 0)
    if count > 0 then
        return count
    end

    return 1
end

function Internal.collectInventoryItemsRecursive(container, into)
    if not container or not into then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            into[#into + 1] = item
            if instanceof(item, "InventoryContainer") then
                Internal.collectInventoryItemsRecursive(item:getItemContainer(), into)
            end
        end
    end
end

return Network
