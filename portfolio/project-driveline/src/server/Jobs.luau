local Players = game:GetService("Players")
local shared = game.ReplicatedStorage.Driveline
local routes = require(shared.Routes)
local vehicles = require(script.Parent.VehicleService)
local data = require(script.Parent.PlayerData)
local runs, cooldown = {}, {}

local function set(player, job, index, expires)
    player:SetAttribute("DrivelineJobIndex", index)
    player:SetAttribute("DrivelineJobExpires", expires)
    player:SetAttribute("DrivelineJob", job)
end

local function stop(player, message)
    runs[player] = nil
    set(player, nil, nil, nil)
    player:SetAttribute("DrivelineJobResult", message)
end

function shared.JobRequest.OnServerInvoke(player, action, id)
    local now = workspace:GetServerTimeNow()
    if now - (cooldown[player] or -1) < 0.55 then return false, "Try again in a moment." end
    cooldown[player] = now
    if action == "Cancel" then
        if runs[player] and runs[player].finishing then return false, "Your route reward is being processed." end
        stop(player, "Route canceled.")
        return true
    end
    if action ~= "Start" or type(id) ~= "string" or not routes[id] then return false, "Unknown route." end
    if runs[player] then return false, "Cancel the current route first." end
    local record = data.get(player)
    if not record then return false, "Your profile is unavailable." end
    local car = vehicles.get(player)
    if not car or not car.model.Driver.Occupant or car.model.Driver.Occupant.Parent ~= player.Character then
        return false, "Take the driver seat to accept a route."
    end
    if car.model:GetAttribute("Trial") then return false, "Use an owned vehicle for an earning route." end
    local expires = now + routes[id].duration
    runs[player] = {id = id, car = car, index = 1, expires = expires,
        reset = car.model:GetAttribute("LastReset"), launch = car.launch}
    player:SetAttribute("DrivelineJobResult", "")
    set(player, id, 1, expires)
    return true
end

task.spawn(function()
    while true do
        task.wait(0.15)
        local now = workspace:GetServerTimeNow()
        for player, run in runs do
            if run.finishing then continue end
            local car, route = vehicles.get(player), routes[run.id]
            if now > run.expires then stop(player, "Route expired."); continue end
            if car ~= run.car or car.model:GetAttribute("LastReset") ~= run.reset or car.launch ~= run.launch then
                stop(player, "Route ended after the vehicle moved to an arrival bay.")
                continue
            end
            local rider = car.model.Driver.Occupant
            if not rider or rider.Parent ~= player.Character then continue end
            local point = route.points[run.index]
            if (car.root.Position - point).Magnitude > 22 then continue end
            if run.index < #route.points then
                run.index += 1
                set(player, run.id, run.index, run.expires)
                continue
            end
            local profile = data.get(player)
            if not profile or profile.busy then continue end
            profile.busy, run.finishing = true, true
            profile.data.cash = math.min(100000000, profile.data.cash + route.payout)
            task.spawn(function()
                local saved = data.commit(profile)
                profile.busy = false
                if player.Parent ~= Players then return end
                if not saved then player:Kick("The route reward could not be confirmed. Rejoin to check your balance."); return end
                player:SetAttribute("DrivelineBalance", profile.data.cash)
                stop(player, string.format("Route completed  +$%d", route.payout))
            end)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    runs[player], cooldown[player] = nil, nil
end)

return true
