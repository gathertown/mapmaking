local scriptVersion = require('deps/scriptVersion')
local configFileName = ".gather_config.json"

local array = require('deps/array')
local tableUtils = require('deps/tableUtils')
local aseprite = require('deps/aseprite')
local file = require('deps/file')
local stringUtils = require('deps/stringUtils')

function run()
  local sprite = app.activeSprite

  -- Checks for a valid sprite
  if not sprite then
    app.alert("Something is wrong with Aseprite. There is no active sprite to parse.")
    return
  end

  -- Get all layers from the aseprite file
  local rootLayer = sprite.layers
  local spriteLayer = aseprite.findLayerByName(rootLayer, 'Sprite')
  local foldLayer = aseprite.findLayerByName(rootLayer, 'Fold')
  local originLayer = aseprite.findLayerByName(rootLayer, 'Origin')
  local collisionLayer = aseprite.findLayerByName(rootLayer, 'Collision')
  local sittableLayer = aseprite.findLayerByName(rootLayer, 'Sittable')

  -- Verify all required layers exist
  local layerErrors = {}
  if not spriteLayer then
    table.insert(layerErrors, 'Layer named "Sprite" is missing')
  end
  if not foldLayer then
    table.insert(layerErrors, 'Layer named "Fold" is missing')
  end
  if not originLayer then
    table.insert(layerErrors, 'Layer named "Origin" is missing')
  end
  if #layerErrors ~= 0 then
      app.alert("There were errors processing the layers of this Sprite. " .. array.join(layerErrors, ", "))
      return
  end


  -- Get the script config file from Aseprite config files
  local configFilePath = app.fs.joinPath(app.fs.userConfigPath, configFileName)
  if not file.exists(configFilePath) then
    -- TODO: We probably want to handle config errors here better and/or
    -- prompt the creation of a config file for artists if it 
    -- does not already exist.
    app.alert("%s does not exist in Asesprite config files. Check README for more info. Aborting script run.", configFileName)
    return
  end
  local configData = file.readJson(configFilePath)

  -- Get images from each Aseprite layer to operate on
  local spriteImage = aseprite.getCelImageWithTransparentPadding(spriteLayer:cel(1))
  local foldImage = aseprite.getCelImageWithTransparentPadding(foldLayer:cel(1))
  local originImage = aseprite.getCelImageWithTransparentPadding(originLayer:cel(1))

  -- Default dialog values
  local defaultTileWidth=32
  local defaultTileHeight=32
  local defaultHasForeground=false

  -- Use active sprite selection as default height/width
  if not sprite.selection.isEmpty then
    defaultTileWidth = sprite.selection.bounds.width
    defaultTileHeight = sprite.selection.bounds.height
  end

  -- Manifest data output path
  local manifestDataOutputPath = app.fs.joinPath(configData.outputDirectory, "manifest.json")

  -- Try to use pre-existing manifest data as default if it exists
  if file.exists(manifestDataOutputPath) then
    local existingManifestData = file.readJson(manifestDataOutputPath)

    if not isCompatibleScriptVersion(existingManifestData.scriptVersion) then
        -- We can handle this case more elegantly if it comes up later.
        -- Should be unreachable for now.
        app.alert("manfiest.json for this file was generated with an incompatible version of this script. Check README for more info. Aborting script run.")
        return
    end

    defaultTileWidth = existingManifestData.tileData.width
    defaultTileHeight = existingManifestData.tileData.height
    defaultHasForeground = existingManifestData.tileData.hasForeground
  end

  -- Ask user for information needed for task
  local tileDataDialog = Dialog()
    -- :modify{ title="Gather Parse Tilesheet" } -- not sure why this isn't working?
    :label{ label="Gather Config File:", text=configFilePath }
    :label{ label="Output Path:", text=configData.outputDirectory}
    :separator{}
    :number{ id="width", label="Tile width:", text=tostring(defaultTileWidth) }
    :number{ id="height", label="Tile height:", text=tostring(defaultTileHeight) }
    :check{ id="hasForeground",
    label="Sprite foreground: ",
    text="Has foreground",
    selected=defaultHasForeground}

  -- TODO:
  -- add a row per variant here, for now, this is temp
  -- this should sync with the information below too.
  --
  -- Should calcuate variants in a shared logical function
  -- somehow in case we change this pattern in the future.
  local variantCount = sprite.height / defaultTileHeight
  if defaultHasForeground then
    variantCount = math.floor(variantCount / 2)
  end
  tileDataDialog:separator{ text="Variants             Primary Color                      Secondary Color" }
  for variant=0, variantCount - 1, 1 do 
    tileDataDialog
        -- :label{ label=string.format("Row %s", variant) }
        :entry{ label=string.format("Row %s", variant) }
        :entry{}
  end

  -- TODO:
  -- When we parse colors, they should either be from a
  -- set of pre-approved aliases or they should be a 
  -- valid hex code.

  -- Add final action buttons to dialogue
  tileDataDialog
    :separator{}
    :button{ id="confirm", text="Confirm" }
    :button{ id="cancel", text="Cancel" }

  local tileData = tileDataDialog:show().data

  if not tileData.confirm then
    app.alert('Quitting!')
    return
  end

  -- TODO:
  -- fix this to a better ordering: up,down,left,right
  local directions = {
    "down",
    "up",
    "right",
    "left"
  }

  -- Data to be output to manifest file
  local manifestData = {}
  manifestData.scriptVersion=scriptVersion
  manifestData.tileData = {
    width=tonumber(tileData.width),
    height=tonumber(tileData.height),
    hasForeground=tileData.hasForeground
  }
  manifestData.variants = {}
  manifestData.images = {}

  -- Calculate rows/cols in the spritesheet
  local rows = sprite.height / tileData.height
  local cols = sprite.width / tileData.width

  -- TODO:
  -- only allow folds on first image? Maybe this is just default?
  -- only allow centers on first image? Maybe this is just default?

  -- Iterate over all sprites in the spritesheet
  for row=0, rows - 1, 1 do
    local variant = row
    if tileData.hasForeground then
      variant = math.floor(row / 2)
    end
    if not array.contains(manifestData.variants, function (manifestVariant) return manifestVariant.id == variant end) then
        table.insert(manifestData.variants, {
            id=variant
        })
    end
    
    for col=0, cols - 1, 1 do
      -- All metadata about this image
      local imageData = {}
      local imageBounds = {
        x=col * tileData.width,
        y=row * tileData.height,
        width=tileData.width,
        height=tileData.height
      }
      local isOddRow = math.fmod(row, 2) == 1
      local isForeground = tileData.hasForeground and isOddRow -- Every other row is a foreground row when this is true
      local direction = directions[col + 1] -- Lua is 1-indexed, not 0-indexed

      local renderable = ""
      if tileData.hasForeground then
        if isOddRow then
          renderable = "-fg"
        else
          renderable = "-bg"
        end
      end
      local imageFileName = string.format("%s-variant%d-%d%s%s.png", app.fs.fileTitle(sprite.filename), variant, col, direction, renderable)
      imageData.fileName = imageFileName
      imageData.direction = direction
      imageData.variant = variant
      imageData.isForeground = isForeground

      local spriteSubImage = aseprite.getSubImageInBounds(spriteImage, imageBounds)
      local path = app.fs.joinPath(configData.outputDirectory, imageFileName)
      if not spriteSubImage:isEmpty() then
        spriteSubImage:saveAs(path) -- Save the sub sprite image to disk
      end

      local foldSubImage = aseprite.getSubImageInBounds(foldImage, imageBounds)
      local foldValue = findFold(foldSubImage)
      imageData.fold = foldValue

      local originSubImage = aseprite.getSubImageInBounds(originImage, imageBounds)
      local originValue = findOrigin(originSubImage)
      imageData.origin = originValue

      table.insert(manifestData.images, imageData)
    end
  end

  file.writeJson(manifestDataOutputPath, manifestData)

  app.alert('Done!')
end

function findFold(image)
  local opaqueFoldPixels = aseprite.getAllOpaquePixels(image)

  -- TODO:
  -- Do SOMETHING if there is no fold data?

  local yValues = array.map(opaqueFoldPixels, function(pixel) return pixel.y end)
  local uniqueYValues = array.getUniqueValueSet(yValues)
  local uniqueYValueCount = tableUtils.countEntries(uniqueYValues)


  if uniqueYValueCount ~= 1 then
    -- TODO: 
    -- We should alert if too many pixels

    -- There are too many or too few y values for fold,
    -- there should only be one
    return false
  end

  -- There should only be the one valid Y value at this point
  return tableUtils.getFirstKey(uniqueYValues)
end

function findOrigin(image) 
  local opaqueOriginPixels = aseprite.getAllOpaquePixels(image)

  -- TODO:
  -- Do SOMETHING if there is no origin data?

  local originCount = #opaqueOriginPixels

  if originCount ~= 1 then
    -- TODO: 
    -- We should alert if too many pixels

    -- There are too many or too few y values for origin,
    -- there should only be one
    return false
  end

  -- Return only origin
  return opaqueOriginPixels[1]
end

function isCompatibleScriptVersion(version) 
    local versionParts = stringUtils.split(version, '.')
    local majorVersion = tonumber(versionParts[1]) -- lua is 1-indexed
    local minorVersion = tonumber(versionParts[2])
    local patchVersion = tonumber(versionParts[3])

    -- There are no compat checks needed yet, but we
    -- can compare against scriptVersion in the future.

    return true
end

-- Using this run function pattern to allow
-- functions to be defined after usage
run()