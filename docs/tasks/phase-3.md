# Phase 3 — revision round 1 (developer's list, 2026-11-08)

The developer's 10 points, turned into tasks R1-R9 (points 8 and 10 are one pipeline: R5). Each task: what
the player sees, how it is built, how it is tested, and what the developer does. ★ = the developer approves
a render / preview before it goes into Studio (point 8: "ออกแบบในblender เสร็จแล้วส่งให้ผมตรวจถ้าผ่านค่อยเอาลงstudio").

| Developer's point | Task |
|---|---|
| 1 Cats in bushes: players cannot walk through | R1 |
| 5 Training locks the player at the right spot; only a jump ends it | R2 |
| 4 Every second a popup shows how much money the cats made | R3 |
| 9 Strength, Speed and money much bigger; top around 99 Sx | R4 |
| 8 Models and animations made in Blender, checked by the developer, then Studio · 10 every in-game item remodelled from GPT reference pictures | R5 |
| 3 Weights: two-hand curl, real weights in the hands, a new look every level (bigger, heavier, cooler) | R6 |
| 2 Treadmill: a new, cooler, slightly bigger look every level | R7 |
| 7 Crate opening: a 5 s animation (paper / wood / gold / diamond box, unboxing, reveal) | R8 |
| 6 New GUI / UI / UX from GPT designs | R9 |

Order: R1-R4 are code only and start at once; meanwhile the developer makes the GPT pictures for R5 (items)
and R9 (UI). R6-R8 need R5's pipeline and approved models. R9 last (it restyles every window, including the
new crate reveal).

---

## R1. Bushes you can walk through (bug fix)
- Cause (checked in Studio): the cats are already non-colliding, but **all 322 bushes on the map collide**
  (MapKit `Kit.bush`), so a cat hiding in a bush sits inside a wall.
- Fix: bushes (and their flower / snow decorations) `CanCollide = false`, `CanQuery` kept so casts and taps
  still find the cat. Fixed in `MapKit` for future rebuilds and patched in the place now (a small MapTools
  script, no full rebuild). Rocks, roofs and bridges stay solid (cats sit on them, not in them).
- Test: Studio Play: walk through bushes in every zone, still fish a cat hiding in one.

## R2. Training locks you in place; jump to stop
- Walking onto your weights / treadmill spot: the server snaps the character to the exact spot facing the
  machine and holds it there (MovementService factor `training` = 0 walk speed, AutoRotate off), and sets
  `Training`. Only a **jump** ends it: the client sees the jump and asks `StopTraining` (rate limited); the
  server also ends it if the character leaves the spot (knockback, teleport, death).
- After a jump the spot does not grab you again until you have stepped off it (no instant re-lock).
- Phones: the jump button is the exit; a small "Jump to stop" hint shows while training (EN / TH).
- Test: Studio Play: walk on -> snapped and locked, WASD does nothing, jump -> free, walk back on -> locked.

## R3. Money popups every second
- Every income tick (1 s) each of **your** cats in your pen shows a small "+$12" that floats up and fades,
  and the money pill on the HUD bumps with "+$total". Amounts come from the server: each pen cat model gets
  a `Rate` attribute (its money per second with every bonus), updated when bonuses change, so the popup
  always matches what is paid.
- Only your own pen, only cats within 80 studs of the camera, pooled labels (60 cats max), so phones stay
  smooth. Option for later: other players' pens too (off by default).
- Test: Studio Play with `!givecat`: popups match the money gained per second; no lag with 60 cats.

## R4. Bigger numbers, top around 99 Sx
- Assumption to confirm: "99SX" = **99 sextillion** (99 x 10^21), the top of the late game (25 rebirths,
  best zone) for money; Strength and the Speed stat on a similar scale. Format already writes K M B T Qa
  Qi Sx.
- Strength must still match cat weight, so **cat weights scale with it** (Basic stays small, Secret reaches
  the top). This changes the blueprint's weight table (§5) and the shop / crate / rebirth prices: a scope
  change "the client should be told" (CLAUDE.md).
- Method (CLAUDE.md: simulate first): `tools/sim/economy.luau` with new curves (exponential growth per
  weights / treadmill level, per zone, per rebirth); a 2-3 option table (time to each zone, to each rebirth,
  to the top) for the developer to pick.
- Engine limits handled: numbers above 2^53 lose single units (fine for display and money at that size);
  the money leaderboard stores log10 x 1000 (OrderedDataStore holds integers up to ~9.2 x 10^18 only);
  walk speed still capped (Config.Walk.Max) while the Speed stat grows; existing saves are migrated once
  (scaled by the same factor), never wiped. Save key unchanged.
- Test: sim table, `tests/*` for curves and Format up to 99 Sx, Studio Play with `!money 90Sx`.

## R5. Blender pipeline + every item remodelled from GPT pictures (points 8 and 10)
Items: rods (25 tiers: Wood / Iron / Gold / Crystal / Cosmic x 5), baseball bat, shoes (8), treats (3),
crates (4), dumbbells (25 levels, R6), treadmills (25 levels, R7).
1. Claude writes `docs/gpt_model_prompts.md` (Thai how-to, English prompts): one reference picture per item
   family, front 3/4 view, plain background, same style sentence as the store pictures (smooth glossy
   blocks, no studs).
2. The developer makes the pictures in ChatGPT -> `art/source/gpt_models/`.
3. Claude models each in Blender from its picture (`art/` scripts, the shape kit), renders a labelled
   preview sheet ★. **Pilot first**: 1 rod, the bat, 1 crate, dumbbells level 1 / 13 / 25, treadmill level
   1 / 13 / 25. Only after "ผ่าน" the rest, one sheet per family ★.
4. Export: one FBX per family, a manifest (size, hold point) -> Luau data. The developer imports each FBX in
   Studio (3D Importer, Creator = the group) into `ReplicatedStorage.ItemModels` (a place folder, not Rojo).
5. Code swaps the part-built models for the meshes (rods / bat in the hand, shoes on the feet, treats and
   crates in the shop, gym pieces at the pens), with a turn / offset in Config.
- Animations (point 8): made as R15 KeyframeSequences from Blender-driven poses (`art/animations`), a
  preview GIF per animation ★, then the developer publishes each under the group (Animation Editor ->
  Publish, Creator = the group) and sends the ids. Cat clips stay code (already approved, A7).

## R6. Weights: two-hand curl with real dumbbells, a new look every level
- Animation ★: standing two-hand dumbbell curl, alternating arms, about 1.2 s per rep, loop (R5 animations).
  While it plays, a dumbbell is welded into each hand (RightHand / LeftHand grip).
- Looks ★: 25 levels = 5 families x 5 steps. Families (bigger and cooler): rubber, chrome, gold, crystal,
  cosmic; inside a family every level adds size (+6 %), plates and trim; the "kg" printed on the side
  grows. The rack at the pen shows the current pair; a level-up plays a short sparkle and swaps them.
- Replaces the current 5-look gym pieces (GymLooks).
- Test: Studio Play: `!level weights N` for N = 1..25 shows each pair; the curl plays on R15 with both hands
  holding; the lock from R2 holds.

## R7. Treadmill: a new look every level, slightly bigger
- Looks ★: 25 levels = 5 families x 5 steps (basic, sport, neon, gold, cosmic); each level adds trim /
  lights and +2 % size (level 25 is about 1.5x level 1). The run animation stays Roblox's run (point 2
  asks only for the machine); the speed lines / belt speed grow with the level.
- Test: `!level treadmill N` for N = 1..25; the R2 spot moves with the bigger machine.

## R8. Crate opening, 5 seconds
- Timeline ★ (preview rendered in Blender as a short video first): 0-1 s the crate (Paper / Wood / Gold /
  Diamond, R5 models) drops in and bounces; 1-3 s it wobbles faster and faster, glowing in the colour of
  the best possible tier; 3-3.6 s the lid pops off with a burst (confetti, rays); 3.6-5 s the cat jumps out
  in its tier colour light and the card shows name, tier, kg (and mutation). A tap skips to the reveal.
- Fair: the server rolls and saves before the client sees anything (already true); the animation only
  shows the result.
- Built in a ViewportFrame with the crate mesh and the real cat model; sound keys crate_shake /
  crate_reveal / crate_rare already exist.

## R9. New GUI / UI / UX from GPT designs
1. Claude writes `docs/gpt_ui_prompts.md`: a style board first (window, 6 button colours, tabs, switch,
   bars, stat pills, menu buttons, a card, a toast), then one mockup per screen (HUD, Shop, Robux, My
   Cats, Book, Rewards, Rebirth, Trade, Settings, crate reveal, fishing bar, event banner).
2. The developer makes the style board in ChatGPT -> approval -> the screens in the same chat.
3. Claude rebuilds the UI in code from them (not pasted images: text must switch EN / TH and numbers
   change), phone first, every button at least 44 px, safe areas. UI icons from GPT pictures where a
   mockup uses one (cut and sized like the store icons).
- Test: every window in Studio Play at phone (375 x 812) and PC sizes; the developer's phone test.

---

## What the developer does in this phase
- Answer: does "99SX" mean 99 sextillion, for money, Strength and Speed (R4)? Then pick a sim option.
- Make the GPT pictures: items (R5) and UI (R9), from the prompt files Claude writes.
- Check every render sheet / preview ★ and answer "ผ่าน" or what to change.
- Import the approved FBX files (Creator = the group) and publish the approved animations under the group.
- Test on a phone at the end of the phase; tell the client about the new numbers (R4).
