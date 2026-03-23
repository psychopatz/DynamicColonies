require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Buildings/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Shared"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Inventory"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Reputation"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Recruitment"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_QueryHandlers"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers"
require "DC/Common/Buildings/DC_BuildingsNetwork"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Debug"

return DC_Colony.Network
