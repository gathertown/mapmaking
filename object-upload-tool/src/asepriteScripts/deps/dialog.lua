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

  function updateVariantRowFields()
    variantCount = sprite.height / tileDataDialog.data.height

    if tileDataDialog.data.hasForeground then
      variantCount = math.floor(variantCount / 2)
    end

    tileDataDialog:modify{ id="variantCount", text=tostring(variantCount) }
  end

  tileDataDialog
    -- :modify{ title="Gather Parse Tilesheet" } -- not sure why this isn't working?
    :label{ label="Gather Config File:", text=configFilePath }
    :label{ label="Output Path:", text=configData.outputDirectory}
    :separator{}
    :number{ id="width", label="Tile width:", text=tostring(defaults.tileWidth), onchange=updateVariantRowFields }
    :number{ id="height", label="Tile height:", text=tostring(defaults.tileHeight), onchange=updateVariantRowFields }
    :check{
        id="hasForeground",
        label="Sprite foreground: ",
        text="Has foreground",
        selected=defaults.hasForeground,
        onclick=updateVariantRowFields
    }
    :label{ id="variantCount", label="Variant Row Count:", text=tostring(variantCount) }
    :separator{}
    :button{ id="confirm", text="Continue" }
    :button{ id="cancel", text="Cancel" }

  return tileDataDialog:show().data
end

function module.collectVariantData(defaults, tileData)
    local variantDataDialog = Dialog()

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
          :entry{ id=primaryColorId, label=string.format("Row %s", variant), text=primaryColor }
          :entry{ id=secondaryColorId, text=secondaryColor }
    end
  
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