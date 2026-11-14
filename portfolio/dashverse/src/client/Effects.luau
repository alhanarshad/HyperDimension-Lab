local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Dashverse")
local Config = require(Shared.Config)
local Models = require(Shared.Models)

local Effects = {}
Effects.__index = Effects
local V = Vector3.new
local rgb = Color3.fromRGB
local client = Players.LocalPlayer

local creatureInfo = {}
for _, entry in ipairs(Config.Creatures) do creatureInfo[entry.id] = entry end
local ribbonColors = {
	["Valley Ribbon"] = {rgb(92, 255, 162), rgb(205, 255, 123)},
	["Mastery Ribbon"] = {rgb(255, 194, 90), rgb(116, 247, 224)},
	["Prism Ribbon"] = {rgb(79, 236, 255), rgb(178, 102, 255)},
	["Solar Ribbon"] = {rgb(255, 240, 141), rgb(255, 118, 99)},
	["Eventide Ribbon"] = {rgb(252, 116, 239), rgb(106, 136, 255)},
}

local function anchor(name, position, size, color)
	local item = Instance.new("Part")
	item.Name = name
	item.Position = position
	item.Size = size
	item.Color = color
	item.Material = Enum.Material.Neon
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	item.Anchored = true
	return item
end

local function attach(parent, pos)
	local item = Instance.new("Attachment")
	item.Position = pos
	item.Parent = parent
	return item
end

local function adorn(parent, name, frame, color, size, shape)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Shape = shape or Enum.PartType.Block
	item.CFrame = parent.CFrame * frame
	item.Color = color
	item.Material = Enum.Material.Neon
	item.Massless = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parent
	weld.Part1 = item
	weld.Parent = item
	item.Parent = parent
	return item
end

function Effects.new()
	local self = setmetatable({
		settings = table.clone(Config.Settings), companions = {}, costumes = {}, hidden = {}, models = {}, sound = {},
	}, Effects)
	self.folder = Instance.new("Folder")
	self.folder.Name = "DashverseLocalEffects"
	self.folder.Parent = workspace
	for id, source in pairs(Config.Audio) do
		local url = if source.assetId then "rbxassetid://" .. source.assetId else source.fallback
		if not url then continue end
		local sound = Instance.new("Sound")
		sound.Name = "Dashverse_" .. id
		sound.SoundId = url
		sound.PlaybackSpeed = source.pitch or 1
		sound.Volume = self.settings.Volume * 0.52
		sound.Looped = id == "ambience"
		sound.Parent = SoundService
		self.sound[id] = sound
	end
	local map = workspace:WaitForChild("DashverseWorld", 18)
	if map then
		local function register(instance)
			if instance:IsA("BasePart") and instance.Parent and instance.Parent:IsA("Model") then
				local id = instance.Parent:GetAttribute("PickupId")
				if id then
					self.models[id] = instance.Parent
					if self.hidden[id] then instance.LocalTransparencyModifier = 1 end
				end
			end
		end
		for _, instance in ipairs(map:GetDescendants()) do register(instance) end
		map.DescendantAdded:Connect(register)
		map.DescendantRemoving:Connect(function(instance)
			if instance:IsA("Model") then
				local id = instance:GetAttribute("PickupId")
				if id and self.models[id] == instance then self.models[id] = nil end
			end
		end)
	end
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / 16 then return end
		self:updateRunners(accumulator)
		accumulator = 0
	end)
	return self
end

function Effects:play(id)
	local sound = self.sound[id]
	if not sound or self.settings.Volume <= 0 then return end
	sound.TimePosition = 0
	SoundService:PlayLocalSound(sound)
end

function Effects:burst(position, color, amount)
	if not self.settings.Effects then return end
	local host = anchor("Spark burst", position, V(0.15, 0.15, 0.15), color)
	host.Transparency = 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color, rgb(255, 250, 207))
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.28, 0.59)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 13)
	emitter.SpreadAngle = Vector2.new(170, 170)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.42), NumberSequenceKeypoint.new(1, 0)})
	emitter.Parent = host
	host.Parent = self.folder
	emitter:Emit(amount)
	task.delay(0.85, function() host:Destroy() end)
end

function Effects:pickup(id, cooldown)
	local model = self.models[id]
	self.hidden[id] = true
	if model and model:IsDescendantOf(workspace) then
		local core = model.PrimaryPart
		if core then self:burst(core.Position, core.Color, 12) end
		for _, item in ipairs(model:GetChildren()) do
			if item:IsA("BasePart") then item.LocalTransparencyModifier = 1 end
		end
	end
	self:play("pickup")
	task.delay(cooldown, function()
		self.hidden[id] = nil
		local current = self.models[id]
		if not current then return end
		for _, item in ipairs(current:GetChildren()) do
			if item:IsA("BasePart") then item.LocalTransparencyModifier = 0 end
		end
	end)
end

local function destroyList(list)
	if not list then return end
	for _, item in ipairs(list) do item:Destroy() end
end

function Effects:costume(runner, character, root)
	local ribbon = runner:GetAttribute("DV_trail") or ""
	local spark = runner:GetAttribute("DV_effect") == "Amber Spark"
	local shoes = runner:GetAttribute("DV_shoes") == "Neon Shoes"
	local head = runner:GetAttribute("DV_head") or ""
	local key = ribbon .. tostring(spark) .. tostring(shoes) .. head
	local entry = self.costumes[runner]
	if entry and (entry.character ~= character or entry.key ~= key or not self.settings.Effects) then
		destroyList(entry.items)
		self.costumes[runner] = nil
		entry = nil
	end
	if not self.settings.Effects then return end
	if entry then
		if entry.emitter then entry.emitter.Enabled = root.AssemblyLinearVelocity.Magnitude > 6 end
		return
	end
	local items = {}
	entry = {items = items, character = character, key = key}
	self.costumes[runner] = entry
	local colors = ribbonColors[ribbon]
	if colors then
		local a = attach(root, V(-0.55, -0.6, 0.50))
		local b = attach(root, V(0.55, -0.6, 0.50))
		local trail = Instance.new("Trail")
		trail.Name = ribbon
		trail.Attachment0 = a
		trail.Attachment1 = b
		trail.Color = ColorSequence.new(colors[1], colors[2])
		trail.Lifetime = 0.46
		trail.MinLength = 0.45
		trail.LightEmission = 0.9
		trail.Transparency = NumberSequence.new(0.12, 0.99)
		trail.WidthScale = NumberSequence.new(1, 0.05)
		trail.Parent = root
		table.insert(items, a)
		table.insert(items, b)
		table.insert(items, trail)
	end
	if spark then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Amber Spark"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(rgb(255, 186, 72), rgb(255, 244, 166))
		emitter.LightEmission = 0.85
		emitter.Rate = 9
		emitter.Lifetime = NumberRange.new(0.28, 0.46)
		emitter.Speed = NumberRange.new(0.2, 2.4)
		emitter.Size = NumberSequence.new(0.31, 0)
		emitter.Parent = root
		entry.emitter = emitter
		table.insert(items, emitter)
	end
	if shoes then
		for _, name in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}) do
			local foot = character:FindFirstChild(name)
			if foot and foot:IsA("BasePart") then
				table.insert(items, adorn(foot, "Neon Shoe", CFrame.new(0, -foot.Size.Y / 2 + 0.18, -0.03),
					rgb(96, 247, 242), V(foot.Size.X + 0.13, 0.24, foot.Size.Z + 0.11)))
			end
		end
	end
	if head ~= "" then
		local face = character:FindFirstChild("Head")
		if face and face:IsA("BasePart") then
			local shade = if head == "Victory Halo" then rgb(255, 224, 117) elseif head == "Prestige Crest" then rgb(137, 245, 224) else rgb(244, 124, 255)
			for i = 1, 8 do
				local angle = i * math.pi / 4
				local frame = CFrame.new(math.cos(angle) * 0.62, 0.88, math.sin(angle) * 0.62)
					* CFrame.Angles(0, -angle, 0)
				local size = if head == "Victory Halo" then V(0.12, 0.10, 0.49) else V(0.16, 0.24 + (i % 2) * 0.19, 0.33)
				table.insert(items, adorn(face, head, frame, shade, size))
			end
		end
	end
end

function Effects:updateRunners(dt)
	local localRoot = client.Character and client.Character:FindFirstChild("HumanoidRootPart")
	local active = {}
	if localRoot then
		local roster = {}
		for _, runner in ipairs(Players:GetPlayers()) do
			local character = runner.Character
			local body = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if body and humanoid and humanoid.Health > 0 then
				local distance = (body.Position - localRoot.Position).Magnitude
				if distance < 115 then table.insert(roster, {runner, character, body, distance}) end
			end
		end
		table.sort(roster, function(a, b) return a[4] < b[4] end)
		for index = 1, math.min(#roster, 10) do
			local runner, character, root = table.unpack(roster[index])
			active[runner] = true
			self:costume(runner, character, root)
			local creature = runner:GetAttribute("DV_Creature")
			local info = creatureInfo[creature]
			local skin = runner:GetAttribute("DV_skin")
			if (creature == "Cub" and skin ~= "Aurora Cub") or (creature == "Wisp" and skin ~= "Eventide Wisp")
				or (creature ~= "Cub" and creature ~= "Wisp") then skin = "" end
			local record = self.companions[runner]
			if record and (record.id ~= creature or record.skin ~= skin) then
				record.model:Destroy()
				self.companions[runner] = nil
				record = nil
			end
			if not info then continue end
			local phase = os.clock() * 4 + (runner.UserId % 17)
			local moving = root.AssemblyLinearVelocity.Magnitude > 3
			local hover = if self.settings.Effects and self.settings.Motion then math.sin(phase * (if moving then 2 else 1)) * 0.18 else 0
			local target = root.CFrame * CFrame.new(2.9, -1.15 + hover, 3.6)
			if not record then
				local model = Models.creature(info, skin)
				model:PivotTo(target)
				model.Parent = self.folder
				record = {id = creature, skin = skin, model = model, position = target}
				self.companions[runner] = record
			end
			if (record.position.Position - target.Position).Magnitude > 24 then
				record.position = target
			else
				record.position = record.position:Lerp(target, 1 - math.exp(-dt * 10))
			end
			record.model:PivotTo(record.position)
		end
	end
	for runner, record in pairs(self.companions) do
		if not active[runner] then
			record.model:Destroy()
			self.companions[runner] = nil
		end
	end
	for runner, record in pairs(self.costumes) do
		if not active[runner] then
			destroyList(record.items)
			self.costumes[runner] = nil
		end
	end
end

function Effects:gate(state)
	local race = state.race
	local gate = if race then (race.gate + 1) % race.gates + 1 else nil
	local key = if race then tostring(state.world) .. ":" .. gate else nil
	if self.gateKey == key then return end
	self.gateKey = key
	if self.marker then self.marker:Destroy() end
	if not race then return end
	local world = Config.Worlds[state.world]
	local point = world.offset + world.route[gate] + V(0, 9.5, 0)
	local marker = anchor("Next checkpoint", point, V(0.2, 0.2, 0.2), world.accent)
	marker.Transparency = 1
	marker.Parent = self.folder
	self.marker = marker
	local board = Instance.new("BillboardGui")
	board.Name = "Checkpoint marker"
	board.Size = UDim2.fromOffset(95, 40)
	board.AlwaysOnTop = true
	board.MaxDistance = 112
	board.Parent = marker
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.Text = if gate == 1 then "▼  FINISH" else "▼  GATE " .. (gate - 1)
	text.TextColor3 = world.accent
	text.TextSize = 15
	text.Font = Enum.Font.GothamBlack
	text.BackgroundColor3 = rgb(14, 26, 44)
	text.BackgroundTransparency = 0.14
	text.BorderSizePixel = 0
	text.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = text
end

function Effects:sync(state)
	self.settings = state.settings
	for id, sound in pairs(self.sound) do
		sound.Volume = self.settings.Volume * (if id == "ambience" then 0.23 else 0.50)
		if id == "ambience" and not sound.IsPlaying and sound.Volume > 0 then sound:Play() end
	end
	if self.world ~= state.world then
		self.world = state.world
		local world = Config.Worlds[state.world]
		local air = Lighting:FindFirstChildOfClass("Atmosphere")
		if air then
			air.Color = world.light
			air.Decay = world.mood
		end
		Lighting.ClockTime = ({14.2, 18.25, 16.5, 11.8, 17.3, 18.7})[state.world]
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then bloom.Enabled = self.settings.Effects end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then rays.Enabled = self.settings.Effects end
	self:gate(state)
	local wide = state.race and state.race.phase == "Running" and self.settings.Motion
	if self.wide ~= wide then
		self.wide = wide
		local camera = workspace.CurrentCamera
		if camera then
			local desired = if wide then 77 else 70
			if self.settings.Motion then TweenService:Create(camera, TweenInfo.new(0.28), {FieldOfView = desired}):Play()
			else camera.FieldOfView = desired end
		end
	end
end

function Effects:notice(effect)
	if effect == "victory" or effect == "upgrade" or effect == "dash" then
		local body = client.Character and client.Character:FindFirstChild("HumanoidRootPart")
		local color = if effect == "victory" then rgb(255, 211, 109) else Config.Worlds[self.world or 1].accent
		if body then self:burst(body.Position - V(0, 0.9, 0), color, if effect == "victory" then 32 else 18) end
	end
	if effect then self:play(effect) end
end

return Effects
