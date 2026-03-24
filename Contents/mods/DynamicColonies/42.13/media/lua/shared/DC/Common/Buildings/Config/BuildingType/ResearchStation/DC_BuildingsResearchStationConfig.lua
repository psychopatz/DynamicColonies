DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.ResearchStation = {
    buildingType = "ResearchStation",
    displayName = "Research Station",
    iconPath = "media/ui/Buildings/DC_ResearchStation.png",
    enabled = false,
    maxLevel = 3,
    isInfinite = false,
    levels = {}
}
