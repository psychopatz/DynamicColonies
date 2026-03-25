DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

local function applyWindowLayout(window, options)
    if not window then
        return
    end

    options = options or {}

    local th = window:titleBarHeight()
    local pad = 10
    local headerY = th + pad + MainWindowLayout.WINDOW_HEADER_CLEARANCE
    local listY = headerY + 38
    local footerH = 38
    local listWidth = 280
    local reserveH = 250
    local contentHeight = window.height - listY - footerH - pad
    local rightX = listWidth + (pad * 2)
    local rightWidth = window.width - rightX - pad
    local textPanelWidth = math.max(0, rightWidth - (MainWindowLayout.PANEL_INNER_PAD * 2))
    local detailY = listY + reserveH + pad
    local detailsAreaHeight = window.height - detailY - footerH - pad
    local splitGap = 8
    local maxDetailHeight = math.max(
        MainWindowLayout.DETAIL_PANEL_MIN_HEIGHT,
        detailsAreaHeight - MainWindowLayout.ACTIVITY_PANEL_MIN_HEIGHT - splitGap
    )
    local detailHeight = math.max(
        MainWindowLayout.DETAIL_PANEL_MIN_HEIGHT,
        math.min(maxDetailHeight, math.floor((detailsAreaHeight - splitGap) * 0.38))
    )
    local refreshDetailText = options.refreshDetailText ~= false
    local refreshActivityText = options.refreshActivityText ~= false
    local refreshStatusText = options.refreshStatusText ~= false

    if window.detailText then
        local currentDetailWidth = tonumber(window.detailText:getWidth()) or tonumber(window.detailText.width) or 0
        local detailTextWidthChanged = math.abs(currentDetailWidth - textPanelWidth) > 0.5
        window.detailText:setWidth(textPanelWidth)
        if refreshDetailText or detailTextWidthChanged then
            MainWindowLayout.refreshRichTextPanel(window.detailText)
        end
        local detailContentHeight = MainWindowLayout.getRichTextContentHeight(window.detailText)
        if detailContentHeight > 0 then
            local desiredHeight = detailContentHeight + (MainWindowLayout.PANEL_INNER_PAD * 2) + 4
            detailHeight = math.max(MainWindowLayout.DETAIL_PANEL_MIN_HEIGHT, math.min(maxDetailHeight, math.ceil(desiredHeight)))
        end
    end

    local activityY = detailY + detailHeight + splitGap
    local activityHeight = math.max(MainWindowLayout.ACTIVITY_PANEL_MIN_HEIGHT, window.height - activityY - footerH - pad)

    if window.workerList then
        window.workerList:setX(10)
        window.workerList:setY(listY)
        window.workerList:setWidth(listWidth)
        window.workerList:setHeight(contentHeight)
    end

    if window.reservePanel then
        window.reservePanel:setX(rightX)
        window.reservePanel:setY(listY)
        window.reservePanel:setWidth(rightWidth)
        window.reservePanel:setHeight(reserveH)
    end

    if window.detailPanel then
        window.detailPanel:setX(rightX)
        window.detailPanel:setY(detailY)
        window.detailPanel:setWidth(rightWidth)
        window.detailPanel:setHeight(detailHeight)
    end

    if window.detailText then
        local currentDetailWidth = tonumber(window.detailText:getWidth()) or tonumber(window.detailText.width) or 0
        local detailTextWidthChanged = math.abs(currentDetailWidth - textPanelWidth) > 0.5
        window.detailText:setX(MainWindowLayout.PANEL_INNER_PAD)
        window.detailText:setY(MainWindowLayout.PANEL_HEADER_HEIGHT)
        window.detailText:setWidth(textPanelWidth)
        window.detailText:setHeight(math.max(0, detailHeight - MainWindowLayout.PANEL_HEADER_HEIGHT - MainWindowLayout.PANEL_INNER_PAD))
        if refreshDetailText or detailTextWidthChanged then
            MainWindowLayout.refreshRichTextPanel(window.detailText)
        end
        if window.detailText.vscroll then
            window.detailText.vscroll:setHeight(window.detailText:getHeight())
        end
    end

    if window.activityLogPanel then
        window.activityLogPanel:setX(rightX)
        window.activityLogPanel:setY(activityY)
        window.activityLogPanel:setWidth(rightWidth)
        window.activityLogPanel:setHeight(activityHeight)
    end

    if window.activityLogText then
        local currentActivityWidth = tonumber(window.activityLogText:getWidth()) or tonumber(window.activityLogText.width) or 0
        local activityTextWidthChanged = math.abs(currentActivityWidth - textPanelWidth) > 0.5
        window.activityLogText:setX(MainWindowLayout.PANEL_INNER_PAD)
        window.activityLogText:setY(MainWindowLayout.PANEL_HEADER_HEIGHT)
        window.activityLogText:setWidth(textPanelWidth)
        window.activityLogText:setHeight(math.max(0, activityHeight - MainWindowLayout.PANEL_HEADER_HEIGHT - MainWindowLayout.PANEL_INNER_PAD))
        if refreshActivityText or activityTextWidthChanged then
            MainWindowLayout.refreshRichTextPanel(window.activityLogText)
        end
        if window.activityLogText.vscroll then
            window.activityLogText.vscroll:setHeight(window.activityLogText:getHeight())
        end
    end

    if window.statusText then
        local currentStatusWidth = tonumber(window.statusText:getWidth()) or tonumber(window.statusText.width) or 0
        local statusTextWidthChanged = math.abs(currentStatusWidth - rightWidth) > 0.5
        window.statusText:setX(rightX)
        window.statusText:setY(window.height - footerH - 4)
        window.statusText:setWidth(rightWidth)
        window.statusText:setHeight(28)
        if refreshStatusText or statusTextWidthChanged then
            MainWindowLayout.refreshRichTextPanel(window.statusText)
        end
    end
end

MainWindowLayout.applyWindowLayout = applyWindowLayout
DC_MainWindow.applyDynamicLayout = applyWindowLayout

function DC_MainWindow:onResize()
    ISCollapsableWindow.onResize(self)
    applyWindowLayout(self)
end
