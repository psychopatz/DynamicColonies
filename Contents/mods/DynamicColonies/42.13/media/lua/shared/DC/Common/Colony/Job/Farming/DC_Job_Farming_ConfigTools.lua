DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
local Config = DC_Colony.Config

if Config.JobProfiles and Config.JobProfiles.Farm then
    Config.JobProfiles.Farm.requiredToolTags = {
        "Tool.Farming"
    }
end
