DC_Colony = DC_Colony or {}
DC_Colony.Energy = DC_Colony.Energy or {}

local Config = DC_Colony.Config

Config.DEFAULT_ENERGY_MAX = 100
Config.DEFAULT_ENERGY_LOW_THRESHOLD_RATIO = 0.10
Config.DEFAULT_ENERGY_WORK_DRAIN_PER_HOUR = 8
Config.DEFAULT_ENERGY_SCAVENGE_WORK_DRAIN_MULTIPLIER = 1.15
Config.DEFAULT_ENERGY_TRAVEL_DRAIN_PER_HOUR = 2
Config.DEFAULT_ENERGY_HOME_RECOVERY_PER_HOUR = 10
Config.DEFAULT_ENERGY_MELEE_COMBAT_DRAIN_PER_ATTACK = 0.90
Config.DEFAULT_ENERGY_RANGED_COMBAT_DRAIN_PER_ATTACK = 0.70
Config.DEFAULT_ENERGY_COMBAT_DRAIN_REDUCTION_PER_SKILL_LEVEL = 0.025
Config.DEFAULT_ENERGY_COMBAT_DRAIN_MIN_MULTIPLIER = 0.35

-- Backwards compatibility
Config.DEFAULT_TIREDNESS_MAX = Config.DEFAULT_ENERGY_MAX
Config.DEFAULT_TIREDNESS_LOW_THRESHOLD_RATIO = Config.DEFAULT_ENERGY_LOW_THRESHOLD_RATIO
Config.DEFAULT_TIREDNESS_WORK_DRAIN_PER_HOUR = Config.DEFAULT_ENERGY_WORK_DRAIN_PER_HOUR
Config.DEFAULT_TIREDNESS_SCAVENGE_WORK_DRAIN_MULTIPLIER = Config.DEFAULT_ENERGY_SCAVENGE_WORK_DRAIN_MULTIPLIER
Config.DEFAULT_TIREDNESS_TRAVEL_DRAIN_PER_HOUR = Config.DEFAULT_ENERGY_TRAVEL_DRAIN_PER_HOUR
Config.DEFAULT_TIREDNESS_HOME_RECOVERY_PER_HOUR = Config.DEFAULT_ENERGY_HOME_RECOVERY_PER_HOUR
Config.DEFAULT_TIREDNESS_MELEE_COMBAT_DRAIN_PER_ATTACK = Config.DEFAULT_ENERGY_MELEE_COMBAT_DRAIN_PER_ATTACK
Config.DEFAULT_TIREDNESS_RANGED_COMBAT_DRAIN_PER_ATTACK = Config.DEFAULT_ENERGY_RANGED_COMBAT_DRAIN_PER_ATTACK
Config.DEFAULT_TIREDNESS_COMBAT_DRAIN_REDUCTION_PER_SKILL_LEVEL = Config.DEFAULT_ENERGY_COMBAT_DRAIN_REDUCTION_PER_SKILL_LEVEL
Config.DEFAULT_TIREDNESS_COMBAT_DRAIN_MIN_MULTIPLIER = Config.DEFAULT_ENERGY_COMBAT_DRAIN_MIN_MULTIPLIER

function Config.GetEnergyMax(worker)
    return math.max(1, tonumber(Config.DEFAULT_ENERGY_MAX) or 100)
end

function Config.GetEnergyLowThresholdRatio()
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_LOW_THRESHOLD_RATIO) or 0.10)
end

function Config.GetEnergyLowThreshold(worker, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or Config.GetEnergyMax(worker))
    return math.max(0, math.min(safeMax, safeMax * Config.GetEnergyLowThresholdRatio()))
end

function Config.GetEnergyBaseWorkDrainPerHour()
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_WORK_DRAIN_PER_HOUR) or 8)
end

function Config.GetEnergyScavengeWorkDrainMultiplier()
    return math.max(0.01, tonumber(Config.DEFAULT_ENERGY_SCAVENGE_WORK_DRAIN_MULTIPLIER) or 1.15)
end

function Config.GetEnergyTravelDrainPerHour(worker, profile)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_TRAVEL_DRAIN_PER_HOUR) or 2)
end

function Config.GetEnergyHomeRecoveryPerHour(worker, profile)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_HOME_RECOVERY_PER_HOUR) or 10)
end

function Config.GetEnergyMeleeCombatDrainPerAttack(worker)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_MELEE_COMBAT_DRAIN_PER_ATTACK) or 0.90)
end

function Config.GetEnergyRangedCombatDrainPerAttack(worker)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_RANGED_COMBAT_DRAIN_PER_ATTACK) or 0.70)
end

function Config.GetEnergyCombatDrainReductionPerSkillLevel(worker)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_COMBAT_DRAIN_REDUCTION_PER_SKILL_LEVEL) or 0.025)
end

function Config.GetEnergyCombatDrainMinMultiplier(worker)
    return math.max(0.05, math.min(1.0, tonumber(Config.DEFAULT_ENERGY_COMBAT_DRAIN_MIN_MULTIPLIER) or 0.35))
end

-- Aliases for Tiredness functions
Config.GetTirednessMax = Config.GetEnergyMax
Config.GetTirednessLowThresholdRatio = Config.GetEnergyLowThresholdRatio
Config.GetTirednessLowThreshold = Config.GetEnergyLowThreshold
Config.GetTirednessBaseWorkDrainPerHour = Config.GetEnergyBaseWorkDrainPerHour
Config.GetTirednessScavengeWorkDrainMultiplier = Config.GetEnergyScavengeWorkDrainMultiplier
Config.GetTirednessTravelDrainPerHour = Config.GetEnergyTravelDrainPerHour
Config.GetTirednessHomeRecoveryPerHour = Config.GetEnergyHomeRecoveryPerHour
Config.GetTirednessMeleeCombatDrainPerAttack = Config.GetEnergyMeleeCombatDrainPerAttack
Config.GetTirednessRangedCombatDrainPerAttack = Config.GetEnergyRangedCombatDrainPerAttack
Config.GetTirednessCombatDrainReductionPerSkillLevel = Config.GetEnergyCombatDrainReductionPerSkillLevel
Config.GetTirednessCombatDrainMinMultiplier = Config.GetEnergyCombatDrainMinMultiplier

return DC_Colony.Energy

