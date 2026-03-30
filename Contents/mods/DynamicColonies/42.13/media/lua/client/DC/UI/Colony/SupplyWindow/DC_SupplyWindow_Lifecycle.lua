DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

function DC_SupplyWindow.Open(worker, viewMode)
    if not worker or not worker.workerID then
        return
    end

    local window = DC_SupplyWindow.instance
    if not window then
        local width = 980
        local height = 620
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2

        window = DC_SupplyWindow:new(x, y, width, height)
        window:initialise()
        window:instantiate()
        DC_SupplyWindow.instance = window
    end

    window.workerID = worker.workerID
    window.workerName = worker.name or worker.workerID
    window.viewMode = viewMode or (DC_SupplyWindow.Internal.ViewModes and DC_SupplyWindow.Internal.ViewModes.Inventory) or "inventory"
    window.activeTab = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.Tabs and DC_SupplyWindow.Internal.Tabs.Provisions or "provisions"
    window.selectedPlayerEntry = nil
    window.selectedWorkerEntry = nil
    window.playerExpandedGroups = {}
    window.workerExpandedGroups = {}
    local subjectName = tostring(window.workerName)
    if window.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse)
        and DC_SupplyWindow.Internal
        and DC_SupplyWindow.Internal.getWarehouseDisplayName then
        subjectName = DC_SupplyWindow.Internal.getWarehouseDisplayName(window)
    end
    window.title = (window.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse) and "Warehouse - " or "NPC Inventory - ")
        .. subjectName
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    local resolvedWorker = DC_SupplyWindow.Internal.resolveWorkerDetail(worker.workerID) or nil
    local workerDetail = resolvedWorker
    if type(worker) == "table" then
        if not workerDetail then
            workerDetail = worker
        else
            for key, value in pairs(worker) do
                if workerDetail[key] == nil then
                    workerDetail[key] = value
                end
            end
        end
    end
    window:setWorkerData(workerDetail or worker)
    window:startInventoryScan()
    window:requestWorkerDetails()
    if DC_EquipmentPickerModal and DC_EquipmentPickerModal.Preload then
        DC_EquipmentPickerModal.Preload()
    end
    window:updateStatus(
        (window.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse) and "Opening warehouse for " or "Opening inventory for ")
            .. subjectName .. "."
    )
end

function DC_SupplyWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_SupplyWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Colony Supplies"
    o.resizable = true
    o.playerEntries = {}
    o.playerEntriesByID = {}
    o.workerEntries = {}
    o.activeTab = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.Tabs and DC_SupplyWindow.Internal.Tabs.Provisions or "provisions"
    o.selectedPlayerEntry = nil
    o.selectedWorkerEntry = nil
    o.activeSelectionSide = "player"
    o.workerID = nil
    o.workerName = nil
    o.viewMode = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.ViewModes and DC_SupplyWindow.Internal.ViewModes.Inventory or "inventory"
    o.detailRefreshTicks = 0
    o.lastPlayerFilter = ""
    o.lastWorkerFilter = ""
    o.playerExpandedGroups = {}
    o.workerExpandedGroups = {}
    o.playerVisibleEntries = {}
    o.workerVisibleEntries = {}
    o.pendingPlayerListRows = nil
    o.pendingPlayerListNextIndex = nil
    o.pendingPlayerListSelectedKey = nil
    o.pendingPlayerListSelectedRowIndex = nil
    o.pendingWorkerListRows = nil
    o.pendingWorkerListNextIndex = nil
    o.pendingWorkerListSelectedKey = nil
    o.pendingWorkerListSelectedRowIndex = nil
    return o
end
