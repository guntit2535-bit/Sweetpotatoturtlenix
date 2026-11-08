# Sweetpotatoturtlenix

Roblox multiplayer cat-catching game for a client (Fastwork job): find cats hidden around a 360° map,
fish them out with a rod against other players, carry them home to your pen while others knock them
loose with baseball bats, and train Strength / Speed for heavier, rarer cats. Bright Roblox-block look,
kid-safe, phone first. Read `docs/BLUEPRINT.md` (scope, numbers) and `docs/PLAN.md` (tasks, plan
changes, log) first in every session. Follow the `roblox-client-game` skill.

## Agreed with the client
Source of truth: `docs/BLUEPRINT.md` = the approved blueprint
(https://claude.ai/artifact/3nUvFj5R3RTyLbKtYvs6n4) + the developer's brief of 2026-11-08 (they match
item for item). Anything not written there is NOT in the job and is priced separately. Balance numbers
are starting values: they live in Config and are tuned after playtests (simulate first, options table).

- Game name **Sweetpotatoturtlenix**. **8 players per server** = 8 pens in the lobby. **Phone first**
  (PC must work too).
- Price **8,500 THB**: 500 deposit paid; then **milestone 1 = 4,000** (paid when the developer's /
  client's test of milestone 1 passes) and **milestone 2 = 4,000** (paid at full delivery).
- Milestone 1: 360 map + lobby + 5 zones + hiding spots, catching (rod + bar minigame), fighting over
  cats + carrying home + baseball bat, weight vs Strength, data for all 400 cats, pens + automatic money
  + sign / likes, weights + treadmill (25 levels each), HUD, Mythical / Secret events, saves.
- Milestone 2: shop, crates, 25 rods, shoes, rebirth, collection book, Robux store + x2 Speed button,
  the 8 extra systems (daily login, mutations, offline income, daily quests, playtime gifts,
  leaderboards, codes, group reward), trading, all 400 cat models, animation, sound, game icon +
  thumbnails, full-server test.
- Revisions: 2 rounds on things in the blueprint. Bug fixes: 30 days after delivery, delivered systems
  only.
- Delivery: the game in a Roblox group + `.rbxl` backup. The group is transferred to the client only
  after approval and full payment (the client joins first).
- Language: **English is the default for every player**, Thai selectable in Settings, the choice is
  saved.
- Monetization (blueprint §13): 5 game passes (x2 Speed, x2 Cash, x2 Strength, Lucky, VIP) and 7
  developer products (+20 slots in price steps, 4 cash packs by income, strength pack, luck x3 15 min,
  server luck 15 min with announcement, summon Mythical, starter pack once). **No auto-collect and no
  auto-lift pass.** The client confirms every Robux price. **No paid random items**: crates are bought
  with in-game money only (odds are still shown before buying; no Secret in crates).
- NOT included: custom music, promo video, advertising, more than 400 cat designs or a unique body
  shape for every cat (400 = base shapes x colours x patterns x accessories), live operation after the
  bug-fix period, any system not in the blueprint.
- Art: bright Roblox-style blocks, green checkered grass, saturated colours, cartoon effects, a theme per
  zone. Everything made new; the client's reference pictures are only a direction.

### Waiting for the client (defaults in Config, work does not wait)
- x2 Speed: permanent game pass or timed, and its price -> `Config.Passes.Speed2x` (default: permanent).
- Roblox group: **done 2026-11-08**: the team created group "Sweetpotatoturtlenix" (565190385, owner
  GUN2535551) with the experience (GameId 10775309921, place 85516549821714) -> `Config.GroupId`.
  Pass / product ids stay 0 until they are made in that experience.
- Shoes: keep them next to the treadmill or drop them -> `Config.Shoes.Enabled` (default: keep).

### Scope changes
(Dated entries, each with "the client should be told" when it changes the blueprint.)
- none yet

## Stack and layout
- Rojo 7.7.1 + Lune 0.10.4 (pinned in `rokit.toml`), Luau with `--!strict` in every file,
  ProfileStore (`src/server/Packages/ProfileStore.luau`, Apache 2.0, `third_party_licenses/`) for saves.
- `src/shared` -> ReplicatedStorage.Shared · `src/server` -> ServerScriptService.Server
  (`Services/*` loaded by `init.server.luau`) · `src/client` -> StarterPlayerScripts.Client
  (`Controllers/*` loaded by `init.client.luau`). Each module is loaded with pcall: one failing module
  never stops the others.
- Every number in `src/shared/Config.luau`; every word a player sees in `src/shared/Text.luau`
  (EN + TH, same placeholders, checked by `tests/Text.spec.luau`).
- Maps and imported meshes live in the place file. The map is built from Studio parts by
  `src/server/MapTools` (MapKit props + BuildMap layout from `Config.World`; never required by the running
  game), run from the Command Bar / Studio MCP:
  `require(game.ServerScriptService.Server.MapTools:Clone().BuildMap).all()`. The place uses
  StreamingEnabled (target radius 600): a far part may not exist on a client. Art comes from Blender scripts in `art/`; flat art (icons, store cards, UI
  look, game icon, thumbnails) from GPT pictures made from Claude's prompts.
- Log prefix in Output: `[Sweetpotato]`.
- Save key: `Config.Data.StoreName = "Sweetpotato_PlayerData_v1"`. **Never rename it.**
- GitHub: `guntit2535-bit/Sweetpotatoturtlenix`, branch `main`. The developer uses GitHub Desktop.
- Local folder: `D:\Roblox\Sweetpotatoturtlenix` (drive D only: drive C is full).

## Check before every commit
```
lune run scripts/check.luau          # syntax + --!strict + tests/*.spec.luau
rojo build -o build/check.rbxlx
```
Engine behaviour (physics, UI, DataStores, purchases, phones) can only be tested in Studio: say so.

## Rules
- Talk to the developer in **Thai**, short, outcome first. Code, comments, commits and `docs/` in English.
- **One task at a time.** After a task: mark `[~]`, Log line, commit, push, give numbered test steps
  starting with "GitHub Desktop: Fetch origin -> Pull origin", end with
  `ผ่าน → พิมพ์ "ผ่าน" · มีปัญหา → เล่าอาการ`. The next task starts only after "ผ่าน".
- **Never change what was not asked.** If asked "did you change X?", answer from `git log -p`.
- **Server authority**: money, Strength, Speed, distance, cooldowns, every random roll, the minigame
  result and every bat hit are decided on the server. Clients only ask. Every client -> server remote is
  type-checked (arguments are `unknown`) and rate limited; limiter state is cleared on leave.
- **Save before you show**: purchases, crate results, trades, rebirths are saved before the client sees
  them. Saved data: no Instances, no Vector3 / Color3, no mixed tables, no gaps in arrays.
- **Robux**: one `ProcessReceipt`, the receipt id is recorded in the same change as the grant, never
  granted twice, `NotProcessedYet` when the profile is not loaded.
- **Trading**: every cat has a unique id; the swap checks both sides own every cat, is done in one step
  on the server and both saves are written; a duplicated cat must be impossible.
- **Assets belong to the group that owns the game** (meshes, images, sounds, animations).
- **Original work only**; kid-safe, no blood. The developer picks every sound id.
- **Never edit Rojo-managed scripts inside Studio.** Stop `rojo serve` before a big pull.
- Show the real look (renders / mockups, 2-4 labelled options) before building what players see; once a
  style is approved, build the rest without asking again.
- Ideas or removals that change the agreed scope: say so once, follow the developer's decision, record
  it under "Scope changes" (dated) and in `docs/PLAN.md`.
