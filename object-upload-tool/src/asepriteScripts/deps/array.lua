local module = {}

-- Like JS array.join
function module.join(array, separator) 
  local output = ""
  
  for index, item in ipairs(array) do 
    output = output .. item

    if index < #array then
      output = output .. separator
    end
  end

  return output
end

-- Like JS array.every
function module.every(array, callback)
  for index, item in ipairs(array) do 
    if not callback(item, index) then
      return false
    end
  end

  return true
end

-- Like JS array.map
function module.map(array, callback)
  local output = {}

  for index, item in ipairs(array) do 
    table.insert(output, callback(item, index))
  end

  return output
end

-- Like JS array.filter
function module.filter(array, callback)
  local output = {}

  for index, item in ipairs(array) do 
    if (callback(item, index)) then
      table.insert(output, item)
    end
  end

  return output
end

  -- Create a "set" of unique values from an array
function module.getUniqueValueSet(values) 
  local uniqueSet = {}

  for _, item in ipairs(values) do 
    uniqueSet[item] = true
  end

  return uniqueSet
end

return module