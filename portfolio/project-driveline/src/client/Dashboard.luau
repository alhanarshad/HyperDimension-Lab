local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local catalog = require(game.ReplicatedStorage.Driveline.Catalog)
local Dashboard = {}

local ink = Color3.fromRGB(10, 23, 29)
local paper = Color3.fromRGB(232, 244, 240)
local muted = Color3.fromRGB(163, 190, 189)
local mint = Color3.fromRGB(104, 234, 191)
local amber = Color3.fromRGB(255, 185, 97)

local function panel(name, parent, size, position, anchor, color, transparency)
    local frame = Instance.new("Frame")
    frame.Name, frame.Size, frame.Position = name, size, position
    frame.AnchorPoint, frame.BackgroundColor3 = anchor or Vector2.zero, color or ink
    frame.BackgroundTransparency, frame.BorderSizePixel = transparency or 0.09, 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)
    local outline = Instance.new("UIStroke", frame)
    outline.Color, outline.Transparency = muted, 0.73
    frame.Parent = parent
    return frame
end

local function label(name, parent, value, size, x, y, width, height, color, heavy)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Position, item.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
    item.Font = heavy and Enum.Font.GothamBold or Enum.Font.GothamMedium
    item.Text, item.TextSize, item.TextColor3 = value, size, color or paper
    item.BackgroundTransparency, item.TextXAlignment = 1, Enum.TextXAlignment.Left
    item.Parent = parent
    return item
end

local function button(parent, name, x, y, width, callback)
    local item = Instance.new("TextButton")
    item.Name, item.Text = name, name
    item.Position, item.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, 31)
    item.Font, item.TextSize, item.TextColor3 = Enum.Font.GothamBold, 11, mint
    item.BackgroundColor3, item.BorderSizePixel = Color3.fromRGB(24, 53, 57), 0
    local corner = Instance.new("UICorner", item)
    corner.CornerRadius = UDim.new(0, 5)
    item.Activated:Connect(callback)
    item.Parent = parent
    return item
end

function Dashboard.create(player, settings, callbacks)
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "Driveline", false, 6
    gui.Parent = player:WaitForChild("PlayerGui")
    local top = panel("Identity", gui, UDim2.fromOffset(270, 60), UDim2.fromOffset(18, 14))
    label("Brand", top, "PROJECT  DRIVELINE", 15, 14, 7, 243, 21, mint, true)
    local district = label("District", top, "FOUNDRY DISTRICT", 11, 14, 31, 242, 17, muted)
    local balance = label("Balance", top, "", 12, 170, 29, 86, 19, mint, true)
    balance.TextXAlignment = Enum.TextXAlignment.Right
    local function refreshBalance()
        local cash = player:GetAttribute("DrivelineBalance")
        balance.Text = cash and ("$" .. tostring(cash):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) or ""
    end
    player:GetAttributeChangedSignal("DrivelineBalance"):Connect(refreshBalance)
    refreshBalance()
    local tipPanel = panel("Welcome", gui, UDim2.fromOffset(270, 51), UDim2.fromOffset(18, 82))
    local tip = label("Next", tipPanel, "Approach your Aster and select Drive.", 12, 14, 6, 243, 38, paper)
    tip.TextWrapped = true

    local settingsButton = button(gui, "SETTINGS", 0, 0, 85, callbacks.settings)
    settingsButton.AnchorPoint, settingsButton.Position = Vector2.new(1, 0), UDim2.new(1, -18, 0, 14)
    local resetButton = button(gui, "RECALL CAR", 0, 0, 85, function() callbacks.action("Reset") end)
    resetButton.AnchorPoint, resetButton.Position = Vector2.new(1, 0), UDim2.new(1, -18, 0, 53)

    local hud = panel("DrivingHUD", gui, UDim2.fromOffset(240, 149),
        UDim2.new(1, -18, 1, -18), Vector2.one)
    hud.Visible = false
    local modelName = label("Model", hud, "ASTER 160", 11, 15, 10, 220, 19, muted, true)
    local speed = label("Speed", hud, "0", 51, 12, 27, 135, 58, paper, true)
    local units = label("Units", hud, "KM/H", 11, 17, 83, 65, 17, muted, true)
    local gear = label("Gear", hud, "N", 30, 172, 33, 53, 42, mint, true)
    gear.TextXAlignment = Enum.TextXAlignment.Right
    local rpm = label("RPM", hud, "0 RPM", 11, 132, 83, 93, 17, muted)
    rpm.TextXAlignment = Enum.TextXAlignment.Right
    local bar = Instance.new("Frame", hud)
    bar.Name, bar.Position, bar.Size = "RPMTrack", UDim2.fromOffset(15, 108), UDim2.fromOffset(210, 4)
    bar.BorderSizePixel, bar.BackgroundColor3 = 0, Color3.fromRGB(41, 63, 69)
    local fill = Instance.new("Frame", bar)
    fill.Name, fill.Size, fill.BorderSizePixel, fill.BackgroundColor3 = "Fill", UDim2.fromScale(0, 1), 0, mint
    local status = label("Status", hud, "", 10, 15, 118, 210, 20, amber, true)

    local actions = panel("CarControls", gui, UDim2.fromOffset(245, 42),
        UDim2.new(0, 18, 1, -18), Vector2.new(0, 1))
    actions.Visible = false
    button(actions, "IGNITION", 5, 5, 60, function() callbacks.action("Engine") end)
    button(actions, "LAMPS", 68, 5, 50, function() callbacks.action("Lights") end)
    button(actions, "VIEW", 121, 5, 52, callbacks.camera)
    button(actions, "EXIT", 176, 5, 63, function() callbacks.action("Exit") end)
    local tow = button(gui, "RECOVERY LINE", 0, 0, 110, function() callbacks.action("Tow") end)
    tow.AnchorPoint, tow.Position, tow.Visible = Vector2.new(0, 1), UDim2.new(0, 18, 1, -72), false
    local consent = button(gui, "ALLOW RECOVERY", 0, 0, 115, function() callbacks.action("Consent") end)
    consent.AnchorPoint, consent.Position, consent.Visible = Vector2.new(0, 1), UDim2.new(0, 134, 1, -72), false
    local range = button(gui, "LOW RANGE", 0, 0, 110, function() callbacks.action("Range") end)
    range.AnchorPoint, range.Position, range.Visible = Vector2.new(0, 1), UDim2.new(0, 18, 1, -109), false
    local ride = button(gui, "EXIT VEHICLE", 0, 0, 100, function() callbacks.action("Exit") end)
    ride.AnchorPoint, ride.Position, ride.Visible = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -18), false

    local modal = panel("SettingsMenu", gui, UDim2.fromOffset(388, 338), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
    modal.Visible = false
    local modalScale = Instance.new("UIScale", modal)
    label("Title", modal, "Driving settings", 20, 17, 8, 250, 35, paper, true)
    local close = button(modal, "CLOSE", 300, 12, 70, callbacks.settings)
    local unit = button(modal, "KM/H", 17, 51, 69, function()
        settings.mph = not settings.mph
        callbacks.changed()
    end)
    local motion = button(modal, "MOTION STANDARD", 91, 51, 131, function()
        settings.reducedMotion = not settings.reducedMotion
        callbacks.changed()
    end)
    local sensitivity = button(modal, "LOOK 1.0", 227, 51, 67, function()
        settings.sensitivity = settings.sensitivity >= 1.5 and 0.65 or (settings.sensitivity < 1 and 1 or 1.5)
        callbacks.changed()
    end)
    local control = label("KeyGuide", modal,
        "KEYBOARD\nW / S  Accelerate / brake and reverse\nA / D  Steer   |   Shift  Handbrake   |   I  Start\nC  View   |   L  Lights   |   R  Recall   |   X  Exit\nZ / V  Signals   |   H  Hazards   |   K  Lock\nT  Recovery   |   Y  Allow recovery   |   N  Low range\nF2  World travel\n\nCONTROLLER\nRT / LT  Pedals   |   Left stick  Steer   |   LB  Park\nD-pad up  Start   |   Down  Lights   |   RB  View\nD-pad sides  Signals   |   B  Exit   |   R3  Recovery",
        12, 17, 92, 354, 229, muted)
    control.TextYAlignment = Enum.TextYAlignment.Top
    control.TextWrapped = true

    local function layout()
        local view = workspace.CurrentCamera.ViewportSize
        modalScale.Scale = math.min(1, (view.X - 24) / 388, (view.Y - 28) / 338)
        local touch = UIS.TouchEnabled
        hud.Position = touch and UDim2.new(1, -18, 1, -186) or UDim2.new(1, -18, 1, -18)
        actions.Position = touch and UDim2.new(0, 18, 1, -145) or UDim2.new(0, 18, 1, -18)
        tow.Position = UDim2.new(0, 18, 1, touch and -195 or -72)
        consent.Position = UDim2.new(0, 134, 1, touch and -195 or -72)
        range.Position = UDim2.new(0, 18, 1, touch and -232 or -109)
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
    layout()

    local view = {gui = gui, modal = modal, factory = {panel = panel, label = label, button = button, muted = muted}}
    function view.toggle()
        modal.Visible = not modal.Visible
        if modal.Visible and UIS.GamepadEnabled then
            GuiService.SelectedObject = close
        elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(modal) then
            GuiService.SelectedObject = nil
        end
    end
    function view.sync()
        unit.Text = settings.mph and "MPH" or "KM/H"
        motion.Text = settings.reducedMotion and "MOTION REDUCED" or "MOTION STANDARD"
        sensitivity.Text = string.format("LOOK %.2g", settings.sensitivity)
        units.Text = unit.Text
    end
    function view.mode(car, mode)
        hud.Visible, actions.Visible = mode == "Driver", mode == "Driver"
        tipPanel.Visible, ride.Visible = not car, mode == "Passenger"
        local id = car and car:GetAttribute("VehicleId")
        local config = id and catalog.vehicles[id]
        tow.Visible = mode == "Driver" and config and config.tow == true
        consent.Visible = mode == "Driver"
        range.Visible = mode == "Driver" and config and config.offroad == true and config.drivetrain == "AWD"
        if car then modelName.Text = string.upper(car.Name) end
    end
    function view.update(car, displaySpeed, redline, gearValue, rpmValue)
        speed.Text = tostring(math.round(displaySpeed))
        gear.Text = gearValue == 0 and "N" or (gearValue == -1 and "R" or tostring(gearValue))
        rpm.Text = string.format("%d RPM", rpmValue)
        fill.Size = UDim2.fromScale(math.clamp(rpmValue / redline, 0, 1), 1)
        fill.BackgroundColor3 = rpmValue > redline * 0.88 and amber or mint
        local signal = car:GetAttribute("Signal")
        local head = car:GetAttribute("Headlights") or 0
        if not car:GetAttribute("Engine") then
            status.Text = "IGNITION OFF  ·  PRESS I OR IGNITION"
        else
            local states = {}
            if car:GetAttribute("Parking") then table.insert(states, "PARK") end
            if head > 0 then table.insert(states, head == 2 and "HIGH BEAM" or "LIGHTS") end
            if signal and signal ~= "Off" then table.insert(states, string.upper(signal)) end
            if car:GetAttribute("Towing") then table.insert(states, "TOWING") end
            if car:GetAttribute("LowRange") then table.insert(states, "4 LOW") end
            status.Text = #states == 0 and "ENGINE RUNNING" or table.concat(states, "  ·  ")
        end
        consent.Text = car:GetAttribute("RecoveryAllowed") and "RECOVERY ALLOWED" or "ALLOW RECOVERY"
        tow.Text = car:GetAttribute("Towing") and "DETACH LINE" or "RECOVERY LINE"
        range.Text = car:GetAttribute("LowRange") and "4 LOW ACTIVE" or "LOW RANGE"
    end
    function view.location(value) district.Text = string.upper(value) end
    function view.hint(value) tip.Text = value end
    view.sync()
    return view
end

return Dashboard
