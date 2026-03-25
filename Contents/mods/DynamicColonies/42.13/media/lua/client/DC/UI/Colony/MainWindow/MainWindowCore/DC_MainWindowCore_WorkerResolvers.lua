DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

function Internal.resolveWorkerSummaries()
    if isClient() and not isServer() then
        return DC_MainWindow.cachedWorkers or {}
    end

    if DC_Colony and DC_Colony.Registry and DC_Colony.Registry.GetWorkerSummariesForOwner then
        return DC_Colony.Registry.GetWorkerSummariesForOwner(Internal.getOwnerUsername())
    end

    return {}
end

function Internal.resolveWorkerDetail(workerID, options)
    if not workerID then
        return nil
    end

    options = options or {}
    local includeWorkerLedgers = options.includeWorkerLedgers == true

    if isClient() and not isServer() then
        local cache = DC_MainWindow.cachedDetails or {}
        return cache[workerID]
    end

    if DC_Colony and DC_Colony.Registry and DC_Colony.Registry.GetWorkerDetailsForOwner then
        return DC_Colony.Registry.GetWorkerDetailsForOwner(
            Internal.getOwnerUsername(),
            workerID,
            false,
            includeWorkerLedgers
        )
    end

    return nil
end
