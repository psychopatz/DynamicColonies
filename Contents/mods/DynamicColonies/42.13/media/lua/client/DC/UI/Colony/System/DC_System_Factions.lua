require "DC/UI/Faction/DC_PlayerFactionNameModal"
require "DC/UI/Faction/FactionInfoWindow/DC_FactionInfoWindow"

local System = DC_System

local function buildBlockedMessage(status)
    status = status or {}
    if status.faction then
        return "You already control a faction."
    end
    if status.createBlockedReason == "needs_recruit" then
        return "Recruit at least one labour worker first."
    end
    return "Faction eligibility is still syncing."
end

function System.GetOwnedFactionStatus()
    if (not isClient() or isServer()) and DynamicTrading_Factions and DynamicTrading_Factions.GetOwnedFactionStatus then
        local player = System.Internal and System.Internal.GetLocalPlayer and System.Internal.GetLocalPlayer() or nil
        System.ownedFactionStatusCache = DynamicTrading_Factions.GetOwnedFactionStatus(player)
    end
    return System.ownedFactionStatusCache or nil
end

function System.RequestOwnedFactionStatus()
    return System.SendCommand("RequestOwnedFactionStatus", {})
end

function System.OpenOwnedFactionManagement()
    local status = System.GetOwnedFactionStatus()
    if status and status.faction then
        DC_FactionInfoWindow.Open()
        if DC_FactionInfoWindow.instance and DC_FactionInfoWindow.instance.refreshList then
            DC_FactionInfoWindow.instance:refreshList()
        end
        return true, nil
    end
    return System.PromptCreateFaction()
end

function System.PromptCreateFaction()
    local status = System.GetOwnedFactionStatus()
    if not status or status.canCreate ~= true then
        return false, buildBlockedMessage(status)
    end

    DC_PlayerFactionNameModal.Open({
        title = "Create Faction",
        promptText = "Choose a name for your new faction.",
        onConfirm = function(name)
            if name == "" then
                if DC_MainWindow.instance and DC_MainWindow.instance.updateStatus then
                    DC_MainWindow.instance:updateStatus("Faction name cannot be empty.")
                end
                return
            end
            System.SendCommand("CreatePlayerFaction", {
                name = name
            })
        end
    })

    return true, nil
end
