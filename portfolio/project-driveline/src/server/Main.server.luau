require(script.Parent.GarageService).start()
require(script.Parent.Jobs)
local vehicles = require(script.Parent.VehicleService)
local lastTravel = {}
local locations = {
    City = true, Dealer = true, Desert = true, Mountain = true,
    Paris = true, Dubai = true, Tokyo = true, Manhattan = true,
}
game.ReplicatedStorage.Driveline.TravelRequest.OnServerInvoke = function(player, destination)
    if type(destination) ~= "string" or not locations[destination] then return false, "Unknown destination." end
    local now = os.clock()
    if now - (lastTravel[player] or -8) < 4 then return false, "Travel is cooling down." end
    lastTravel[player] = now
    return vehicles.travel(player, destination)
end
game.Players.PlayerRemoving:Connect(function(player) lastTravel[player] = nil end)
