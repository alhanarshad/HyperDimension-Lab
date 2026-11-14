local world = workspace.Driveline
local frontier = assert(world:FindFirstChild("Frontier"))
local heads = assert(world:FindFirstChild("Trailheads"))
local cities = Instance.new("Folder", world)
cities.Name = "InternationalDistricts"
local Color = Color3.fromRGB
local asphalt, pavement, steel, white = Color(54, 61, 67), Color(177, 167, 148), Color(47, 63, 68), Color(241, 235, 216)
local glass = Color(65, 111, 136)
local rng = Random.new(67129)

local function part(parent, name, size, transform, color, material, collision)
    local item = Instance.new("Part")
    item.Name, item.Size, item.CFrame = name, size, typeof(transform) == "Vector3" and CFrame.new(transform) or transform
    item.Color, item.Material = color, material
    item.Anchored, item.CanCollide, item.CanTouch = true, collision, false
    item.CanQuery, item.CastShadow = collision, collision
    item.Parent = parent
    return item
end
local function block(parent, name, x, y, z, w, h, d, color, material, collision)
    return part(parent, name, Vector3.new(w, h, d), Vector3.new(x, y, z), color, material, collision)
end
local function sign(parent, caption, x, y, z, width)
    local panel = block(parent, "Destination sign", x, y, z, width, 4.2, 0.4, Color(26, 74, 77), Enum.Material.Metal, false)
    for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
        local ui = Instance.new("SurfaceGui", panel)
        ui.Face, ui.MaxDistance = face, 400
        local text = Instance.new("TextLabel", ui)
        text.BackgroundTransparency, text.TextScaled, text.TextColor3 = 1, true, white
        text.Size, text.Text, text.Font = UDim2.fromScale(1, 1), caption, Enum.Font.GothamBold
    end
end
local function arrival(id, x, z)
    local node = block(heads, id, x, 3.2, z, 1, 1, 1, white, Enum.Material.SmoothPlastic, false)
    node.Transparency = 1
end
local function street(parent, x, z, x2, z2, width)
    local a, b = Vector3.new(x, -0.46, z), Vector3.new(x2, -0.46, z2)
    local cf = CFrame.lookAt((a + b) / 2, b)
    local length = (b - a).Magnitude
    part(parent, "Carriageway", Vector3.new(width, 1, length + 0.2), cf, asphalt, Enum.Material.Asphalt, true)
    for _, side in {-1, 1} do
        part(parent, "Edge line", Vector3.new(0.24, 0.035, length), cf * CFrame.new(side * (width / 2 - 2), 0.528, 0),
            white, Enum.Material.SmoothPlastic, false)
        part(parent, "Center divider", Vector3.new(0.20, 0.04, length), cf * CFrame.new(side * 0.42, 0.528, 0),
            Color(241, 179, 83), Enum.Material.SmoothPlastic, false)
    end
    if width >= 32 then
        for dist = -length / 2 + 12, length / 2 - 9, 27 do
            for _, side in {-1, 1} do
                part(parent, "Lane dash", Vector3.new(0.20, 0.04, 11), cf * CFrame.new(side * width / 4, 0.532, dist),
                    white, Enum.Material.SmoothPlastic, false)
            end
        end
    end
end
local function garden(parent, x, z, palm)
    block(parent, "Planter", x, 0.12, z, 8, 0.54, 8, Color(116, 125, 88), Enum.Material.Grass, true)
    block(parent, "Trunk", x, palm and 6.7 or 3.7, z, 0.64, palm and 13.4 or 7.4, 0.64,
        Color(101, 84, 65), Enum.Material.Wood, false)
    if palm then
        for n = 1, 7 do
            local cf = CFrame.new(x, 13.1, z) * CFrame.Angles(0, n * math.pi * 2 / 7, 0)
            part(parent, "Palm frond", Vector3.new(1.9, 0.31, 6.8), cf * CFrame.new(0, -0.3, -2.4)
                * CFrame.Angles(-0.19, 0, 0), Color(63, 100, 75), Enum.Material.Grass, false)
        end
    else
        for n = 1, 3 do
            local ball = block(parent, "Linden crown", x + (n - 2) * 1.52, 7 + n * 0.8, z,
                6.7, 8.5, 7.4, Color(52 + n * 8, 83 + n * 8, 61), Enum.Material.Grass, false)
            ball.Shape = Enum.PartType.Ball
        end
    end
end
local function building(parent, name, x, z, w, d, h, dubai)
    local model = Instance.new("Model")
    model.Name = name
    local wall = dubai and glass:Lerp(Color(160, 185, 186), rng:NextNumber(0, 0.6))
        or white:Lerp(Color(163, 138, 110), rng:NextNumber(0.25, 0.7))
    block(model, "Building shell", x, h / 2, z, w, h, d, wall, dubai and Enum.Material.Glass or Enum.Material.Limestone, true)
    block(model, "Entrance podium", x, 2.2, z, w + 2, 4.4, d + 2, wall:Lerp(steel, 0.23), Enum.Material.Concrete, true)
    for i = 1, dubai and 9 or 5 do
        local offset = (i / ((dubai and 9 or 5) + 1) - 0.5) * w
        for _, side in {-1, 1} do
            if dubai then
                block(model, "Vertical fin", x + offset, h * 0.52, z + side * (d / 2 + 0.12),
                    0.29, h * 0.96, 0.39, Color(186, 197, 193), Enum.Material.Metal, false)
            else
                for y = 8, h - 2, 5.7 do
                    block(model, "Window recess", x + offset, y, z + side * (d / 2 + 0.07), w / 12, 2.75, 0.19, glass, Enum.Material.Glass, false)
                    block(model, "Window sill", x + offset, y - 1.5, z + side * (d / 2 + 0.17), w / 9, 0.14, 0.62, steel, Enum.Material.Metal, false)
                end
            end
        end
    end
    for y = 6, h - 1, dubai and 10 or 5.7 do
        block(model, "Floor band", x, y, z, w + 0.65, 0.29, d + 0.65, wall:Lerp(steel, 0.26), Enum.Material.Metal, false)
    end
    if dubai then
        local upper = h * rng:NextNumber(0.09, 0.20)
        block(model, "Setback crown", x, h + upper / 2, z, w * 0.58, upper, d * 0.72, wall, Enum.Material.Glass, true)
    else
        for _, side in {-1, 1} do
            part(model, "Mansard", Vector3.new(w + 1, 0.55, d * 0.54), CFrame.new(x, h + 2.6, z + side * d * 0.262)
                * CFrame.Angles(side * 0.33, 0, 0), Color(79, 92, 101), Enum.Material.Slate, false)
        end
    end
    model.Parent = parent
end

local function strut(parent, a, b, width, depth, color)
    return part(parent, "Lattice member", Vector3.new(width, depth, (b - a).Magnitude),
        CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Metal, true)
end
local function parisLandmark(parent, x, z)
    local landmark = Instance.new("Model", parent)
    landmark.Name = "Iron Tower Promenade"
    local material = Color(104, 89, 73)
    local levels = {{0, 33}, {42, 20}, {81, 12}, {135, 6}, {172, 3}}
    for i = 2, #levels do
        local bottom, top = levels[i - 1], levels[i]
        for _, sx in {-1, 1} do
            for _, sz in {-1, 1} do
                local a = Vector3.new(x + sx * bottom[2], bottom[1], z + sz * bottom[2])
                local b = Vector3.new(x + sx * top[2], top[1], z + sz * top[2])
                strut(landmark, a, b, 2.05, 2.05, material)
                local brace = Vector3.new(x - sx * top[2], top[1], z + sz * top[2])
                strut(landmark, a, brace, 0.55, 0.55, material)
                strut(landmark, b, Vector3.new(x + sx * top[2], top[1], z - sz * top[2]), 0.64, 0.64, material)
            end
        end
        if i == 2 or i == 3 then
            block(landmark, "Platform", x, top[1], z, top[2] * 2.35, 1.7, top[2] * 2.35, material, Enum.Material.Metal, true)
        end
    end
    block(landmark, "Antenna", x, 183, z, 1.2, 24, 1.2, steel, Enum.Material.Metal, false)
end
local function dubaiLandmark(parent, x, z)
    local tower = Instance.new("Model", parent)
    tower.Name = "Downtown Spire"
    for level = 0, 8 do
        local width = 60 - level * 6.6
        local y = 27.5 + level * 42
        for angle = 0, 2 do
            local cf = CFrame.new(x, y, z) * CFrame.Angles(0, angle * 2 * math.pi / 3 + level * 0.18, 0)
            part(tower, "Setback glass wing", Vector3.new(width, 55, width * 0.68),
                cf * CFrame.new(0, 0, -width * 0.31), glass:Lerp(white, level * 0.048), Enum.Material.Glass, true)
            part(tower, "Vertical metal fin", Vector3.new(0.42, 54.5, 0.62),
                cf * CFrame.new(0, 0, -width * 0.66), white, Enum.Material.Metal, false)
        end
    end
    block(tower, "Spire", x, 389, z, 1.6, 65, 1.6, white, Enum.Material.Metal, false)
end
local expressway = Instance.new("Folder", frontier)
expressway.Name = "International Expressway"
local function connector(x1, z1, x2, z2, width)
    local a = Vector3.new(x1, -1.6, z1)
    local b = Vector3.new(x2, -1.6, z2)
    local cf = CFrame.lookAt((a + b) / 2, b)
    local length = (b - a).Magnitude
    part(expressway, "Rock embankment", Vector3.new(width + 15, 2, length + 2), cf,
        Color(119, 111, 96), Enum.Material.Rock, true)
    local chunkCount = math.ceil(length / 370)
    for i = 1, chunkCount do
        local start, finish = a:Lerp(b, (i - 1) / chunkCount), a:Lerp(b, i / chunkCount)
        street(expressway, start.X, start.Z, finish.X, finish.Z, width)
        if i % 2 == 0 then task.wait() end
    end
end

for _, item in world.FoundryDistrict.StreetFurniture:GetChildren() do
    if item:IsA("Part") and item.Name == "District boundary barrier" and math.abs(item.Position.Z) > 360
        and math.abs(item.Position.X) < 1 then item:Destroy() end
end
connector(0, -365, 0, -2080, 43)
connector(0, 365, 0, 2490, 43)
arrival("Dealer", -66, 77)

for _, data in {{id = "Paris", z = -2600}, {id = "Dubai", z = 3070}} do
    local model = Instance.new("Folder")
    model.Name = data.id
    local z, dubai = data.z, data.id == "Dubai"
    block(model, "City foundation", 0, -3.4, z, 1450, 6.4, 1160, dubai and Color(204, 173, 128) or Color(103, 119, 89),
        dubai and Enum.Material.Sand or Enum.Material.Grass, true)
    for _, dx in {-480, -235, 0, 235, 480} do
        street(model, dx, z - 550, dx, z + 550, dx == 0 and 43 or 29)
    end
    for _, dz in {-510, -270, 0, 270, 510} do
        street(model, -695, z + dz, 695, z + dz, dz == 0 and 38 or 29)
    end
    local cz = z + (dubai and -375 or 365)
    block(model, "Arrival forecourt", -87, -0.05, cz, 102, 0.33, 121, asphalt, Enum.Material.Asphalt, true)
    street(model, -105, cz - 22, -19, cz - 22, 18)
    arrival(data.id, -125, cz - 10)
    sign(model, dubai and "DOWNTOWN DUBAI" or "PARIS PROMENADE", -92, 5.8, cz + 40, 38)
    model.Parent = cities
    task.wait()
    if dubai then dubaiLandmark(model, 113, z - 129) else parisLandmark(model, 118, z + 133) end
    for col, x in {-585, -355, -112, 114, 360, 586} do
        local neighborhood = Instance.new("Folder")
        neighborhood.Name = "Boulevard blocks " .. col
        for row, offset in {-393, -134, 136, 390} do
            local centerZ = z + offset
            if col == 3 and (dubai and row == 1 or not dubai and row == 4) then continue end
            local landmark = col == 4 and row == (dubai and 2 or 3)
            block(neighborhood, "Sidewalk square", x, -0.015, centerZ, 172, 0.54, 183, pavement, Enum.Material.Concrete, true)
            if not landmark then
                for n = 1, dubai and 2 or 3 do
                    local bx = x + (n % 2 == 1 and 42 or -43)
                    local bz = centerZ + (n == 3 and 38 or -22)
                    building(neighborhood, dubai and "Glass residence" or "Limestone apartments", bx, bz,
                        rng:NextInteger(35, 61), rng:NextInteger(34, 57),
                        dubai and rng:NextInteger(50, 170) or rng:NextInteger(19, 31), dubai)
                end
            end
            for _, side in {-1, 1} do
                garden(neighborhood, x + side * 67, centerZ + 74, dubai)
                garden(neighborhood, x + side * 67, centerZ - 71, dubai)
            end
        end
        neighborhood.Parent = model
        task.wait()
    end
    for _, dx in {-480, -235, 0, 235, 480} do
        for _, side in {-1, 1} do
            local boundary = z + side * 550
            if dx == 0 and side == (dubai and -1 or 1) then continue end
            block(model, "Road end protection", dx, 0.68, boundary, 44, 1.34, 1.5,
                Color(156, 149, 139), Enum.Material.Concrete, true)
        end
    end
end
sign(expressway, "PARIS NORTH", 26, 4.5, -550, 33)
sign(expressway, "DUBAI SOUTH", -26, 4.5, 560, 33)
return "Paris and Downtown Dubai linked to Foundry by drivable expressways"
