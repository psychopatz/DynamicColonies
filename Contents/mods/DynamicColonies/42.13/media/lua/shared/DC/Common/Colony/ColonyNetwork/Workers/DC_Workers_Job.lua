DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Shared = (Network.Workers or {}).Shared or {}
local Skills = DC_Colony.Skills
local Internal = Network.Internal or {}

Network.Handlers = Network.Handlers or {}

local function getConstructionLevel(worker)
    local entry = Skills and Skills.GetSkillEntry and Skills.GetSkillEntry(worker, "Construction") or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function canAssignJobType(worker, jobType)
    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(jobType) or tostring(jobType or "")
    if normalizedJob == ((Config.JobTypes or {}).Builder) and getConstructionLevel(worker) <= 0 then
        return false, "That worker has no Construction skill and cannot be assigned to Builder."
    end
    return true, nil
end

Network.Handlers.SetWorkerJobEnabled = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    if args.enabled == true and Config.NormalizeJobType(worker.jobType) == ((Config.JobTypes or {}).Unemployed) then
        Internal.syncNotice(player, "Assign a job first. Unemployed workers stay idle until you choose a role.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    Registry.SetWorkerJobEnabled(worker, args.enabled == true)
    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.SetWorkerAutoRepeatScavenge = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    Registry.SetWorkerAutoRepeatScavenge(worker, args.enabled == true)
    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.SetWorkerJobType = function(player, args)
    if not args or not args.workerID or not args.jobType then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local canAssign, reason = canAssignJobType(worker, args.jobType)
    if not canAssign then
        Internal.syncNotice(player, reason or "That worker cannot take that job.", "error")
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    Registry.SetWorkerJobType(worker, args.jobType)
    Shared.saveAndRefreshProcessed(player, worker)
end

return Network
