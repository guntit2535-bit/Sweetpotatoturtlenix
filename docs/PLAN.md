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
- [x] 1.4 Developer: Roblox group **Sweetpotatoturtlenix** (565190385, made by the team) + experience (GameId 10775309921, place 85516549821714) in Team Create. Still to check: API Services on, max players 8

### Map and models first (developer 2026-11-08, "1A 2A 3B 4A")
- [x] A1 ★ Art direction with GPT: prompt file `docs/gpt_map_prompts.md`; the developer makes 2 lobby style options (A / B), picks one, then the 5 zones in the same chat; pictures in `art/source/gpt_map/`
- [x] A2 ★ Map layout plan (top-down, sizes in studs): lobby safe circle, ring of 8 pens, training spot per pen, the 5 ring widths, zone gates, hiding-spot kinds and counts per zone, walk times at start speed, streaming decision for phones; numbers in `Config.World` (developer 2026-11-08: build it straight in Studio, no page)
- [x] A3 Lobby in the approved look (built from Studio parts by `src/server/MapTools`, see Plan changes): plaza, 8 pens + signs, weights (5 looks: dumbbell > barbell > bench > machine > giant barbell) + treadmill per pen, safe-zone edge; renders first, then export with box colliders, the developer imports under the group, a builder places it. Reuse: PSE `server/Util/MapKit`, `art/world2_export.py`, art kit
- [x] A4 Backyard zone as the template: renders first, export + import, 30-60 tagged hiding spots (roof / bush / rock / bridge), zone gate. Reuse: PSE `MapKit`, SP `tools/lib/WorldKit`
- [x] A5 The other 4 zones in the approved Backyard standard, one batch: Town Market, Forest, Snow Mountain, Sky Islands (each its own theme, 30-60 hiding spots, gates)
- [x] A6 ★ Cat look prototype: 3 base shapes (Loaf, Slim, Fluffy) x colour / pattern / accessory built from Studio parts (`src/shared/CatModel`), preview `Workspace.CatPreview`, one cat per tier, Mythical / Secret sizes; the approved style is used for all 400 in milestone 2 (2.21). Reuse: PSE `CreatureModels`, art kit
- [x] A7 Cat rig + animations (developer 2026-11-08, pulled forward from 2.22 for cats only): Motor6D bones in `CatModel` (Body, Head, Tail1-2, 4 legs, wings), clips idle / walk / struggle / carried / sleep + "showcase" (all in turn) as maths in `shared/CatAnims`, played on the clients by `CatAnimController` (no animation uploads). Player animations stay in 2.22

### Code
- [x] 1.1 Project base: Remotes (all created at start, typed, rate limited), Guard / RateLimiter / Validate, client Lang, number Format (K/M/B/T), Settings button + language switch EN/TH (saved in 1.2). Reuse: PSE `shared/Remotes`, `shared/Validate`, `shared/Format`, `server/Util/Guard`, `RateLimiter`, `client/Lang`, `Controllers/SettingsUI`, `SettingsService`
- [x] 1.2 Saves: ProfileStore `Sweetpotato_PlayerData_v1`, DataTemplate (money, Strength, Speed, levels, cats by unique id, slots, likes, settings, receipts), leaderstats, client data copy, `Workspace.FreshSave` test profile. Reuse: PSE `DataService` + `shared/DataTemplate`, BA `DataService` (FreshSave)
- [x] 1.3 Debug commands (Studio + admins): money, strength, speed, give cat, spawn event, reset, fresh save. Reuse: PSE `DebugService` + `shared/Commands`, BA `DebugService`
- [x] 1.5 Cat data, 400 cats: generator from base shapes x colours x patterns x accessories, 6 tiers with the blueprint counts and weight ranges, weight roll, size rule (Mythical 1.3-2x, Secret 3-6x by weight), income from weight; pure module + spec. Reuse: PSE `tools/gen/species.luau`, `shared/Creatures`, `shared/Income`
- [x] 1.6 Economy simulation: income per kg by tier, weights / treadmill curves (25 levels), upgrade prices, zone gates (Strength / Rebirth), pen sell price; 2-3 options table, the developer picks. Reuse: PSE `tools/sim/economy.luau`, `speed.luau`, `docs/economy.md`
- [x] 1.8 Pens: one per player on join, spawn at it, freed on leave; 10 slots (max 60), cats wander, money every second straight into the wallet; My Cats window (view, sell, lock). Reuse: PSE `CorralService`, `FarmService`, `Controllers/CorralLife`, `CreaturesUI`, HR `PenService`
- [x] 1.9 Pen sign + likes: owner name, like count, Like button; liker gets x2 speed 5 min; one like per pen per day (saved). Reuse: PSE `Controllers/FarmSignController`, HR `PenService` (signs), BA `FarmSignController`
- [x] 1.10 Wild cats: spawn by zone odds at the hiding spots tagged in A4 / A5, respawn at another spot in 30-90 s, tier / weight label, "need X Strength" message. Reuse: PSE `SpawnService`, `shared/Spawning`, `Controllers/CreatureTagController`
- [x] 1.11 Rod + bar minigame: cast at a cat in range, hooked cat struggles, hold to move the green zone, meter fills / drains; the server simulates the cat and the bar from the player's hold input (seeded, rate limited) and decides the result; rarer = faster cat + smaller zone; rod tier hook for milestone 2; the Wood rod model (Blender) is made in this task. Reuse: PSE `CaptureService`, `shared/Contest`, `Controllers/ContestUI`, `CaptureController`
- [x] 1.12 Fighting over a cat: several players fish the same cat, the first full meter wins, the others drop out at once; caught card (name, tier, weight). Reuse: PSE `CaptureService` (multi-catcher, first to 100 wins)
- [x] 1.13 Carry home: the winner holds the cat over the head with a floating cat icon, walks into the lobby to the own pen, the cat goes in and starts earning. Reuse: HR `GrabService` (carry over the head), PSE `TrainService` / `shared/Escape` (delivery on entering the town)
- [x] 1.14 Baseball bat: hotbar tool next to the rod, short cooldown, server hit check (range, facing), no hits in the lobby or on players fishing; a hit carrier drops the cat where hit and is knocked far; the dropped cat is fishable by all, 60 s then back to hiding; the bat model (Blender) is made in this task. Reuse: HR `BatService`, `Controllers/BatSwingController`, `KnockbackController`
- [x] 1.15 Weights, 25 levels: stand at the spot = auto lift, Strength per rep by level, upgrade sign (money), 5 looks (dumbbell > barbell > bench > machine > giant barbell). Reuse: PSE `TreadmillService`, `shared/Treadmill`, `Controllers/TreadmillController`, `TreadmillTierUI`, `StandController`
- [x] 1.16 Treadmill, 25 levels next to the weights: stand = auto run, Speed, upgrade with money; walk speed from Speed. Reuse: PSE `TreadmillService`, `shared/Speed`, `SpeedTrail`
- [x] 1.17 ★ HUD (phone first): left Shop / x2 Speed (blink) / My Cats / Trade, right Strength + weights / treadmill levels, bottom-left Speed + money, bottom-centre hotbar (bat + rod), bottom-right event countdown, Settings; UI look options first (GPT style board). Reuse: PSE `client/UI/Style`, `Window`, `Icons`, `Controllers/HudController`, BA `client/Ui/HudLayout`, `Kit`
- [x] 1.18 Events: Mythical every 10-20 min, Secret every 40 min; server-wide announcement, light beam, arrow, bottom-right countdown, 3 min then it escapes; Secret: bigger announcement, sky colour change, event music hook; caught event cats are carried home like others. Reuse: PSE `MythicEventService`, `GoldenEventService`, `Controllers/ZoneFx`, BA `LightingController`, SP `EventService`
- [x] 1.21 Milestone 1 check: 2+ players and a phone test, fixes, play video + test notes for the client

## Milestone 2 — everything else (4,000 THB at full delivery)
- [x] 2.1 Shop window (in-game money), tabs Rods / Shoes / Pen / Treats / Crates. Reuse: SP `ShopService` + `UI/ShopPanel`, PSE `UpgradeService` + `UpgradesUI`
- [x] 2.2 Rods, 25 tiers (Wood / Iron / Gold / Crystal / Cosmic x 5): zone width, meter speed, luck, a look per tier. Reuse: SP `Items`, `ItemModels`, `ClubVisualService`
- [x] 2.3 Shoes, 8 pairs (CLIENT PENDING: keep or drop). Reuse: SP `Items`
- [x] 2.4 Pen expansion with money (10 -> 60). Reuse: PSE `UpgradeService` (corral expansion)
- [x] 2.5 Cat treats, 10 min: Lucky Treat (luck x1.5), Golden Fish (money x2), Catnip (easier minigame). Reuse: BA `shared/Buffs`, SP `shared/Boosts`
- [x] 2.6 Crates x4 (money): odds before buying, opening animation, no Secret, cat into the pen (saved before shown). Reuse: SP `CrateService`, `shared/Crates`, PSE `MysteryRevealUI`, BA `shared/Gacha`
- [x] 2.7 Rebirth x25: resets money / Strength / Speed / weights / treadmill, x1.5 money + x1.5 Strength permanent, opens zones; cats and items stay. Reuse: SP `RebirthService`, `shared/RebirthRules`
- [x] 2.8 Collection book, 400 cats, silhouettes, full-set bonus. Reuse: PSE `BookService`, `shared/Collection`, `Controllers/BookUI`, `UI/Portrait`
- [x] 2.9 Mutations Gold / Rainbow / Glow, money x2-x10, Basic-Legendary only. Reuse: PSE `shared/Mutation`, `MutationFx`, `RainbowFx`
- [x] 2.10 Offline income, max 8 hours, welcome-back window. Reuse: PSE `OfflineService`, `shared/Offline`, `WelcomeBackUI`
- [x] 2.11 Daily login, 7-day cycle, day 7 big reward. Reuse: BA `LoginService`, `shared/Login`, `RewardsService`
- [x] 2.12 Daily quests. Reuse: SP `QuestService`, `shared/Quests`, BA `QuestBoardService`
- [x] 2.13 Playtime gifts. Reuse: SP `PlaytimeService`, `shared/Playtime`, BA `RewardsService`
- [x] 2.14 Leaderboards: money per second + cat count (OrderedDataStore + lobby boards). Reuse: SP `LeaderboardService` + `tools/lib/BuildLeaderboard`, BA `LeaderboardService`
- [x] 2.15 Gift codes. Reuse: BA `CodeService`
- [x] 2.16 Group reward (needs Config.GroupId). Reuse: BA `GroupChestService`
- [x] 2.17 Trading: request / accept, up to 6 cats each, Ready + 5 s countdown (any change resets), confirm, server re-checks ownership + pen room + locks, one-step swap, both saves, trade log, leave = cancel, duplicate-proof. Reuse: BA `TradeService`, `shared/Trade`, `TradeController` (minus capsules)
- [x] 2.18 Game passes x5 (x2 Speed button: blink, then on/off toggle; x2 Cash, x2 Strength, Lucky, VIP tag + 10%). Reuse: PSE `PassService`, `shared/Passes`, `VipTagController`, SP `GamePassService`
- [x] 2.19 Developer products x7 (+20 slots in price steps, 4 cash packs by income, strength pack, luck x3 15 min, server luck 15 min + announcement, summon Mythical, starter pack once) + the one ProcessReceipt. Reuse: PSE `ProductService`, `shared/Products`, SP `DevProductService`
- [x] 2.20 Robux store window + card images (GPT prompts). Reuse: PSE `Controllers/StoreUI`, BA `LivePrices`, `StoreController`
- [x] 2.21 All 400 cat models in the approved style (+ Mythical / Secret effects). Reuse: PSE `CreatureModels`, art pipeline
- [x] 2.22 Animations: cats (idle, walk, struggle, carried), players (cast, reel, lift, run, swing, carry). Reuse: BA `client/CharacterAnims`, `CreatureAnimator`, SP `art/animations`
- [x] 2.23 Sound: sound module + sound list xlsx for the developer to pick ids (event music included). Reuse: SP `client/Sound`, `SoundController`, PSE `tools/gen/sounds_xlsx.luau`
- [x] 2.24 Game icon 512 + 3-5 thumbnails 1920x1080 (GPT prompts) + store description EN / TH
- [~] 2.25 Full-server test (8 players incl. phones), `docs/LAUNCH_CHECKLIST.md`, client delivery page, Debug off, `.rbxl` backup

## Phase 3 — revision round 1 (developer, 2026-11-08; spec `docs/tasks/phase-3.md`)
- [x] R1 Bushes you can walk through: all 322 map bushes collide (cats do not); bushes CanCollide off in MapKit + patch the place
- [x] R2 Training locks the player on the exact spot, only a jump ends it (StopTraining remote), no instant re-lock
- [x] R3 Money popups every second over your own pen's cats (server `Rate` attribute per cat) + HUD "+$total"
- [x] R4 Bigger numbers, top ~99 Sx (money / Strength / Speed, cat weights scaled): sim + options table, log-scale leaderboard, save migration
- [x] R5 ★ Blender pipeline: GPT reference prompts for every item, pilot sheet, all families, FBX + manifest, the developer imports; Blender-made R15 animations (preview GIF, the developer publishes under the group)
- [x] R6 ★ Weights: two-hand curl animation with a dumbbell in each hand, 25 looks (5 families x 5 steps, bigger every level)
- [x] R7 ★ Treadmill: 25 looks (5 families x 5 steps, +2 % size per level)
- [x] R8 ★ Crate opening 5 s: drop, shake with tier glow, lid pops, cat jumps out, card; tap to skip
- [x] R9 ★ New UI from GPT designs: style board, one mockup per screen, rebuilt in code (EN / TH, phone first)

## Phase 4 — revision round 2, the last free round (developer, 2026-11-09; spec `docs/tasks/phase-4.md`)
- [~] V1 ★ Cat style board in Blender: one original voxel cat in 3 options (Pixel / Brick / Mix), then the pick on 4 base shapes; the developer and the client approve
- [~] V2 Fishing pose matching the rod: right hand at the grip, left hand turning the reel handle on the rod
- [x] V3 Map detail pass (ground details approved 2026-11-09): survey every area, then a real fountain, winding rivers with banks, layered waterfalls, more ground detail per zone
- [~] V4 New-player tutorial (NOT in the blueprint: the developer decides the price with the client): 7 guided steps, arrows, skip / replay, saved
- [~] V5 ★ All 400 cats as approved: block cats with LEGO studs, 50 unique designs per tier (docs/Sweetpotato_Cats.xlsx), bones + walk / idle animation, a unique effect round every Mythical / Secret cat
  - [x] V5a design table (300) + one Blender cat per tier + bones / walk preview (art/preview/cats_v1/walk.gif)
  - [x] V5b-g the other 294 in Blender, one tier at a time, a sheet per tier for approval (Basic, Rare, Epic, Legendary, Mythical, Secret)
    - [x] V5b Basic: all 50 built (`art/preview/cats_v1/tier_basic.png`), approved 2026-11-09
    - [x] V5c Rare: all 50 (`tier_rare.png`), self-checked (developer: "build every tier, check them yourself"), approved 2026-11-09
    - [x] V5d Epic: all 50 costumes (`tier_epic.png`), self-checked, approved 2026-11-09
    - [x] V5e Legendary: all 50 food / animal cats (`tier_legendary.png`), self-checked, approved 2026-11-09
    - [x] V5f Mythical: all 50 creatures with their effects (`tier_mythical.png`), self-checked, approved 2026-11-09
    - [x] V5g Secret: all 50 gods / cosmic cats with their effects (`tier_secret.png`), self-checked, approved 2026-11-09
  - [x] V5h into the game (approved 2026-11-09): `art/blender/cats_export.py` writes every design as blocks per bone to `src/shared/CatShapeData/<Tier>` (+ `CatDesigns` names); `shared/CatShapes` decodes them; CatModel builds one Part per block on the same rig (Body, Head, Tail1/2, legs, wings, + Fx that spins round Mythical / Secret cats) so CatAnims moves it; studs = Roblox's Studs surface on Plastic (no extra parts, no upload; a finer MaterialVariant option is ready: `art/export/CatStuds_Normal.png`); Mythical / Secret sparkles + light in their effect's colours; Cats data: 400 cats (100/80/70/50/50/50) = 300 designs + 100 colour variants (Basic 50, Rare 30, Epic 20)
  - [~] V5i Studio checks: full pens (480 cats) made fast enough (anchored blocks, posing budget), carried cats animate, My Cats / book cards checked; a real phone test with `!fillpens` is the developer's

  - [x] V5j effects remade as smooth Blender shapes with an aura (developer 2026-11-09: "the effects look like plain
    geometry"): `art/blender/fxshapes.py`; picked: Mythical = A (items orbit the cat, soft ground glow), Secret = B
    (magic circle, ribbons of light shoot up from the ground and fade every 3 s). All 100 built: `tier_mythical.png`,
    `tier_secret.png`, motion in `fx_anim.gif`, approved 2026-11-09. In the game: mesh library `art/export/Effects.fbx`
    (78 meshes, developer imports into ReplicatedStorage.FxMeshes), pieces per cat in CatShapeData `fx`, CatModel builds
    them (Fx spins, FxStill on the ground), CatFxController plays the Secret burst with Trails; meshes not imported yet

## Phase 5 — revision list 3, free (developer, 2026-11-13; table `docs/revision3_plan.md`)
Developer's answers: everything free (no extra charge), training boosts = permanent steps. Order: bugs, quick UI,
shop / pen, economy, world.
- [x] W1 Bugs (passed 2026-11-13): phone fishing bar (8) and bat fling (7) fixed + checked in Studio; event arrow (1) look A in the game (EventArrow.fbx, the developer imports); holes in the ground (18) filled (100 tiles, BuildMap.groundGaps)
- [x] W2 Phone fit (12): passed 2026-11-13
- [x] W3 Quick UI (passed 2026-11-13, multi-sell (21) done here too): Settings gear without frame (19), sell without asking (20), red line instead of the cat icon (16), icon bar 70% (11), Rebirth + Rewards middle left (13), big Money / Speed / Strength bottom left (10), green ring at the training spots (6)
- [x] W4 ★ (passed 2026-11-13: card shop A, pen board, tool icons) Shop as big swipe cards (4), pen slots on a board at each pen, Pen tab removed (5), multi-select sell (21), Rod / Bat icons (3)
- [x] W5 Economy to ~50 h + crate prices (9, 14): option B, passed 2026-11-13 (sim 53 h)
- [x] W6 Training boost ladder (17): passed 2026-11-13 (product ids in)
- [x] W7 ★ (passed 2026-11-13) Event arrow as a Blender mesh (1, done in W1), bigger pens (15: option B), pixel + LEGO ground, paths and trees (2, done 2026-11-13: MapTools/Lego)

## Plan changes
- 2026-11-13 (developer, 21-point list after the 2 free rounds): phase 5, done free. Changes to the blueprint the
  client should be told: economy paced to ~50 h with dearer crates, the Pen tab moves to the pen, a training
  boost ladder of developer products (new Robux items, prices from the client), bigger pens.
- 2026-11-08 (developer, 10-point revision list, "เริ่มทำplan แก้ไขทั้งหมดนี้"): phase 3 above. Models and
  animations now go through Blender with the developer's check before Studio (point 8), item models are
  remade from GPT reference pictures (point 10), the UI is redesigned from GPT mockups (point 6). Numbers grow
  to ~99 Sx (point 9): the blueprint's weight table and prices change, the client should be told.
- 2026-11-08 (developer: the client threatens to cancel for slowness; "สร้างจริงบน roblox studio ได้เลย"): the map is
  built **now, straight in Studio** from anchored Parts by `src/server/MapTools` (MapKit props + BuildMap layout) in
  the A1 look, instead of Blender kits with renders first. No client summary page. Blender meshes can replace props
  later if the look needs it.
- 2026-11-08 (developer, "1A 2A 3B 4A"): **map and models first**, code after. The box blockout (old
  1.7) is dropped; the top-down layout plan A2 is approved before modelling instead. Old 1.19 (map art)
  and 1.20 (cat prototype) became A1-A6. The developer's Roblox setup (1.4) moves up: the first import
  (A3) needs the group. The bat and the Wood rod models are made with their code tasks (1.14, 1.11).
  All 400 cat models stay in milestone 2 (2.21). Order only: the client's scope is unchanged.

## Decisions to review
- W3 (2026-11-13): the left buttons became a 2-wide grid (Shop | x2 Speed, My Cats | Trade, Rebirth | Rewards) at
  70% size, so Rebirth and Rewards sit middle left without a taller column; the right-hand Strength panel is gone
  (Strength now big at the bottom left with Speed and money; the weights / treadmill levels stay on their Upgrade
  prompts at the pen); the Settings gear is the drawn white gear (the uploaded Settings icon is a cat face, not a
  gear); Lock works on one chosen cat, Sell on every chosen unlocked cat (one SellCat call, max 120); the training
  rings show only at your own pen and hide on the spot you are training on. To fix in W2: on a fresh save the
  tutorial card overlaps the fishing bar.
- V5i (2026-11-09): cats on the ground are anchored blocks with no joints (480 jointed cats cost ~40 ms of physics
  a frame); the client moves the blocks itself, nearest cats first within a block budget (PC 900, phone 400 a
  frame); cats farther than 100 studs from the camera hold still and do not start walks; a carried cat becomes a
  jointed rig again. Studio PC with 480 cats in 8 full pens: 12 fps before, 38-42 fps after (54 with none).
- R8 (2026-11-09): the opening was built in the game from the approved mockup 12 instead of a Blender preview
  video first (the look was already approved with the UI; the real crate meshes and cat models are used), and
  shown as in-game pictures. The crate sounds moved from SoundController into the opening's own timeline so a
  skip stays in step. Every cat is fitted to the same size in the scene (Mythical / Secret giants included).
- R6 (2026-11-08): the curl is a code pose (shared/PlayerPoses "curl", shoulders + elbows each frame, like the
  carry / reel poses) instead of an uploaded Blender animation: nothing to publish, every avatar works, and it
  plays only near the camera. R6-rig avatars (no elbows) keep Roblox's cheer. The dumbbells grow like the rack
  (WeightsGrowth 0.5: level 25 = 1.56x level 1).
- R5 (2026-11-08): the left foot wears the same (right) shoe mesh (Roblox cannot mirror a MeshPart; the shoes are
  nearly symmetric); the rack's own growth is softened at the pens (Config.ItemModels.WeightsGrowth 0.5: level 25
  is 1.56x level 1 instead of 2.44x, so it fits the pen corner); with the meshes the rod is held leaning up and
  forward (RodGrip 15) and the bat upright (BatGrip -20) instead of the old backward angles; the R15 animations
  of R5 (curl) are done with R6. R7's 25 treadmill looks and the Stand moving onto the bigger belt are in now.
- 2.10-2.15 (2026-11-08): offline income at 50% of the normal rate (blueprint gives only the 8-hour cap); gift
  codes live in Config.Codes (add one and publish) instead of an admin panel; the Rewards button sits under
  Rebirth on the right (the left column keeps the 4 buttons of blueprint §16).
- 2.2 (2026-11-08): "luck" (rods, Lucky pass, Lucky Treat, luck x3, server luck) raises the mutation chance of
  caught and crate cats (2.9); wild cats are shared by the server, so server luck also tilts the zone tier odds.
- 1.17 (2026-11-08): the HUD uses the chunky bright button kit already in the game (no separate GPT UI board);
  the hotbar is Roblox's own backpack bar; tools are named "Bat" / "Rod" in English (the server finds them by name).
- 1.18 (2026-11-08): an event cat that breaks free from a rod hides at a new random spot and the event goes on
  (normal cats: back to a new hiding spot too); the 3-minute escape clock waits while someone is fishing it.
- 1.5 (2026-11-08): cat names are English in both languages (like zone names); Mythical / Secret cats come only
  from events (and the Diamond crate in milestone 2), never from normal zone spawns.
- 1.6 (2026-11-08): economy option B "normal" (docs/economy.md); the like buff doubles the walk-speed bonus above
  the base 16 (blueprint: "x2 speed"), capped by Config.Walk.Max.
- A2-A5 (2026-11-08): rings 180 studs wide (lobby 150, edge 1050; ~65 s to the edge at walk speed 16), 8 roads
  with a gate on every zone wall, 24-stud checker tiles, Town Market paved; StreamingEnabled on with
  StreamingTargetRadius 600 / MinRadius 160 (the map is ~35,000 parts); gate barriers are see-through and
  not solid until the gate code exists.
- 1.0: streaming is decided in A2 (the 360 map may be big for phones, Tamer Academy lesson).
- A2: with no box blockout the core loop is first played on the real map; the layout plan (sizes,
  walk times) is the guard against a "เกมเฉย ๆ" redesign (Pet Storm Escape lesson).

## Log
- 2026-11-08: 1.0 project set up at `D:\Roblox\Sweetpotatoturtlenix` (Rojo 7.7.1, Lune 0.10.4,
  ProfileStore from Pet Storm Escape), CLAUDE.md, BLUEPRINT (English copy of the approved blueprint),
  PLAN with the reuse map. `lune run scripts/check.luau` and `rojo build` pass.
- 2026-11-08: plan reordered (developer "1A 2A 3B 4A"): map and models first (A1-A6), code after.
- 2026-11-08: A1 `docs/gpt_map_prompts.md` written (2 lobby styles A / B, then 5 zones in the picked
  style); waiting for the developer's GPT pictures in `art/source/gpt_map/`.
- 2026-11-08: A1 pictures received (L_A lobby + Z1-Z5, style A), saved in `art/source/gpt_map/`,
  notes in `docs/art_direction.md`; waiting for the developer's answers on the open points.
- 2026-11-08: A2-A5 built in Studio (Team Create) with `BuildMap.all()`: lobby (plaza, fountain, 8 pens with cat
  house, gate sign, treadmill, dumbbell rack, glowing safe edge), checker ground, 8 roads, 3 zone walls + snow cliff
  with 32 gates, Backyard / Town Market / Forest / Snow Mountain clusters, Sky Islands (56 + 28 islands, rope bridges,
  clouds, 2 rainbows), lighting; 300 hiding spots (55-60 per zone). Checked by Studio captures of every zone; not yet
  walked in Play or on a phone.
- 2026-11-08: A2-A5 passed ("ผ่าน"). Next: A6 cat look prototype (blocky Studio-part cats to match the map).
- 2026-11-08: A6 built: `src/shared/CatModel` (3 shapes, patterns tabby / patches / socks / tuxedo / spots, accessories
  bow / collar / scarf / hat / flowers / crown / wings / halo, tier effects sparkle / gold / glow / rainbow, sizes by
  multiplier) and `MapTools/CatPreview` (one cat per tier + 6 variants on the lobby road at 270 degrees). Checked by
  Studio captures; waiting for the developer's look approval.
- 2026-11-08: A6 passed. A7 built: rigged cats + 5 looping clips + showcase; the preview cats play "showcase" for the
  developer's client video. Checked in Studio Play: every preview cat's joints move (Motor6D.Transform changes).
  Fixed on the way: with StreamingEnabled a cat arrived before its joints, so the controller waits for all of
  them ("Bones" attribute) and cats stream as Atomic models.
- 2026-11-08: A7 passed ("ผ่าน"). The Studio camera was left Scriptable by the MCP screen capture (developer could not turn it); reset to Fixed. Next: 1.1 project base (code tasks start).
- 2026-11-08: 1.1 built: `shared/Remotes` (full list, all created at server start), `server/Util/Guard` + `RateLimiter`,
  `shared/Validate`, `shared/Format`, `client/Lang` (follows the player's "Language" attribute), `client/UI/Kit`
  (buttons, windows, one open at a time, phone fit), `SettingsController` (gear button top right + Settings window,
  English / ไทย) and `SettingsService`. Specs: RateLimiter, Validate, Format, Remotes. Studio Play: gear -> Thai
  switched every text; bad values ignored; 30 calls in a row -> 4 accepted; no errors. Saving the language is 1.2.
- 2026-11-08: long-run mode starts (developer: work on without waiting for "ผ่าน"); 1.1 counted as passed.
- 2026-11-08: 1.2 saves (`DataTemplate` with cats as a map of unique ids, `sanitize`, `DataService` with attributes +
  leaderstats + owner snapshot, FreshSave = ProfileStore Mock, `client/PlayerData`) and 1.3 debug (`DebugService`:
  !money !strength !speed !level !reset !data !save !help, Studio hook ServerStorage.SweetpotatoDebug). Studio Play:
  !money / !strength / !save work, attributes and leaderstats follow. **Saves across sessions not testable yet: Studio
  API access is off** (DEVELOPER_TODO); ProfileStore runs in memory until then.
- 2026-11-08: 1.5 `shared/Cats` (400 designs from fixed seeds: 150/110/70/45/20/5, unique ids / names / looks, tier
  effects) + `shared/CatRules` (kg roll, income, size, sell price, tier pick, training curves, walk speed, zone gates);
  1.6 `tools/sim/economy.luau`, option B picked (`docs/economy.md`). Spec: tests/Cats.spec.luau.
- 2026-11-08: 1.8 `PenService` (pen on join, spawn at it, cats from the save as rigged models, income every second,
  SellCat / LockCat, !givecat !slots), `PenCatsController` (cats wander on clients), `MyCatsController` + `UI/Hud`
  left column, `ToastController` + `Util/Notify`, `MovementService` (walk speed + like buff). 1.9 sign drawn per
  client (`PenSignController`), Like prompt with one like per owner per UTC day. Studio Play: 4 cats -> income
  1,444.7/s exactly, lock / sell (3.8K for a 40 kg Rare) / locked refusal, cats walk, signs read "YOUR PEN" /
  "Free pen". The like itself needs two players: in DEVELOPER_TODO.
- 2026-11-08: 1.10-1.14 built: `WildCatService` (18 cats per zone on the hiding spots, zone odds / kg skew, 30-90 s
  respawn elsewhere, dropped cats, !wild !nearcat), `shared/FishingBar` (bar maths + spec; tuned with
  tools/sim/fishing.luau: Basic ~7 s ... Secret ~76 s for a decent player, 40% of tries), `FishingService` (Cast,
  per-player bars on the server at 15 Hz, snapshots, first full meter wins, others dropped, escape on empty, line
  beam, players stand still while fishing), `CarryService` (cat welded over the head, icon attributes, delivery
  at the own pen + save before the toast, full-pen message, drop on hit / death / leave, !drop), `BatService`
  (cooldown, nearest in front, no hits in the lobby or on fishers, carrier drops the cat and flies),
  `ToolService` (Bat + Rod from parts), clients: `FishingController` (bar UI, HOLD button, caught card),
  `WildCatTagController`, `CarryIconController`, `BatController` (knockback). Studio Play with a bot driving the
  real remotes: Basic caught in 10 s, no input -> escaped in 6 s, carried 4.7 studs over the head, delivered at
  the pen (cat count +1, income starts), !drop -> dropped wild cat re-fished, too weak -> "Need 211 Strength".
  **Two-player parts (contest, bat hits) need the developer's 2-player test** (DEVELOPER_TODO).
- 2026-11-08: 1.15 / 1.16 `TrainingService` (own pen's weights / treadmill train every second, Upgrade prompts,
  weights look per 5 levels via `Util/GymLooks`), `TrainingController` (Roblox default cheer / run animation in
  place, "+0.1 kg" popups, own-pen prompts with cost), zone gates enforced: `ZoneGateService` (server puts players
  back with "needs X Strength") + `GateController` (barriers solid on the client while closed). Studio Play:
  Strength 1 -> 1.4 in 3 s at the weights, Speed 0 -> 0.6 on the treadmill (walk 16.5), look 1 -> 3 (Lv 11) -> 5
  (Lv 21), Market with Strength 1 -> put back to r = 322. The Upgrade prompt click itself is for the developer's
  test (key F at your weights / treadmill).
- 2026-11-08: 1.17 `HudController` (left: Shop / x2 Speed blinking / My Cats / Trade - Shop, x2 Speed and Trade say
  "coming in the next update" until milestone 2; right: Strength + levels; bottom-left: Speed, money, +money/s;
  bottom-right: event countdown; Roblox's own hotbar for Bat + Rod; phone scaling). 1.18 `EventService` (Mythical
  every 10-20 min, Secret every 40 min, random hiding spot anywhere, beam, 3 min escape that waits while someone is
  fishing, a cat that breaks free from a rod hides at a new spot and the event goes on, !mythical !secret
  !eventin !endevent) + `EventController` (banner, arrow over your head, beam label with distance, Secret sky tint,
  music hook). Studio Play: HUD as specified, Mythical beam + arrow + countdown 2:56, escape message, Secret tint;
  fishing the event cat with no input -> it moved 674 studs and the event went on. No errors in Output.
  Fixed: BindableEvents copy tables, so wild cat removals now pass the id.
- 2026-11-08: milestone 1 built and self-tested in Studio (single player + debug commands). Waiting for the
  developer (docs/DEVELOPER_TODO.md): API Services on (saves across sessions), max players 8, a 2-player test
  (contest, bat, likes), a phone test, publish, then the play video for the client.
- 2026-11-08: developer: 2-player test done and API Services on ("ทำแล้ว"). Checked here: ProfileStore says "data
  will be saved"; money 777 survived a stop + Play; the developer's save was reset to a new player afterwards.
  Milestone 1 counted as done. Studio Play still reports MaxPlayers 60: check Game Settings (8) in DEVELOPER_TODO.
- 2026-11-08: milestone 2 starts (long-run mode). `docs/tasks/phase-2.md` written. 2.1-2.5: `shared/Bonus` (all
  multipliers, spec), `Util/BonusCtx`, `shared/Shop` (prices, spec), `ShopService` (BuyItem: rods in order,
  shoes, pen +5 up to 60, treats 10 min stacking), `ShopController` (tabs Rods / Shoes / Pen / Treats / Crates),
  rod colour by material (`ToolService.refreshRod`), income / Strength / walk / fishing now go through Bonus;
  toasts translate item names on the client. Studio Play (FreshSave): rod 3 before 2 refused, rod 2 bought,
  shoes 16 -> 18 walk, pen 10 -> 15, Golden Fish income 120 -> 240/s; shop window screenshot.
- 2026-11-08: 2.6-2.9: `shared/Crates` + `CrateService` (money crates, odds before buying, no Secret, server roll,
  saved before the reveal, full pen refused before paying, !crate) + `CrateController` (Crates tab with every chance,
  reveal with the real cat turning in a ViewportFrame); `shared/Mutation` (Gold x2 / Rainbow x5 / Glow x10 at
  4 / 1.5 / 0.5 % x luck, Basic-Legendary) rolled on catch (winner's luck; a knocked-loose cat keeps it) and in
  crates, shown on the pen cat (gold fur / rainbow sparkles / glowing fur), in My Cats and the caught card;
  `shared/Book` + `BookController` (400 cards, unseen = black "???", +5% money per full tier, +25% all);
  `RebirthService` + `RebirthController` (Strength 1,500 x 2.2^r, resets money / Strength / Speed / levels, keeps
  cats, rods, shoes, slots, book). Studio Play (FreshSave): 100,000 rolls per crate within 0.1% of the odds,
  Diamond crate bought -> Legendary "Tabby Sesame" revealed and in the pen, rebirth refused at 1,000, done at
  1,600: money / Strength reset, cat kept, income 600 -> 900/s.
- 2026-11-08: 2.10-2.16: `shared/Rewards` (days, money by income, offline, quest pick, gift bits; spec),
  `RewardsService` (offline income 50% up to 8 h with a toast, 7-day login, playtime gifts per UTC day, 3 daily
  quests fed by `Util/Progress` from catches / bat hits / training / crates / likes, codes from Config.Codes, group
  reward via IsInGroupAsync; saved before toasts; RewardsReady badge; !playtime !newday), `CrateService.give` (free
  crates), `LeaderboardService` (2 OrderedDataStores, boards outside the lobby ring) + `LeaderboardController`,
  `RewardsController` (Daily / Gifts / Quests / Codes / Group, button under Rebirth). Studio Play (FreshSave):
  login 500, second claim refused, code MEOW once (then "already used"), unknown code refused, group 10K + treat,
  gifts 1-4 (gift 4 = a Wood crate cat), gift 5 refused at 31 min, quest "open 2 crates" paid, board row written.
- 2026-11-08: 2.17 `shared/Trade` (offer / room checks, one-step swap with renumbered ids; spec proves no cat is
  copied or lost), `TradeService` (invite 20 s, offers up to 6, any change clears Ready, both Ready -> 5 s ->
  re-check + swap + both saves + TradeLog store, cancel on leave), `TradeController` (players list, invite popup,
  both offers, tap-to-add, Ready / countdown / Cancel); HUD Trade button opens it. Studio Play (one player):
  window opens, "Nobody else is in this server", self-request and stray offers ignored, no errors. **The real
  2-player trade is in DEVELOPER_TODO.**
- 2026-11-08: 2.18-2.20: `PassService` (5 passes -> PassX attributes read by Bonus, ToggleSpeed saved, !pass),
  `ProductService` (the one ProcessReceipt: NotProcessedYet when not loaded / unknown, receipt recorded with the
  grant, saved before PurchaseGranted; +20 slots in 3 price steps capped at 60, 4 cash packs by income, strength
  pack, luck x3, server luck with announcement, summon Mythical via EventService.summon, starter pack once; !buy),
  `StoreController` (Shop's Robux tab, regional prices from GetProductInfo, "Not on sale yet" while ids are 0;
  x2 Speed button = switch for owners, else the pass prompt), `VipTagController`. Studio Play (FreshSave):
  Cash pass income 40 -> 80/s, Speed pass walk 37.6 -> 59.2 and the switch back to 37.6, all 7 products granted
  through the receipt path with 7 receipts kept. **Real purchases need the ids (DEVELOPER_TODO).**
- 2026-11-08: 2.21 all 400 designs from `shared/Cats` built by `CatModel` with no mutation, Gold, Rainbow and
  Glow (Studio Edit, 1,600 builds): 0 failures, 47 parts on average, 63 at most. Gallery capture of every tier
  (Mythical halo / wings, Secret size) checked and removed.
- 2026-11-08: 2.22 player animations without uploads: `shared/PlayerPoses` (carry = both arms up, reel = rod
  arm out + reel arm turning) applied by `PlayerAnimController` on every client to every player within 160
  studs from the "CarryingCat" / "Fishing" attributes, blended in / out in 0.25 s, for Motor6D and the newer
  AnimationConstraint joints (the avatars here use AnimationConstraint: a Motor6D-only version did nothing);
  cast = default tool "Slash" via `Util/ToolAnim` (bat swing moved to the same helper); lift / run stay the
  default cheer / run. `Config.Carry.HeadOffset` 3.6 -> 2.6 so the cat rests on the raised hands (gap 1.13 ->
  0.12 studs). Studio Play: reel pose while fishing, real catch -> arms up under the cat, !drop -> arms down.
  Cats' clips were done in A7.
- 2026-11-08: 2.23 sound: `client/Sound` (SFX / Music groups, 3D roll-off), `SoundController` hooks existing
  signals only (button clicks except HOLD, window open, toasts by key / kind, cast / swing via the tool's
  toolanim for anyone near, reel loop, catch / escape, bat hit, training ticks, crate shake -> reveal / rare,
  hidden cats meow near the camera every 8-16 s, music Lobby / Zones / Mythical / Secret with cross-fade,
  event_start); Settings Music / Sound effects ON-OFF saved in data.Settings (MusicOn / SfxOn attributes);
  `Config.Events.MusicId` folded into `Config.Music.Secret` (one music path, muted by the switch). All 28
  ids are 0: `docs/Sweetpotato_Sounds.xlsx` + `docs/SOUNDS.md` (from `tools/gen/sounds_xlsx.py`) for the
  developer. Studio Play with dummy ids (removed): buy, Music_Lobby -> Music_Zones, meow, cast, reel,
  catch + meow, click, open, both switches mute the groups, Music OFF saved.
- 2026-11-08: 2.24 `docs/gpt_store_prompts.md`: Thai how-to, icon + 4 thumbnail prompts in English (smooth blocky
  style, no studs, only what the game does: rod catch, carry over head, bat bonk with cartoon stars, Mythical halo
  / wings, Gold / Rainbow / Glow, 400 cats, weights + Secret giant; Roblox rules in every prompt) and the store
  description EN / TH. Style references for ChatGPT: `art/preview/cats_lineup.jpg` (Studio render of real cats)
  and `art/preview/carry_ingame.jpg`. Making the pictures and uploading = DEVELOPER_TODO.
- 2026-11-08: 2.25 `docs/LAUNCH_CHECKLIST.md` (every blueprint item with its state and how to try it, the
  developer's tests, Dashboard settings, launch-day order, handover) and `scripts/launch_check.luau` (fails while
  any pass / product id is 0, Debug is on, GroupId 0 or players != 8; lists silent sounds). Studio Play
  2026-11-08: `!crate <kind> 20000` matches the blueprint odds (Diamond Mythical 0.48 % for 0.5 %), 18 cats on 60
  spots in each zone, Output clean except a "ContentId 203785492 ... type does not match" line that is not in
  the place, the code or the character (Studio's own). The Edit place has only Terrain, Camera and Map. Left
  [~]: the full-server / phone tests, Debug off, publish and the `.rbxl` are the developer's (checklist B-D).
- 2026-11-08: sound ids from the developer's sheet (all 28) in `Config.Sounds` / `Config.Music`. Each checked in
  Studio Edit: audio type, loads in this game, lengths 0.0-6.5 s (songs 102-165 s). `Sound.preload` loads every id
  at start (the first click was not loaded yet); the crate shake sound (3.1 s) stops at the reveal (1.2 s). Studio
  Play: Music_Lobby -> Music_Zones on leaving the lobby, click / open / meow play, 27 / 27 preloaded. Told the
  developer which picks carry other games' names (deliver, drop, escape, rebirth): their call.
- 2026-11-08: the developer keeps the 4 sounds named after other games (deliver, drop, escape, rebirth) as they
  are ("เก็บไว้ตามเดิม"). If Roblox removes one, only that sound goes silent; swap its id in Config.Sounds.
- 2026-11-08: the developer's tests passed: 8-player server, a real phone, 2 players (same cat, bat, likes,
  trade). Max players = 8 set and the game published. 2.17 -> [x]. 2.25 stays [~] until launch day (Robux ids,
  Debug off, `.rbxl`).
- 2026-11-08: `docs/Sweetpotato_Robux.xlsx` (from `tools/gen/robux_xlsx.py`, Thai): the 5 passes and 12 products
  with the English name / description to paste into Creator Hub, a suggested price (client confirms), yellow
  columns for the client's price and the id. Decision to review: "luck" (Lucky pass, Luck x3, Server Luck) raises
  only the Gold / Rainbow / Glow chance, as built in 2.8; the descriptions say so.
- 2026-11-08: `docs/gpt_item_prompts.md` (Thai how-to, English prompts): 15 pictures for the 5 passes and 12
  products (the 3 slot products share one), smooth blocky style, transparent 1024 px, kept inside the pass circle.
- 2026-11-08: the developer's 15 GPT item pictures saved as `art/source/gpt_items/<Key>.webp`; `tools/gen/item_icons.py`
  (Pillow) cuts the background by a flood fill from the border (white and painted checkerboards), centres and
  sizes them to 512 x 512 transparent PNGs in `art/export/store_items/` (review sheet `_review.png`: all clean).
- 2026-11-08: pass / product ids from the developer (5 + 12) in Config. Checked with GetProductInfo in Studio:
  every name matches, all on sale, passes owned by the group, every item has an icon; Dashboard prices
  149 / 299 / 249 / 199 / 149 and 49 / 99 / 199 / 25 / 79 / 199 / 449 / 99 / 49 / 199 / 149 / 49 (Studio shows the
  developer's regional prices, lower). `launch_check` now fails only on Debug (switched off on launch day).
  `rojo serve` had stopped and Config was missing from the Studio place; restarted it.
- 2026-11-08: Robux tab checked in Studio Play with the real ids: 15 rows with regional prices, passes "Owned"
  for the developer (the group owner's account owns them). Cards now show each item's Creator Hub icon
  (IconImageAssetId from GetProductInfo; the coloured chip stays until the picture has loaded). Fixed: the
  Luck x3 card showed the Lucky Treat text ("x1.5 for 10 minutes"); new key ProductLuck3Desc.
- 2026-11-08: phase 3 planned from the developer's 10-point list (`docs/tasks/phase-3.md`, R1-R9). Checked first:
  wild cats are already non-colliding; the blocking comes from the bushes (322 / 322 collide).
- 2026-11-08: R1 bushes walk-through: MapKit Opts `walk` (CanCollide off, queries kept) on the bush balls; the place
  patched in Studio Edit (322 bushes, 1,610 parts). Studio Play: the character walks straight through a zone-1
  bush. The place change goes live with the developer's next Save / Publish.
- 2026-11-08: the developer confirmed "99SX" = 99 sextillion for money, Strength and Speed (R4), and wants the new UI
  in a cute-cat style (R9).
- 2026-11-08: GPT prompt files for phase 3: `docs/gpt_ui_prompts.md` (cute-cat style board, 12 screens of the real
  game, 12 icons) and `docs/gpt_model_prompts.md` (20 reference sheets: rods x 5 sets, bat, shoes x 2, treats, crates,
  dumbbells x 5 sets, treadmills x 5 sets). The developer makes the pictures while R2-R4 are built.
- 2026-11-08: R2 training lock: TrainingService checks the spots every 0.2 s; stepping on your own spot snaps the
  character onto it facing the machine (walk speed factor 0, AutoRotate off, `Training` set); a jump (JumpRequest ->
  StopTraining, rate limited) or a push 3 studs off releases it, and the spot grabs you again only after stepping
  off. "Jump to stop" hint (EN / TH). `!train` shows the lock state. Studio Play: locked on treadmill and weights,
  MoveTo away does nothing (0.00 studs), Space releases, landing back does not re-lock, walk off + back re-locks.
- 2026-11-08: R3 money popups: PenService puts `BaseRate` (income x mutation) on each pen cat and `IncomeMult` (every
  money bonus) on the player; `IncomePopupController` shows "+$X" over each of your cats within 80 studs every tick
  (one reused label per cat, random 0-0.35 s start) and "+$total" right of the money pill. Studio Play: 3 cats,
  popups sum 27.94/s = Income 27.94, money +84 in 3 s; labels visible over the cats and by the pill.
- 2026-11-08: R4 step 1: `tools/sim/economy_sx.luau` + options A / B / C in `docs/economy.md` (log-ladder cat weights,
  x3.6 heavier cats per rebirth, income rate x kg^0.6, Strength x~3.95 per rebirth, rebirth need x4, 99 Sx cap).
  Waiting for the developer's pick before Config, migration and tests.
- 2026-11-08: R4 option B (developer's pick) built: Config (log-ladder tier kg, zone gates 100 / 10K / 1M / 10M,
  IncomePower 0.6, Weights / Treadmill Gain 1 Growth 1.6 with CostRebirth 3, Rebirth StrengthMult / SpeedMult 3.95,
  KgMult 3.6, RebirthNeed 150M x 4^r, Economy.Max 99 Sx, Walk.Scale 100, crates CostRebirth 3, strength pack 10K);
  CatRules kgFor / cap / log rollKg / income kg^0.6 / size without the rebirth factor / costs per rebirth / walk
  relative to the life / gates x3.6^r; wild cats keep the base kg (models too), each player sees, needs and
  delivers base x 3.6^rebirths (FishingService, CarryService, CrateService, WildCatTag, !givecat); DataService caps
  Money / Strength / Speed at 99 Sx on every change; Commands parse T / Qa / Qi / Sx; money leaderboard stores
  log10 x 1e6 (new store _v2); `shared/Migrate` converts EconVersion 0 saves once (tests/Migrate.spec). Studio Play:
  the developer's save converted (Strength 78 -> 21.4K, Speed x10, cats remapped, money kept); with a test save
  !money past 99 Sx caps at 9.9e22, rebirth 1 -> wild Basic 1 kg shows 3.6 kg + "Need 4 Strength", the server
  refuses at Strength 1, catches at 10, the pen gets 3.6 kg, income 3.56/s as computed, weights +7.90/s, upgrade
  $90; no errors. FreshSave removed again.
- 2026-11-08: plan change: R9 (UI) moves ahead of R5-R8 because the developer's UI pictures came first (style board,
  12 screens, 12 icons in `art/source/gpt_ui/`); R5 waits for the item reference pictures.
- 2026-11-08: R9 step 1: the 12 icons cut to 512 px transparent (`tools/gen/item_icons.py ui` -> `art/export/ui_icons`,
  all clean; upload = DEVELOPER_TODO, ids -> `Config.UIIcons`, a white paw until then). Kit restyled from the style
  board: cream windows with cat ears, peach inner border and faint paw prints, pink cat-head title banner, round pink
  close button, glossy jelly buttons with a lip and a tiny paw, cream tabs (`Kit.Colors.tab`), `Kit.paw`, `Kit.ears`,
  `Kit.icon`. HUD from mockup 01: square cat-ear menu buttons with icon + label, cream Strength panel with ears and
  level pills, cream speed / money pills, purple event pill, cat-ear Settings button. Studio Play: every window picks
  up the new kit (Shop checked), the HUD fits a short viewport without overlaps, no errors. Next: each window laid
  out like its mockup (Shop, Robux, My Cats, Book, Rewards, Rebirth, Trade, Settings, fishing, popups).
- 2026-11-08: the developer uploaded the 12 UI icons to the group; ids in `Config.UIIcons` (checked: images, group,
  load). HUD now shows them (menu buttons, Settings, Strength dumbbell, coin, Speed lightning, event cat, Rebirth /
  Rewards buttons): Studio Play, 11 / 11 icons loaded, the layout fits a 746 x 531 view.
- 2026-11-08: R9 windows 1: `Kit.row` / `Kit.rowButton` (mockups 02 / 03: sky picture box, big outlined name,
  description pill, paw marks) used by the Shop tabs and the Robux tab (item icons fill the picture box); money
  pill on the Shop window. My Cats rebuilt as a card grid (mockup 04): real cat pictures from `UI/CatPortrait`
  (CatModel in a ViewportFrame, built only for cards on screen), tier ribbon, kg, income, mutation tag, lock badge;
  tap a card to choose it, Sell (tap twice) and Lock at the bottom; Book button with its icon. Studio Play: Shop,
  Robux and My Cats drawn as the mockups, choosing a cat works, no errors.
- 2026-11-08: R9 windows 2: Book (mockup 05: cat pictures, dark silhouettes for unseen cats via CatPortrait, yellow /
  cream tabs, progress bar with a cat head, gold bonus ribbon), Rewards (shared rows with the gift icon), Rebirth
  (mockup 07: keep / reset cards around a glowing Mythical cat, "Rebirth 0 -> 1", Money / Strength / Cats chips from
  Config.Rebirth, Strength progress bar, purple button). Studio Play: all three drawn, no errors.
- 2026-11-08: R9 windows 3: Trade (mockup 08: "You" / partner pills, cat cards with pictures and tier ribbons, Ready /
  Not ready pills, the picker row with pictures, cream invite popup with ears; checked with a fake TradeState),
  fishing (mockup 10: light bar, round HOLD with a pink paw), the Caught! card (mockup 11: pink cat-ear banner, the
  real cat picture, details; FishingService sends the cat kind), toasts as round pills with a paw. Settings uses the
  new kit as built. Studio Play: catch -> Caught! card with Ginger Pumpkin, toast pill; no errors. R9 stays [~]
  for the developer's look check; the crate opening screen (mockup 12) comes with R8.
- 2026-11-08: R9 approved by the developer ("ผ่าน"). The 20 item reference pictures for R5 arrived
  (`art/source/gpt_models/M01-M20`): rods x 5 sets, bat, shoes 1-4 / 5-8, treats, crates, dumbbell racks x 5 sets,
  treadmills x 5 sets (steps 1 / 3 / 5). R5 starts with the pilot sheet.
- 2026-11-08: R5 pilot: `art/blender/items.py` (builders: treadmill / weights / dumbbell / rod by level 1-25 =
  5 families x 5 steps, bat, crate by key) + `pilot.py` (renders and lays out `art/preview/models/pilot_sheet.png`):
  treadmill Lv1 / 13 / 25, weights Lv1 / 13 / 25, wood rod 5, gold rod 3, bat, paper / gold / diamond crate.
  Treadmill screens face the runner (+Y; front = -Y). Sent to the developer for approval before the other families.
- 2026-11-08: R5 pilot feedback: everything approved except the crates ("ดูสมจริงกว่านี้"). New `art/blender/crates.py`:
  hollow boxes with a cap lid that opens around its back edge (for R8), paw holes cut through the walls (boolean),
  crisp bevels; paper = tape + taped corners + printed arrows, wood = grooved planks, posts, rims, brace, metal
  brackets with bolts, gold = edge bands, rivets, faceted red gems, cat-face lock, diamond = chamfered crystal,
  crystal bars and diamonds, glowing core. Sheet `art/preview/models/crates_sheet.png` (4 closed + gold open).
- 2026-11-08: crates approved ("ผ่าน"). All families built: `shoes.py` (8 shoes, M07 / M08), `treats.py` (3, M09);
  treadmill and weights reworked so every step adds a visible part (2 side panels / plate + caps, 3 ears + paws /
  ears + star, 4 gem pillars / third plate + gems, 5 halo ring + winged star / glow rings + winged star) plus a
  signature per family. Sheets via `sheets.py`: `art/preview/models/sheet_{treadmill,weights,rod,shoes,treats}.png`.
  Export `items_export.py` -> `art/export/{Treadmills,Weights,Dumbbells,Rods,Gear,Crates}.fbx` + manifest
  (RES 0.5, per-item triangle caps, see-through parts in `<id>_Glass`, crate lids as `Crate_<key>_Lid` with the
  hinge); `manifest_to_luau.py` -> `src/shared/ItemModelData.luau`. The developer imports after approving the sheets.
- 2026-11-08: R5 in the game. The developer imported the 6 FBX (132 MeshParts; Claude moved them from Workspace into
  ReplicatedStorage.ItemModels, the place needs a Save / Publish). Checked in Studio: the importer turned the meshes
  180 degrees about Y (Config.ItemModels.Flip). New `shared/ItemModels` (build a copy with a Root at the item's
  origin) + generated `shared/ItemModelData`; ToolService dresses the bat and the best rod (Tip attachment at the
  mesh tip, follows RodLevel on every data change); GymLooks.applyLevel puts Treadmill1..25 / Weights1..25 at the
  pens with an invisible collider and moves the treadmill's Stand onto the belt (falls back to the old looks);
  new ShoeService puts the best pair on both R15 feet; shop rows (rods, shoes, treats) and the crates tab show the
  mesh in a ViewportFrame (UI/ItemPortrait). Debug `!gear rod|shoes N`. Studio Play: treadmill Lv4 / Lv25 lock and
  run on the belt, rack Lv25, rod 25 + bat in the hand, Bouncy Boots on both feet, every shop tab drawn; no errors.
  The developer's save was put back as it was (rod 1, shoes 0, treadmill 4, weights 2, Speed 2623.04).
- 2026-11-08: R5 approved ("ผ่าน"). R6: standing two-hand dumbbell curl, the arms taking turns (1.2 s a rep):
  PlayerPoses "curl" (elbows re / le) + PlayerAnimController bends RightElbow / LeftElbow (Motor6D or
  AnimationConstraint); TrainingController no longer plays the cheer on R15; TrainingService welds the mesh
  Dumbbell<level> into each hand while you lift (Config.ItemModels.DumbbellScale 0.9), swaps it when the level
  changes, drops it when you leave. The 25 rack looks came with R5. Tests: PlayerPoses.spec curl checks. Studio
  Play: lock at the weights -> a dumbbell in each hand, right then left arm up (`art/preview/r6/`), level 25 =
  cosmic dumbbells; leaving drops them; no errors. The developer's save was put back (weights 2, Strength 21386.6).
- 2026-11-08: R6 approved ("ผ่าน"). R7: the 25 treadmill looks, +2 % size a level and the Stand moving onto the belt
  came with R5; now the run gets faster with the level: the run animation plays 1x .. 1.9x (TrainingController,
  Config.TreadmillFx.RunSpeed) and sparkles race back along the belt under the runner, 5 .. 34 a second at
  8 .. 24 studs/s, in the treadmill family's colour, fading at the belt's end (TrainingService speedLines: an
  invisible strip welded in front of the feet, seen by everyone, removed when you leave). Thin streaks were
  tried first: too faint from the camera behind. Studio Play: levels 4 / 13 / 25 (`art/preview/r7/`), no errors;
  the developer's save was put back (treadmill 4, Speed 2623.04).
- 2026-11-09: R7 approved ("ผ่าน"). R8: the 5 s crate opening (mockup 12) in CrateController on a full-screen layer:
  0-1 s the crate mesh (lid included) drops and bounces; 1-3 s it wobbles faster with a glow in the colour of the
  best tier that crate can give (crate_shake); 3-3.6 s the lid flies off up to the right with confetti and turning
  rays in the cat's tier colour (crate_reveal / crate_rare); then the real cat model jumps out and stands on the
  crate, and the card (name, tier ribbon, kg and income pills, mutation, "Tap to continue" EN / TH) pops up,
  sized to the screen's height. A tap before the burst skips to it, a tap after the card closes; it closes itself
  after 12 s. Timeline in Config.Crates.Open; a plain box stands in when the meshes are missing. Studio Play
  (CrateResult fired to the client, no save touched): Paper / Wood / Gold (Legendary) / Diamond (Mythical, Gold
  mutation), skip and close, no errors (`art/preview/r8/`).
- 2026-11-09: R8 approved ("ผ่าน"). Revision round 1 (phase 3, R1-R9) is done. Left (developer): Save / Publish the
  place (ItemModels moved in by Claude), a phone test of the new looks, tell the client about the numbers (R4),
  game icon + thumbnails, then 2.25 (launch checklist, delivery).
- 2026-11-09: revision round 2 from the developer (4 points + the client's 3 cat reference pictures, saved as
  `art/source/client_refs/`): plan V1-V5 in `docs/tasks/phase-4.md`. V1 goes first (approvals), V2-V4 meanwhile,
  V5 after V1. The tutorial (V4) is not in the blueprint; the cat pictures are from another game (direction only).
- 2026-11-09: V1 style board (`art/blender/voxcat.py`, `art/preview/cats_v1/styles.png`): one original ginger tabby on a
  voxel grid in A Pixel (0.125 voxels), B Brick (0.25 + studs), C Mix (0.16, big eyes with iris and shines),
  flat-painted pixel face, Freestyle outline round the silhouette only. Sent; waiting for the developer / client.
- 2026-11-09: V2: the rods' reel moved to the angler's left (items.py rod, Rods.fbx re-exported, ItemModelData
  regenerated: the developer re-imports Rods.fbx); the rod gets a "Reel" attachment at the crank (radius on it);
  reel pose: the rod hand in close by the belly, and on R15 the left hand is put on the crank and follows it
  round (PlayerAnimController reachLeft: a two-bone solve from the rig's own rest arm, so slanted / small avatars
  work; out of reach = stretched towards it); R6 keeps the old circling arm. Studio: the left hand stays on the
  crank circle (0.6-0.8 from its centre, radius 0.64), no errors. Until the re-import the old meshes sit 0.63 off.
- 2026-11-09: V4 tutorial: TutorialService (server owns the step: save TutorialStep / TutorialRewarded, Migrate.tutorial
  marks old saves done; steps advance from the lobby edge, CarryingCat, CarryService.Delivered, a training tick; acks
  only for welcome / shop / finish; a lost cat sends step 4 back to 3; Skip, Replay from Settings, !tutorial N) +
  TutorialController (bubble at the bottom centre sized to the screen, Next / Skip, a yellow beam and a bouncing
  marker to the Backyard / nearest catchable cat / pen / weights, a pulsing ring on the Shop button). Reward
  Config.Tutorial.Reward 1000 once. Studio: 1 -> 2 (Next) -> 3 (left the lobby) -> 4 (carrying) -> 3 (lost) ->
  6 (training) -> 7 (Shop opened) -> done + reward; Skip; no errors (art/preview/v4/). Save put back.
- 2026-11-09: V3 part 1 (water): survey found the fountain as plain cylinders with white sticks, creeks as a straight
  strip with round ends, waterfalls as a white block (art/preview/v3/before_*). New MapKit fountain (octagonal stone
  basin, rim, corner posts, pedestal, two bowls, glassy water, 16 + 8 flowing streams (Beams with a built-in texture
  moving), top spray, splashes, a light under the water), creek (winding glassy water over a darker bed, sand / snow
  banks, bank stones, reeds, lily pads, stepping stones, flowing current; the bridge and its hiding spot unchanged)
  and waterfall (rough rock blocks with moss, glass curtains with flowing water, upper fall, a pool with a stone ring,
  foam and mist; frozen: ice curtains, icicles, crystals). MapTools/Upgrade swaps them in place (frames read back from
  the old parts) with the old ones in ServerStorage.MapBackup_V3 (Upgrade.undo puts them back): 19 fountains,
  79 creeks, 47 waterfalls. Studio Play: wild cats hide in every zone, no errors. Next: ground detail per zone.
- 2026-11-09: round 2 feedback: (1) the rod in the LEFT hand while fishing and the right hand cranking the reel on the
  rod's right (the first export's side; Rods.fbx re-exported back to it, ItemModelData as before): ToolService switches
  Roblox's RightGrip off and welds the handle to the left hand (LeftGrip) while "Fishing" is set, back after;
  PlayerPoses reel holds with the left arm (hx / hz / he), PlayerAnimController puts the right hand on the crank
  (the arm solve now works for either arm). Studio: handle 0.36 from the left hand, right hand on the crank circle,
  grip back to the right hand after. (2) Hotbar 1 = rod, 2 = bat (tools given rod first).
- 2026-11-09: V1 try 2 (`art/blender/blockcat.py`, `art/preview/cats_v1/blockcats.png`): the try-1 voxel cats were not
  approved; the developer's new pictures show chunky block creatures covered in LEGO studs, stacked plates, block
  faces, glow on rare ones. Block cats (head / muzzle / ears / body / legs / tail blocks, studs on every face, flat
  plate stripes, Fluffy fur plates) with tier extras: Rare collar + bell, Epic crystals, Legendary gold armour,
  crown, wings, sparkles. In the game: Roblox Parts (as CatModel now) with a tiled studs texture. Sent.
- 2026-11-09: V4 redone (developer: arrows first, every step moves on by itself): welcome and the last step move on
  after 5 s (no Next button), the shop step when the Shop opens; the guide is yellow chevrons flowing along the
  ground to the target, a big bouncing 3D arrow over it, the target outlined (Highlight), an edge arrow with the
  distance when it is off screen, a pointing hand on the Shop / hold button; the banner shows the step number, a
  title, one short line and progress dots (new texts TutT1-7, TutHold). Studio: 1 -> 2 after 5 s, chevrons along
  the road, cat outlined + arrow, hand on Shop, 7 -> done after 5 s; no errors (art/preview/v4/v2_*).
- 2026-11-09: V1 try 2 not approved ("the tiers look too alike"). The developer wants plain cats at the bottom,
  fashion higher up, fantasy at the top (dragon, gorilla, god, alien, strawberry, banana, whale, zombie, mech
  cats...) and 50 unique designs per tier, keeping 400 cats in all (their pick: 50 unique per tier + colour
  variants). Design table first (`tools/gen/cat_designs.py` -> `docs/Sweetpotato_Cats.xlsx` in Thai +
  `art/source/cat_designs.json`): 300 designs with EN / TH names, base body, colours, what is special, effect;
  tier counts 100 / 80 / 70 / 50 / 50 / 50. Next after "ผ่าน": one Blender model per tier, then all of them.
- 2026-11-09: design table approved ("ผ่าน"). One Blender model per tier (`art/blender/blockcat.py`: base cat with attach
  points + a function per design; `blockcat_sheet.py` -> `art/preview/cats_v1/tier_sample.png`): Ginger Tabby (Basic,
  plain), Cool Shades (Rare, sunglasses), Pirate (Epic: tricorn hat with a paw badge, eye patch, striped shirt,
  wooden cutlass, earring), Strawberry Cat (Legendary: red with seeds, a big leaf crown and stem, cream, hearts),
  Dragon Cat (Mythical: gold horns, back and tail spikes, belly plates, bat wings with bones, a fire puff), Cat God
  (Secret: golden, crown with gems, halo, gold armour and sash, wings, glowing eyes, floating gems, a light ring).
  Sent for approval; after "ผ่าน" the other 294.
- 2026-11-09: tier samples approved ("ผ่าน"); the developer asked for bones, animation and a different effect round
  every Mythical / Secret cat. Effects: 100 unique ones in the table (effectKey + Thai text, e.g. Cat God sparkles,
  Dragon soft flames, Alien a UFO circling). Bones: `art/blender/catrig.py` sorts every block into the game's rig
  bones (Body, Head, Tail1, Tail2, LegFL/FR/BL/BR, WingL/R, Fx) with pivots; walk cycle (legs in diagonal pairs,
  body bob, head nod, tail sway, wing flap, effects orbit / flicker) rendered as `art/preview/cats_v1/walk.gif`.
  Also (developer): the pens' inside decorations removed (red and pink discs, 2 flower patches each) in MapKit and
  in the place, only the house and the green floor left.
- 2026-11-09 V5b Basic cats: the base cat (`art/blender/blockcat.py`) now takes breed traits from its look: 18 patterns
  (tabby, mackerel, tiger, classic swirl, calico, tortie, colourpoint, mitted, spots, rosettes, leopard, patch,
  socks, mittens, black paws, tuxedo, bicolour, smoke, ...), ear types (fold, tufts, big, small), tails (long curl,
  bob pompom, fluffy, thin), eyes (big, sleepy, odd colours, glow), and kitten / chubby / loaf / short legs / big,
  cheeks, flat face, ruff, hairless wrinkles, curls, cloud puffs, yawn, blush. `BASIC_LOOKS` = the 50 Basic designs
  from the table (31-61 blocks each); `art/blender/blockcat_tier.py` renders a tier on one sheet at the same
  scale. All 50 rig cleanly (catrig: new head / body / sock names).
- 2026-11-09 V5b approved; developer: build all the other tiers, check and fix them myself, review in the morning.
  V5c Rare: `art/blender/catparts.py` = the parts library for every tier above Basic (hats, glasses, clothes, held
  things, wings, effect previews; boxes / balls / cylinders / wedges only, name prefix = bone), `cats_rare.py` = the
  49 Rare designs, `catalog.py` loads every tier. Self-check fixes: ears tilt out under hats, clothes stand 0.22
  off the body with studs only on top (no studs or pattern patches poking through), white-on-white accessories
  recoloured. 34-80 parts per cat (average 45).
- 2026-11-09 V5d Epic: `cats_epic.py` = 49 costume designs (hat + clothes + a held thing each; boards and skis under the
  paws). Self-check: white-on-white cats recoloured (Doctor, Chef, Baker, Scientist), fishing rod turned outwards.
  39-79 parts per cat (average 53), all rig cleanly.
- 2026-11-09 V5e Legendary: `cats_legendary.py` = 49 food / animal designs (the body becomes the thing: peel, shell,
  bun, cup, tentacles in place of legs, new ears and tails). Self-check: turtle / snail shells made bigger and moved
  back (they hid behind the head), banana peel and donut ring made readable, octopus tentacles bigger.
  28-85 parts per cat (average 50), all rig cleanly.
- 2026-11-09 V5f Mythical: `cats_mythical.py` = 49 creature designs; `cateffects.py` = the effect table for all 100
  Mythical / Secret effectKeys (layout + item + colours + count + glow; the sheets preview it, V5h builds the same
  in game). Self-check: pale cats recoloured (Ice Dragon, Crystal, Fairy, Ghost, Snow Spirit, Cloud Dragon, Bubble,
  Pegasus wings, Mummy), sheets now on a slightly darker background so white cats show. Note for V5h: Mermaid and
  Genie have no back legs (fish tail / smoke), so the game rig must allow a missing bone. 33-73 parts (average 49).
- 2026-11-09 V5g Secret: `cats_secret.py` = 49 god / cosmic designs (discs and wheels behind, rings round the body,
  crowns, wings, crystals, tentacles, a mountain or a tree on the back) with their effects. Self-check: Earth Titan's
  mountain made taller (it hid behind the head), Moon Goddess crescent made gold, Angel wings gold-edged, Prism's
  rainbow beam moved to the visible side. 34-101 parts (average 60; Sakura Goddess the most).
- 2026-11-09 V5c-g approved (developer: "ผ่าน นำเข้าเกม"). V5h: the Blender helpers record each block's shape and frame
  (`kit.prim`), `cats_export.py` turns every block into one Roblox part line (box / ball / ellipsoid / cylinder / stepped
  cone / wedge / gem; rings = a circle of boxes), bones sorted by catrig and named by their Roblox side. CatModel
  rewritten on that data (Look = { design, tint?, mutation? }); Cats = 300 designs + 100 tinted variants ("Frost Ginger
  Tabby"), ids cat001-400 by tier (old test saves now show other designs: fine before launch). Parts per cat 28-131
  (Basic avg 38, Secret avg 83). Studio: all 6 tiers built and compared with the sheets (wedges, wings, halos,
  effects match), pen cats animate (walk / idle / sleep, Fx spins), no errors in Play. Phone performance not
  checked yet (V5i).
- 2026-11-09 V5h approved. V5i: 480 test cats in 8 full pens took Studio from 54 to 12 fps: the cost was physics of
  the jointed rigs. Now every ground cat is anchored blocks (CatModel; `CatModel.joinRig` for carried cats) and
  CatAnimController poses blocks with one BulkMoveTo a frame, nearest first within Config.CatAnim.PartBudget
  (moving a block costs ~3.5 us in Studio); PenCatsController skips resting cats, moves near walkers by their Root
  only and far ones in steps; far cats keep resting. Result 38-42 fps with 480 cats. Found and fixed: the carried
  cat never animated (the character's Animator reset its joints; the pass now runs in PreSimulation). New: the
  "CatAnimMs" / "PenCatsMs" player attributes (time per frame), `!fillpens N` / `!clearpens` (test cats, not
  saved), and scripts/check.luau fails a module with no top-level return. Checked in Play: pen cats walk / rest,
  carried cat animates over the head, My Cats cards and the book (100/80/70/50/50/50) show the new cats.
- 2026-11-09 V5j: effect style options rendered (fxshapes.py, fx_options.py): smooth flames / faceted crystal clusters /
  puffy stars + twinkles; A soft ground glow, B magic circle + two light ribbons, C ring of see-through flame tongues.
  Self-check round: crystals read as drops (made long faceted clusters), ground glow too solid (three faint discs +
  thin ring), ribbons too thick, aura looked like an egg (now flame tongues).
- 2026-11-09 V5j picked (developer: "Mythical A, items turning round the body; Secret B, a spiral shooting up from the
  ground and vanishing every 3 s"). cateffects.effect now builds fxshapes.from_style (smooth versions of all 31 item
  kinds, smooth ring / wheel layouts, tier look) and removes the old block effect parts (also Dragon Cat / Cat God).
  Mythical / Secret sheets now on the game's grass (the glow vanished on the grey sheet). Self-check: items made
  bigger, pale effects (ice, snow, clouds) get a stronger glow colour, the Secret sheet shows the burst mid-flight in
  each effect's colours (the full white spiral hid every cat). `fx_anim.py` -> `fx_anim.gif` (3 s loop).
- 2026-11-09 V5j approved ("ผ่าน นำเข้าเกม"). Game import: `fx_export.py` builds each item kind once in red and splits it
  into layers by colour role (main / light:k / fixed / see-through glow) -> `art/export/Effects.fbx` + `FxMeshData.luau`
  (78 meshes, 63k triangles, 33 kinds + GlowRing / MagicCircle / RingSeg / WheelRay). fxshapes logs every placement;
  cats_export writes them as `fx` lines per cat (and skips the effect objects). CatModel builds the pieces from
  ReplicatedStorage.FxMeshes (small glowing balls until the import), ground glows / discs are plain cylinders, the
  Secret burst is two Trails behind invisible movers (no assets) every Config.CatFx.BurstEvery = 3 s. Studio (Play):
  4 test cats built (13-19 effect parts each), the burst ribbons fly and fade, no errors. The mesh path waits for the
  developer's import (then check the import turn / sizes in Studio).
- 2026-11-09 V5j meshes imported by the developer (ReplicatedStorage.FxMeshes, Model "Effects"): all 78 found, sizes match
  FxMeshData. Studio: flames upright with core and glow lined up, bats / hearts / notes / stars facing out, Sun God
  wheel behind, scan ring, UFOs, magic circles as in Blender. Effect parts per cat: Mythical avg 33 (most 60), Secret
  avg 38 (most 63); whole cat avg 93 / 109 parts. CatPreview: one grid spacing for the biggest cat.
- 2026-11-09 V5j approved in game ("ผ่าน"). V3 part 2 (ground detail): new MapKit decorations (tuft, grassPatch, sprigs,
  pebbles, mushroom, fern, log, leafPile / sakura petals, snowMound, sapling, icePatch, cobbles, flowerPot, sack,
  crystalBits) and MapTools/Detail scatters clumps per zone (Detail.Clumps 380 / 340 / 330 / 380 / 120) only where a
  ray hits bare ground with nothing within 2.6 studs (never on roads, water, houses, hiding spots), into
  Map.Zone<i>.Details (Detail.clear() removes them). 22,000 parts, all decoration (no collision / queries / touch /
  shadow). Studio: `!wild` 18 hiding in every zone; Backyard 51 -> 49 fps with them. Self-check: details made ~1.5x
  bigger (too small to see), darker cobbles on the market paving, pink petals instead of autumn leaves in the sakura
  forest, saplings in the snow (white mounds vanished). Pictures: art/preview/v3/details_before_after.png.
- 2026-11-09 developer: "ลบได้": ServerStorage.MapBackup_V3 (19 fountains, 79 creeks, 47 waterfalls, 3,915 instances) deleted in
  Studio; Upgrade.undo has nothing to put back any more. Waits for the developer's Save / Publish.
- 2026-11-13: phase 5 W1. Fishing bar in fixed ticks with tick-stamped holds, server confirms 0.5 s behind (Studio with
  IncomingReplicationLag 0.2 = 460 ms ping: 0 corrections, the bar never jumps back); HOLD follows each touch until it
  lifts. Bat: the victim goes into the Physics state for the stun (Studio: non-carrier 1.4 -> ~40 studs, carrier
  ~80-100). Event arrow: 3 Blender looks (A cartoon with a white rim, B LEGO pixel, C chevrons) for the developer.
- 2026-11-13: arrow look A picked. `art/blender/arrow_export.py` -> `art/export/EventArrow.fbx` (ArrowBody tinted + white
  ArrowRim, 1,280 tris); EventController clones ReplicatedStorage.EventArrow (SmoothPlastic, soft light, bobs) and until
  it is imported draws a part arrow with a proper two-wedge head (checked in Studio with !mythical). Import = developer.
- 2026-11-13: phase 5 W3 in Studio: new HUD (grid 70%, big bottom-left stats, frameless gear), My Cats multi-select
  (FreshSave: 3 chosen incl. 1 locked -> "Sell 2", sold 2 for $81K, the locked one stayed), red line on the fishing
  bar, green rings at both own training spots (on the tiles and on the treadmill belt). Rojo had stopped mid-edit;
  restarted, the developer reconnected.
- 2026-11-13: item 18 was holes ("รู"), not a picture: a 1-stud raycast scan found long thin holes at the lobby edge
  (16 spots, the 20-stud lobby tiles and 24-stud zone tiles did not meet) and before the snow ledge (24 spots).
  BuildMap's zone-tile rule now overlaps both; `BuildMap.groundGaps()` added the 100 missing tiles to the place;
  rescan: 0 holes. Item 2 (developer's picture as the direction): `MapTools/Lego.apply()` puts Roblox's Studs surface
  (Plastic) on every ground tile, island top, road / curb and tree block (10,747 parts, `.undo()` restores);
  Build.all() runs it too. Waits for the developer's Save / Publish.
- 2026-11-13 developer: "ผ่าน" (holes + LEGO ground) and EventArrow.fbx imported into ReplicatedStorage. Checked: 2
  MeshParts, the tip faces LookVector once the importer's PivotOffset (90 degrees about X) is replaced (EventController
  does), Play with !mythical: the mesh arrow with its light, 6.3 studs over the root, pointing at the cat (dot 1.000).
- 2026-11-13: phase 5 W2 (phone fit), checked in Studio's phone view (749 x 381, touch, jump button): the place's
  StarterGui.ScreenOrientation Sensor -> LandscapeSensor (the client sets it too) so phones never turn the game to
  portrait; Kit.fit / Kit.scaleFor = one scaling rule (shorter side, follows rotation) with a touch floor of 0.7 so
  the left buttons stay finger-sized; the left grid's bottom stays above the bottom-left stats (they overlapped);
  windows fit under Roblox's top bar (GetGuiInset); fishing: HOLD sits left of Roblox's jump button on small and big
  touch screens (it covered the big one), the bar panel left of HOLD, the hint line left of the panel; the event
  countdown moves under the gear on touch (the jump button covered it); the tutorial bubble hides while fishing and
  while a window is open (it covered both). Text in the big windows is small on the smallest phones (window scale
  ~0.5): the shop becomes big swipe cards in W4. Waits for the developer's Save / Publish (ScreenOrientation).
- 2026-11-13: W4 look A picked ("A card rail"). UI/ShopCard (rail of 140-px cards, swipe, settles on the nearest
  card, arrows 3 cards at a time, opens on the item in use with the next one beside it); the Shop window is 700 x 340
  so a phone keeps it at ~0.8 (Studio phone view: readable); every tab is cards (rods with 3 stat lines, shoes,
  treats, crates with every tier's chance in its colour, Robux with the Creator Hub icon). Pen tab removed; pen slots
  at a board in front of your own pen (PenBoardController, client-built, SurfaceGui button + prompt; FreshSave: Buy
  $2K -> 10 to 15 slots, next $4.2K). Known, older than W4: the crate meshes show grey in the game (textures load;
  the crates' UVs / palette do not match), the shop shows them grey too.
- 2026-11-13: W4 follow-ups (developer: "Yes, fix both"). Grey crates: the meshes are coloured in the world; a
  ViewportFrame does not redraw when a texture finishes loading, and the crate palette was never used before the
  shop, so the shop / opening pictures stayed grey. ItemPortrait now preloads the model's textures and re-adds it;
  the shop preloads ReplicatedStorage.ItemModels at start (Studio: the 4 crates in colour). Tool icons (item 3):
  `art/blender/tool_icons.py` -> ui_icons/P13_rod.png, P14_bat.png (Blender, dark outline); ToolService sets
  Tool.TextureId from Config.UIIcons.Rod / Bat once the developer uploads them (0 = names as before).
- 2026-11-13: tool icons uploaded by the developer (P13_rod 137425277592316, P14_bat 71320313933012), checked in
  Studio (GetProductInfo: image, group 565190385, preload Success) and put in Config.UIIcons; in Play both tools
  carry their TextureId (Studio captures do not show Roblox's own hotbar, so the look is the developer's check).
- 2026-11-13 developer: "ผ่าน" (W4) + the left HUD (buttons, stats) and the right one (gear, event) closer to the
  phone's edges. Roblox keeps ScreenGuis inside the device safe area (the Studio phone: 62 px each side); Kit.edge /
  Kit.edgeX now put those groups 45% of that gap from the real edge (min 10 px; ClipToDeviceSafeArea off): Studio
  phone view 76 -> 28 px from the edge on both sides, clear of a notch; a PC keeps ~10 px.
- 2026-11-13: W5 option B picked ("B~53 hours") and put in Config: Rebirth.StrengthMult 3.95 -> 3.8, Rods.CostGrowth
  2.15 -> 5.5, PenUpgrade.CostGrowth 2.1 -> 14, crates 40K / 2.5M / 75M / 900M (were 2K / 25K / 150K / 900K) x3.4 a
  rebirth (was x3); the rebirth texts say x3.8. tools/sim/endgame.luau on the real Config: rebirth 25 at 52h49, rod 25
  at 34h45, 60 pen slots at 11h27, Diamond crate ~5-8 min of income. Studio: the new prices load. Saves keep what was
  bought; nothing to convert.
- 2026-11-13: W6 training boosts: saves BoostWeights / BoostTread (0..6, sanitized), products TrainW1-6 / TrainT1-6
  (Kind TrainBoost, ids 0 until the developer creates them; a step is kept even if bought out of order, never goes
  down, receipt recorded in the same save change), Bonus.strength x2^steps, Bonus.speedGain for the treadmill.
  UI/WorldBoard (shared with the pen board): a board beside your own weights and treadmill "x8 STRENGTH · Now x4 ·
  forever · [R$ ..]" (Roblox's purchase prompt), and the next step of each in the Robux tab. Studio (FreshSave):
  `!buy TrainW1`, `!buy TrainW2` -> 4 s of lifting 8 -> 32 Strength. docs/Sweetpotato_Robux.xlsx rows 18-29 added
  (suggested 5 / 10 / 20 / 40 / 80 / 160 R$, the client confirms).
- 2026-11-13: the developer created the 12 boost products (TrainW1-6 3730700282 .. 3730700439, TrainT1-6
  3730700488 .. 3730700690), checked in Studio (GetProductInfo: names match, on sale, 4 / 8 / 15 / 30 / 60 / 120 R$ =
  the regional price of 5 .. 160) and put in Config; Play: both boards show "x2 · R$ 4". The products are named
  TrainW1 .. in Creator Hub (players see that in the prompt): renaming them is in DEVELOPER_TODO. The Robux sheet was
  open in Excel, so its id column was not written.
- 2026-11-13 developer: "ผ่าน" (W6) + Robux prices with the Robux coin icon instead of "R$". Format.robux uses the glyph
  U+E002 that Roblox's fonts draw as the Robux icon (checked in FredokaOne in Studio; no upload); the Robux tab and
  the boost boards use it. The 12 boost products still have Roblox's default grey icon (shown on their shop cards).
- 2026-11-13: W7 bigger pens, option B picked ("B x2.5"): Config.World.Pens 40 x 34 -> 44 x 56 (Ring 100 -> 111, the
  front at r 83 as before, so the sign, spawn, weights and treadmill did not move); BuildMap.pens() rebuilds only
  Lobby.Pens (and Build.lobby uses it) and moves the 16 flower beds from 9 to 13 degrees off the pens' centre lines.
  Run in Studio: the pens' cat area 34 x 18 -> 38 x 40 (x2.5); the pen board is now placed from the gate sign. Play:
  !fillpens 60 -> 60 cats spread over the whole area (x -19..16, z -16..20), boards where they were. Found and fixed
  on the way: !fillpens (V5i) failed (Config.Pens -> Config.World.Pens). Waits for the developer's Save / Publish.
- 2026-11-13 developer: "ผ่าน" (W7). Phase 5 (revision list 3) done: all 21 items, status table in docs/revision3_plan.md.
- 2026-11-13: client page for revision list 3 (developer's ask): https://claude.ai/artifact/9ZTmKiw3P3HGqWmrYXJtiN (Thai,
  the earlier client page's game theme, 21 items by the client's numbers in 5 groups, before / after captures from Studio,
  the arrow / pen option sheets, the economy summary; no scope or price statements; files in build/rev3_page, ignored).
