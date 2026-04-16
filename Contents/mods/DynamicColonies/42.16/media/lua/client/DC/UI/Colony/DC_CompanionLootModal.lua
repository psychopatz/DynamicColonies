require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISComboBox"

DC_CompanionLootModal = ISCollapsableWindow:derive("DC_CompanionLootModal")
DC_CompanionLootModal.instance = nil

local DEFAULT_RADIUS = 10
local MIN_RADIUS = 2
local MAX_RADIUS = 25
local LIST_ROW_HEIGHT = 22

local TagList = ISScrollingListBox:derive("DC_CompanionLootModal_TagList")

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function clampRadius(value)
    local number = math.floor(tonumber(value) or DEFAULT_RADIUS)
    if number < MIN_RADIUS then
        return MIN_RADIUS
    end
    if number > MAX_RADIUS then
        return MAX_RADIUS
    end
    return number
end

local function copyArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do
        result[index] = value
    end
    return result
end

local function normalizeStringList(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        local normalized = trim(value)
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            result[#result + 1] = normalized
        end
    end
    table.sort(result)
    return result
end

local function getCompanionInternal()
    local companion = DC_Colony and DC_Colony.Companion or nil
    return companion and companion.Internal or nil
end

local function buildDefaultConfig()
    return {
        radius = DEFAULT_RADIUS,
        includeWorldContainers = true,
        includeLooseWorldItems = true,
        includeGroundContainers = true,
        includeFurnitureContainers = true,
        includeCorpseContainers = true,
        includeVehicleContainers = true,
        profileID = nil,
        rawTags = {}
    }
end

local function cloneLootConfig(config)
    local companionInternal = getCompanionInternal()
    if companionInternal and companionInternal.CloneCompanionLootConfig then
        return companionInternal.CloneCompanionLootConfig(config)
    end

    local source = type(config) == "table" and config or buildDefaultConfig()
    local includeWorldContainers = source.includeWorldContainers ~= false
    return {
        radius = clampRadius(source.radius),
        includeWorldContainers = includeWorldContainers,
        includeLooseWorldItems = source.includeLooseWorldItems ~= nil
            and source.includeLooseWorldItems ~= false
            or (source.includeLooseWorldItems == nil and includeWorldContainers),
        includeGroundContainers = source.includeGroundContainers ~= nil
            and source.includeGroundContainers ~= false
            or (source.includeGroundContainers == nil and includeWorldContainers),
        includeFurnitureContainers = source.includeFurnitureContainers ~= nil
            and source.includeFurnitureContainers ~= false
            or (source.includeFurnitureContainers == nil and includeWorldContainers),
        includeCorpseContainers = source.includeCorpseContainers ~= false,
        includeVehicleContainers = source.includeVehicleContainers ~= false,
        profileID = trim(source.profileID) ~= "" and trim(source.profileID) or nil,
        rawTags = normalizeStringList(source.rawTags or {})
    }
end

local function getWorkerLootConfig(worker)
    local companionInternal = getCompanionInternal()
    if companionInternal and companionInternal.GetCompanionLootConfig then
        return cloneLootConfig(companionInternal.GetCompanionLootConfig(worker))
    end

    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    return cloneLootConfig(companionData.lootConfig)
end

local function buildProfileOptions()
    local config = DC_Colony and DC_Colony.Config or {}
    local profiles = config.ScavengeSiteProfiles or {}
    local order = config.ScavengeSiteProfileOrder or {}
    local seen = {}
    local options = {
        {
            id = nil,
            label = "No preset"
        }
    }

    for _, profileID in ipairs(order) do
        local profile = profiles[profileID]
        if type(profile) == "table" and not seen[profileID] then
            seen[profileID] = true
            options[#options + 1] = {
                id = profileID,
                label = tostring(profile.displayName or profileID)
            }
        end
    end

    local extras = {}
    for profileID, profile in pairs(profiles) do
        if type(profile) == "table" and not seen[profileID] then
            extras[#extras + 1] = {
                id = profileID,
                label = tostring(profile.displayName or profileID)
            }
        end
    end
    table.sort(extras, function(a, b)
        return tostring(a.label or "") < tostring(b.label or "")
    end)
    for _, option in ipairs(extras) do
        options[#options + 1] = option
    end

    return options
end

local function buildAvailableTags()
    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or {}
    local tags = {}
    local seen = {}

    for _, entry in pairs(masterList or {}) do
        local sourceTags = type(entry and entry.tags) == "table" and entry.tags or nil
        if sourceTags then
            for _, tag in ipairs(sourceTags) do
                local normalized = trim(tag)
                if normalized ~= "" and not seen[normalized] then
                    seen[normalized] = true
                    tags[#tags + 1] = normalized
                end
            end
        end
    end

    table.sort(tags)
    return tags
end

function TagList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = LIST_ROW_HEIGHT
    o.font = UIFont.Small
    o.doDrawItem = self.doDrawItem
    return o
end

function TagList:doDrawItem(y, item, alt)
    local value = item and item.item or nil
    if not value then
        return y + self.itemheight
    end

    local width = self:getWidth()
    if self.selected == item.index then
        self:drawRect(0, y, width, self.itemheight, 0.22, 0.18, 0.36, 0.62)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.04, 1, 1, 1)
    end

    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)
    self:drawText(tostring(value), 8, y + 3, 0.96, 0.96, 0.96, 1, UIFont.Small)
    return y + self.itemheight
end

function DC_CompanionLootModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
    self.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.94 }
    self.borderColor = { r = 0.9, g = 0.9, b = 0.9, a = 0.18 }
end

function DC_CompanionLootModal:applyToggleStyle(button, enabled, onLabel, offLabel)
    if not button then
        return
    end

    button:setTitle((enabled and onLabel or offLabel) or "")
    if enabled then
        button.backgroundColor = { r = 0.10, g = 0.34, b = 0.12, a = 1 }
        button.backgroundColorMouseOver = { r = 0.14, g = 0.46, b = 0.18, a = 1 }
        button.borderColor = { r = 0.58, g = 0.92, b = 0.62, a = 0.35 }
    else
        button.backgroundColor = { r = 0.16, g = 0.16, b = 0.16, a = 1 }
        button.backgroundColorMouseOver = { r = 0.24, g = 0.24, b = 0.24, a = 1 }
        button.borderColor = { r = 1, g = 1, b = 1, a = 0.15 }
    end
end

function DC_CompanionLootModal:setCurrentConfig(config)
    local nextConfig = cloneLootConfig(config)
    self.currentConfig = nextConfig
    self.selectedTags = copyArray(nextConfig.rawTags or {})

    if self.radiusEntry then
        self.radiusEntry:setText(tostring(nextConfig.radius or DEFAULT_RADIUS))
    end

    if self.profileCombo then
        local selectedIndex = 1
        for index, option in ipairs(self.profileOptions or {}) do
            if option.id == nextConfig.profileID then
                selectedIndex = index
                break
            end
        end
        self.profileCombo.selected = selectedIndex
    end

    self.includeWorldContainers = nextConfig.includeWorldContainers ~= false
    self.includeLooseWorldItems = nextConfig.includeLooseWorldItems ~= false
    self.includeGroundContainers = nextConfig.includeGroundContainers ~= false
    self.includeFurnitureContainers = nextConfig.includeFurnitureContainers ~= false
    self.includeCorpseContainers = nextConfig.includeCorpseContainers ~= false
    self.includeVehicleContainers = nextConfig.includeVehicleContainers ~= false

    self:refreshSelectedTagList()
    self:refreshAvailableTagList()
    self:updateContainerButtons()
end

function DC_CompanionLootModal:buildCurrentConfig()
    local profileOption = self.profileOptions and self.profileOptions[self.profileCombo and self.profileCombo.selected or 1] or nil
    return cloneLootConfig({
        radius = self.radiusEntry and self.radiusEntry:getText() or DEFAULT_RADIUS,
        includeWorldContainers = self.includeWorldContainers ~= false,
        includeLooseWorldItems = self.includeLooseWorldItems ~= false,
        includeGroundContainers = self.includeGroundContainers ~= false,
        includeFurnitureContainers = self.includeFurnitureContainers ~= false,
        includeCorpseContainers = self.includeCorpseContainers ~= false,
        includeVehicleContainers = self.includeVehicleContainers ~= false,
        profileID = profileOption and profileOption.id or nil,
        rawTags = self.selectedTags
    })
end

function DC_CompanionLootModal:refreshAvailableTagList()
    if not self.availableTagList then
        return
    end

    local filterText = string.lower(trim(self.tagEntry and self.tagEntry:getText() or ""))
    local selectedLookup = {}
    for _, tag in ipairs(self.selectedTags or {}) do
        selectedLookup[tag] = true
    end

    self.availableTagList:clear()
    for _, tag in ipairs(self.allTags or {}) do
        if not selectedLookup[tag] then
            local matches = filterText == ""
                or string.find(string.lower(tag), filterText, 1, true) ~= nil
            if matches then
                self.availableTagList:addItem(tag, tag)
            end
        end
    end
end

function DC_CompanionLootModal:refreshSelectedTagList()
    if not self.selectedTagList then
        return
    end

    self.selectedTagList:clear()
    table.sort(self.selectedTags)
    for _, tag in ipairs(self.selectedTags or {}) do
        self.selectedTagList:addItem(tag, tag)
    end
end

function DC_CompanionLootModal:updateContainerButtons()
    self:applyToggleStyle(
        self.btnLooseWorldItems,
        self.includeLooseWorldItems ~= false,
        "Ground Items: On",
        "Ground Items: Off"
    )
    self:applyToggleStyle(
        self.btnGroundContainers,
        self.includeGroundContainers ~= false,
        "Ground Bags: On",
        "Ground Bags: Off"
    )
    self:applyToggleStyle(
        self.btnFurnitureContainers,
        self.includeFurnitureContainers ~= false,
        "Furniture: On",
        "Furniture: Off"
    )
    self:applyToggleStyle(
        self.btnCorpseContainers,
        self.includeCorpseContainers ~= false,
        "Corpses: On",
        "Corpses: Off"
    )
    self:applyToggleStyle(
        self.btnVehicleContainers,
        self.includeVehicleContainers ~= false,
        "Vehicles: On",
        "Vehicles: Off"
    )
end

function DC_CompanionLootModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local contentWidth = self.width - (pad * 2)
    local columnGap = 16
    local halfWidth = math.floor((contentWidth - columnGap) / 2)
    local rightColumnX = pad + halfWidth + columnGap
    local profileRowY = contentY + 50
    local containerRowY = profileRowY + 54
    local containerRowTwoY = containerRowY + 30
    local queryLabelY = containerRowTwoY + 42
    local queryRowY = queryLabelY + 20
    local listLabelY = queryRowY + 40
    local listY = listLabelY + 18
    local buttonY = self.height - 42
    local noteY = buttonY - 28
    local listHeight = math.max(180, noteY - listY - 10)

    self.promptLabel = ISLabel:new(
        pad,
        contentY,
        20,
        tostring(self.promptText or "Configure companion looting."),
        1,
        1,
        1,
        1,
        UIFont.Small,
        true
    )
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.profileLabel = ISLabel:new(pad, contentY + 32, 20, "Scavenge Preset", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.profileLabel:initialise()
    self.profileLabel:instantiate()
    self:addChild(self.profileLabel)

    self.profileCombo = ISComboBox:new(pad, profileRowY, 250, 24, self, self.onProfileChanged)
    self.profileCombo:initialise()
    self.profileCombo:instantiate()
    for _, option in ipairs(self.profileOptions or {}) do
        self.profileCombo:addOption(option.label)
    end
    self:addChild(self.profileCombo)

    self.radiusLabel = ISLabel:new(270, contentY + 32, 20, "Search Radius", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.radiusLabel:initialise()
    self.radiusLabel:instantiate()
    self:addChild(self.radiusLabel)

    self.radiusEntry = ISTextEntryBox:new(tostring(DEFAULT_RADIUS), 270, profileRowY, 80, 24)
    self.radiusEntry:initialise()
    self.radiusEntry:instantiate()
    self:addChild(self.radiusEntry)

    self.radiusHint = ISLabel:new(
        360,
        profileRowY + 4,
        20,
        "tiles",
        0.7,
        0.7,
        0.7,
        1,
        UIFont.Small,
        true
    )
    self.radiusHint:initialise()
    self.radiusHint:instantiate()
    self:addChild(self.radiusHint)

    self.containerLabel = ISLabel:new(pad, contentY + 84, 20, "Container Sources", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.containerLabel:initialise()
    self.containerLabel:instantiate()
    self:addChild(self.containerLabel)

    self.btnLooseWorldItems = ISButton:new(pad, containerRowY, 120, 24, "", self, self.onToggleLooseWorldItems)
    self.btnLooseWorldItems:initialise()
    self.btnLooseWorldItems:instantiate()
    self:addChild(self.btnLooseWorldItems)

    self.btnGroundContainers = ISButton:new(pad + 130, containerRowY, 120, 24, "", self, self.onToggleGroundContainers)
    self.btnGroundContainers:initialise()
    self.btnGroundContainers:instantiate()
    self:addChild(self.btnGroundContainers)

    self.btnFurnitureContainers = ISButton:new(pad + 260, containerRowY, 120, 24, "", self, self.onToggleFurnitureContainers)
    self.btnFurnitureContainers:initialise()
    self.btnFurnitureContainers:instantiate()
    self:addChild(self.btnFurnitureContainers)

    self.btnCorpseContainers = ISButton:new(pad, containerRowTwoY, 120, 24, "", self, self.onToggleCorpseContainers)
    self.btnCorpseContainers:initialise()
    self.btnCorpseContainers:instantiate()
    self:addChild(self.btnCorpseContainers)

    self.btnVehicleContainers = ISButton:new(pad + 130, containerRowTwoY, 120, 24, "", self, self.onToggleVehicleContainers)
    self.btnVehicleContainers:initialise()
    self.btnVehicleContainers:instantiate()
    self:addChild(self.btnVehicleContainers)

    self.tagEntryLabel = ISLabel:new(
        pad,
        queryLabelY,
        20,
        "Tag Search Or Manual Query",
        0.8,
        0.8,
        0.8,
        1,
        UIFont.Small,
        true
    )
    self.tagEntryLabel:initialise()
    self.tagEntryLabel:instantiate()
    self:addChild(self.tagEntryLabel)

    self.tagEntry = ISTextEntryBox:new("", pad, queryRowY, 300, 24)
    self.tagEntry:initialise()
    self.tagEntry:instantiate()
    self:addChild(self.tagEntry)

    self.btnAddQuery = ISButton:new(320, queryRowY, 90, 24, "Add Query", self, self.onAddQueryTag)
    self.btnAddQuery:initialise()
    self.btnAddQuery:instantiate()
    self:addChild(self.btnAddQuery)

    self.availableLabel = ISLabel:new(pad, listY - 20, 20, "Available Tags", 0.88, 0.88, 0.88, 1, UIFont.Small, true)
    self.availableLabel:initialise()
    self.availableLabel:instantiate()
    self:addChild(self.availableLabel)

    self.selectedLabel = ISLabel:new(
        rightColumnX,
        listY - 20,
        20,
        "Selected Queries",
        0.88,
        0.88,
        0.88,
        1,
        UIFont.Small,
        true
    )
    self.selectedLabel:initialise()
    self.selectedLabel:instantiate()
    self:addChild(self.selectedLabel)

    self.availableTagList = TagList:new(pad, listY, halfWidth, listHeight)
    self.availableTagList:initialise()
    self.availableTagList:instantiate()
    self.availableTagList:setFont(UIFont.Small, 2)
    self:addChild(self.availableTagList)

    self.selectedTagList = TagList:new(rightColumnX, listY, halfWidth, listHeight)
    self.selectedTagList:initialise()
    self.selectedTagList:instantiate()
    self.selectedTagList:setFont(UIFont.Small, 2)
    self:addChild(self.selectedTagList)

    self.btnAddSelected = ISButton:new(pad, buttonY, 120, 24, "Add Selected", self, self.onAddSelectedTag)
    self.btnAddSelected:initialise()
    self.btnAddSelected:instantiate()
    self:addChild(self.btnAddSelected)

    self.btnRemoveSelected = ISButton:new(pad + 130, buttonY, 140, 24, "Remove Selected", self, self.onRemoveSelectedTag)
    self.btnRemoveSelected:initialise()
    self.btnRemoveSelected:instantiate()
    self:addChild(self.btnRemoveSelected)

    self.btnReset = ISButton:new(self.width - 310, buttonY, 90, 24, "Defaults", self, self.onResetDefaults)
    self.btnReset:initialise()
    self.btnReset:instantiate()
    self:addChild(self.btnReset)

    self.btnCancel = ISButton:new(self.width - 210, buttonY, 90, 24, "Cancel", self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)

    self.btnSave = ISButton:new(self.width - 110, buttonY, 90, 24, "Save", self, self.onSave)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self:addChild(self.btnSave)

    self.noteLabel = ISLabel:new(
        pad,
        noteY,
        20,
        "Companions only loot items matching your preset or tag queries. Empty filters will not start looting.",
        0.72,
        0.72,
        0.72,
        1,
        UIFont.Small,
        true
    )
    self.noteLabel:initialise()
    self.noteLabel:instantiate()
    self:addChild(self.noteLabel)

    self:setCurrentConfig(self.currentConfig)
end

function DC_CompanionLootModal:onProfileChanged()
end

function DC_CompanionLootModal:onToggleLooseWorldItems()
    self.includeLooseWorldItems = not (self.includeLooseWorldItems ~= false)
    self.includeWorldContainers = self.includeLooseWorldItems ~= false
        or self.includeGroundContainers ~= false
        or self.includeFurnitureContainers ~= false
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleGroundContainers()
    self.includeGroundContainers = not (self.includeGroundContainers ~= false)
    self.includeWorldContainers = self.includeLooseWorldItems ~= false
        or self.includeGroundContainers ~= false
        or self.includeFurnitureContainers ~= false
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleFurnitureContainers()
    self.includeFurnitureContainers = not (self.includeFurnitureContainers ~= false)
    self.includeWorldContainers = self.includeLooseWorldItems ~= false
        or self.includeGroundContainers ~= false
        or self.includeFurnitureContainers ~= false
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleCorpseContainers()
    self.includeCorpseContainers = not (self.includeCorpseContainers ~= false)
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onToggleVehicleContainers()
    self.includeVehicleContainers = not (self.includeVehicleContainers ~= false)
    self:updateContainerButtons()
end

function DC_CompanionLootModal:onAddSelectedTag()
    local item = self.availableTagList and self.availableTagList.items and self.availableTagList.items[self.availableTagList.selected] or nil
    local tag = item and item.item or nil
    if not tag then
        return
    end

    self.selectedTags[#self.selectedTags + 1] = tag
    self.selectedTags = normalizeStringList(self.selectedTags)
    self:refreshSelectedTagList()
    self:refreshAvailableTagList()
end

function DC_CompanionLootModal:onAddQueryTag()
    local query = trim(self.tagEntry and self.tagEntry:getText() or "")
    if query == "" then
        return
    end

    self.selectedTags[#self.selectedTags + 1] = query
    self.selectedTags = normalizeStringList(self.selectedTags)
    self.tagEntry:setText("")
    self.lastTagFilter = ""
    self:refreshSelectedTagList()
    self:refreshAvailableTagList()
end

function DC_CompanionLootModal:onRemoveSelectedTag()
    local item = self.selectedTagList and self.selectedTagList.items and self.selectedTagList.items[self.selectedTagList.selected] or nil
    local tag = item and item.item or nil
    if not tag then
        return
    end

    local remaining = {}
    for _, existing in ipairs(self.selectedTags or {}) do
        if existing ~= tag then
            remaining[#remaining + 1] = existing
        end
    end
    self.selectedTags = remaining
    self:refreshSelectedTagList()
    self:refreshAvailableTagList()
end

function DC_CompanionLootModal:onResetDefaults()
    if self.tagEntry then
        self.tagEntry:setText("")
    end
    self.lastTagFilter = ""
    self:setCurrentConfig(buildDefaultConfig())
end

function DC_CompanionLootModal:onCancel()
    self:close()
end

function DC_CompanionLootModal:onSave()
    if self.onSaveConfig then
        self.onSaveConfig(self:buildCurrentConfig(), self.worker)
    end
    self:close()
end

function DC_CompanionLootModal:update()
    ISCollapsableWindow.update(self)

    local nextFilter = trim(self.tagEntry and self.tagEntry:getText() or "")
    if nextFilter ~= self.lastTagFilter then
        self.lastTagFilter = nextFilter
        self:refreshAvailableTagList()
    end
end

function DC_CompanionLootModal:close()
    DC_CompanionLootModal.instance = nil
    ISCollapsableWindow.close(self)
end

function DC_CompanionLootModal:new(x, y, width, height, args)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    args = args or {}
    o.worker = args.worker
    o.promptText = args.promptText
    o.onSaveConfig = args.onSave
    o.currentConfig = getWorkerLootConfig(args.worker)
    o.profileOptions = buildProfileOptions()
    o.allTags = buildAvailableTags()
    o.selectedTags = {}
    o.includeWorldContainers = true
    o.includeLooseWorldItems = true
    o.includeGroundContainers = true
    o.includeFurnitureContainers = true
    o.includeCorpseContainers = true
    o.includeVehicleContainers = true
    o.lastTagFilter = ""
    o.title = args.title or "Companion Loot Setup"
    return o
end

function DC_CompanionLootModal.Open(args)
    if DC_CompanionLootModal.instance then
        DC_CompanionLootModal.instance:close()
    end

    local width = 760
    local height = 580
    local x = math.max(0, math.floor((getCore():getScreenWidth() - width) / 2))
    local y = math.max(0, math.floor((getCore():getScreenHeight() - height) / 2))
    local modal = DC_CompanionLootModal:new(x, y, width, height, args or {})
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:setVisible(true)
    modal:bringToTop()
    DC_CompanionLootModal.instance = modal
    return modal
end

return DC_CompanionLootModal
