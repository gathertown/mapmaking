local color = require('color')
local array = require('array')

local module = {}

function module.collectTileData(sprite, defaults, configData) 
  -- Ask user for information needed for task
  local tileDataDialog = Dialog()

  -- TODO:
  -- Should calcuate variants in a shared logical function
  -- somehow in case we change this pattern in the future.
  local variantCount = sprite.height / defaults.tileHeight

  if defaults.hasForeground then
    variantCount = math.floor(variantCount / 2)
  end

  function updateVariantCount()
    variantCount = sprite.height / tileDataDialog.data.height

    if tileDataDialog.data.hasForeground then
      variantCount = math.floor(variantCount / 2)
    end

    tileDataDialog:modify{ id="variantCount", text=tostring(variantCount) }
  end

  tileDataDialog
    -- :modify{ title="Gather Parse Tilesheet" } -- not sure why this isn't working?
    :label{ label="Gather Config File:", text=configData.filePath }
    :label{ label="Output Path:", text=configData.outputDirectory}
    :separator{}
    :number{ id="width", label="Tile width:", text=tostring(defaults.tileWidth), onchange=updateVariantCount }
    :number{ id="height", label="Tile height:", text=tostring(defaults.tileHeight), onchange=updateVariantCount }
    :check{
        id="hasForeground",
        label="Sprite foreground: ",
        text="Has foreground",
        selected=defaults.hasForeground,
        onclick=updateVariantCount
    }
    :label{ id="variantCount", label="Variant Row Count:", text=tostring(variantCount) }
    :separator{}
    :button{ id="confirm", text="Continue" }
    :button{ id="cancel", text="Cancel" }

  return tileDataDialog:show().data
end

function module.collectVariantData(defaults, tileData)
    local variantDataDialog = Dialog()

    function updateErrors()
      local errors = {}

      for variant=0, tileData.variantCount - 1, 1 do
        local primaryColor = variantDataDialog.data[string.format("variantColorPrimary-%d", variant)]
        local secondaryColor = variantDataDialog.data[string.format("variantColorSecondary-%d", variant)]

        if not color.isValidColor(primaryColor) then
          table.insert(errors, string.format("v%d_1st", variant))
        end

        if secondaryColor ~= "" and not color.isValidColor(secondaryColor) then
          table.insert(errors, string.format("v%d_2nd", variant))
        end
      end

      if #errors > 0 then
        variantDataDialog:modify{ id="errors", text=array.join(errors, ", ") }
        variantDataDialog:modify{ id="confirm", visible=false }
      else
        variantDataDialog:modify{ id="errors", text="" }
        variantDataDialog:modify{ id="confirm", visible=true }
      end

      -- variantCount = sprite.height / tileDataDialog.data.height
  
      -- if tileDataDialog.data.hasForeground then
      --   variantCount = math.floor(variantCount / 2)
      -- end
  
      -- tileDataDialog:modify{ id="errors", text=tostring(variantCount) }
    end

    variantDataDialog:separator{ text="Variants         Primary Color              Secondary Color" }
    for variant=0, tileData.variantCount - 1, 1 do 
      local primaryColor = defaults.orderedColors[variant + 1]
      local secondaryColor = ""
  
      if defaults.variantPrimaryColors[variant + 1] ~= nil then
          primaryColor = defaults.variantPrimaryColors[variant + 1]
      end
      if defaults.variantSecondaryColors[variant + 1] ~= nil then
          secondaryColor = defaults.variantSecondaryColors[variant + 1]
      end
  
      local primaryColorId = string.format("variantColorPrimary-%d", variant)
      local secondaryColorId = string.format("variantColorSecondary-%d", variant)
      
      variantDataDialog
          -- :label{ label=string.format("Row %s", variant) }
          :entry{ id=primaryColorId, label=string.format("Row %s", variant), text=primaryColor, onchange=updateErrors }
          :entry{ id=secondaryColorId, text=secondaryColor, onchange=updateErrors }
    end

    variantDataDialog
      :separator{}
      :label{ id="errors", label="Invalid Colors:", text="" }
  
    variantDataDialog
      :separator{}
      :button{ id="confirm", text="Parse" }
      :button{ id="cancel", text="Cancel" }
      
    -- TODO:
    -- When we parse colors, they should either be from a
    -- set of pre-approved aliases or they should be a 
    -- valid hex code.
  
    return variantDataDialog:show().data
end

return module