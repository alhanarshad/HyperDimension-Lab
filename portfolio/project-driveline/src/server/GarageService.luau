local Players = game:GetService("Players")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Driveline")
local catalog = require(shared.Catalog)
local tuning = require(shared.Tuning)
local vehicles = require(script.Parent.VehicleService)
local Data = require(script.Parent.PlayerData)

local Garage = {}
local studioDemos = {}

local function view(player, profile)
    local own = {}
    for _, id in catalog.order do
        if profile.owned[id] then table.insert(own, id) end
    end
    local current = vehicles.get(player)
    return {owned = own, favorites = table.clone(profile.favorites),
        active = current and current.model:GetAttribute("VehicleId") or nil, cash = profile.cash, studioFleet = Data.studio,
        builds = profile.builds}
end

local function join(player)
    local record = Data.load(player)
    if not record then
        if player.Parent == Players then player:Kick("Your Driveline profile is unavailable. Please rejoin in a moment.") end
        return
    end
    if Data.studio then studioDemos[player] = true end
    player:SetAttribute("DrivelineBalance", record.data.cash)
    vehicles.spawn(player, "Aster", tuning.config(catalog.vehicles.Aster, record.data.builds.Aster))
end

local function charge(player, record, amount, change)
    record.busy = true
    record.data.cash -= amount
    change()
    local saved = Data.commit(record)
    record.busy = false
    if saved then
        player:SetAttribute("DrivelineBalance", record.data.cash)
    elseif player.Parent == Players then
        player:Kick("The purchase could not be confirmed. Rejoin to check your garage.")
    end
    return saved
end

function Garage.start()
    Players.PlayerAdded:Connect(join)
    Players.PlayerRemoving:Connect(function(player) studioDemos[player] = nil end)
    for _, player in Players:GetPlayers() do task.spawn(join, player) end
    shared.GarageRequest.OnServerInvoke = function(player, action, id, category, choice)
        local record = Data.get(player)
        if not record then return false, "Garage is loading." end
        if record.busy then return false, "Your profile is saving." end
        local profile = record.data
        local now = os.clock()
        if now - record.request < 0.32 then return false, "Try again in a moment." end
        record.request = now
        if action == "View" then return true, view(player, profile) end
        local car = vehicles.get(player)
        if action == "Store" then
            if not car then return false, "No car is deployed." end
            if car.root.AssemblyLinearVelocity.Magnitude > 7 then return false, "Stop the car before storing it." end
            vehicles.remove(player)
            return true, view(player, profile)
        end
        if typeof(id) ~= "string" or #id > 24 or not catalog.vehicles[id] then return false, "Unknown vehicle." end
        local config = catalog.vehicles[id]
        if action == "Buy" then
            if profile.owned[id] then return false, "You already own this car." end
            if profile.cash < config.price then return false, "Insufficient funds." end
            if not charge(player, record, config.price, function() profile.owned[id] = true end) then
                return false, "Purchase confirmation unavailable."
            end
            return true, view(player, profile)
        end
        if not profile.owned[id] and action ~= "Demo" then
            return false, "This car is unavailable in your garage."
        end
        if action == "Tune" then
            local option = type(category) == "string" and tuning.byKey[category]
            if not option or type(choice) ~= "number" or choice ~= choice or choice % 1 ~= 0 then
                return false, "Invalid workshop option."
            end
            local spec = option.choices[choice]
            local build = tuning.clean(profile.builds[id])
            if not spec or (build[category] or 1) == choice then return false, "Select a different option." end
            if profile.cash < spec.price then return false, "Insufficient funds." end
            if not charge(player, record, spec.price, function()
                build[category] = choice > 1 and choice or nil
                profile.builds[id] = build
            end) then return false, "Modification confirmation unavailable." end
            return true, view(player, profile)
        end
        if action == "Favorite" then
            profile.favorites[id] = not profile.favorites[id] or nil
            return true, view(player, profile)
        end
        if action == "Deploy" or action == "Demo" then
            if car and car.root.AssemblyLinearVelocity.Magnitude > 7 then return false, "Stop the current car first." end
            local success, issue = vehicles.spawn(player, id, tuning.config(config, profile.builds[id]),
                player:GetAttribute("DrivelineDestination"))
            if not success then return false, issue end
            if action == "Demo" and not studioDemos[player] and not profile.owned[id] then
                local demo = vehicles.get(player)
                demo.model:SetAttribute("Trial", true)
                task.delay(150, function()
                    if vehicles.get(player) == demo and player.Parent == Players then
                        local replaced = vehicles.spawn(player, "Aster", tuning.config(catalog.vehicles.Aster, profile.builds.Aster),
                            player:GetAttribute("DrivelineDestination"))
                        if not replaced then vehicles.remove(player) end
                    end
                end)
            end
            return true, view(player, profile)
        end
        return false, "Invalid garage request."
    end
end
return Garage
