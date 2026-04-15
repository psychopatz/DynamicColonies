DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}

local Definitions = {
    ["Fish.Tool.Basic"] = {
        label = "Fishing Tool",
        hintText = "Fishing spear or fishing rod",
        reasonText = "Needed so the worker can fish, with the spear serving as the renewable starter tool.",
        searchText = "crafted spear fire hardened spear crude spear stone spear fishing rod",
        supportedFullTypes = {
            "Base.SpearCrafted",
            "Base.SpearCraftedFireHardened",
            "Base.SpearCrude",
            "Base.SpearCrudeLong",
            "Base.SpearStone",
            "Base.SpearStoneLong",
            "Base.CraftedFishingRod",
            "Base.FishingRod"
        },
        iconFullType = "Base.SpearCrafted",
        jobTypes = { "Fish" },
        autoEquip = true,
        sortOrder = 130,
    },
    ["Fish.Upgrade.Rod"] = {
        label = "Fishing Rod",
        hintText = "Crafted fishing rod or fishing rod",
        reasonText = "A rod setup unlocks better fish and supports baited fishing.",
        searchText = "crafted fishing rod fishing rod",
        supportedFullTypes = { "Base.CraftedFishingRod", "Base.FishingRod" },
        iconFullType = "Base.FishingRod",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 131,
    },
    ["Fish.Upgrade.Line"] = {
        label = "Fishing Line",
        hintText = "Fishing line or premium fishing line",
        reasonText = "A proper line is required before rod-based fishing can land larger catches.",
        searchText = "fishing line premium fishing line",
        supportedFullTypes = { "Base.FishingLine", "Base.PremiumFishingLine" },
        iconFullType = "Base.FishingLine",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 132,
    },
    ["Fish.Upgrade.Tackle"] = {
        label = "Fishing Tackle",
        hintText = "Hook, lure, bobber, or gaff",
        reasonText = "Tackle improves the rod setup enough to target the biggest fish.",
        searchText = "fishing hook lure bobber gaff tackle",
        supportedFullTypes = {
            "Base.FishingHook",
            "Base.FishingHook_Bone",
            "Base.FishingHook_Forged",
            "Base.FishingHookBox",
            "Base.Bobber",
            "Base.JigLure",
            "Base.MinnowLure",
            "Base.Gaffhook"
        },
        iconFullType = "Base.FishingHook",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 133,
    },
    ["Fish.Upgrade.Bait"] = {
        label = "Fishing Bait",
        hintText = "Worms, maggots, insects, leeches, or chum",
        reasonText = "Bait speeds up rod fishing and improves bite consistency, but it can be consumed.",
        searchText = "worm maggots cricket grasshopper leech tadpole bait fish chum",
        supportedFullTypes = {
            "Base.Worm",
            "Base.Maggots",
            "Base.Cricket",
            "Base.Grasshopper",
            "Base.Leech",
            "Base.Tadpole",
            "Base.BaitFish",
            "Base.Chum"
        },
        iconFullType = "Base.Worm",
        jobTypes = { "Fish" },
        autoEquip = false,
        sortOrder = 134,
    },
}

for key, definition in pairs(Definitions) do
    Config.EquipmentRequirementDefinitions[key] = definition
end

return Config
