DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

local function buildWorkerListSignature(workers)
    local parts = {}

    for index, worker in ipairs(workers or {}) do
        parts[index] = table.concat({
            tostring(worker and worker.workerID or ""),
            tostring(worker and worker.name or ""),
            tostring(worker and worker.state or ""),
            tostring(worker and worker.jobType or ""),
            tostring(worker and worker.presenceState or ""),
            tostring(worker and worker.jobEnabled == true and 1 or 0)
        }, "\31")
    end

    return table.concat(parts, "\30")
end

local function findWorkerIndex(items, workerID)
    if not workerID then
        return nil
    end

    for index, entry in ipairs(items or {}) do
        local worker = entry and entry.item or nil
        if worker and worker.workerID == workerID then
            return index
        end
    end

    return nil
end

local function findWorkerSummary(workers, workerID)
    if not workerID then
        return nil
    end

    for _, worker in ipairs(workers or {}) do
        if worker and worker.workerID == workerID then
            return worker
        end
    end

    return nil
end

function DC_MainWindow:populateWorkerList(workers)
    if not self.workerList then
        return
    end

    local nextWorkers = workers or {}
    local nextSignature = buildWorkerListSignature(nextWorkers)
    local preferredID = self.selectedWorkerSummary and self.selectedWorkerSummary.workerID or nil
    local latestSelectedSummary = findWorkerSummary(nextWorkers, preferredID)

    if self.workerListSignature == nextSignature then
        local currentItems = self.workerList.items or {}
        if #currentItems > 0 then
            local currentIndex = findWorkerIndex(currentItems, preferredID) or self.workerList.selected or 1
            self.workerList.selected = currentIndex
            if latestSelectedSummary then
                self.selectedWorkerSummary = latestSelectedSummary
            end
            if not self.selectedWorker and currentItems[currentIndex] and currentItems[currentIndex].item then
                self:applyWorkerSelection(currentItems[currentIndex].item, false)
            end
        else
            self.selectedWorkerSummary = nil
            self.selectedWorker = nil
            self:updateWorkerDetail(nil)
        end
        return
    end

    self.workerListSignature = nextSignature
    self.workerList:clear()

    local selectedIndex = nil
    for _, worker in ipairs(nextWorkers) do
        self.workerList:addItem(worker.name or worker.workerID, worker)
        if preferredID and preferredID == worker.workerID then
            selectedIndex = #self.workerList.items
        end
    end

    if self.workerList.items and #self.workerList.items > 0 then
        local targetIndex = selectedIndex or 1
        local selectedSummary = self.workerList.items[targetIndex].item
        local selectedWorkerID = selectedSummary and selectedSummary.workerID or nil
        local previousWorkerID = self.selectedWorkerSummary and self.selectedWorkerSummary.workerID or nil
        local cachedDetail = selectedWorkerID and Internal.resolveWorkerDetail(selectedWorkerID) or nil

        self.workerList.selected = targetIndex
        self.selectedWorkerSummary = selectedSummary

        if previousWorkerID ~= selectedWorkerID or not cachedDetail or not self.selectedWorker or self.selectedWorker.workerID ~= selectedWorkerID then
            self:applyWorkerSelection(selectedSummary, false)
        end
    else
        self.selectedWorkerSummary = nil
        self.selectedWorker = nil
        self.workerList.selected = 0
        self:updateWorkerDetail(nil)
    end
end
