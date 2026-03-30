DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:isAutoEquipControlVisible()
    return self.workerID ~= nil
        and (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Equipment
        and Internal.isInventoryView
        and Internal.isInventoryView(self)
end

function DC_SupplyWindow:getWarehouseAutoEquipEnabled()
    local warehouse = self.workerData and self.workerData.warehouse or nil
    return warehouse and warehouse.autoEquipEnabled == true or false
end

function DC_SupplyWindow:onToggleAutoEquip()
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end

    local enabled = not self:getWarehouseAutoEquipEnabled()
    if not self:sendColonyCommand("SetWarehouseAutoEquipEnabled", {
            enabled = enabled
        }) then
        self:updateStatus("Unable to update warehouse auto-equip setting.")
        return
    end

    self.workerData = type(self.workerData) == "table" and self.workerData or {}
    self.workerData.warehouse = type(self.workerData.warehouse) == "table" and self.workerData.warehouse or {}
    self.workerData.warehouse.autoEquipEnabled = enabled
    self:updateTransferControls()
    self:updateStatus("Warehouse auto-equip " .. (enabled and "enabled." or "disabled."))
end

function DC_SupplyWindow:onAutoEquipNow()
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    if not self:sendColonyCommand("AutoEquipWorkerFromWarehouse", {
            workerID = self.workerID
        }) then
        self:updateStatus("Unable to auto-equip from warehouse.")
        return
    end

    self.autoRefreshPending = true
    self:updateStatus("Auto-equipping matching warehouse gear...")
end
