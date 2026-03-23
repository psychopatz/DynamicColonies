DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

Internal.Config = DC_Colony and DC_Colony.Config or Internal.Config or {}
Internal.Nutrition = DC_Colony and DC_Colony.Nutrition or Internal.Nutrition or {}
Internal.ENTRY_SCAN_BATCH_SIZE = 40
Internal.RAW_SCAN_STEP_LIMIT = 600
Internal.NutritionPreviewCache = Internal.NutritionPreviewCache or {}
Internal.TextureCache = Internal.TextureCache or {}
Internal.DETAIL_SUPPORT_PANEL_HEIGHT = 56
Internal.DETAIL_SUPPORT_ICON_SIZE = 24
Internal.ViewModes = {
    Inventory = "inventory",
    Warehouse = "warehouse",
}
Internal.Tabs = {
    Provisions = "provisions",
    Output = "output",
    Equipment = "equipment",
}

function Internal.isWarehouseView(window)
    return window and window.viewMode == Internal.ViewModes.Warehouse
end

function Internal.isInventoryView(window)
    return not Internal.isWarehouseView(window)
end
