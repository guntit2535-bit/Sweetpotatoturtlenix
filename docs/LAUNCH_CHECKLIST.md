# Launch checklist (task 2.25)

Status: ✅ passed (Claude, Studio Play / tests) · 🔶 the developer must try it (2+ players, a real phone, the
live game) · ⬜ not done yet.

Before every test: GitHub Desktop -> Fetch origin -> Pull origin, and `rojo serve` connected in Studio.
Debug commands (`!help` in chat) work in Studio and for the developer until Debug is switched off (D3).

---

## A. The blueprint, item by item

| § | What the client gets | Status | Tested / how to try it |
|---|---|---|---|
| 1 | 360° map: lobby safe zone with 8 pens, 5 ring zones, gates by Strength or Rebirth, 30-60 hiding spots per zone, cats respawn in 30-90 s | ✅ | Each zone: 18 cats on 60 spots. Gate message shows what is missing. Walk out of the lobby to Backyard, try the Town Market gate with a new save. |
| 2 | Catching: Strength >= weight (message otherwise), cast -> bar minigame, rarer = harder, better rod = easier, card on catch | ✅ | Studio Play: caught Basic in 10-15 s, Need Strength message, escape on empty meter. Balance from `tools/sim/fishing.luau`. |
| 3 | Fighting over a cat: first full meter wins, the others are dropped; winner carries it home | 🔶 | Server picks one winner (1 player tested). **2 players**: both fish the same cat; both screens must agree on the winner. |
| 4 | Baseball bat: hits only outside the lobby, never someone fishing; a carrier drops the cat and flies; cat back in hiding after 60 s | 🔶 | Drop tested with `!drop` (cat on the ground, fishable). **2 players**: hit the carrier outside the lobby; try inside the lobby and on someone fishing (no hit). |
| 5 | 400 cats, 6 tiers, weights by tier, Mythical 1.3-2x and Secret 3-6x size | ✅ | All 400 designs x 4 mutations built in Studio (1,600 builds, 0 failures). Tier and weight rules in `tests/Cats.spec.luau`. |
| 6 | Pens: 10 slots up to 60, cats walk inside, money straight into the wallet, My Cats (view, sell, lock) | ✅ | Studio Play: delivery, income per second, sell, lock. |
| 7 | Pen sign: name, likes, Like button -> x2 speed 5 min, one like per pen per day | 🔶 | **2 players**: like the other pen; a second like the same day is refused. |
| 8-9 | Weights and treadmill, 25 levels each, look changes every 5 levels, automatic lifting / running | ✅ | `!level weights 25` shows each look; Strength / Speed gains while standing on them. |
| 10 | Events: Mythical every 10-20 min (3 min to catch), Secret every 40 min (sky colour, event music, huge cat) | ✅ | `!mythical`, `!secret`, `!eventin`, `!endevent`: banner, light beam, arrow, countdown, escape. Event music waits for its sound id (§ sound). |
| 11 | Rods 25 tiers, shoes 8 pairs, rebirth 25 times (x1.5 money / Strength), collection book with bonuses | ✅ | Studio Play with `!money`, `!strength`: buy, rebirth, book silhouettes and bonus. |
| 12 | Shop tabs (Rods, Shoes, Pen, Treats, Crates), treats 10 min, crates with odds shown, no Secret | ✅ | 2026-11-08 `!crate <kind> 20000`: Paper 75.5 / 21.7 / 2.8 %, Wood 40.6 / 39.3 / 17.0 / 3.1 %, Gold 49.9 / 38.1 / 12.0 %, Diamond 62.2 / 37.3 / 0.48 % (all match the table). |
| 13 | Robux: 5 passes, 7 products, x2 Speed button (on / off once owned), no auto-collect / auto-lift pass | 🔶 | Every grant path tested with `!pass` and `!buy` (receipt saved before granting, never twice). **Ids are 0** until the passes / products exist in the group's experience (C10); then one real purchase live (B4). |
| 14 | Extra systems: daily login, mutations, offline income, daily quests, playtime gifts, leaderboards, codes, group reward | ✅ | Studio Play (`!newday`, `!playtime`, codes SWEETPOTATO / MEOW, group 565190385). |
| 15 | Trading: same server, up to 6 cats, Ready + 5 s countdown, swap checked on the server, both saved, logged, no duplicates | 🔶 | `tests/Trade.spec.luau` proves no cat is copied or lost; window tested alone. **2 players** (B2). |
| 16 | HUD layout (left buttons, Strength right, Speed / money bottom-left, hotbar, event countdown) | ✅ | Studio screenshots; phone layout in B3. |
| 17 | Art: bright blocks, checkered grass, a theme per zone | ✅ | Approved map and cat style (2026-11-08). |
| M2 | Animation: cats (idle, walk, struggle, carried, sleep), players (cast, reel, carry, swing, lift, run) | ✅ | Studio Play: reel and carry poses, cast / swing, cat clips. |
| M2 | Sound: system + Settings switches (saved) | 🔶 | Wiring tested with dummy ids. **Ids from the developer** (`docs/Sweetpotato_Sounds.xlsx`). |
| M2 | Game icon + thumbnails | 🔶 | Prompts ready (`docs/gpt_store_prompts.md`); pictures by the developer. |
| M2 | Full-server test | 🔶 | B1. |
| — | English by default, Thai in Settings, saved | ✅ | `tests/Text.spec.luau`: every text has EN + TH with the same placeholders. Try a new save on a phone (B3). |
| — | Saves | ✅ | ProfileStore, key `Sweetpotato_PlayerData_v1` (never renamed); progress kept after rejoining (API Services on). |

## B. Tests only the developer can do

1. **Full server**: Studio -> Test -> Clients and Servers -> 8 players -> Start (if the PC cannot run 8, use 4 plus
   friends in the published game). Everyone gets their own pen, the sign shows the right name, no red lines in
   Output. Watch the server memory in the Developer Console (F9 -> Memory).
2. **2 players**: the same cat (A3), the bat (A4), likes (A7) and a trade (A15): Trade -> Ask -> Accept -> add
   cats -> both Ready -> after 5 s the cats swap and stay after rejoining; changing an offer clears Ready; a
   locked cat cannot be added; leaving mid-trade cancels it.
3. **A real phone**, new save (`!reset`), 15 minutes: catch -> carry -> pen -> weights -> shop -> crate -> Settings
   (Thai, Music / Sound effects). Every button reachable, nothing covered by the thumb buttons.
4. **One real purchase** in the published game (the cheapest product), then rejoin: it must still be there.
5. Send screenshots / a short video of anything wrong: Claude fixes it.

## C. Creator Dashboard before going public

| | Item | Status |
|---|---|---|
| C1 | Name **Sweetpotatoturtlenix** | ⬜ |
| C2 | Description EN + TH (Localization -> Thai) from `docs/gpt_store_prompts.md` | ⬜ |
| C3 | Icon 512 x 512 + 4 thumbnails 1920 x 1080 | ⬜ (GPT, then Claude sizes them) |
| C4 | Max players **8** (a Studio Play still showed 60) | ⬜ |
| C5 | Maturity & Compliance questionnaire, answered truthfully: cartoon baseball bat hit that knocks players back (no blood, no damage), **no paid random items** (crates use in-game money only; odds shown), trading between players | ⬜ |
| C6 | Genre: Simulation (or the closest collecting / pets option) | ⬜ |
| C7 | Devices: Computer, Phone, Tablet (no Console: the UI is not made for gamepads) | ⬜ |
| C8 | Language: source English, Thai added | ⬜ |
| C9 | Private servers: off (not in the blueprint) | ⬜ |
| C10 | 5 game passes + 12 developer products (Config.Products.List) created **in the group's experience** with the client's prices; ids sent to Claude (Claude puts them in Config and checks them from outside) | ⬜ |
| C11 | Game Settings -> Security -> API Services on | ✅ |
| C12 | Avatar type stays R15 (the arm poses support both, R15 tested) | ✅ |
| C13 | The x2 Speed choice (permanent pass or timed) and its price from the client (`Config.Passes.Speed2x`, default permanent) | ⬜ |

## D. Launch day, in this order

1. ⬜ Claude: put the pass / product ids and sound ids in Config; `lune run scripts/launch_check.luau` must say
   LAUNCH CHECK PASSED (today it fails on 5 pass ids, 12 product ids and Debug on); push.
2. ⬜ Studio: `workspace` attribute **FreshSave** removed (Claude does it at the end of milestone 2; check it is gone:
   with it, nothing is saved).
3. ⬜ In the game, type `!reset` on your own test save (money / cats from debug commands go; receipts stay).
4. ⬜ Tell Claude "ปิด Debug" (before step 1's final check) -> `Config.Debug.Enabled = false`, push. After this the `!` commands are gone, even in
   Studio (Claude can switch them back on for a fix).
5. ⬜ GitHub Desktop: Pull -> Studio: Rojo sync -> stop `rojo serve` -> **File -> Publish to Roblox** (the group's
   game, place 85516549821714).
6. ⬜ Dashboard: set the game **Public**.
7. ⬜ File -> Save to File: `Sweetpotatoturtlenix_launch.rbxl` (the backup for the client).
8. ⬜ Join from the Roblox website on a phone once: it plays, no `!` commands, prices show in the store.
9. ⬜ After any later publish: Dashboard -> "Shut down all servers" so everyone gets the new version.

## E. Handover

1. Claude writes the delivery message (Thai, finished work only, grouped by system) and the client page.
2. The client tests and approves on Fastwork; milestone 2 (4,000 THB) is paid.
3. Only then: the client joins group 565190385 -> Configure Group -> Settings -> make the client Owner. Keep your
   own `.rbxl` backup.
4. Log the approval date in `docs/PLAN.md`: bug fixes free for 30 days after it, delivered systems only;
   2 revision rounds on blueprint items.
