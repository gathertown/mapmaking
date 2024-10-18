-- Bundled by luabundle {"version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
local scriptVersion = require("deps/scriptVersion")
local configFileName = ".gather_config.json"

local array = require("deps/array")
local tableUtils = require("deps/tableUtils")
local aseprite = require("deps/aseprite")
local file = require("deps/file")
local stringUtils = require("deps/stringUtils")
local dialog = require("deps/dialog")

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

  -- TODO:
  -- This is a temp (?) override.
  -- Override output directory to just output next to aseprite file:
  configData.outputDirectory = app.fs.filePath(sprite.filename)

  -- Get images from each Aseprite layer to operate on
  local spriteImage = aseprite.getCelImageWithTransparentPadding(spriteLayer:cel(1))
  local foldImage = aseprite.getCelImageWithTransparentPadding(foldLayer:cel(1))
  local originImage = aseprite.getCelImageWithTransparentPadding(originLayer:cel(1))

  -- Default dialog values
  local defaultTileWidth=32
  local defaultTileHeight=32
  local defaultHasForeground=false
  -- See reference/palette_naming_reference.png for more info here.
  -- This is an agreed upon set of default colors for variant rows.
  local defaultOrderedColors={
    "brown",
    "red",
    "orange",
    "yellow",
    "green",
    "blue",
    "purple"
  }
  local defaultVariantPrimaryColors={}
  local defaultVariantSecondaryColors={}

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

    defaultVariantPrimaryColors = array.map(existingManifestData.variants, function(variant) return variant.color.primary end)
    defaultVariantSecondaryColors = array.map(existingManifestData.variants, function(variant) return variant.color.secondary end)
  end
  
  local tileData = dialog.collectTileData(sprite, {
    tileHeight=defaultTileHeight,
    tileWidth=defaultTileWidth,
    hasForeground=defaultHasForeground
  }, configData)

  if not tileData.confirm then
    app.alert('Quitting!')
    return
  end

  local variantData = dialog.collectVariantData({
    orderedColors=defaultOrderedColors,
    variantPrimaryColors=defaultVariantPrimaryColors,
    variantSecondaryColors=defaultVariantSecondaryColors
  }, tileData)

  if not variantData.confirm then
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
            id=variant,
            color={
                primary=variantData[string.format("variantColorPrimary-%d", variant)],
                secondary=variantData[string.format("variantColorSecondary-%d", variant)],
            }
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
end)
__bundle_register("deps/dialog", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("deps/stringUtils", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("deps/file", function(require, _LOADED, __bundle_register, __bundle_modules)
local module = {}

function module.exists(path) 
    local file=io.open(path,"r")

    if file~=nil then
        io.close(file)
        return true
    end

    return false
end

function module.readJson(path)
    local file = io.open(path, "r")
    io.input(file)
    local rawData = io.read("*all")
    
    return json.decode(rawData)
end

function module.writeJson(path, data) 
    local file = io.open(path, "w")
    io.output(file)
    io.write(json.encode(data))
    io.close(file)
end

return module
end)
__bundle_register("deps/aseprite", function(require, _LOADED, __bundle_register, __bundle_modules)
local module = {}

-- Get array of all opaque pixels in an image
function module.getAllOpaquePixels(image) 
    local opaquePixels = {}

    for pixelIterator in image:pixels() do
        local pixelValue = pixelIterator()
        local alpha = app.pixelColor.rgbaA(pixelValue)
        if alpha > 0 then
        table.insert(opaquePixels, {
            x=pixelIterator.x,
            y=pixelIterator.y
        })
    end
end

return opaquePixels
end

function  module.getSubImageInBounds(sourceImage, bounds)
    local image = Image(bounds.width, bounds.height)
        
    -- X and Y are negative because we're drawing the source image onto 
    -- our new image, not placing our new image over top of the source image.
    image:drawImage(sourceImage, Point(-bounds.x, -bounds.y))

    return image;
end

-- Find a layer on a Sprite by name
function  module.findLayerByName(rootLayer, name) 
    for index, layer in ipairs(rootLayer) do
        if layer.name == name then
        return layer
        end
    end

    return nil
end

-- Aseprite cel images do not store bordering transparent
-- pixel data. Instead, cels have an x/y position and the
-- transparent pixels from a canvas are omitted.
--
-- This function uses bounds data to create an image with 
-- these omitted transparent pixels in place.
-- 
-- more info: 
-- https://community.aseprite.org/t/lua-scripts-image-size-does-not-match-actual-image-size/9766/4
function  module.getCelImageWithTransparentPadding(cel) 
    local paddedImage = Image(cel.bounds.x + cel.bounds.width, cel.bounds.y + cel.bounds.height)
    paddedImage:drawImage(cel.image, Point(cel.bounds.x, cel.bounds.y))

    return paddedImage
end

return module
end)
__bundle_register("deps/tableUtils", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
__bundle_register("deps/array", function(require, _LOADED, __bundle_register, __bundle_modules)
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
function module.getUniqueValueSet(array) 
  local uniqueSet = {}

  for _, item in ipairs(array) do 
    uniqueSet[item] = true
  end

  return uniqueSet
end

function module.contains(array, callback)
  for index, item in ipairs(array) do 
    if (callback(item, index)) then
      return true
    end
  end

  return false
end

return module
end)
__bundle_register("deps/scriptVersion", function(require, _LOADED, __bundle_register, __bundle_modules)
-- This file is generated.
-- It will be overwritten by bundleScripts.js during
-- the lua bundle process.
return "1.0.0"
end)
return __bundle_require("__root")