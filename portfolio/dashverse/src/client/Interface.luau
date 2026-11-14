local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Dashverse")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Models = require(Shared.Models)

local Interface = {}
Interface.__index = Interface

local rgb = Color3.fromRGB
local u = UDim2.new
local off = UDim2.fromOffset
local scale = UDim2.fromScale
local v = Vector2.new
local P = {
	ink = rgb(13, 21, 36), deep = rgb(8, 16, 29), panel = rgb(20, 33, 51), tile = rgb(26, 43, 62),
	line = rgb(61, 83, 101), white = rgb(246, 250, 250), light = rgb(173, 196, 210),
	mint = rgb(113, 255, 188), gold = rgb(255, 220, 132), danger = rgb(255, 163, 177),
}
local display = Enum.Font.GothamBlack
local bold = Enum.Font.GothamBold
local regular = Enum.Font.GothamMedium
local nav = {"Worlds", "Upgrades", "Creatures", "Races", "Menu"}
local more = {"Quests", "Achievements", "Inventory", "Shop", "Settings", "Statistics", "Tutorial"}
local pages = {
	Worlds = "Choose your destination", Upgrades = "Velocity Lab", Creatures = "Creature Habitat",
	Races = "Race lobby", Menu = "Runner menu", Quests = "Quests", Achievements = "Achievements",
	Inventory = "Cosmetic locker", Shop = "Premium shop", Settings = "Settings", Statistics = "Statistics",
	Tutorial = "How to play",
}
local instructions = {
	{"Collect 3 sparks", "Follow the lit path toward the first race gate."},
	{"Buy a Speed upgrade", "Open Upgrades and put your Energy and Coins to work."},
	{"Finish River Circuit", "Open Races. The route lights show your next gate."},
}

local function new(kind, name, parent, properties)
	local object = Instance.new(kind)
	object.Name = name
	for key, value in pairs(properties) do object[key] = value end
	object.Parent = parent
	return object
end

local function round(object, radius)
	new("UICorner", "Corners", object, {CornerRadius = UDim.new(0, radius)})
end

local function stroke(object, color, transparency)
	return new("UIStroke", "Outline", object, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1,
		Color = color or P.line, Transparency = transparency or 0.25,
	})
end

local function frame(parent, name, position, size, color, radius)
	local object = new("Frame", name, parent, {
		Position = position, Size = size, BackgroundColor3 = color or P.panel,
		BackgroundTransparency = if color then 0 else 1, BorderSizePixel = 0,
	})
	if radius then round(object, radius) end
	return object
end

local function label(parent, name, text, position, size, properties)
	local options = {
		Position = position, Size = size, BackgroundTransparency = 1, TextColor3 = P.white, Text = text,
		Font = regular, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}
	for key, value in pairs(properties or {}) do options[key] = value end
	return new("TextLabel", name, parent, options)
end

local function button(parent, name, title, position, size, action, primary)
	local object = new("TextButton", name, parent, {
		Position = position, Size = size, Text = title, BackgroundColor3 = if primary then P.mint else P.tile,
		BorderSizePixel = 0, Font = bold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = if primary then P.deep else P.white, AutoButtonColor = action ~= nil,
		Selectable = action ~= nil, Active = action ~= nil,
	})
	round(object, 8)
	if action then object.Activated:Connect(action) end
	if not action then
		object.BackgroundColor3 = P.panel
		object.TextColor3 = P.light
	end
	return object
end

local function number(amount)
	if amount >= 1e9 then return ("%.1fb"):format(amount / 1e9) end
	if amount >= 1e6 then return ("%.1fm"):format(amount / 1e6) end
	if amount >= 1e4 then return ("%.1fk"):format(amount / 1e3) end
	return tostring(amount)
end

local function time(ms)
	return if ms then ("%.2fs"):format(ms / 1000) else "—"
end

local function count(dictionary)
	local total = 0
	for _, value in pairs(dictionary) do if value then total += 1 end end
	return total
end

local function viewport(parent, object, size, at, angle)
	local preview = new("ViewportFrame", "Preview", parent, {
		Position = at, Size = size, BorderSizePixel = 0, BackgroundColor3 = P.deep,
		Ambient = rgb(175, 177, 207), LightColor = rgb(255, 239, 220), LightDirection = Vector3.new(-0.8, -1, -0.5),
	})
	round(preview, 9)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(2.85, 1.65, -5.2), Vector3.new(0, 0.38, 0))
	camera.Parent = preview
	preview.CurrentCamera = camera
	object:PivotTo(CFrame.Angles(0, angle or -0.2, 0))
	object.Parent = preview
	return preview
end

function Interface.new(parent, send, sound)
	local self = setmetatable({send = send, sound = sound, productInfo = {}, marketRevision = 0, standings = {}, lastKeys = {}}, Interface)
	self.gui = new("ScreenGui", "DashverseHUD", parent, {ResetOnSpawn = false, DisplayOrder = 15, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	self.root = frame(self.gui, "SafeArea", off(0, 0), scale(1, 1))
	self.accent = P.mint

	local top = frame(self.root, "Header", off(19, 12), off(388, 64), P.ink, 13)
	self.top = top
	stroke(top, P.line)
	new("UIGradient", "Header gradient", top, {Color = ColorSequence.new(rgb(255, 255, 255), rgb(164, 190, 214)), Rotation = 19})
	for i = 1, 2 do
		local stripe = frame(top, "Logo stripe", off(17 + i * 9, 14 + i * 4), off(5, 22 - i * 3), P.mint, 2)
		stripe.Rotation = 27
	end
	self.logo = label(top, "Wordmark", "DASHVERSE", off(43, 8), off(138, 23), {Font = display, TextSize = 19})
	self.location = label(top, "Location", "GREEN VALLEY", off(43, 32), off(141, 19), {TextColor3 = P.mint, Font = bold, TextSize = 10})
	local divider = frame(top, "Divider", off(183, 12), off(1, 38), P.line)
	local energy = label(top, "Energy label", "ENERGY", off(200, 9), off(80, 17), {TextColor3 = P.light, Font = bold, TextSize = 10})
	self.energy = label(top, "Energy", "0", off(200, 27), off(77, 26), {TextColor3 = P.mint, Font = display, TextSize = 21})
	local coins = label(top, "Coins label", "COINS", off(295, 9), off(70, 17), {TextColor3 = P.light, Font = bold, TextSize = 10})
	self.coins = label(top, "Coins", "0", off(295, 27), off(76, 26), {TextColor3 = P.gold, Font = display, TextSize = 21})
	self.counters = {divider, energy, coins}

	self.goal = frame(self.root, "Objective", u(1, -19, 0, 12), off(278, 98), P.ink, 12)
	self.goal.AnchorPoint = v(1, 0)
	stroke(self.goal, P.line)
	self.goalTag = label(self.goal, "Objective type", "FIRST RUN", off(15, 10), u(1, -30, 0, 14), {TextColor3 = P.mint, Font = bold, TextSize = 10})
	self.goalTitle = label(self.goal, "Objective title", "Collect 3 sparks", off(15, 26), u(1, -30, 0, 20), {Font = bold, TextSize = 15})
	self.goalNote = label(self.goal, "Objective detail", instructions[1][2], off(15, 48), u(1, -30, 0, 35), {
		TextColor3 = P.light, TextSize = 11, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
	})
	self.goalTrack = frame(self.goal, "Objective progress", u(0, 15, 1, -13), u(1, -30, 0, 3), P.tile, 2)
	self.goalFill = frame(self.goalTrack, "Progress", off(0, 0), scale(0.07, 1), P.mint, 2)

	self.dock = frame(self.root, "Navigation", u(0.5, 0, 1, -17), off(498, 52), P.ink, 12)
	self.dock.AnchorPoint = v(0.5, 1)
	stroke(self.dock, P.line)
	self.navButtons = {}
	for i, page in ipairs(nav) do
		self.navButtons[i] = button(self.dock, page, page, u((i - 1) / #nav, 5, 0, 6), u(1 / #nav, -10, 1, -12),
			function() self:open(if self.page == page then nil else page) end)
	end
	self.dash = button(self.root, "Dash", "Dash   Q", u(1, -24, 1, -89), off(112, 48), function() self.send("dash") end, true)
	self.dash.AnchorPoint = v(1, 1)
	self.dash.Visible = false

	self.raceHUD = frame(self.root, "Race progress", u(0.5, 0, 0, 92), off(232, 64), P.ink, 11)
	self.raceHUD.AnchorPoint = v(0.5, 0)
	self.raceHUD.Visible = false
	stroke(self.raceHUD, P.mint, 0.44)
	self.raceClock = label(self.raceHUD, "Clock", "GET READY", off(9, 6), u(1, -18, 0, 31), {
		Font = display, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center,
	})
	self.raceDetail = label(self.raceHUD, "Gate count", "", off(9, 37), u(1, -18, 0, 18), {
		Font = bold, TextSize = 11, TextColor3 = P.light, TextXAlignment = Enum.TextXAlignment.Center,
	})
	self.toast = frame(self.root, "Notification", u(0.5, 0, 1, -83), off(352, 42), P.deep, 9)
	self.toast.AnchorPoint = v(0.5, 1)
	stroke(self.toast, P.mint, 0.42)
	self.toastText = label(self.toast, "Message", "", off(12, 0), u(1, -24, 1, 0), {
		TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, Font = bold, TextSize = 13,
	})
	self.toast.Visible = false

	self.shade = new("TextButton", "Close menu backdrop", self.root, {
		Size = scale(1, 1), Text = "", BackgroundColor3 = rgb(5, 11, 23), BackgroundTransparency = 0.36,
		BorderSizePixel = 0, AutoButtonColor = false, Selectable = false, Visible = false,
	})
	self.shade.Activated:Connect(function() self:open(nil) end)
	self.sheet = frame(self.root, "Menu panel", scale(0.5, 0.5), off(736, 488), P.ink, 15)
	self.sheet.AnchorPoint = v(0.5, 0.5)
	self.sheet.Visible = false
	stroke(self.sheet, P.line)
	self.sheet.ClipsDescendants = true
	self.sheetTag = label(self.sheet, "Current district", "GREEN VALLEY", off(23, 13), u(1, -104, 0, 16), {
		TextColor3 = P.mint, Font = bold, TextSize = 10,
	})
	self.sheetTitle = label(self.sheet, "Page title", "", off(22, 28), u(1, -106, 0, 33), {Font = display, TextSize = 27})
	self.back = button(self.sheet, "Close", "Close", u(1, -75, 0, 17), off(54, 34), function() self:open(nil) end)
	self.tabs = frame(self.sheet, "Tabs", off(16, 71), u(1, -32, 0, 37))
	self.tabsList = new("UIListLayout", "Tab layout", self.tabs, {
		FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5),
	})
	for i, page in ipairs(nav) do
		local tab = button(self.tabs, page, page, off(0, 0), u(0.2, -4, 1, 0), function() self:open(page) end)
		tab.LayoutOrder = i
	end
	frame(self.sheet, "Separator", off(20, 117), u(1, -40, 0, 1), P.line)
	self.scroll = new("ScrollingFrame", "Content", self.sheet, {
		Position = off(16, 125), Size = u(1, -32, 1, -140), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = off(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4,
		ScrollBarImageColor3 = P.line, ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	new("UIPadding", "Content padding", self.scroll, {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 2)})
	new("UIListLayout", "Cards", self.scroll, {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 9)})

	self.root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function() self:layout() end)
	self:layout()
	return self
end

function Interface:layout()
	local size = self.root.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	local narrow = size.X < 560
	local touch = UserInputService.TouchEnabled
	local touchPortrait = touch and size.Y > size.X
	local previous = self.narrow
	self.narrow = narrow
	self.top.Position = off(if narrow then 9 else 19, if narrow then 7 else 12)
	self.top.Size = off(if narrow then math.min(size.X - 18, 355) else 388, if narrow then 56 else 64)
	self.logo.TextSize = if narrow then 16 else 19
	self.counters[1].Position = off(if narrow then 153 else 183, 12)
	self.counters[2].Position = off(if narrow then 165 else 200, 9)
	self.counters[3].Position = off(if narrow then 240 else 295, 9)
	self.energy.Position = off(if narrow then 165 else 200, 26)
	self.coins.Position = off(if narrow then 240 else 295, 26)
	local stackGoal = size.X < 705
	self.goal.Position = u(1, if narrow then -9 else -19, 0, if narrow then 71 elseif stackGoal then 85 else 12)
	self.goal.Size = off(if narrow then 211 else 248, if narrow then 78 else 94)
	self.goalNote.Size = u(1, -30, 0, if narrow then 25 else 35)
	self.goalNote.Position = off(15, if narrow then 44 else 48)
	self.goalTitle.Position = off(15, if narrow then 23 else 26)
	self.goalTag.Position = off(15, if narrow then 8 else 10)
	self.goalTrack.Position = u(0, 15, 1, if narrow then -6 else -13)
	self.dock.Size = off(math.min(size.X - 18, 498), 54)
	self.dock.Position = u(0.5, 0, 1, if touchPortrait then -107 elseif narrow then -9 else -17)
	self.dash.Position = u(1, if narrow then -12 else -24, 1, if touchPortrait then -174 elseif touch then -math.clamp(size.Y * 0.23, 103, 235) elseif narrow then -150 else -89)
	self.raceHUD.Position = u(0.5, 0, 0, if narrow then 75 else 93)
	self.toast.Size = off(math.min(size.X - 24, 390), 42)
	self.toast.Position = u(0.5, 0, 1, if touchPortrait then -227 elseif narrow then -65 else -83)
	self.sheet.Size = off(math.min(size.X - 14, 736), math.min(size.Y - 14, 506))
	self.sheetTitle.TextSize = if narrow then 23 else 27
	if previous ~= narrow and self.page then self:render(true) end
end

function Interface:toastMessage(message, tone)
	self.toastId = (self.toastId or 0) + 1
	local id = self.toastId
	self.toastText.Text = message
	self.toastText.TextColor3 = if tone == "victory" then P.gold else P.white
	self.toast.Visible = true
	task.delay(3.0, function()
		if self.toastId == id then self.toast.Visible = false end
	end)
end

function Interface:open(page, detail)
	if page and not pages[page] then return end
	self.page = page
	self.detail = detail
	self.shade.Visible = page ~= nil
	self.sheet.Visible = page ~= nil
	self.dock.Visible = page == nil
	self.sound("click")
	if page then
		self.scroll.CanvasPosition = v(0, 0)
		self:render(true)
		if self.state and self.state.settings.Motion then
			self.sheet.Position = u(0.5, 0, 0.5, 10)
			TweenService:Create(self.sheet, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {Position = scale(0.5, 0.5)}):Play()
		else
			self.sheet.Position = scale(0.5, 0.5)
		end
	end
end

function Interface:clock()
	if not self.state then return end
	local now = workspace:GetServerTimeNow()
	local race = self.state.race
	if race then
		if race.phase == "Countdown" and now < race.starts then
			local count = math.ceil(race.starts - now)
			if count ~= self.lastCount then
				self.lastCount = count
				self.sound("countdown")
			end
			self.raceClock.Text = tostring(count)
			self.raceDetail.Text = race.mode .. "  /  " .. race.count .. " runner" .. (if race.count == 1 then "" else "s")
		else
			self.raceClock.Text = ("%.1fs"):format(math.max(0, now - race.starts))
			self.raceDetail.Text = ("Gate %d of %d  •  Equal speed"):format(math.min(race.gate + 1, race.gates), race.gates)
		end
	else
		self.lastCount = nil
	end
	if self.dash.Visible then
		local waiting = math.ceil((self.state.dash or 0) - now)
		self.dash.Text = if waiting > 0 then ("Dash   %ds"):format(waiting) else (if UserInputService.TouchEnabled then "Dash" else "Dash   Q")
		self.dash.BackgroundColor3 = if waiting > 0 then P.tile else self.accent
		self.dash.TextColor3 = if waiting > 0 then P.light else P.deep
	end
end

function Interface:sync(state)
	self.state = state
	local world = Config.Worlds[state.world]
	self.accent = world.accent
	self.location.Text = string.upper(world.name)
	self.location.TextColor3 = world.accent
	self.energy.Text = number(state.energy)
	self.coins.Text = number(state.coins)
	self.goal.Visible = not state.race and state.tutorial < #instructions
	self.goalTag.Text = ("FIRST RUN  /  %d OF %d"):format(math.min(state.tutorial + 1, #instructions), #instructions)
	local instruction = instructions[state.tutorial + 1]
	if instruction then
		self.goalTitle.Text = instruction[1]
		self.goalNote.Text = instruction[2]
		local progress = if state.tutorial == 0 then math.min(state.stats.Pickups, 3) / 3 else 0
		self.goalFill.Size = scale((state.tutorial + math.max(progress, 0.10)) / #instructions, 1)
	end
	self.goalFill.BackgroundColor3 = world.accent
	self.raceHUD.Visible = state.race ~= nil
	self.dash.Visible = state.speed >= 2 and not state.race and not self.page
	self.top.BackgroundColor3 = if state.settings.HighContrast then Color3.new(0, 0, 0) else P.ink
	self.goal.BackgroundColor3 = self.top.BackgroundColor3
	self.sheet.BackgroundColor3 = self.top.BackgroundColor3
	self.goalTitle.TextSize = if state.settings.LargeText then 17 else 15
	self.goalNote.TextSize = if state.settings.LargeText then 13 else 11
	self:clock()
	if self.page then self:render(false) end
end

function Interface:card(name, height, style)
	self.order += 1
	local base = frame(self.scroll, name, off(0, 0), u(1, 0, 0, height), style or P.panel, 10)
	base.LayoutOrder = self.order
	stroke(base, P.line, 0.54)
	return base
end

function Interface:copy(parent, name, title, description, x, right, height)
	label(parent, name, title, off(x, 7), u(1, -x - right, 0, 24), {
		Font = bold, TextSize = if self.state.settings.LargeText then 17 else 15,
	})
	label(parent, name .. " detail", description, off(x, 33), u(1, -x - right, 0, height or 34), {
		TextColor3 = P.light, TextSize = if self.state.settings.LargeText then 14 else 12,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None,
	})
end

function Interface:row(title, note, action, callback, options)
	options = options or {}
	local right = if action then (if self.narrow then 95 else 140) else 11
	local x = options.x or 14
	local height = options.height or (if self.narrow then 88 else 75)
	local card = self:card(title, height, options.style)
	self:copy(card, "Title", title, note, x, right, height - 36)
	if action then
		local control = button(card, "Action", action, u(1, -11, 0.5, 0), off(right - 20, if self.narrow then 44 else 38), callback, options.primary)
		control.AnchorPoint = v(1, 0.5)
	end
	return card
end

function Interface:section(text)
	self.order += 1
	local item = label(self.scroll, "Section", text, off(0, 0), u(1, 0, 0, 26), {TextColor3 = self.accent, Font = bold, TextSize = 12})
	item.LayoutOrder = self.order
end

function Interface:showWorlds(s)
	for i, world in ipairs(Config.Worlds) do
		local allowed = i <= s.unlocked or (i == s.unlocked + 1 and s.speed >= world.speed and s.stats.Finishes >= world.finishes)
		local state = if i == s.world then "Here" elseif allowed then "Travel" else "Locked"
		local note = world.detail
		if not allowed then note ..= (" Requires Speed %d and %d race finishes."):format(world.speed, world.finishes) end
		local card = self:row(world.name, note, state, if allowed and i ~= s.world then function()
			self.send("travel", i)
			self:open(nil)
		end else nil, {x = 21, height = if self.narrow then 101 else 76, primary = allowed and i ~= s.world})
		frame(card, "District color", off(8, 11), off(3, 36), world.accent, 2)
	end
	self:row("Return to arrival plaza", "Go back to the hub in your current world.", "Return", function()
		self.send("home")
		self:open(nil)
	end)
end

function Interface:showUpgrades(s)
	for _, kind in ipairs({"Speed", "Training"}) do
		local level = s[string.lower(kind)]
		local energy, coins = Config.cost(kind, level)
		local current = if kind == "Speed" then s.runSpeed .. " studs/s" else
			(1 + math.floor((level + 1) / 2)) .. " base Energy every 7 studs"
		local cost = if level < 12 then ("Next upgrade  •  %d Energy + %d Coins"):format(energy, coins) else "Maximum level reached."
		self:row(("%s  /  Level %d"):format(kind, level), current .. "\n" .. cost,
			if level >= 12 then "Max level" else "Upgrade",
			if level < 12 and s.energy >= energy and s.coins >= coins then function() self.send("upgrade", kind) end else nil,
			{height = 92, primary = true})
	end
	self:row("Dash", "Unlocks at Speed level 2. Press Q or tap Dash between races. Recharge takes 7 seconds.",
		if s.speed >= 2 then "Unlocked" else "Locked", nil, {height = 98})
	local eligible = s.unlocked == #Config.Worlds and s.speed >= 10 and s.prestige < 100
	self:row(("Prestige  /  Rank %d"):format(s.prestige),
		"Unlock Cosmic Rift and reach Speed 10. Reset Speed, Training and Energy. Keep Coins, worlds, creatures, and records. Earn the Prestige Crest and +6% Energy per rank, up to +180%.",
		if self.detail == "Prestige" then "Confirm" else "Prestige",
		if eligible then function()
			if self.detail == "Prestige" then
				self.detail = nil
				self.send("prestige")
			else
				self.detail = "Prestige"
				self:render(true)
			end
		end else nil, {height = if self.narrow then 151 else 101})
end

function Interface:showCreatures(s)
	for _, info in ipairs(Config.Creatures) do
		local unlocked = s.creatures[info.id] == true
		local active = s.equipped == info.id
		local action = if active then "Unequip" elseif unlocked then "Equip" else "Locked"
		local detail = (if unlocked then "" else info.where .. ". ") .. ("Up to +%d%% Energy while equipped."):format(info.bonus)
		local previewSize = if self.narrow then 51 else 66
		local card = self:row(info.name, detail, action, if unlocked then function()
			self.send("equip", if active then "" else info.id)
		end else nil, {x = previewSize + 20, height = if self.narrow then 96 else 86, primary = unlocked and not active})
		viewport(card, Models.creature(info), off(previewSize, previewSize), off(8, 8))
	end
end

function Interface:showRaces(s)
	local world = Config.Worlds[s.world]
	if s.race then
		self:row(world.race, "Equal speed. Follow each lit checkpoint in order.", "Leave race", function()
			self.send("quit")
			self:open(nil)
		end, {height = 88})
	else
		self:row(world.race, "Join the next heat. Solo finishes count toward progression. All runners use the same speed.", "Join race", function()
			self.send("race")
			self:open(nil)
		end, {height = 99, primary = true})
	end
	self:row("Spark Rally", ("%d / %d sparks  •  %d runners\nYou contributed %d. Two runners need at least 5 each."):format(
		math.min(s.rally.total, s.rally.target), s.rally.target, s.rally.runners, s.rally.mine), if s.rally.joined then "Leave" else "Join rally", function()
		self.send("rally")
	end, {height = 94})
	if s.duel and s.duel.expires > workspace:GetServerTimeNow() then
		self:row("Friend duel", s.duel.name .. " invited you to race.", "Accept", function()
			self.send("accept")
			self:open(nil)
		end, {primary = true})
	end
	if #s.roster > 0 then
		self:section("CHALLENGE A ROBLOX FRIEND")
		for _, runner in ipairs(s.roster) do
			self:row(runner.name, "Same world", "Invite", function() self.send("challenge", runner.id) end)
		end
	end
	self:section("PERSONAL BEST  /  " .. time(s.best[tostring(s.world)]))
	local last = self.standings[s.world]
	if last then
		self:section("LAST HEAT")
		for _, record in ipairs(last) do self:row(("%d. %s"):format(record.rank, record.name), time(record.time), nil, nil, {height = 60}) end
	end
	self:section("SERVER RECORDS")
	if #s.board == 0 then self:row("No times yet", "Finish a race to set the first server record.", nil, nil, {height = 65}) end
	for i, record in ipairs(s.board) do self:row(("%d. %s"):format(i, record.name), time(record.time), nil, nil, {height = 60}) end
	if #s.globalBoard > 0 then
		self:section("GLOBAL RECORDS")
		for i, record in ipairs(s.globalBoard) do self:row(("%d. %s"):format(i, record.name), time(record.time), nil, nil, {height = 60}) end
	end
end

function Interface:showClaims(s, achievement)
	local entries = if achievement then Config.Achievements else s.quests
	for _, entry in ipairs(entries) do
		local record = if achievement then s.achievements[entry.id] else entry
		local title = if achievement then entry.title else entry.label .. "  /  " .. entry.text
		local ready = if achievement then record.ready else record.progress >= entry.target
		local grant = if record.claimed then "Claimed" elseif ready then "Claim" else "In progress"
		local note
		if entry.course then
			note = ("Best %s  •  Target %s  •  %d Coins"):format(time(if record.progress > 0 then record.progress else nil), time(entry.target), entry.reward)
		elseif entry.id == "mastery" then
			note = ("%d / %d courses mastered  •  %d Coins and Mastery Ribbon"):format(math.min(record.progress, entry.target), entry.target, entry.reward)
		else
			note = ("%s%d / %d  •  %d Coins"):format(if achievement then entry.metric .. "  " else "",
				math.min(record.progress, entry.target), entry.target, entry.reward)
		end
		self:row(title, note, grant,
			if grant == "Claim" then function() self.send("claim", entry.id) end else nil, {primary = true})
	end
end

function Interface:showInventory(s)
	local items = {}
	if s.freeTrail then table.insert(items, {"Valley Ribbon", "Green trail earned through First Light."}) end
	if s.masteryTrail then table.insert(items, {"Mastery Ribbon", "Gold and mint trail earned through Versatile Runner."}) end
	if s.prestige > 0 then table.insert(items, {"Prestige Crest", "Mint crown earned through Prestige."}) end
	for _, entry in ipairs(Catalog) do
		if s.owned[entry.id] then
			for _, item in ipairs(entry.items or {}) do table.insert(items, {item, entry.name}) end
		end
	end
	if #items == 0 then
		self:row("Valley Ribbon", "Collect 12 sparks and claim First Light to earn your first trail.", "Achievements",
			function() self:open("Achievements") end, {height = 100})
		return
	end
	for _, item in ipairs(items) do
		local equipped = false
		for _, value in pairs(s.cosmetics) do if value == item[1] then equipped = true end end
		self:row(item[1], item[2], if equipped then "Unequip" else "Equip", function() self.send("cosmetic", item[1]) end, {primary = not equipped})
	end
end

function Interface:market(info)
	if not info.assetId or self.productInfo[info.id] then return end
	self.productInfo[info.id] = {loading = true}
	task.spawn(function()
		local ok, listing = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, info.assetId,
			if info.kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		self.productInfo[info.id] = if ok and listing then {price = listing.PriceInRobux, forSale = listing.IsForSale == true} else {}
		self.marketRevision += 1
		if self.page == "Shop" then self:render(false) end
	end)
end

function Interface:showShop(s)
	if self.detail then
		self:row("Browse catalog", "Optional cosmetics and progression boosts.", "View all", function() self:open("Shop") end, {height = 67})
	end
	for _, info in ipairs(Catalog) do
		if self.detail and self.detail ~= info.id then continue end
		self:market(info)
		local listing = self.productInfo[info.id]
		local owned = s.owned[info.id]
		local available = Config.PurchasesEnabled and (not RunService:IsStudio() or Config.StudioPurchasePrompts)
			and listing and listing.forSale and type(listing.price) == "number"
		local labelText = if owned then "Owned" elseif available then listing.price .. " Robux" elseif listing and listing.loading then "Checking" else "Unavailable"
		local previewSize = if self.narrow then 50 else 74
		local callback = if available and not owned then function()
			self.send("buy", info.id)
		end else nil
		local card
		if self.narrow then
			card = self:card(info.name, 145)
			self:copy(card, "Title", info.name, info.details, previewSize + 20, 10, 65)
			button(card, "Action", labelText, u(1, -122, 1, -44), off(110, 35), callback, callback ~= nil)
		else
			card = self:row(info.name, info.details, labelText, callback, {x = previewSize + 20, height = 100, primary = callback ~= nil})
		end
		viewport(card, Models.product(info), off(previewSize, previewSize), off(8, 9), 0)
		if info.id == "starter" or info.id == "founder" then
			local creature = if info.id == "starter" then Config.Creatures[3] else Config.Creatures[8]
			local skin = if info.id == "starter" then "Aurora Cub" else "Eventide Wisp"
			local skinCard = self:row(skin, "Creature skin preview", nil, nil, {x = previewSize + 20, height = previewSize + 18})
			viewport(skinCard, Models.creature(creature, skin), off(previewSize, previewSize), off(8, 8))
		end
	end
end

function Interface:showSettings(s)
	local options = {
		{"Effects", "Visual effects", "Trails, spark particles, and companion animation."},
		{"Motion", "Reduced motion", "Use simpler menu transitions and a steady race camera."},
		{"HighContrast", "High contrast", "Use darker panels behind key labels."},
		{"LargeText", "Larger text", "Increase the size of instructions and menu text."},
	}
	for _, option in ipairs(options) do
		local key = option[1]
		local current = s.settings[key]
		self:row(option[2], option[3], if (if key == "Motion" then not current else current) then "On" else "Off",
			function() self.send("setting", key, not current) end)
	end
	local volume = s.settings.Volume
	local card = self:row("Volume", ("%d%%  •  Game sounds"):format(math.floor(volume * 100 + 0.5)), nil, nil, {height = 72})
	local down = button(card, "Lower volume", "−", u(1, -102, 0, 15), off(41, 41), function()
		self.send("setting", "Volume", math.max(0, volume - 0.10))
	end)
	local up = button(card, "Raise volume", "+", u(1, -53, 0, 15), off(41, 41), function()
		self.send("setting", "Volume", math.min(1, volume + 0.10))
	end)
	down.TextSize = 20
	up.TextSize = 20
end

function Interface:showMenu()
	for _, page in ipairs(more) do
		local info = ({
			Quests = "Daily and weekly challenges", Achievements = "Milestones and rewards", Inventory = "Equip your cosmetics",
			Shop = "Inspect optional items", Settings = "Effects, accessibility, and sound",
			Statistics = "Records and lifetime progress", Tutorial = "Movement, upgrades, and races",
		})[page]
		self:row(pages[page], info, "Open", function() self:open(page) end, {height = 64})
	end
end

function Interface:showStatistics(s)
	for _, item in ipairs({
		{"Run distance", number(s.stats.Run) .. " studs"}, {"Sparks collected", number(s.stats.Pickups)},
		{"Race finishes", number(s.stats.Finishes)}, {"Multiplayer wins", number(s.stats.Wins)},
		{"Secrets discovered", count(s.secrets) .. " / " .. #Config.Worlds},
		{"Creatures discovered", count(s.creatures) .. " / " .. #Config.Creatures},
		{"Prestige rank", number(s.prestige)},
	}) do
		self:row(item[1], item[2], nil, nil, {height = 64})
	end
end

function Interface:showTutorial()
	for _, step in ipairs(instructions) do self:row(step[1], step[2], nil, nil, {height = 67}) end
	self:row("Movement", "Use WASD or the touch thumbstick to run. Jump with Space or the jump button. Use Q or Dash after reaching Speed level 2.",
		nil, nil, {height = 95})
	self:row("Race checkpoints", "Run through the lit gates in order. You can enter a heat alone or race other players in the same world.",
		nil, nil, {height = 93})
	self:row("World gates", "Finish races and upgrade Speed to reach new worlds. Open Worlds from anywhere between races.",
		"Worlds", function() self:open("Worlds") end, {height = 96})
end

function Interface:render(force)
	local page = self.page
	if not page then return end
	local s = self.state
	self.sheetTitle.Text = pages[page]
	self.sheetTag.Text = if s then string.upper(Config.Worlds[s.world].name) else "DASHVERSE"
	self.sheetTag.TextColor3 = self.accent
	self.dash.Visible = false
	for _, tab in ipairs(self.tabs:GetChildren()) do
		if tab:IsA("TextButton") then
			local active = tab.Name == page or (tab.Name == "Menu" and table.find(more, page) ~= nil)
			tab.BackgroundColor3 = if active then self.accent else P.tile
			tab.TextColor3 = if active then P.deep else P.white
		end
	end
	local key = page .. (self.detail or "") .. (if self.narrow then "n" else "w")
	if s then
		local extra
		if page == "Worlds" then extra = {s.world, s.speed, s.unlocked, s.stats.Finishes}
		elseif page == "Upgrades" then
			local a, b = Config.cost("Speed", s.speed)
			local c, d = Config.cost("Training", s.training)
			extra = {s.speed, s.training, s.prestige, s.unlocked, s.energy >= a and s.coins >= b, s.energy >= c and s.coins >= d}
		elseif page == "Creatures" then extra = {s.creatures, s.equipped}
		elseif page == "Races" then extra = {s.world, s.race ~= nil, s.rally, s.duel or false, s.roster, s.best, s.board, s.globalBoard, self.standings}
		elseif page == "Quests" then extra = s.quests
		elseif page == "Achievements" then extra = s.achievements
		elseif page == "Inventory" then extra = {s.owned, s.cosmetics, s.freeTrail, s.masteryTrail, s.prestige}
		elseif page == "Shop" then extra = {s.owned, self.marketRevision}
		elseif page == "Settings" then extra = s.settings
		elseif page == "Statistics" then extra = {s.stats, s.secrets, s.creatures, s.prestige}
		else extra = {} end
		key ..= HttpService:JSONEncode({s.settings.LargeText, extra})
	end
	if key == self.renderKey and not force then return end
	self.renderKey = key
	local position = self.scroll.CanvasPosition
	for _, child in ipairs(self.scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	self.order = 0
	if not s then
		self:section("LOADING RUNNER PROFILE")
	elseif page == "Worlds" then self:showWorlds(s)
	elseif page == "Upgrades" then self:showUpgrades(s)
	elseif page == "Creatures" then self:showCreatures(s)
	elseif page == "Races" then self:showRaces(s)
	elseif page == "Quests" then self:showClaims(s, false)
	elseif page == "Achievements" then self:showClaims(s, true)
	elseif page == "Inventory" then self:showInventory(s)
	elseif page == "Shop" then self:showShop(s)
	elseif page == "Settings" then self:showSettings(s)
	elseif page == "Statistics" then self:showStatistics(s)
	elseif page == "Tutorial" then self:showTutorial()
	else self:showMenu() end
	self.scroll.CanvasPosition = position
end

return Interface
