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