-- string is a base library namespace already, using stringUtils instead

local module = {}

-- Cleaned up from here:
-- https://stackoverflow.com/a/7615129/24122706
function module.split(input, separator)
    if separator == nil then
        -- Default to white space as a separator
        separator = "%s"
    end

    local output = {}

    for match in string.gmatch(input, "([^"..separator.."]+)") do
        table.insert(output, match)
    end

    return output
end

return module