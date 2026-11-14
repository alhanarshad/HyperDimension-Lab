local Lighting = game:GetService("Lighting")
local world = workspace.Driveline
assert(world:FindFirstChild("Test Asphalt"), "Expected the existing proving ground")
local city = Instance.new("Folder")
city.Name = "FoundryDistrict"
local rng = Random.new(42821)
local p = {
    asphalt = Color3.fromRGB(54, 62, 68), concrete = Color3.fromRGB(155, 151, 138),
    curb = Color3.fromRGB(181, 179, 163), paint = Color3.fromRGB(227, 230, 216),
    amber = Color3.fromRGB(237, 175, 76), steel = Color3.fromRGB(58, 76, 80),
    glass = Color3.fromRGB(81, 120, 130), soil = Color3.fromRGB(107, 123, 91),
    mint = Color3.fromRGB(127, 239, 192), warm = Color3.fromRGB(255, 216, 158),
}

local function part(parent, name, size, position, color, material, collides)
    local item = Instance.new("Part")
    item.Name, item.Size, item.Anchored = name, size, true
    item.Color, item.Material = color, material or Enum.Material.SmoothPlastic
    item.CFrame = typeof(position) == "CFrame" and position or CFrame.new(position)
    item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    item.CanCollide, item.CanTouch = collides ~= false, false
    item.CanQuery = item.CanCollide
    item.CastShadow = item.CanCollide
    item.Parent = parent
    return item
end

local function flat(parent, name, x, z, w, l, level, color, material, collision)
    return part(parent, name, Vector3.new(w, 0.10, l), Vector3.new(x, level - 0.05, z),
        color, material, collision)
end

local function letter(parent, text, face, tint)
    local ui = Instance.new("SurfaceGui", parent)
    ui.Name, ui.Face, ui.SizingMode = "Sign", face, Enum.SurfaceGuiSizingMode.PixelsPerStud
    ui.PixelsPerStud, ui.LightInfluence, ui.MaxDistance = 16, 0.35, 260
    local label = Instance.new("TextLabel", ui)
    label.Size, label.BackgroundTransparency, label.TextScaled = UDim2.fromScale(1, 1), 1, true
    label.TextColor3, label.Font, label.Text = tint, Enum.Font.GothamBold, text
    local padding = Instance.new("UIPadding", label)
    padding.PaddingLeft, padding.PaddingRight = UDim.new(0.06, 0), UDim.new(0.06, 0)
end

local function tree(parent, x, z, scale)
    local y = scale or 1
    part(parent, "Tree trunk", Vector3.new(0.67, 6, 0.67) * y, Vector3.new(x, 3 * y, z),
        Color3.fromRGB(97, 85, 68), Enum.Material.Wood, false)
    for n = 1, 3 do
        local canopy = part(parent, "Tree crown", Vector3.new(7.1, 8.6, 7.1) * y,
            Vector3.new(x + (n - 2) * 1.75 * y, (7.2 + n * 0.6) * y, z + n % 2 * 1.6),
            Color3.fromRGB(47 + n * 10, 83 + n * 8, 72 + n * 2), Enum.Material.Grass, false)
        canopy.Shape, canopy.CastShadow = Enum.PartType.Ball, true
    end
end

local function lamp(parent, x, z, angle, emits)
    local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, angle, 0)
    part(parent, "Lamp standard", Vector3.new(0.48, 13.6, 0.48), cf * CFrame.new(0, 6.8, 0), p.steel, Enum.Material.Metal)
    part(parent, "Lamp arm", Vector3.new(0.35, 0.35, 3.6), cf * CFrame.new(0, 13.4, -1.7), p.steel, Enum.Material.Metal, false)
    local head = part(parent, "Street lamp", Vector3.new(1.03, 0.27, 1.69),
        cf * CFrame.new(0, 13.2, -3.45), p.warm, Enum.Material.Neon, false)
    if emits then
        local point = Instance.new("SpotLight", head)
        point.Face, point.Range, point.Angle, point.Brightness = Enum.NormalId.Bottom, 23, 90, 0.87
        point.Color = p.warm
    end
end

local asphalt = Instance.new("Folder", city)
asphalt.Name = "StreetNetwork"
local grid = {-260, 0, 260}
local streetWidth, limits = 44, 370
flat(asphalt, "Subgrade", 0, 0, 920, 912, -0.10, p.soil, Enum.Material.Grass, true)
flat(asphalt, "District surface", 0, 0, 742, 742, -0.02, p.concrete, Enum.Material.Concrete, true)
for _, z in grid do
    flat(asphalt, "East-west arterial", 0, z, limits * 2, streetWidth, 0, p.asphalt, Enum.Material.Asphalt, true)
end
for _, x in grid do
    for index = 1, 4 do
        local a = index == 1 and -limits or grid[index - 1] + streetWidth / 2
        local b = index == 4 and limits or grid[index] - streetWidth / 2
        flat(asphalt, "North-south arterial", x, (a + b) / 2, streetWidth, b - a, 0,
            p.asphalt, Enum.Material.Asphalt, true)
    end
end

local shoulders = Instance.new("Folder", city)
shoulders.Name = "PavementAndMarkings"
local function marking(x, z, w, l, color)
    flat(shoulders, "Road paint", x, z, w, l, 0.014, color or p.paint, nil, false)
end
for _, road in grid do
    for index = 1, 4 do
        local a = index == 1 and -limits or grid[index - 1] + 24
        local b = index == 4 and limits or grid[index] - 24
        local middle, length = (a + b) / 2, b - a
        for _, side in {-1, 1} do
            marking(road + side * 0.54, middle, 0.21, length - 3, p.amber)
            marking(middle, road + side * 0.54, length - 3, 0.21, p.amber)
            for at = a + 11, b - 8, 21 do
                marking(road + side * 10.4, at, 0.19, 8)
                marking(at, road + side * 10.4, 8, 0.19)
            end
        end
    end
    for _, cross in grid do
        for _, side in {-1, 1} do
            for at = -17, 17, 4.25 do
                marking(road + at, cross + side * 24, 1.42, 3.1)
                marking(road + side * 24, cross + at, 3.1, 1.42)
            end
            marking(road, cross + side * 29, 36, 0.45)
            marking(road + side * 29, cross, 0.45, 36)
        end
    end
end
city.Parent = world
task.wait()

local palette = {
    Color3.fromRGB(171, 179, 169), Color3.fromRGB(133, 152, 146), Color3.fromRGB(173, 146, 126),
    Color3.fromRGB(183, 177, 147), Color3.fromRGB(74, 98, 110), Color3.fromRGB(124, 138, 135),
}

local function tower(parent, name, x, z, w, d, h, color, slats)
    local m = Instance.new("Model")
    m.Name = name
    part(m, "Structure", Vector3.new(w, h, d), Vector3.new(x, h / 2, z), color, Enum.Material.Concrete)
    part(m, "Stone podium", Vector3.new(w + 2, 7, d + 2), Vector3.new(x, 3.5, z),
        Color3.fromRGB(119, 122, 108), Enum.Material.Concrete)
    part(m, "Parapet", Vector3.new(w + 1.8, 1.15, d + 1.8), Vector3.new(x, h - 0.1, z), p.steel, Enum.Material.Metal)
    local window = p.glass:Lerp(color, 0.18)
    for n = 1, slats do
        local offset = n / (slats + 1) - 0.5
        for _, side in {-1, 1} do
            part(m, "Continuous glazing", Vector3.new(w / (slats + 3), h - 11, 0.16),
                Vector3.new(x + offset * w, (h + 5) / 2, z + side * (d / 2 + 0.04)), window, Enum.Material.Glass, false)
            part(m, "Continuous glazing", Vector3.new(0.16, h - 11, d / (slats + 3)),
                Vector3.new(x + side * (w / 2 + 0.04), (h + 5) / 2, z + offset * d), window, Enum.Material.Glass, false)
        end
    end
    for y = 12, h - 5, math.max(5, math.floor(h / 12)) do
        part(m, "Floor reveal", Vector3.new(w + 0.21, 0.35, d + 0.21), Vector3.new(x, y, z),
            color:Lerp(p.steel, 0.23), nil, false)
    end
    part(m, "Rooftop plant room", Vector3.new(w * 0.38, 3.9, d * 0.31),
        Vector3.new(x + w * 0.10, h + 1.95, z - d * 0.15), p.steel, Enum.Material.Metal)
    local marquee = part(m, "Entrance signage", Vector3.new(w * 0.70, 2.5, 0.22),
        Vector3.new(x, 5.3, z + d / 2 + 1.16), p.steel, nil, false)
    letter(marquee, name, Enum.NormalId.Back, p.paint)
    part(m, "Lobby glass", Vector3.new(w * 0.65, 3.7, 0.11),
        Vector3.new(x, 2.1, z + d / 2 + 1.1), p.glass:Lerp(p.warm, 0.35), Enum.Material.Glass, false)
    m.Parent = parent
end

local blocks = {
    {-130, -130, "Mercantile Row", {"HALCYON BANK", "ANCHOR HOUSE", "THE FORGE", "MERCANTILE EXCHANGE"}},
    {130, -130, "Foundry Center", {"FOUNDRY TOWER", "VANTAGE", "CALDER HOUSE", "NORTHLINE OFFICES"}},
    {130, 130, "Calder Square", {"CALDER HOTEL", "CIVIC GALLERY", "KINETIC WORKS", "FOUNDERS HALL"}},
    {-130, 130, "Motor Court", {"FOUNDRY MOTOR CLUB", "SERVICE WORKS"}},
}

for _, block in blocks do
    local x, z = block[1], block[2]
    local neighborhood = Instance.new("Folder")
    neighborhood.Name = block[3]
    part(neighborhood, "Block plinth", Vector3.new(216, 0.42, 216),
        Vector3.new(x, 0.15, z), p.curb, Enum.Material.Concrete)
    local names = block[4]
    if #names > 2 then
        for n, name in names do
            local ox, oz = n % 2 == 0 and 50 or -50, n <= 2 and -50 or 50
            tower(neighborhood, name, x + ox, z + oz, rng:NextInteger(42, 64), rng:NextInteger(42, 64),
                rng:NextInteger(34, 102), palette[rng:NextInteger(1, #palette)], 5)
        end
    else
        tower(neighborhood, names[1], -161, 119, 64, 84, 24, palette[5], 7)
        tower(neighborhood, names[2], -98, 181, 69, 47, 20, palette[3], 6)
        flat(neighborhood, "Launch forecourt", -63, 84, 78, 115, 0.45, p.asphalt, Enum.Material.Asphalt, true)
        flat(neighborhood, "Foundry Avenue driveway", -62, 22.5, 49, 12, 0.42, p.asphalt, Enum.Material.Asphalt, true)
        for index = 0, 7 do
            flat(neighborhood, "Bay striping", -67 + index * 8, 116, 0.18, 13, 0.471, p.paint, nil, false)
        end
        local sign = part(neighborhood, "Motor Court monument", Vector3.new(19, 3.1, 0.8),
            Vector3.new(-98, 2.55, 47), p.steel, Enum.Material.Metal)
        letter(sign, "MOTOR COURT", Enum.NormalId.Front, p.mint)
        letter(sign, "MOTOR COURT", Enum.NormalId.Back, p.mint)
        local awning = part(neighborhood, "Club arrival canopy", Vector3.new(24, 0.48, 13),
            Vector3.new(-110, 9.5, 103), p.steel, Enum.Material.Metal)
        for _, side in {-1, 1} do
            part(neighborhood, "Canopy column", Vector3.new(0.7, 9, 0.7), Vector3.new(-110 + side * 10.5, 4.5, 108),
                p.steel, Enum.Material.Metal)
        end
        awning.Color = Color3.fromRGB(64, 107, 108)
    end
    for _, side in {-1, 1} do
        for index = -2, 2 do
            local at = index * 37
            if #names > 2 or side == 1 or at < 10 then
                flat(neighborhood, "Planter bed", x + at, z + side * 95, 13, 7, 0.56, p.soil, Enum.Material.Grass, true)
                tree(neighborhood, x + at, z + side * 95, rng:NextNumber(0.8, 1.19))
            end
            if index ~= 0 then
                lamp(neighborhood, x + side * 103, z + at, side == -1 and math.pi / 2 or -math.pi / 2, index % 2 == 0)
            end
        end
    end
    neighborhood.Parent = city
    task.wait()
end

local civic = Instance.new("Folder")
civic.Name = "StreetFurniture"
for _, x in grid do
    for _, z in grid do
        for _, side in {-1, 1} do
            local cf = CFrame.new(x + side * 22.8, 0, z + side * 31) * CFrame.Angles(0, side < 0 and 0 or math.pi, 0)
            part(civic, "Signal pole", Vector3.new(0.25, 13.6, 0.25), cf * CFrame.new(0, 6.8, 0), p.steel, Enum.Material.Metal)
            part(civic, "Signal arm", Vector3.new(10.4, 0.26, 0.25), cf * CFrame.new(5.1, 12, 0), p.steel, Enum.Material.Metal, false)
            local box = part(civic, "Signal housing", Vector3.new(0.85, 2.55, 0.52),
                cf * CFrame.new(9.9, 11.65, 0), p.steel, nil, false)
            for n, color in {Color3.fromRGB(186, 47, 41), p.amber, p.mint} do
                local lens = part(civic, "Signal lens", Vector3.new(0.48, 0.48, 0.12),
                    box.CFrame * CFrame.new(0, 1.44 - n * 0.72, -0.30), color,
                    n == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic, false)
                if n < 3 then lens.Color = color:Lerp(p.steel, 0.54) end
            end
        end
    end
end

local function direction(x, z, text, rotation)
    local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, rotation, 0)
    part(civic, "Wayfinding post", Vector3.new(0.23, 9, 0.23), cf * CFrame.new(0, 4.5, 0), p.steel, Enum.Material.Metal)
    local plate = part(civic, "Wayfinding", Vector3.new(17, 2.55, 0.24), cf * CFrame.new(0, 7.9, 0),
        Color3.fromRGB(22, 78, 77), Enum.Material.Metal, false)
    letter(plate, text, Enum.NormalId.Front, p.paint)
    letter(plate, text, Enum.NormalId.Back, p.paint)
end
direction(-23, 46, "FOUNDRY AVENUE", 0)
direction(23, -46, "MERCANTILE ROW", math.pi)
direction(232, 46, "CALDER SQUARE", 0)
direction(-232, -46, "MOTOR COURT", math.pi)

for _, side in {-1, 1} do
    for n = 1, 7 do
        local at = -335 + n * 83
        local h = rng:NextInteger(18, 37)
        local offset = 310 + rng:NextInteger(-6, 12)
        tower(civic, "Perimeter loft", at, side * offset, rng:NextInteger(26, 38), 36, h,
            palette[rng:NextInteger(1, #palette)], 3)
    end
end
for _, side in {-1, 1} do
    local at = side * 371
    for _, road in grid do
        part(civic, "District boundary barrier", Vector3.new(45, 1.6, 1.5),
            Vector3.new(road, 0.8, at), p.curb, Enum.Material.Concrete)
        part(civic, "District boundary barrier", Vector3.new(1.5, 1.6, 45),
            Vector3.new(at, 0.8, road), p.curb, Enum.Material.Concrete)
    end
end
civic.Parent = city
task.wait()

world["Test Asphalt"]:Destroy()
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
    baseplate.Transparency, baseplate.CanCollide, baseplate.CanQuery, baseplate.CanTouch = 1, false, false, false
end
world.Launch.CFrame = CFrame.new(-67, 2.52, 97)
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
spawn.CFrame = CFrame.new(-71.6, 0.54, 97)
Lighting.ClockTime, Lighting.GeographicLatitude = 16.25, 34
Lighting.Brightness, Lighting.ExposureCompensation = 2.05, 0.13
Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(90, 106, 111), Color3.fromRGB(128, 137, 140)
Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.67, 0.88
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atmosphere.Density, atmosphere.Haze, atmosphere.Glare = 0.26, 1.13, 0.12
atmosphere.Color, atmosphere.Decay = Color3.fromRGB(204, 224, 232), Color3.fromRGB(149, 162, 171)
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
bloom.Intensity, bloom.Size, bloom.Threshold = 0.18, 19, 1.65
local focus = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if focus then focus.Enabled = false end
local camera = workspace.CurrentCamera
local subject = Vector3.new(-32, 0, 50)
camera.CFrame = CFrame.lookAt(Vector3.new(-189, 128, 235), subject)
camera.Focus = CFrame.new(subject)
return "Foundry District installed with " .. #city:GetDescendants() .. " instances"
