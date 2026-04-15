DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
local Config = DC_Colony.Config

if Config.JobProfiles and Config.JobProfiles.Builder then
    Config.JobProfiles.Builder.requiredToolTags = {
        "Builder.Tool.Hammer",
        "Builder.Tool.Saw"
    }
end
