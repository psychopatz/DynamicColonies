DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}

local Definitions = {
    ["Tool.Farming"] = {
        label = "Farming Tool",
        hintText = "Hoe, trowel, or hand fork",
        reasonText = "Needed so the worker can tend plots and complete farming cycles.",
        searchText = "farming hoe trowel hand fork hand shovel",
        supportedFullTypes = { "Base.GardenHoe", "Base.Trowel", "Base.HandFork", "Base.HandShovel" },
        iconFullType = "Base.Trowel",
        jobTypes = { "Farm" },
        autoEquip = true,
        sortOrder = 120,
    },
}

for key, definition in pairs(Definitions) do
    Config.EquipmentRequirementDefinitions[key] = definition
end

return Config
