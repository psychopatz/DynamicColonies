DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
local Config = DC_Colony.Config

if Config.JobProfiles and Config.JobProfiles.Fish then
    Config.JobProfiles.Fish.requiredToolTags = {
        "Tool.Fishing"
    }
end
