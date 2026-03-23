function DC_MainWindow:onOpenBuildings()
    if DC_BuildingsWindow and DC_BuildingsWindow.Open then
        DC_BuildingsWindow.Open(self)
        self:updateStatus("Opening Buildings management...")
    end
end
