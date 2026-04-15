require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISTextEntryBox"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/ColonyNetwork/DC_Colony_Network"

DC_SupplyWindow = ISCollapsableWindow:derive("DC_SupplyWindow")
DC_SupplyWindow.instance = nil
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

-- Keep explicit load order so shared helpers are available before dependent modules.
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore"
require "DC/UI/Colony/SupplyWindow/DC_SupplyWindow_List"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState"
require "DC/UI/Colony/SupplyWindow/SupplyWindowActions/DC_SupplyWindowActions"
require "DC/UI/Colony/SupplyWindow/DC_SupplyWindow_Lifecycle"
require "DC/UI/Colony/SupplyWindow/DC_SupplyWindow_Events"

return DC_SupplyWindow
