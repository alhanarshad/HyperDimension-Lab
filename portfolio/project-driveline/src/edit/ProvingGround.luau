local previous = workspace:FindFirstChild("Driveline")
assert(not previous, "Driveline world already exists")
local world = Instance.new("Folder")
world.Name = "Driveline"
local ground = Instance.new("Part", world)
ground.Name, ground.Anchored = "Test Asphalt", true
ground.Size, ground.Position = Vector3.new(236, 1, 415), Vector3.new(0, -0.5, -112)
ground.Material, ground.Color = Enum.Material.Asphalt, Color3.fromRGB(48, 56, 62)
local launch = Instance.new("Part", world)
launch.Name, launch.Anchored = "Launch", true
launch.Size, launch.CFrame = Vector3.one, CFrame.new(-15, 2.14, 49)
launch.Transparency, launch.CanCollide, launch.CanTouch, launch.CanQuery = 1, false, false, false
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
spawn.CFrame = CFrame.new(-19.5, 0.25, 49)
spawn.Size = Vector3.new(3, 0.5, 3)
spawn.Transparency, spawn.CanCollide, spawn.Duration = 1, false, 0
world.Parent = workspace
return "Installed the proving ground"
