local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local Garage = {}

function Garage.create(hud, shared, catalog, closeSettings)
    local factory = hud.factory
    local shell = factory.panel("Garage", hud.gui, UDim2.fromOffset(515, 367),
        UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
    shell.Visible = false
    local scale = Instance.new("UIScale", shell)
    local function resize()
        local viewport = workspace.CurrentCamera.ViewportSize
        scale.Scale = math.min(1, (viewport.X - 22) / 515, (viewport.Y - 22) / 367)
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    resize()
    local title = factory.label("Title", shell, "Motor Court Garage", 20, 17, 8, 322, 34, nil, true)
    local result = factory.label("Result", shell, "", 12, 17, 329, 480, 24, factory.muted)
    local name = factory.label("VehicleName", shell, "", 18, 174, 53, 322, 27, nil, true)
    local specification = factory.label("Specifications", shell, "", 12, 174, 81, 322, 23, factory.muted)
    local list = Instance.new("ScrollingFrame", shell)
    list.Name, list.BackgroundTransparency = "Rows", 1
    list.Position, list.Size = UDim2.fromOffset(17, 59), UDim2.fromOffset(145, 210)
    list.BorderSizePixel, list.ScrollBarThickness = 0, 4
    list.CanvasSize, list.ScrollingDirection = UDim2.fromOffset(0, 0), Enum.ScrollingDirection.Y
    local preview = Instance.new("ViewportFrame", shell)
    preview.Name, preview.Position, preview.Size = "Preview", UDim2.fromOffset(174, 110), UDim2.fromOffset(324, 155)
    preview.BackgroundColor3, preview.BorderSizePixel = Color3.fromRGB(32, 56, 61), 0
    preview.Ambient, preview.LightColor, preview.LightDirection = Color3.fromRGB(174, 180, 184),
        Color3.fromRGB(241, 232, 207), Vector3.new(-1, -1, -0.4)
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
    local camera = Instance.new("Camera", preview)
    preview.CurrentCamera = camera
    camera.FieldOfView = 35
    local stage = Instance.new("WorldModel", preview)
    local builder = require(shared.CarBuilder)
    local angle, selected, profile, busy, mode, confirmation = -0.85, nil, nil, false, "Garage", nil
    local purchase, favorite, storeCar, demo, nextOption, nextChoice
    local optionIndex, choiceIndex = 1, 1
    local tuning = require(shared.Tuning)

    local function rotate()
        angle += math.rad(45)
        camera.CFrame = CFrame.lookAt(Vector3.new(math.sin(angle) * 21, 7.0, math.cos(angle) * -21),
            Vector3.new(0, 0.8, 0))
    end

    local function choose(id, resetWorkshopSelection)
        if not id then return end
        local workshop = mode == "Workshop"
        local market = mode == "Dealer"
        local redraw = workshop or selected ~= id or #stage:GetChildren() == 0
        if resetWorkshopSelection or selected ~= id then
            local build = profile.builds[id]
            choiceIndex = build and build[tuning.options[optionIndex].key] or 1
        end
        selected = id
        confirmation = nil
        local config = catalog.vehicles[id]
        name.Text = config.name
        local owned = table.find(profile.owned, id)
        local persisted = profile.builds[id] or {}
        if workshop then
            local option = tuning.options[optionIndex]
            local choice = option.choices[choiceIndex]
            local installed = choiceIndex == (persisted[option.key] or 1)
            specification.Text = string.format("%s  /  %s  /  %s", option.name, choice.name,
                installed and "Installed" or (choice.price == 0 and "Free" or "$" .. choice.price))
            purchase.Text = installed and "INSTALLED" or "INSTALL"
            purchase.Active, purchase.AutoButtonColor = not installed, not installed
            local previewBuild = table.clone(persisted)
            previewBuild[option.key] = choiceIndex
            config = tuning.config(config, previewBuild)
        elseif market then
            specification.Text = string.format("%s  ·  %s  ·  %s", config.class, config.drivetrain,
                owned and "Owned" or ("$" .. tostring(config.price)))
            purchase.Text = owned and "OWNED" or "BUY CAR"
            purchase.Active, purchase.AutoButtonColor = not owned, not owned
        else
            specification.Text = string.format("%s  ·  %s  ·  %d km/h target", config.class, config.drivetrain,
                math.round(config.topSpeed * catalog.kmhPerStudSecond))
            purchase.Text = "DEPLOY"
            purchase.Active, purchase.AutoButtonColor = true, true
            config = tuning.config(config, persisted)
        end
        if not redraw then return end
        stage:ClearAllChildren()
        builder.build(id, config, CFrame.identity, true).Parent = stage
        angle = -1.45
        rotate()
    end

    local function paint()
        list:ClearAllChildren()
        local market = mode == "Dealer"
        local rows = table.clone(market and catalog.order or profile.owned)
        table.sort(rows, function(a, b)
            local aFavorite, bFavorite = profile.favorites[a] == true, profile.favorites[b] == true
            if aFavorite ~= bFavorite then return aFavorite end
            return catalog.vehicles[a].name < catalog.vehicles[b].name
        end)
        for n, id in rows do
            local prefix = profile.active == id and "● " or (profile.favorites[id] and "★ " or "")
            local row = factory.button(list, prefix .. (catalog.vehicles[id].shortName or catalog.vehicles[id].name),
                0, (n - 1) * 39, 136, function()
                if not busy then choose(id) end
            end)
            row.Name = id
        end
        list.CanvasSize = UDim2.fromOffset(0, #rows * 39)
        local activeOwned = table.find(rows, profile.active) and profile.active
        choose(table.find(rows, selected) and selected or activeOwned or rows[1], true)
        demo.Visible = market
    end

    local function request(action)
        if busy then return end
        busy = true
        result.Text = "Contacting garage…"
        local id, category, choice = selected, tuning.options[optionIndex].key, choiceIndex
        task.spawn(function()
            local connected, accepted, data = pcall(function()
                return shared.GarageRequest:InvokeServer(action, id, category, choice)
            end)
            busy = false
            if not connected then result.Text = "Garage connection interrupted."; return end
            if not accepted then result.Text = data; return end
            profile = data
            paint()
            if action == "Deploy" or action == "Demo" then result.Text = "Vehicle deployed to the arrival bay."
            elseif action == "Buy" then result.Text = "Purchase complete. Deploy your car from the garage."
            elseif action == "Tune" then result.Text = "Modification saved. Deploy the car to apply it."
            elseif action == "Store" then result.Text = "Vehicle stored."
            elseif action == "Favorite" then result.Text = profile.favorites[id] and "Added to favorites." or "Removed from favorites."
            elseif mode == "Dealer" then result.Text = "Balance  $" .. profile.cash
            elseif mode == "Workshop" then result.Text = "Select a category and preview its options."
            else result.Text = "Select a vehicle from your collection."
            end
        end)
    end

    local function toggle(nextMode)
        if shell.Visible then
            if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(shell) then GuiService.SelectedObject = nil end
            shell.Visible = false
            if nextMode == nil or nextMode == mode then return end
        end
        if nextMode then
            closeSettings()
            mode, selected, confirmation = nextMode, nil, nil
            title.Text = ({Dealer = "Foundry Motors", Garage = "Motor Court Garage", Workshop = "Service Works"})[mode]
            favorite.Visible, storeCar.Visible, demo.Visible = mode == "Garage", mode == "Garage", false
            nextOption.Visible, nextChoice.Visible = mode == "Workshop", mode == "Workshop"
            shell.Visible = true
            if profile then paint() end
            request("View")
            if UIS.GamepadEnabled then GuiService.SelectedObject = shell.CLOSE end
        end
    end

    factory.button(shell, "CLOSE", 423, 13, 75, function() toggle() end)
    factory.button(shell, "ROTATE", 174, 272, 76, rotate)
    favorite = factory.button(shell, "FAVORITE", 257, 272, 97, function() request("Favorite") end)
    purchase = factory.button(shell, "DEPLOY", 361, 272, 137, function()
        if not selected or not profile or busy then return end
        if mode == "Garage" then request("Deploy"); return end
        if mode == "Workshop" then
            local category = tuning.options[optionIndex]
            local option = category.choices[choiceIndex]
            local build = profile.builds[selected] or {}
            if choiceIndex == (build[category.key] or 1) then return end
            if confirmation ~= option then
                confirmation = option
                purchase.Text = "CONFIRM INSTALL"
                result.Text = string.format("Install %s for $%d?", option.name, option.price)
            else
                request("Tune")
            end
            return
        end
        if table.find(profile.owned, selected) then return end
        if confirmation ~= selected then
            confirmation = selected
            purchase.Text = "CONFIRM PURCHASE"
            result.Text = string.format("Buy %s for $%d?", catalog.vehicles[selected].name, catalog.vehicles[selected].price)
            return
        end
        request("Buy")
    end)
    storeCar = factory.button(shell, "STORE CAR", 17, 272, 141, function() request("Store") end)
    demo = factory.button(shell, "TEST DRIVE", 257, 272, 97, function() request("Demo") end)
    demo.Visible = false
    nextOption = factory.button(shell, "CATEGORY", 17, 272, 141, function()
        if not selected or busy then return end
        optionIndex = optionIndex % #tuning.options + 1
        choose(selected, true)
        result.Text = "Select an option to preview."
    end)
    nextChoice = factory.button(shell, "NEXT OPTION", 257, 272, 97, function()
        if not selected or busy then return end
        choiceIndex = choiceIndex % #tuning.options[optionIndex].choices + 1
        choose(selected)
        result.Text = "Select Install to confirm this option."
    end)
    local open = factory.button(hud.gui, "GARAGE", 0, 0, 85, function() toggle("Garage") end)
    open.Position, open.AnchorPoint = UDim2.new(1, -18, 0, 92), Vector2.new(1, 0)
    local dealer = factory.button(hud.gui, "DEALER", 0, 0, 85, function() toggle("Dealer") end)
    dealer.Position, dealer.AnchorPoint = UDim2.new(1, -18, 0, 131), Vector2.new(1, 0)
    local workshop = factory.button(hud.gui, "WORKSHOP", 0, 0, 85, function() toggle("Workshop") end)
    workshop.Position, workshop.AnchorPoint = UDim2.new(1, -18, 0, 170), Vector2.new(1, 0)
    return {toggle = toggle, openDealer = function() if not shell.Visible or mode ~= "Dealer" then toggle("Dealer") end end,
        close = function() if shell.Visible then toggle() end end}
end

return Garage
