local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local catalog = require(game.ReplicatedStorage.Driveline.Catalog)
local tuning = require(game.ReplicatedStorage.Driveline.Tuning)

local Data = {}
local studio = RunService:IsStudio()
local store = not studio and game:GetService("DataStoreService"):GetDataStore("DrivelineProfiles") or nil
local session = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local leaseSeconds = 210
local profiles = {}
local closing = false
Data.studio = studio

local function clean(raw)
    raw = type(raw) == "table" and raw or {}
    local cash = raw.cash
    if type(cash) ~= "number" or cash ~= cash or cash < 0 or cash == math.huge then cash = 36000 end
    local profile = {version = 1, cash = math.min(100000000, math.floor(cash)), owned = {Aster = true}, favorites = {}, builds = {}}
    for _, id in catalog.order do
        if type(raw.owned) == "table" and raw.owned[id] == true then profile.owned[id] = true end
        if profile.owned[id] and type(raw.favorites) == "table" and raw.favorites[id] == true then
            profile.favorites[id] = true
        end
        if profile.owned[id] and type(raw.builds) == "table" and type(raw.builds[id]) == "table" then
            profile.builds[id] = tuning.clean(raw.builds[id])
        end
    end
    return profile
end

local function update(key, transform, attempts)
    for attempt = 1, attempts do
        local ok, result = pcall(function() return store:UpdateAsync(key, transform) end)
        if ok then return result end
        if attempt < attempts then task.wait(0.8 * 2^(attempt - 1) + math.random() * 0.22) end
    end
    return nil
end

local function save(record, release)
    if studio then return true end
    local snapshot = clean(record.data)
    local key = record.key
    local saved = update(key, function(old)
        if type(old) ~= "table" or type(old.lock) ~= "table" or old.lock.id ~= session then return nil end
        local value = {profile = snapshot}
        if not release then value.lock = {id = session, expires = os.time() + leaseSeconds} end
        return value
    end, 3)
    return saved ~= nil
end

function Data.load(player)
    if studio then
        local record = {data = clean(), busy = false, request = 0}
        profiles[player] = record
        return record
    end
    local key = "User_" .. player.UserId
    local loaded = update(key, function(old)
        if old ~= nil and type(old) ~= "table" then return nil end
        if old and type(old.profile) == "table" and (tonumber(old.profile.version) or 0) > 1 then return nil end
        if old and type(old.lock) == "table" and old.lock.id ~= session
            and (tonumber(old.lock.expires) or 0) > os.time() then return nil end
        return {profile = clean(old and old.profile), lock = {id = session, expires = os.time() + leaseSeconds}}
    end, 4)
    if not loaded then return nil end
    local record = {data = loaded.profile, busy = false, key = key, request = 0, renewed = os.time()}
    if closing or player.Parent ~= Players then
        save(record, true)
        return nil
    end
    profiles[player] = record
    return record
end

function Data.get(player)
    local record = profiles[player]
    if record and not record.leaving and (studio or os.time() < record.renewed + leaseSeconds - 12) then return record end
    return nil
end

function Data.commit(record)
    if save(record, false) then record.renewed = os.time(); return true end
    return false
end

local function leave(player)
    local record = profiles[player]
    if not record or record.leaving then return end
    record.leaving = true
    while record.busy do task.wait() end
    if not save(record, true) then warn("Driveline could not close a profile session") end
    profiles[player] = nil
end

Players.PlayerRemoving:Connect(leave)
game:BindToClose(function()
    closing = true
    for player in profiles do task.spawn(leave, player) end
    local deadline = os.clock() + 24
    while next(profiles) and os.clock() < deadline do task.wait(0.1) end
end)

if not studio then
    task.spawn(function()
        while not closing do
            task.wait(14)
            for player, record in profiles do
                if not record.busy and not record.leaving and os.time() - record.renewed > 65 + player.UserId % 18 then
                    record.busy = true
                    task.spawn(function()
                        local ok = Data.commit(record)
                        record.busy = false
                        if not ok and os.time() > record.renewed + leaseSeconds - 25 and player.Parent == Players then
                            player:Kick("Your Driveline save connection was lost. Please rejoin.")
                        end
                    end)
                end
            end
        end
    end)
end

return Data
