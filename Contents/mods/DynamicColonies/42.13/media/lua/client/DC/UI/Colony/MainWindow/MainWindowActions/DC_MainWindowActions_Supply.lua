DC_MainWindow = DC_MainWindow or {}

function DC_MainWindow:onOpenInventory()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    DC_SupplyWindow.Open(self.selectedWorker or self.selectedWorkerSummary, "inventory")
    self:updateStatus("Opening NPC inventory...")
end

function DC_MainWindow:onOpenWarehouse()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    DC_SupplyWindow.Open(self.selectedWorker or self.selectedWorkerSummary, "warehouse")
    self:updateStatus("Opening warehouse...")
end
