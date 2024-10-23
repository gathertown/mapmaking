local array = require('array')

local module = {}

-- See reference/palette_naming_reference.png for more info here.
local validColorsWithShadeModifier = {
    "brown",
    "coffee",
    "pink",
    "purple",
    "blue",
    "teal",
    "green",
    "yellow",
    "orange",
    "red"
}
local validOtherColors = {
    "white",
    "grey",
    "black"
}

function module.isValidColor(color)
    local firstChar = string.sub(color, 1, 1)
    
    if string.len(color) == 7 and firstChar == '#' then
        -- This is probably a valid hex code
        return true
    end

    local validColors = {}

    for index, baseColor in ipairs(validColorsWithShadeModifier) do 
        table.insert(validColors, baseColor)
        table.insert(validColors, "light" .. baseColor)
        table.insert(validColors, "dark" .. baseColor)
    end
    
    for index, color in ipairs(validOtherColors) do 
        table.insert(validColors, color)
    end

    return array.contains(validColors, function(validColor) return validColor == color end)
end


return module