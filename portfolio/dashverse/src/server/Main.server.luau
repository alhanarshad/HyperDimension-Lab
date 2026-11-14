local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local AnalyticsService = game:GetService("AnalyticsService")

local shared = ReplicatedStorage:WaitForChild("Dashverse")
local Config = require(shared.Config)
local Catalog = require(shared.Catalog)
local Profiles = require(script.Parent.Profiles)
local World = require(script.Parent.World)
local Races = require(script.Parent.Races)

local V = Vector3.new
local contexts = {}
local creatures = {}
local products = {}
local passes = {}
local pickups = {}
local features = {}
local boards = {}
local rallies = {}
local races
local studio = RunService:IsStudio()
local playerGroup = "DashverseRunners"

for _, creature in ipairs(Config.Creatures) do creatures[creature.id] = creature end
for _, info in ipairs(Catalog) do
	products[info.id] = info
	if info.assetId and info.kind == "Pass" then passes[info.assetId] = info end
end

local function event(name)
	local object = shared:FindFirstChild(name) or Instance.new("RemoteEvent")
	object.Name = name
	object.Parent = shared
	return object
end
local command = event("Command")
local message = event("Message")

local function analytics(player, kind, name, value)
	if studio then return end
	task.defer(function()
		local ok, problem = pcall(function()
			if kind == "onboarding" then
				AnalyticsService:LogOnboardingFunnelStepEvent(player, value, name)
			else
				AnalyticsService:LogCustomEvent(player, name, value)
			end
		end)
		if not ok then warn("[Dashverse] Analytics: " .. tostring(problem)) end
	end)
end

local function notice(player, label, effect)
	if player.Parent == Players then message:FireClient(player, "notice", label, effect) end
end

local function bodyFor(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function ownedItem(ctx, item)
	if item == "Valley Ribbon" then return ctx.data.Claims.first_run == true end
	if item == "Mastery Ribbon" then return ctx.data.Claims.mastery == true end
	if item == "Prestige Crest" then return ctx.data.Prestige > 0 end
	for key in pairs(ctx.owned) do
		local items = products[key].items
		if items and table.find(items, item) then return true end
	end
	return false
end

local function cosmeticSlot(item)
	if string.find(item, "Ribbon", 1, true) then return "trail" end
	if string.find(item, "Spark", 1, true) then return "effect" end
	if string.find(item, "Shoes", 1, true) then return "shoes" end
	if string.find(item, "Halo", 1, true) or string.find(item, "Crown", 1, true) or item == "Prestige Crest" then return "head" end
	return "skin"
end

local function updateAppearance(player, ctx)
	player:SetAttribute("DV_Creature", ctx.data.Equipped)
	for _, slot in ipairs({"trail", "effect", "shoes", "head", "skin"}) do
		local item = ctx.data.Cosmetics[slot]
		player:SetAttribute("DV_" .. slot, if type(item) == "string" and ownedItem(ctx, item) then item else "")
	end
end

local function chooseQuest(ctx, pool)
	local now = os.time()
	local period, taskInfo = Config.quest(pool, now)
	local entry = ctx.data.Quests[pool.id]
	if type(entry) ~= "table" or entry.period ~= period or type(entry.base) ~= "number" then
		entry = {period = period, base = ctx.data.Stats[taskInfo.metric], claimed = false}
		ctx.data.Quests[pool.id] = entry
	end
	return entry, taskInfo
end

local function count(dictionary)
	local total = 0
	for _, value in pairs(dictionary) do if value == true then total += 1 end end
	return total
end

local function metric(data, key)
	if key == "Secrets" then return count(data.Secrets) end
	if key == "Creatures" then return count(data.Creatures) end
	if key == "Mastered" then
		local total = 0
		for _, achievement in ipairs(Config.Achievements) do
			local best = achievement.course and data.Best[tostring(achievement.course)]
			if type(best) == "number" and best > 0 and best <= achievement.target then total += 1 end
		end
		return total
	end
	return data.Stats[key] or data[key] or 0
end

local function achievementProgress(data, item)
	if item.course then
		local best = data.Best[tostring(item.course)]
		if type(best) == "number" and best > 0 then return best, best <= item.target end
		return 0, false
	end
	local progress = metric(data, item.metric)
	return progress, progress >= item.target
end

local function canTravel(data, index)
	local world = Config.Worlds[index]
	return world ~= nil and (index <= data.Unlocked or
		(index == data.Unlocked + 1 and data.Speed >= world.speed and data.Stats.Finishes >= world.finishes))
end

local function status(player, force)
	local ctx = contexts[player]
	if not ctx or not ctx.ready or player.Parent ~= Players then return end
	if not force and os.clock() - ctx.lastSend < 0.48 then return end
	ctx.lastSend = os.clock()
	local data = ctx.data
	local quests = {}
	for _, pool in ipairs(Config.QuestPools) do
		local entry, taskInfo = chooseQuest(ctx, pool)
		table.insert(quests, {id = pool.id, label = pool.title, text = taskInfo.verb:format(taskInfo.target),
			progress = math.max(0, data.Stats[taskInfo.metric] - entry.base), target = taskInfo.target, reward = taskInfo.coins,
			claimed = entry.claimed == true})
	end
	local achievements = {}
	for _, item in ipairs(Config.Achievements) do
		local progress, ready = achievementProgress(data, item)
		achievements[item.id] = {progress = progress, ready = ready, claimed = data.Claims[item.id] == true}
	end
	local leaderboard = ctx.leaderstats
	if leaderboard then
		leaderboard.Coins.Value = data.Coins
		leaderboard.Speed.Value = Config.speed(data.Speed)
		leaderboard.Wins.Value = data.Stats.Wins
	end
	local worldBoard = boards[ctx.world]
	local localBoard = {}
	for _, row in pairs(worldBoard.localRows) do table.insert(localBoard, row) end
	table.sort(localBoard, function(a, b) return a.time < b.time end)
	while #localBoard > 8 do table.remove(localBoard) end
	local roster = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local partner = contexts[other]
		if other ~= player and partner and partner.ready and partner.world == ctx.world then
			table.insert(roster, {id = other.UserId, name = other.DisplayName})
		end
	end
	local rally = rallies[ctx.world]
	message:FireClient(player, "state", {
		energy = data.Energy, coins = data.Coins, speed = data.Speed, training = data.Training, runSpeed = Config.speed(data.Speed),
		prestige = data.Prestige, unlocked = data.Unlocked, world = ctx.world, tutorial = data.Tutorial, stats = data.Stats,
		creatures = data.Creatures, equipped = data.Equipped, quests = quests, achievements = achievements, secrets = data.Secrets,
		settings = data.Settings, best = data.Best, owned = ctx.owned, cosmetics = data.Cosmetics, freeTrail = data.Claims.first_run == true,
		masteryTrail = data.Claims.mastery == true,
		race = races:describe(player), board = localBoard, globalBoard = worldBoard.globalRows, roster = roster,
		rally = {total = rally.total, mine = rally.participants[player] or 0, joined = rally.participants[player] ~= nil,
			target = 32, runners = rally.count}, duel = ctx.duel and {name = ctx.duel.player.DisplayName, expires = ctx.duel.expires},
		dash = ctx.dashReady or 0,
	})
end

local function restoreSpeed(player)
	local ctx = contexts[player]
	local _, humanoid = bodyFor(player)
	if not ctx or not humanoid then return end
	humanoid.WalkSpeed = Config.speed(ctx.data.Speed)
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
end

local function relocate(player, ctx, index)
	local root, humanoid = bodyFor(player)
	ctx.world = index
	ctx.previous = nil
	ctx.moveBudget = 14
	ctx.travelAt = os.clock()
	local destination = Config.Spawn + Config.Worlds[index].offset
	ctx.safePosition = destination
	player:SetAttribute("DV_World", index)
	if root and humanoid and humanoid.Health > 0 then
		root.AssemblyLinearVelocity = V(0, 0, 0)
		root.AssemblyAngularVelocity = V(0, 0, 0)
		player.Character:PivotTo(CFrame.new(destination))
	end
end

local function addCoins(ctx, amount)
	local multiplier = if ctx.owned.coinboost then 3 else 1
	local granted = math.floor(amount * multiplier)
	ctx.data.Coins = math.min(Config.MaxNumber, ctx.data.Coins + granted)
	return granted
end

local function addEnergy(ctx, amount, source)
	local creature = creatures[ctx.data.Equipped]
	local companion = if creature then 1 + creature.bonus / 100 else 1
	local legacy = 1 + math.min(ctx.data.Prestige, 30) * 0.06
	local speedPass = (source == "Run" or source == "Pickup") and ctx.owned.energy
	local trainingPass = source == "Run" and ctx.owned.training
	local boost = math.max(companion, legacy, if speedPass then 2 else 1, if trainingPass then 4 else 1)
	local precise = amount * boost + ctx.data.EnergyFraction
	local granted = math.floor(precise)
	ctx.data.EnergyFraction = precise - granted
	ctx.data.Energy = math.min(Config.MaxNumber, ctx.data.Energy + granted)
	return granted
end

local function milestone(player, ctx, stage, text)
	if ctx.data.Tutorial ~= stage - 1 then return end
	ctx.data.Tutorial = stage
	analytics(player, "onboarding", text, stage + 1)
end

local function discoverCreatures(player, ctx)
	local data = ctx.data
	for _, creature in ipairs(Config.Creatures) do
		local met = if creature.goal == "Secret" then data.Secrets[tostring(creature.target)] == true
			else metric(data, creature.goal) >= creature.target
		if not data.Creatures[creature.id] and met then
			data.Creatures[creature.id] = true
			if data.Equipped == "" then
				data.Equipped = creature.id
				updateAppearance(player, ctx)
			end
			notice(player, creature.name .. " joined your collection!", "upgrade")
		end
	end
end

local function addRally(player, ctx)
	local rally = rallies[ctx.world]
	local contributions = rally.participants[player]
	if contributions == nil then return end
	rally.participants[player] = contributions + 1
	rally.total += 1
	local eligible = {}
	for partner, points in pairs(rally.participants) do
		if points >= 5 then table.insert(eligible, partner) end
	end
	if rally.total >= 32 and #eligible >= 2 then
		for partner in pairs(rally.participants) do rally.participants[partner] = 0 end
		rally.total = 0
		for _, partner in ipairs(eligible) do
			local runner = contexts[partner]
			if runner and Profiles.get(partner) then
				local coins = addCoins(runner, 145)
				addEnergy(runner, 55)
				notice(partner, ("Spark Rally complete! +%d Coins"):format(coins), "victory")
			end
		end
	end
end

local function collect(player, ctx, record, now)
	ctx.cooldowns[record.id] = now + 13
	local energy = addEnergy(ctx, record.value, "Pickup")
	local coins = addCoins(ctx, 2 + math.floor(ctx.world / 3))
	ctx.data.Stats.Pickups += 1
	message:FireClient(player, "pickup", record.id, energy, coins, 13)
	if ctx.data.Stats.Pickups >= 3 then milestone(player, ctx, 1, "Collect three sparks") end
	discoverCreatures(player, ctx)
	addRally(player, ctx)
end

local function orderedStore(index)
	return DataStoreService:GetOrderedDataStore(Config.BoardStore, "world" .. index)
end

local function refreshBoard(index)
	if not Profiles.isPersistent() then return end
	local success, page = pcall(function()
		return orderedStore(index):GetSortedAsync(true, 8):GetCurrentPage()
	end)
	if not success then
		warn("[Dashverse] Could not refresh race leaderboard: " .. tostring(page))
		return
	end
	local rows = {}
	for _, row in ipairs(page) do
		local userId = tonumber(row.key)
		if userId then
			local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			table.insert(rows, {name = if ok then name else "Runner " .. userId, time = row.value})
		end
	end
	boards[index].globalRows = rows
end

races = Races.new({
	notice = notice,
	push = function(player) status(player, true) end,
	restore = restoreSpeed,
	enter = function(player)
		local ctx = contexts[player]
		ctx.previous = nil
		ctx.safePosition = nil
		ctx.dashUntil = nil
		ctx.featureUntil = nil
		analytics(player, "custom", "Race Joined", 1)
	end,
	finish = function(player, index, elapsed, rank, competitive)
		local ctx = contexts[player]
		if not ctx or not Profiles.get(player) then return end
		for _, pool in ipairs(Config.QuestPools) do chooseQuest(ctx, pool) end
		local data = ctx.data
		data.Stats.Finishes += 1
		if rank == 1 and competitive then data.Stats.Wins += 1 end
		local coins = addCoins(ctx, 64 + index * 18 + (if competitive and rank == 1 then 30 else 0))
		local ms = math.floor(elapsed * 1000 + 0.5)
		local key = tostring(index)
		if type(data.Best[key]) ~= "number" or ms < data.Best[key] then
			data.Best[key] = ms
			boards[index].localRows[player.UserId] = {name = player.DisplayName, time = ms}
			if Profiles.isPersistent() then
				task.spawn(function()
					local ok, problem = pcall(function()
						orderedStore(index):UpdateAsync(tostring(player.UserId), function(previous)
							return math.min(previous or ms, ms)
						end)
					end)
					if not ok then warn("[Dashverse] Could not save race record: " .. tostring(problem)) end
				end)
			end
		end
		addEnergy(ctx, 29 + index * 10)
		milestone(player, ctx, 3, "Finish a race")
		discoverCreatures(player, ctx)
		notice(player, ("Finished in %.2fs  •  +%d Coins"):format(elapsed, coins), "victory")
		analytics(player, "custom", "Race Finished", 1)
		status(player, true)
	end,
	results = function(player, index, results)
		if player.Parent ~= Players then return end
		local standings = {}
		for _, result in ipairs(results) do
			table.insert(standings, {name = result.name, rank = result.rank, time = result.time})
		end
		message:FireClient(player, "results", index, standings)
	end,
})

local function refreshPass(player, ctx, info)
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, info.assetId)
	if ok and contexts[player] == ctx then
		ctx.owned[info.id] = if owns then true else nil
	end
	return ok and owns == true
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, assetId, bought)
	local ctx = contexts[player]
	local info = passes[assetId]
	if not ctx or not info then return end
	ctx.promptUntil = 0
	if not bought or (studio and not Config.StudioPurchasePrompts) then return end
	task.spawn(function()
		if refreshPass(player, ctx, info) then
			updateAppearance(player, ctx)
			notice(player, info.name .. " is now owned.", "upgrade")
			status(player, true)
			analytics(player, "custom", "Pass Granted", 1)
		else
			notice(player, "Roblox is confirming ownership. Rejoin to refresh your items.")
		end
	end)
end)

local consumables = {}
for _, info in ipairs(Catalog) do
	if info.kind == "Product" and info.assetId then consumables[info.assetId] = info end
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, assetId)
	local player = Players:GetPlayerByUserId(userId)
	local ctx = player and contexts[player]
	if ctx and consumables[assetId] then ctx.promptUntil = 0 end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	if studio and not Config.StudioPurchasePrompts then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local info = consumables[receipt.ProductId]
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local ctx = player and contexts[player]
	if not info or not ctx or type(receipt.PurchaseId) ~= "string" or #receipt.PurchaseId == 0
		or (not studio and not Profiles.isPersistent()) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local success, fresh = Profiles.receipt(player, receipt.PurchaseId, info.coins)
	if not success then
		analytics(player, "custom", "Receipt Deferred", 1)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if fresh then
		notice(player, ("Purchase delivered • +%d Coins"):format(info.coins), "upgrade")
		analytics(player, "custom", "Product Granted", 1)
	end
	status(player, true)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local map = World.build()
local spawn = World.configure()
World.ground()
pcall(function() PhysicsService:RegisterCollisionGroup(playerGroup) end)
PhysicsService:CollisionGroupSetCollidable(playerGroup, playerGroup, false)

for index, info in ipairs(Config.Worlds) do
	local district = map:FindFirstChild(info.name)
	local list = {}
	for _, model in ipairs(district.Pickups:GetChildren()) do
		table.insert(list, {id = model:GetAttribute("PickupId"), value = model:GetAttribute("Value"), position = model.PrimaryPart.Position})
	end
	pickups[index] = list
	local pads = {}
	for _, part in ipairs(district.Features:GetChildren()) do
		if part:GetAttribute("Feature") then table.insert(pads, part) end
	end
	features[index] = pads
	boards[index] = {localRows = {}, globalRows = {}}
	rallies[index] = {participants = {}, total = 0, count = 0}
end

local function setRally(player, index, join)
	local rally = rallies[index]
	local contribution = rally.participants[player]
	if join and contribution == nil then
		rally.participants[player] = 0
		rally.count += 1
	elseif not join and contribution ~= nil then
		rally.participants[player] = nil
		rally.count -= 1
		rally.total = math.max(0, rally.total - contribution)
	end
end

local function onCharacter(player, ctx, character)
	local humanoid = character:WaitForChild("Humanoid", 12)
	if not humanoid or contexts[player] ~= ctx then return end
	local function collision(instance)
		if instance:IsA("BasePart") then instance.CollisionGroup = playerGroup end
	end
	for _, instance in ipairs(character:GetDescendants()) do collision(instance) end
	character.DescendantAdded:Connect(collision)
	humanoid.Died:Connect(function()
		races:leave(player)
		ctx.previous = nil
	end)
	restoreSpeed(player)
	if character:WaitForChild("HumanoidRootPart", 10) and contexts[player] == ctx then
		relocate(player, ctx, ctx.world)
	end
end

local function onPlayer(player)
	if contexts[player] then return end
	local ctx = {ready = false}
	contexts[player] = ctx
	player.RespawnLocation = spawn
	local data = Profiles.load(player)
	if not data then
		contexts[player] = nil
		if player.Parent == Players then player:Kick("Your Dashverse save is unavailable. Please reconnect shortly.") end
		return
	end
	if player.Parent ~= Players then
		Profiles.close(player)
		contexts[player] = nil
		return
	end
	ctx.data = data
	ctx.ready = true
	ctx.world = 1
	ctx.cooldowns = {}
	ctx.owned = {}
	ctx.lastSend = 0
	ctx.travelAt = 0
	ctx.moveBudget = 14
	ctx.runFraction = 0
	ctx.energyDistance = 0
	ctx.actions = {}
	ctx.joinedAt = os.clock()
	for _, pool in ipairs(Config.QuestPools) do chooseQuest(ctx, pool) end
	if data.Tutorial == 0 then analytics(player, "onboarding", "Enter Green Valley", 1) end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, label in ipairs({"Speed", "Coins", "Wins"}) do
		local value = Instance.new("IntValue")
		value.Name = label
		value.Parent = leaderstats
	end
	ctx.leaderstats = leaderstats
	leaderstats.Parent = player
	player:SetAttribute("DV_World", 1)
	updateAppearance(player, ctx)
	player.CharacterAdded:Connect(function(character) onCharacter(player, ctx, character) end)
	if player.Character then task.spawn(onCharacter, player, ctx, player.Character) end
	status(player, true)
	task.spawn(function()
		for _, info in pairs(passes) do
			if contexts[player] ~= ctx then return end
			refreshPass(player, ctx, info)
		end
		if contexts[player] == ctx then updateAppearance(player, ctx) end
	end)
end

local function onLeave(player)
	local ctx = contexts[player]
	if not ctx then return end
	races:leave(player)
	if ctx.ready then
		setRally(player, ctx.world, false)
		analytics(player, "custom", "Session Seconds", math.max(1, math.floor(os.clock() - ctx.joinedAt)))
	end
	Profiles.close(player)
	if contexts[player] == ctx then contexts[player] = nil end
end

local function rateLimit(ctx, key, interval)
	local now = os.clock()
	if (ctx.actions[key] or 0) > now then return false end
	ctx.actions[key] = now + interval
	return true
end

local function tryUpgrade(player, ctx, kind)
	local level = ctx.data[kind]
	if level >= 12 then return notice(player, "This upgrade is at maximum level.") end
	local energy, coins = Config.cost(kind, level)
	if ctx.data.Energy < energy or ctx.data.Coins < coins then
		return notice(player, ("You need %d Energy and %d Coins."):format(energy, coins))
	end
	ctx.data.Energy -= energy
	ctx.data.Coins -= coins
	ctx.data[kind] += 1
	if kind == "Speed" then
		restoreSpeed(player)
		milestone(player, ctx, 2, "Buy first speed upgrade")
	end
	notice(player, ("%s upgraded to level %d."):format(kind, level + 1), "upgrade")
end

local function tryTravel(player, ctx, index)
	if not canTravel(ctx.data, index) then return notice(player, "Complete this world's entry goals first.") end
	if index > ctx.data.Unlocked then
		ctx.data.Unlocked = index
		discoverCreatures(player, ctx)
		analytics(player, "custom", "World Unlocked", index)
	end
	if ctx.world ~= index then
		setRally(player, ctx.world, false)
		ctx.duel = nil
	end
	relocate(player, ctx, index)
	notice(player, "Arrived in " .. Config.Worlds[index].name .. ".", "upgrade")
end

local function tryClaim(player, ctx, id)
	for _, pool in ipairs(Config.QuestPools) do
		if pool.id == id then
			local entry, taskInfo = chooseQuest(ctx, pool)
			if entry.claimed or ctx.data.Stats[taskInfo.metric] - entry.base < taskInfo.target then return end
			entry.claimed = true
			notice(player, ("Quest complete • +%d Coins"):format(addCoins(ctx, taskInfo.coins)), "upgrade")
			return
		end
	end
	for _, info in ipairs(Config.Achievements) do
		if info.id ~= id or ctx.data.Claims[id] then continue end
		local _, ready = achievementProgress(ctx.data, info)
		if ready then
			ctx.data.Claims[id] = true
			notice(player, ("%s • +%d Coins"):format(info.title, addCoins(ctx, info.reward)), "upgrade")
		end
		return
	end
end

local function tryDash(player, ctx)
	if ctx.data.Speed < 2 then return notice(player, "Dash unlocks at Speed level 2.") end
	if (ctx.dashReady or 0) > workspace:GetServerTimeNow() then return end
	local root, humanoid = bodyFor(player)
	if not root or not humanoid or humanoid.Health <= 0 then return end
	ctx.dashReady = workspace:GetServerTimeNow() + 7
	ctx.dashUntil = os.clock() + 0.65
	local move = root.CFrame.LookVector
	local flat = V(move.X, 0, move.Z)
	if flat.Magnitude > 0.1 then
		local launch = flat.Unit * math.min(Config.MaxSpeed + 7, Config.speed(ctx.data.Speed) + 25)
		root.AssemblyLinearVelocity = V(launch.X, math.max(root.AssemblyLinearVelocity.Y, 3), launch.Z)
	end
	notice(player, "Dash!", "dash")
end

local function tryPurchase(player, ctx, key)
	local info = products[key]
	if not info or not info.assetId or ctx.owned[key] then return end
	if not Config.PurchasesEnabled then
		return notice(player, "The premium catalog is currently in preview.")
	end
	if studio and not Config.StudioPurchasePrompts then
		return notice(player, "Purchases are disabled in this Studio playtest.")
	end
	if os.clock() < (ctx.promptUntil or 0) then return end
	ctx.promptUntil = os.clock() + 25
	task.spawn(function()
		if info.kind == "Pass" and refreshPass(player, ctx, info) then
			ctx.promptUntil = 0
			updateAppearance(player, ctx)
			status(player, true)
			return notice(player, "You already own " .. info.name .. ".")
		end
		local ok = pcall(function()
			if player.Parent ~= Players then return end
			if info.kind == "Pass" then
				MarketplaceService:PromptGamePassPurchase(player, info.assetId)
			elseif Profiles.isPersistent() or studio then
				MarketplaceService:PromptProductPurchase(player, info.assetId)
			else
				error("Persistent profile required for consumables")
			end
		end)
		if ok then
			analytics(player, "custom", "Shop Prompt Opened", 1)
		else
			ctx.promptUntil = 0
			notice(player, "The Roblox purchase window could not open. Try again later.")
			analytics(player, "custom", "Shop Prompt Failed", 1)
		end
	end)
end

local function challenge(player, ctx, userId)
	local friend = Players:GetPlayerByUserId(userId)
	local other = friend and contexts[friend]
	if not other or friend == player or other.world ~= ctx.world or not other.ready or races.entries[friend] then
		return notice(player, "That runner is unavailable.")
	end
	local ok, isFriend = pcall(function() return player:IsFriendsWithAsync(userId) end)
	if not ok or not isFriend then return notice(player, "Friend duels are available for Roblox friends.") end
	if contexts[friend] ~= other or other.world ~= ctx.world or races.entries[friend] or races.entries[player] then return end
	other.duel = {player = player, expires = workspace:GetServerTimeNow() + 30}
	notice(friend, player.DisplayName .. " invited you to a duel. Open Races to accept.")
	notice(player, "Duel invitation sent.")
	status(friend, true)
end

local function acceptDuel(player, ctx)
	local invite = ctx.duel
	ctx.duel = nil
	if not invite or workspace:GetServerTimeNow() >= invite.expires then return notice(player, "That invitation expired.") end
	local partner = contexts[invite.player]
	if not partner or partner.world ~= ctx.world or not Profiles.get(invite.player) then
		return notice(player, "The other runner left this world.")
	end
	local ok, reason = races:join({invite.player, player}, ctx.world, "Friend duel")
	if not ok then return notice(player, reason) end
	status(invite.player, true)
end

command.OnServerEvent:Connect(function(player, action, value, extra)
	local ctx = contexts[player]
	if not ctx or not ctx.ready or not Profiles.get(player) or type(action) ~= "string" or #action > 20 then return end
	if not rateLimit(ctx, "command", 0.12) then return end
	local racing = races.entries[player] ~= nil
	if action == "sync" then
		status(player, true)
		return
	elseif action == "setting" and type(value) == "string" and Config.Settings[value] ~= nil then
		if type(extra) == "boolean" and type(Config.Settings[value]) == "boolean" then ctx.data.Settings[value] = extra end
		if value == "Volume" and type(extra) == "number" and extra == extra then ctx.data.Settings.Volume = math.clamp(extra, 0, 1) end
	elseif action == "quit" and racing then
		races:leave(player, "You left the race.")
	elseif racing then
		return notice(player, "This action is available after the race.")
	elseif action == "upgrade" and (value == "Speed" or value == "Training") then
		tryUpgrade(player, ctx, value)
	elseif action == "travel" and type(value) == "number" and value >= 1 and value <= #Config.Worlds and value % 1 == 0 and rateLimit(ctx, "travel", 1.15) then
		tryTravel(player, ctx, value)
	elseif action == "equip" and type(value) == "string" and (value == "" or (creatures[value] and ctx.data.Creatures[value] == true)) then
		ctx.data.Equipped = value
		updateAppearance(player, ctx)
	elseif action == "cosmetic" and type(value) == "string" and #value < 40 and ownedItem(ctx, value) then
		local slot = cosmeticSlot(value)
		ctx.data.Cosmetics[slot] = if ctx.data.Cosmetics[slot] == value then nil else value
		updateAppearance(player, ctx)
	elseif action == "claim" and type(value) == "string" then
		tryClaim(player, ctx, value)
	elseif action == "race" then
		local ok, reason = races:join({player}, ctx.world, "Open race")
		if not ok then notice(player, reason) end
	elseif action == "challenge" and type(value) == "number" and value % 1 == 0 and rateLimit(ctx, "duel", 5) then
		challenge(player, ctx, value)
	elseif action == "accept" then
		acceptDuel(player, ctx)
	elseif action == "rally" then
		setRally(player, ctx.world, rallies[ctx.world].participants[player] == nil)
	elseif action == "buy" and type(value) == "string" and #value < 32 then
		tryPurchase(player, ctx, value)
	elseif action == "prestige" and ctx.data.Unlocked == #Config.Worlds and ctx.data.Speed >= 10 and ctx.data.Prestige < 100 then
		ctx.data.Speed = 0
		ctx.data.Training = 0
		ctx.data.Energy = 0
		ctx.data.EnergyFraction = 0
		ctx.data.Prestige += 1
		restoreSpeed(player)
		notice(player, ("Prestige %d earned."):format(ctx.data.Prestige), "victory")
	elseif action == "dash" then
		tryDash(player, ctx)
	elseif action == "home" and rateLimit(ctx, "travel", 1.15) then
		relocate(player, ctx, ctx.world)
	end
	status(player, true)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local ctx = contexts[player]
	local root = bodyFor(player)
	local anchor = prompt.Parent
	if not ctx or not ctx.ready or not root or not anchor or not anchor:IsA("BasePart") or not prompt:IsDescendantOf(map) or
		not Profiles.get(player) or prompt:GetAttribute("World") ~= ctx.world or
		(root.Position - anchor.Position).Magnitude > prompt.MaxActivationDistance + 4 or races.entries[player] then return end
	local action = prompt:GetAttribute("Action")
	local value = prompt:GetAttribute("Value")
	if action == "Open" then
		message:FireClient(player, "page", value)
	elseif action == "Shop" then
		message:FireClient(player, "page", "Shop", value)
	elseif action == "Secret" and ctx.safePosition and (root.Position - ctx.safePosition).Magnitude < 10
		and not ctx.data.Secrets[tostring(value)] then
		ctx.data.Secrets[tostring(value)] = true
		local coins = addCoins(ctx, 55 + value * 30)
		addEnergy(ctx, 30 + value * 15)
		discoverCreatures(player, ctx)
		notice(player, ("%s discovered • +%d Coins"):format(Config.Worlds[value].secretName, coins), "victory")
		status(player, true)
	end
end)

local function distanceToMove(point, from, to)
	local delta = to - from
	if delta:Dot(delta) < 0.01 then return (point - to).Magnitude end
	local t = math.clamp((point - from):Dot(delta) / delta:Dot(delta), 0, 1)
	return (point - from - delta * t).Magnitude
end

local function sample(player, ctx, now, dt)
	local root, humanoid = bodyFor(player)
	if not root or not humanoid or humanoid.Health <= 0 then return end
	local point = root.Position
	local world = Config.Worlds[ctx.world]
	local localPoint = point - world.offset
	if localPoint.Y < -48 or math.abs(localPoint.X) > 226 or localPoint.Z < -289 or localPoint.Z > 128 then
		races:leave(player, "You left the race course.")
		relocate(player, ctx, ctx.world)
		return
	end
	for _, pool in ipairs(Config.QuestPools) do chooseQuest(ctx, pool) end
	if races.entries[player] then
		ctx.previous = nil
		return
	end
	local previous = ctx.previous or ctx.safePosition or point
	ctx.previous = point
	local delta = point - previous
	local walked = V(delta.X, 0, delta.Z).Magnitude
	local maxSpeed = Config.speed(ctx.data.Speed)
	if (ctx.dashUntil or 0) > now then maxSpeed = math.min(Config.MaxSpeed + 7, maxSpeed + 25) end
	if (ctx.featureUntil or 0) > now then maxSpeed = math.min(Config.MaxSpeed, maxSpeed + 12) end
	if walked > math.max(68, maxSpeed * dt * 1.5 + 25) and ctx.safePosition then
		root.AssemblyLinearVelocity = V(0, 0, 0)
		player.Character:PivotTo(CFrame.new(ctx.safePosition) * root.CFrame.Rotation)
		ctx.previous = ctx.safePosition
		return
	end
	ctx.moveBudget = math.max(-24, math.min(34, ctx.moveBudget + maxSpeed * 1.18 * dt) - walked)
	if ctx.moveBudget < -1 or math.abs(delta.Y) > 24 + dt * 90 then return end
	ctx.safePosition = point
	if walked > 0.4 and math.abs(delta.Y) < 12 and now - ctx.travelAt > 0.45 then
		ctx.runFraction += walked
		local whole = math.floor(ctx.runFraction)
		ctx.runFraction -= whole
		ctx.data.Stats.Run += whole
		ctx.energyDistance += walked
		local units = math.floor(ctx.energyDistance / 7)
		if units > 0 then
			ctx.energyDistance -= units * 7
			addEnergy(ctx, units * (1 + math.floor((ctx.data.Training + 1) / 2)), "Run")
		end
	end
	for _, pickup in ipairs(pickups[ctx.world]) do
		if (ctx.cooldowns[pickup.id] or 0) <= now and distanceToMove(pickup.position, previous, point) < 4.8 then
			collect(player, ctx, pickup, now)
		end
	end
	if (ctx.featureReady or 0) < now then
		for _, pad in ipairs(features[ctx.world]) do
			if (pad.Position - point).Magnitude < 4.1 then
				ctx.featureReady = now + 3
				if pad:GetAttribute("Feature") == "Boost" then
					ctx.featureUntil = now + 1.6
					humanoid.WalkSpeed = math.min(Config.MaxSpeed, maxSpeed + 12)
					task.delay(1.6, function()
						if contexts[player] == ctx and not races.entries[player] then restoreSpeed(player) end
					end)
				else
					local current = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = V(current.X, 39, current.Z)
				end
				notice(player, pad.Name .. "!", "dash")
				break
			end
		end
	end
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(onLeave)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

task.spawn(function()
	local previous = os.clock()
	while task.wait(0.20) do
		local now = os.clock()
		local dt = now - previous
		previous = now
		races:step(workspace:GetServerTimeNow())
		for player, ctx in pairs(contexts) do
			if ctx.ready and Profiles.get(player) then
				sample(player, ctx, now, dt)
				status(player, false)
			end
		end
	end
end)

if Profiles.isPersistent() then
	task.spawn(function()
		while task.wait(42) do
			for player, ctx in pairs(contexts) do
				if ctx.ready then task.spawn(Profiles.save, player) end
			end
		end
	end)
	task.spawn(function()
		while true do
			for index in ipairs(Config.Worlds) do refreshBoard(index) end
			task.wait(120)
		end
	end)
end

game:BindToClose(function()
	local remaining = 0
	for player in pairs(contexts) do
		remaining += 1
		task.spawn(function()
			onLeave(player)
			remaining -= 1
		end)
	end
	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do task.wait(0.12) end
end)
