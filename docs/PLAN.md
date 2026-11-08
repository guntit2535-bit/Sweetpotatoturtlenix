# Sweetpotatoturtlenix — Plan

Statuses: `[ ]` todo · `[~]` built, waiting for the developer's test · `[x]` done.
One task at a time, in order. Specs: `docs/tasks/phase-1.md` (milestone 2 specs are written before
milestone 2 starts). Scope: `docs/BLUEPRINT.md`. ★ = the developer approves a look before it is built.

**Reuse first.** Every task starts from working code of an earlier game, adapted (not pasted blindly):
- **PSE** = Pet Storm Escape `D:\RobloxGames\PetStormEscape` (closest game: 8 farms, multi-catcher
  capture, delivery home, treadmill, corral income, Mythic event, passes / products, UI kit, EN/TH)
- **BA** = Tamer Academy `D:\beast-academy\beast-academy` (trade, daily login, codes, group reward,
  leaderboards, rewards window, buffs, debug + FreshSave, lighting)
- **HR** = HatchRush `D:\HatchRush` (carry over the head, baseball bat + knockback, pens with signs)
- **SP** = SKY PUTT `guntit2535-bit/sky-putt` (reference clone `D:\Roblox\_ref\sky-putt`: crates,
  rebirth, quests, playtime gifts, leaderboard board, boosts, sound)

## Milestone 1 — the core loop (4,000 THB when the test passes)
- [x] 1.0 Project setup: repo, Rojo 7.7.1 + Lune, ProfileStore, bootstrap loaders, Config / Text skeleton, check script, CLAUDE.md, BLUEPRINT, PLAN
- [ ] 1.1 Project base: Remotes (all created at start, typed, rate limited), Guard / RateLimiter / Validate, client Lang, number Format (K/M/B/T), Settings button + language switch EN/TH (saved in 1.2). Reuse: PSE `shared/Remotes`, `shared/Validate`, `shared/Format`, `server/Util/Guard`, `RateLimiter`, `client/Lang`, `Controllers/SettingsUI`, `SettingsService`
- [ ] 1.2 Saves: ProfileStore `Sweetpotato_PlayerData_v1`, DataTemplate (money, Strength, Speed, levels, cats by unique id, slots, likes, settings, receipts), leaderstats, client data copy, `Workspace.FreshSave` test profile. Reuse: PSE `DataService` + `shared/DataTemplate`, BA `DataService` (FreshSave)
- [ ] 1.3 Debug commands (Studio + admins): money, strength, speed, give cat, spawn event, reset, fresh save. Reuse: PSE `DebugService` + `shared/Commands`, BA `DebugService`
- [ ] 1.4 Developer: Roblox group (client's or ours, pending) + experience, place published, API Services on, max players 8
- [ ] 1.5 Cat data, 400 cats: generator from base shapes x colours x patterns x accessories, 6 tiers with the blueprint counts and weight ranges, weight roll, size rule (Mythical 1.3-2x, Secret 3-6x by weight), income from weight; pure module + spec. Reuse: PSE `tools/gen/species.luau`, `shared/Creatures`, `shared/Income`
- [ ] 1.6 Economy simulation: income per kg by tier, weights / treadmill curves (25 levels), upgrade prices, zone gates (Strength / Rebirth), pen sell price; 2-3 options table, the developer picks. Reuse: PSE `tools/sim/economy.luau`, `speed.luau`, `docs/economy.md`
- [ ] 1.7 ★ Map blockout (boxes) for an early playtest: lobby in the centre (safe zone, 8 pens in a ring), 5 ring zones with gates, 30-60 tagged hiding spots per zone (roof / bush / rock / bridge), streaming decision for phones. Reuse: PSE `server/Util/MapKit`, `WorldBuilder`, SP `tools/lib/WorldKit`
- [ ] 1.8 Pens: one per player on join, spawn at it, freed on leave; 10 slots (max 60), cats wander, money every second straight into the wallet; My Cats window (view, sell, lock). Reuse: PSE `CorralService`, `FarmService`, `Controllers/CorralLife`, `CreaturesUI`, HR `PenService`
- [ ] 1.9 Pen sign + likes: owner name, like count, Like button; liker gets x2 speed 5 min; one like per pen per day (saved). Reuse: PSE `Controllers/FarmSignController`, HR `PenService` (signs), BA `FarmSignController`
- [ ] 1.10 Wild cats: spawn by zone odds at hiding spots, respawn at another spot in 30-90 s, tier / weight label, "need X Strength" message. Reuse: PSE `SpawnService`, `shared/Spawning`, `Controllers/CreatureTagController`
- [ ] 1.11 Rod + bar minigame: cast at a cat in range, hooked cat struggles, hold to move the green zone, meter fills / drains; the server simulates the cat and the bar from the player's hold input (seeded, rate limited) and decides the result; rarer = faster cat + smaller zone; rod tier hook for milestone 2. Reuse: PSE `CaptureService`, `shared/Contest`, `Controllers/ContestUI`, `CaptureController`
- [ ] 1.12 Fighting over a cat: several players fish the same cat, the first full meter wins, the others drop out at once; caught card (name, tier, weight). Reuse: PSE `CaptureService` (multi-catcher, first to 100 wins)
- [ ] 1.13 Carry home: the winner holds the cat over the head with a floating cat icon, walks into the lobby to the own pen, the cat goes in and starts earning. Reuse: HR `GrabService` (carry over the head), PSE `TrainService` / `shared/Escape` (delivery on entering the town)
- [ ] 1.14 Baseball bat: hotbar tool next to the rod, short cooldown, server hit check (range, facing), no hits in the lobby or on players fishing; a hit carrier drops the cat where hit and is knocked far; the dropped cat is fishable by all, 60 s then back to hiding. Reuse: HR `BatService`, `Controllers/BatSwingController`, `KnockbackController`
- [ ] 1.15 Weights, 25 levels: stand at the spot = auto lift, Strength per rep by level, upgrade sign (money), 5 looks (dumbbell > barbell > bench > machine > giant barbell). Reuse: PSE `TreadmillService`, `shared/Treadmill`, `Controllers/TreadmillController`, `TreadmillTierUI`, `StandController`
- [ ] 1.16 Treadmill, 25 levels next to the weights: stand = auto run, Speed, upgrade with money; walk speed from Speed. Reuse: PSE `TreadmillService`, `shared/Speed`, `SpeedTrail`
- [ ] 1.17 ★ HUD (phone first): left Shop / x2 Speed (blink) / My Cats / Trade, right Strength + weights / treadmill levels, bottom-left Speed + money, bottom-centre hotbar (bat + rod), bottom-right event countdown, Settings; UI look options first (GPT style board). Reuse: PSE `client/UI/Style`, `Window`, `Icons`, `Controllers/HudController`, BA `client/Ui/HudLayout`, `Kit`
- [ ] 1.18 Events: Mythical every 10-20 min, Secret every 40 min; server-wide announcement, light beam, arrow, bottom-right countdown, 3 min then it escapes; Secret: bigger announcement, sky colour change, event music hook; caught event cats are carried home like others. Reuse: PSE `MythicEventService`, `GoldenEventService`, `Controllers/ZoneFx`, BA `LightingController`, SP `EventService`
- [ ] 1.19 ★ Map art: style options (renders / GPT) -> lobby, pens, weights / treadmill area and the 5 themed zones in the approved style (checkered grass, Japanese-garden style gates, blossoms, bamboo, waterfalls ...), colliders as boxes. Reuse: PSE `MapKit` + `art/world2_export.py` (box colliders), skill `art-pipeline`
- [ ] 1.20 ★ Cat look prototype: 2-3 base shapes x colour / pattern / accessory as Blender renders, one per tier, Mythical / Secret size; the approved style is used for all 400 in milestone 2. Reuse: PSE `CreatureModels`, art kit
- [ ] 1.21 Milestone 1 check: 2+ players and a phone test, fixes, play video + test notes for the client

## Milestone 2 — everything else (4,000 THB at full delivery)
- [ ] 2.1 Shop window (in-game money), tabs Rods / Shoes / Pen / Treats / Crates. Reuse: SP `ShopService` + `UI/ShopPanel`, PSE `UpgradeService` + `UpgradesUI`
- [ ] 2.2 Rods, 25 tiers (Wood / Iron / Gold / Crystal / Cosmic x 5): zone width, meter speed, luck, a look per tier. Reuse: SP `Items`, `ItemModels`, `ClubVisualService`
- [ ] 2.3 Shoes, 8 pairs (CLIENT PENDING: keep or drop). Reuse: SP `Items`
- [ ] 2.4 Pen expansion with money (10 -> 60). Reuse: PSE `UpgradeService` (corral expansion)
- [ ] 2.5 Cat treats, 10 min: Lucky Treat (luck x1.5), Golden Fish (money x2), Catnip (easier minigame). Reuse: BA `shared/Buffs`, SP `shared/Boosts`
- [ ] 2.6 Crates x4 (money): odds before buying, opening animation, no Secret, cat into the pen (saved before shown). Reuse: SP `CrateService`, `shared/Crates`, PSE `MysteryRevealUI`, BA `shared/Gacha`
- [ ] 2.7 Rebirth x25: resets money / Strength / Speed / weights / treadmill, x1.5 money + x1.5 Strength permanent, opens zones; cats and items stay. Reuse: SP `RebirthService`, `shared/RebirthRules`
- [ ] 2.8 Collection book, 400 cats, silhouettes, full-set bonus. Reuse: PSE `BookService`, `shared/Collection`, `Controllers/BookUI`, `UI/Portrait`
- [ ] 2.9 Mutations Gold / Rainbow / Glow, money x2-x10, Basic-Legendary only. Reuse: PSE `shared/Mutation`, `MutationFx`, `RainbowFx`
- [ ] 2.10 Offline income, max 8 hours, welcome-back window. Reuse: PSE `OfflineService`, `shared/Offline`, `WelcomeBackUI`
- [ ] 2.11 Daily login, 7-day cycle, day 7 big reward. Reuse: BA `LoginService`, `shared/Login`, `RewardsService`
- [ ] 2.12 Daily quests. Reuse: SP `QuestService`, `shared/Quests`, BA `QuestBoardService`
- [ ] 2.13 Playtime gifts. Reuse: SP `PlaytimeService`, `shared/Playtime`, BA `RewardsService`
- [ ] 2.14 Leaderboards: money per second + cat count (OrderedDataStore + lobby boards). Reuse: SP `LeaderboardService` + `tools/lib/BuildLeaderboard`, BA `LeaderboardService`
- [ ] 2.15 Gift codes. Reuse: BA `CodeService`
- [ ] 2.16 Group reward (needs Config.GroupId). Reuse: BA `GroupChestService`
- [ ] 2.17 Trading: request / accept, up to 6 cats each, Ready + 5 s countdown (any change resets), confirm, server re-checks ownership + pen room + locks, one-step swap, both saves, trade log, leave = cancel, duplicate-proof. Reuse: BA `TradeService`, `shared/Trade`, `TradeController` (minus capsules)
- [ ] 2.18 Game passes x5 (x2 Speed button: blink, then on/off toggle; x2 Cash, x2 Strength, Lucky, VIP tag + 10%). Reuse: PSE `PassService`, `shared/Passes`, `VipTagController`, SP `GamePassService`
- [ ] 2.19 Developer products x7 (+20 slots in price steps, 4 cash packs by income, strength pack, luck x3 15 min, server luck 15 min + announcement, summon Mythical, starter pack once) + the one ProcessReceipt. Reuse: PSE `ProductService`, `shared/Products`, SP `DevProductService`
- [ ] 2.20 Robux store window + card images (GPT prompts). Reuse: PSE `Controllers/StoreUI`, BA `LivePrices`, `StoreController`
- [ ] 2.21 All 400 cat models in the approved style (+ Mythical / Secret effects). Reuse: PSE `CreatureModels`, art pipeline
- [ ] 2.22 Animations: cats (idle, walk, struggle, carried), players (cast, reel, lift, run, swing, carry). Reuse: BA `client/CharacterAnims`, `CreatureAnimator`, SP `art/animations`
- [ ] 2.23 Sound: sound module + sound list xlsx for the developer to pick ids (event music included). Reuse: SP `client/Sound`, `SoundController`, PSE `tools/gen/sounds_xlsx.luau`
- [ ] 2.24 Game icon 512 + 3-5 thumbnails 1920x1080 (GPT prompts) + store description EN / TH
- [ ] 2.25 Full-server test (8 players incl. phones), `docs/LAUNCH_CHECKLIST.md`, client delivery page, Debug off, `.rbxl` backup

## Plan changes
- none yet

## Decisions to review
- 1.0: streaming is left to the map task (1.7): the 360 map may be big for phones (Tamer Academy lesson).
- 1.0: the map is a box blockout first (1.7) and the art pass comes after the core loop plays well
  (Pet Storm Escape lesson: "เกมเฉย ๆ" found only at the first playtest).

## Log
- 2026-11-08: 1.0 project set up at `D:\Roblox\Sweetpotatoturtlenix` (Rojo 7.7.1, Lune 0.10.4,
  ProfileStore from Pet Storm Escape), CLAUDE.md, BLUEPRINT (English copy of the approved blueprint),
  PLAN with the reuse map. `lune run scripts/check.luau` and `rojo build` pass.
