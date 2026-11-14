local world = workspace.Driveline
local cities, heads = world.InternationalDistricts, world.Trailheads
local network = world.Frontier["International Expressway"]
local color = Color3.fromRGB
local road = color(51, 58, 64)
local ivory = color(224, 220, 202)
local rng = Random.new(18205)

local function block(parent, name, size, pivot, tint, material, collision)
    local part = Instance.new("Part")
    part.Name, part.Anchored, part.Size, part.CFrame = name, true, size, pivot
    part.Color, part.Material, part.CanCollide = tint, material, collision
    part.CanQuery, part.CanTouch, part.CastShadow = collision, false, collision
    part.Parent = parent
    return part
end

local function at(parent, name, x, y, z, w, h, d, tint, material, collision)
    return block(parent, name, Vector3.new(w, h, d), CFrame.new(x, y, z), tint, material, collision)
end

local function street(parent, a, b, width, lines)
    local cf = CFrame.lookAt((a + b) / 2 - Vector3.yAxis * 0.45, b - Vector3.yAxis * 0.45)
    local length = (a - b).Magnitude
    block(parent, "Asphalt", Vector3.new(width, 1, length + 0.2), cf, road, Enum.Material.Asphalt, true)
    if lines then
        for _, side in {-1, 1} do
            block(parent, "Road shoulder paint", Vector3.new(0.24, 0.03, length),
                cf * CFrame.new(side * (width / 2 - 1.6), 0.53, 0), ivory, Enum.Material.SmoothPlastic, false)
        end
        for offset = 15, length - 12, 25 do
            block(parent, "Center paint", Vector3.new(0.24, 0.03, 10),
                cf * CFrame.new(0, 0.53, offset - length / 2), ivory, Enum.Material.SmoothPlastic, false)
        end
    end
end

local function sign(parent, caption, x, y, z, width)
    local plate = at(parent, "Direction sign", x, y, z, width, 4.4, 0.4, color(34, 72, 84), Enum.Material.Metal, false)
    for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
        local ui = Instance.new("SurfaceGui", plate)
        ui.Face, ui.MaxDistance = face, 375
        local text = Instance.new("TextLabel", ui)
        text.Size, text.BackgroundTransparency, text.TextScaled = UDim2.fromScale(1, 1), 1, true
        text.Text, text.TextColor3, text.Font = caption, ivory, Enum.Font.GothamBold
    end
end

local function route(label, a, b)
    local highway = Instance.new("Folder", network)
    highway.Name = label
    local pieces = math.ceil((a - b).Magnitude / 325)
    for i = 1, pieces do
        local start, finish = a:Lerp(b, (i - 1) / pieces), a:Lerp(b, i / pieces)
        local cf = CFrame.lookAt((start + finish) / 2, finish)
        block(highway, "Expressway deck", Vector3.new(58, 6.2, (start - finish).Magnitude + 0.4),
            cf * CFrame.new(0, -3.4, 0), color(100, 102, 100), Enum.Material.Concrete, true)
        street(highway, start, finish, 48, true)
        for _, side in {-1, 1} do
            block(highway, "Guardrail", Vector3.new(0.5, 2.5, (start - finish).Magnitude + 0.1),
                cf * CFrame.new(27.4 * side, 1.14, 0), color(129, 137, 141), Enum.Material.Metal, true)
        end
        if i % 4 == 0 then task.wait() end
    end
end

local function landmark(parent, tokyo, x, z)
    local model = Instance.new("Model", parent)
    model.Name = tokyo and "Tokyo Tower" or "Empire State Building"
    if tokyo then
        local red = color(184, 74, 52)
        local heights = {{0, 103}, {260, 59}, {490, 37}, {820, 14}, {938, 9}, {1010, 4}}
        for n = 2, #heights do
            local a, b = heights[n - 1], heights[n]
            for _, sx in {-1, 1} do
                for _, sz in {-1, 1} do
                    local low = Vector3.new(x + sx * a[2], a[1], z + sz * a[2])
                    local high = Vector3.new(x + sx * b[2], b[1], z + sz * b[2])
                    local brace = Vector3.new(x - sx * b[2], b[1], z + sz * b[2])
                    block(model, "Tower leg", Vector3.new(6, 6, (low - high).Magnitude),
                        CFrame.lookAt((low + high) / 2, high), n % 2 == 0 and red or ivory, Enum.Material.Metal, true)
                    block(model, "Diagonal tower brace", Vector3.new(2.3, 2.3, (low - brace).Magnitude),
                        CFrame.lookAt((low + brace) / 2, brace), red, Enum.Material.Metal, false)
                end
            end
        end
        at(model, "Main deck", x, 490, z, 84, 23, 84, ivory, Enum.Material.Metal, true)
        at(model, "Upper deck", x, 820, z, 32, 11, 32, red, Enum.Material.Metal, true)
        at(model, "Antenna mast", x, 1051.5, z, 3, 83, 3, red, Enum.Material.Metal, false)
    else
        local stone = color(152, 144, 123)
        local shapes = {{124, 160, 285}, {117, 127, 575}, {96, 98, 910}, {72, 74, 1025}, {39, 48, 1090}, {21, 27, 1250}}
        local lower = 0
        for index, s in shapes do
            local h = s[3] - lower
            at(model, "Setback tower section", x, lower + h / 2, z, s[1], h, s[2], stone, Enum.Material.Limestone, true)
            for n = 1, 11 do
                for _, side in {-1, 1} do
                    local tx = x + (n / 12 - 0.5) * s[1]
                    at(model, "Vertical window line", tx, lower + h / 2, z + side * s[2] / 2,
                        math.max(s[1] / 37, 0.22), h - 4, 0.8, color(75, 89, 94), Enum.Material.Glass, false)
                end
            end
            at(model, "Cornice", x, s[3] - 5, z, s[1] + 2, 3, s[2] + 2, ivory, Enum.Material.Concrete, false)
            lower = s[3]
        end
        at(model, "Broadcast mast", x, 1352, z, 4, 204, 4, ivory, Enum.Material.Metal, false)
    end
end

route("Dubai–Tokyo Highway", Vector3.new(693, 0, 3070), Vector3.new(5496, 0, 3070))
route("Paris–Manhattan Highway", Vector3.new(-694, 0, -2600), Vector3.new(-5726, 0, -2600))
for _, loc in {{id = "Tokyo", x = 6160, z = 3070}, {id = "Manhattan", x = -6390, z = -2600}} do
    local tokyo, x, z = loc.id == "Tokyo", loc.x, loc.z
    local city = Instance.new("Folder", cities)
    city.Name = loc.id
    at(city, "District foundation", x, -3.3, z, 1390, 6.4, 1144, color(118, 119, 106), Enum.Material.Concrete, true)
    for _, dx in {-512, -256, 0, 256, 512} do
        street(city, Vector3.new(x + dx, 0, z - 548), Vector3.new(x + dx, 0, z + 548), dx == 0 and 44 or 31, true)
    end
    for _, dz in {-512, -256, 0, 256, 512} do
        street(city, Vector3.new(x - 676, 0, z + dz), Vector3.new(x + 676, 0, z + dz), dz == 0 and 48 or 31, true)
    end
    local spawnX = x + (tokyo and -610 or 588)
    at(city, "Arrival court", spawnX + 10, -0.11, z + 68, 98, 0.49, 94, road, Enum.Material.Asphalt, true)
    local arrival = at(heads, loc.id, spawnX - 24, 3.1, z + 41, 1, 1, 1, ivory, Enum.Material.SmoothPlastic, false)
    arrival.Transparency = 1
    sign(city, tokyo and "TOKYO" or "MANHATTAN", spawnX + 18, 6.8, z + 110, 28)
    landmark(city, tokyo, x + 123, z - 130)

    for col, dx in {-615, -385, -128, 128, 385, 615} do
        local blockGroup = Instance.new("Folder")
        blockGroup.Name = "Avenue block " .. col
        for row, dz in {-382, -129, 129, 382} do
            local skip = (tokyo and col == 1 or not tokyo and col == 6) and row == 3
            if skip then continue end
            local w = (col == 1 or col == 6) and 128 or 213
            at(blockGroup, "Sidewalk", x + dx, 0.02, z + dz, w, 0.42, 216,
                color(151, 147, 137), Enum.Material.Concrete, true)
            if col == 4 and row == 2 then continue end
            for n = 1, 3 do
                local bx = x + dx + (n - 2) * w * 0.29
                local bz = z + dz + (n == 2 and 40 or -24)
                local height = rng:NextInteger(tokyo and 33 or 52, tokyo and 169 or 230)
                local width, depth = rng:NextInteger(28, 44), rng:NextInteger(31, 66)
                local tint = tokyo and color(90, 112, 120):Lerp(ivory, rng:NextNumber(0.1, 0.55))
                    or color(102, 111, 112):Lerp(ivory, rng:NextNumber(0.2, 0.65))
                at(blockGroup, "Building", bx, height / 2, bz, width, height, depth, tint, Enum.Material.Concrete, true)
                for slot = 1, 5 do
                    for _, side in {-1, 1} do
                        at(blockGroup, "Glazing strip", bx + (slot / 6 - 0.5) * width, (height + 4) / 2,
                            bz + side * (depth / 2 + 0.06), width / 11, height - 9, 0.2,
                            color(62, 98, 116), Enum.Material.Glass, false)
                    end
                end
                for floor = 9, height - 2, 11 do
                    at(blockGroup, "Floor band", bx, floor, bz, width + 0.32, 0.27, depth + 0.32, tint,
                        Enum.Material.Metal, false)
                end
                if tokyo then
                    local accent = ({color(191, 98, 96), color(95, 172, 177), color(236, 197, 116)})[n]
                    at(blockGroup, "Shop light strip", bx, 6, bz + depth / 2 + 0.14, width * 0.71, 0.89, 0.22,
                        accent, Enum.Material.Neon, false)
                end
            end
        end
        blockGroup.Parent = city
        task.wait()
    end
end

local paris = cities.Paris["Iron Tower Promenade"]
local dubai = cities.Dubai["Downtown Spire"]
paris:ScaleTo(1083 / 195)
dubai:ScaleTo(2717 / 421.5)
local function groundLandmark(model, position)
    local old = model:GetPivot()
    local bounds, size = model:GetBoundingBox()
    local base = bounds.Position.Y - size.Y / 2
    model:PivotTo(old + Vector3.new(position.X - bounds.Position.X, -base, position.Z - bounds.Position.Z))
end
at(cities.Paris, "Iron tower gardens", 971, -2.1, -2600, 530, 4.1, 560,
    color(91, 124, 88), Enum.Material.Grass, true)
at(cities.Dubai, "Spire plaza foundation", -950, -2.1, 3070, 512, 4.1, 520,
    color(178, 169, 146), Enum.Material.Concrete, true)
street(cities.Paris, Vector3.new(689, 0, -2600), Vector3.new(871, 0, -2600), 32, true)
street(cities.Dubai, Vector3.new(-688, 0, 3070), Vector3.new(-847, 0, 3070), 32, true)
groundLandmark(paris, Vector3.new(990, 0, -2600))
groundLandmark(dubai, Vector3.new(-978, 0, 3070))
return "Tokyo and Manhattan installed; world foundations span roughly 13,940 studs east-west"
