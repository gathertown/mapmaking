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