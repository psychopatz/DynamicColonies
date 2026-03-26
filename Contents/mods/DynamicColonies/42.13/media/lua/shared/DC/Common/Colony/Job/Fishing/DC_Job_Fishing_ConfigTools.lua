DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
DC_Colony.Config.Internal = DC_Colony.Config.Internal or {}

local Config = DC_Colony.Config
local Internal = Config.Internal

if Config.JobProfiles and Config.JobProfiles.Fish then
    Config.JobProfiles.Fish.requiredToolTags = {
        "Fish.Tool.Basic"
    }
end

Config.FishingDefaults = Config.FishingDefaults or {
    baitSpeedMultiplier = 1.60,
    baitFailureReduction = 0.04,
    baitConsumeChanceBase = 0.45,
    baitConsumeChancePerMaintenance = 0.03,
    baitConsumeChanceMin = 0.12,
}

Config.FishingFailureChanceByTier = Config.FishingFailureChanceByTier or {
    [1] = 0.28,
    [2] = 0.18,
    [3] = 0.10,
}

Config.FishingCatchPools = Config.FishingCatchPools or {
    [1] = { "Base.Crayfish", "Base.GreenSunfish", "Base.RedearSunfish" },
    [2] = { "Base.BlueCatfish", "Base.ChannelCatfish", "Base.FishRoeSac" },
    [3] = { "Base.FlatheadCatfish", "Base.Paddlefish" },
}

Config.FishingItemProfiles = Config.FishingItemProfiles or {
    ["Base.SpearCrafted"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic" },
        capabilities = { "Fish.Tool.Basic", "Fish.Tool.Spear" },
    },
    ["Base.SpearCraftedFireHardened"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic" },
        capabilities = { "Fish.Tool.Basic", "Fish.Tool.Spear" },
    },
    ["Base.SpearCrude"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic" },
        capabilities = { "Fish.Tool.Basic", "Fish.Tool.Spear" },
    },
    ["Base.SpearCrudeLong"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic" },
        capabilities = { "Fish.Tool.Basic", "Fish.Tool.Spear" },
    },
    ["Base.SpearStone"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic" },
        capabilities = { "Fish.Tool.Basic", "Fish.Tool.Spear" },
    },
    ["Base.SpearStoneLong"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic" },
        capabilities = { "Fish.Tool.Basic", "Fish.Tool.Spear" },
    },
    ["Base.CraftedFishingRod"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic", "Fish.Upgrade.Rod" },
        capabilities = { "Fish.Tool.Basic", "Fish.Upgrade.Rod", "Fish.Rod.Crafted" },
    },
    ["Base.FishingRod"] = {
        tier = 1,
        labourTags = { "Fish.Tool.Basic", "Fish.Upgrade.Rod" },
        capabilities = { "Fish.Tool.Basic", "Fish.Upgrade.Rod", "Fish.Rod.Standard" },
    },
    ["Base.FishingLine"] = {
        labourTags = { "Fish.Upgrade.Line" },
        capabilities = { "Fish.Upgrade.Line", "Fish.Line.Basic" },
    },
    ["Base.PremiumFishingLine"] = {
        labourTags = { "Fish.Upgrade.Line" },
        capabilities = { "Fish.Upgrade.Line", "Fish.Line.Premium" },
    },
    ["Base.FishingHook"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.FishingHook_Bone"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.FishingHook_Forged"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.FishingHookBox"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.Bobber"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.JigLure"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.MinnowLure"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.Gaffhook"] = {
        labourTags = { "Fish.Upgrade.Tackle" },
        capabilities = { "Fish.Upgrade.Tackle" },
    },
    ["Base.Worm"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.Maggots"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.Cricket"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.Grasshopper"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.Leech"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.Tadpole"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.BaitFish"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
    ["Base.Chum"] = {
        labourTags = { "Fish.Upgrade.Bait" },
        capabilities = { "Fish.Upgrade.Bait" },
    },
}

if Config.__equipmentRequirementCache then
    Config.__equipmentRequirementCache.definitionByKey = {}
    Config.__equipmentRequirementCache.definitionsByJob = {}
    Config.__equipmentRequirementCache.autoEquipByJob = {}
    Config.__equipmentRequirementCache.matchesByJobAndType = {}
    Config.__equipmentRequirementCache.knownEquipmentFullTypes = nil
end

local function entryHasTag(entry, tag)
    if not entry or not tag then
        return false
    end

    for _, itemTag in ipairs(entry.tags or {}) do
        if Config.TagMatches and Config.TagMatches(itemTag, tag) then
            return true
        end
        if tostring(itemTag or "") == tostring(tag or "") then
            return true
        end
    end

    return false
end

local function appendProfileValues(profile, values)
    if not values then
        return profile
    end

    profile.labourTags = Internal.AppendUniqueValues(profile.labourTags, values.labourTags)
    profile.capabilities = Internal.AppendUniqueValues(profile.capabilities, values.capabilities)
    profile.tier = math.max(tonumber(profile.tier) or 0, tonumber(values.tier) or 0)
    profile.catchSpeedMultiplier = math.max(
        tonumber(profile.catchSpeedMultiplier) or 0,
        tonumber(values.catchSpeedMultiplier) or 0
    )
    profile.catchChanceBonus = math.max(tonumber(profile.catchChanceBonus) or 0, tonumber(values.catchChanceBonus) or 0)
    profile.isBackpack = profile.isBackpack == true or values.isBackpack == true

    return profile
end

local function selectBestEntryForTag(worker, tag, preferredFullTypes)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    local preferredRank = {}
    for index, fullType in ipairs(preferredFullTypes or {}) do
        preferredRank[tostring(fullType or "")] = index
    end

    local bestIndex = nil
    local bestEntry = nil
    local bestRank = math.huge
    for index, entry in ipairs(worker and worker.toolLedger or {}) do
        local usable = not registryInternal or not registryInternal.IsEquipmentEntryUsable or registryInternal.IsEquipmentEntryUsable(entry)
        if usable and entryHasTag(entry, tag) then
            local rank = preferredRank[tostring(entry and entry.fullType or "")] or math.huge
            if not bestEntry or rank < bestRank then
                bestIndex = index
                bestEntry = entry
                bestRank = rank
            end
        end
    end

    return bestIndex, bestEntry
end

function Config.GetFishingItemProfile(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local profile = Internal.CloneProfileTable(Config.FishingItemProfiles[fullType] or {})
    appendProfileValues(profile, Config.GetBackpackItemProfile and Config.GetBackpackItemProfile(fullType) or nil)

    if not Internal.HasTableEntries(profile) then
        return nil
    end

    return profile
end

function Config.GetFishingTierLabel(tier)
    local safeTier = math.max(0, math.floor(tonumber(tier) or 0))
    if safeTier <= 0 then
        return "No Fishing Setup"
    end
    if safeTier == 1 then
        return "Tier 1 - Spear Fishing"
    end
    if safeTier == 2 then
        return "Tier 2 - Rod and Line"
    end
    return "Tier 3 - Full Tackle Rig"
end

function Config.GetFishingCarryProfile(worker)
    return Config.GetWorkerBackpackCarryProfile and Config.GetWorkerBackpackCarryProfile(worker) or nil
end

function Config.GetFishingLoadout(worker)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    local defaults = Config.FishingDefaults or {}
    local loadout = {
        tier = 0,
        tierLabel = Config.GetFishingTierLabel(0),
        activeToolIndex = nil,
        activeToolEntry = nil,
        rodIndex = nil,
        rodEntry = nil,
        lineIndex = nil,
        lineEntry = nil,
        tackleIndex = nil,
        tackleEntry = nil,
        baitIndex = nil,
        baitEntry = nil,
        hasBasicTool = false,
        hasRod = false,
        hasLine = false,
        hasTackle = false,
        hasBait = false,
        usesStandardRod = false,
        usesCraftedRod = false,
        baitApplies = false,
        baitSpeedMultiplier = 1.0,
        failureChanceModifier = 0,
        carryProfile = Config.GetFishingCarryProfile and Config.GetFishingCarryProfile(worker) or nil,
        capabilityList = {},
        capabilityMap = {},
    }

    local capabilitySeen = {}
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local usable = not registryInternal or not registryInternal.IsEquipmentEntryUsable or registryInternal.IsEquipmentEntryUsable(entry)
        local profile = usable and Config.GetFishingItemProfile and Config.GetFishingItemProfile(entry and entry.fullType or nil) or nil
        if profile then
            for _, capability in ipairs(profile.capabilities or {}) do
                if not capabilitySeen[capability] then
                    capabilitySeen[capability] = true
                    loadout.capabilityMap[capability] = true
                    loadout.capabilityList[#loadout.capabilityList + 1] = capability
                end
            end
        end
    end

    loadout.activeToolIndex, loadout.activeToolEntry = selectBestEntryForTag(worker, "Fish.Tool.Basic", {
        "Base.SpearCrafted",
        "Base.SpearCraftedFireHardened",
        "Base.SpearCrude",
        "Base.SpearCrudeLong",
        "Base.SpearStone",
        "Base.SpearStoneLong",
        "Base.CraftedFishingRod",
        "Base.FishingRod"
    })
    loadout.rodIndex, loadout.rodEntry = selectBestEntryForTag(worker, "Fish.Upgrade.Rod", {
        "Base.FishingRod",
        "Base.CraftedFishingRod"
    })
    loadout.lineIndex, loadout.lineEntry = selectBestEntryForTag(worker, "Fish.Upgrade.Line", {
        "Base.PremiumFishingLine",
        "Base.FishingLine"
    })
    loadout.tackleIndex, loadout.tackleEntry = selectBestEntryForTag(worker, "Fish.Upgrade.Tackle")
    loadout.baitIndex, loadout.baitEntry = selectBestEntryForTag(worker, "Fish.Upgrade.Bait")

    loadout.hasBasicTool = loadout.activeToolEntry ~= nil
    loadout.hasRod = loadout.rodEntry ~= nil
    loadout.hasLine = loadout.lineEntry ~= nil
    loadout.hasTackle = loadout.tackleEntry ~= nil
    loadout.hasBait = loadout.baitEntry ~= nil
    loadout.usesStandardRod = loadout.hasRod and tostring(loadout.rodEntry.fullType or "") == "Base.FishingRod"
    loadout.usesCraftedRod = loadout.hasRod and tostring(loadout.rodEntry.fullType or "") == "Base.CraftedFishingRod"
    if loadout.carryProfile and #(loadout.carryProfile.containers or {}) > 0 then
        if not loadout.capabilityMap["Colony.Carry.Backpack"] then
            loadout.capabilityMap["Colony.Carry.Backpack"] = true
            loadout.capabilityList[#loadout.capabilityList + 1] = "Colony.Carry.Backpack"
        end
    end

    if loadout.hasBasicTool then
        loadout.tier = 1
    end
    if loadout.hasRod and loadout.hasLine then
        loadout.tier = 2
    end
    if loadout.usesStandardRod and loadout.hasLine and loadout.hasTackle then
        loadout.tier = 3
    end

    loadout.baitApplies = loadout.tier >= 2 and loadout.hasBait
    if loadout.baitApplies then
        loadout.baitSpeedMultiplier = tonumber(defaults.baitSpeedMultiplier) or 1.60
        loadout.failureChanceModifier = -(tonumber(defaults.baitFailureReduction) or 0.04)
    end

    loadout.tierLabel = Config.GetFishingTierLabel(loadout.tier)

    return loadout
end

function Config.GetFishingBaitConsumeChance(worker)
    local defaults = Config.FishingDefaults or {}
    local skills = DC_Colony and DC_Colony.Skills or nil
    local maintenance = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, "Maintenance") or nil
    local maintenanceLevel = math.max(0, math.floor(tonumber(maintenance and maintenance.level) or 0))
    local chance = (tonumber(defaults.baitConsumeChanceBase) or 0.45)
        - (maintenanceLevel * (tonumber(defaults.baitConsumeChancePerMaintenance) or 0.03))
    return math.max(tonumber(defaults.baitConsumeChanceMin) or 0.12, math.min(0.95, chance))
end
