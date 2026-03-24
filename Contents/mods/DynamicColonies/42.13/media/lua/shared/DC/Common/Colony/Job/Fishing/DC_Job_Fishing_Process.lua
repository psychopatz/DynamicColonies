local Sim = DC_Colony.Sim

-- Fishing shares the exact same logic flow as Farming (producing output items based on outputRules).
-- We wrap it here so Fishing has its own dedicated subsystem folder mapping for future expansion.
function Sim.ProcessFishingJob(worker, ctx)
    return Sim.ProcessGenericJob(worker, ctx)
end
