DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal

function Registry.GetRecruitAttempt(ownerUsername, sourceNPCID)
    if not sourceNPCID then return nil end
    local ownerData = Registry.EnsureOwner(ownerUsername)
    return ownerData.recruitAttempts[tostring(sourceNPCID)]
end

function Registry.SetRecruitAttempt(ownerUsername, sourceNPCID, attemptData)
    if not sourceNPCID then return nil end
    local ownerData = Registry.EnsureOwner(ownerUsername)
    local key = tostring(sourceNPCID)
    if attemptData == nil then
        ownerData.recruitAttempts[key] = nil
        return nil
    end

    ownerData.recruitAttempts[key] = Internal.CopyShallow(attemptData)
    return ownerData.recruitAttempts[key]
end

function Registry.FindWorkerBySourceID(ownerUsername, sourceNPCID)
    if not sourceNPCID then return nil end

    local owner = Config.GetOwnerUsername(ownerUsername)
    for _, worker in ipairs(Registry.GetWorkersForOwner(owner)) do
        if worker.sourceNPCID and tostring(worker.sourceNPCID) == tostring(sourceNPCID) then
            return worker
        end
    end

    return nil
end

return Registry
