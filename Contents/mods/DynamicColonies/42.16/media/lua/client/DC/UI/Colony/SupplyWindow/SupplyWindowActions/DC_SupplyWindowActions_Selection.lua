DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

function DC_SupplyWindow.onPlayerListMouseDown(target, item)
    if not target or not item then
        return
    end

    local entry = item.item or item
    target.selectedPlayerEntry = entry
    target.activeSelectionSide = "player"
    target:updateItemDetail(entry, "player")
end

function DC_SupplyWindow.onWorkerListMouseDown(target, item)
    if not target or not item then
        return
    end

    local entry = item.item or item
    target.selectedWorkerEntry = entry
    target.activeSelectionSide = "worker"
    target:updateItemDetail(entry, "worker")

    local activeTab = target.activeTab or (DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.Tabs and DC_SupplyWindow.Internal.Tabs.Provisions) or "provisions"
    if activeTab == ((DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.Tabs or {}).Equipment)
        and entry
        and entry.kind ~= "money"
        and target.openEquipmentPickerForWorkerEntry then
        target:openEquipmentPickerForWorkerEntry(entry)
    end
end
