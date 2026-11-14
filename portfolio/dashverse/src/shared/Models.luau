local Models = {}
local V = Vector3.new
local rgb = Color3.fromRGB

local function part(parent, name, size, position, color, shape, angles, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = CFrame.new(position) * (angles or CFrame.identity)
	object.Color = color
	object.Shape = shape or Enum.PartType.Block
	object.Material = material or Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanQuery = false
	object.CanTouch = false
	object.CastShadow = false
	object.Parent = parent
	return object
end

local function ball(model, name, size, position, color)
	return part(model, name, size, position, color, Enum.PartType.Ball)
end

function Models.creature(info, skin)
	local model = Instance.new("Model")
	model.Name = info.name
	local color = info.color
	if skin == "Aurora Cub" then color = rgb(116, 250, 225) end
	if skin == "Eventide Wisp" then color = rgb(255, 126, 203) end
	local light = color:Lerp(rgb(255, 255, 245), 0.55)
	local dark = rgb(21, 24, 46)
	local style = info.style
	local head = ball(model, "Head", V(1.35, 1.18, 1.08), V(0, 0.6, -0.45), color)
	local body = ball(model, "Body", V(1.43, 0.92, 1.62), V(0, 0.07, 0.22), color:Lerp(dark, 0.14))
	model.PrimaryPart = body
	for _, side in ipairs({-1, 1}) do
		ball(model, "Foot", V(0.37, 0.4, 0.52), V(side * 0.46, -0.26, -0.37), light)
		ball(model, "Eye", V(0.22, 0.30, 0.15), V(side * 0.34, 0.67, -0.93), dark)
		ball(model, "Eye glint", V(0.075, 0.095, 0.07), V(side * 0.34 + 0.035, 0.73, -0.996), rgb(255, 255, 255))
		if style == "fox" or style == "cub" then
			local tilt = CFrame.Angles(0, 0, math.rad(-side * 22))
			local earShape = if style == "fox" then Enum.PartType.Wedge else Enum.PartType.Ball
			part(model, "Ear", V(0.47, 0.78, 0.49), V(side * 0.47, 1.12, -0.36), color, earShape, tilt)
			ball(model, "Ear tuft", V(0.23, 0.36, 0.18), V(side * 0.54, 1.17, -0.57), light)
		elseif style == "bunny" then
			part(model, "Ear", V(0.33, 1.04, 0.36), V(side * 0.38, 1.42, -0.42), color, Enum.PartType.Ball, CFrame.Angles(0, 0, -side * 0.22))
			ball(model, "Ear lining", V(0.19, 0.68, 0.18), V(side * 0.41, 1.44, -0.57), rgb(255, 168, 213))
		elseif style == "owl" or style == "wisp" then
			part(model, "Wing", V(0.42, 1.07, 0.71), V(side * 0.82, 0.35, 0.25), light, Enum.PartType.Ball, CFrame.Angles(0, 0, -side * 0.64))
		elseif style == "gecko" then
			ball(model, "Fin", V(0.21, 0.54, 0.72), V(side * 0.66, 0.18, 0.46), light)
		else
			part(model, "Plate", V(0.46, 0.51, 0.50), V(side * 0.46, 0.49, 0.34), light, Enum.PartType.Wedge, CFrame.Angles(0, side * 0.6, side * 0.17))
		end
	end
	ball(model, "Muzzle", V(0.41, 0.24, 0.23), V(0, 0.39, -0.95), light)
	ball(model, "Nose", V(0.14, 0.10, 0.10), V(0, 0.45, -1.07), dark)
	if style == "fox" or style == "gecko" then
		part(model, "Tail", V(0.58, 0.6, 1.52), V(0.32, 0.29, 1.11), color, Enum.PartType.Ball, CFrame.Angles(-0.29, 0.45, 0))
		ball(model, "Tail tip", V(0.42, 0.44, 0.56), V(0.56, 0.48, 1.58), light)
	elseif style == "wisp" or style == "meteor" or style == "cub" then
		part(model, "Core", V(0.46, 0.46, 0.46), V(0, 1.36, -0.08), light, Enum.PartType.Block, CFrame.Angles(0.62, 0.8, 0.62), Enum.Material.Neon)
		head.Material = Enum.Material.SmoothPlastic
	else
		ball(model, "Tail", V(0.51, 0.51, 0.51), V(0, 0.15, 1.08), light)
	end
	return model
end

function Models.product(info)
	local model = Instance.new("Model")
	model.Name = info.name
	local color = info.color
	local dark = rgb(33, 32, 60)
	local white = color:Lerp(rgb(255, 255, 255), 0.58)
	local kind = info.icon
	local origin = part(model, "Origin", V(0.15, 0.15, 0.15), V(0, 0, 0), dark)
	origin.Transparency = 1
	model.PrimaryPart = origin
	if kind == "shoes" then
		for _, side in ipairs({-1, 1}) do
			local x = side * 0.54
			part(model, "Sole", V(0.74, 0.23, 1.5), V(x, -0.5, 0), color, Enum.PartType.Block, nil, Enum.Material.Neon)
			ball(model, "Shoe", V(0.77, 0.52, 1.45), V(x, -0.22, 0), dark)
			ball(model, "Cuff", V(0.65, 0.68, 0.69), V(x, 0.04, 0.34), white)
		end
	elseif kind == "trail" or kind == "spark" then
		for i = 1, 7 do
			local t = (i - 1) / 6
			local size = 0.15 + t * 0.46
			part(model, "Streak", V(size, size, size), V(-1.08 + t * 2.1, math.sin(t * 2.5) - 0.43, 0),
				color:Lerp(white, t), Enum.PartType.Block, CFrame.Angles(0.6, 0.75, t * 1.2), Enum.Material.Neon)
		end
	elseif kind == "coins" or kind == "coinboost" then
		for i = 1, 5 do
			part(model, "Coin", V(0.18, 1.04, 1.04), V((i % 3 - 1) * 0.55, i * 0.22 - 0.8, (i % 2) * 0.5),
				color:Lerp(white, (i % 3) * 0.2), Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Metal)
		end
	else
		local count = if kind == "founder" then 8 else 5
		part(model, "Core", V(0.7, 0.7, 0.7), V(0, 0, 0), white, Enum.PartType.Block, CFrame.Angles(0.68, 0.61, 0.78), Enum.Material.Neon)
		for i = 1, count do
			local a = i / count * math.pi * 2
			part(model, "Facet", V(0.22, 0.60, 0.22), V(math.sin(a) * 0.94, math.cos(a) * 0.78, math.sin(a * 2) * 0.3),
				color, Enum.PartType.Block, CFrame.Angles(0.35, 0, -a), Enum.Material.Neon)
		end
	end
	return model
end

return Models
