DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

function DC_MainWindow:updateFactionButton()
    if not self.btnFaction then
        return
    end

    local status = (DC_System and DC_System.GetOwnedFactionStatus and DC_System.GetOwnedFactionStatus()) or DC_MainWindow.cachedOwnedFactionStatus
    if status and status.faction then
        self.btnFaction:setTitle("Open Faction")
        self.btnFaction:setEnable(true)
        return
    end

    if status and status.canCreate == true then
        self.btnFaction:setTitle("Create Faction")
        self.btnFaction:setEnable(true)
        return
    end

    self.btnFaction:setTitle("Faction Locked")
    self.btnFaction:setEnable(false)
end

function DC_MainWindow:onOpenFaction()
    if not DC_System or not DC_System.OpenOwnedFactionManagement then
        self:updateStatus("Faction management is unavailable.")
        return
    end

    local ok, msg = DC_System.OpenOwnedFactionManagement()
    if msg and msg ~= "" then
        self:updateStatus(msg)
    elseif ok then
        self:updateStatus("Opening faction management...")
    end
end
