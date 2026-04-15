require "ISUI/ISScrollingListBox"

DC_ResourceCategoryList = ISScrollingListBox:derive("DC_ResourceCategoryList")

function DC_ResourceCategoryList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 40
    o.selected = 1
    o.drawBorder = true
    o.font = UIFont.Small
    return o
end

function DC_ResourceCategoryList:doDrawItem(y, item, alt)
    local category = item and item.item or nil
    if not category then
        return y + self.itemheight
    end

    local win = self.target
    local barData = win and win.getCategoryBarData and win:getCategoryBarData(category) or nil
    local displayName = tostring(category.displayName or category.id or "Resource")
    local statusText = tostring(category.status or "")
    local ratio = math.max(0, math.min(1, tonumber(barData and barData.ratio) or 0))
    local metricText = tostring(barData and barData.metricText or "0 / 0")
    local color = barData and barData.color or { r = 0.62, g = 0.62, b = 0.62 }

    if item.selected then
        self:drawRect(0, y, self.width, self.itemheight, 0.32, 0.22, 0.24, 0.28)
        self:drawRect(0, y, 4, self.itemheight, 0.95, color.r, color.g, color.b)
    elseif alt then
        self:drawRect(0, y, self.width, self.itemheight, 0.06, 1, 1, 1)
    else
        self:drawRect(0, y, self.width, self.itemheight, 0.06, 0, 0, 0)
    end

    self:drawText(displayName, 10, y + 3, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawTextRight(statusText, self.width - 8, y + 3, 0.72, 0.72, 0.72, 1, UIFont.Small)

    local barX = 10
    local barY = y + 18
    local barWidth = self.width - 20
    local barHeight = 16
    local fillWidth = math.floor((barWidth - 4) * ratio)

    self:drawRect(barX, barY, barWidth, barHeight, 0.35, 0.10, 0.10, 0.10)
    self:drawRectBorder(barX, barY, barWidth, barHeight, 0.2, 1, 1, 1)
    if fillWidth > 0 then
        self:drawRect(barX + 2, barY + 2, fillWidth, barHeight - 4, 0.9, color.r, color.g, color.b)
    end

    local metricWidth = getTextManager():MeasureStringX(UIFont.Small, metricText)
    self:drawText(metricText, barX + math.max(6, math.floor((barWidth - metricWidth) / 2)), barY + 1, 0.94, 0.94, 0.94, 1, UIFont.Small)

    if item.selected then
        self:drawRectBorder(0, y, self.width, self.itemheight, 0.28, 0.98, 0.86, 0.4)
    else
        self:drawRectBorder(0, y, self.width, self.itemheight, 0.08, 1, 1, 1)
    end

    return y + self.itemheight
end

return DC_ResourceCategoryList
