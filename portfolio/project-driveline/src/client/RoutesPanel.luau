local RoutesPanel = {}

function RoutesPanel.create(hud, shared, dismissOthers)
    local routes = require(shared.Routes)
    local player = game.Players.LocalPlayer
    local factory = hud.factory
    local panel = factory.panel("RoutesPanel", hud.gui, UDim2.fromOffset(390, 250),
        UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
    panel.Visible = false
    local scale = Instance.new("UIScale", panel)
    local function resize()
        local size = workspace.CurrentCamera.ViewportSize
        scale.Scale = math.min(1, (size.X - 22) / 390, (size.Y - 22) / 250)
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    resize()
    factory.label("Title", panel, "Driving routes", 20, 16, 11, 230, 32, nil, true)
    local status = factory.label("Result", panel, "Sit in your vehicle, then accept a route.", 12, 16, 210, 356, 30, factory.muted)
    status.TextWrapped = true
    local tracker = factory.panel("RouteTracker", hud.gui, UDim2.fromOffset(270, 38), UDim2.fromOffset(18, 143))
    local progress = factory.label("Progress", tracker, "", 11, 13, 4, 244, 30, factory.muted, true)
    tracker.Visible = false

    local marker
    local function refresh()
        if marker then marker:Destroy(); marker = nil end
        local id = player:GetAttribute("DrivelineJob")
        local route = id and routes[id]
        local index = player:GetAttribute("DrivelineJobIndex")
        local message = player:GetAttribute("DrivelineJobResult")
        if not route or not index or not route.points[index] then
            tracker.Visible = message ~= nil and message ~= ""
            progress.Text = message or ""
            if tracker.Visible then
                local captured = message
                task.delay(7, function() if progress.Text == captured then tracker.Visible = false end end)
            end
            return
        end
        tracker.Visible = true
        progress.Text = string.format("%s  %d/%d", route.title, index, #route.points)
        local point = route.points[index]
        marker = Instance.new("Part")
        marker.Anchored, marker.CanCollide, marker.CanTouch, marker.CanQuery = true, false, false, false
        marker.Position, marker.Size, marker.Transparency = point + Vector3.yAxis * 5, Vector3.one, 1
        marker.Parent = workspace
        local label = Instance.new("BillboardGui", marker)
        label.Size = UDim2.fromOffset(122, 38)
        label.AlwaysOnTop, label.MaxDistance = true, 1500
        factory.label("Waypoint", label, string.format("◆  %d / %d", index, #route.points), 16, 6, 2, 116, 34,
            Color3.fromRGB(255, 191, 88), true)
    end
    for _, attr in {"DrivelineJob", "DrivelineJobIndex", "DrivelineJobResult"} do
        player:GetAttributeChangedSignal(attr):Connect(refresh)
    end
    local busy = false
    local function request(action, id)
        if busy then return end
        busy = true
        task.spawn(function()
            local ok, success, issue = pcall(function() return shared.JobRequest:InvokeServer(action, id) end)
            busy = false
            if not ok then status.Text = "Route connection interrupted."; return end
            if not success then status.Text = issue; return end
            panel.Visible = false
        end)
    end
    for index, id in {"FoundryCourier", "RedBasinRun", "PineDivideClimb"} do
        local route = routes[id]
        local y = 47 + (index - 1) * 44
        factory.label(id, panel, route.title, 13, 18, y, 237, 20, nil, true)
        factory.label(id .. "Info", panel, route.location .. "  ·  $" .. route.payout,
            11, 18, y + 21, 237, 17, factory.muted)
        factory.button(panel, "ACCEPT", 286, y + 4, 86, function() request("Start", id) end)
    end
    factory.button(panel, "CANCEL ACTIVE ROUTE", 17, 178, 152, function() request("Cancel") end)
    factory.button(panel, "CLOSE", 300, 12, 71, function() panel.Visible = false end)
    local open = factory.button(hud.gui, "ROUTES", 0, 0, 85, function()
        if not panel.Visible then dismissOthers() end
        panel.Visible = not panel.Visible
    end)
    open.Position, open.AnchorPoint = UDim2.new(1, -18, 0, 248), Vector2.new(1, 0)
    refresh()
    return {close = function() panel.Visible = false end}
end

return RoutesPanel
