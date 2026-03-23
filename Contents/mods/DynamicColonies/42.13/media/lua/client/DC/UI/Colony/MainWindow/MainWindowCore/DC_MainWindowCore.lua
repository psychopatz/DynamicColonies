DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

-- Keep explicit load order so core helpers are available before dependent modules.
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ReserveData"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_PlayerAccess"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerResolvers"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ColonyCommands"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ReservePanel"

