DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_Metrics"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_Initialise"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_CreateChildren"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_Tabs"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_Relayout"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_Render"
require "DC/UI/Colony/SupplyWindow/SupplyWindowLayout/DC_SupplyWindowLayout_Detail"

return DC_SupplyWindow
