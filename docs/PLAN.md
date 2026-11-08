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
- [~] 1.9 Pen sign + likes: owner name, like count, Like button; liker gets x2 speed 5 min; one like per pen per day (saved). Reuse: PSE `Controllers/FarmSignController`, HR `PenService` (signs), BA `FarmSignController`
- [x] 1.10 Wild cats: spawn by zone odds at the hiding spots tagged in A4 / A5, respawn at another spot in 30-90 s, tier / weight label, "need X Strength" message. Reuse: PSE `SpawnService`, `shared/Spawning`, `Controllers/CreatureTagController`
- [x] 1.11 Rod + bar minigame: cast at a cat in range, hooked cat struggles, hold to move the green zone, meter fills / drains; the server simulates the cat and the bar from the player's hold input (seeded, rate limited) and decides the result; rarer = faster cat + smaller zone; rod tier hook for milestone 2; the Wood rod model (Blender) is made in this task. Reuse: PSE `CaptureService`, `shared/Contest`, `Controllers/ContestUI`, `CaptureController`
- [~] 1.12 Fighting over a cat: several players fish the same cat, the first full meter wins, the others drop out at once; caught card (name, tier, weight). Reuse: PSE `CaptureService` (multi-catcher, first to 100 wins)
- [x] 1.13 Carry home: the winner holds the cat over the head with a floating cat icon, walks into the lobby to the own pen, the cat goes in and starts earning. Reuse: HR `GrabService` (carry over the head), PSE `TrainService` / `shared/Escape` (delivery on entering the town)
- [~] 1.14 Baseball bat: hotbar tool next to the rod, short cooldown, server hit check (range, facing), no hits in the lobby or on players fishing; a hit carrier drops the cat where hit and is knocked far; the dropped cat is fishable by all, 60 s then back to hiding; the bat model (Blender) is made in this task. Reuse: HR `BatService`, `Controllers/BatSwingController`, `KnockbackController`
- [x] 1.15 Weights, 25 levels: stand at the spot = auto lift, Strength per rep by level, upgrade sign (money), 5 looks (dumbbell > barbell > bench > machine > giant barbell). Reuse: PSE `TreadmillService`, `shared/Treadmill`, `Controllers/TreadmillController`, `TreadmillTierUI`, `StandController`
- [x] 1.16 Treadmill, 25 levels next to the weights: stand = auto run, Speed, upgrade with money; walk speed from Speed. Reuse: PSE `TreadmillService`, `shared/Speed`, `SpeedTrail`
- [x] 1.17 ★ HUD (phone first): left Shop / x2 Speed (blink) / My Cats / Trade, right Strength + weights / treadmill levels, bottom-left Speed + money, bottom-centre hotbar (bat + rod), bottom-right event countdown, Settings; UI look options first (GPT style board). Reuse: PSE `client/UI/Style`, `Window`, `Icons`, `Controllers/HudController`, BA `client/Ui/HudLayout`, `Kit`
- [x] 1.18 Events: Mythical every 10-20 min, Secret every 40 min; server-wide announcement, light beam, arrow, bottom-right countdown, 3 min then it escapes; Secret: bigger announcement, sky colour change, event music hook; caught event cats are carried home like others. Reuse: PSE `MythicEventService`, `GoldenEventService`, `Controllers/ZoneFx`, BA `LightingController`, SP `EventService`
- [~] 1.21 Milestone 1 check: 2+ players and a phone test, fixes, play video + test notes for the client

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
