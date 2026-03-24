DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
local Config = Buildings.Config

local function getOwnerUsername(ownerUsername)
    local colonyConfig = DC_Colony and DC_Colony.Config or nil
    return colonyConfig and colonyConfig.GetOwnerUsername and colonyConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function sortPlotsByPosition(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

local function getCardinalDirections()
    local frontierConfig = Config and Config.Frontier or nil
    return frontierConfig and frontierConfig.CARDINAL_DIRECTIONS or {
        { x = -1, y = 0 },
        { x = 1, y = 0 },
        { x = 0, y = -1 },
        { x = 0, y = 1 }
    }
end

function Buildings.GetUnlockedPlotEntries(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(owner)
    local plots = {}

    for _, plot in pairs(mapData and mapData.plots or {}) do
        if plot and plot.unlocked == true then
            plots[#plots + 1] = Buildings.BuildVirtualPlot(plot.x, plot.y, true, plot.kind)
        end
    end

    sortPlotsByPosition(plots)
    return plots
end

function Buildings.GetHeadquartersLevel(ownerUsername)
    local headquarters = Buildings.GetHeadquartersInstance and Buildings.GetHeadquartersInstance(ownerUsername) or nil
    return math.max(0, math.floor(tonumber(headquarters and headquarters.level) or 0))
end

function Buildings.GetMaxActiveBarricades(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local frontierConfig = Config and Config.Frontier or nil
    local headquartersLevel = Buildings.GetHeadquartersLevel(owner)
    return frontierConfig and frontierConfig.GetMaxActiveBarricades and frontierConfig.GetMaxActiveBarricades(headquartersLevel) or 0
end

function Buildings.GetActiveBarricadeCount(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local count = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            count = count + 1
        end
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner) or {}) do
        if tostring(project and project.status or "") == "Active"
            and tostring(project and project.buildingType or "") == "Barricade" then
            count = count + 1
        end
    end

    return count
end

function Buildings.IsFrontierPlot(ownerUsername, plotX, plotY)
    local owner = getOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local plot, state, building, project = Buildings.GetPlotWithState(owner, x, y)

    if not plot or tostring(plot.kind or "") ~= tostring(Buildings.MapConstants.PlotKinds.Standard) then
        return false
    end
    if tostring(state or "") ~= tostring(Buildings.MapConstants.PlotStates.Locked) then
        return false
    end
    if building or project then
        return false
    end

    for _, direction in ipairs(getCardinalDirections()) do
        local neighbor = Buildings.GetStoredPlotForOwner(owner, x + direction.x, y + direction.y)
        if neighbor and neighbor.unlocked == true then
            return true
        end
    end

    return false
end

function Buildings.GetFrontierCandidatePlots(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local candidates = {}
    local seen = {}

    for _, plot in ipairs(Buildings.GetUnlockedPlotEntries(owner)) do
        for _, direction in ipairs(getCardinalDirections()) do
            local nextX = math.floor(tonumber(plot.x) or 0) + direction.x
            local nextY = math.floor(tonumber(plot.y) or 0) + direction.y
            local key = Buildings.GetPlotKey(nextX, nextY)
            if not seen[key] and Buildings.IsFrontierPlot(owner, nextX, nextY) then
                seen[key] = true
                local candidate = Buildings.BuildVisiblePlot(owner, nextX, nextY)
                candidate.frontierCandidate = true
                candidates[#candidates + 1] = candidate
            end
        end
    end

    sortPlotsByPosition(candidates)
    return candidates
end

function Buildings.GetTerritorySummary(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local unlockedPlots = Buildings.GetUnlockedPlotEntries(owner)
    local headquartersLevel = Buildings.GetHeadquartersLevel(owner)
    local activeBarricades = Buildings.GetActiveBarricadeCount(owner)
    local maxBarricades = Buildings.GetMaxActiveBarricades(owner)

    return {
        ownerUsername = owner,
        headquartersLevel = headquartersLevel,
        unlockedPlotCount = #unlockedPlots,
        activeBarricadeCount = activeBarricades,
        maxActiveBarricades = maxBarricades
    }
end

function Buildings.BuildVisibleBounds(plots)
    local bounds = {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0
    }
    local seeded = false

    for _, plot in ipairs(plots or {}) do
        local x = math.floor(tonumber(plot and plot.x) or 0)
        local y = math.floor(tonumber(plot and plot.y) or 0)
        if not seeded then
            bounds.minX = x
            bounds.maxX = x
            bounds.minY = y
            bounds.maxY = y
            seeded = true
        else
            bounds.minX = math.min(bounds.minX, x)
            bounds.maxX = math.max(bounds.maxX, x)
            bounds.minY = math.min(bounds.minY, y)
            bounds.maxY = math.max(bounds.maxY, y)
        end
    end

    return bounds
end

return Buildings
