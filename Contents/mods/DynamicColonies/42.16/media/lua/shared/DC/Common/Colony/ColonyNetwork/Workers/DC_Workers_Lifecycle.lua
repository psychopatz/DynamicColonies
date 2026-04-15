DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Presentation = DC_Colony.Presentation
local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.DeleteDeadWorker = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Internal.syncNotice(player, "That worker could not be found.", "error")
        return
    end

    if worker.state ~= Config.States.Dead then
        Internal.syncNotice(player, tostring(worker.name or worker.workerID) .. " is not dead.", "error")
        return
    end

    local workerID = worker.workerID
    local workerName = tostring(worker.name or worker.workerID)
    if DynamicTrading_Factions and DynamicTrading_Factions.OnColonyWorkerRemoved then
        DynamicTrading_Factions.OnColonyWorkerRemoved(owner, workerID)
    end
    if Presentation and Presentation.RemoveProjection then
        Presentation.RemoveProjection(worker)
    end

    Registry.RemoveWorkerForOwner(owner, workerID)
    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
        workerID = workerID
    })
    Internal.syncNotice(player, "Removed deceased worker " .. workerName .. ".", "success")
    Internal.syncWorkerList(player)
    Internal.syncOwnedFactionStatus(player)
end

return Network
