DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
local Config = DC_Colony.Config

if Config.JobProfiles and Config.JobProfiles.Scavenge then
    Config.JobProfiles.Scavenge.requiredToolTags = {}
end

Config.ScavengeItemProfiles = {
    ["Base.Crowbar"] = {
        tier = 1,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.LockedHome" },
        capabilities = { "Scavenge.Access.LockedHome" }
    },
    ["Base.CrowbarForged"] = {
        tier = 1,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.LockedHome" },
        capabilities = { "Scavenge.Access.LockedHome" }
    },
    ["Base.Screwdriver"] = {
        tier = 1,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" },
        capabilities = { "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" }
    },
    ["Base.Screwdriver_Old"] = {
        tier = 1,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" },
        capabilities = { "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" }
    },
    ["Base.Screwdriver_Improvised"] = {
        tier = 1,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" },
        capabilities = { "Scavenge.Access.LockedHome", "Scavenge.Access.ElectronicStore" }
    },
    ["Base.Sledgehammer"] = {
        tier = 3,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.HeavyEntry" },
        capabilities = { "Scavenge.Access.HeavyEntry" }
    },
    ["Base.Sledgehammer2"] = {
        tier = 3,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.HeavyEntry" },
        capabilities = { "Scavenge.Access.HeavyEntry" }
    },
    ["Base.SledgehammerForged"] = {
        tier = 3,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Access.HeavyEntry" },
        capabilities = { "Scavenge.Access.HeavyEntry" }
    },
    ["Base.Hammer"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.HammerForged"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.HammerStone"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.BallPeenHammer"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.BallPeenHammerForged"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.ClubHammer"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.ClubHammerForged"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentryHammer" },
        capabilities = { "Scavenge.Extraction.CarpentryHammer" }
    },
    ["Base.Saw"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentrySaw" },
        capabilities = { "Scavenge.Extraction.CarpentrySaw" }
    },
    ["Base.SmallSaw"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentrySaw" },
        capabilities = { "Scavenge.Extraction.CarpentrySaw" }
    },
    ["Base.GardenSaw"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentrySaw" },
        capabilities = { "Scavenge.Extraction.CarpentrySaw" }
    },
    ["Base.CrudeSaw"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.CarpentrySaw" },
        capabilities = { "Scavenge.Extraction.CarpentrySaw" }
    },
    ["Base.PipeWrench"] = {
        tier = 2,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.Plumbing" },
        capabilities = { "Scavenge.Extraction.Plumbing" }
    },
    ["Base.BlowTorch"] = {
        tier = 3,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.MetalTorch" },
        capabilities = { "Scavenge.Extraction.MetalTorch" }
    },
    ["Base.WeldingMask"] = {
        tier = 3,
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Extraction.MetalMask" },
        capabilities = { "Scavenge.Extraction.MetalMask" }
    },
    ["Base.EmptySandbag"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Haul.Bulk" },
        capabilities = { "Scavenge.Haul.Bulk" }
    },
    ["Base.Garbagebag"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Haul.Bulk" },
        capabilities = { "Scavenge.Haul.Bulk" }
    },
    ["Base.SheetRope"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Haul.Bundle" },
        capabilities = { "Scavenge.Haul.Bundle" }
    },
    ["Base.SheetRopeBundle"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Haul.Bundle" },
        capabilities = { "Scavenge.Haul.Bundle" }
    },
    ["Base.Pen"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    },
    ["Base.BluePen"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    },
    ["Base.GreenPen"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    },
    ["Base.RedPen"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    },
    ["Base.PenFancy"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    },
    ["Base.PenMultiColor"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    },
    ["Base.PenSpiffo"] = {
        labourTags = { "Colony.Tool.Scavenge", "Scavenge.Utility.Pen" },
        capabilities = { "Scavenge.Utility.Pen" },
        routePlanning = 1
    }
}
