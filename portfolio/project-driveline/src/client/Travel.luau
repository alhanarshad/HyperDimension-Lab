local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local Travel = {}

local places = {
    {"City", "Foundry District", "City streets and the Motor Court garage"},
    {"Dealer", "Foundry Motors", "Dealership, showroom and workshop"},
    {"Desert", "Red Basin Sand Dunes", "Sand, dune tracks and a recovery car"},
    {"Mountain", "Pine Divide Off-Road", "Mountain ascent, snow line and a recovery truck"},
    {"Paris", "Paris Promenade", "Limestone boulevards and the Iron Tower"},
    {"Dubai", "Downtown Dubai", "Glass avenues and the Downtown Spire"},
    {"Tokyo", "Tokyo", "Shop streets and the Tokyo Tower district"},
    {"Manhattan", "Manhattan", "Avenues and the Empire State Building"},
}

function Travel.create(hud, shared, dismissOthers, arrive)
    local factory = hud.factory
    local menu = factory.panel("TravelMenu", hud.gui, UDim2.fromOffset(447, 424),
        UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
    menu.Visible = false
    local scaler = Instance.new("UIScale", menu)
    local function layout()
        local view = workspace.CurrentCamera.ViewportSize
        scaler.Scale = math.min(1, (view.X - 24) / 447, (view.Y - 22) / 424)
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
    layout()
    factory.label("Title", menu, "World travel", 22, 19, 10, 260, 37, nil, true)
    local status = factory.label("Result", menu, "Choose a destination. You can travel with your stopped vehicle.",
        11, 19, 388, 410, 28, factory.muted)
    status.TextWrapped = true
    local list = Instance.new("ScrollingFrame")
    list.Name, list.Position, list.Size = "Destinations", UDim2.fromOffset(0, 53), UDim2.fromOffset(445, 332)
    list.BackgroundTransparency, list.BorderSizePixel = 1, 0
    list.ScrollBarThickness, list.ScrollingDirection = 5, Enum.ScrollingDirection.Y
    list.CanvasSize = UDim2.fromOffset(0, #places * 55)
    list.Parent = menu
    local busy = false
    local close
    local function open(value)
        menu.Visible = value
        if value and UIS.GamepadEnabled then
            GuiService.SelectedObject = close
        elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(menu) then
            GuiService.SelectedObject = nil
        end
    end
    close = factory.button(menu, "CLOSE", 350, 15, 77, function() open(false) end)
    for index, data in places do
        local y = (index - 1) * 55
        local card = factory.panel(data[1], list, UDim2.fromOffset(411, 49), UDim2.fromOffset(18, y),
            nil, Color3.fromRGB(18, 38, 44), 0.08)
        factory.label("Destination", card, data[2], 14, 10, 4, 310, 22, nil, true)
        factory.label("Description", card, data[3], 10, 10, 26, 310, 16, factory.muted)
        factory.button(card, "TRAVEL", 337, 9, 64, function()
            if busy then return end
            busy = true
            status.Text = "Traveling to " .. data[2] .. "…"
            task.spawn(function()
                local ok, success, message = pcall(function() return shared.TravelRequest:InvokeServer(data[1]) end)
                busy = false
                if not ok then status.Text = "Travel connection interrupted."; return end
                if not success then status.Text = message; return end
                status.Text = "Arrived at " .. data[2] .. "."
                open(false)
                arrive(data[1])
            end)
        end)
    end
    local function toggle()
        if not menu.Visible then dismissOthers() end
        open(not menu.Visible)
    end
    local opener = factory.button(hud.gui, "TRAVEL", 0, 0, 85, toggle)
    opener.Position, opener.AnchorPoint = UDim2.new(1, -18, 0, 209), Vector2.new(1, 0)
    return {toggle = toggle, close = function() open(false) end}
end

return Travel
