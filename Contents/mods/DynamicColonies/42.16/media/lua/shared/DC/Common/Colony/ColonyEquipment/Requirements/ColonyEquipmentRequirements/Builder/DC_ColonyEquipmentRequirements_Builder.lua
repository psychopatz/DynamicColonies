DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}

local Definitions = {
    ["Builder.Tool.Hammer"] = {
        label = "Hammer",
        hintText = "Hammer or ball-peen hammer",
        reasonText = "Needed so the builder can make progress on hammer-based construction work.",
        searchText = "builder hammer ball peen club hammer",
        supportedFullTypes = { "Base.Hammer", "Base.BallPeenHammer", "Base.ClubHammer" },
        iconFullType = "Base.Hammer",
        jobTypes = { "Builder" },
        autoEquip = true,
        sortOrder = 100,
    },
    ["Builder.Tool.Saw"] = {
        label = "Saw",
        hintText = "Saw or garden saw",
        reasonText = "Needed so the builder can cut lumber and complete wood construction tasks.",
        searchText = "builder saw garden saw small saw crude saw",
        supportedFullTypes = { "Base.Saw", "Base.GardenSaw", "Base.SmallSaw", "Base.CrudeSaw" },
        iconFullType = "Base.Saw",
        jobTypes = { "Builder" },
        autoEquip = true,
        sortOrder = 110,
    },
}

for key, definition in pairs(Definitions) do
    Config.EquipmentRequirementDefinitions[key] = definition
end

return Config
