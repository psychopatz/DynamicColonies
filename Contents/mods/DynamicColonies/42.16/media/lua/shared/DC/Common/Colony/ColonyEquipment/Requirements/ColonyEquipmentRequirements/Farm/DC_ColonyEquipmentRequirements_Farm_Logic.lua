DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

-- ------------------------------------------------
-- Farm Logic Registration
-- ------------------------------------------------

if Config.Common and Config.Common.RegisterEquipmentRequirementKnownTypeHandler then
    Config.Common.RegisterEquipmentRequirementKnownTypeHandler(function()
        local fullTypes = {}
        -- Add farm-specific types if needed, currently no special profiles are listed in original Logic file
        return fullTypes
    end)
end

return Config
