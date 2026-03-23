DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

function DC_SupplyWindow:onRefresh()
    self:startInventoryScan()
    if self.workerID then
        local includeWarehouseLedgers = self.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse)
        self:sendColonyCommand("RequestWorkerDetails", {
            workerID = self.workerID,
            includeWarehouseLedgers = includeWarehouseLedgers
        })
    end
end

function DC_SupplyWindow:requestWorkerDetails()
    if not self.workerID then
        return
    end

    local includeWarehouseLedgers = self.viewMode == ((DC_SupplyWindow.Internal.ViewModes or {}).Warehouse)
    self:sendColonyCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        includeWarehouseLedgers = includeWarehouseLedgers
    })
end
