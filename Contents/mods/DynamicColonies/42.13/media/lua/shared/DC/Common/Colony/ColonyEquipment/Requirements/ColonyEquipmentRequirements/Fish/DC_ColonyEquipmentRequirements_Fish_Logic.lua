DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

-- ------------------------------------------------
-- Fish Logic Registration
-- ------------------------------------------------

if Config.Common and Config.Common.RegisterEquipmentRequirementKnownTypeHandler then
    Config.Common.RegisterEquipmentRequirementKnownTypeHandler(function()
        local fullTypes = {}
        for fullType, _ in pairs(Config.FishingItemProfiles or {}) do
            Config.Common.AppendUniqueStrings(fullTypes, { fullType })
        end
        return fullTypes
    end)
end

return Config
