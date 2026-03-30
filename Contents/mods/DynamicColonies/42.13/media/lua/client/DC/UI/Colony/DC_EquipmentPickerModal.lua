require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"

local SOURCE_OPTIONS = {
    { label = "All Sources", filterID = "all" },
    { label = "Player Inventory", filterID = "player" },
    { label = "Warehouse Storage", filterID = "warehouse" },
}

local function findSourceOptionIndex(filterID)
    local target = tostring(filterID or "all")
    for index, option in ipairs(SOURCE_OPTIONS) do
        if tostring(option.filterID or "") == target then
            return index
        end
    end
    return 1
end

local function getSourceFilterIDByIndex(index)
    local option = SOURCE_OPTIONS[math.max(1, math.floor(tonumber(index) or 1))] or SOURCE_OPTIONS[1]
    return tostring(option and option.filterID or "all")
end

local EquipmentPickerList = ISScrollingListBox:derive("DC_EquipmentPickerModal_List")

function EquipmentPickerList:doDrawItem(y, item, alt)
    local candidate = item and item.item or nil
    if not candidate then
        return y + self.itemheight
    end

    local width = self:getWidth()
    local isSelected = self.selected == item.index
    if isSelected then
        self:drawRect(0, y, width, self.itemheight, 0.25, 0.18, 0.38, 0.62)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.06, 1, 1, 1)
    end

    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)

    if candidate.texture then
        self:drawTextureScaled(candidate.texture, 8, y + 9, 28, 28, 1, 1, 1, 1)
    end

    local textX = 44
    local sourceLabel = tostring(candidate.sourceLabel or candidate.source or "")
    local badgeR, badgeG, badgeB = 0.72, 0.72, 0.72
    if sourceLabel == "Player" then
        badgeR, badgeG, badgeB = 0.54, 0.88, 0.72
    elseif sourceLabel == "Warehouse" then
        badgeR, badgeG, badgeB = 0.56, 0.8, 0.98
    end

    self:drawText(tostring(candidate.displayName or candidate.fullType or "Item"), textX, y + 6, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawTextRight(sourceLabel, width - 12, y + 6, badgeR, badgeG, badgeB, 1, UIFont.Small)

    local statText = tostring(candidate.statText or "")
    if statText ~= "" then
        self:drawText(statText, textX, y + 24, 0.66, 0.8, 0.95, 1, UIFont.Small)
    end

    return y + self.itemheight
end

function EquipmentPickerList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 48
    o.font = UIFont.Small
    return o
end

function EquipmentPickerList:onMouseDown(x, y)
    local result = ISScrollingListBox.onMouseDown(self, x, y)
    if self.target and self.target.updateConfirmState then
        self.target:updateConfirmState()
    end
    return result
end

DC_EquipmentPickerModal = ISCollapsableWindow:derive("DC_EquipmentPickerModal")
DC_EquipmentPickerModal.instance = DC_EquipmentPickerModal.instance or nil

function DC_EquipmentPickerModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_EquipmentPickerModal:getSelectedCandidate()
    local row = self.list and self.list.selected or -1
    local item = row and row > 0 and self.list.items[row] or nil
    return item and item.item or nil
end

function DC_EquipmentPickerModal:refreshVisibleCandidates()
    if not self.list then
        return
    end

    local selectedCandidate = self:getSelectedCandidate()
    local selectedKey = selectedCandidate and tostring(selectedCandidate.source or "") .. "|" .. tostring(selectedCandidate.itemID or selectedCandidate.ledgerIndex or selectedCandidate.fullType or "")
        or nil

    self.list:clear()
    for _, candidate in ipairs(self.candidates or {}) do
        local source = tostring(candidate.source or "")
        if self.sourceFilter == "all" or self.sourceFilter == source then
            self.list:addItem(candidate.displayName or candidate.fullType or "Item", candidate)
        end
    end

    if selectedKey then
        for index, row in ipairs(self.list.items) do
            local candidate = row and row.item or nil
            local rowKey = tostring(candidate and candidate.source or "") .. "|" .. tostring(candidate and (candidate.itemID or candidate.ledgerIndex or candidate.fullType) or "")
            if rowKey == selectedKey then
                self.list.selected = index
                break
            end
        end
    end

    if self.list.selected == -1 and #self.list.items > 0 then
        self.list.selected = 1
    end

    self:updateConfirmState()
end

function DC_EquipmentPickerModal:updateConfirmState()
    if self.btnConfirm then
        self.btnConfirm:setEnable(self:getSelectedCandidate() ~= nil)
    end
end

function DC_EquipmentPickerModal:setSourceFilter(filterID)
    self.sourceFilter = filterID or "all"
    if self.sourceCombo then
        local selectedIndex = findSourceOptionIndex(self.sourceFilter)
        if self.sourceCombo.selected ~= selectedIndex then
            self.sourceCombo.selected = selectedIndex
        end
    end
    self:refreshVisibleCandidates()
end

function DC_EquipmentPickerModal:applyArgs(args)
    args = args or {}
    self.title = tostring(args.title or "Choose Equipment")
    self.promptText = tostring(args.promptText or "Choose an equipment source.")
    self.confirmLabel = tostring(args.confirmLabel or "Confirm")
    self.candidates = args.candidates or {}
    self.sourceFilter = tostring(args.sourceFilter or "all")
    self.onConfirmCallback = args.onConfirm

    if self.promptLabel then
        self.promptLabel:setName(self.promptText)
    end
    if self.btnConfirm then
        self.btnConfirm:setTitle(self.confirmLabel)
    end

    self:setSourceFilter(self.sourceFilter)
end

function DC_EquipmentPickerModal:onSourceFilterChanged()
    if not self.sourceCombo then
        return
    end
    self:setSourceFilter(getSourceFilterIDByIndex(self.sourceCombo.selected))
end

function DC_EquipmentPickerModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    if self.promptLabel then
        return
    end

    local th = self:titleBarHeight()

    self.promptLabel = ISLabel:new(10, th + 14, 20, tostring(self.promptText or "Choose an equipment source."), 0.82, 0.82, 0.82, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    local filterY = th + 42
    self.sourceCombo = ISComboBox:new(10, filterY, 196, 24, self, self.onSourceFilterChanged)
    self.sourceCombo:initialise()
    self.sourceCombo:instantiate()
    for _, option in ipairs(SOURCE_OPTIONS) do
        self.sourceCombo:addOption(option.label)
    end
    self:addChild(self.sourceCombo)

    self.list = EquipmentPickerList:new(10, th + 76, self.width - 20, self.height - th - 120)
    self.list:initialise()
    self.list:instantiate()
    self.list.target = self
    self:addChild(self.list)

    self.btnConfirm = ISButton:new(10, self.height - 34, 92, 24, tostring(self.confirmLabel or "Confirm"), self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 102, self.height - 34, 92, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)

    self:applyArgs({
        title = self.title,
        promptText = self.promptText,
        confirmLabel = self.confirmLabel,
        candidates = self.candidates,
        sourceFilter = self.sourceFilter,
        onConfirm = self.onConfirmCallback,
    })
end

function DC_EquipmentPickerModal:onConfirmClicked()
    local candidate = self:getSelectedCandidate()
    if candidate and self.onConfirmCallback then
        self.onConfirmCallback(candidate)
    end
    self:close()
end

function DC_EquipmentPickerModal:onCancelClicked()
    self:close()
end

function DC_EquipmentPickerModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_EquipmentPickerModal.Preload()
    local modal = DC_EquipmentPickerModal.instance
    if modal then
        return modal
    end

    local width = 640
    local height = 520
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    modal = DC_EquipmentPickerModal:new(x, y, width, height)
    modal:initialise()
    modal:instantiate()
    modal:setVisible(false)
    DC_EquipmentPickerModal.instance = modal
    return modal
end

function DC_EquipmentPickerModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Choose Equipment"
    o.resizable = false
    o.promptText = "Choose an equipment source."
    o.confirmLabel = "Confirm"
    o.candidates = {}
    o.sourceFilter = "all"
    o.onConfirmCallback = nil
    return o
end

function DC_EquipmentPickerModal.Open(args)
    local modal = DC_EquipmentPickerModal.Preload()
    modal:applyArgs(args)
    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()
    return modal
end

return DC_EquipmentPickerModal
