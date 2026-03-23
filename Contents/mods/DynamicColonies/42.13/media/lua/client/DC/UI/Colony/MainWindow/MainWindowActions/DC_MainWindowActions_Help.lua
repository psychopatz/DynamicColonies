DC_MainWindow = DC_MainWindow or {}

function DC_MainWindow:onOpenHelp()
    DC_ColonyHelpWindow.Open()
    self:updateStatus("Opened scavenging help.")
end
