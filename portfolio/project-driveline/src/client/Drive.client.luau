local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Driveline")
local Catalog = require(shared.Catalog)
local Dashboard = require(script.Parent.Dashboard)
local Camera = require(script.Parent.Camera)
local Input = require(script.Parent.Input)
local Garage = require(script.Parent.Garage)
local Travel = require(script.Parent.Travel)
local RoutesPanel = require(script.Parent.RoutesPanel)

local player = Players.LocalPlayer
local settings = {mph = false, reducedMotion = false, sensitivity = 1}
local view = Camera.create(settings)
local hud, garage, travel, routes
local function toggle()
    if garage then garage.close() end
    if travel then travel.close() end
    if routes then routes.close() end
    hud.toggle()
end
local function action(name) shared.CarAction:FireServer(name) end
local function cycle() view.cycle() end
hud = Dashboard.create(player, settings, {settings = toggle, action = action, camera = cycle, changed = function() hud.sync() end})
garage = Garage.create(hud, shared, Catalog, function()
    if hud.modal.Visible then hud.toggle() end
    if travel then travel.close() end
    if routes then routes.close() end
end)
travel = Travel.create(hud, shared, function()
    if hud.modal.Visible then hud.toggle() end
    garage.close()
    if routes then routes.close() end
end, function(destination)
    if destination == "Dealer" then garage.openDealer() end
end)
routes = RoutesPanel.create(hud, shared, function()
    if hud.modal.Visible then hud.toggle() end
    travel.close()
    garage.close()
end)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, actor)
    if actor == player and prompt:GetAttribute("DrivelineDealer") then garage.openDealer() end
end)
game:GetService("UserInputService").InputBegan:Connect(function(input, captured)
    if captured then return end
    if input.KeyCode == Enum.KeyCode.F2 then travel.toggle(); return end
    local menu = ({[Enum.KeyCode.B] = "Garage", [Enum.KeyCode.M] = "Dealer", [Enum.KeyCode.U] = "Workshop"})[input.KeyCode]
    if menu then garage.toggle(menu) end
end)
local controls = Input.attach(shared, cycle, toggle)
local current, mode
local speed, send, refresh = 0, 0, 0
local seatConnection

local function characterAdded(character)
    if seatConnection then seatConnection:Disconnect() end
    local human = character:WaitForChild("Humanoid")
    local function seatChanged()
        local seat = human.SeatPart
        current = seat and seat.Parent:GetAttribute("DrivelineCar") and seat.Parent or nil
        mode = current and seat.Name or false
        speed = 0
        view.set(mode == "Driver" and current or nil, character)
        controls.set(mode)
        hud.mode(current, mode)
    end
    seatConnection = human:GetPropertyChangedSignal("SeatPart"):Connect(seatChanged)
    seatChanged()
end

player.CharacterAdded:Connect(characterAdded)
if player.Character then characterAdded(player.Character) end

RunService.RenderStepped:Connect(function(dt)
    send += dt
    refresh += dt
    if refresh >= 1 / 30 then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local x, z = root.Position.X, root.Position.Z
            local district = "Foundry Avenue"
            if x > 5465 and z > 2460 then district = "Tokyo"
            elseif x < -5690 and z < -2010 then district = "Manhattan"
            elseif z > 2480 and x < 1220 then district = "Downtown Dubai"
            elseif z < -2010 and x > -730 then district = "Paris Promenade"
            elseif z > 2480 or z < -2010 then district = "International Expressway"
            elseif x > 380 then district = "Red Basin"
            elseif x < -380 then district = "Pine Divide"
            elseif math.abs(z) > 375 then district = "International Expressway"
            elseif x < -23 and z > 23 then district = "Motor Court"
            elseif x > 23 and z > 23 then district = "Calder Square"
            elseif x > 23 and z < -23 then district = "Foundry Center"
            elseif x < -23 and z < -23 then district = "Mercantile Row" end
            hud.location(district)
        end
    end
    if send >= 1 / 25 then
        send = 0
        controls.send()
    end
    local update = refresh >= 1 / 30
    if update then refresh = 0 end
    if current and current.PrimaryPart and mode == "Driver" then
        local root = current.PrimaryPart
        local velocity = root.AssemblyLinearVelocity
        local kmh = Vector3.new(velocity.X, 0, velocity.Z).Magnitude * Catalog.kmhPerStudSecond
        speed += (kmh - speed) * (1 - math.exp(-10 * dt))
        if update then
            local config = Catalog.vehicles[current:GetAttribute("VehicleId")]
            hud.update(current, settings.mph and speed * 0.621371 or speed, config.redline,
                current:GetAttribute("Gear") or 0, current:GetAttribute("RPM") or 0)
        end
    end
end)
