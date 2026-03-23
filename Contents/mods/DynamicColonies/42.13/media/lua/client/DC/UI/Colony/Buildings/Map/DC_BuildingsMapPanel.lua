require "ISUI/ISPanel"
require "DC/UI/Colony/Buildings/Map/DC_BuildingsMapLayout"
require "DC/UI/Colony/Buildings/Map/DC_BuildingsPlotButton"

DC_BuildingsMapPanel = ISPanel:derive("DC_BuildingsMapPanel")

function DC_BuildingsMapPanel:initialise()
    ISPanel.initialise(self)
end

function DC_BuildingsMapPanel:clearButtons()
    for _, button in ipairs(self.plotButtons or {}) do
        self:removeChild(button)
    end
    self.plotButtons = {}
end

function DC_BuildingsMapPanel:setSnapshot(snapshot, selectedPlotKey)
    self.snapshot = snapshot
    self.selectedPlotKey = selectedPlotKey
    self:rebuildButtons()
end

function DC_BuildingsMapPanel:onPlotButtonClicked(button)
    if self.onPlotSelectedCallback then
        self.onPlotSelectedCallback(button.plot)
    end
end

function DC_BuildingsMapPanel:rebuildButtons()
    self:clearButtons()
    local map = self.snapshot and self.snapshot.map or {}
    local plots = map.plots or {}
    local layout = DC_BuildingsMapLayout.Calculate(self.width, self.height, map.bounds)

    for _, plot in ipairs(plots) do
        local col = (math.floor(tonumber(plot.x) or 0) - layout.minX)
        local row = (math.floor(tonumber(plot.y) or 0) - layout.minY)
        local x = layout.offsetX + (col * (layout.cell + layout.gap))
        local y = layout.offsetY + (row * (layout.cell + layout.gap))
        local button = DC_BuildingsPlotButton:new(x, y, layout.cell, layout.cell, "", self, self.onPlotButtonClicked)
        button:initialise()
        button:applyPlot(plot, tostring(plot.key or "") == tostring(self.selectedPlotKey or ""))
        self:addChild(button)
        self.plotButtons[#self.plotButtons + 1] = button
    end
end

function DC_BuildingsMapPanel:prerender()
    ISPanel.prerender(self)
    self:drawText("Settlement Map", 10, 8, 1, 1, 1, 1, UIFont.Medium)
end

function DC_BuildingsMapPanel:new(x, y, width, height, onPlotSelectedCallback)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.plotButtons = {}
    o.onPlotSelectedCallback = onPlotSelectedCallback
    return o
end

return DC_BuildingsMapPanel
