local Catalog = {}

Catalog.vehicles = {
    Aster = {
        name = "Aster 160", class = "Commuter", drivetrain = "FWD", price = 0,
        color = Color3.fromRGB(41, 137, 139), shape = "Hatchback",
        width = 6.15, length = 12.5, wheelbase = 7.35, radius = 1.02, tireWidth = 0.72,
        density = 3.4, spring = 0.49, damping = 0.40, frontBias = 0.52,
        acceleration = 30, brake = 57, grip = 0.94, steer = 32, topSpeed = 119,
        ratios = {3.54, 2.12, 1.46, 1.06, 0.83}, redline = 6500, shift = 5790,
        torque = {0.40, 0.68, 0.92, 1.00, 0.92, 0.70}, throttle = 5.4,
    },
    Meridian = {
        name = "Meridian S6", class = "Sports coupe", drivetrain = "RWD", price = 34200,
        color = Color3.fromRGB(188, 81, 64), shape = "Coupe",
        width = 6.45, length = 12.8, wheelbase = 7.5, radius = 1.08, tireWidth = 0.91,
        density = 3.1, spring = 0.43, damping = 0.36, frontBias = 0.49,
        acceleration = 48, brake = 73, grip = 1.10, steer = 34, topSpeed = 169,
        ratios = {3.45, 2.20, 1.51, 1.13, 0.91, 0.75}, redline = 7900, shift = 7100,
        torque = {0.34, 0.61, 0.83, 0.98, 1.0, 0.88}, throttle = 7.4, finalDrive = 3.79,
    },
    Ridgeway = {
        name = "Ridgeway 4X", class = "Utility SUV", drivetrain = "AWD", price = 28100,
        color = Color3.fromRGB(184, 165, 115), shape = "SUV",
        width = 7.0, length = 14.4, wheelbase = 8.25, radius = 1.22, tireWidth = 0.90,
        density = 4.5, spring = 0.60, damping = 0.45, frontBias = 0.53,
        acceleration = 25, brake = 48, grip = 0.87, steer = 29, topSpeed = 104,
        ratios = {3.90, 2.27, 1.56, 1.13, 0.84}, redline = 5900, shift = 5350,
        torque = {0.55, 0.87, 1.0, 0.92, 0.79, 0.62}, throttle = 3.9, finalDrive = 4.06,
    },
    DuneRunner = {
        name = "2026 Dune Runner R", shortName = "Dune Runner R", class = "Desert pickup", drivetrain = "AWD", price = 71800,
        color = Color3.fromRGB(102, 119, 122), shape = "Pickup", body = "Dune",
        width = 7.86, length = 19.38, wheelbase = 12.15, radius = 1.54, tireWidth = 1.04,
        density = 3.30, spring = 0.56, damping = 0.47, frontBias = 0.52, travel = 1.72, ride = 1.03,
        acceleration = 63, brake = 52, grip = 1.03, steer = 33, topSpeed = 182,
        ratios = {4.69, 2.99, 2.15, 1.77, 1.52, 1.28, 1.0, 0.85, 0.69, 0.64},
        redline = 6900, shift = 6580, finalDrive = 4.10, torque = {0.58, 0.75, 0.94, 1, 0.96, 0.85},
        throttle = 5.4, offroad = true, tow = true, horsepower = 720, torqueLbFt = 640,
    },
    MesaXR = {
        name = "2027 Mesa 1500 XR", shortName = "Mesa 1500 XR", class = "Desert pickup", drivetrain = "AWD", price = 74200,
        color = Color3.fromRGB(84, 94, 64), shape = "Pickup", body = "Mesa",
        width = 7.98, length = 19.46, wheelbase = 12.08, radius = 1.46, tireWidth = 1.04,
        density = 3.66, spring = 0.57, damping = 0.46, frontBias = 0.53, travel = 1.69, ride = 1.00,
        acceleration = 67, brake = 55, grip = 1.04, steer = 31, topSpeed = 188,
        ratios = {4.71, 3.14, 2.11, 1.67, 1.29, 1.0, 0.84, 0.67},
        redline = 6400, shift = 6100, finalDrive = 3.55, torque = {0.61, 0.79, 0.96, 1, 0.97, 0.89},
        throttle = 5.05, offroad = true, tow = true, horsepower = 777, torqueLbFt = 680,
    },
}

Catalog.order = {"Aster", "Meridian", "Ridgeway", "DuneRunner", "MesaXR"}
Catalog.kmhPerStudSecond = 1.008

local bikeBase = {
    class = "Trail motorcycle", drivetrain = "RWD", shape = "Bike", offroad = true,
    width = 2.05, length = 6.92, wheelbase = 4.85, radius = 1.08, tireWidth = 0.38,
    density = 2.70, spring = 0.79, damping = 0.30, frontBias = 0.50, travel = 1.44, ride = 0.71,
    acceleration = 38, brake = 48, grip = 0.91, steer = 31, topSpeed = 124, throttle = 5.5,
    ratios = {2.46, 1.78, 1.41, 1.19, 1, 0.88}, redline = 9650, shift = 8710, finalDrive = 5.22,
    torque = {0.33, 0.56, 0.80, 0.96, 1, 0.87},
}
for _, source in {
    {"TrailBike", "Pine 450", 16800, "C5633C", 40, 126},
    {"RallyBike", "Basin 450", 14600, "B73539", 37, 117},
    {"AdventureBike", "Divide 700", 19800, "42619B", 45, 142},
} do
    local id, name, price, color, acceleration, speed = table.unpack(source)
    local config = table.clone(bikeBase)
    config.name, config.price, config.color = name, price, Color3.fromHex(color)
    config.acceleration, config.topSpeed = acceleration, speed
    if id == "AdventureBike" then
        config.class = "Adventure motorcycle"
        config.density, config.wheelbase, config.length, config.width = 3.18, 5.22, 7.44, 2.37
        config.tireWidth, config.ride = 0.47, 0.77
    end
    Catalog.vehicles[id] = config
    table.insert(Catalog.order, id)
end

return Catalog
