DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
Internal.ReservePanel = Internal.ReservePanel or {}
local ReservePanel = Internal.ReservePanel

function ReservePanel.getConfig()
    if Internal.Config then
        return Internal.Config
    end
    if DC_Colony and DC_Colony.Config then
        return DC_Colony.Config
    end
    return {}
end

function ReservePanel.isFunction(value)
    return type(value) == "function"
end

function ReservePanel.formatReserveValue(value)
    if Internal.formatReserveValue then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

function ReservePanel.getJobDisplayName(worker, profile)
    if Internal.getJobDisplayName then
        return Internal.getJobDisplayName(worker, profile)
    end
    return tostring(worker and worker.jobType or profile and profile.displayName or "Unassigned")
end

function ReservePanel.getWorkerStateLabel(worker)
    if Internal.getWorkerStateLabel then
        return Internal.getWorkerStateLabel(worker)
    end
    return tostring(worker and worker.state or "Idle")
end

function ReservePanel.getWorkerJobColor(worker, profile)
    if Internal.getWorkerJobColor then
        return Internal.getWorkerJobColor(worker, profile)
    end
    return { r = 0.68, g = 0.8, b = 1, a = 1 }
end

function ReservePanel.formatDaysAndEta(daysValue, hoursValue)
    if Internal.formatDaysAndEta then
        return Internal.formatDaysAndEta(daysValue, hoursValue)
    end
    if daysValue == nil then
        return "No estimate"
    end
    if hoursValue ~= nil then
        return string.format("%.1f days | %.1fh", math.max(0, tonumber(daysValue) or 0), math.max(0, tonumber(hoursValue) or 0))
    end
    return string.format("%.1f days", math.max(0, tonumber(daysValue) or 0))
end
