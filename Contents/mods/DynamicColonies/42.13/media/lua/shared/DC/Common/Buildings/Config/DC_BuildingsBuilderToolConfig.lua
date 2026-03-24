DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config

Config.DEFAULT_BUILDER_BASE_WORK_POINTS_PER_HOUR = 1.0

Config.ToolTags = Config.ToolTags or {}
Config.ToolTags.Builder = "Builder.Tool"
Config.ToolTags.Hammer = "Builder.Tool.Hammer"
Config.ToolTags.Saw = "Builder.Tool.Saw"

Config.BuilderToolFullTypes = {
    ["Base.Hammer"] = { Config.ToolTags.Builder, Config.ToolTags.Hammer },
    ["Base.BallPeenHammer"] = { Config.ToolTags.Builder, Config.ToolTags.Hammer },
    ["Base.ClubHammer"] = { Config.ToolTags.Builder, Config.ToolTags.Hammer },
    ["Base.Saw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw },
    ["Base.GardenSaw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw },
    ["Base.SmallSaw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw },
    ["Base.CrudeSaw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw }
}

function Config.GetBuilderToolTags(fullType)
    local mapped = Config.BuilderToolFullTypes[tostring(fullType or "")]
    local tags = {}
    for _, tag in ipairs(mapped or {}) do
        tags[#tags + 1] = tag
    end
    return tags
end

function Config.IsBuilderToolFullType(fullType)
    return Config.BuilderToolFullTypes[tostring(fullType or "")] ~= nil
end

function Config.GetBuilderBaseWorkPointsPerHour()
    return math.max(0.01, tonumber(Config.DEFAULT_BUILDER_BASE_WORK_POINTS_PER_HOUR) or 1.0)
end
