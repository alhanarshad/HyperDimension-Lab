# Release and QA handoff


The cloud draft contains six districts and 234 pickups. Free progression includes Speed, Training, Dash, eight companions, six hidden caches, quests, time-based course mastery, world travel, and prestige. The race lobby supports solo heats, same-server multiplayer, Roblox friend duels, and Spark Rally. The premium displays open an item preview only after deliberate interaction.

## Studio verification

| Check | Result |
| --- | --- |
| Startup and first upgrade | Ran from spawn, collected sparks, unlocked and rendered Spark Fox, and bought two Speed upgrades. WalkSpeed advanced from 17 to 23. |
| Standalone place | Opened the local place in Roblox Studio. Verified pickup collection, 19.10s River Circuit completion, and a 135-Coin mastery reward. A repeat claim granted zero Coins. |
| Free world progression | Finished all six courses in one Studio session using normal travel, pickups, and upgrade commands. Recorded 19.14s, 20.68s, 18.37s, 19.08s, 20.85s, and 21.12s in course order. Movement was driven by Humanoid waypoints at gameplay speed. |
| Two-player heat | Both local clients saw the same standings in the final standalone build. First and second finished in 19.123s and 25.933s. The winner received one multiplayer win and 112 Coins. The runner-up received 82 Coins. |
| Co-op | Two local clients contributed to a Spark Rally. The server delivered the 145-Coin completion reward. |
| Input checks | Early travel to Cosmic Rift, equipping a locked creature, requesting a missing product, and claiming an unearned achievement left the player’s balance and unlocks unchanged. A race checkpoint skip ended the race without a reward. |
| Receipt logic | The Studio in-memory adapter granted 300 Coins once per unique synthetic receipt. Duplicate delivery before and after a profile reopen granted zero extra Coins. A second session was refused while the first held its lease. |
| Mobile layout | Inspected iPhone 17 Pro landscape and portrait and iPad Pro M5 13-inch landscape using Studio Device Simulator. Rechecked that revised portrait navigation and tablet Dash controls cleared the jump button. Studio’s default viewport was restored. |
| Desktop performance | Green Valley opening loop produced 303 render frames in 5.06 seconds, about 59.8 FPS. Median frame interval was 16.70 ms and p95 was 17.81 ms. The client had 1,018 streamed map descendants. This was one Studio desktop sample. |
| Audio fallback | All six Roblox-bundled effect sound objects loaded on the client. The original ambience master awaits audio import. |

Cloud DataStore rejoin, ordered global records, MarketplaceService purchase prompts with real IDs, Roblox pass ownership, live analytics, friend-only invitations with real accounts, and performance on physical phones still need end-to-end tests. Studio uses a disposable in-memory adapter by default.

## Catalog approval

`assets/catalog.csv` contains the exact descriptions and artwork paths. The current account has an empty game-pass and developer-product catalog. Read-only scope probes for both Open Cloud write scopes succeeded. The creation requests require multipart form data, which Roblox Studio’s authenticated Open Cloud integration supports.

| Target Robux | Item | Type |
| ---: | --- | --- |
| 1 | Mini Spark Effect | Pass |
| 9 | Colorful Speed Trail | Pass |
| 24 | Small Coin Pack | Developer product |
| 59 | Neon Runner Shoes | Pass |
| 150 | Starter Cosmetic Bundle | Pass |
| 299 | Permanent 2× Speed Energy | Pass |
| 499 | Permanent 3× Coin Earnings | Pass |
| 1,999 | Permanent 4× Training Energy | Pass |
| 3,999 | Cosmic Founder’s Bundle | Pass |

Roblox’s current developer-product guide lists 1 Robux as the minimum. Roblox staff has also confirmed that a pass can be set to 1 Robux. Verify accepted prices during the approved creation step. The UI retrieves the player’s Roblox price dynamically. [Developer products](https://create.roblox.com/docs/production/monetization/developer-products), [Roblox staff clarification on pass pricing](https://devforum.roblox.com/t/game-passes-for-one-robux/3818145/9), [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)

After approval, re-list both product types to avoid duplicates. Create the eight passes and one developer product **off sale** with their prepared icons. Read back the official IDs, store them in `src/shared/Catalog.luau`, and verify the product details through the same private universe. Keep the coin pack’s external store listing off during testing. If an icon path is rejected, approve the exact local icon folder in Studio **Assistant Settings → MCP Permissions**. [Passes API](https://create.roblox.com/docs/cloud/reference/features/game-passes), [Developer products API](https://create.roblox.com/docs/cloud/reference/features/developer-products)

## Release checklist

1. For a live-service smoke test, approve publishing a private test build and use the Roblox app with authorized test accounts. Check rejoin, concurrent-session recovery, and ordered records. A Studio DataStore test should use a separate test experience, its own store names, and **Enable Studio Access to API Services** there. [Data stores](https://create.roblox.com/docs/cloud-services/data-stores)
2. Verify the nine catalog entries and confirmed IDs. Use supported Studio mock prompts with a test configuration and an in-memory profile to exercise receipt delivery. Verify permanent pass ownership with authorized test accounts before enabling sales. Test a duplicate receipt, retry after transient failure, cancellation, off-sale behavior, and regional display. [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService)
3. Review and approve the Blender and audio asset import. Add confirmed audio asset IDs in `Config.Audio` and ensure the experience has access. Recheck scale, collision, and appearance before substituting any runtime mesh. [Roblox 3D importer](https://create.roblox.com/docs/art/modeling/3d-importer), [Roblox audio assets](https://create.roblox.com/docs/audio/assets)
4. In the Roblox app, test a friend duel with two real test accounts, verify the default controls and labels on a physical phone, and inspect the Creator Dashboard for onboarding, retention, and race analytics. [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes), [Creator Analytics](https://create.roblox.com/docs/production/analytics)
5. Review experience title, description, icon, content ratings, and target audience. Roblox applies different requirements for 16+ and all-ages releases, including account verification and additional all-ages criteria. Confirm eligibility and obtain explicit approval before publishing or enabling live sales. [Create and publish games](https://create.roblox.com/docs/production/publishing/publish-games-and-places)
