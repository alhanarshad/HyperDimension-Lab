local Suspension = {}

local TRAVEL = 1.38
local REST = 0.88
local IDLE = 850

local function smooth(value, target, rate, dt)
    return value + (target - value) * (1 - math.exp(-rate * dt))
end

function Suspension.new(model, config)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {model}
    params.RespectCanCollide = true
    local wheels = {}
    for _, part in model.Wheels:GetChildren() do
        local mount = part:GetAttribute("Mount")
        local front = mount.Z < 0
        table.insert(wheels, {
            mount = mount, front = front, joint = part.Suspension, rotation = 0,
            driven = config.drivetrain == "AWD" or (front == (config.drivetrain == "FWD")),
            extension = REST,
        })
    end
    return {
        model = model, root = model.PrimaryPart, config = config, params = params, wheels = wheels,
        gear = 0, rpm = 0, throttle = 0, steer = 0, shiftTime = 0, slip = 0,
    }
end

function Suspension.step(car, dt, forward, backward, turn, parking, engine, dtClock)
    local config, root = car.config, car.root
    local cf = root.CFrame
    local up, facing, right = cf.UpVector, cf.LookVector, cf.RightVector
    local velocity = root.AssemblyLinearVelocity
    local spin, center = root.AssemblyAngularVelocity, root.AssemblyCenterOfMass
    local mass = root.AssemblyMass
    local directionSpeed = velocity:Dot(facing)
    local speed = math.abs(directionSpeed)
    local weight = mass * workspace.Gravity
    local wheelRadius = config.radius
    local bike = config.shape == "Bike"

    local gear, thrust, brake = car.gear, 0, 0
    local travel, rest = config.travel or TRAVEL, config.ride or REST
    if forward > 0.02 and backward > 0.02 then
        brake = backward
    elseif forward > 0.02 then
        if directionSpeed < -1.4 then brake = forward else gear, thrust = math.max(gear, 1), forward end
    elseif backward > 0.02 then
        if directionSpeed > 1.4 or bike then brake = backward else gear, thrust = -1, backward end
    end
    if not engine then
        gear, thrust = 0, 0
    end

    local ratios = config.ratios
    local wheelRpm = speed / (2 * math.pi * wheelRadius) * 60
    local finalDrive = (config.finalDrive or 4.12) * (car.lowRange and 2.56 or 1)
    car.shiftTime = math.max(0, car.shiftTime - dtClock)
    if gear > 0 and car.shiftTime == 0 then
        local gearRpm = wheelRpm * finalDrive * ratios[gear]
        if gear < #ratios and gearRpm > config.shift then
            gear += 1
            car.shiftTime = 0.18
        elseif gear > 1 and gearRpm < 2250 and wheelRpm * finalDrive * ratios[gear - 1] < config.shift * 0.88 then
            gear -= 1
            car.shiftTime = 0.13
        end
    end
    local ratio = gear == -1 and 3.12 or (ratios[gear] or 0)
    local coupledRpm = wheelRpm * finalDrive * ratio
    local rpm = engine and math.clamp(math.max(coupledRpm, IDLE + thrust * 1150), IDLE, config.redline) or 0
    car.rpm = smooth(car.rpm, rpm, 10, dt)
    car.gear = gear
    car.throttle = smooth(car.throttle, thrust, thrust > car.throttle and config.throttle or 15, dt)
    car.steer = smooth(car.steer, turn, 7, dt)
    local steering = math.rad(config.steer) * car.steer / (1 + (speed / 52)^1.5)
    if bike then
        local flat = Vector3.new(facing.X, 0, facing.Z)
        if flat.Magnitude > 0.1 then
            local heading = CFrame.lookAt(Vector3.zero, flat.Unit)
            local bank = math.clamp(car.steer * speed / 74, -0.54, 0.54)
            local turnRate = math.clamp(speed / 28, 0, 1.1) * car.steer
            root.BikeBalance.CFrame = heading * CFrame.Angles(0, -turnRate * dt * 3.5, -bank)
        end
    end
    local curve = config.torque
    local curvePosition = (math.clamp(car.rpm / config.redline, 0, 1)) * (#curve - 1)
    local curveIndex = math.min(math.floor(curvePosition) + 1, #curve - 1)
    local torque = curve[curveIndex] + (curve[curveIndex + 1] - curve[curveIndex]) * (curvePosition - curveIndex + 1)
    local speedLimit = car.towing and 34 or (car.lowRange and config.topSpeed * 0.35 or config.topSpeed)
    local limiter = math.clamp((1 - speed / (gear < 0 and 22 or speedLimit)) * 8, 0, 1)
    local drive = 0
    if car.lowRange and engine and thrust <= 0.02 and speed > 10 then
        brake = math.max(brake, math.clamp((speed - 10) / 15, 0, 0.7))
    end
    if engine and gear ~= 0 and brake == 0 and car.shiftTime == 0 then
        drive = config.acceleration * mass * car.throttle * torque * (ratio / ratios[1])^0.74 * limiter
        if car.lowRange then drive *= 1.52 end
        if gear < 0 then drive *= -0.65 end
    end

    local largestSlip = 0
    for _, wheel in car.wheels do
        local origin = cf:PointToWorldSpace(wheel.mount)
        local hit = workspace:Raycast(origin, -up * (travel + wheelRadius), car.params)
        local extension = travel
        local angle = wheel.front and steering or 0
        if hit and hit.Normal:Dot(up) > 0.39 then
            local pointVelocity = velocity + spin:Cross(origin - center)
            extension = math.clamp(hit.Distance - wheelRadius, 0.20, travel)
            local share = weight * (wheel.front and config.frontBias or 1 - config.frontBias) / (bike and 1 or 2)
            local springRate = share / config.spring
            local zonalMass = share / workspace.Gravity
            local damping = config.damping * 2 * math.sqrt(springRate * zonalMass)
            local compression = (rest + config.spring - extension)
            local springForce = math.clamp(springRate * compression - pointVelocity:Dot(up) * damping, 0, share * 2.9)
            local aim = facing * math.cos(angle) + right * math.sin(angle)
            local longitudinal = (aim - hit.Normal * aim:Dot(hit.Normal)).Unit
            local lateral = longitudinal:Cross(hit.Normal).Unit
            local contactVelocity = velocity + spin:Cross(hit.Position - center)
            local rolling, sliding = contactVelocity:Dot(longitudinal), contactVelocity:Dot(lateral)
            local surfaceGrip = 1
            if hit.Material == Enum.Material.Sand then
                surfaceGrip = config.offroad and 0.77 or 0.47
            elseif hit.Material == Enum.Material.Ground or hit.Material == Enum.Material.Grass then
                surfaceGrip = config.offroad and 0.84 or 0.58
            elseif hit.Material == Enum.Material.Mud then
                surfaceGrip = config.offroad and 0.68 or 0.36
            elseif hit.Material == Enum.Material.Snow then
                surfaceGrip = config.offroad and 0.66 or 0.44
            end
            local rearLock = parking and not wheel.front
            local traction = config.grip * springForce * surfaceGrip
            local lateralForce = -sliding * zonalMass * (rearLock and 2.3 or 7.0)
            local opposing = config.brake * zonalMass * brake
            if not car.beingTowed and (rearLock or not engine) then opposing = math.max(opposing, 56 * zonalMass) end
            local rollingLoss = (1.10 + (1 - surfaceGrip) * 4) * zonalMass + 0.00115 * rolling^2 * zonalMass
            local stopping = math.min((opposing + rollingLoss), math.abs(rolling) * zonalMass * 13)
            local torqueAtWheel = wheel.driven and drive / (bike and 1 or (config.drivetrain == "AWD" and 4 or 2)) or 0
            local forwardForce = torqueAtWheel - math.sign(rolling) * stopping
            local slideCapacity = math.max(traction * (rearLock and 0.43 or 1), 1)
            local demand = math.sqrt((forwardForce / math.max(traction, 1))^2 + (lateralForce / slideCapacity)^2)
            local scale = 1 / math.max(demand, 1)
            root:ApplyImpulseAtPosition(hit.Normal * springForce * dt, origin)
            root:ApplyImpulseAtPosition((longitudinal * forwardForce + lateral * lateralForce) * scale * dt, hit.Position)
            largestSlip = math.max(largestSlip, math.deg(math.atan2(math.abs(sliding), math.abs(rolling) + 1)))
            if not rearLock then
                wheel.rotation = (wheel.rotation - rolling * dt / wheelRadius) % (2 * math.pi)
            end
        end
        wheel.extension = smooth(wheel.extension, extension, 17, dt)
        wheel.pose = CFrame.new(wheel.mount - Vector3.yAxis * wheel.extension)
            * CFrame.Angles(0, -angle, 0) * CFrame.Angles(wheel.rotation, 0, 0)
    end
    car.slip = largestSlip
    car.braking = brake > 0.05
end

return Suspension
