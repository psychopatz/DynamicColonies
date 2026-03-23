DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DC_Colony and DC_Colony.Config) or {}
        Internal.Config = config
    end
    return config
end

local function getPlayerObject()
    local config = getConfig()
    if type(config.GetPlayerObject) == "function" then
        return config.GetPlayerObject()
    end
    return nil
end

function Internal.getPlayerWealth(player)
    if DC_MainWindow.MoneyProvider and DC_MainWindow.MoneyProvider.getPlayerWealth then
        return DC_MainWindow.MoneyProvider:getPlayerWealth(player)
    end
    return 0
end

function Internal.getOwnerUsername()
    local config = getConfig()
    local player = getPlayerObject()
    if type(config.GetOwnerUsername) == "function" then
        return config.GetOwnerUsername(player)
    end
    return "local"
end

function Internal.appendHeldItem(targetList, seenIDs, itemObj)
    if not itemObj or not itemObj.getID then
        return
    end

    local itemID = itemObj:getID()
    if itemID == nil or seenIDs[itemID] then
        return
    end

    seenIDs[itemID] = true
    targetList[#targetList + 1] = itemObj
end

function Internal.getHeldItems()
    local player = getPlayerObject()
    if not player then
        return {}
    end

    local items = {}
    local seenIDs = {}
    Internal.appendHeldItem(items, seenIDs, player.getPrimaryHandItem and player:getPrimaryHandItem() or nil)
    Internal.appendHeldItem(items, seenIDs, player.getSecondaryHandItem and player:getSecondaryHandItem() or nil)
    return items
end
