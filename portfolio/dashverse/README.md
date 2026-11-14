# Dashverse — Speed & Creatures

This public snapshot contains the editable sources and asset generators. Build your own local place with the instructions below.
Veltrix Studios · private playtest build 0.1.1

Open the saved Roblox place and press **Play** in Studio. Run down the lit arrival lane to collect three sparks and unlock Spark Fox. Open **Upgrades**, purchase a Speed level, and use **Races** to enter River Circuit. World gates use Speed level and total race finishes. Race speed is fixed at 34 studs per second.


## Project layout

| Folder or file | Purpose |
| --- | --- |
| `src/shared/Config.luau` | Districts, routes, progression, quests, achievements, creatures, and audio |
| `src/shared/Catalog.luau` | Nine products, their benefits, and confirmed Roblox IDs once available |
| `src/server/Main.server.luau` | Gameplay, remotes, achievements, analytics, leaderboards, and MarketplaceService integration |
| `src/server/Profiles.luau` | Session lease, migrations, save retries, and receipt delivery |
| `src/server/Races.luau` | Heats, countdowns, race corridors, checkpoints, finish timing, and standings |
| `src/server/World.luau` | Deterministic world and terrain generator |
| `src/client` | HUD, responsive menus, audio, and nearby companion effects |
| `assets` | Editable Blender scene, GLBs, original audio, catalog icons, and catalog CSV |

A fresh place generated from source builds the districts automatically when you press Play. To materialize the scenery in that file’s Edit mode, run `tools/PrepareStudio.luau` in the Studio Command Bar and save the local copy.

To regenerate the source-built place, run `python tools/build_place.py Dashverse.rbxlx`. To regenerate the WAV masters and product art, run `python tools/make_release_media.py assets`. To regenerate the editable mesh collection and its GLBs, run `blender -b -t 2 --python tools/make_blender_assets.py -- assets/meshes` with Blender 5.3.

## Gameplay and design references

- Sonic Speed Simulator demonstrates an immediately legible run-to-level loop and visible world progression. Dashverse puts its first six sparks in the arrival lane and unlocks the starter companion after three. [Sonic Speed Simulator on Roblox](https://www.roblox.com/games/9049840490/Sonic-Speed-Simulator)
- Pet Simulator 99 combines incremental currency, collection, exploration, and minigames. Dashverse uses deterministic creature goals tied to running, race finishes, and hidden locations. [Pet Simulator 99 on Roblox](https://www.roblox.com/games/8737899170/Pet-Simulator-99)
- Driving Empire combines racing with free-roam exploration and social gathering. Dashverse gives each district a common hub, a separate fixed-speed heat, and the cooperative Spark Rally. [Driving Empire on Roblox](https://www.roblox.com/games/3351674303/Driving-Empire)
- Roblox’s current discovery guidance highlights first-play bounce, play days, playtime, and intentional co-play. The build logs onboarding, race participation, world progression, session length, and purchase events from the server. Retention and payer conversion require post-publication data. [Roblox Discovery FAQ](https://create.roblox.com/docs/discovery-faq), [Creator Analytics](https://create.roblox.com/docs/production/analytics)

## Assets

The Studio build uses original Roblox primitives and Roblox-bundled UI and movement sounds. The asset folder includes eight creature sculpts, four environmental and display props, nine 512 × 512 shop icons, and seven original WAVs. The Blender exports use material colors and no external textures. The per-mesh triangle maximum in the exports is 168. The Blender and WAV files are ready for a separately approved import and moderation pass. [Roblox mesh specifications](https://create.roblox.com/docs/art/modeling/specifications), [Roblox audio assets](https://create.roblox.com/docs/audio/assets)
