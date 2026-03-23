require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Tiredness = DC_Colony.Tiredness or {}

require "DC/Common/Colony/ColonyTiredness/DC_ColonyTiredness_Config"
require "DC/Common/Colony/ColonyTiredness/DC_ColonyTiredness_WorkerState"
require "DC/Common/Colony/ColonyTiredness/DC_ColonyTiredness_Rates"
require "DC/Common/Colony/ColonyTiredness/DC_ColonyTiredness_Process"
require "DC/Common/Colony/ColonyTiredness/DC_ColonyTiredness_Presentation"

return DC_Colony.Tiredness
