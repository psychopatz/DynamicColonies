DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
Internal.ReservePanel = Internal.ReservePanel or {}

-- Keep explicit load order so this panel remains deterministic under PZ script loading.
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ReserveData"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy"

require "DC/UI/Colony/MainWindow/MainWindowCore/MainWindowCoreReservePanel/DC_MainWindowCoreReservePanel_Foundation_logic"
require "DC/UI/Colony/MainWindow/MainWindowCore/MainWindowCoreReservePanel/DC_MainWindowCoreReservePanel_DataBuilders_logic"
require "DC/UI/Colony/MainWindow/MainWindowCore/MainWindowCoreReservePanel/DC_MainWindowCoreReservePanel_WorkerAdapters_logic"
require "DC/UI/Colony/MainWindow/MainWindowCore/MainWindowCoreReservePanel/DC_MainWindowCoreReservePanel_CardLifecycle_logic"
require "DC/UI/Colony/MainWindow/MainWindowCore/MainWindowCoreReservePanel/DC_MainWindowCoreReservePanel_Rendering_logic"

Internal.ColonyReservePanel = Internal.ReservePanel.ColonyProfileCard

return Internal.ColonyReservePanel
