local scriptVersion = "1.0.0"
local configFileName = ".gather_config.json"

local array = require('deps/array')
local tableUtils = require('deps/tableUtils')
local aseprite = require('deps/aseprite')

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

  -- TODO: We probably want to handle config errors here better and/or
  -- prompt the creation of a config file for artists if it 
  -- does not already exist.
  -- 
  -- Get the script config file from Aseprite config files
  local configFilePath = app.fs.joinPath(app.fs.userConfigPath, configFileName)
  local configFile = io.open(configFilePath, "r")
  io.input(configFile)
  local configDataRaw = io.read("*all")
  local configData = json.decode(configDataRaw)

  -- Get images from each Aseprite layer to operate on
  local spriteImage = aseprite.getCelImageWithTransparentPadding(spriteLayer:cel(1))
  local foldImage = aseprite.getCelImageWithTransparentPadding(foldLayer:cel(1))
  local originImage = aseprite.getCelImageWithTransparentPadding(originLayer:cel(1))

  -- Ask user for information needed for task
  local tileData =
    Dialog()
            :label{ label="Gather Config File:", text=configFilePath }
            :separator{}
            :entry{ id="width", label="Tile width:", text="32" }
            :entry{ id="height", label="Tile height:", text="32" }
            :check{ id="hasForeground",
            label="Sprite foreground: ",
            text="Has foreground",
            selected=false}
            :button{ id="confirm", text="Confirm" }
            :button{ id="cancel", text="Cancel" }
            :show().data

  if tileData.cancel then
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

  -- Calculate rows/cols in the spritesheet
  local rows = sprite.height / tileData.height
  local cols = sprite.width / tileData.width

  -- TODO:
  -- only allow folds on first image? Maybe this is just default?
  -- only allow centers on first image? Maybe this is just default?

  -- Iterate over all sprites in the spritesheet
  for row=0, rows - 1, 1 do
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
      local variant = row
      if tileData.hasForeground then
        variant = math.floor(row / 2)
      end
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

      table.insert(manifestData, imageData)
    end
  end

  local outputPath = app.fs.joinPath(configData.outputDirectory, "manifest.json")
  local file = io.open(outputPath, "w")
  io.output(file)
  io.write(json.encode(manifestData))
  io.close(file)

  app.alert('Done!')
end

function findFold(image)
  local opaqueFoldPixels = aseprite.getAllOpaquePixels(image)

  -- TODO:
  -- Do SOMETHING if there is no fold data

  local yValues = array.map(opaqueFoldPixels, function(pixel) return pixel.y end)
  local uniqueYValues = array.getUniqueValueSet(yValues)
  -- app.alert(uniqueYValues)
  local uniqueYValueCount = tableUtils.countEntries(uniqueYValues)


  if uniqueYValueCount ~= 1 then
    -- There are too many or too few y values for fold,
    -- there should only be one
    return false
  end

  -- Return only Y value
  return tableUtils.getFirstKey(uniqueYValues)
end

function findOrigin(image) 
  local opaqueOriginPixels = aseprite.getAllOpaquePixels(image)

  -- TODO:
  -- Do SOMETHING if there is no origin data

  local originCount = #opaqueOriginPixels

  if originCount ~= 1 then
    -- There are too many or too few y values for origin,
    -- there should only be one
    return false
  end

  -- Return only origin
  return opaqueOriginPixels[1]
end

-- Using this run function pattern to allow
-- functions to be defined after usage
run()