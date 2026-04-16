DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
local Config = DC_Colony.Config

local TRAVEL_STAGE_OUTBOUND = "Outbound"
local TRAVEL_STAGE_ACTIVE = "Active"
local TRAVEL_STAGE_DEPARTING = "Departing"
local TRAVEL_STAGE_RETURNING = "Returning"
local COMMAND_CLAIM_RANGE_TILES = 6
local COMMAND_INVALID_GRACE_MS = 5 * 60 * 1000

local function debugCompanion(message)
    local text = "[DC Companion Debug] " .. tostring(message)
    print(text)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DTCommons", "Colony", "Companion", tostring(message))
    end
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getInteraction()
    return DC_Colony and DC_Colony.Interaction or nil
end

local function getHealth()
    return DC_Colony and DC_Colony.Health or nil
end

local function saveRegistry()
    local registry = getRegistry()
    if registry and registry.Save then
        registry.Save()
    end
end

local function getCurrentWorldHours()
    return (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
end

local function getCurrentMillis()
    if getTimeInMillis then
        return tonumber(getTimeInMillis()) or 0
    end

    local gt = getGameTime and getGameTime() or nil
    if gt and gt.getWorldAgeHours then
        return math.floor((tonumber(gt:getWorldAgeHours()) or 0) * 3600000)
    end

    return os and os.time and (os.time() * 1000) or 0
end

local function getPlayerUsername(player)
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return tostring(username)
        end
    end
    return nil
end

local function getPlayerOnlineID(player)
    if player and player.getOnlineID then
        return tonumber(player:getOnlineID())
    end
    return nil
end

local function getOnlinePlayerByUsername(username)
    local target = tostring(username or "")
    if target == "" then
        return nil
    end

    local localPlayer = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if localPlayer and localPlayer.getUsername and tostring(localPlayer:getUsername() or "") == target then
        return localPlayer
    end

    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for index = 0, players:size() - 1 do
            local player = players:get(index)
            if player and player.getUsername and tostring(player:getUsername() or "") == target then
                return player
            end
        end
    end

    return nil
end

local function isOnlinePlayerValid(username)
    local player = getOnlinePlayerByUsername(username)
    if not player then
        return false, nil
    end
    if player.isDead and player:isDead() then
        return false, player
    end
    return true, player
end

local function getActualFactionForUsername(username)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetPlayerFaction then
        return nil
    end
    return DynamicTrading_Factions.GetPlayerFaction(tostring(username or ""))
end

local function isUsernameInWorkerColony(worker, username)
    local normalizedUsername = tostring(username or "")
    if not worker or normalizedUsername == "" then
        return false
    end

    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(worker.ownerUsername) or tostring(worker.ownerUsername or "")
    if normalizedUsername == owner then
        return true
    end

    local faction = getActualFactionForUsername(normalizedUsername)
    if type(faction) ~= "table" then
        return false
    end

    if tostring(faction.leadershipState or "Active") ~= "Active" then
        return false
    end
    if tostring(faction.leaderUsername or "") ~= owner then
        return false
    end
    if normalizedUsername == owner then
        return true
    end
    for _, memberUsername in ipairs(faction.memberUsernames or {}) do
        if tostring(memberUsername or "") == normalizedUsername then
            return true
        end
    end

    return false
end

local function resolveWorkerFromCommandContext(workerOrNPC)
    local registry = getRegistry()
    if type(workerOrNPC) ~= "table" then
        return nil
    end
    if workerOrNPC.workerID then
        return workerOrNPC
    end
    local linkedWorkerID = workerOrNPC.linkedWorkerID
    if linkedWorkerID and registry and registry.GetWorkerRaw then
        return registry.GetWorkerRaw(linkedWorkerID)
    end
    return nil
end

local function getWorkerSkillLevel(worker, skillID)
    local common = Config and Config.Common or nil
    if common and common.GetWorkerSkillLevel then
        return math.max(0, math.floor(tonumber(common.GetWorkerSkillLevel(worker, skillID)) or 0))
    end

    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function getSkillsModule()
    local skills = DC_Colony and DC_Colony.Skills or nil
    if skills and skills.GrantXP and skills.EnsureWorkerSkills then
        return skills
    end

    pcall(function()
        require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
    end)

    skills = DC_Colony and DC_Colony.Skills or nil
    if skills and skills.GrantXP and skills.EnsureWorkerSkills then
        return skills
    end

    return nil
end

local function getCompanionCombatSkillID(attackType)
    local mode = tostring(attackType or "")
    if mode == "ranged" then
        return "Shooting"
    end
    if mode == "melee" then
        return "Melee"
    end
    return nil
end

local function getCompanionCombatDrainPerAttack(worker, attackType)
    local skillID = getCompanionCombatSkillID(attackType)
    if not skillID then
        return 0, nil, 0, 1
    end

    local skillLevel = getWorkerSkillLevel(worker, skillID)
    local baseDrain
    if skillID == "Shooting" then
        baseDrain = (Config.GetEnergyRangedCombatDrainPerAttack and Config.GetEnergyRangedCombatDrainPerAttack(worker))
            or (Config.GetTirednessRangedCombatDrainPerAttack and Config.GetTirednessRangedCombatDrainPerAttack(worker))
            or 0.70
    else
        baseDrain = (Config.GetEnergyMeleeCombatDrainPerAttack and Config.GetEnergyMeleeCombatDrainPerAttack(worker))
            or (Config.GetTirednessMeleeCombatDrainPerAttack and Config.GetTirednessMeleeCombatDrainPerAttack(worker))
            or 0.90
    end

    local reductionPerLevel = (Config.GetEnergyCombatDrainReductionPerSkillLevel and Config.GetEnergyCombatDrainReductionPerSkillLevel(worker))
        or (Config.GetTirednessCombatDrainReductionPerSkillLevel and Config.GetTirednessCombatDrainReductionPerSkillLevel(worker))
        or 0.025
    local minMultiplier = (Config.GetEnergyCombatDrainMinMultiplier and Config.GetEnergyCombatDrainMinMultiplier(worker))
        or (Config.GetTirednessCombatDrainMinMultiplier and Config.GetTirednessCombatDrainMinMultiplier(worker))
        or 0.35

    local multiplier = math.max(minMultiplier, 1 - (skillLevel * reductionPerLevel))
    return math.max(0, baseDrain * multiplier), skillID, skillLevel, multiplier
end

local function getTravelHours()
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if internal and internal.getScavengeTravelHours then
        return math.max(0, tonumber(internal.getScavengeTravelHours()) or 0)
    end

    return math.max(
        0,
        tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours())
            or tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end

local function appendLog(worker, text, currentHour, category)
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if internal and internal.appendWorkerLog then
        internal.appendWorkerLog(worker, text, currentHour or getCurrentWorldHours(), category or "travel")
    end
end

local function getRosterRegistry()
    if not DynamicTrading_Roster or not DynamicTrading_Roster.MOD_DATA_KEY then
        return nil
    end
    if not ModData or not ModData.get then
        return nil
    end
    return ModData.get(DynamicTrading_Roster.MOD_DATA_KEY)
end

local function getCompanionData(worker)
    if type(worker) ~= "table" then
        return nil
    end

    worker.companion = type(worker.companion) == "table" and worker.companion or {}
    return worker.companion
end

local function getCompanionUUID(worker)
    local companionData = getCompanionData(worker)
    local uuid = companionData and tostring(companionData.uuid or "") or ""
    return uuid ~= "" and uuid or nil
end

local saveSoul
local getSoul

local function getCommandVersion(companionData)
    return math.max(0, math.floor(tonumber(companionData and companionData.commandVersion) or 0))
end

local function mirrorCommanderToNPC(worker, npcData)
    if not worker or not npcData then
        return false
    end

    local companionData = getCompanionData(worker)
    npcData.dcCommanderUsername = companionData and companionData.commanderUsername or nil
    npcData.dcCommanderOnlineID = companionData and companionData.commanderOnlineID or nil
    npcData.dcCommandVersion = companionData and companionData.commandVersion or nil
    return true
end

local function syncCommanderToSoul(worker)
    local uuid = getCompanionUUID(worker)
    local npcData = uuid and getSoul(uuid) or nil
    if not uuid or not npcData then
        return false
    end

    mirrorCommanderToNPC(worker, npcData)
    saveSoul(uuid, npcData)

    if not isClient() or isServer() then
        local updates = {
            dcCommanderUsername = npcData.dcCommanderUsername,
            dcCommanderOnlineID = npcData.dcCommanderOnlineID,
            dcCommandVersion = npcData.dcCommandVersion,
        }
        if DTNPCServerCore and DTNPCServerCore.UpdateNPCByUUID then
            DTNPCServerCore.UpdateNPCByUUID(uuid, updates, true)
        end
    end
    return true
end

local function isFollowerCommandState(state)
    return state == "Follow"
        or state == "ProtectRanged"
        or state == "ProtectMelee"
        or state == "ProtectAuto"
end

local function issueCommanderFollowOrder(worker, targetPlayer, stateOverride, combatOrderOverride)
    local uuid = getCompanionUUID(worker)
    if not uuid or not targetPlayer or not DTNPCServerCore or not DTNPCServerCore.IssueOrderByUUID then
        return false
    end

    local npcData = getSoul(uuid)
    local state = stateOverride or (npcData and isFollowerCommandState(tostring(npcData.state or "")) and tostring(npcData.state or nil)) or "Follow"
    local combatOrder = combatOrderOverride or npcData and npcData.combatOrder or nil
    return DTNPCServerCore.IssueOrderByUUID(uuid, targetPlayer, {
        state = state,
        combatOrder = combatOrder,
        returnStatus = "Resting",
        systemCompanionOrder = true,
    }) == true
end

local function findExistingCompanionSoul(worker)
    if not worker or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
        return nil
    end

    local companionData = getCompanionData(worker)
    local existingUUID = companionData and companionData.uuid or nil
    if existingUUID and DynamicTrading_Roster.GetSoul(existingUUID) then
        return existingUUID, false
    end

    local rosterData = getRosterRegistry()
    local souls = rosterData and rosterData.Souls or nil
    if type(souls) ~= "table" then
        return nil
    end

    local ownerUsername = tostring(worker.ownerUsername or "")
    for uuid, soul in pairs(souls) do
        if soul
            and soul.linkedWorkerID == worker.workerID
            and tostring(soul.ownerUsername or "") == ownerUsername then
            local liveSoul = DynamicTrading_Roster.GetSoul(uuid)
            if liveSoul and tostring(liveSoul.dcCompanionJob or "") == tostring((Config.JobTypes and Config.JobTypes.TravelCompanion) or "TravelCompanion") then
                if companionData then
                    companionData.uuid = uuid
                end
                return uuid, false
            end
        end
    end

    return nil
end

saveSoul = function(uuid, npcData)
    if uuid and npcData and DynamicTrading_Roster and DynamicTrading_Roster.SaveSoul then
        DynamicTrading_Roster.SaveSoul(uuid, npcData)
    end
end

getSoul = function(uuid)
    if not uuid or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
        return nil
    end

    return DynamicTrading_Roster.GetSoul(uuid)
end

local function createCompanionSoul(worker)
    if not worker or not DynamicTrading_Roster or not DynamicTrading_Roster.AddSoul then
        return nil, "Dynamic Trading roster is unavailable.", false
    end

    local uuid, existing = findExistingCompanionSoul(worker)
    if uuid then
        return uuid, nil, existing == true
    end

    local homeCoords = {
        x = worker.homeX or 0,
        y = worker.homeY or 0,
        z = worker.homeZ or 0,
    }
    local archetypeID = worker.archetypeID or worker.profession or "General"

    uuid = DynamicTrading_Roster.AddSoul("Independent", archetypeID, homeCoords, {
        forceFaction = true
    })
    if not uuid then
        return nil, "Unable to create companion soul.", false
    end

    local companionData = getCompanionData(worker)
    if companionData then
        companionData.uuid = uuid
    end

    debugCompanion(
        "Created independent companion soul workerID=" .. tostring(worker.workerID)
            .. " uuid=" .. tostring(uuid)
            .. " owner=" .. tostring(worker.ownerUsername)
    )

    return uuid, nil, true
end

local function restoreWorkerAfterFailedStart(worker)
    if not worker then
        return
    end

    worker.jobEnabled = false
    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    worker.state = Config.States.Idle
end

local function getAmmoTypeForWeapon(fullType)
    local scriptItem = fullType and getScriptManager and getScriptManager():getItem(fullType) or nil
    if scriptItem and scriptItem.getAmmoType then
        local ammoType = scriptItem:getAmmoType()
        if ammoType and ammoType ~= "" then
            return tostring(ammoType)
        end
    end
    return nil
end

local function getFallbackAmmoCount(weaponType)
    local scriptItem = weaponType and getScriptManager and getScriptManager():getItem(weaponType) or nil
    local clipSize = scriptItem and scriptItem.getClipSize and tonumber(scriptItem:getClipSize()) or 0
    clipSize = math.max(1, math.floor(clipSize or 0))
    return clipSize * 3
end

local DEFAULT_COMPANION_LOADOUTS = {
    melee = {
        rangedWeapon = nil,
        rangedAmmoType = nil,
        ammoCount = 0,
        meleeWeapon = "Base.BaseballBat",
        bag = nil,
    },
    ranged = {
        rangedWeapon = "Base.Pistol",
        rangedAmmoType = "Base.Bullets9mm",
        ammoCount = 24,
        meleeWeapon = nil,
        bag = nil,
    },
    hybrid = {
        rangedWeapon = "Base.Pistol",
        rangedAmmoType = "Base.Bullets9mm",
        ammoCount = 24,
        meleeWeapon = "Base.BaseballBat",
        bag = nil,
    },
}

local function copyLoadout(loadout)
    local source = type(loadout) == "table" and loadout or {}
    return {
        rangedWeapon = source.rangedWeapon or nil,
        rangedAmmoType = source.rangedAmmoType or nil,
        ammoCount = math.max(0, tonumber(source.ammoCount) or 0),
        meleeWeapon = source.meleeWeapon or nil,
        bag = source.bag or nil,
        rangedCondition = source.rangedCondition ~= nil and tonumber(source.rangedCondition) or nil,
        meleeCondition = source.meleeCondition ~= nil and tonumber(source.meleeCondition) or nil,
    }
end

local function getFallbackLoadoutPreset(loadoutType)
    if DTNPCProtect and DTNPCProtect.GetWorldLoadoutPreset then
        local ok, preset = pcall(DTNPCProtect.GetWorldLoadoutPreset, loadoutType)
        if ok and type(preset) == "table" then
            return copyLoadout(preset)
        end
    end

    local preset = DEFAULT_COMPANION_LOADOUTS[loadoutType] or DEFAULT_COMPANION_LOADOUTS.melee
    return copyLoadout(preset)
end

local function getPreferredFallbackLoadoutType(worker)
    local melee = getWorkerSkillLevel(worker, "Melee")
    local shooting = getWorkerSkillLevel(worker, "Shooting")

    if shooting > 0 and melee > 0 then
        return "hybrid"
    end
    if shooting > 0 then
        return "ranged"
    end
    return "melee"
end

local function mergeFallbackCombatLoadout(worker, loadout)
    loadout = copyLoadout(loadout)

    local preferredType = getPreferredFallbackLoadoutType(worker)
    local fallback = getFallbackLoadoutPreset(preferredType)
    local appliedFallback = false

    if (not loadout.meleeWeapon or loadout.meleeWeapon == "")
        and (preferredType == "melee" or preferredType == "hybrid")
        and fallback.meleeWeapon and fallback.meleeWeapon ~= "" then
        loadout.meleeWeapon = fallback.meleeWeapon
        loadout.meleeCondition = fallback.meleeCondition
        appliedFallback = true
    end

    if (not loadout.rangedWeapon or loadout.rangedWeapon == "")
        and (preferredType == "ranged" or preferredType == "hybrid")
        and fallback.rangedWeapon and fallback.rangedWeapon ~= "" then
        loadout.rangedWeapon = fallback.rangedWeapon
        loadout.rangedCondition = fallback.rangedCondition
        appliedFallback = true
    end

    if loadout.rangedWeapon and (not loadout.rangedAmmoType or loadout.rangedAmmoType == "") then
        loadout.rangedAmmoType = fallback.rangedAmmoType or getAmmoTypeForWeapon(loadout.rangedWeapon)
        appliedFallback = true
    end

    if loadout.rangedWeapon and (tonumber(loadout.ammoCount) or 0) <= 0 then
        local fallbackAmmo = math.max(0, tonumber(fallback.ammoCount) or 0)
        loadout.ammoCount = fallbackAmmo > 0 and fallbackAmmo or getFallbackAmmoCount(loadout.rangedWeapon)
        appliedFallback = true
    end

    return loadout, appliedFallback, preferredType
end

local function hasTag(entry, targetTag)
    if type(entry) ~= "table" or type(entry.tags) ~= "table" then
        return false
    end

    for _, tag in ipairs(entry.tags) do
        if tag == targetTag or string.find(tostring(tag), "^" .. targetTag .. "%.") then
            return true
        end
    end

    return false
end

local function selectEquipmentEntries(worker)
    local selected = {
        ranged = nil,
        melee = nil,
        ammo = nil,
        bag = nil,
    }

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local requirementKey = tostring(entry and entry.assignedRequirementKey or "")
        if requirementKey == "Colony.Combat.Ranged" and not selected.ranged then
            selected.ranged = entry
        elseif requirementKey == "Colony.Combat.Melee" and not selected.melee then
            selected.melee = entry
        elseif requirementKey == "Colony.Combat.Ammo" and not selected.ammo then
            selected.ammo = entry
        elseif requirementKey == "Colony.Carry.Backpack" and not selected.bag then
            selected.bag = entry
        end
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if not selected.ranged and hasTag(entry, "Weapon.Ranged.Firearm") then
            selected.ranged = entry
        end
        if not selected.melee and hasTag(entry, "Weapon.Melee") then
            selected.melee = entry
        end
        if not selected.ammo and hasTag(entry, "Weapon.Ranged.Ammo") then
            selected.ammo = entry
        end
        if not selected.bag and hasTag(entry, "Colony.Carry.Backpack") then
            selected.bag = entry
        end
    end

    return selected
end

local function buildLoadoutFromWorker(worker)
    local chosen = selectEquipmentEntries(worker)
    local rangedWeapon = chosen.ranged and chosen.ranged.fullType or nil
    local meleeWeapon = chosen.melee and chosen.melee.fullType or nil
    local ammoType = chosen.ammo and chosen.ammo.fullType or getAmmoTypeForWeapon(rangedWeapon)
    local ammoCount = chosen.ammo and 24 or 0

    if rangedWeapon and ammoCount <= 0 then
        ammoCount = getFallbackAmmoCount(rangedWeapon)
    end

    local loadout = {
        rangedWeapon = rangedWeapon,
        rangedAmmoType = ammoType,
        ammoCount = math.max(0, tonumber(ammoCount) or 0),
        meleeWeapon = meleeWeapon,
        bag = chosen.bag and chosen.bag.fullType or nil,
        rangedCondition = chosen.ranged and chosen.ranged.condition or nil,
        meleeCondition = chosen.melee and chosen.melee.condition or nil,
    }

    local resolvedLoadout, appliedFallback, fallbackType = mergeFallbackCombatLoadout(worker, loadout)
    if appliedFallback then
        debugCompanion(
            "Applied fallback combat loadout workerID=" .. tostring(worker and worker.workerID)
                .. " type=" .. tostring(fallbackType)
                .. " melee=" .. tostring(resolvedLoadout.meleeWeapon or "nil")
                .. " ranged=" .. tostring(resolvedLoadout.rangedWeapon or "nil")
                .. " ammo=" .. tostring(resolvedLoadout.ammoCount or 0)
        )
    end

    return resolvedLoadout
end

local function buildHealthSeed(worker, npcData)
    local health = getHealth()
    local maxHp = math.max(
        1,
        tonumber(worker and worker.maxHp)
            or tonumber(worker and worker.healthMax)
            or tonumber(Config.DEFAULT_WORKER_MAX_HP)
            or 100
    )
    local currentHp = math.max(
        0,
        math.min(
            maxHp,
            tonumber(worker and worker.hp)
                or tonumber(worker and worker.health)
                or maxHp
        )
    )

    npcData.combatHealth = type(npcData.combatHealth) == "table" and npcData.combatHealth or {}
    npcData.combatHealth.max = maxHp
    npcData.combatHealth.current = currentHp
    npcData.combatHealth.baseMax = maxHp
    npcData.combatHealth.skillBonus = 0
    npcData.combatHealth.bandageUnlimited = false
    npcData.combatHealth.bandageCharges = 0
    npcData.combatHealth.activeBandage = false
    npcData.combatHealth.bandageDirty = false
    npcData.combatHealth.bandageStatus = "None"
    npcData.combatHealth.bandageHealPool = 0
    npcData.combatHealth.bandageHealRemaining = 0
    npcData.combatHealth.bandageActionUntil = 0
    npcData.combatHealth.bandageRetryAt = 0
    npcData.combatHealth.linkedWorkerMaxHp = maxHp
    npcData.combatHealth.linkedWorkerCurrentHp = currentHp
    npcData.combatHealth.linkedWorkerHealthOverride = true
    npcData.restingRegenMultiplier = health and health.GetSleepHealingRate and health.GetSleepHealingRate(worker) or nil
end

local function setSoulCompanionFlags(worker, npcData, active)
    local companionData = getCompanionData(worker)
    npcData.dcCompanionJob = Config.JobTypes and Config.JobTypes.TravelCompanion or "TravelCompanion"
    npcData.dcCompanionOwner = worker.ownerUsername
    npcData.dcCompanionStage = companionData and companionData.stage or nil
    npcData.dcCompanionActive = active == true
    mirrorCommanderToNPC(worker, npcData)
end

local function getMedicalBandageTier(fullType)
    local value = tostring(fullType or "")
    if value == "Base.AlcoholRippedSheets" then
        return "sterilized_rag", "Base.RippedSheetsDirty"
    end
    if value == "Base.RippedSheets" then
        return "clean_rag", "Base.RippedSheetsDirty"
    end
    if value == "Base.Bandage" or value == "Base.BandageBox" or value == "Base.AlcoholBandage" then
        return "bandage", "Base.BandageDirty"
    end
    return "clean_rag", "Base.RippedSheetsDirty"
end

local function removeNutritionEntry(worker, index)
    if not worker or not index then
        return
    end

    table.remove(worker.nutritionLedger, index)
    worker.nutritionCacheDirty = true
end

local function addDirtyMedicalOutput(worker, fullType)
    local registry = getRegistry()
    if not registry or not registry.AddOutputEntry or not fullType or fullType == "" then
        return
    end

    registry.AddOutputEntry(worker, {
        fullType = fullType,
        displayName = registry.Internal and registry.Internal.GetDisplayNameForFullType and registry.Internal.GetDisplayNameForFullType(fullType) or nil,
        qty = 1,
    })
end

local function finalizeReturnTravel(worker, currentHour)
    local companionData = getCompanionData(worker)
    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    if worker.state ~= Config.States.Dead and worker.state ~= Config.States.Incapacitated then
        worker.state = Config.States.Idle
    end
    companionData.awaitingDespawn = false
    companionData.stage = nil
    companionData.currentOrder = nil
    companionData.returnReason = nil
    companionData.returnTravelHours = nil
    companionData.commanderUsername = nil
    companionData.commanderOnlineID = nil
    companionData.commandInvalidSinceMs = nil
    appendLog(worker, "Returned home after companion duty.", currentHour, "travel")
end

function Companion.IsV2Active()
    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

function Companion.IsTravelCompanionWorker(worker)
    return Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) == ((Config.JobTypes or {}).TravelCompanion)
end

function Companion.CanWorkerBeCompanion(worker)
    if not Companion.IsV2Active() then
        return false, "Travel Companion needs V2."
    end

    local melee = getWorkerSkillLevel(worker, "Melee")
    local shooting = getWorkerSkillLevel(worker, "Shooting")
    if melee <= 0 and shooting <= 0 then
        return false, "Travel Companion requires Melee or Shooting skill."
    end

    return true, nil
end

local function canWorkerStartCompanionNow(worker)
    if not worker then
        return false, "Companion start is unavailable."
    end

    local homeState = tostring((Config.PresenceStates or {}).Home or "Home")
    if tostring(worker.presenceState or "") ~= homeState then
        return false, "Travel Companion can only start when the worker is at home."
    end

    local states = Config.States or {}
    local currentState = tostring(worker.state or "")
    if currentState == tostring(states.Incapacitated or "Incapacitated") then
        return false, "Worker is incapacitated and must recover first."
    end
    if currentState == tostring(states.Dead or "Dead") then
        return false, "Worker is dead and cannot start companion duty."
    end
    if currentState == tostring(states.Starving or "Starving") then
        return false, "Worker is hungry and must eat before companion duty."
    end
    if currentState == tostring(states.Dehydrated or "Dehydrated") then
        return false, "Worker is thirsty and must drink before companion duty."
    end

    local returnReason = tostring(worker.returnReason or "")
    local returnReasons = Config.ReturnReasons or {}
    if returnReason == tostring(returnReasons.LowFood or "LowFood") then
        return false, "Worker is hungry and must eat before companion duty."
    end
    if returnReason == tostring(returnReasons.LowDrink or "LowDrink") then
        return false, "Worker is thirsty and must drink before companion duty."
    end

    local energy = DC_Colony and DC_Colony.Energy or nil
    if energy and ((energy.IsForcedRest and energy.IsForcedRest(worker)) or (energy.IsDepleted and energy.IsDepleted(worker))) then
        return false, "Worker is too tired and must rest before companion duty."
    end

    local nutrition = DC_Colony and DC_Colony.Nutrition or nil
    if nutrition and nutrition.GetOnBodyTotals then
        local calories, hydration = nutrition.GetOnBodyTotals(worker)
        if (tonumber(calories) or 0) <= 0 then
            return false, "Worker is hungry and must eat before companion duty."
        end
        if (tonumber(hydration) or 0) <= 0 then
            return false, "Worker is thirsty and must drink before companion duty."
        end
    end

    return true, nil
end

function Companion.GetWorkerTravelHours(worker)
    return getTravelHours()
end

function Companion.GetHealthSeed(worker)
    if type(worker) ~= "table" then
        return nil
    end

    return {
        hp = math.max(0, tonumber(worker.hp) or tonumber(worker.health) or 0),
        maxHp = math.max(1, tonumber(worker.maxHp) or tonumber(worker.healthMax) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100),
    }
end

function Companion.SyncNPCFromWorker(worker, uuid)
    if not worker or not uuid then
        return false
    end

    local npcData = getSoul(uuid)
    if not npcData then
        return false
    end

    npcData.name = worker.name or npcData.name
    npcData.isFemale = worker.isFemale
    npcData.identitySeed = worker.identitySeed or npcData.identitySeed
    npcData.archetypeID = worker.archetypeID or npcData.archetypeID or worker.profession or "General"
    npcData.ownerUsername = worker.ownerUsername
    npcData.linkedWorkerID = worker.workerID
    npcData.isPlayerFactionTrader = false
    npcData.factionID = npcData.factionID or "Independent"
    npcData.homeCoords = {
        x = worker.homeX or 0,
        y = worker.homeY or 0,
        z = worker.homeZ or 0,
    }
    npcData.loadout = buildLoadoutFromWorker(worker)
    buildHealthSeed(worker, npcData)
    setSoulCompanionFlags(worker, npcData, worker.presenceState == Config.PresenceStates.CompanionActive)
    saveSoul(uuid, npcData)
    return true
end

function Companion.SyncActiveNPCFromWorker(worker, shouldBroadcast)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    local uuid = getCompanionUUID(worker)
    if not uuid then
        return false
    end

    local syncedSoul = Companion.SyncNPCFromWorker(worker, uuid) == true
    local npcData = getSoul(uuid)
    if not npcData then
        return syncedSoul
    end

    if isClient() and not isServer() then
        return syncedSoul
    end

    local liveSynced = false
    if DTNPCServerCore and DTNPCServerCore.UpdateNPCByUUID then
        local changed = DTNPCServerCore.UpdateNPCByUUID(uuid, {
            loadout = npcData.loadout,
            combatHealth = npcData.combatHealth,
            restingRegenMultiplier = npcData.restingRegenMultiplier,
        }, shouldBroadcast ~= false)
        liveSynced = changed == true
        debugCompanion(
            "SyncActiveNPCFromWorker workerID=" .. tostring(worker.workerID)
                .. " uuid=" .. tostring(uuid)
                .. " liveSynced=" .. tostring(liveSynced)
                .. " hp=" .. tostring(npcData.combatHealth and npcData.combatHealth.current or "nil")
                .. "/" .. tostring(npcData.combatHealth and npcData.combatHealth.max or "nil")
                .. " melee=" .. tostring(npcData.loadout and npcData.loadout.meleeWeapon or "nil")
                .. " ranged=" .. tostring(npcData.loadout and npcData.loadout.rangedWeapon or "nil")
                .. " bag=" .. tostring(npcData.loadout and npcData.loadout.bag or "nil")
        )
    end

    return syncedSoul or liveSynced
end

function Companion.CanPlayerCommandCompanion(player, workerOrNPC)
    local username = getPlayerUsername(player)
    local worker = resolveWorkerFromCommandContext(workerOrNPC)
    if not username or not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false, "Companion command is unavailable."
    end

    if not isUsernameInWorkerColony(worker, username) then
        return false, "You are not part of this companion's colony."
    end

    local companionData = getCompanionData(worker)
    local commander = tostring((companionData and companionData.commanderUsername)
        or (type(workerOrNPC) == "table" and workerOrNPC.dcCommanderUsername)
        or "")
    if commander == "" then
        return false, "No commander assigned. Use Claim Command while nearby."
    end

    if commander ~= username then
        return false, "Only " .. commander .. " can command this companion. Use Claim Command while nearby to take over."
    end

    return true, nil, worker
end

function Companion.AssignWorkerCompanionCommander(player, worker, targetUsername, reason)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false, "Companion command is unavailable."
    end

    local username = targetUsername and tostring(targetUsername or "") or getPlayerUsername(player)
    if username == "" then
        return false, "A target username is required."
    end

    if not isUsernameInWorkerColony(worker, username) then
        return false, "That player is not part of this companion's colony."
    end

    local companionData = getCompanionData(worker)
    local _, onlinePlayer = isOnlinePlayerValid(username)
    companionData.commanderUsername = username
    companionData.commanderOnlineID = onlinePlayer and getPlayerOnlineID(onlinePlayer) or nil
    companionData.commandVersion = getCommandVersion(companionData) + 1
    companionData.commandAssignedAtMs = getCurrentMillis()
    companionData.commandInvalidSinceMs = nil
    companionData.commandReason = reason or "assigned"
    syncCommanderToSoul(worker)
    return true, username
end

function Companion.RefreshCompanionCommanderValidity(worker)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return true
    end

    local companionData = getCompanionData(worker)
    local commander = tostring(companionData.commanderUsername or "")
    local presenceState = tostring(worker.presenceState or "")
    local activeState = Config.PresenceStates and Config.PresenceStates.CompanionActive or "CompanionActive"
    local toPlayerState = Config.PresenceStates and Config.PresenceStates.CompanionToPlayer or "CompanionToPlayer"
    if presenceState ~= activeState and presenceState ~= toPlayerState then
        companionData.commandInvalidSinceMs = nil
        return true
    end

    local validOnline = false
    if commander ~= "" and isUsernameInWorkerColony(worker, commander) then
        validOnline = isOnlinePlayerValid(commander)
    end

    if validOnline then
        if companionData.commandInvalidSinceMs ~= nil then
            companionData.commandInvalidSinceMs = nil
            syncCommanderToSoul(worker)
            saveRegistry()
        end
        return true
    end

    local now = getCurrentMillis()
    if companionData.commandInvalidSinceMs == nil then
        companionData.commandInvalidSinceMs = now
        local uuid = getCompanionUUID(worker)
        if uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
            DTNPCServerCore.IssueOrderByUUID(uuid, { ownerUsername = worker.ownerUsername }, {
                state = "Stay",
                returnStatus = "Resting",
                systemCompanionOrder = true,
            })
        end
        syncCommanderToSoul(worker)
        saveRegistry()
        return false
    end

    if now - (tonumber(companionData.commandInvalidSinceMs) or now) >= COMMAND_INVALID_GRACE_MS then
        Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        saveRegistry()
        return false
    end

    return false
end

function Companion.ClaimWorkerCompanionCommand(player, workerID)
    local username = getPlayerUsername(player)
    local registry = getRegistry()
    local owner = Config.GetOwnerUsername(player)
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    if not username or not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false, "Companion is unavailable.", nil
    end
    if not isUsernameInWorkerColony(worker, username) then
        return false, "You are not part of this companion's colony.", worker
    end

    local uuid = getCompanionUUID(worker)
    local zombie = nil
    if uuid and DTNPCServerCore and DTNPCServerCore.GetNPCDataByUUID then
        zombie = DTNPCServerCore.GetNPCDataByUUID(uuid)
    end
    if not zombie then
        return false, "Move near the live companion before claiming command.", worker
    end

    local dz = math.abs((tonumber(player:getZ()) or 0) - (tonumber(zombie:getZ()) or 0))
    local dx = (tonumber(player:getX()) or 0) - (tonumber(zombie:getX()) or 0)
    local dy = (tonumber(player:getY()) or 0) - (tonumber(zombie:getY()) or 0)
    local distance = math.sqrt((dx * dx) + (dy * dy))
    if dz > 1 or distance > COMMAND_CLAIM_RANGE_TILES then
        return false, "Move closer to claim command.", worker
    end

    local ok, result = Companion.AssignWorkerCompanionCommander(player, worker, username, "claimed")
    if ok then
        issueCommanderFollowOrder(worker, player, "Follow", nil)
        appendLog(worker, username .. " claimed companion command.", getCurrentWorldHours(), "travel")
        saveRegistry()
    end
    return ok, ok and "Command claimed." or result, worker
end

function Companion.TransferWorkerCompanionCommand(player, workerID, targetUsername)
    local username = getPlayerUsername(player)
    local target = tostring(targetUsername or "")
    local registry = getRegistry()
    local owner = Config.GetOwnerUsername(player)
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    if not username or not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false, "Companion is unavailable.", nil
    end

    local companionData = getCompanionData(worker)
    if tostring(companionData.commanderUsername or "") ~= username then
        return false, "Only the current commander can transfer command.", worker
    end
    if target == "" then
        return false, "A target username is required.", worker
    end
    if not isUsernameInWorkerColony(worker, target) then
        return false, "That player is not part of this companion's colony.", worker
    end

    local ok, result = Companion.AssignWorkerCompanionCommander(player, worker, target, "transferred")
    if ok then
        local online, targetPlayer = isOnlinePlayerValid(target)
        if online then
            issueCommanderFollowOrder(worker, targetPlayer, "Follow", nil)
        else
            companionData.commandInvalidSinceMs = getCurrentMillis()
            local uuid = getCompanionUUID(worker)
            if uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
                DTNPCServerCore.IssueOrderByUUID(uuid, { ownerUsername = worker.ownerUsername }, {
                    state = "Stay",
                    returnStatus = "Resting",
                    systemCompanionOrder = true,
                })
            end
            syncCommanderToSoul(worker)
        end
        appendLog(worker, username .. " transferred companion command to " .. target .. ".", getCurrentWorldHours(), "travel")
        saveRegistry()
    end
    return ok, ok and "Command transferred to " .. target .. "." or result, worker
end

function Companion.StartWorkerCompanion(player, worker)
    if not player or not worker or not Companion.IsTravelCompanionWorker(worker) then
        debugCompanion("StartWorkerCompanion rejected: invalid player/worker context")
        return false, "Companion start is unavailable."
    end

    local okay, reason = Companion.CanWorkerBeCompanion(worker)
    if not okay then
        debugCompanion("StartWorkerCompanion capability check failed workerID=" .. tostring(worker.workerID) .. " reason=" .. tostring(reason))
        return false, reason
    end

    local ready, readyReason = canWorkerStartCompanionNow(worker)
    if not ready then
        debugCompanion("StartWorkerCompanion readiness check failed workerID=" .. tostring(worker.workerID) .. " reason=" .. tostring(readyReason))
        return false, readyReason
    end

    local uuid, err, createdFresh = createCompanionSoul(worker)
    if not uuid then
        debugCompanion("StartWorkerCompanion failed to prepare companion soul workerID=" .. tostring(worker.workerID) .. " reason=" .. tostring(err))
        return false, err or "Unable to prepare companion soul."
    end

    debugCompanion(
        "StartWorkerCompanion prepared companion soul workerID=" .. tostring(worker.workerID)
            .. " uuid=" .. tostring(uuid)
            .. " owner=" .. tostring(worker.ownerUsername)
    )

    local companionData = getCompanionData(worker)
    companionData.uuid = uuid
    companionData.stage = TRAVEL_STAGE_OUTBOUND
    companionData.awaitingDespawn = false
    companionData.currentOrder = "Follow"
    companionData.returnReason = nil
    companionData.returnTravelHours = nil
    companionData.homeRecoveryLogged = false
    Companion.AssignWorkerCompanionCommander(player, worker, getPlayerUsername(player), "started")

    worker.presenceState = Config.PresenceStates.CompanionToPlayer
    worker.travelHoursRemaining = getTravelHours()
    worker.returnReason = nil
    worker.state = Config.States.Working

    Companion.SyncNPCFromWorker(worker, uuid)

    if isClient() and not isServer() then
        debugCompanion("StartWorkerCompanion client optimistic success workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid))
        return true, uuid
    end

    if not DTNPCServerCore then
        debugCompanion("StartWorkerCompanion missing DTNPCServerCore workerID=" .. tostring(worker.workerID))
        restoreWorkerAfterFailedStart(worker)
        return false, "Dynamic Trading V2 server controls are unavailable."
    end

    local spawned = false
    if DTNPCServerCore.SpawnOffscreenCompanionByUUID then
        spawned = DTNPCServerCore.SpawnOffscreenCompanionByUUID(uuid, player) == true
        debugCompanion("SpawnOffscreenCompanionByUUID workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid) .. " spawned=" .. tostring(spawned))
    end
    if not spawned and DTNPCServerCore.SpawnNearbyCompanionByUUID then
        spawned = DTNPCServerCore.SpawnNearbyCompanionByUUID(uuid, player, 2, 5) == true
        debugCompanion("SpawnNearbyCompanionByUUID fallback workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid) .. " spawned=" .. tostring(spawned))
    end

    local ordered = DTNPCServerCore.IssueOrderByUUID and DTNPCServerCore.IssueOrderByUUID(uuid, player, {
        state = "Follow",
        returnStatus = "Resting",
        systemCompanionOrder = true,
    })
    debugCompanion("IssueOrderByUUID Follow workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid) .. " ordered=" .. tostring(ordered))

    if ordered ~= true then
        debugCompanion("StartWorkerCompanion failed to issue follow order workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid))
        if createdFresh and DynamicTrading_Roster and DynamicTrading_Roster.RemoveSpecificSoul then
            DynamicTrading_Roster.RemoveSpecificSoul(uuid)
            local liveCompanionData = getCompanionData(worker)
            if liveCompanionData then
                liveCompanionData.uuid = nil
            end
        end
        restoreWorkerAfterFailedStart(worker)
        return false, "Unable to issue companion follow order."
    end

    appendLog(worker, "Left home and started heading to your location.", getCurrentWorldHours(), "travel")
    if not spawned then
        debugCompanion("StartWorkerCompanion continuing after order-driven spawn workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid))
    end
    return true, uuid
end

function Companion.IssueWorkerCompanionOrder(player, workerID, order, args)
    if isClient() and not isServer() then
        return false, "Server-only companion control."
    end

    local registry = getRegistry()
    local worker = registry and registry.GetWorker and registry.GetWorker(workerID) or nil
    local uuid = worker and getCompanionUUID(worker) or nil
    if not worker or not uuid or not DTNPCServerCore or not DTNPCServerCore.IssueOrderByUUID then
        return false, "Companion is unavailable."
    end

    local canCommand, commandReason = Companion.CanPlayerCommandCompanion(player, worker)
    if not canCommand then
        return false, commandReason or "Only the current commander can command this companion."
    end

    args = type(args) == "table" and args or {}
    args.state = order
    local changed = DTNPCServerCore.IssueOrderByUUID(uuid, player, args)
    return changed == true, uuid
end

function Companion.BeginWorkerCompanionReturn(player, worker, reason)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    debugCompanion(
        "BeginWorkerCompanionReturn workerID=" .. tostring(worker.workerID)
            .. " uuid=" .. tostring(getCompanionUUID(worker))
            .. " reason=" .. tostring(reason)
            .. " presenceState=" .. tostring(worker.presenceState)
    )

    local companionData = getCompanionData(worker)
    local uuid = getCompanionUUID(worker)
    local travelHours = getTravelHours()
    local currentHour = getCurrentWorldHours()
    companionData.returnReason = reason or Config.ReturnReasons.Manual
    companionData.returnTravelHours = travelHours
    companionData.commandInvalidSinceMs = nil
    worker.returnReason = companionData.returnReason

    if worker.presenceState == Config.PresenceStates.CompanionActive and uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
        companionData.stage = TRAVEL_STAGE_DEPARTING
        companionData.awaitingDespawn = true
        worker.state = Config.States.Working
        local npcData = getSoul(uuid)
        if npcData then
            setSoulCompanionFlags(worker, npcData, false)
            saveSoul(uuid, npcData)
        end
        DTNPCServerCore.IssueOrderByUUID(uuid, player or { ownerUsername = worker.ownerUsername }, {
            state = "Stay",
            returnStatus = "Resting",
            startDeparture = true,
            systemCompanionOrder = true,
        })
        appendLog(worker, "Leaving your position and heading home.", currentHour, "travel")
        return true
    end

    if worker.presenceState == Config.PresenceStates.Home then
        worker.jobEnabled = false
        worker.returnReason = nil
        companionData.stage = nil
        companionData.awaitingDespawn = false
        companionData.commanderUsername = nil
        companionData.commanderOnlineID = nil
        companionData.commandInvalidSinceMs = nil
        return true
    end

    worker.presenceState = Config.PresenceStates.CompanionReturning
    worker.travelHoursRemaining = travelHours
    worker.jobEnabled = false
    companionData.stage = TRAVEL_STAGE_RETURNING
    companionData.awaitingDespawn = false
    appendLog(worker, "Heading home from your location.", currentHour, "travel")
    return true
end

function Companion.MarkCompanionActive(worker)
    if not worker then
        return
    end

    local companionData = getCompanionData(worker)
    companionData.stage = TRAVEL_STAGE_ACTIVE
    companionData.awaitingDespawn = false
    companionData.homeRecoveryLogged = false
    worker.presenceState = Config.PresenceStates.CompanionActive
    worker.travelHoursRemaining = 0
    worker.state = Config.States.Working

    local uuid = getCompanionUUID(worker)
    local npcData = uuid and getSoul(uuid) or nil
    if npcData then
        setSoulCompanionFlags(worker, npcData, true)
        saveSoul(uuid, npcData)
    end
end

function Companion.OnSoulStatusChanged(uuid, status, npcData)
    if not uuid or not status then
        return
    end

    debugCompanion(
        "OnSoulStatusChanged uuid=" .. tostring(uuid)
            .. " status=" .. tostring(status)
            .. " linkedWorkerID=" .. tostring(npcData and npcData.linkedWorkerID)
    )

    local linkedWorkerID = npcData and npcData.linkedWorkerID or nil
    local registry = getRegistry()
    local worker = linkedWorkerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(linkedWorkerID) or nil
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return
    end

    local companionData = getCompanionData(worker)
    if tostring(status) == "Dead" then
        worker.state = Config.States.Dead
        worker.jobEnabled = false
        worker.hp = 0
        worker.presenceState = Config.PresenceStates.Home
        worker.travelHoursRemaining = 0
        companionData.stage = nil
        companionData.awaitingDespawn = false
        appendLog(worker, "Died while away on companion duty.", getCurrentWorldHours(), "death")
        saveRegistry()
        return
    end

    if tostring(status) == "Away"
        and (companionData.awaitingDespawn == true
            or worker.presenceState == Config.PresenceStates.CompanionActive
            or worker.presenceState == Config.PresenceStates.CompanionToPlayer) then
        worker.jobEnabled = false
        worker.presenceState = Config.PresenceStates.CompanionReturning
        worker.travelHoursRemaining = math.max(0, tonumber(companionData.returnTravelHours) or getTravelHours())
        worker.returnReason = worker.returnReason or companionData.returnReason or Config.ReturnReasons.Manual
        worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
        companionData.stage = TRAVEL_STAGE_RETURNING
        companionData.awaitingDespawn = false
        saveRegistry()
    end
end

function Companion.SyncWorkerHealthFromNPC(workerID, npcData)
    local registry = getRegistry()
    local worker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker then
        return false
    end

    local current = tonumber(npcData and npcData.combatHealth and npcData.combatHealth.current)
        or tonumber(npcData and npcData.health)
        or nil
    local maxHp = tonumber(npcData and npcData.combatHealth and npcData.combatHealth.max)
        or tonumber(worker.maxHp)
        or tonumber(Config.DEFAULT_WORKER_MAX_HP)
        or 100

    if maxHp and maxHp > 0 then
        worker.maxHp = math.max(1, math.floor(maxHp + 0.5))
    end
    if current ~= nil then
        worker.hp = math.max(0, math.min(worker.maxHp, current))
    end
    saveRegistry()
    return true
end

function Companion.HandleIncapacitatedNPC(npcData)
    local workerID = npcData and npcData.linkedWorkerID or nil
    local registry = getRegistry()
    local worker = workerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    Companion.SyncWorkerHealthFromNPC(worker.workerID, npcData)
    worker.state = Config.States.Incapacitated
    worker.jobEnabled = false
    local companionData = getCompanionData(worker)
    companionData.awaitingDespawn = false
    companionData.stage = TRAVEL_STAGE_RETURNING
    companionData.homeRecoveryLogged = false
    worker.presenceState = Config.PresenceStates.CompanionReturning
    worker.travelHoursRemaining = getTravelHours()
    worker.returnReason = Config.ReturnReasons.LowEnergy
    appendLog(worker, "Was incapacitated and is being brought home to recover.", getCurrentWorldHours(), "medical")
    saveRegistry()
    return true
end

function Companion.ResolveBandageSupply(worker)
    if not worker then
        return nil
    end

    for index, entry in ipairs(worker.nutritionLedger or {}) do
        local isMedical = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) or false
        local useKind = tostring(entry and entry.medicalUse or "")
        local units = math.max(0, tonumber(entry and entry.treatmentUnitsRemaining) or 0)
        if isMedical and units > 0 and (useKind == "bandage" or useKind == "") then
            local tierID, dirtyFullType = getMedicalBandageTier(entry.fullType)
            return {
                index = index,
                entry = entry,
                tierID = tierID,
                dirtyFullType = dirtyFullType,
            }
        end
    end

    return nil
end

function Companion.ConsumeBandageSupply(workerID)
    local registry = getRegistry()
    local worker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker then
        return nil
    end

    local supply = Companion.ResolveBandageSupply(worker)
    if not supply then
        return nil
    end

    local entry = supply.entry
    entry.treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0) - 1
    if entry.treatmentUnitsRemaining <= 0 then
        removeNutritionEntry(worker, supply.index)
    else
        worker.nutritionCacheDirty = true
    end

    addDirtyMedicalOutput(worker, supply.dirtyFullType)
    return {
        tierID = supply.tierID,
        fullType = entry and entry.fullType or nil,
        dirtyFullType = supply.dirtyFullType,
    }
end

function Companion.RecordCombatAttack(workerID, npcData, attackType, options)
    local registry = getRegistry()
    local worker = workerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    local skillID = getCompanionCombatSkillID(attackType)
    if not skillID then
        return false
    end

    local energy = DC_Colony and DC_Colony.Energy or nil
    local beforeEnergy = energy and energy.GetCurrent and energy.GetCurrent(worker) or nil
    local drainAmount, _, skillLevel, drainMultiplier = getCompanionCombatDrainPerAttack(worker, attackType)
    local energyApplied = false
    if energy and energy.SetCurrent and beforeEnergy ~= nil and drainAmount > 0 then
        energy.SetCurrent(worker, beforeEnergy - drainAmount)
        energyApplied = true
    end

    local skills = getSkillsModule()
    local xpAmount = Config.GetCompanionCombatXPPerAttack and Config.GetCompanionCombatXPPerAttack(attackType, worker) or 1
    local xpResult = nil
    if skills and skills.EnsureWorkerSkills then
        skills.EnsureWorkerSkills(worker)
    end
    if skills and skills.GrantXP and xpAmount > 0 then
        xpResult = skills.GrantXP(worker, skillID, xpAmount)
    end

    if registry and registry.RecalculateWorker then
        registry.RecalculateWorker(worker)
    end

    local xpGranted = tonumber(xpResult and xpResult.granted) or 0
    local leveledUp = tonumber(xpResult and xpResult.leveledUp) or 0
    if energyApplied or xpGranted > 0 then
        local companionData = getCompanionData(worker)
        local currentMs = getCurrentMillis()
        local lastSavedAt = tonumber(companionData and companionData.combatProgressSavedAt) or 0
        local shouldSaveNow = leveledUp > 0
            or currentMs <= 0
            or lastSavedAt <= 0
            or (currentMs - lastSavedAt) >= 4000

        if shouldSaveNow then
            if companionData then
                companionData.combatProgressSavedAt = currentMs
            end
            saveRegistry()
        end
    end

    if energy and energy.IsDepleted and energy.IsDepleted(worker) then
        local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
        if energy.BeginForcedRest then
            energy.BeginForcedRest(worker, getCurrentWorldHours(), lowEnergyReason, "Too tired for companion duty. Returning home to rest.")
        end
        Companion.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
    end

    return true, {
        attackType = attackType,
        skillID = skillID,
        skillLevel = skillLevel,
        drainApplied = drainAmount,
        drainMultiplier = drainMultiplier,
        xpResult = xpResult,
    }
end

function Companion.UpdateTravelCompanionWorker(worker, ctx)
    if not worker or not Companion.IsTravelCompanionWorker(worker) then
        return false
    end

    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or getCurrentWorldHours()
    local forcedRest = ctx and ctx.forcedRest == true or false
    local hasCalories = ctx and ctx.hasCalories ~= false
    local hasHydration = ctx and ctx.hasHydration ~= false
    local energy = DC_Colony and DC_Colony.Energy or nil
    local health = getHealth()
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local presenceState = tostring(worker.presenceState or "")
    local companionData = getCompanionData(worker)
    local hpCurrent = health and health.GetCurrent and health.GetCurrent(worker) or math.max(0, tonumber(worker.hp) or 0)
    local hpMax = health and health.GetMax and health.GetMax(worker) or math.max(1, tonumber(worker.maxHp) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100)

    if presenceState == Config.PresenceStates.Home then
        if energy and deltaHours > 0 and hpCurrent > 0 and energy.ApplyHomeRecovery then
            energy.ApplyHomeRecovery(worker, deltaHours, profile)
            if energy.IsForcedRest and energy.IsForcedRest(worker) and energy.CompleteForcedRest then
                energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            end
            forcedRest = energy.IsForcedRest and energy.IsForcedRest(worker) or forcedRest
        end

        local isIncapacitated = tostring(worker.state or "") == tostring(Config.States.Incapacitated)
        local needsRecovery = isIncapacitated or (hpCurrent + 0.0001) < hpMax

        if isIncapacitated and (hpCurrent + 0.0001) >= hpMax then
            worker.state = forcedRest and Config.States.Resting or Config.States.Idle
            companionData.homeRecoveryLogged = false
            appendLog(worker, "Recovered from incapacitation and is back on their feet.", currentHour, "medical")
            return true
        end

        if needsRecovery then
            if companionData.homeRecoveryLogged ~= true then
                local message = isIncapacitated
                    and "Reached home and is now resting to recover from incapacitation."
                    or "Is resting at home to recover from injuries."
                appendLog(worker, message, currentHour, "medical")
                companionData.homeRecoveryLogged = true
            end

            if not isIncapacitated then
                worker.state = Config.States.Resting
            end
            return true
        end

        companionData.homeRecoveryLogged = false
        if worker.state ~= Config.States.Dead then
            worker.state = forcedRest and Config.States.Resting or Config.States.Idle
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionToPlayer then
        Companion.RefreshCompanionCommanderValidity(worker)
        if tostring(worker.presenceState or "") ~= presenceState then
            return true
        end
        if not worker.jobEnabled then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
            return true
        end
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if deltaHours > 0 then
            worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
        end
        if energy and deltaHours > 0 then
            energy.ApplyTravelDrain(worker, deltaHours, profile)
        end
        if energy and energy.IsDepleted and energy.IsDepleted(worker) then
            local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
            if energy.BeginForcedRest then
                energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to reach your position. Returning home to rest.")
            end
            Companion.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
            return true
        end
        if worker.travelHoursRemaining <= 0 then
            Companion.MarkCompanionActive(worker)
            appendLog(worker, "Reached your location and is now traveling with you.", currentHour, "travel")
        else
            worker.state = Config.States.Working
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionReturning then
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if deltaHours > 0 then
            worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
        end
        if energy and deltaHours > 0 then
            energy.ApplyTravelDrain(worker, deltaHours, profile)
        end
        if worker.travelHoursRemaining <= 0 then
            finalizeReturnTravel(worker, currentHour)
        else
            worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionActive then
        Companion.RefreshCompanionCommanderValidity(worker)
        if tostring(worker.presenceState or "") ~= presenceState then
            return true
        end
        if companionData.awaitingDespawn == true then
            worker.state = Config.States.Working
            return true
        end

        if energy and deltaHours > 0 then
            energy.ApplyWorkDrain(worker, deltaHours, profile)
        end

        if not worker.jobEnabled then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        elseif not hasHydration then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowDrink)
        elseif not hasCalories then
            Companion.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowFood)
        elseif forcedRest or (energy and energy.IsDepleted and energy.IsDepleted(worker)) then
            local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
            if energy and energy.BeginForcedRest then
                energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired for companion duty. Returning home to rest.")
            end
            Companion.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
        else
            worker.state = Config.States.Working
            companionData.stage = TRAVEL_STAGE_ACTIVE
        end
        return true
    end

    return false
end

return Companion
