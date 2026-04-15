require "ISUI/ISPanel"
require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"
require "DC/UI/Colony/Buildings/Map/Render/DC_BuildingsMapRenderer"

DC_BuildingsMapPanel = ISPanel:derive("DC_BuildingsMapPanel")

function DC_BuildingsMapPanel:initialise()
    ISPanel.initialise(self)
end

function DC_BuildingsMapPanel:setSnapshot(snapshot, selectedPlotKey)
    self.snapshot = snapshot
    self.selectedPlotKey = selectedPlotKey
    self.viewportState = DC_BuildingsMapViewport.EnsureState(self.viewportState, snapshot)
end

function DC_BuildingsMapPanel:prerender()
    ISPanel.prerender(self)
    DC_BuildingsMapRenderer.Draw(self, self.snapshot or { map = { plots = {} } }, self.viewportState or {}, self.selectedPlotKey)
end

function DC_BuildingsMapPanel:onMouseDown(x, y)
    self.dragActive = true
    self.dragMoved = false
    self.dragDistance = 0
    return true
end

function DC_BuildingsMapPanel:onMouseMove(dx, dy)
    if not self.dragActive then
        return false
    end

    self.dragDistance = (tonumber(self.dragDistance) or 0) + math.abs(tonumber(dx) or 0) + math.abs(tonumber(dy) or 0)
    if self.dragDistance > 6 then
        self.dragMoved = true
    end

    if self.dragMoved then
        self.viewportState = DC_BuildingsMapViewport.PanByPixels(self.viewportState or {}, self.snapshot, dx, dy)
    end
    return true
end

function DC_BuildingsMapPanel:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function DC_BuildingsMapPanel:onMouseUp(x, y)
    local shouldSelect = self.dragActive == true and self.dragMoved ~= true
    self.dragActive = false

    if shouldSelect and self.onPlotSelectedCallback then
        local plot = DC_BuildingsMapViewport.PickPlot(self.snapshot or { map = { plots = {} } }, self.viewportState or {}, self.width, self.height, x, y)
        if plot then
            self.onPlotSelectedCallback(plot)
        end
    end
    return true
end

function DC_BuildingsMapPanel:onMouseUpOutside(x, y)
    self.dragActive = false
    return true
end

function DC_BuildingsMapPanel:new(x, y, width, height, onPlotSelectedCallback)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.snapshot = { map = { plots = {} } }
    o.viewportState = {
        tileSize = DC_BuildingsMapViewport.DEFAULT_TILE_SIZE,
        gap = DC_BuildingsMapViewport.DEFAULT_GAP
    }
    o.onPlotSelectedCallback = onPlotSelectedCallback
    return o
end

return DC_BuildingsMapPanel
