local terrain = workspace.Terrain
local world = workspace.Driveline
assert(not world:FindFirstChild("Frontier"), "Frontier already exists")
local frontier = Instance.new("Folder", world)
frontier.Name = "Frontier"
local heads = Instance.new("Folder", world)
heads.Name = "Trailheads"
local targets = Instance.new("Folder", world)
targets.Name = "RecoveryTargets"

local desertRoute = {
    Vector3.new(355, 0, 0), Vector3.new(480, 0, 0), Vector3.new(720, 5, 0),
    Vector3.new(960, 12, -95), Vector3.new(1230, 19, -92), Vector3.new(1510, 29, 15),
    Vector3.new(1780, 44, 115), Vector3.new(2040, 32, 14), Vector3.new(2225, 25, -145),
    Vector3.new(2200, 32, -360), Vector3.new(1920, 27, -470), Vector3.new(1730, 31, -360),
    Vector3.new(1510, 30, -220), Vector3.new(1230, 19, -92),
}
local ridgeRoute = {
    Vector3.new(-355, 0, 0), Vector3.new(-490, 0, 0), Vector3.new(-665, 11, -35),
    Vector3.new(-815, 28, -102), Vector3.new(-950, 48, -265), Vector3.new(-1100, 66, -365),
    Vector3.new(-1320, 88, -410), Vector3.new(-1490, 108, -543), Vector3.new(-1460, 124, -723),
    Vector3.new(-1660, 150, -840), Vector3.new(-1930, 178, -884), Vector3.new(-2060, 196, -1000),
    Vector3.new(-2000, 216, -1110), Vector3.new(-1810, 226, -1150),
}
local regions = {
    {name = "Red Basin", minX = 368, maxX = 2416, minZ = -704, maxZ = 704, route = desertRoute,
        pitch = 16, natural = Enum.Material.Sand, roadway = Enum.Material.Ground},
    {name = "Pine Divide", minX = -2256, maxX = -368, minZ = -1264, maxZ = 752, route = ridgeRoute,
        pitch = 19, natural = Enum.Material.Grass, roadway = Enum.Material.Asphalt},
}

local function nearRoute(x, z, route)
    local best, height = math.huge, 0
    for i = 2, #route do
        local a, b = route[i - 1], route[i]
        local dx, dz = b.X - a.X, b.Z - a.Z
        local t = math.clamp(((x - a.X) * dx + (z - a.Z) * dz) / (dx * dx + dz * dz), 0, 1)
        local ex, ez = x - (a.X + t * dx), z - (a.Z + t * dz)
        local distance = ex * ex + ez * ez
        if distance < best then
            best, height = distance, a.Y + (b.Y - a.Y) * t
        end
    end
    return math.sqrt(best), height
end

local function sample(x, z, area)
    local distance, road = nearRoute(x, z, area.route)
    local mountain = area.name == "Pine Divide"
    local fringe = math.clamp((math.abs(x) - 407) / 270, 0, 1)
    local rough = math.noise(x / 267, z / 303, 4.7) * (mountain and 82 or 31)
        + math.noise(x / 90, z / 72, 7.3) * (mountain and 23 or 7)
    local height
    if mountain then
        local rise = math.clamp((-x - 490) / 1350, 0, 1)
        local ridge = 96 * math.exp(-((z + 728 + (x + 1600) * 0.17) / 475)^2)
        local summit = 153 * math.exp(-((x + 1690) / 410)^2 - ((z + 645) / 365)^2)
        height = rise * (81 + ridge + summit) + rough
    else
        local dune = (1 + math.sin(x * 0.017 + z * 0.013 + math.noise(x / 316, z / 250, 8) * 2.7)) / 2
        local mesa = 69 * math.exp(-((x - 1690) / 278)^2 - ((z + 550) / 196)^2)
        height = 5 + dune ^ 2 * 27 + mesa + rough
    end
    height *= fringe
    local width = math.clamp((distance - area.pitch) / (mountain and 62 or 38), 0, 1)
    width = width^2 * (3 - 2 * width)
    height = road * (1 - width) + height * width
    local material = distance < area.pitch and area.roadway or area.natural
    if distance > area.pitch + 9 and mountain then
        if height > 226 then material = Enum.Material.Snow
        elseif height > 165 or math.noise(x / 97, z / 113, 11) > 0.34 then material = Enum.Material.Rock end
    elseif distance > area.pitch + 12 and not mountain then
        if height > 53 then material = Enum.Material.Sandstone
        elseif height < 4 and math.noise(x / 91, z / 116, 3.2) < -0.20 then material = Enum.Material.Mud end
    end
    return height, material, distance
end

-- Paint in bounded chunks so Studio yields between voxel writes.
local function tile(area, x0, z0, x1, z1)
    local cols = {}
    local minH, maxH = math.huge, -math.huge
    for x = x0 + 2, x1 - 2, 4 do
        local col = {}
        for z = z0 + 2, z1 - 2, 4 do
            local height, material = sample(x, z, area)
            table.insert(col, {height, material})
            minH, maxH = math.min(minH, height), math.max(maxH, height)
        end
        table.insert(cols, col)
    end
    local y0, y1 = (math.floor(minH / 4) - 3) * 4, (math.ceil(maxH / 4) + 1) * 4
    local layers = (y1 - y0) / 4
    local mats, fills = table.create(#cols), table.create(#cols)
    for xi, col in cols do
        local m, f = table.create(layers), table.create(layers)
        for yi = 1, layers do
            local rowM, rowF = table.create(#col), table.create(#col)
            local floor = y0 + (yi - 1) * 4
            for zi, c in col do
                local fill = math.clamp((c[1] - floor) / 4, 0, 1)
                rowM[zi], rowF[zi] = fill > 0 and c[2] or Enum.Material.Air, fill
            end
            m[yi], f[yi] = rowM, rowF
        end
        mats[xi], fills[xi] = m, f
    end
    terrain:WriteVoxels(Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1)), 4, mats, fills)
end

local function makePart(parent, name, size, cf, color, material, collision)
    local part = Instance.new("Part")
    part.Name, part.Size, part.CFrame = name, size, cf
    part.Anchored, part.CanCollide, part.CanTouch = true, collision, false
    part.CanQuery, part.CastShadow = collision, collision
    part.Color, part.Material = color, material
    part.Parent = parent
    return part
end

local function sign(parent, caption, x, y, z, angle)
    local post = Color3.fromRGB(55, 66, 69)
    local cf = CFrame.new(x, y, z) * CFrame.Angles(0, angle, 0)
    makePart(parent, "Sign post", Vector3.new(0.6, 9, 0.6), cf * CFrame.new(0, 4.5, 0), post, Enum.Material.Metal, true)
    local board = makePart(parent, "Trail sign", Vector3.new(23, 3.6, 0.45), cf * CFrame.new(0, 8.5, 0),
        Color3.fromRGB(49, 89, 74), Enum.Material.Metal, false)
    for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
        local surface = Instance.new("SurfaceGui", board)
        surface.Face, surface.MaxDistance = face, 440
        local label = Instance.new("TextLabel", surface)
        label.Text, label.TextScaled, label.Font = caption, true, Enum.Font.GothamBold
        label.TextColor3, label.Size = Color3.fromRGB(237, 227, 192), UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
    end
end

local function apron(parent, name, x, y, z, width, length)
    return makePart(parent, name, Vector3.new(width, 1.25, length), CFrame.new(x, y - 0.625, z),
        Color3.fromRGB(74, 79, 78), Enum.Material.Asphalt, true)
end

local function marker(parent, name, cf, id)
    local marker = makePart(parent, name, Vector3.one, cf, Color3.new(), Enum.Material.SmoothPlastic, false)
    marker.Transparency = 1
    if id then marker:SetAttribute("VehicleId", id) end
    return marker
end

local rng = Random.new(47173)
for _, area in regions do
    local place = Instance.new("Folder", frontier)
    place.Name = area.name
    for x = area.minX, area.maxX - 1, 256 do
        for z = area.minZ, area.maxZ - 1, 256 do
            tile(area, x, z, math.min(x + 256, area.maxX), math.min(z + 256, area.maxZ))
        end
        task.wait()
    end
    local mountain = area.name == "Pine Divide"
    local x = mountain and -555 or 535
    local y = mountain and 4.3 or 4.4
    apron(place, "Trailhead apron", x, y, 29, 83, 84)
    apron(place, "City road seam", mountain and -402 or 402, 0.23, 0, 69, 36)
    local maxX = mountain and -499 or 479
    local ramp = CFrame.new(maxX, y * 0.52, 28) * CFrame.Angles(0, 0, mountain and -0.056 or 0.056)
    makePart(place, "Trailhead approach", Vector3.new(96, 1.1, 23), ramp, Color3.fromRGB(76, 82, 79), Enum.Material.Asphalt, true)
    local lead = CFrame.new(x - 24, y + 3.2, 5)
    marker(heads, mountain and "Mountain" or "Desert", lead)
    marker(targets, mountain and "Recovery Truck" or "Recovery Car", CFrame.new(x - 24, y + 3.0, 35),
        mountain and "Ridgeway" or "Aster")
    sign(place, mountain and "PINE DIVIDE" or "RED BASIN", x + 27, y, -16, math.pi / 2)

    for i = 4, #area.route - 1 do
        local point = area.route[i]
        sign(place, mountain and (i == #area.route - 1 and "SUMMIT OVERLOOK" or "PINE DIVIDE")
            or (i == 8 and "BASIN LOOP" or "RED BASIN"),
            point.X, point.Y + 0.25, point.Z + 23, mountain and math.pi / 3 or -math.pi / 3)
    end
    for _ = 1, mountain and 190 or 78 do
        local tx, tz = rng:NextNumber(area.minX + 65, area.maxX - 65), rng:NextNumber(area.minZ + 44, area.maxZ - 44)
        local ty, material, distance = sample(tx, tz, area)
        if distance < 36 or math.abs(tx - x) < 79 and math.abs(tz - 29) < 66 then continue end
        if mountain and material == Enum.Material.Grass then
            local height = rng:NextNumber(10, 25)
            makePart(place, "Pine trunk", Vector3.new(0.8, height * 0.77, 0.8),
                CFrame.new(tx, ty + height * 0.33, tz), Color3.fromRGB(88, 77, 67), Enum.Material.Wood, false)
            for i = 1, 3 do
                local width = height * (0.54 - 0.082 * i)
                local cone = makePart(place, "Pine bough", Vector3.new(width, height * 0.43, width),
                    CFrame.new(tx, ty + height * (0.26 + i * 0.20), tz), Color3.fromRGB(43 + 6 * i, 72 + 5 * i, 61),
                    Enum.Material.Grass, false)
                cone.Shape = Enum.PartType.Ball
            end
        elseif distance < 200 then
            local size = rng:NextNumber(1.8, 7)
            local rock = makePart(place, mountain and "Granite drift" or "Sandstone outcrop", Vector3.new(size, size * 0.6, size * 0.75),
                CFrame.new(tx, ty + size * 0.15, tz) * CFrame.Angles(0.27, rng:NextNumber(0, math.pi), -0.14),
                mountain and Color3.fromRGB(116, 119, 119) or Color3.fromRGB(156, 101, 65),
                mountain and Enum.Material.Rock or Enum.Material.Sandstone, true)
            rock.Shape = Enum.PartType.Ball
        end
    end
    task.wait()
end

for _, item in world.FoundryDistrict.StreetFurniture:GetChildren() do
    if item:IsA("Part") and item.Name == "District boundary barrier" and math.abs(item.Position.X) > 360
        and math.abs(item.Position.Z) < 1 then item:Destroy() end
end
for _, x in {-555, 535} do
    terrain:FillBlock(CFrame.new(x, 15, 31), Vector3.new(80, 110, 79), Enum.Material.Air)
end
sign(frontier, "RED BASIN EAST", 343, 0, -22.5, -math.pi / 2)
sign(frontier, "PINE DIVIDE WEST", -343, 0, 22.5, math.pi / 2)
return "Frontier installed: city to desert and mountain, 4672 studs east-west"
