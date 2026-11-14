local Config = require(game:GetService("ReplicatedStorage").Dashverse.Config)
local Races = {}
Races.__index = Races

local V = Vector3.new

local function position(player)
	local character = player.Character
	local body = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return body, humanoid
end

local function xz(point)
	return V(point.X, 0, point.Z)
end

local function distanceFromSegment(point, a, b)
	local flat = xz(b - a)
	local progress = math.clamp(xz(point - a):Dot(flat) / flat:Dot(flat), 0, 1)
	local nearest = a:Lerp(b, progress)
	return xz(point - nearest).Magnitude, math.abs(point.Y - nearest.Y)
end

function Races.new(callbacks)
	return setmetatable({rounds = {}, public = {}, entries = {}, callbacks = callbacks}, Races)
end

function Races:describe(player)
	local state = self.entries[player]
	if not state then return nil end
	local round = state.round
	return {
		world = round.world, mode = round.mode, phase = round.phase, count = round.count,
		gate = state.gate - 1, gates = #Config.Worlds[round.world].route,
		starts = round.starts, elapsed = if round.phase == "Running" then workspace:GetServerTimeNow() - round.starts else 0,
	}
end

function Races:release(player)
	local body = position(player)
	if body then body.Anchored = false end
	self.callbacks.restore(player)
end

function Races:leave(player, reason)
	local state = self.entries[player]
	if not state then return end
	self.entries[player] = nil
	local round = state.round
	round.entries[player] = nil
	round.remaining -= 1
	self:release(player)
	if reason then self.callbacks.notice(player, reason, "race") end
	self.callbacks.push(player)
end

function Races:close(round)
	for player in pairs(round.entries) do
		self:leave(player)
	end
	self.rounds[round] = nil
	if self.public[round.world] == round then self.public[round.world] = nil end
	for _, result in ipairs(round.results) do
		self.callbacks.results(result.player, round.world, round.results)
	end
end

function Races:join(players, worldIndex, mode)
	local round = if mode == "Open race" then self.public[worldIndex] else nil
	local now = workspace:GetServerTimeNow()
	if round and (round.phase ~= "Countdown" or round.starts - now < 0.8) then
		return false, "A race is running. Try again after the finish."
	end
	if round and round.count + #players > 12 then
		return false, "This heat is full."
	end
	for _, player in ipairs(players) do
		local body, humanoid = position(player)
		if self.entries[player] or not body or not humanoid or humanoid.Health <= 0 then
			return false, "A runner is already racing or is respawning."
		end
	end
	if not round then
		round = {
			world = worldIndex, mode = mode, phase = "Countdown", starts = now + Config.Countdown,
			entries = {}, results = {}, count = 0, remaining = 0,
		}
		self.rounds[round] = true
		if mode == "Open race" then self.public[worldIndex] = round end
	end

	local world = Config.Worlds[worldIndex]
	local route = world.route
	local first = world.offset + route[1]
	local forward = xz(route[2] - route[1]).Unit
	local side = forward:Cross(V(0, 1, 0))
	for _, player in ipairs(players) do
		local body, humanoid = position(player)
		local slot = round.count
		local spawn = first + V(0, 3.2, 0) + side * ((slot % 5 - 2) * 2.6) - forward * (3.5 + math.floor(slot / 5) * 3.1)
		body.AssemblyLinearVelocity = V(0, 0, 0)
		body.Anchored = true
		player.Character:PivotTo(CFrame.lookAt(spawn, spawn + forward))
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		local state = {round = round, gate = 1, last = body.Position, sampled = now, budget = 14, outside = 0}
		self.entries[player] = state
		round.entries[player] = state
		round.count += 1
		round.remaining += 1
		self.callbacks.enter(player, worldIndex)
	end
	return true
end

function Races:finish(player, state, now)
	local round = state.round
	local world = Config.Worlds[round.world]
	local expected = 0
	for i, a in ipairs(world.route) do
		expected += xz(world.route[i % #world.route + 1] - a).Magnitude
	end
	local elapsed = now - round.starts
	if elapsed < expected * 0.77 / Config.RaceSpeed then
		self:leave(player, "Course speed could not be verified.")
		return
	end
	local rank = #round.results + 1
	local contenders = #round.results
	for _, entrant in pairs(round.entries) do
		if entrant.gate >= 4 then contenders += 1 end
	end
	local official = contenders >= 2
	table.insert(round.results, {player = player, name = player.DisplayName, time = math.floor(elapsed * 1000 + 0.5), rank = rank})
	self:leave(player)
	self.callbacks.finish(player, round.world, elapsed, rank, official)
end

function Races:step(now)
	for round in pairs(self.rounds) do
		if round.remaining == 0 then
			self:close(round)
			continue
		end
		if round.phase == "Countdown" and now >= round.starts then
			round.phase = "Running"
			for player, state in pairs(round.entries) do
				local body, humanoid = position(player)
				if body and humanoid then
					state.last = body.Position
					state.sampled = now
					body.Anchored = false
					humanoid.WalkSpeed = Config.RaceSpeed
					humanoid.JumpPower = 43
					humanoid.JumpHeight = 6
					self.callbacks.notice(player, "Go! Follow the lit gates.", "countdown")
				end
			end
		end
		if round.phase ~= "Running" then continue end
		if now - round.starts > Config.RaceTimeout then
			for player in pairs(round.entries) do
				self:leave(player, "Time expired. Queue again for another run.")
			end
			continue
		end
		local world = Config.Worlds[round.world]
		local route = world.route
		for player, state in pairs(round.entries) do
			local body, humanoid = position(player)
			if not body or not humanoid or humanoid.Health <= 0 then
				self:leave(player, "Race ended when your runner respawned.")
				continue
			end
			local point = body.Position
			local dt = math.max(0.05, now - state.sampled)
			local change = xz(point - state.last).Magnitude
			state.budget = math.min(42, state.budget + dt * (Config.RaceSpeed * 1.20)) - change
			state.last = point
			state.sampled = now
			if state.budget < -2 then
				self:leave(player, "Race movement could not be verified.")
				continue
			end
			local relative = point - world.offset
			local a = route[state.gate]
			local b = route[state.gate % #route + 1]
			local width, height = distanceFromSegment(relative, a, b)
			if width > 15.5 or height > 11 then
				state.outside += dt
				if state.outside >= 1.5 then
					self:leave(player, "You left the course. Follow the lit gates on the next run.")
				end
				continue
			end
			state.outside = math.max(0, state.outside - dt * 2)
			if xz(relative - b).Magnitude < 9.2 and math.abs(relative.Y - b.Y) < 9.3 then
				if state.gate == #route then
					self:finish(player, state, now)
				else
					state.gate += 1
				end
			end
		end
	end
end

return Races
