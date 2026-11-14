local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Driveline")
local Catalog = require(shared.Catalog)
local Builder = require(shared.CarBuilder)
local AudioProfiles = require(shared.AudioProfiles)
local Suspension = require(script.Parent.Suspension)

local VehicleService = {}
local active = {}
local recovery = {}
local areas = workspace:WaitForChild("Driveline")
local fleet = Instance.new("Folder")
fleet.Name = "PlayerVehicles"
fleet.Parent = areas

local function getLaunch(player, region)
    local origin = areas:WaitForChild("Launch")
    if region and region ~= "City" then
        local zones = areas:FindFirstChild("Trailheads")
        origin = zones and zones:FindFirstChild(region)
        if not origin then return nil end
    end
    for index = 0, 11 do
        local position = origin.CFrame * CFrame.new(index % 4 * 10.4, 0, math.floor(index / 4) * 17)
        local available = true
        for other, car in active do
            if other ~= player and (car.root.Position - position.Position).Magnitude < 9.5 then
                available = false
                break
            end
        end
        if available then return position end
    end
    return nil
end

local function unhook(car)
    local target = car.towing
    if not target then return end
    car.rope:Destroy()
    car.hitch:Destroy()
    target.hitch:Destroy()
    target.beingTowed, target.hitch = nil, nil
    car.towing, car.rope, car.hitch = nil, nil, nil
    car.model:SetAttribute("Towing", false)
    target.model:SetAttribute("BeingTowed", false)
end

local function clearTow(car)
    if car.beingTowed then unhook(car.beingTowed) end
    unhook(car)
end

local function leave(seat, car)
    local humanoid = seat.Occupant
    if not humanoid then return end
    local character = humanoid.Parent
    local exterior = car.root.CFrame * CFrame.new(seat == car.model.Driver and -4.7 or 4.7, 2.7, 0)
    humanoid.Sit = false
    local weld = seat:FindFirstChild("SeatWeld")
    if weld then weld:Destroy() end
    if character and character.Parent then character:PivotTo(exterior) end
end

function VehicleService.remove(player)
    local car = active[player]
    if not car then return end
    clearTow(car)
    active[player] = nil
    leave(car.model.Passenger, car)
    leave(car.model.Driver, car)
    car.model:Destroy()
end

function VehicleService.spawn(player, id, config, region)
    local launch = getLaunch(player, region)
    if not launch then return false, "All launch bays are occupied." end
    VehicleService.remove(player)
    local model = Builder.build(id, config, launch, false)
    model:SetAttribute("Owner", player.UserId)
    model:SetAttribute("Engine", false)
    model:SetAttribute("Gear", 0)
    model:SetAttribute("RPM", 0)
    model:SetAttribute("Locked", false)
    model:SetAttribute("LowRange", false)
    model.Parent = fleet
    local car = Suspension.new(model, config)
    car.audio = AudioProfiles.attach(model, config)
    car.launch, car.head, car.signal, car.engine, car.locked = launch, 0, "Off", false, false
    car.region = region or "City"
    car.lastInput, car.inputs, car.limit = 0, {0, 0, 0, false}, {}
    car.root:SetNetworkOwner(nil)
    active[player] = car

    for _, seat in {model.Driver, model.Passenger} do
        local driver = seat == model.Driver
        if not driver and config.shape == "Bike" then continue end
        seat.Board.Triggered:Connect(function(entrant)
            local character = entrant.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local human = character and character:FindFirstChildOfClass("Humanoid")
            if not root or not human or human.Health <= 0 or human.SeatPart or seat.Occupant or car.beingTowed
                or (root.Position - seat.Position).Magnitude > 11 or car.root.AssemblyLinearVelocity.Magnitude > 6 then
                return
            end
            if driver and entrant ~= player or car.locked and entrant ~= player then return end
            seat:Sit(human)
        end)
        seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            local occupant = seat.Occupant
            seat.Board.Enabled = occupant == nil and (driver or not car.locked)
            car.root:SetNetworkOwner(nil)
            if occupant and (driver and occupant.Parent ~= player.Character
                or car.locked and occupant.Parent ~= player.Character) then
                task.defer(leave, seat, car)
                return
            end
            local ignore = {model}
            for _, otherSeat in {model.Driver, model.Passenger} do
                if otherSeat.Occupant then table.insert(ignore, otherSeat.Occupant.Parent) end
            end
            car.params.FilterDescendantsInstances = ignore
            if driver and not occupant then
                car.engine = false
                car.inputs = {0, 0, 0, false}
                car.lastInput = 0
                model:SetAttribute("Engine", false)
            end
        end)
    end
    return true
end

function VehicleService.get(player)
    return active[player]
end

local function reset(car, launch)
    clearTow(car)
    car.root.CFrame = launch
    car.root.AssemblyLinearVelocity = Vector3.zero
    car.root.AssemblyAngularVelocity = Vector3.zero
    car.gear, car.throttle, car.steer, car.shiftTime = 0, 0, 0, 0
    car.inputs = {0, 0, 0, false}
    car.lastInput = 0
end

function VehicleService.travel(player, region)
    local character = player.Character
    local human = character and character:FindFirstChildOfClass("Humanoid")
    if not human or human.Health <= 0 then return false, "Your character is unavailable." end
    local car = active[player]
    local seat = human.SeatPart
    if seat and (not car or seat ~= car.model.Driver) then return false, "Exit the passenger seat first." end
    if car and car.towing or car and car.beingTowed then return false, "Disconnect the recovery line first." end
    if car and car.root.AssemblyLinearVelocity.Magnitude > 8 then return false, "Stop your vehicle before traveling." end
    local launch = getLaunch(player, region)
    if not launch then return false, "That destination has no free arrival bays." end
    if car then
        car.launch, car.region = launch, region
        reset(car, launch)
    end
    if not seat then character:PivotTo(launch * CFrame.new(-5.5, 1.4, 0)) end
    player:SetAttribute("DrivelineDestination", region)
    return true
end

local function tow(car)
    if car.towing then unhook(car); return end
    if not car.config.tow or car.beingTowed or car.root.AssemblyLinearVelocity.Magnitude > 4 then return end
    local rear = Vector3.new(0, -0.16, car.config.length * 0.51)
    local hitchPosition = car.root.CFrame:PointToWorldSpace(rear)
    local target, nearest, front = nil, 20, nil
    local function consider(candidate)
        if candidate == car or candidate.beingTowed or candidate.towing or candidate.model.Driver.Occupant
            or candidate.model.Passenger.Occupant or candidate.root.AssemblyLinearVelocity.Magnitude > 4 then return end
        if not candidate.recovery and not candidate.model:GetAttribute("RecoveryAllowed") then return end
        local offset = Vector3.new(0, -0.15, -candidate.config.length * 0.51)
        local difference = candidate.root.CFrame:PointToWorldSpace(offset) - hitchPosition
        local distance = difference.Magnitude
        if distance > 3 and distance < nearest and difference:Dot(car.root.CFrame.LookVector) < -1 then
            target, nearest, front = candidate, distance, offset
        end
    end
    for _, candidate in recovery do consider(candidate) end
    for _, candidate in active do consider(candidate) end
    if not target then return end
    local hitch = Instance.new("Attachment", car.root)
    hitch.Name, hitch.Position = "RecoveryHitch", rear
    local nose = Instance.new("Attachment", target.root)
    nose.Name, nose.Position = "RecoveryEye", front
    local rope = Instance.new("RopeConstraint")
    rope.Name, rope.Attachment0, rope.Attachment1 = "RecoveryLine", hitch, nose
    rope.Length, rope.Restitution, rope.Thickness, rope.Visible = math.max(7, nearest + 0.6), 0, 0.11, true
    rope.Color = BrickColor.new("Bright orange")
    rope.Parent = car.root
    car.hitch, car.rope, car.towing = hitch, rope, target
    target.hitch, target.beingTowed = nose, car
    car.model:SetAttribute("Towing", true)
    target.model:SetAttribute("BeingTowed", true)
end

local function validAxis(value, min, max)
    return typeof(value) == "number" and value == value and value >= min and value <= max
end

shared.DriveInput.OnServerEvent:Connect(function(player, forward, backward, turn, parking)
    local car = active[player]
    local human = car and car.model.Driver.Occupant
    if not human or human.Parent ~= player.Character then return end
    local now = os.clock()
    if now - (car.limit.input or 0) < 1 / 35 then return end
    car.limit.input = now
    if validAxis(forward, 0, 1) and validAxis(backward, 0, 1) and validAxis(turn, -1, 1) and typeof(parking) == "boolean" then
        car.inputs[1], car.inputs[2], car.inputs[3], car.inputs[4] = forward, backward, turn, parking
        car.lastInput = now
    end
end)

shared.CarAction.OnServerEvent:Connect(function(player, action)
    if typeof(action) ~= "string" or #action > 16 then return end
    local character = player.Character
    local human = character and character:FindFirstChildOfClass("Humanoid")
    local seat = human and human.SeatPart
    if action == "Exit" and seat and seat.Parent:GetAttribute("DrivelineCar") then
        if seat.Parent.PrimaryPart.AssemblyLinearVelocity.Magnitude < 9 then
            leave(seat, {root = seat.Parent.PrimaryPart, model = seat.Parent})
        end
        return
    end
    local car = active[player]
    if not car then return end
    local now = os.clock()
    if now - (car.limit.action or 0) < 0.16 then return end
    car.limit.action = now
    local driving = seat == car.model.Driver and car.model.Driver.Occupant == human
    if action == "Lock" then
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - car.root.Position).Magnitude < 16 then
            car.locked = not car.locked
            car.model.Passenger.Board.Enabled = car.config.shape ~= "Bike" and not car.locked
                and car.model.Passenger.Occupant == nil
            car.model:SetAttribute("Locked", car.locked)
        end
    elseif action == "Reset" and now - (car.limit.reset or 0) > 5 then
        local launch = getLaunch(player, car.region)
        if launch then
            car.limit.reset = now
            car.launch = launch
            reset(car, launch)
            car.model:SetAttribute("LastReset", now)
        end
    elseif action == "Consent" then
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - car.root.Position).Magnitude < 16 then
            local enabled = not car.model:GetAttribute("RecoveryAllowed")
            car.model:SetAttribute("RecoveryAllowed", enabled)
            if not enabled and car.beingTowed then unhook(car.beingTowed) end
        end
    elseif driving then
        if action == "Engine" then
            car.engine = not car.engine
            car.model:SetAttribute("Engine", car.engine)
        elseif action == "Lights" then
            car.head = (car.head + 1) % 3
            car.model:SetAttribute("Headlights", car.head)
        elseif action == "Hazards" or action == "Left" or action == "Right" then
            car.signal = car.signal == action and "Off" or action
            car.model:SetAttribute("Signal", car.signal)
        elseif action == "Tow" then
            tow(car)
        elseif action == "Range" and car.config.offroad and car.config.drivetrain == "AWD"
            and car.root.AssemblyLinearVelocity.Magnitude < 4 then
            car.lowRange = not car.lowRange
            car.model:SetAttribute("LowRange", car.lowRange)
        elseif action == "Horn" and car.audio.horn and now - (car.limit.horn or -2) > 1.2 then
            car.limit.horn = now
            car.audio.horn:Play()
        end
    end
end)

local function activateRecovery()
    local spots = areas:FindFirstChild("RecoveryTargets")
    if not spots then return end
    for _, point in spots:GetChildren() do
        local id = point:GetAttribute("VehicleId")
        local config = Catalog.vehicles[id]
        if not config then continue end
        local model = Builder.build(id, config, point.CFrame, false)
        model.Name = "Recovery " .. config.name
        model.Driver.Board.Enabled, model.Passenger.Board.Enabled = false, false
        model.Parent = fleet
        local car = Suspension.new(model, config)
        car.model:SetAttribute("RecoveryTarget", true)
        car.root:SetNetworkOwner(nil)
        car.recovery, car.launch = true, point.CFrame
        table.insert(recovery, car)
    end
end
activateRecovery()

local telemetry = 0
RunService.PreSimulation:Connect(function(delta)
    if delta <= 0 then return end
    local dt, now = math.min(delta, 1 / 30), os.clock()
    telemetry += delta
    local publish = telemetry >= 1 / 18
    if publish then telemetry = 0 end
    for player, car in active do
        if car.root.Position.Y < -30 or car.root.Position.Magnitude > 16000 then
            local launch = getLaunch(player, car.region) or car.launch
            reset(car, launch)
            car.model:SetAttribute("LastReset", now)
        end
        local fresh = now - car.lastInput < 0.33
        local forward, backward, steer = 0, 0, 0
        local parking = car.model.Driver.Occupant == nil and not car.beingTowed
        if fresh and not parking then
            forward, backward, steer, parking = table.unpack(car.inputs)
        end
        Suspension.step(car, dt, forward, backward, steer, parking, car.engine, delta)
        if publish then
            AudioProfiles.update(car.audio, car)
            for _, wheel in car.wheels do wheel.joint.C0 = wheel.pose end
            local model = car.model
            model:SetAttribute("RPM", math.floor(car.rpm / 25 + 0.5) * 25)
            model:SetAttribute("Gear", car.gear)
            model:SetAttribute("Parking", parking)
            model:SetAttribute("Slip", math.round(car.slip))
            local flash = now % 0.80 < 0.40
            for _, light in model.Lights:GetChildren() do
                local circuit = light:GetAttribute("Circuit")
                local on = circuit == "Head" and car.head > 0
                    or circuit == "Tail" and (car.braking or car.head > 0)
                    or circuit == "Reverse" and car.gear == -1
                    or (circuit == "Left" or circuit == "Right") and flash
                        and (car.signal == circuit or car.signal == "Hazards")
                light.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
                local spot = light:FindFirstChildOfClass("SpotLight")
                if spot then
                    spot.Enabled = on
                    spot.Range = car.head == 2 and 100 or 62
                    spot.Brightness = car.head == 2 and 2.2 or 1.6
                end
            end
        end
    end
    for _, car in recovery do
        if car.root.Position.Y < -30 or car.root.Position.Magnitude > 16000 then reset(car, car.launch) end
        Suspension.step(car, dt, 0, 0, 0, not car.beingTowed, false, delta)
        if publish then
            for _, wheel in car.wheels do wheel.joint.C0 = wheel.pose end
        end
    end
end)

Players.PlayerRemoving:Connect(VehicleService.remove)

return VehicleService
