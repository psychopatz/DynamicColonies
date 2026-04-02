DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
Internal.ReservePanel = Internal.ReservePanel or {}
local ReservePanel = Internal.ReservePanel

function ReservePanel.buildWorkerProgressData(worker, profile)
    if ReservePanel.isFunction(Internal.getWorkerProgressData) then
        return Internal.getWorkerProgressData(worker, profile)
    end

    local interaction = DC_Colony and DC_Colony.Interaction or nil
    if not interaction or not ReservePanel.isFunction(interaction.GetProgressDescriptor) then
        return nil
    end

    local data = interaction.GetProgressDescriptor(worker, profile)
    if not data then
        return nil
    end

    data.stored = tonumber(data.progressAmount) or tonumber(data.progressHours) or 0
    data.usage = tonumber(data.workTarget) or tonumber(data.cycleHours) or 0
    data.overflow = 0
    data.daysLeft = nil
    return data
end

function ReservePanel.getWorkerPortraitTexture(worker)
    if ReservePanel.isFunction(Internal.getWorkerPortraitTexture) then
        return Internal.getWorkerPortraitTexture(worker)
    end
    if not worker then
        return nil
    end

    local archetype = tostring(worker.archetypeID or "General")
    local gender = worker.isFemale and "Female" or "Male"
    local seed = tonumber(worker.identitySeed) or 1
    local portraitID = 1
    local pathFolder = "media/ui/Portraits/" .. archetype .. "/" .. gender .. "/"

    if DynamicTrading and DynamicTrading.Portraits then
        if ReservePanel.isFunction(DynamicTrading.Portraits.GetMappedID) then
            portraitID = DynamicTrading.Portraits.GetMappedID(archetype, gender, seed)
        end
        if ReservePanel.isFunction(DynamicTrading.Portraits.GetPathFolder) then
            pathFolder = DynamicTrading.Portraits.GetPathFolder(archetype, gender)
        end
    end

    return getTexture(pathFolder .. tostring(portraitID) .. ".png")
        or getTexture("media/ui/Portraits/General/" .. gender .. "/1.png")
end
