local Tuning = {}

Tuning.options = {
    {key = "paint", name = "Body paint", choices = {
        {name = "Factory", price = 0},
        {name = "Harbor teal", price = 300, color = Color3.fromRGB(35, 138, 139)},
        {name = "Calder cream", price = 300, color = Color3.fromRGB(222, 202, 158)},
        {name = "Copper red", price = 300, color = Color3.fromRGB(167, 65, 48)},
        {name = "Basalt", price = 300, color = Color3.fromRGB(49, 55, 66)},
    }},
    {key = "wheels", name = "Alloy finish", choices = {
        {name = "Factory", price = 0},
        {name = "Graphite", price = 180, color = Color3.fromRGB(62, 69, 75)},
        {name = "Bronze", price = 180, color = Color3.fromRGB(167, 125, 75)},
        {name = "Polished", price = 180, color = Color3.fromRGB(202, 211, 218)},
    }},
    {key = "engine", name = "Engine", choices = {
        {name = "Factory", price = 0}, {name = "Sport ECU", price = 850}, {name = "Club ECU", price = 1450},
    }},
    {key = "brakes", name = "Brakes", choices = {
        {name = "Factory", price = 0}, {name = "Sport pads", price = 525}, {name = "Track pads", price = 840},
    }},
    {key = "tires", name = "Tires", choices = {
        {name = "Factory", price = 0}, {name = "Touring", price = 510}, {name = "Summer", price = 825},
    }},
    {key = "suspension", name = "Suspension", choices = {
        {name = "Factory", price = 0}, {name = "Touring", price = 425}, {name = "Sport", price = 680},
    }},
    {key = "gearing", name = "Final drive", choices = {
        {name = "Factory", price = 0}, {name = "Short", price = 480}, {name = "Long", price = 480},
    }},
}

local byKey = {}
for _, item in Tuning.options do byKey[item.key] = item end
Tuning.byKey = byKey

function Tuning.clean(raw)
    local build = {}
    if type(raw) ~= "table" then return build end
    for key, category in byKey do
        local index = raw[key]
        if type(index) == "number" and index > 1 and index <= #category.choices and index == math.floor(index) then
            build[key] = index
        end
    end
    return build
end

function Tuning.config(factory, raw)
    local spec = Tuning.clean(raw)
    local config = table.clone(factory)
    if spec.engine then config.acceleration *= spec.engine == 2 and 1.10 or 1.19 end
    if spec.brakes then config.brake *= spec.brakes == 2 and 1.13 or 1.26 end
    if spec.tires then config.grip *= spec.tires == 2 and 1.07 or 1.15 end
    if spec.suspension == 2 then
        config.spring *= 1.12
        config.damping *= 0.96
    elseif spec.suspension == 3 then
        config.spring *= 0.90
        config.damping *= 1.03
    end
    if spec.gearing then
        local ratio = spec.gearing == 2 and 1.12 or 0.90
        config.finalDrive = (config.finalDrive or 4.12) * ratio
        config.acceleration *= ratio ^ 0.62
        config.topSpeed *= spec.gearing == 2 and 0.95 or 1.05
    end
    if spec.paint then config.color = byKey.paint.choices[spec.paint].color end
    if spec.wheels then config.wheelColor = byKey.wheels.choices[spec.wheels].color end
    return config
end
return Tuning
