require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"

DC_Colony = DC_Colony or {}
DC_Colony.Output = DC_Colony.Output or {}

local Config = DC_Colony.Config
local Output = DC_Colony.Output
local Skills = DC_Colony.Skills

Output.CandidateCache = Output.CandidateCache or {}

local function matchesAllTags(itemTags, requiredTags)
    if type(itemTags) ~= "table" then return false end
    for _, required in ipairs(requiredTags or {}) do
        if not Config.HasMatchingTag(itemTags, required) then
            return false
        end
    end
    return true
end

local function getCandidates(requiredTags)
    local cacheKey = table.concat(requiredTags or {}, "|")
    if Output.CandidateCache[cacheKey] and #Output.CandidateCache[cacheKey] > 0 then
        return Output.CandidateCache[cacheKey]
    end

    local pool = {}
    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or {}
    for fullType, itemData in pairs(masterList) do
        if itemData and matchesAllTags(itemData.tags, requiredTags) then
            pool[#pool + 1] = fullType
        end
    end

    Output.CandidateCache[cacheKey] = pool
    return pool
end

local function applyWeightMultiplier(baseWeight, multiplier)
    local safeWeight = math.max(0, tonumber(baseWeight) or 0)
    local safeMultiplier = tonumber(multiplier)
    if safeWeight <= 0 then
        return 0
    end
    if safeMultiplier == nil then
        return safeWeight
    end
    if safeMultiplier <= 0 then
        return 0
    end
    return math.max(1, math.floor((safeWeight * safeMultiplier) + 0.5))
end

local function rollChance(chance)
    local safeChance = math.max(0, math.min(0.99, tonumber(chance) or 0))
    if safeChance <= 0 then
        return false
    end

    local scaled = math.max(1, math.floor((safeChance * 10000) + 0.5))
    return (ZombRand(10000) + 1) <= scaled
end

local function applyQuantityMultiplier(baseQty, multiplier)
    local safeQty = math.max(1, math.floor(tonumber(baseQty) or 1))
    local scaled = math.max(1, safeQty * math.max(0.01, tonumber(multiplier) or 1))
    local guaranteed = math.floor(scaled)
    local remainder = scaled - guaranteed

    if remainder > 0 and rollChance(remainder) then
        guaranteed = guaranteed + 1
    end

    return math.max(1, guaranteed)
end

local function getJobFailureChance(jobType)
    if jobType == Config.JobTypes.Farm then
        return 0.18
    end
    if jobType == Config.JobTypes.Fish then
        return 0.24
    end
    return 0
end

local function clampNumber(value, minimum, maximum)
    local safeValue = tonumber(value) or 0
    if safeValue < minimum then
        return minimum
    end
    if safeValue > maximum then
        return maximum
    end
    return safeValue
end

Output.matchesAllTags = matchesAllTags
Output.getCandidates = getCandidates
Output.applyWeightMultiplier = applyWeightMultiplier
Output.rollChance = rollChance
Output.applyQuantityMultiplier = applyQuantityMultiplier
Output.getJobFailureChance = getJobFailureChance
Output.clampNumber = clampNumber

function Output.GenerateForJob(profile, worker)
    local results = {
        entries = {},
        totalQuantity = 0,
        success = false,
        failed = false,
        failureReason = nil
    }
    if not profile then
        return results
    end

    local normalizedJobType = Config.NormalizeJobType and Config.NormalizeJobType(profile.jobType) or profile.jobType
    if normalizedJobType == Config.JobTypes.Scavenge then
        return Output.GenerateScavengeRun(worker)
    end

    local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or {
        speedMultiplier = 1,
        yieldMultiplier = 1,
        botchChanceMultiplier = 1,
        level = 0
    }
    results.skillEffects = skillEffects

    if rollChance(getJobFailureChance(normalizedJobType) * (skillEffects.botchChanceMultiplier or 1)) then
        results.failed = true
        results.failureReason = normalizedJobType == Config.JobTypes.Fish and "No catch this cycle." or "Botched cycle."
        return results
    end

    for _, rule in ipairs(profile.outputRules or {}) do
        local pool = getCandidates(rule.tags)
        if #pool > 0 then
            local picks = math.max(1, rule.picks or 1)
            for _ = 1, picks do
                local fullType = pool[ZombRand(#pool) + 1]
                local qty = ZombRand((rule.minQty or 1), (rule.maxQty or 1) + 1)
                qty = applyQuantityMultiplier(qty, skillEffects.yieldMultiplier)
                results.entries[#results.entries + 1] = {
                    fullType = fullType,
                    qty = qty
                }
                results.totalQuantity = results.totalQuantity + qty
            end
        end
    end

    results.success = results.totalQuantity > 0
    return results
end

function Output.GenerateForProfile(profile, worker)
    return Output.GenerateForJob(profile, worker)
end

return Output
