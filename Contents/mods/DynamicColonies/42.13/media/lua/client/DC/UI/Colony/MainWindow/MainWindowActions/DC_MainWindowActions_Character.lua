DC_MainWindow = DC_MainWindow or {}

function DC_MainWindow:onOpenCharacter()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    DC_ColonyCharacterWindow.OpenWorker(self.selectedWorker or self.selectedWorkerSummary)
    self:updateStatus("Opening character sheet...")
end
