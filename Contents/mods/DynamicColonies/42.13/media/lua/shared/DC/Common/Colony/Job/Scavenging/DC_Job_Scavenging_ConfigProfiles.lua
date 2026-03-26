DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
DC_Colony.Config.Internal = DC_Colony.Config.Internal or {}

local Config = DC_Colony.Config
local Internal = Config.Internal

function Config.GetScavengeItemProfile(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local profile = Internal.CloneProfileTable(Config.ScavengeItemProfiles[fullType] or {})
    local tags = Config.FindItemTags(fullType)
    local defaults = Config.ScavengeLootDefaults or {}

    if Config.HasMatchingTag(tags, "Container.Bag.Backpack") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Colony.Tool.Scavenge", "Scavenge.Haul.Bag" },
            capabilities = { "Scavenge.Haul.Bag" },
            haulBonus = Config.HasMatchingTag(tags, "Container.WeightReduction.High") and 2 or 1
        })
    elseif Config.HasMatchingTag(tags, "Container.Bag.Duffel") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Colony.Tool.Scavenge", "Scavenge.Haul.Bag" },
            capabilities = { "Scavenge.Haul.Bag" },
            haulBonus = 1
        })
    end

    if Config.HasMatchingTag(tags, "Electronics.Light") or Config.HasMatchingTag(tags, "Electronics.LightSource") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Light" },
            capabilities = { "Scavenge.Utility.Light" },
            searchSpeedMultiplier = defaults.litSearchSpeedMultiplier or 1.0
        })
    end

    if Config.HasMatchingTag(tags, "Literature.Media") then
        Internal.ExtendScavengeProfile(profile, {
            labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Map" },
            capabilities = { "Scavenge.Utility.Map" },
            routePlanning = 1
        })
    end

    if not Internal.HasTableEntries(profile) then
        return nil
    end

    return profile
end

function Config.GetItemCombinedTags(fullType)
    local tags = Internal.AppendUniqueValues({}, Config.FindItemTags(fullType))
    local scavengeProfile = Config.GetScavengeItemProfile(fullType)
    local fishingProfile = Config.GetFishingItemProfile and Config.GetFishingItemProfile(fullType) or nil
    local backpackProfile = Config.GetBackpackItemProfile and Config.GetBackpackItemProfile(fullType) or nil
    if scavengeProfile and scavengeProfile.labourTags then
        Internal.AppendUniqueValues(tags, scavengeProfile.labourTags)
    end
    if fishingProfile and fishingProfile.labourTags then
        Internal.AppendUniqueValues(tags, fishingProfile.labourTags)
    end
    if backpackProfile and backpackProfile.labourTags then
        Internal.AppendUniqueValues(tags, backpackProfile.labourTags)
    end
    if DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.GetBuilderToolTags then
        Internal.AppendUniqueValues(tags, DC_Buildings.Config.GetBuilderToolTags(fullType))
    end
    return tags
end

function Config.IsColonyToolFullType(fullType)
    if not fullType or fullType == "" then
        return false
    end

    local tags = Config.FindItemTags(fullType)
    if Config.HasMatchingTag(tags, "Tool") then
        return true
    end
    if DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.IsBuilderToolFullType
        and DC_Buildings.Config.IsBuilderToolFullType(fullType) then
        return true
    end

    if Config.GetScavengeItemProfile(fullType) ~= nil then
        return true
    end

    if Config.GetFishingItemProfile and Config.GetFishingItemProfile(fullType) ~= nil then
        return true
    end

    return Config.GetBackpackItemProfile and Config.GetBackpackItemProfile(fullType) ~= nil
end

return Config
