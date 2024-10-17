-- table is a base library namespace already, using tableUtils instead

local module = {}

-- Count number of entries in a table
function module.countEntries(table)
    local count = 0

    for _, item in pairs(table) do 
        count = count + 1
    end

    return count
end

-- Get first key of a table
function module.getFirstKey(table) 
    for key, _ in pairs(table) do 
        return key
    end
end

return module