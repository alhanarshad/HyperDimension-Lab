local Builder = {}

local dark = Color3.fromRGB(27, 33, 39)
local glass = Color3.fromRGB(51, 69, 80)
local trim = Color3.fromRGB(111, 122, 127)
local tire = Color3.fromRGB(31, 34, 36)
local white = Color3.fromRGB(221, 243, 255)
local red = Color3.fromRGB(192, 37, 47)
local amber = Color3.fromRGB(239, 174, 72)

function Builder.build(id, config, pivot, preview)
    local model = Instance.new("Model")
    model.Name = config.name
    model:SetAttribute("DrivelineCar", true)
    model:SetAttribute("VehicleId", id)
    local width, length, radius = config.width, config.length, config.radius
    local chassis = Instance.new("Part")
    chassis.Name = "Chassis"
    chassis.Size = Vector3.new(width - 0.7, 0.72, length - 0.8)
    chassis.CFrame = pivot
    chassis.Transparency = 1
    chassis.Anchored = preview == true
    chassis.RootPriority = 127
    chassis.CustomPhysicalProperties = PhysicalProperties.new(config.density, 0.23, 0.02, 1, 1)
    chassis.Parent = model
    model.PrimaryPart = chassis

    local geometry = Instance.new("Folder", model)
    geometry.Name = "Body"
    local wheels = Instance.new("Folder", model)
    wheels.Name = "Wheels"
    local lamps = Instance.new("Folder", model)
    lamps.Name = "Lights"

    local function piece(name, size, offset, color, material, parent, class, joint)
        local part = Instance.new(class or "Part")
        part.Name = name
        part.Size = size
        part.CFrame = pivot * offset
        part.Color = color
        part.Material = material or Enum.Material.SmoothPlastic
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
        part.Parent = parent or geometry
        if joint ~= false then
            local weld = Instance.new("WeldConstraint", part)
            weld.Part0, weld.Part1 = chassis, part
        end
        return part
    end

    local function body(name, x, y, z, sx, sy, sz, color, rotation)
        local part = piece(name, Vector3.new(sx, sy, sz),
            CFrame.new(x, y, z) * (rotation or CFrame.identity), color or config.color)
        if not color then
            part:SetAttribute("PrimaryPaint", true)
        end
        return part
    end

    if config.shape == "Bike" then
        local function tube(name, a, b, diameter, color)
            piece(name, Vector3.new(diameter, diameter, (b - a).Magnitude),
                CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Metal)
        end
        body("Cradle", 0, 0.23, 0.08, 0.62, 0.42, 2.3, dark)
        body("Engine", 0, 0.54, -0.11, 0.65, 0.69, 0.87, trim)
        body("Fuel tank", 0, 1.24, -0.69, 0.87, 0.35, 1.28)
        body("Seat saddle", 0, 1.27, 0.66, 0.61, 0.20, 1.71, dark)
        body("Front fender", 0, 0.86, -config.wheelbase / 2, 0.47, 0.16, 1.79, nil, CFrame.Angles(0.11, 0, 0))
        body("Rear fender", 0, 1.18, config.wheelbase / 2 - 0.16, 0.48, 0.12, 1.92)
        body("Headlamp", 0, 1.45, -1.96, 0.38, 0.27, 0.16, white)
        body("Tail lamp", 0, 1.13, config.wheelbase / 2 + 0.57, 0.28, 0.105, 0.13, red)
        body("Handlebar", 0, 1.92, -1.52, 1.62, 0.075, 0.075, trim)
        for _, side in {-1, 1} do
            tube("Fork stanchion", Vector3.new(side * 0.23, 1.76, -1.48),
                Vector3.new(side * 0.23, -0.63, -config.wheelbase / 2), 0.11, trim)
            tube("Swingarm", Vector3.new(side * 0.25, 0.32, 0.26),
                Vector3.new(side * 0.25, -0.59, config.wheelbase / 2), 0.12, trim)
            body("Grip", side * 0.70, 1.93, -1.52, 0.32, 0.14, 0.13, dark)
            body("Peg", side * 0.40, 0.30, 0.31, 0.29, 0.069, 0.13, dark)
        end
        body("Exhaust", 0.43, 0.82, 1.59, 0.19, 0.27, 1.60, trim,
            CFrame.Angles(-0.23, 0, 0))
    end

    local sport = config.shape == "Coupe" or config.shape == "RallyCoupe" or config.shape == "RallySedan"
    local pickup = config.shape == "Pickup" or config.shape == "UtilityPickup"
    local tall = config.shape == "SUV" or config.shape == "TrailSUV" or config.shape == "ShortSUV"
        or config.shape == "Crossover" or pickup
    local bike = config.shape == "Bike"
    if not bike then
    local roof = pickup and (config.body == "Dune" and 3.96 or 3.74) or (tall and 3.18 or (sport and 2.07 or 2.62))
    local cabinFront = sport and -0.52 or (pickup and -4.01 or -0.83)
    local cabinRear = pickup and 2.87 or length * (tall and 0.37 or 0.31)
    local hood = pickup and (config.body == "Mesa" and 2.25 or 2.12) or (tall and 1.55 or (sport and 0.83 or 1.16))
    body("Floor", 0, 0.06, 0, width - 0.18, 0.42, length - 0.35, dark)
    body("Beltline", 0, 0.84, 0, width - 0.12, 0.55, length - 0.36)
    body("Hood", 0, hood, -length * 0.32, width - 0.19, 0.32, length * 0.34)
    body("Bonnet inlay", 0, hood + 0.17, -length * 0.31, width * 0.66, 0.045, length * 0.30)
    if pickup then
        local bedLength = length * 0.5 - cabinRear
        local bed = cabinRear + bedLength / 2
        body("Textured bed liner", 0, 1.19, bed, width - 0.8, 0.25, bedLength, dark)
        body("Tailgate", 0, 1.67, length * 0.475, width - 0.4, 0.96, 0.30)
        for _, side in {-1, 1} do
            body("Bed rail", side * (width * 0.45), 1.60, bed, 0.64, 1.15, bedLength)
            body("Bed rail cap", side * (width * 0.45), 2.20, bed, 0.69, 0.09, bedLength, dark)
            body("Side step", side * (width * 0.5), 0.42, -0.55, 0.75, 0.18, 5.6, dark)
            body("Exhaust outlet", side * (width * 0.30), 0.21, length * 0.495, 0.57, 0.35, 0.35, trim)
        end
        for rail = -7, 7 do
            body("Bed floor rib", rail * 0.41, 1.34, bed, 0.09, 0.07, bedLength - 0.50, trim)
        end
        body("Bed bulkhead", 0, 1.75, cabinRear + 0.18, width * 0.78, 1.2, 0.22, dark)
        body("Tailgate applique", 0, 1.70, length * 0.497, width * 0.57, 0.47, 0.12, dark)
    else
        body("Rear deck", 0, hood, length * 0.34, width - 0.22, 0.42, length * 0.28)
    end
    body("Front bumper", 0, 0.37, -length * 0.49, width - 0.22, 0.58, 0.28)
    body("Rear bumper", 0, 0.44, length * 0.49, width - 0.22, 0.48, 0.28)
    body("Front intake", 0, 0.57, -length * 0.506, width * 0.50, 0.28, 0.085, dark)
    for stripe = -1, 1 do
        body("Grille slat", 0, 0.57 + stripe * 0.076, -length * 0.513, width * 0.43, 0.022, 0.04, trim)
    end
    body("Rear diffuser", 0, 0.28, length * 0.506, width * 0.72, 0.19, 0.07, dark)
    if pickup then
        local raptor = config.body == "Dune"
        body("Wide grille", 0, 1.51, -length * 0.500, width * (raptor and 0.65 or 0.72), 1.11, 0.18, dark)
        body("Front skid plate", 0, 0.37, -length * 0.485, width * 0.73, 0.48, 0.48, trim)
        body("Hood power dome", 0, hood + 0.24, -length * 0.32, width * 0.41, 0.21, length * 0.20, raptor and config.color or dark)
        body("Hood vent", 0, hood + 0.364, -length * (raptor and 0.39 or 0.45), width * 0.28, 0.055, raptor and 0.68 or 1.1, dark)
        for index = -3, 3 do
            body("Grille mesh rib", index * 0.67, 1.49, -length * 0.51, 0.06, 0.81, 0.057, trim)
        end
        for index = -1, 1 do
            body("Amber running marker", index * 0.64, 2.04, -length * 0.512, 0.29, 0.081, 0.05, amber)
        end
        for _, side in {-1, 1} do
            body("Recovery eye", side * width * 0.26, 0.41, -length * 0.509, 0.47, 0.27, 0.21, red)
            body("Bumper wing", side * width * 0.39, 0.77, -length * 0.492, width * 0.19, 0.45, 0.38, dark)
            body("Vertical DRL trim", side * width * 0.46, 1.69, -length * 0.511, 0.17, raptor and 0.77 or 0.50, 0.05, white)
        end
    end
    body("Roof", 0, roof, (cabinFront + cabinRear) / 2, width * 0.75, 0.15, cabinRear - cabinFront)
    body("Windshield", 0, (roof + hood) / 2, cabinFront - 0.54, width * 0.78, 0.13,
        math.sqrt((roof - hood)^2 + 1.15^2), glass, CFrame.Angles(-math.atan2(roof - hood, 1.15), 0, 0))
    if pickup then
        body("Rear cab glass", 0, (roof + 1.91) / 2, cabinRear + 0.052, width * 0.72, roof - 1.91, 0.14, glass)
    else
        body("Rear glass", 0, (roof + hood) / 2, cabinRear + 0.52, width * 0.76, 0.13,
            math.sqrt((roof - hood)^2 + 1.06^2), glass, CFrame.Angles(math.atan2(roof - hood, 1.06), 0, 0))
    end
    for _, side in {-1, 1} do
        local edge = side * width * 0.372
        body("Side windows", edge, (roof + 1.09) / 2, (cabinFront + cabinRear) / 2,
            0.09, roof - 1.12, cabinRear - cabinFront, glass)
        for _, z in {cabinFront, (cabinFront + cabinRear) / 2, cabinRear} do
            body("Pillar", edge * 1.01, (roof + 1.06) / 2, z, 0.14, roof - 1.01, 0.16, dark)
        end
        body("Door skin", side * width * 0.493, 0.83, 0.12, 0.13, 0.52, length * 0.34)
        body("Door handle", side * width * 0.507, 1.02, 1.15, 0.07, 0.075, 0.35, trim)
        body("Rocker", side * width * 0.48, 0.20, 0.15, 0.23, 0.21, length * 0.44, dark)
        body("Mirror mount", side * width * 0.46, hood + 0.26, -1.38, 0.65, 0.12, 0.22, dark)
        body("Mirror housing", side * width * 0.54, hood + 0.30, -1.38, 0.36, 0.25, 0.38)
        for _, axle in {-1, 1} do
            local z = axle * config.wheelbase * 0.5
            body("Fender shoulder", side * width * 0.454, radius * 0.76, z, 0.52, 0.25, 2.23)
            if pickup then
                for i = -3, 3 do
                    local angle = i * 0.38
                    body("Wheel arch cladding", side * width * 0.494, 0.08 + math.cos(angle) * (radius + 0.29),
                        z + math.sin(angle) * (radius + 0.29), 0.37, 0.25, 0.83, dark,
                        CFrame.Angles(-angle, 0, 0))
                end
            end
        end
    end

    local function light(kind, side, z, x, y, sx, sy, color, beam)
        local part = piece(kind .. side, Vector3.new(sx, sy, 0.09),
            CFrame.new(side * x, y, z), color, Enum.Material.SmoothPlastic, lamps)
        part:SetAttribute("Circuit", kind)
        if beam and not preview then
            local spot = Instance.new("SpotLight", part)
            spot.Face = Enum.NormalId.Front
            spot.Color, spot.Angle, spot.Range, spot.Brightness = white, 59, 62, 1.6
            spot.Enabled = false
        end
    end
    for _, side in {-1, 1} do
        light("Head", side, -length * 0.505, width * 0.34, hood - 0.16, 1.14, 0.21, white, true)
        light("Tail", side, length * 0.508, width * (pickup and 0.415 or 0.35), pickup and 1.66 or 0.90,
            pickup and 0.41 or 0.93, pickup and 0.87 or 0.23, red)
        light("Reverse", side, length * 0.51, width * 0.21, 0.88, 0.44, 0.13, white)
        light(side < 0 and "Left" or "Right", side, length * 0.51, width * 0.454, 0.90, 0.32, 0.19, amber)
        light(side < 0 and "Left" or "Right", side, -length * 0.508, width * 0.454, hood - 0.17, 0.27, 0.17, amber)
    end
    body("Plate recess", 0, 0.76, length * 0.514, 1.12, 0.34, 0.095, Color3.fromRGB(224, 231, 230))

    local plate = geometry["Plate recess"]
    local plateFace = Instance.new("SurfaceGui", plate)
    plateFace.Face = Enum.NormalId.Back
    plateFace.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    plateFace.PixelsPerStud = 85
    local plateText = Instance.new("TextLabel", plateFace)
    plateText.Size = UDim2.fromScale(1, 1)
    plateText.BackgroundTransparency = 1
    plateText.TextColor3, plateText.TextScaled, plateText.Font = dark, true, Enum.Font.GothamBold
    plateText.Text = "DL " .. string.upper(string.sub(id, 1, 3))
    end

    for _, axle in {-1, 1} do
        for _, side in bike and {0} or {-1, 1} do
            local name = (axle < 0 and "Front" or "Rear") .. (side < 0 and "Left" or (side == 0 and "Center" or "Right"))
            local mount = Vector3.new(side * width * 0.443, 0.12, axle * config.wheelbase / 2)
            local offset = CFrame.new(mount - Vector3.yAxis * 0.70)
            local wheel = piece(name, Vector3.new(config.tireWidth, radius * 2, radius * 2),
                offset, tire, Enum.Material.SmoothPlastic, wheels, "Part", false)
            wheel.Shape = Enum.PartType.Cylinder
            wheel:SetAttribute("Mount", mount)
            local joint = Instance.new("Motor6D", wheel)
            joint.Name, joint.Part0, joint.Part1, joint.C0 = "Suspension", chassis, wheel, offset
            local outerSide = side == 0 and 1 or side
            local outside = outerSide * (config.tireWidth / 2 + 0.018)
            local function rimPiece(label, size, rimOffset, color, cylindrical)
                local part = piece(label, size, offset * rimOffset, color, Enum.Material.Metal, wheel, "Part", false)
                if cylindrical then
                    part.Shape = Enum.PartType.Cylinder
                end
                local weld = Instance.new("WeldConstraint", part)
                weld.Part0, weld.Part1 = wheel, part
                return part
            end
            rimPiece("Alloy", Vector3.new(0.05, radius * 1.51, radius * 1.51),
                CFrame.new(outside, 0, 0), dark, true)
            for spoke = 1, 5 do
                local angle = spoke * math.pi * 2 / 5
                local blade = rimPiece("Spoke", Vector3.new(0.07, radius * 0.62, radius * 0.11),
                    CFrame.new(outside + outerSide * 0.04, 0, 0) * CFrame.Angles(angle, 0, 0)
                        * CFrame.new(0, radius * 0.38, 0), config.wheelColor or trim, false)
                blade:SetAttribute("WheelPaint", true)
            end
            rimPiece("Center cap", Vector3.new(0.085, radius * 0.30, radius * 0.30),
                CFrame.new(outside + outerSide * 0.08, 0, 0), trim, true)
            if pickup or bike then
                for lug = 0, 15 do
                    local angle = lug * math.pi / 8
                    rimPiece("All-terrain tread", Vector3.new(config.tireWidth + 0.036, radius * 0.073, radius * 0.14),
                        CFrame.Angles(angle, 0, 0) * CFrame.new(0, radius, 0), tire, false)
                end
            end
        end
    end

    if not preview then
        for index, side in {-1, 1} do
            local seat = piece(index == 1 and "Driver" or "Passenger", Vector3.new(1.45, 0.38, 1.56),
                CFrame.new(bike and 0 or side, bike and 1.10 or 0.73, bike and 0.56 or 0.24),
                dark, nil, model, "Seat")
            seat.Transparency = 1
            local prompt = Instance.new("ProximityPrompt", seat)
            prompt.Name = "Board"
            prompt.ActionText = index == 1 and "Drive" or "Ride"
            prompt.ObjectText = config.name
            prompt.KeyboardKeyCode = index == 1 and Enum.KeyCode.E or Enum.KeyCode.G
            prompt.GamepadKeyCode = index == 1 and Enum.KeyCode.ButtonX or Enum.KeyCode.ButtonY
            prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 9, false
            prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
            if bike and index == 2 then prompt.Enabled = false end
        end
        if bike then
            local attachment = Instance.new("Attachment", chassis)
            local balance = Instance.new("AlignOrientation", chassis)
            balance.Name, balance.Mode, balance.Attachment0 = "BikeBalance", Enum.OrientationAlignmentMode.OneAttachment, attachment
            balance.RigidityEnabled, balance.Responsiveness = false, 21
            balance.MaxTorque, balance.MaxAngularVelocity = 60000, 12
            balance.CFrame = pivot.Rotation
        end
    end
    return model
end

return Builder
