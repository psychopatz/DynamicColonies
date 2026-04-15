DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Headquarters = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DC_Headquarters.png",
    enabled = true,
    maxLevel = 0,
    isInfinite = true,
    levels = {}
}

local HQConfig = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DC_Headquarters.png",
    enabled = true,
    isInfinite = true
}

local function buildRecipe(targetLevel)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    return {
        { fullType = "Base.Log", count = 4 + (level * 2) },
        { fullType = "Base.Nails", count = 12 + (level * 8) },
        { fullType = "Base.Sheet", count = 2 + math.floor((level + 1) / 2) },
        { fullType = "Base.Hinge", count = 1 + math.floor(level / 2) }
    }
end

function HQConfig.GetDefinition()
    return {
        buildingType = HQConfig.buildingType,
        displayName = HQConfig.displayName,
        iconPath = HQConfig.iconPath,
        enabled = HQConfig.enabled,
        maxLevel = 0,
        isInfinite = true,
        levels = {}
    }
end

function HQConfig.GetLevelDefinition(targetLevel)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    local frontierConfig = Config and Config.Frontier or nil
    local currentCap = frontierConfig and frontierConfig.GetMaxActiveBarricades and frontierConfig.GetMaxActiveBarricades(level) or 0
    local previousCap = level > 1 and frontierConfig and frontierConfig.GetMaxActiveBarricades and frontierConfig.GetMaxActiveBarricades(level - 1) or 0
    return {
        enabled = true,
        workPoints = 30 + (level * 18),
        xpReward = 150 + (level * 20),
        recipe = buildRecipe(level),
        effects = {
            maxActiveBarricades = currentCap,
            barricadeCapDelta = math.max(0, currentCap - previousCap)
        }
    }
end

Config.HQ = HQConfig
