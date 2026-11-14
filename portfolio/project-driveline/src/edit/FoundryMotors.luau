local block = workspace.Driveline.FoundryDistrict["Motor Court"]
local showroom = Instance.new("Model")
showroom.Name = "Foundry Motors"
local Color = Color3.fromRGB
local function part(name, w, h, d, x, y, z, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, Vector3.new(w, h, d), CFrame.new(x, y, z)
    p.Anchored, p.Material, p.Color = true, material, color
    p.Parent = showroom
    return p
end
local stone, steel, glow = Color(172, 168, 151), Color(34, 53, 58), Color(136, 233, 194)
part("Showroom floor", 35, 0.32, 23, -91, 0.53, 71, stone, Enum.Material.Concrete)
part("Cantilevered canopy", 37, 0.7, 25, -91, 9.1, 71, steel, Enum.Material.Metal)
part("Service desk", 7.5, 2.6, 2.2, -102, 1.98, 66, steel, Enum.Material.Metal)
part("Back wall", 35, 8.1, 0.45, -91, 4.65, 59.7, steel, Enum.Material.Concrete)
part("Showroom fascia", 35, 2.5, 0.3, -91, 8.3, 83.6, steel, Enum.Material.Metal)
local fascia = showroom["Showroom fascia"]
local sign = Instance.new("SurfaceGui", fascia)
sign.Face, sign.SizingMode, sign.PixelsPerStud = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 22
local label = Instance.new("TextLabel", sign)
label.Size, label.BackgroundTransparency, label.TextScaled = UDim2.fromScale(1, 1), 1, true
label.Font, label.Text, label.TextColor3 = Enum.Font.GothamBold, "FOUNDRY  MOTORS", glow
for _, x in {-108, -74} do
    part("Steel jamb", 0.55, 8.2, 0.65, x, 4.8, 82.0, steel, Enum.Material.Metal)
end
for _, x in {-105, -77} do
    part("Canopy strip", 0.28, 0.11, 19, x, 8.67, 71, glow, Enum.Material.Neon)
end
local desk = showroom["Service desk"]
local prompt = Instance.new("ProximityPrompt", desk)
prompt.ActionText, prompt.ObjectText = "Browse vehicles", "Foundry Motors"
prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 10, false
prompt:SetAttribute("DrivelineDealer", true)
local asset = game.ReplicatedStorage.Driveline
local catalog = require(asset.Catalog)
local builder = require(asset.CarBuilder)
local display = builder.build("Meridian", catalog.vehicles.Meridian, CFrame.new(-86, 2.57, 71) * CFrame.Angles(0, 0.52, 0), true)
display.PrimaryPart.CanCollide, display.PrimaryPart.CanQuery = false, false
display.Parent = showroom
showroom.Parent = block
return showroom:GetFullName()
