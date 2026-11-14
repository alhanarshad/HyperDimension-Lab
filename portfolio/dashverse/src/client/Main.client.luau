local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Dashverse")
local command = shared:WaitForChild("Command")
local message = shared:WaitForChild("Message")
local Interface = require(script.Parent.Interface)
local Effects = require(script.Parent.Effects)

local effects = Effects.new()
local ui = Interface.new(gui, function(...)
	command:FireServer(...)
end, function(id)
	effects:play(id)
end)

message.OnClientEvent:Connect(function(kind, a, b, c, d)
	if kind == "state" then
		ui:sync(a)
		effects:sync(a)
	elseif kind == "notice" then
		ui:toastMessage(a, b)
		effects:notice(b)
	elseif kind == "page" then
		ui:open(a, b)
	elseif kind == "pickup" then
		effects:pickup(a, d)
		ui:toastMessage(("+%d Energy   +%d Coins"):format(b, c))
	elseif kind == "results" then
		ui.standings[a] = b
		if ui.page == "Races" then ui:render(true) end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q and not ui.page then
		command:FireServer("dash")
	elseif input.KeyCode == Enum.KeyCode.Tab then
		ui:open(if ui.page then nil else "Menu")
	elseif input.KeyCode == Enum.KeyCode.ButtonB and ui.page then
		ui:open(nil)
	end
end)

command:FireServer("sync")
task.spawn(function()
	while task.wait(0.12) do ui:clock() end
end)
