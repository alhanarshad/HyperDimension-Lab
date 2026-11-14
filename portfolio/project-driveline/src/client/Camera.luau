local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = {}
Camera.modes = {"Chase", "Close", "Hood", "Free look"}

function Camera.create(settings)
    local car, mode, yaw, pitch = nil, 1, 0, 0.16
    local smoothed, heading
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.RespectCanCollide = true
    local view = {}

    local function look(delta)
        yaw -= delta.X * 0.0055 * settings.sensitivity
        pitch = math.clamp(pitch + delta.Y * 0.0055 * settings.sensitivity, -0.25, 1.05)
    end
    UIS.InputChanged:Connect(function(obj, captured)
        if car and obj.UserInputType == Enum.UserInputType.MouseMovement
            and (mode == 4 or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
            look(obj.Delta)
        elseif car and mode == 4 and not captured and obj.UserInputType == Enum.UserInputType.Touch then
            look(obj.Delta)
        end
    end)
    function view.set(model, character)
        car, smoothed, heading = model, nil, nil
        yaw, pitch = 0, 0.16
        local camera = workspace.CurrentCamera
        if car then
            ray.FilterDescendantsInstances = {model, character}
            camera.CameraType = Enum.CameraType.Scriptable
        else
            camera.CameraType, camera.FieldOfView = Enum.CameraType.Custom, 70
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then camera.CameraSubject = humanoid end
        end
    end
    function view.cycle()
        mode = mode % #Camera.modes + 1
        yaw, pitch = 0, 0.16
        return Camera.modes[mode]
    end

    RunService:BindToRenderStep("DrivelineCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not car or not car.PrimaryPart then return end
        local root, camera = car.PrimaryPart, workspace.CurrentCamera
        local cf = root.CFrame
        local speed = root.AssemblyLinearVelocity.Magnitude
        local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if flat.Magnitude < 0.1 then flat = heading or -Vector3.zAxis end
        heading = heading and heading:Lerp(flat.Unit, 1 - math.exp(-8 * dt)).Unit or flat.Unit
        for _, gamepad in UIS:GetConnectedGamepads() do
            for _, input in UIS:GetGamepadState(gamepad) do
                if input.KeyCode == Enum.KeyCode.Thumbstick2 and input.Position.Magnitude > 0.16 then
                    look(Vector2.new(input.Position.X, -input.Position.Y) * dt * 265)
                end
            end
            break
        end
        if mode ~= 4 and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            yaw *= math.exp(-2 * dt)
        end
        local aim = root.Position + Vector3.yAxis * 1.55
        local desired, target
        if mode == 3 then
            desired = cf:PointToWorldSpace(Vector3.new(0, 2.15, -3.25))
            target = desired + heading * 34 + Vector3.yAxis * 0.9
        else
            local baseDistance = mode == 2 and 9 or (mode == 4 and 15 or 13)
            local distance = baseDistance + (settings.reducedMotion and 0 or math.min(speed * 0.047, 5.5))
            local back = CFrame.fromAxisAngle(Vector3.yAxis, yaw):VectorToWorldSpace(-heading)
            desired = aim + back * (distance * math.cos(pitch))
                + Vector3.yAxis * (2.2 + distance * math.sin(pitch))
            target = aim + heading * (mode == 4 and 0 or 2.8)
        end
        smoothed = smoothed and smoothed:Lerp(desired, 1 - math.exp(-12 * dt)) or desired
        if mode ~= 3 then
            local hit = workspace:Raycast(aim, smoothed - aim, ray)
            if hit then
                smoothed = hit.Position - (smoothed - aim).Unit * 0.45
            end
        end
        camera.CFrame = CFrame.lookAt(smoothed, target)
        camera.Focus = CFrame.new(aim)
        local fov = settings.reducedMotion and 69 or 69 + math.min(speed * 0.07, 8)
        camera.FieldOfView += (fov - camera.FieldOfView) * (1 - math.exp(-5 * dt))
    end)
    return view
end

return Camera
