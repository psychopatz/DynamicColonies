DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

-- ------------------------------------------------
-- Builder Logic Registration
-- ------------------------------------------------

if Config.Common and Config.Common.RegisterEquipmentRequirementKnownTypeHandler then
    Config.Common.RegisterEquipmentRequirementKnownTypeHandler(function()
        local fullTypes = {}
        local builderToolFullTypes = DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.BuilderToolFullTypes or nil
        for fullType, _ in pairs(builderToolFullTypes or {}) do
            Config.Common.AppendUniqueStrings(fullTypes, { fullType })
        end
        return fullTypes
    end)
end

return Config
