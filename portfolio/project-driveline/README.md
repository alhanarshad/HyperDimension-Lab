# Project Driveline

Public source snapshot of a Roblox driving simulator with server-side raycast suspension, automatic transmissions, a garage, vehicle tuning, checkpoint jobs, and rope-based vehicle recovery.

The public snapshot has eight fictional vehicles, including two recovery pickups and three motorcycles. The original Studio build was playtested with a larger roster. The public snapshot uses no external recordings and contains only the editable scripts.

## Assemble in Roblox Studio

1. Create a new Baseplate place. Add a `Driveline` folder under `ReplicatedStorage`, `ServerScriptService`, and `StarterPlayer.StarterPlayerScripts`.
2. Under `ReplicatedStorage.Driveline`, install the shared ModuleScripts, two RemoteEvents named `DriveInput` and `CarAction`, and RemoteFunctions named `GarageRequest`, `TravelRequest`, and `JobRequest`.
3. Install the server modules and the `Main` Script under `ServerScriptService.Driveline`. Install the client modules and `Drive` LocalScript under `StarterPlayer.StarterPlayerScripts.Driveline`.
4. Run the edit scripts in the Command Bar in this order: `ProvingGround`, `FoundryDistrict`, `FoundryMotors`, `Frontier`, `InternationalDistricts`, `WorldExtensions`. Run them in a fresh place. Some edit scripts replace geometry they created in earlier steps.
5. Press **Play**. Approach the Aster and press **E**, then **I** to start. Use **WASD** to drive, **F2** for travel, **T** for recovery, and **N** for low range on supported AWD vehicles.

The local original passed driving, teleport, towing, purchase and route-reward playtests. The public snapshot changes catalog names and sound configuration. Live DataStore and multi-client play remain unverified.
