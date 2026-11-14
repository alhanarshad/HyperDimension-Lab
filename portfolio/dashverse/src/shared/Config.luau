local V = Vector3.new
local rgb = Color3.fromRGB

local Config = {
	Name = "DASHVERSE",
	Subtitle = "SPEED & CREATURES",
	Studio = "Veltrix Studios",
	Version = "0.1.1",
	DataStore = "DashverseProfiles_v1",
	BoardStore = "DashverseRaceTimes_v1",
	StudioPersistentData = false,
	StudioPurchasePrompts = false,
	PurchasesEnabled = false,
	MaxSpeed = 54,
	BaseSpeed = 17,
	RaceSpeed = 34,
	Countdown = 6,
	RaceTimeout = 95,
	MaxNumber = 10^12,
	Spawn = V(0, 3.5, 83),
}

Config.Worlds = {
	{
		name = "Green Valley", race = "River Circuit", offset = V(0, 0, 0),
		accent = rgb(102, 255, 188), road = rgb(42, 101, 84), terrain = rgb(93, 168, 96),
		light = rgb(208, 239, 224), mood = rgb(125, 205, 203),
		detail = "Follow the river across two bridges and find the grotto behind the falls.",
		secret = V(-124, 1, -94), secretName = "Fern Grotto", feature = "River bridges",
		route = {V(0, 0, 29), V(0, 0, -25), V(56, 0, -74), V(105, 0, -106), V(104, 0, -155), V(54, 0, -198), V(-4, 0, -203), V(-60, 0, -160), V(-80, 0, -100), V(-45, 0, -55), V(-26, 0, -18)},
	},
	{
		name = "Neon City", race = "Skyline Relay", offset = V(850, 0, 0),
		accent = rgb(80, 237, 255), road = rgb(37, 47, 84), terrain = rgb(41, 43, 66),
		light = rgb(187, 207, 255), mood = rgb(109, 116, 204),
		detail = "Run the rooftop ramps and use slipstream pads between races.",
		secret = V(105, 28, -79), secretName = "Signal Loft", feature = "Slipstream ramps",
		speed = 2, finishes = 1,
		route = {V(0, 0, 29), V(0, 0, -16), V(0, 14, -65), V(48, 27, -108), V(100, 27, -108), V(133, 27, -155), V(76, 14, -201), V(11, 0, -205), V(-48, 0, -151), V(-58, 0, -83), V(-27, 0, -26)},
	},
	{
		name = "Crystal Canyon", race = "Prism Descent", offset = V(1700, 0, 0),
		accent = rgb(204, 145, 255), road = rgb(87, 66, 112), terrain = rgb(137, 87, 125),
		light = rgb(238, 201, 246), mood = rgb(163, 126, 214),
		detail = "Descend into the geode tunnels and charge crystal springs.",
		secret = V(76, -13, -142), secretName = "Amethyst Hollow", feature = "Crystal springs",
		speed = 4, finishes = 2,
		route = {V(0, 0, 29), V(0, 0, -14), V(-9, -15, -59), V(32, -15, -97), V(59, -15, -145), V(38, -15, -193), V(-16, -15, -206), V(-70, -8, -172), V(-82, 0, -115), V(-63, 0, -60), V(-26, 0, -22)},
	},
	{
		name = "Floating Skylands", race = "Cloudway Cup", offset = V(2550, 0, 0),
		accent = rgb(255, 223, 140), road = rgb(115, 114, 164), terrain = rgb(115, 162, 148),
		light = rgb(255, 232, 189), mood = rgb(175, 195, 241),
		detail = "Cross suspended bridges and ride updrafts above the clouds.",
		secret = V(101, 18, -116), secretName = "Sun Nest", feature = "Updrafts",
		speed = 6, finishes = 3,
		route = {V(0, 0, 29), V(0, 0, -19), V(28, 8, -71), V(70, 18, -111), V(85, 18, -161), V(37, 11, -211), V(-14, 11, -224), V(-65, 4, -182), V(-82, 4, -129), V(-69, 0, -74), V(-27, 0, -26)},
	},
	{
		name = "Meteor Wasteland", race = "Ember Traverse", offset = V(3400, 0, 0),
		accent = rgb(255, 163, 95), road = rgb(102, 69, 73), terrain = rgb(114, 71, 66),
		light = rgb(250, 208, 172), mood = rgb(193, 128, 117),
		detail = "Circle the impact basin and follow cooling vents to meteor fragments.",
		secret = V(105, 0, -169), secretName = "Ember Cache", feature = "Thermal vents",
		speed = 8, finishes = 4,
		route = {V(0, 0, 29), V(0, 0, -24), V(44, 0, -61), V(103, 3, -92), V(127, 3, -148), V(84, -3, -195), V(14, -3, -217), V(-47, 0, -202), V(-84, 0, -142), V(-70, 0, -78), V(-27, 0, -28)},
	},
	{
		name = "Cosmic Rift", race = "Event Horizon", offset = V(4250, 0, 0),
		accent = rgb(233, 153, 255), road = rgb(67, 50, 112), terrain = rgb(57, 47, 94),
		light = rgb(219, 194, 255), mood = rgb(107, 93, 188),
		detail = "Traverse floating rings and harness low-gravity launch fields.",
		secret = V(114, 14, -115), secretName = "Eventide Observatory", feature = "Rift lifts",
		speed = 10, finishes = 5,
		route = {V(0, 0, 29), V(0, 0, -23), V(34, 10, -79), V(91, 14, -109), V(123, 14, -162), V(82, 6, -208), V(16, 12, -233), V(-41, 12, -207), V(-84, 3, -153), V(-67, 3, -94), V(-26, 0, -33)},
	},
}

Config.Creatures = {
	{id = "Fox", name = "Spark Fox", where = "Collect 3 energy sparks", goal = "Pickups", target = 3, bonus = 10, style = "fox", color = rgb(255, 168, 75)},
	{id = "Gecko", name = "Neon Gecko", where = "Visit Neon City", goal = "Unlocked", target = 2, bonus = 14, style = "gecko", color = rgb(96, 246, 162)},
	{id = "Cub", name = "Crystal Cub", where = "Find Amethyst Hollow in Crystal Canyon", goal = "Secret", target = 3, bonus = 19, style = "cub", color = rgb(202, 145, 255)},
	{id = "Bunny", name = "Cloud Bunny", where = "Visit Floating Skylands", goal = "Unlocked", target = 4, bonus = 22, style = "bunny", color = rgb(240, 235, 255)},
	{id = "Owl", name = "Thunder Owl", where = "Finish 5 races", goal = "Finishes", target = 5, bonus = 24, style = "owl", color = rgb(255, 220, 110)},
	{id = "Meteor", name = "Mini Meteor", where = "Find the Ember Cache in Meteor Wasteland", goal = "Secret", target = 5, bonus = 27, style = "meteor", color = rgb(255, 129, 83)},
	{id = "Turtle", name = "Lava Turtle", where = "Collect 180 energy sparks", goal = "Pickups", target = 180, bonus = 29, style = "turtle", color = rgb(241, 114, 137)},
	{id = "Wisp", name = "Galaxy Wisp", where = "Find Eventide Observatory in Cosmic Rift", goal = "Secret", target = 6, bonus = 32, style = "wisp", color = rgb(184, 147, 255)},
}

Config.Achievements = {
	{id = "first_run", title = "First Light", metric = "Pickups", target = 12, reward = 75},
	{id = "racer", title = "Across the Line", metric = "Finishes", target = 1, reward = 100},
	{id = "scout", title = "Off the Map", metric = "Secrets", target = 3, reward = 240},
	{id = "crew", title = "In Good Company", metric = "Creatures", target = 4, reward = 300},
	{id = "atlas", title = "Across the Verse", metric = "Unlocked", target = 6, reward = 800},
	{id = "legacy", title = "Velocity Legacy", metric = "Prestige", target = 1, reward = 500},
	{id = "mastery", title = "Versatile Runner", metric = "Mastered", target = 4, reward = 700},
}

local masteryTimes = {22000, 23500, 21000, 22000, 23500, 24000}
for index, limit in ipairs(masteryTimes) do
	table.insert(Config.Achievements, {
		id = "course_" .. index, title = Config.Worlds[index].race .. " Mastery",
		metric = "Course", course = index, target = limit, reward = 110 + 25 * index,
	})
end

Config.QuestPools = {
	{ id = "day", title = "Daily", tasks = {
		{metric = "Pickups", verb = "Collect %d sparks", target = 18, coins = 90},
		{metric = "Run", verb = "Run %d studs", target = 800, coins = 100},
		{metric = "Finishes", verb = "Finish %d race", target = 1, coins = 115},
	}},
	{ id = "week", title = "Weekly", tasks = {
		{metric = "Pickups", verb = "Collect %d sparks", target = 100, coins = 650},
		{metric = "Finishes", verb = "Finish %d races", target = 5, coins = 750},
		{metric = "Run", verb = "Run %d studs", target = 6500, coins = 700},
	}},
}

Config.Settings = {
	Effects = true, Motion = true, HighContrast = false, LargeText = false, Volume = 0.55,
}

Config.Audio = {
	pickup = {fallback = "rbxasset://sounds/volume_slider.ogg", pitch = 1.8},
	upgrade = {fallback = "rbxasset://sounds/volume_slider.ogg", pitch = 1.05},
	countdown = {fallback = "rbxasset://sounds/volume_slider.ogg", pitch = 0.8},
	victory = {fallback = "rbxasset://sounds/volume_slider.ogg", pitch = 1.25},
	click = {fallback = "rbxasset://sounds/volume_slider.ogg", pitch = 1.35},
	dash = {fallback = "rbxasset://sounds/action_jump.mp3", pitch = 1.15},
	ambience = {},
}

function Config.speed(level)
	return math.min(Config.MaxSpeed, Config.BaseSpeed + level * 3)
end

function Config.cost(kind, level)
	if kind == "Speed" then
		return math.floor(14 + 8 * level^1.58), math.floor(8 + 5 * level^1.55)
	end
	return math.floor(20 + 9 * level^1.65), math.floor(16 + 7 * level^1.5)
end

function Config.quest(pool, now)
	local period = if pool.id == "day" then math.floor(now / 86400) else math.floor((now + 259200) / 604800)
	return period, pool.tasks[1 + period % #pool.tasks]
end

return Config
