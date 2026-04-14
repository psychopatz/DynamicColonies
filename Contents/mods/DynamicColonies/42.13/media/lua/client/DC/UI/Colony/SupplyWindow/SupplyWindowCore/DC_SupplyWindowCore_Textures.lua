DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.getDisplayNameForFullType(fullType)
    if not fullType or not getScriptManager then
        return tostring(fullType or "Unknown Item")
    end

    local item = getScriptManager():getItem(fullType)
    if item and item.getDisplayName then
        return item:getDisplayName()
    end

    return tostring(fullType or "Unknown Item")
end

local function isValidItemTexture(tex)
    return tex and tex.getName and tex:getName() ~= "Question_Highlight"
end

local function safeCall(target, methodName, ...)
    if not target or not target[methodName] then
        return nil
    end

    local ok, result = pcall(target[methodName], target, ...)
    if ok then
        return result
    end

    return nil
end

local function tryTexture(textureName)
    if not textureName or textureName == "" then
        return nil
    end

    local tex = getTexture(textureName)
    if isValidItemTexture(tex) then
        return tex
    end

    return nil
end

local function normalizeIconVariants(rawVariants)
    if not rawVariants then
        return nil
    end

    if type(rawVariants) == "string" then
        local variants = {}
        for entry in string.gmatch(rawVariants, "([^;]+)") do
            entry = entry:gsub("^%s+", ""):gsub("%s+$", "")
            if entry ~= "" then
                variants[#variants + 1] = entry
            end
        end
        return #variants > 0 and variants or nil
    end

    if type(rawVariants) == "table" then
        return #rawVariants > 0 and rawVariants or nil
    end

    if rawVariants.size and rawVariants.get then
        local variants = {}
        for i = 0, rawVariants:size() - 1 do
            local entry = rawVariants:get(i)
            if entry and tostring(entry) ~= "" then
                variants[#variants + 1] = tostring(entry)
            end
        end
        return #variants > 0 and variants or nil
    end

    return nil
end

local function getScriptIconVariants(script)
    if not script then
        return nil
    end

    local candidates = {
        safeCall(script, "getIconsForTexture"),
        safeCall(script, "getIconsForTextures"),
        safeCall(script, "getIconsForTextureString"),
        safeCall(script, "getIconsForTextureChoices"),
    }

    for _, candidate in ipairs(candidates) do
        local variants = normalizeIconVariants(candidate)
        if variants then
            return variants
        end
    end

    return nil
end

local function resolveScriptVariantTexture(script)
    local variants = getScriptIconVariants(script)
    if not variants then
        return nil
    end

    for _, variant in ipairs(variants) do
        local tex = tryTexture("Item_" .. variant)
            or tryTexture(variant)
            or tryTexture("media/textures/Item_" .. variant .. ".png")
        if tex then
            return tex
        end
    end

    return nil
end

local function resolveInventoryItemTexture(item)
    if not item then
        return nil
    end

    if item.getTex then
        local tex = item:getTex()
        if isValidItemTexture(tex) then
            return tex
        end
    end

    if item.getIcon then
        local icon = item:getIcon()
        if icon and type(icon) ~= "string" and isValidItemTexture(icon) then
            return icon
        end
    end

    local tex = safeCall(item, "getTexture")
    if isValidItemTexture(tex) then
        return tex
    end

    return nil
end

function Internal.getTextureForFullType(fullType)
    if not fullType then
        return nil
    end

    local cache = Internal.TextureCache or {}
    Internal.TextureCache = cache
    if cache[fullType] ~= nil then
        return cache[fullType]
    end

    local texture = nil
    local script = getScriptManager and getScriptManager():getItem(fullType) or nil

    if DC_TradingWindow and DC_TradingWindow.GetItemTexture then
        texture = DC_TradingWindow.GetItemTexture(fullType, nil)
    end

    if not isValidItemTexture(texture) and script then
        texture = resolveScriptVariantTexture(script)
    end

    if not isValidItemTexture(texture) and script then
        local iconStr = safeCall(script, "getIcon")
        if iconStr and iconStr ~= "" then
            texture = tryTexture("Item_" .. iconStr)
                or tryTexture(iconStr)
                or tryTexture("media/textures/Item_" .. iconStr .. ".png")
        end
    end

    if not isValidItemTexture(texture) and script and script.getClothingItem then
        local clothingItem = script:getClothingItem()
        if clothingItem and clothingItem ~= "" then
            texture = tryTexture("Item_" .. clothingItem) or tryTexture(clothingItem)
        end
    end

    if not isValidItemTexture(texture) and InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok and item then
            texture = resolveInventoryItemTexture(item)
        end
    end

    cache[fullType] = isValidItemTexture(texture) and texture or false
    return cache[fullType] or nil
end

function Internal.peekTextureForFullType(fullType)
    if not fullType then
        return nil
    end

    local cache = Internal.TextureCache or {}
    local cached = cache[tostring(fullType)]
    return cached ~= false and cached or nil
end

function Internal.queueTextureForFullType(fullType)
    local key = tostring(fullType or "")
    if key == "" then
        return nil
    end

    local cached = Internal.peekTextureForFullType(key)
    if cached then
        return cached
    end

    local cache = Internal.TextureCache or {}
    if cache[key] == false then
        return nil
    end

    Internal.TextureQueue = Internal.TextureQueue or {}
    Internal.TextureQueueSet = Internal.TextureQueueSet or {}
    if not Internal.TextureQueueSet[key] then
        Internal.TextureQueueSet[key] = true
        Internal.TextureQueue[#Internal.TextureQueue + 1] = key
    end
    return nil
end

function Internal.resolveEntryTexture(entry)
    if not entry then
        return nil
    end
    if entry.texture then
        return entry.texture
    end

    local fullType = entry.iconFullType or entry.fullType
    local cached = Internal.queueTextureForFullType(fullType)
    if cached then
        entry.texture = cached
    end
    return entry.texture
end

function Internal.processTextureQueue(batchSize)
    local queue = Internal.TextureQueue
    if type(queue) ~= "table" or #queue <= 0 then
        return false
    end

    local set = Internal.TextureQueueSet or {}
    Internal.TextureQueueSet = set
    local limit = math.max(1, tonumber(batchSize) or tonumber(Internal.ICON_RESOLVE_BATCH_SIZE) or 1)
    local processed = 0

    while #queue > 0 and processed < limit do
        local fullType = table.remove(queue, 1)
        set[fullType] = nil
        Internal.getTextureForFullType(fullType)
        processed = processed + 1
    end

    return #queue > 0
end
