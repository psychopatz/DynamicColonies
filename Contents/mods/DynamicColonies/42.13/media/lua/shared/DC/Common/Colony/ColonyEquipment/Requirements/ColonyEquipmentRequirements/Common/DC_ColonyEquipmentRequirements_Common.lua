DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}

local Definitions = {
    ["Colony.Carry.Backpack"] = {
        label = "Backpack",
        hintText = "Any wearable bag with capacity and weight reduction",
        reasonText = "A wearable backpack expands worker inventory capacity across every job.",
        searchText = "wearable backpack duffel satchel hiking bag schoolbag",
        supportedFullTypes = {},
        iconFullType = "Base.Bag_Schoolbag",
        allJobTypes = true,
        autoEquip = false,
        sortOrder = 135,
    },
    ["Colony.Combat.Melee"] = {
        label = "Melee",
        hintText = "Any melee weapon the companion can fight with",
        reasonText = "Keeps a combat-capable worker ready for close fights during survival encounters.",
        searchText = "melee weapon blade blunt spear axe knife bat",
        supportedFullTypes = {},
        iconFullType = "Base.BaseballBat",
        requirementTags = { "Weapon.Melee" },
        allJobTypes = true,
        combatCapability = "melee",
        autoEquip = false,
        sortOrder = 136,
    },
    ["Colony.Combat.Ranged"] = {
        label = "Ranged",
        hintText = "Any firearm the companion can shoot",
        reasonText = "Keeps a shooting-capable worker ready for ranged combat when needed.",
        searchText = "ranged firearm pistol revolver shotgun rifle gun",
        supportedFullTypes = {},
        iconFullType = "Base.Pistol",
        requirementTags = { "Weapon.Ranged.Firearm" },
        allJobTypes = true,
        combatCapability = "shooting",
        autoEquip = false,
        sortOrder = 137,
    },
    ["Colony.Combat.Ammo"] = {
        label = "Ammo",
        hintText = "Any ammunition matching the worker's ranged kit",
        reasonText = "Lets a shooting-capable worker actually use their ranged weapon in combat.",
        searchText = "ammo ammunition bullets shells rounds magazines",
        supportedFullTypes = {},
        iconFullType = "Base.Bullets9mmBox",
        requirementTags = { "Weapon.Ranged.Ammo" },
        allJobTypes = true,
        combatCapability = "shooting",
        autoEquip = false,
        sortOrder = 138,
    },
}

for key, definition in pairs(Definitions) do
    Config.EquipmentRequirementDefinitions[key] = definition
end

return Config
