# Milestone 1 — task specs

Each task: what to build, the files, what to reuse, "Done when". Numbers go in `Config`, words in
`Text`. Every new client -> server remote: arguments typed as `unknown`, checked, rate limited.
Repo tags (PSE, BA, HR, SP) are explained at the top of `docs/PLAN.md`.
Order (developer 2026-11-08): 1.4, then the map and models A1-A6, then the code tasks 1.1 onwards.

## A1 Art direction (GPT)
- Build: `docs/gpt_map_prompts.md` (Thai how-to, English prompts, one picture per prompt): 2 lobby
  style options (A / B, same layout, different finish), then the 5 zones in the picked style in the same
  chat, each showing its hiding places (roof, bush, rock, bridge) with a cat peeking out.
- The developer saves the files as `art/source/gpt_map/<code>.png` (keep .webp if GPT sends it).
- Done when: the developer picked A or B and has 5 zone pictures they like.

## A2 Map layout plan
- Build: a top-down plan in studs as a private page: lobby safe circle radius, ring of 8 pens (pen
  size for 60 cats), each pen's weights + treadmill spot, 5 ring widths and where each zone's gate is,
  the hiding-spot kinds and counts per zone (30-60), walk times at the start speed and at a high speed,
  where Mythical / Secret spawn, part / triangle budget and the StreamingEnabled decision. Numbers go
  into `Config.World`.
- Done when: the developer approves the plan ("ผ่าน" or "1A ...").

## A3 Lobby
- Build: Blender kit for the lobby in the A1 look: checkered-grass plaza, safe-zone edge, 8 pens with
  sign boards, the weights in 5 looks and the treadmill per pen. Renders first (2-4 angles); after
  "ผ่าน" export FBX + box colliders (`<Kit>Data.luau`), the developer imports under the group, a
  `tools/lib` builder places it.
- Reuse: PSE `server/Util/MapKit`, `art/world2_export.py`, skill `references/art-pipeline.md`.
- Done when: the lobby stands in Studio as in the renders and a player walks through it without
  invisible walls.

## A4 Backyard (template zone)
- Build: the first ring zone in Blender (houses, fences, roofs, bushes, rocks, a small bridge), 30-60
  hiding spots exported as tagged points with their kind, the gate to the next zone. Renders first.
- Done when: the developer passes it as the standard for the other zones; the spot count is printed.

## A5 The other 4 zones
- Build: Town Market, Forest, Snow Mountain, Sky Islands in the A4 standard, one batch, renders first;
  each its own theme (e.g. red gates, pink blossom trees, bamboo, waterfalls), 30-60 spots, gates.
- Done when: the developer walks from the lobby to Sky Islands; spot counts are inside 30-60.

## A6 Cat look prototype
- Build: Blender renders of 2-3 base shapes with colour / pattern / accessory variants, one cat per
  tier, Mythical / Secret at their sizes.
- Done when: the developer approves the style used for all 400 cats (2.21).

## 1.1 Project base
- Build: `shared/Remotes` (every remote created by the server at start; the client waits with a
  timeout), `server/Util/Guard` + `RateLimiter` (per player per remote, cleared on leave),
  `shared/Validate` (finite numbers, string length / UTF-8, ids), `shared/Format` (1.2K, 3.4M, B, T),
  `client/Lang` (current language, `changed` signal), Settings button + window with the language
  switch (the server saves it once 1.2 exists).
- Reuse: PSE `shared/Remotes`, `Validate`, `Format`, `server/Util/Guard`, `RateLimiter`,
  `client/Lang`, `Controllers/SettingsUI`, `Services/SettingsService`.
- Done when: the check passes with specs for RateLimiter / Validate / Format; Play shows
  `[Sweetpotato] server ready` / `client ready`; the language switch flips the Settings window text.

## 1.2 Saves
- Build: `shared/DataTemplate` (money, Strength, Speed, weights / treadmill levels, cats as
  `{ id, kind, kg, locked }` with unique ids from a saved counter, pen slots, likes given per day,
  settings, receipt ids), `Services/DataService` (ProfileStore `Sweetpotato_PlayerData_v1`, session
  lock, kick on load failure, reconcile, leaderstats Money / Strength, owner's client data copy,
  `SaveAsync`), `Workspace.FreshSave` test profile in Studio (separate store).
- Reuse: PSE `DataService` + `DataTemplate`, BA `DataService` (FreshSave), `Controllers/DataController`.
- Done when: data survives a rejoin in Studio (API Services on); FreshSave starts clean and is never
  written to the real store; DataTemplate spec checks no Vector3 / Instance / mixed tables.

## 1.3 Debug commands
- Build: chat commands for admins (`Config.Debug.Admins`) and Studio: `!money`, `!strength`,
  `!speed`, `!givecat <kind> <kg>`, `!mythical`, `!secret`, `!reset`, `!level weights|treadmill <n>`.
- Reuse: PSE `DebugService` + `shared/Commands`, BA `DebugService`.
- Done when: each command works in Studio; a non-admin in a live server gets nothing.

## 1.4 Developer setup (the developer does it)
- The Roblox group (the client's, or one the team creates: CLIENT PENDING), the experience inside the
  group, the place published, Game Settings -> Security -> API Services on, max players 8. Send the
  group id, universe id and place id; Claude checks them from outside and puts them in Config.

## 1.5 Cat data (400)
- Build: `shared/Cats` generated by `tools/gen/cats.luau`: per tier the blueprint count (150 / 110 /
  70 / 45 / 20 / 5), each kind = base shape + colour + pattern + accessory (no two kinds the same),
  English name, tier; `shared/CatRules`: weight roll in the tier range (server Random), size rule
  (Basic-Legendary 1x, Mythical 1.3-2x, Secret 3-6x by weight), income from weight.
- Reuse: PSE `tools/gen/species.luau`, `shared/Creatures`, `shared/Income`.
- Done when: a spec checks 400 unique kinds, the counts, the ranges, sizes and that heavier = more
  income.

## 1.6 Economy simulation
- Build: `tools/sim/economy.luau` for 2-3 pacing options: income per kg, the 25-level weights and
  treadmill curves and prices, zone gates (Strength, Rebirth), sell price; time to reach each zone.
  Write `docs/economy.md`; the developer picks; the numbers go into Config.
- Reuse: PSE `tools/sim/economy.luau`, `speed.luau`, `docs/economy.md`.
- Done when: the developer picked an option ("1A ...") and Config holds it.

## 1.8 Pens
- Build: `Services/PenService`: a free pen on join (spawn there), freed on leave; slots 10 (max 60);
  cats in the pen wander; money every second into the wallet (`DataService.AddMoney`); My Cats window
  (list, sell with confirm, lock favourite).
- Reuse: PSE `CorralService`, `FarmService`, `Controllers/CorralLife`, `CreaturesUI`, HR `PenService`.
- Done when: `!givecat` puts a cat in the pen, money ticks up in the HUD, sell and lock work and save.

## 1.9 Pen sign + likes
- Build: sign with owner name + like count; Like button (ProximityPrompt / tap) for other players; the
  liker gets x2 speed for 5 minutes; one like per pen owner per day (saved by the liker, UTC day).
- Reuse: PSE `Controllers/FarmSignController`, HR `PenService` signs.
- Done when: two Studio players like each other once a day; the buff shows and ends after 5 min.

## 1.10 Wild cats
- Build: `Services/CatSpawnService`: each zone keeps N cats at random free hiding spots, rolled by zone
  odds and weight on the server; a caught / escaped cat comes back at another spot in 30-90 s; a label
  shows tier + kg; trying to fish a cat that is too heavy shows "Need X Strength".
- Reuse: PSE `SpawnService`, `shared/Spawning`, `Controllers/CreatureTagController`.
- Done when: cats appear in every zone, respawn at new spots within 30-90 s, labels read right.

## 1.11 Rod + bar minigame
- Build: `shared/FishingBar` (pure: cat movement from a seed + tier, green zone size, fill / drain per
  tick, rod bonuses), `Services/FishingService` (cast in range + Strength check, session per player,
  ticks the bar on the server from the player's hold on / off messages, rate limited; result decided
  on the server), `Controllers/FishingUI` (the bar, hold button for phone + mouse / space), the Wood
  rod model in Blender (renders first).
- Reuse: PSE `CaptureService`, `shared/Contest`, `Controllers/ContestUI`, `CaptureController`.
- Done when: a spec checks the bar math (rarer = harder, wider zone = easier); in Studio a Basic cat is
  caught by holding well and escapes when not.

## 1.12 Fighting over a cat
- Build: many players fish one cat; the first full meter wins; everyone else is dropped at once and
  told; the winner sees the caught card (name, tier, kg).
- Reuse: PSE `CaptureService` (multi-catcher, first to win).
- Done when: two Studio players fish the same cat and only one gets it.

## 1.13 Carry home
- Build: the winner holds the cat (model over the head + floating cat icon BillboardGui for all), walks
  into the lobby and to the own pen; touching the pen puts it in (saved), it starts earning. Pen full =
  a message and the cat stays held.
- Reuse: HR `GrabService`, PSE `TrainService` / `shared/Escape`.
- Done when: a caught cat ends up in the pen after walking there, and survives a rejoin.

## 1.14 Baseball bat
- Build: `Services/BatService`: a bat Tool for everyone next to the rod, cooldown, the server checks
  range and facing; no hits inside the lobby and on players fishing; a carrier hit drops the cat at the
  spot (fishable by all, the hitter too) and is knocked far; a dropped cat nobody catches in 60 s goes
  back to hiding. The bat model in Blender (renders first).
- Reuse: HR `BatService`, `Controllers/BatSwingController`, `KnockbackController`.
- Done when: with two Studio players a hit carrier drops the cat and flies; no hit in the lobby or on a
  fishing player; the 60 s return works.

## 1.15 Weights (25 levels)
- Build: a lifting spot by each pen: stand = auto lift every rep, Strength per rep by level (Config);
  an upgrade sign with the next price; 5 looks (dumbbell, barbell, bench, machine, giant barbell).
- Reuse: PSE `TreadmillService`, `shared/Treadmill`, `Controllers/TreadmillController`,
  `TreadmillTierUI`, `StandController`.
- Done when: standing raises Strength, the sign upgrades with money, the look changes at 6 / 11 / 16 / 21.

## 1.16 Treadmill (25 levels)
- Build: next to the weights: stand = auto run, Speed per tick by level, upgrade with money; walk
  speed from Speed (Config curve).
- Reuse: PSE `TreadmillService`, `shared/Speed`, `SpeedTrail`.
- Done when: Speed rises while running and the player walks faster.

## 1.17 HUD
- Build: UI look options first (GPT style board / mockup); then the HUD in the approved look: left
  Shop / x2 Speed (soft blink) / My Cats / Trade, right Strength (kg) + weights / treadmill levels,
  bottom-left Speed + money, bottom-centre hotbar bat + rod, bottom-right event countdown, a Settings
  button. Shop / Trade open "coming in milestone 2" until then.
- Reuse: PSE `client/UI/Style`, `Window`, `Icons`, `Controllers/HudController`, BA `Ui/HudLayout`, `Kit`.
- Done when: the developer approves the look and the phone layout (Studio device emulator + a phone).

## 1.18 Events
- Build: `Services/EventService`: Mythical every 10-20 min (random), Secret every 40 min, random spot in
  the right zone; announcement, light beam, arrow from the player, countdown bottom-right; 3 min then it
  escapes; Secret: bigger banner + sky colour + a music hook (the sound id comes in 2.23); caught event
  cats are carried home and can be knocked loose like any cat.
- Reuse: PSE `MythicEventService`, `GoldenEventService`, `Controllers/ZoneFx`, BA `LightingController`.
- Done when: `!mythical` / `!secret` run the whole flow; the timers keep their intervals.

## 1.21 Milestone 1 check
- 2+ players and a phone test of the whole loop, fixes, a play video and test notes for the client.
