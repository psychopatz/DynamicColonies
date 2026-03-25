DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

function DC_MainWindow:updateStatus(text)
    if not self.statusText then
        return
    end

    local nextStatus = tostring(text or "")
    if self.lastStatusText == nextStatus then
        return
    end

    self.lastStatusText = nextStatus
    self.statusText:setText(" <RGB:0.75,0.75,0.75> " .. nextStatus .. " ")
    MainWindowLayout.refreshRichTextPanel(self.statusText)
end
