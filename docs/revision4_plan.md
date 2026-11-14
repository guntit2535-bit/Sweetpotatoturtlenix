# Revision list 4 (developer, 2026-11-14): 23 items

Source: the developer's chat message of 2026-11-14 (13 pictures + one 6 s phone video). Scope keys: **rev** = a
change to something in the blueprint, **new** = not in the blueprint, **del** = a removal. Size: S < 1 h, M = a few
hours, L = a day or more (art + Studio).

What the code does now was checked for each item (file in brackets).

| # | Asked | Now | What we do | Key | Size |
|---|---|---|---|---|---|
| 1 | No cat icon over the head while carrying | `CarryIconController` draws a floating cat icon over every carrier | Remove the icon; the carried cat itself stays on the head | rev | S |
| 2 | Left HUD: no square jelly boxes, no cat ears; open look like picture 2 | `Hud.leftButton`: jelly square + ears + icon + label | Icon only (bigger) with an outlined label under it and the red "!" badge; mockup first | rev | M |
| 3 | A home icon so players find their way back | Nothing | A house marker over your own pen, seen from anywhere (always on top, distance in m); when off screen an arrow at the screen edge | new | M |
| 4 | Tutorial: a line that leads to the cat and a line back home | Flowing chevrons; step 2 trains first (a new player has 1 kg) | A solid glowing line on the ground from the player to the target (cat, then pen); see question 4 for the order | rev | M |
| 5 | Stats icons (kg / speed / money) bigger | ~44 px icons | Icons about x1.6, text unchanged | rev | S |
| 6 | Treadmill and weights: 25 levels, not lost on rebirth | 25 levels each already (`Config.Weights/Treadmill.Levels = 25`); rebirth sets both to level 1 (`RebirthService`) | Rebirth keeps both levels; economy re-simulated (training stays fast after a rebirth); see question 3 | rev | M |
| 7 | Bottom right: when the Secret cat comes | Only "Mythical in mm:ss" (Secret every 40 min, `Config.Events.SecretEvery`) | A second pill "Secret in mm:ss" under the Mythical one | rev | S |
| 8 | Remove the benches and lamps in the middle of the map | Plaza benches + lamps (`BuildMap` lobby) | Removed (the shop and sell booth of 13 / 18 go there) | del | S |
| 9 | 7 crates with a price ladder, better crate models | 4 crates: Paper $40K, Wood $2.5M, Gold $75M, Diamond $900M | 7 crates (e.g. Paper, Wood, Iron, Gold, Ruby, Diamond, Cosmic), prices stepped between today's lowest and highest, odds shown, never Secret; new Blender models (renders first, 2-3 looks) | rev | L |
| 10 | Remove shoes from the game (the client does not want them) | Shoes tab + speed bonus (`Config.Shoes`) | `Config.Shoes.Enabled = false`: tab, items and bonus gone; the save field stays (never removed) | del | S |
| 11 | x2 cats; better water, as deep as a player is tall | 18 wild cats per zone; water is thin glass parts over a bed | 36 per zone (checked against the hiding spots); creeks and ponds rebuilt as real Terrain water about 6 studs deep (players swim in it) | rev | L |
| 12 | Nicer farm (pen) floor | LEGO-stud green floor | New floor look, 2-3 renders first | rev | M |
| 13 | Remove the Shop button; a small shop in the middle of the map | Shop button in the left HUD | A small shop stall in the middle; walking up to it opens the Shop window; the HUD button goes; tutorial step 6 points at the stall | new | L |
| 14 | Walls cut into the gate pillars; tidy the whole map, more detail | Wall rings meet the gates inside the pillars (`BuildMap.walls`) | Walls stop at the pillars; a detail pass zone by zone (paths, fences, props, edges), captures before / after | rev | L |
| 15 | Remove the yellow line | The glowing yellow ring (with light posts) round the lobby edge (`BuildMap` safe-zone edge; the video) | Ring and its posts removed | del | S |
| 16 | Carrying home: do not put the cat in by itself; keep holding, choose to put it in | Auto delivery inside the pen (`CarryService`) | At your pen a big "Put in pen" button; until pressed you keep carrying (bats can still knock it loose) | rev | M |
| 17 | Cat label: name and weight, no tier word, tier shown by the text colour | "Basic · 4.8 kg" | "Whiskers · 4.8 kg" in the tier's colour (Basic grey/white ... Secret teal) | rev | S |
| 18 | A small booth in the middle to sell a carried cat | Cats are sold from My Cats only | A sell booth next to the shop: carrying a cat there shows "Sell $X" (the same price as selling it from the pen) | new | M |
| 19 | Codes window ugly: the square box sticks out | Icon square overlaps the input row | Layout fixed (the box inside the row) | rev | S |
| 20 | Rebirth button on the right, bigger, stands out | Left grid | Big button on the right side | rev | S |
| 21 | Bat too hard to hit; a baseball swing animation | Range 9, arc 0.3 | Longer reach and a wider arc, with a soft aim to the nearest player in front; new baseball swing (KeyframeSequence; the developer uploads it to the group) | rev | M |
| 22 | Treadmill green ring under the treadmill, x2 bigger | Ring on the stand, radius 3.6 | Ring on the ground under the treadmill, radius x2 (weights the same) | rev | S |
| 23 | Remove the x2 icon and the x2 items from the store (too strong) | HUD x2 Speed button; store x2 Speed, x2 Cash, x2 Strength passes | Hidden from the HUD and store; owners lose nothing saved; see question 2 | del | S |

## Economy
Items 6, 9, 10 and 23 change the ~50 h end-game pacing (revision 3, option B). After they are built, re-run
`tools/sim/endgame.luau` and give 2-3 options before changing prices.

## Blueprint changes (the client should be told)
- §13 monetization: x2 Speed, x2 Cash, x2 Strength passes and the x2 Speed button removed (item 23).
- Shoes dropped (the open question "keep or drop shoes" answered: drop).
- New: home marker, shop stall, sell booth, put-in-pen choice, 7 crates, Terrain water.

## Build order (after the answers)
1. Quick fixes: 1, 5, 7, 10, 15, 17, 19, 20, 22, 23.
2. Rules: 6, 11 (cats), 16, 18, 21 + economy re-sim.
3. Looks with renders first: 2, 9, 12, 13 (+ 8, 18 stall), 3, 4.
4. Map: 11 (water), 14 detail pass.

## Developer's answers (2026-11-14)
1. Price: build first, talk price later. The new items (3, 9 extra crates, 11 water, 13, 16, 18) are marked **new**
   above so the developer can price them.
2. Item 23: only the three x2 passes (x2 Speed, x2 Cash, x2 Strength) and the HUD x2 button go; Lucky, VIP, the
   training boost ladder, cash / strength packs stay.
3. Item 6: the 25 levels stay as they are; rebirth no longer resets the weights / treadmill levels (economy re-sim).
4. Item 4: training stays first; the floor chevrons become a glowing line to the cat, then a line home.
