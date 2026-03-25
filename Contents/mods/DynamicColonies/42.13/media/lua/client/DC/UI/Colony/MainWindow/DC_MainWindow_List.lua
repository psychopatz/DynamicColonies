require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local ColonyWorkerList = ISScrollingListBox:derive("ColonyWorkerList")

local function formatWorkerListSubtitle(worker)
    if type(Internal.formatWorkerListSubtitle) == "function" then
        return Internal.formatWorkerListSubtitle(worker)
    end
    return tostring(worker and worker.state or "Idle")
        .. " | "
        .. tostring(worker and worker.jobType or "Unassigned")
        .. " | "
        .. tostring(worker and worker.presenceState or "Home")
end

local function getSelectedWorkerID(list)
    local target = list and list.target or nil
    if target and target.selectedWorkerSummary and target.selectedWorkerSummary.workerID then
        return tostring(target.selectedWorkerSummary.workerID)
    end
    if target and target.selectedWorker and target.selectedWorker.workerID then
        return tostring(target.selectedWorker.workerID)
    end
    return nil
end

local function drawSubtitleLine(list, x, y, worker)
    local stateLabel = type(Internal.getNpcConditionLabel) == "function"
        and Internal.getNpcConditionLabel(worker)
        or tostring(worker and worker.state or "Idle")
    local jobLabel = type(Internal.getJobDisplayName) == "function"
        and Internal.getJobDisplayName(worker)
        or tostring(worker and worker.jobType or "Unknown")
    local presenceLabel = type(Internal.getWorkerPresenceLabel) == "function"
        and Internal.getWorkerPresenceLabel(worker)
        or tostring(worker and worker.presenceState or "Home")
    local jobColor = type(Internal.getWorkerJobColor) == "function"
        and Internal.getWorkerJobColor(worker)
        or { r = 0.82, g = 0.82, b = 0.82, a = 1 }
    local font = UIFont.Small
    local tm = getTextManager()
    local separator = " | "
    local muted = { r = 0.72, g = 0.72, b = 0.72, a = 0.95 }
    local cursorX = x

    list:drawText(stateLabel, cursorX, y, muted.r, muted.g, muted.b, muted.a, font)
    cursorX = cursorX + tm:MeasureStringX(font, stateLabel)
    list:drawText(separator, cursorX, y, muted.r, muted.g, muted.b, muted.a, font)
    cursorX = cursorX + tm:MeasureStringX(font, separator)
    list:drawText(jobLabel, cursorX, y, jobColor.r, jobColor.g, jobColor.b, jobColor.a, font)
    cursorX = cursorX + tm:MeasureStringX(font, jobLabel)
    list:drawText(separator, cursorX, y, muted.r, muted.g, muted.b, muted.a, font)
    cursorX = cursorX + tm:MeasureStringX(font, separator)
    list:drawText(presenceLabel, cursorX, y, muted.r, muted.g, muted.b, muted.a, font)
end

function ColonyWorkerList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 60
    o.selected = 1
    o.drawBorder = true
    o.font = UIFont.Medium
    return o
end

function ColonyWorkerList:doDrawItem(y, item, alt)
    local worker = item.item
    if not worker then
        return y + self.itemheight
    end

    local selectedWorkerID = getSelectedWorkerID(self)
    local isSelected = item.selected or (selectedWorkerID ~= nil and tostring(worker.workerID or "") == selectedWorkerID)

    if isSelected then
        self:drawRect(0, y, self.width, self.itemheight, 0.32, 0.22, 0.24, 0.28)
        self:drawRect(0, y, 5, self.itemheight, 0.95, 0.82, 0.32, 0.16)
    elseif alt then
        self:drawRect(0, y, self.width, self.itemheight, 0.08, 1, 1, 1)
    else
        self:drawRect(0, y, self.width, self.itemheight, 0.08, 0, 0, 0)
    end

    self:drawText(tostring(worker.name or worker.workerID), 12, y + 7, 0.88, 0.92, 1, 1, UIFont.Medium)
    drawSubtitleLine(self, 12, y + 33, worker)
    if isSelected then
        self:drawRectBorder(0, y, self.width, self.itemheight, 0.28, 0.98, 0.86, 0.4)
    else
        self:drawRectBorder(0, y, self.width, self.itemheight, 0.08, 1, 1, 1)
    end
    return y + self.itemheight
end

Internal.ColonyWorkerList = ColonyWorkerList

function DC_MainWindow.onWorkerListMouseDown(target, item)
    if not item then
        return
    end

    local win = target or DC_MainWindow.instance
    if not win or not win.applyWorkerSelection then
        return
    end

    win:applyWorkerSelection(item, true)
end
