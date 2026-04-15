DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}
Config.InstallDefinitions = Config.InstallDefinitions or {}

Config.DEFAULT_INFIRMARY_BASE_CAPACITY = 1

Config.Definitions.Infirmary = {
    buildingType = "Infirmary",
    displayName = "Infirmary",
    iconPath = "media/ui/Buildings/DC_Infirmary.png",
    enabled = true,
    maxLevel = 3,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { fullType = "Base.Log", count = 4 },
                { fullType = "Base.Nails", count = 10 },
                { fullType = "Base.Sheet", count = 2 },
                { fullType = "Base.Hinge", count = 1 }
            },
            effects = {
                infirmaryBaseCapacity = 1,
                infirmaryCapacityCap = 5
            }
        },
        [2] = {
            enabled = true,
            workPoints = 54,
            xpReward = 120,
            recipe = {
                { fullType = "Base.Log", count = 6 },
                { fullType = "Base.Nails", count = 16 },
                { fullType = "Base.Sheet", count = 4 },
                { fullType = "Base.Hinge", count = 2 },
                { fullType = "Base.Woodglue", count = 1 }
            },
            effects = {
                infirmaryBaseCapacity = 1,
                infirmaryCapacityCap = 10
            }
        },
        [3] = {
            enabled = true,
            workPoints = 78,
            xpReward = 120,
            recipe = {
                { fullType = "Base.Log", count = 8 },
                { fullType = "Base.Nails", count = 24 },
                { fullType = "Base.Sheet", count = 6 },
                { fullType = "Base.Hinge", count = 4 },
                { fullType = "Base.Woodglue", count = 2 }
            },
            effects = {
                infirmaryBaseCapacity = 1,
                infirmaryCapacityCap = 15
            }
        }
    }
}

Config.InstallDefinitions.Infirmary = {
    bed = {
        installKey = "bed",
        displayName = "Bed",
        iconPath = "media/ui/Buildings/DC_Infirmary.png",
        requiredLevel = 1,
        maxCount = 14,
        workPoints = 18,
        xpReward = 60,
        recipe = {
            { fullType = "Base.Log", count = 2 },
            { fullType = "Base.Nails", count = 10 },
            { fullType = "Base.Sheet", count = 1 },
            { fullType = "Base.Hinge", count = 1 }
        },
        effects = {
            infirmaryCapacityBonus = 1
        },
        description = "Adds another medical bed so one more worker can receive infirmary treatment while sleeping."
    }
}

Config.Infirmary = Config.Infirmary or {}

function Config.GetInfirmaryBaseCapacity(level)
    local levelDefinition = Config.GetLevelDefinition("Infirmary", level)
    return math.max(
        0,
        math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.infirmaryBaseCapacity) or Config.DEFAULT_INFIRMARY_BASE_CAPACITY)
    )
end

function Config.GetInfirmaryCapacityCap(level)
    local levelDefinition = Config.GetLevelDefinition("Infirmary", level)
    local levelIndex = math.max(0, math.floor(tonumber(level) or 0))
    return math.max(
        0,
        math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.infirmaryCapacityCap) or (levelIndex * 5))
    )
end

function Config.Infirmary.GetInstallMaxCount(installKey, buildingLevel)
    if tostring(installKey or "") == "bed" then
        local level = math.max(0, math.floor(tonumber(buildingLevel) or 0))
        return math.max(0, Config.GetInfirmaryCapacityCap(level) - Config.GetInfirmaryBaseCapacity(level))
    end
    
    local definition = Config.GetInstallDefinition("Infirmary", installKey)
    if not definition then
        return 0
    end
    return math.max(0, math.floor(tonumber(definition.maxCount) or 0))
end
