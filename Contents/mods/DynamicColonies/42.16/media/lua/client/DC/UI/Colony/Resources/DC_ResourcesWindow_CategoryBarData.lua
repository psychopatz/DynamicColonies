DC_ResourcesWindow_CategoryBarData = DC_ResourcesWindow_CategoryBarData or {}

local CategoryBarData = DC_ResourcesWindow_CategoryBarData

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function parseMetricPair(metricText)
    local text = tostring(metricText or "")
    local rawCurrent, rawCapacity = string.match(text, "([%d%.%-]+)%s*/%s*([%d%.%-]+)")
    if not rawCurrent or not rawCapacity then
        return nil, nil
    end
    return tonumber(rawCurrent), tonumber(rawCapacity)
end

function CategoryBarData.GetCategoryBarColor(category)
    local categoryID = tostring(category and category.id or "")
    if categoryID == "Water" then
        return { r = 0.36, g = 0.74, b = 1.00 }
    elseif categoryID == "Electricity" then
        return { r = 0.96, g = 0.78, b = 0.16 }
    elseif categoryID == "Ammo" then
        return { r = 0.74, g = 0.44, b = 0.18 }
    elseif categoryID == "Medicine" then
        return { r = 0.32, g = 0.78, b = 0.42 }
    elseif categoryID == "Scrap" then
        return { r = 0.66, g = 0.62, b = 0.50 }
    end
    return { r = 0.62, g = 0.62, b = 0.62 }
end

function CategoryBarData.GetCategoryBarData(category)
    local current, capacity = nil, nil

    if category then
        current = tonumber(category.current)
        capacity = tonumber(category.capacity)

        if current == nil or capacity == nil then
            local parsedCurrent, parsedCapacity = parseMetricPair(category.metric)
            current = current or parsedCurrent
            capacity = capacity or parsedCapacity
        end
    end

    current = tonumber(current) or 0
    capacity = tonumber(capacity) or 0
    if current < 0 then
        current = 0
    end
    if capacity < 0 then
        capacity = 0
    end

    local ratio = 0
    if capacity > 0 then
        ratio = clamp01(current / capacity)
    end

    return {
        ratio = ratio,
        metricText = tostring(math.floor(current + 0.5)) .. " / " .. tostring(math.floor(capacity + 0.5)),
        color = CategoryBarData.GetCategoryBarColor(category)
    }
end

return CategoryBarData
