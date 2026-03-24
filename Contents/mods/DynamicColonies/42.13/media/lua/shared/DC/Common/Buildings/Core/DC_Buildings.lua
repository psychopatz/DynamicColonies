require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

require "DC/Common/Buildings/Config/Frontier/DC_BuildingsFrontierConfig"
require "DC/Common/Buildings/Config/DC_BuildingsHQConfig"
require "DC/Common/Buildings/Config/DC_BuildingsConfig"
require "DC/Common/Buildings/Data/DC_BuildingsMapData"
require "DC/Common/Buildings/Map/DC_BuildingsMapExpansion"
require "DC/Common/Buildings/Map/Frontier/DC_BuildingsMapFrontier"
require "DC/Common/Buildings/Data/DC_BuildingsData"
require "DC/Common/Buildings/Presentation/DC_BuildingsHousing"
require "DC/Common/Buildings/Map/DC_BuildingsMap"
require "DC/Common/Buildings/Projects/DC_BuildingsProjectTargeting"
require "DC/Common/Buildings/Projects/DC_BuildingsProjects"
require "DC/Common/Buildings/Map/DC_BuildingsMapPresentation"
require "DC/Common/Buildings/Presentation/DC_BuildingsPresentation"

return DC_Buildings
