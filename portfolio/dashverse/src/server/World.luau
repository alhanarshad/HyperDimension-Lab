local Shared = game:GetService("ReplicatedStorage").Dashverse
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Models = require(Shared.Models)

local World = {}
local V = Vector3.new
local rgb = Color3.fromRGB
local concrete = Enum.Material.SmoothPlastic
local metal = Enum.Material.Metal
local neon = Enum.Material.Neon
local grass = Enum.Material.Grass
local rock = Enum.Material.Slate
local wood = Enum.Material.WoodPlanks
local ink = rgb(20, 35, 52)
local white = rgb(248, 249, 226)
local water = rgb(74, 202, 222)

local function folder(parent, name)
	local item = Instance.new("Folder")
	item.Name = name
	item.Parent = parent
	return item
end

local function piece(parent, name, size, frame, color, material, collision, shape)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = if typeof(frame) == "CFrame" then frame else CFrame.new(frame)
	item.Color = color
	item.Material = material or concrete
	item.Anchored = true
	item.CanCollide = collision ~= false
	item.CanTouch = false
	item.CanQuery = collision ~= false
	item.CastShadow = collision ~= false
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Shape = shape or Enum.PartType.Block
	item.Parent = parent
	return item
end

local function beam(parent, name, a, b, width, depth, color, material, collision)
	if (a - b).Magnitude < 0.05 then return end
	local midpoint = a:Lerp(b, 0.5)
	return piece(parent, name, V(width, depth, (a - b).Magnitude), CFrame.lookAt(midpoint, b), color, material, collision)
end

local function sign(parent, text, small, position, width, angle, color)
	local panel = piece(parent, "Sign", V(width, 5.5, 0.4), CFrame.new(position) * CFrame.Angles(0, angle or 0, 0), ink, metal, false)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 48
	surface.LightInfluence = 0
	surface.MaxDistance = 135
	surface.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.04, 0.09)
	title.Size = UDim2.fromScale(0.92, if small then 0.50 else 0.82)
	title.Font = Enum.Font.GothamBlack
	title.Text = text
	title.TextScaled = true
	title.TextColor3 = color or white
	title.Parent = surface
	if small then
		local subtitle = Instance.new("TextLabel")
		subtitle.BackgroundTransparency = 1
		subtitle.Position = UDim2.fromScale(0.05, 0.61)
		subtitle.Size = UDim2.fromScale(0.90, 0.24)
		subtitle.Font = Enum.Font.GothamMedium
		subtitle.Text = small
		subtitle.TextColor3 = white
		subtitle.TextScaled = true
		subtitle.Parent = surface
	end
end

local function prompt(anchor, action, object, kind, value, world)
	local p = Instance.new("ProximityPrompt")
	p.Name = kind
	p.ActionText = action
	p.ObjectText = object
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p:SetAttribute("Action", kind)
	p:SetAttribute("Value", value)
	p:SetAttribute("World", world)
	p.Parent = anchor
	return p
end

local function ring(parent, position, radius, sides, thickness, color, material, vertical)
	for i = 0, sides - 1 do
		local a = i / sides * 2 * math.pi
		local b = (i + 1) / sides * 2 * math.pi
		local p = if vertical then V(math.cos(a), math.sin(a), 0) else V(math.cos(a), 0, math.sin(a))
		local q = if vertical then V(math.cos(b), math.sin(b), 0) else V(math.cos(b), 0, math.sin(b))
		beam(parent, "Ring", position + p * radius, position + q * radius, thickness, thickness, color, material, false)
	end
end

local function tree(parent, pos, height, palette, seed)
	local trunk = if palette == 5 then rgb(87, 53, 61) else rgb(121, 83, 67)
	local leaf = if palette == 3 then rgb(199, 120, 165) elseif palette == 4 then rgb(108, 175, 159) else rgb(53, 135, 89)
	piece(parent, "Trunk", V(height * 0.12, height * 0.7, height * 0.12), pos + V(0, height * 0.35, 0), trunk, wood, false)
	for i = 1, 3 do
		local a = seed + i * 2.39
		local size = height * (0.67 - i * 0.085)
		local centre = pos + V(math.cos(a) * height * 0.14, height * (0.62 + i * 0.105), math.sin(a) * height * 0.13)
		piece(parent, "Canopy", V(size, size * 1.04, size), CFrame.new(centre) * CFrame.Angles(a * 0.2, a, a * 0.14),
			leaf:Lerp(rgb(174, 217, 106), i * 0.13), grass, false, Enum.PartType.Ball)
	end
end

local function crystal(parent, pos, size, color, seed)
	for i = 1, 3 do
		local h = size * (0.45 + 0.19 * i)
		local c = CFrame.new(pos + V((i - 2) * size * 0.22, h * 0.34, (i % 2) * size * 0.16))
			* CFrame.Angles(i * 0.21 - 0.25, seed + i, (i - 2) * -0.28)
		piece(parent, "Crystal face", V(h * 0.42, h, h * 0.42), c, color:Lerp(white, 0.14 * i), if i == 2 then neon else Enum.Material.Glass, false)
		piece(parent, "Crystal tip", V(h * 0.42, h * 0.29, h * 0.42), c * CFrame.new(0, h * 0.62, 0), color,
			neon, false, Enum.PartType.Wedge)
	end
end

local function crate(parent, position, size, accent)
	piece(parent, "Cargo", V(size, size, size), position, ink:Lerp(accent, 0.22), metal)
	for _, x in ipairs({-0.32, 0.32}) do
		piece(parent, "Cargo strip", V(0.14, size * 0.85, 0.12), position + V(size * x, 0, size * 0.51), accent, neon, false)
	end
end

local function bench(parent, position, accent)
	local woodColor = rgb(164, 113, 71)
	piece(parent, "Bench seat", V(7.0, 0.42, 2.4), position + V(0, 1.35, 0), woodColor, wood)
	piece(parent, "Bench back", V(7.0, 1.15, 0.37), position + V(0, 2.15, -1.03), woodColor, wood)
	for _, x in ipairs({-2.45, 2.45}) do
		piece(parent, "Bench legs", V(0.32, 1.4, 1.6), position + V(x, 0.67, 0), ink, metal)
		piece(parent, "Bench arm", V(0.35, 0.22, 1.8), position + V(x, 1.9, 0), accent, concrete, false)
	end
end

local function cabin(parent, position)
	local wall = rgb(201, 155, 104)
	local roof = rgb(55, 97, 104)
	piece(parent, "Cabin walls", V(15.3, 7.1, 11), position + V(0, 3.5, 0), wall, wood)
	for _, side in ipairs({-1, 1}) do
		local tilt = CFrame.new(position + V(side * 4.10, 8.05, 0)) * CFrame.Angles(0, 0, side * -0.38)
		piece(parent, "Cabin roof", V(9.2, 0.55, 13), tilt, roof, metal)
		local window = position + V(side * 4.72, 3.8, 5.56)
		piece(parent, "Window trim", V(2.9, 2.7, 0.32), window, white, wood, false)
		piece(parent, "Warm glass", V(2.3, 2.12, 0.12), window + V(0, 0, 0.23), rgb(247, 215, 152), neon, false)
	end
	piece(parent, "Cabin door", V(2.7, 4.2, 0.35), position + V(0, 2.1, 5.57), roof, wood, false)
	piece(parent, "Stone doorstep", V(4.7, 0.48, 2.7), position + V(0, 0.20, 6.56), rgb(143, 153, 140), rock)
end

local function pavilion(parent, label, note, p, accent, material)
	piece(parent, "Pavilion deck", V(17, 0.5, 12), p + V(0, 0.25, 0), ink:Lerp(accent, 0.20), material)
	for _, x in ipairs({-7.4, 7.4}) do
		for _, z in ipairs({-4.6, 4.6}) do
			piece(parent, "Pillar", V(0.8, 8.1, 0.8), p + V(x, 4, z), ink, material)
		end
	end
	piece(parent, "Canopy", V(17.5, 0.6, 12.5), p + V(0, 8.1, 0), ink, material)
	piece(parent, "Canopy rim", V(17.6, 0.20, 12.6), p + V(0, 8.43, 0), accent, neon, false)
	piece(parent, "Back panel", V(14, 4, 0.45), p + V(0, 3, -4.9), ink:Lerp(accent, 0.2), material, false)
	sign(parent, label, note, p + V(0, 6.0, 4.8), 14.9, 0, accent)
	return piece(parent, label, V(8, 2.1, 2), p + V(0, 1.2, 0), ink, material, false)
end

local function gantry(parent, pos, heading, caption, detail, accent, span, height)
	local frame = CFrame.lookAt(pos, pos + heading)
	for _, side in ipairs({-1, 1}) do
		local foot = frame * CFrame.new(side * span * 0.50, 0, 0)
		piece(parent, "Gate base", V(2.8, 1.25, 3.5), foot * CFrame.new(0, 0.55, 0), ink, metal)
		piece(parent, "Gate column", V(1.23, height, 1.26), foot * CFrame.new(0, height * 0.5, 0), ink, metal)
		piece(parent, "Gate light", V(0.26, height - 1, 1.3), foot * CFrame.new(side * -0.56, height * 0.5, 0), accent, neon, false)
	end
	piece(parent, "Gate lintel", V(span + 1.2, 1.15, 1.4), frame * CFrame.new(0, height, 0), ink, metal)
	piece(parent, "Gate line", V(span - 1.0, 0.12, 1.8), frame * CFrame.new(0, 0.1, 0), accent, neon, false)
	if caption then
		local _, angle = frame:ToOrientation()
		sign(parent, caption, detail, pos + V(0, height + 2.0, 0.6), span * 0.78, angle, accent)
	end
end

local function tracks(parent, world)
	local route = world.route
	for i, a in ipairs(route) do
		local b = route[i % #route + 1]
		local direction = (b - a).Unit
		local side = direction:Cross(V(0, 1, 0)).Unit
		piece(parent, "Curve", V(1.0, 18.5, 18.5), CFrame.new(a - V(0, 0.50, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			world.road, concrete, true, Enum.PartType.Cylinder)
		beam(parent, "Track", a - V(0, 0.53, 0), b - V(0, 0.53, 0), 18.5, 1.06, world.road, concrete, true)
		for _, signValue in ipairs({-1, 1}) do
			local offset = side * signValue * 8.9 + V(0, 0.08, 0)
			beam(parent, "Shoulder", a + offset, b + offset, 0.37, 0.11, world.accent, neon, false)
		end
		for j = 1, 4 do
			local centre = a:Lerp(b, j / 5) + V(0, 0.075, 0)
			beam(parent, "Lane dash", centre - direction * 1.0, centre + direction * 1.0, 0.23, 0.09, white, concrete, false)
		end
		if i > 1 then
			gantry(parent, a, direction, nil, nil, world.accent:Lerp(white, 0.2), 20, 7)
		end
	end
	local start = route[1]
	gantry(parent, start, (route[2] - start).Unit, string.upper(world.race), "RACE START  /  FINISH", world.accent, 24, 10.4)
end

local function spark(parent, pos, id, color, world, value)
	local model = Instance.new("Model")
	model.Name = "Spark " .. id
	model:SetAttribute("PickupId", id)
	model:SetAttribute("World", world)
	model:SetAttribute("Value", value)
	local core = piece(model, "Core", V(1.14, 1.14, 1.14), CFrame.new(pos) * CFrame.Angles(0.57, 0.65, 0.6), color, neon, false)
	piece(model, "Halo", V(1.88, 1.88, 1.88), CFrame.new(pos) * CFrame.Angles(0.57, 0.65, 0.6), color, Enum.Material.Glass, false).Transparency = 0.78
	model.PrimaryPart = core
	model.Parent = parent
end

local function district(parent, index, world)
	local scene = folder(parent, "Scenery")
	local ground = folder(parent, "Ground")
	local random = Random.new(413 + index * 97)
	local accent = world.accent
	local terrain = world.terrain
	local route = world.route
	local hubMaterial = if index == 1 then wood elseif index == 3 or index == 5 then rock else metal
	local hub = V(0, -1.0, 75)
	piece(ground, "Arrival plaza", V(112, 2, 76), hub, terrain:Lerp(ink, 0.15), hubMaterial)
	piece(ground, "Arrival lane", V(13, 0.16, 69), V(0, 0.05, 68), world.road, concrete)
	for _, x in ipairs({-6.4, 6.4}) do
		piece(ground, "Arrival guide", V(0.18, 0.06, 69), V(x, 0.16, 68), accent, neon, false)
	end
	for _, x in ipairs({-53, 53}) do
		for _, z in ipairs({45, 71, 98}) do
			piece(scene, "Plaza bollard", V(1, 3.0, 1), V(x, 1.5, z), ink, metal)
			piece(scene, "Bollard light", V(1.05, 0.40, 1.05), V(x, 2.87, z), accent, neon, false)
		end
	end

	if index == 1 then
		piece(ground, "Valley floor", V(385, 15, 403), V(-6, -9, -61), terrain, grass)
		for _, z in ipairs({-64, -129}) do
			local stream = piece(scene, "River", V(338, 0.42, 21), CFrame.new(0, -1.23, z) * CFrame.Angles(0, 0.17, 0), water, Enum.Material.Glass, false)
			stream.Reflectance = 0.14
			for i = 1, 14 do
				local x = -158 + i * 22
				local point = stream.CFrame:PointToWorldSpace(V(x, 0.24, random:NextNumber(-8, 8)))
				piece(scene, "Current", V(random:NextNumber(5, 16), 0.035, 0.36), CFrame.new(point) * CFrame.Angles(0, 0.17, 0), white, neon, false).Transparency = 0.48
			end
		end
		for _, p in ipairs({V(46, -0.12, -66), V(104, -0.1, -136), V(-68, -0.1, -141)}) do
			for s = -1, 1, 2 do
				for j = -2, 2 do
					piece(scene, "Bridge post", V(0.65, 2.55, 0.65), p + V(s * 10.3, 1.02, j * 3.7), rgb(161, 110, 73), wood)
				end
				piece(scene, "Bridge rail", V(0.42, 0.55, 16), p + V(s * 10.3, 1.95, 0), rgb(182, 125, 78), wood, false)
			end
		end
		local falls = V(-144, 0, -104)
		piece(scene, "Grotto west", V(17, 29, 39), CFrame.new(falls + V(-13, 11, 0)) * CFrame.Angles(0, 0.15, 0.11), rgb(83, 113, 101), rock)
		piece(scene, "Grotto east", V(9, 23, 32), CFrame.new(falls + V(3, 10, -13)) * CFrame.Angles(0, -0.25, -0.13), rgb(93, 121, 106), rock)
		for j = 0, 5 do
			local sheet = piece(scene, "Waterfall", V(0.30, 24 - j * 0.75, 1.65), falls + V(8.8 + j * 0.16, 10.2, -10 + j * 1.55), water:Lerp(white, j * 0.11), Enum.Material.Glass, false)
			sheet.Transparency = 0.20 + (j % 2) * 0.18
			piece(scene, "Foam", V(2.4, 0.27, 3.6), falls + V(10.5, -0.7, -10 + j * 1.55), white, neon, false, Enum.PartType.Ball)
		end
		for i = 1, 26 do
			local side = if i % 2 == 0 then -1 else 1
			local x = side * random:NextNumber(115, 178)
			local z = random:NextNumber(-248, 115)
			if math.abs(x + 131) > 15 or math.abs(z + 100) > 20 then
				tree(scene, V(x, -1.45, z), random:NextNumber(10, 25), index, i)
			end
		end
		for _, p in ipairs({V(-44, 0, 76), V(41, 0, 87), V(45, -1, 22), V(-54, -1, 11), V(25, -1, -48), V(-31, -1, -83), V(26, -1, -152)}) do
			tree(scene, p, random:NextNumber(10, 15), index, p.X)
			for i = 1, 5 do
				local a = i * 2.4
				piece(scene, "Meadow bloom", V(0.65, 0.64, 0.65), p + V(math.cos(a) * i, 0.2, math.sin(a) * i),
					if i % 2 == 0 then rgb(255, 214, 105) else rgb(255, 147, 164), concrete, false, Enum.PartType.Ball)
			end
		end
		for i = 1, 9 do
			local x = -216 + i * 46
			local h = random:NextNumber(35, 76)
			local frame = CFrame.new(x, h * 0.20 - 2, -251 - random:NextNumber(0, 24)) * CFrame.Angles(0, i * 0.49, i % 2 * 0.16)
			piece(scene, "Ridge", V(64, h, 52), frame, terrain:Lerp(rgb(66, 124, 117), i / 10), rock, false, Enum.PartType.Ball)
		end
		for _, p in ipairs({V(-48, 0, 93), V(47, 0, 93), V(-37, 0, 43)}) do bench(scene, p, accent) end
		cabin(scene, V(-65, -1.5, 48))
		cabin(scene, V(70, -1.5, 76))
		for i = 1, 11 do
			local x = -124 + i * 23
			local z = -38 - (i % 4) * 30
			if math.abs(x) > 31 and math.abs(x) < 94 then
				local mound = piece(scene, "Valley mound", V(12 + i % 5, 3 + i % 4, 12), V(x, -2.4, z), terrain:Lerp(rgb(121, 191, 95), 0.28), grass, false, Enum.PartType.Ball)
				tree(scene, mound.Position + V(0, 2.0, 0), 7 + i % 5, index, i * 2)
			end
		end
	elseif index == 2 then
		piece(ground, "City foundation", V(352, 12, 378), V(5, -7.5, -60), terrain, concrete)
		local towers = {
			V(-90, 0, 37), V(83, 0, 44), V(-111, 0, -12), V(72, 0, -25), V(-115, 0, -80), V(99, 0, -44),
			V(-125, 0, -142), V(141, 0, -74), V(-93, 0, -206), V(151, 0, -191), V(-46, 0, -228), V(30, 0, -240),
			V(85, 0, -236), V(165, 0, -249), V(-152, 0, -205), V(-137, 0, -254), V(164, 0, -26),
		}
		for i, base in ipairs(towers) do
			local h = random:NextInteger(21, 84)
			local width = random:NextInteger(13, 23)
			local depth = random:NextInteger(12, 23)
			local glow = if i % 3 == 0 then rgb(247, 108, 214) else accent
			local towerColor = terrain:Lerp(rgb(60, 69, 119), random:NextNumber(0, 0.9))
			piece(scene, "Tower", V(width, h, depth), base + V(0, h * 0.5 - 1.2, 0), towerColor, metal)
			piece(scene, "Roof band", V(width + 0.9, 0.5, depth + 0.9), base + V(0, h - 1, 0), glow, neon, false)
			for line = 1, math.min(7, math.floor(h / 7)) do
				local y = line * (h - 6) / (math.min(7, math.floor(h / 7)) + 1) + 1
				piece(scene, "Office lights", V(width * 0.69, 0.34, 0.10), base + V(0, y, depth * 0.5 + 0.07), glow:Lerp(white, 0.3), neon, false)
			end
			piece(scene, "Edge light", V(0.16, h * 0.75, 0.17), base + V(-width / 2 + 1.2, h * 0.53, depth * 0.5 + 0.10), glow, neon, false)
		end
		for i = 3, 7 do
			local p = route[i]
			if p.Y > 5 then
				piece(scene, "Skyway support", V(5.7, p.Y + 2, 5.7), V(p.X, p.Y / 2 - 1, p.Z), ink, metal)
			end
		end
		local p = world.secret
		piece(ground, "Signal Loft balcony", V(24, 1.7, 27), p + V(0, -1.85, -3.2), terrain, metal)
		beam(ground, "Balcony bridge", route[5] - V(0, 0.56, 0), p - V(0, 1.56, 0), 9.5, 1.1, terrain, metal, true)
		for i = 1, 3 do crate(scene, V(-30 + i * 3.1, 1.0, 8 + i), 2.5, accent) end
		sign(scene, "SKYLINE TRANSIT", "PLATFORM  /  ROOFTOP LINE", V(-31, 14, -5), 18, 0, rgb(255, 118, 212))
		sign(scene, "NEON OUTFITTERS", "TRAILS  /  FOOTWEAR", V(-31, 7.4, 92), 14, 0, accent)
		for _, x in ipairs({-9, 9}) do
			for _, z in ipairs({77, 62, 46}) do
				piece(scene, "Walkway inlay", V(0.34, 0.06, 6.8), V(x, 0.13, z), rgb(232, 97, 213), neon, false)
			end
		end
	elseif index == 3 then
		piece(ground, "Canyon lowlands", V(350, 14, 382), V(0, -23.7, -58), terrain:Lerp(ink, 0.19), rock)
		piece(ground, "Canyon rim", V(196, 12, 115), V(0, -7.5, 66), terrain, rock)
		for i = 1, 32 do
			local side = if i % 2 == 0 then -1 else 1
			local x = side * random:NextNumber(109, 163)
			local z = random:NextNumber(-247, 64)
			local h = random:NextNumber(20, 51)
			local b = V(x, h * 0.40 - 15, z)
			piece(scene, "Canyon buttress", V(random:NextNumber(12, 24), h, random:NextNumber(13, 27)),
				CFrame.new(b) * CFrame.Angles(i * 0.12, i, i * 0.21), terrain:Lerp(rgb(71, 46, 95), random:NextNumber(0.15, 0.6)), rock)
			if i % 3 ~= 0 then crystal(scene, V(x - side * 19, -15, z), random:NextNumber(5, 13), accent, i) end
		end
		for _, p in ipairs({V(10, -15, -77), V(57, -15, -94), V(96, -15, -137), V(67, -15, -174), V(-2, -15, -177), V(-44, -13, -122), V(-42, 0, 44), V(44, 0, 76)}) do
			crystal(scene, p, random:NextNumber(5, 9), accent, p.X)
		end
		for j = 0, 2 do
			local p = V(48 + j * 7, -15, -121 - j * 8)
			for _, side in ipairs({-1, 1}) do
				piece(scene, "Geode wall", V(5.8, 12, 8.8), CFrame.new(p + V(side * 11.5, 3.1, 0)) * CFrame.Angles(0, 0.56, side * 0.21), rgb(91, 57, 119), rock)
			end
			piece(scene, "Geode roof", V(25.5, 4, 10.3), CFrame.new(p + V(0, 11.6, 0)) * CFrame.Angles(0, 0.55, -0.12), rgb(104, 67, 129), rock)
		end
		for j = 1, 5 do
			piece(scene, "Opal falls", V(0.7, 21, 2.2), V(-106, -5.0, -116 + j * 2.1), accent:Lerp(water, 0.65), Enum.Material.Glass, false).Transparency = 0.25
		end
		for _, p in ipairs({V(-51, -1, 53), V(48, -1, 38), V(-56, -1, 93), V(50, -1, 91)}) do
			crystal(scene, p, 11.5, accent:Lerp(water, 0.21), p.Z)
		end
	else
		if index == 5 then
			piece(ground, "Volcanic plain", V(369, 17, 380), V(0, -13.5, -61), terrain, rock)
			local center = V(22, -4.75, -130)
			piece(scene, "Impact glass", V(0.2, 95, 95), CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2), rgb(88, 51, 60), rock, false, Enum.PartType.Cylinder)
			ring(scene, center + V(0, 0.1, 0), 36, 16, 0.42, rgb(245, 114, 64), neon, false)
		end
		for i = 1, #route do
			local a = route[i]
			local h = random:NextInteger(7, 16)
			local w = random:NextInteger(24, 38)
			piece(ground, "Island shelf", V(w, 2.4, w * 0.92), a - V(0, 2.1, 0), terrain, rock)
			local c = CFrame.new(a - V(0, h * 0.50 + 3.1, 0)) * CFrame.Angles(i * 0.31, i * 0.65, 0.33)
			piece(scene, "Island underside", V(w * 0.83, h, w * 0.71), c, terrain:Lerp(ink, 0.37), rock, false)
			local islandSide = if i % 2 == 0 then -1 else 1
			if index == 4 then
				tree(scene, a + V(islandSide * 13, -0.8, 2), 7 + i % 5, index, i)
				local cloud = a + V(islandSide * 23, -8 - i % 5, 7)
				for j = 1, 3 do
					piece(scene, "Cloud bank", V(24, 6 + j, 14), cloud + V((j - 2) * 8, j % 2, j * 1.2), white:Lerp(world.mood, 0.28),
						concrete, false, Enum.PartType.Ball).Transparency = 0.14
				end
			else
				crystal(scene, a + V(islandSide * 15, -1, 5), 4 + i % 5, accent, i)
				if index == 6 and i % 2 == 0 then
					ring(scene, a + V(islandSide * 18, 14, 5), 9, 12, 0.67, accent:Lerp(white, 0.35), neon, true)
				end
			end
		end
		local nearest = route[4]
		for _, point in ipairs(route) do
			if (point - world.secret).Magnitude < (nearest - world.secret).Magnitude then nearest = point end
		end
		beam(ground, "Secret walkway", nearest - V(0, 0.63, 0), world.secret - V(0, 1.63, 0), 9, 1.25, terrain, metal, true)
		piece(ground, "Secret platform", V(20, 1.6, 21), world.secret - V(0, 1.8, 0), terrain, rock)
	end

	local track = folder(parent, "Course")
	tracks(track, world)
	local hubObjects = folder(parent, "Hub")
	local station = pavilion(hubObjects, "VELOCITY LAB", "SPEED  /  TRAINING", V(24, 0.18, 60), accent, hubMaterial)
	prompt(station, "Open upgrades", "Velocity Lab", "Open", "Upgrades", index)
	local habitat = pavilion(hubObjects, "CREATURE HABITAT", "DISCOVER  /  EQUIP", V(-25, 0.18, 58), accent, hubMaterial)
	prompt(habitat, "Open collection", "Habitat", "Open", "Creatures", index)
	local creature = Models.creature(Config.Creatures[math.min(index, #Config.Creatures)])
	creature:ScaleTo(1.7)
	creature:PivotTo(CFrame.new(-25, 3.1, 57.5) * CFrame.Angles(0, math.pi, 0))
	creature.Parent = hubObjects

	local gateCenter = V(0, 6.2, 105)
	ring(hubObjects, gateCenter, 6, 14, 1.0, ink, metal, true)
	ring(hubObjects, gateCenter + V(0, 0, 0.57), 5.82, 14, 0.24, accent, neon, true)
	local portal = piece(hubObjects, "World console", V(6, 1.4, 2.4), V(9, 0.7, 103.5), ink, metal)
	prompt(portal, "Choose destination", "World gate", "Open", "Worlds", index)
	sign(hubObjects, string.upper(world.name), "DASHVERSE  /  VELTRIX STUDIOS", V(0, 10.1, 106.0), 22, math.pi, accent)
	local raceConsole = piece(hubObjects, "Race console", V(3.5, 2.5, 2.2), V(-13, 1.25, 37.5), ink, metal)
	prompt(raceConsole, "Open race lobby", world.race, "Open", "Races", index)

	local shrine = piece(scene, world.secretName, V(4.7, 0.75, 4.7), world.secret - V(0, 0.42, 0), ink, rock)
	ring(scene, world.secret + V(0, 2.2, 0), 2.4, 8, 0.18, accent, neon, true)
	crystal(scene, world.secret + V(0, 0.1, 0), 3.8, accent, index)
	prompt(shrine, "Discover cache", world.secretName, "Secret", index, index)

	local stands = folder(parent, "Premium displays")
	local standsByKey = {
		spark = V(-23, 0, 86), trail = V(20, 0, 41), energy = V(33, 0, 76),
		shoes = V(-27, 0, 86), coins = V(31, 0, 83), starter = world.secret + V(7, -0.75, 0),
		training = V(25, 0, 83), coinboost = V(24, 0, 82), founder = world.secret + V(6, -1, 0),
	}
	for _, info in ipairs(Catalog) do
		if info.world == index then
			local p = standsByKey[info.id]
			local base = piece(stands, info.stand, V(5.6, 1.35, 4.6), p + V(0, 0.65, 0), ink, metal)
			piece(stands, "Display rim", V(5.1, 0.19, 4.1), p + V(0, 1.40, 0), info.color, neon, false)
			local model = Models.product(info)
			model:ScaleTo(1.55)
			model:PivotTo(CFrame.new(p + V(0, 3.04, 0)) * CFrame.Angles(0, 0.35, 0))
			model.Parent = stands
			prompt(base, "Inspect item", info.name, "Shop", info.id, index)
		end
	end

	local features = folder(parent, "Features")
	if index > 1 then
		local names = {"", "Slipstream", "Crystal spring", "Updraft", "Thermal vent", "Rift lift"}
		for j, node in ipairs({3, 5, 8}) do
			local p = route[node] + V(5, 0.13, 0)
			local pad = piece(features, names[index], V(5.0, 0.22, 5.0), p, accent, neon)
			pad:SetAttribute("World", index)
			pad:SetAttribute("Feature", if index == 2 or index == 5 then "Boost" else "Lift")
			ring(features, p + V(0, 0.24, 0), 1.75, 8, 0.14, white, neon, false)
		end
	end

	local sparks = folder(parent, "Pickups")
	for i = 1, 6 do
		spark(sparks, V(if i % 2 == 0 then 1.9 else -1.9, 1.85, 79 - i * 7.5), index * 100 + i, accent, index, 4 + index * 2)
	end
	for i = 1, #route do
		local a, b = route[i], route[i % #route + 1]
		for j = 1, 3 do
			local p = a:Lerp(b, j / 4) + V(if j == 2 then 3.4 else -2.1, 1.85, 0)
			spark(sparks, p, index * 100 + 6 + (i - 1) * 3 + j, accent, index, 4 + index * 2)
		end
	end
end

function World.build()
	local current = workspace:FindFirstChild("DashverseWorld")
	if current and current:GetAttribute("Build") == Config.Version and #current:GetChildren() == #Config.Worlds then
		return current
	end
	if current then current:Destroy() end
	local root = folder(workspace, "DashverseWorld")
	root:SetAttribute("Build", Config.Version)
	for index, world in ipairs(Config.Worlds) do
		local model = Instance.new("Model")
		model.Name = world.name
		model:SetAttribute("World", index)
		model.WorldPivot = CFrame.identity
		district(model, index, world)
		model:PivotTo(CFrame.new(world.offset))
		model.Parent = root
		task.wait()
	end
	return root
end

function World.configure()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14.2
	lighting.Brightness = 2.0
	lighting.ExposureCompensation = -0.12
	lighting.Ambient = rgb(105, 111, 140)
	lighting.OutdoorAmbient = rgb(139, 154, 174)
	lighting.EnvironmentDiffuseScale = 0.42
	lighting.EnvironmentSpecularScale = 0.45
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "DashverseAtmosphere"
	atmosphere.Color = rgb(210, 231, 246)
	atmosphere.Decay = rgb(166, 193, 215)
	atmosphere.Density = 0.27
	atmosphere.Offset = 0.12
	atmosphere.Haze = 1.27
	atmosphere.Glare = 0.13
	atmosphere.Parent = lighting
	local bloom = lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Name = "DashverseBloom"
	bloom.Intensity = 0.37
	bloom.Size = 25
	bloom.Threshold = 1.25
	bloom.Parent = lighting
	local blur = lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if blur then blur.Enabled = false end

	local spawn = workspace:FindFirstChild("DashverseSpawn")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "DashverseSpawn"
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.CanTouch = false
		spawn.CanQuery = false
		spawn.Transparency = 1
		spawn.Size = V(8, 0.4, 8)
		spawn.CFrame = CFrame.new(Config.Spawn - V(0, 3.15, 0))
		spawn.Duration = 0
		spawn.Neutral = true
		spawn.Parent = workspace
	end
	return spawn
end

function World.ground()
	local terrain = workspace.Terrain
	if terrain:GetAttribute("DashverseValleyWater") then return end
	terrain.WaterColor = rgb(63, 172, 187)
	terrain.WaterTransparency = 0.31
	terrain.WaterReflectance = 0.13
	terrain.WaterWaveSize = 0.11
	terrain.WaterWaveSpeed = 7
	for _, z in ipairs({-64, -129}) do
		terrain:FillBlock(CFrame.new(0, -2.2, z) * CFrame.Angles(0, 0.17, 0), V(338, 2.0, 21), Enum.Material.Water)
	end
	terrain:SetAttribute("DashverseValleyWater", true)
end

return World
