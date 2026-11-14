local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Dashverse.Config)

local Profiles = {}
local active = {}
local memory = {}
local persistent = not RunService:IsStudio() or Config.StudioPersistentData
local store = persistent and DataStoreService:GetDataStore(Config.DataStore)
local leaseSeconds = 150

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end

local function number(value, default, minimum, maximum)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return default
	end
	return math.clamp(math.floor(value), minimum, maximum)
end

local function dictionary(value)
	return if type(value) == "table" then value else {}
end

local function migrate(raw)
	raw = dictionary(raw)
	local stats = dictionary(raw.Stats)
	local settings = table.clone(Config.Settings)
	for key, default in pairs(settings) do
		local candidate = dictionary(raw.Settings)[key]
		if type(candidate) == type(default) then
			if type(candidate) == "boolean" then
				settings[key] = candidate
			elseif candidate == candidate then
				settings[key] = math.clamp(candidate, 0, 1)
			end
		end
	end
	return {
		Schema = 1,
		Energy = number(raw.Energy, 0, 0, Config.MaxNumber),
		EnergyFraction = if type(raw.EnergyFraction) == "number" and raw.EnergyFraction >= 0 and raw.EnergyFraction < 1 then raw.EnergyFraction else 0,
		Coins = number(raw.Coins, 12, 0, Config.MaxNumber),
		Speed = number(raw.Speed, 0, 0, 12),
		Training = number(raw.Training, 0, 0, 12),
		Unlocked = number(raw.Unlocked, 1, 1, #Config.Worlds),
		Prestige = number(raw.Prestige, 0, 0, 100),
		Tutorial = number(raw.Tutorial, 0, 0, 3),
		Stats = {
			Run = number(stats.Run, 0, 0, Config.MaxNumber),
			Pickups = number(stats.Pickups, 0, 0, Config.MaxNumber),
			Finishes = number(stats.Finishes, 0, 0, Config.MaxNumber),
			Wins = number(stats.Wins, 0, 0, Config.MaxNumber),
		},
		Creatures = dictionary(raw.Creatures),
		Secrets = dictionary(raw.Secrets),
		Claims = dictionary(raw.Claims),
		Quests = dictionary(raw.Quests),
		Best = dictionary(raw.Best),
		Receipts = dictionary(raw.Receipts),
		Cosmetics = dictionary(raw.Cosmetics),
		Equipped = if type(raw.Equipped) == "string" then raw.Equipped else "",
		Settings = settings,
	}
end

local function update(key, transform)
	if persistent then
		return store:UpdateAsync(key, transform)
	end
	local result = transform(copy(memory[key]))
	if result then
		memory[key] = copy(result)
	end
	return result
end

function Profiles.load(player)
	local key = "player:" .. player.UserId
	local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
	for attempt = 1, 5 do
		local success, result = pcall(update, key, function(current)
			current = dictionary(current)
			if type(current.profile) == "table" and type(current.profile.Schema) == "number" and current.profile.Schema > 1 then
				return nil
			end
			if current.owner and current.owner ~= token and (current.lease or 0) > os.time() then
				return nil
			end
			return {profile = migrate(current.profile), owner = token, lease = os.time() + leaseSeconds}
		end)
		if success and result and result.owner == token then
			local entry = {key = key, token = token, data = migrate(result.profile), deadline = result.lease}
			active[player] = entry
			return entry.data
		end
		if not success then
			warn(("[Dashverse] Profile load attempt %d failed: %s"):format(attempt, tostring(result)))
		end
		if attempt < 5 and player.Parent then
			task.wait(attempt * 1.4)
		else
			break
		end
	end
	return nil
end

function Profiles.get(player)
	local entry = active[player]
	if entry and not entry.closing and not entry.invalid and (not persistent or entry.deadline > os.time()) then
		return entry.data
	end
	return nil
end

local function reconcileReceipts(target, receipts)
	for receipt, amount in pairs(dictionary(receipts)) do
		if target.Receipts[receipt] == nil and type(amount) == "number" and amount > 0 then
			target.Receipts[receipt] = amount
			target.Coins = math.min(Config.MaxNumber, target.Coins + amount)
		end
	end
end

local function saveEntry(player, entry, release, receiptId, credit)
	local deadline = os.clock() + 9
	while entry.saving and os.clock() < deadline do
		task.wait(0.08)
	end
	if entry.saving or entry.invalid or active[player] ~= entry or (entry.closing and not release and not receiptId) then
		return false
	end
	if receiptId and entry.data.Receipts[receiptId] then
		return true, false
	end

	entry.saving = true
	local snapshot = copy(entry.data)
	local saved = false
	local fresh = false
	for attempt = 1, 3 do
		local success, result = pcall(update, entry.key, function(current)
			if type(current) ~= "table" or current.owner ~= entry.token then
				return nil
			end
			local data = copy(snapshot)
			reconcileReceipts(data, dictionary(current.profile).Receipts)
			if receiptId then
				fresh = data.Receipts[receiptId] == nil
				reconcileReceipts(data, {[receiptId] = credit})
			end
			return {profile = data, owner = if release then nil else entry.token, lease = if release then 0 else os.time() + leaseSeconds}
		end)
		if success and result then
			reconcileReceipts(entry.data, result.profile.Receipts)
			entry.deadline = result.lease
			saved = true
			break
		elseif success then
			entry.invalid = true
			if not release and player.Parent then
				player:Kick("Your save was opened on another server. Please reconnect.")
			end
			break
		else
			warn(("[Dashverse] Profile save attempt %d failed: %s"):format(attempt, tostring(result)))
			if attempt < 3 then task.wait(attempt) end
		end
	end
	entry.saving = false
	return saved, saved and fresh
end

function Profiles.save(player)
	local entry = active[player]
	if entry then
		return saveEntry(player, entry, false)
	end
	return false
end

function Profiles.receipt(player, receiptId, credit)
	local entry = active[player]
	if not Profiles.get(player) or not entry or entry.closing then
		return false
	end
	return saveEntry(player, entry, false, receiptId, credit)
end

function Profiles.isPersistent()
	return persistent
end

function Profiles.close(player)
	local entry = active[player]
	if not entry then return end
	if entry.closing then
		local deadline = os.clock() + 15
		while active[player] == entry and os.clock() < deadline do task.wait(0.1) end
		return
	end
	entry.closing = true
	saveEntry(player, entry, true)
	active[player] = nil
end

return Profiles
