local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local Input = {}

function Input.attach(shared, onCamera, onSettings)
    local axes = {}
    local active = false
    local names = {
        "Forward", "Brake", "Left", "Right", "Steer", "Parking", "Engine",
        "Lights", "Camera", "Reset", "Exit", "Hazards", "SignalLeft", "SignalRight", "Lock", "Settings",
        "Tow", "Consent", "Horn", "Range",
    }
    local priority = Enum.ContextActionPriority.High.Value + 20
    local function axis(name, touch, title, position, ...)
        CAS:BindActionAtPriority("DL" .. name, function(_, state, object)
            if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                axes[name] = 0
            elseif object.KeyCode == Enum.KeyCode.Thumbstick1 then
                local x = object.Position.X
                axes[name] = math.sign(x) * math.max(0, (math.abs(x) - 0.13) / 0.87)
            elseif object.KeyCode == Enum.KeyCode.ButtonR2 or object.KeyCode == Enum.KeyCode.ButtonL2 then
                axes[name] = math.clamp(object.Position.Z, 0, 1)
            else
                axes[name] = 1
            end
            return Enum.ContextActionResult.Sink
        end, touch, priority, ...)
        if touch then
            CAS:SetTitle("DL" .. name, title)
            CAS:SetPosition("DL" .. name, position)
        end
    end
    local function button(name, callback, ...)
        CAS:BindActionAtPriority("DL" .. name, function(_, state)
            if state == Enum.UserInputState.Begin then callback() end
            return Enum.ContextActionResult.Sink
        end, false, priority, ...)
    end
    local function command(action)
        return function() shared.CarAction:FireServer(action) end
    end

    local controller = {}
    function controller.set(mode)
        if active == mode then return end
        active = mode
        for _, name in names do CAS:UnbindAction("DL" .. name) end
        table.clear(axes)
        if mode == false then return end
        button("Exit", command("Exit"), Enum.KeyCode.X, Enum.KeyCode.Space, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonA)
        if mode == "Passenger" then return end
        local K = Enum.KeyCode
        axis("Forward", true, "GAS", UDim2.new(1, -74, 1, -122), K.W, K.Up, K.ButtonR2)
        axis("Brake", true, "BRAKE", UDim2.new(1, -140, 1, -72), K.S, K.Down, K.ButtonL2)
        axis("Left", true, "LEFT", UDim2.new(0, 17, 1, -81), K.A, K.Left)
        axis("Right", true, "RIGHT", UDim2.new(0, 85, 1, -81), K.D, K.Right)
        axis("Steer", false, "", nil, K.Thumbstick1)
        axis("Parking", true, "PARK", UDim2.new(1, -78, 1, -58), K.LeftShift, K.ButtonL1)
        button("Engine", command("Engine"), K.I, K.DPadUp)
        button("Lights", command("Lights"), K.L, K.DPadDown)
        button("Camera", onCamera, K.C, K.ButtonR1)
        button("Reset", command("Reset"), K.R)
        button("Hazards", command("Hazards"), K.H)
        button("SignalLeft", command("Left"), K.Z, K.DPadLeft)
        button("SignalRight", command("Right"), K.V, K.DPadRight)
        button("Lock", command("Lock"), K.K)
        button("Tow", command("Tow"), K.T, K.ButtonR3)
        button("Consent", command("Consent"), K.Y)
        button("Horn", command("Horn"), K.J, K.ButtonL3)
        button("Range", command("Range"), K.N)
        button("Settings", onSettings, K.F1, K.ButtonSelect)
    end
    function controller.send()
        if active ~= "Driver" then return end
        local turn = (axes.Right or 0) - (axes.Left or 0) + (axes.Steer or 0)
        if UIS:GetFocusedTextBox() then turn = 0 end
        shared.DriveInput:FireServer(axes.Forward or 0, axes.Brake or 0,
            math.clamp(turn, -1, 1), (axes.Parking or 0) > 0)
    end
    UIS.WindowFocusReleased:Connect(function() table.clear(axes) end)
    return controller
end

return Input
