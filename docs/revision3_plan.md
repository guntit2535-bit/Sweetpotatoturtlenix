# Revision list 3 (developer, 2026-11-13)

Round 2 (phase 4) was the last free round of the agreement. Each item gets a scope key:
- **bug** = something delivered does not work as the blueprint says (free, bug-fix promise)
- **new** = a change or addition beyond the blueprint and the 2 rounds (the developer decides the price with the client)

Size: S = under an hour, M = a few hours, L = a day or more. ★ = a look is shown first (renders / mockups).

| # | Asked | What exists now | What we do | Key | Size |
|---|---|---|---|---|---|
| 1 | A nicer arrow over the head (Blender) | EventController: 2 neon parts; the head wedge is turned wrong, so it reads as an "L" | ★ Blender arrow mesh (3 options), event colour, bob + glow | bug (the head) + new (Blender look) | S |
| 2 | Ground, paths and trees as pixel + LEGO | Flat checker tiles, plain path parts, MapKit trees | ★ Studio captures of 2-3 looks (studded tiles, pixel-step paths, voxel trees), then rebuild with MapTools | new | L |
| 3 | Rod / Bat words -> icons | Roblox backpack shows the tool names | Icons from the Blender item renders on the tools (2 images, the developer uploads under the group) | new | S |
| 4 | New shop window: big item cards, swipe left / right (like picture 2) | Tabbed list of rows | ★ Mockup, then a card carousel (swipe on phones, arrows on PC) for every tab | new | M |
| 5 | Remove the Pen tab, buy pen slots at the farm (like picture 4) | Shop tab "Pen" | Pen tab removed; an "Upgrade pen" board at each pen (next price / MAX), tap to buy | new | M |
| 6 | Green circle at the weights so players know where to stand | Invisible stand spot | Glowing green ring on the floor at the weights and the treadmill spots (own pen only) | new | S |
| 7 | Bat hits really send players flying | BatService knockback | Stronger fling (ragdoll-style tumble + flight), tuned in Studio | bug (blueprint: "knocked far") | S |
| 8 | Phone fishing: the green bar jumps around, too hard | FishingBar / FishingController | Find the cause on a phone-sized view (input / smoothing / latency), steadier bar | bug | M |
| 9 | Economy: the end game at about 50 hours | Option B (docs/economy.md) | Simulate, options table of 2-3 paces to 50 h, the developer picks | new | M |
| 10 | Money, Speed, Strength big at the bottom left (picture 5) | Right column + small bottom-left | Big icon + number stack at the bottom left | new | S |
| 11 | Icon bar 30% smaller | Left column buttons | Scale 0.7 | new | S |
| 12 | UI fits every phone | Phone-first layout | Check at 5 phone sizes (small Android to iPad), fix overlaps, safe areas | bug (phone first) | M |
| 13 | Rebirth and Rewards to the middle left | Right column | Move to the middle of the left edge | new | S |
| 14 | Crates cost more | Config.Crates | New prices from the item 9 simulation | new | S |
| 15 | Bigger farm (60 cats is too crowded) | Pens in the lobby ring | Bigger pens: the lobby ring grows (MapTools rebuild of the lobby) | new | L |
| 16 | Fishing: a red line instead of the cat icon | Cat icon on the bar | Red marker line | new | S |
| 17 | Training boosts 2x 5 R$, 4x 10 R$, 8x 20 R$ ... | x2 Strength pass only | A ladder of developer products (the developer creates them, the client confirms prices) | new | M |
| 18 | A picture in the map | ? | Needs a screenshot / place | bug | S |
| 19 | Settings button: no frame, only the gear + "Settings" | Framed button | Frameless gear + label | new | S |
| 20 | Selling a cat: no "are you sure?" | Confirm dialog | Sell at once (locked cats still cannot be sold) | new | S |
| 21 | Pick several cats to sell at once | One at a time | Select mode in My Cats + "Sell N" (one server call, checked, saved before shown) | new | M |

## Proposed order
1. Bugs: 1 (head fix), 7, 8, 18, 12
2. Quick UI: 19, 20, 16, 11, 13, 10, 6
3. Shop and pen: 4 ★, 5, 21, 3
4. Economy: 9 + 14 (options table first), 17
5. World: 1 ★ arrow mesh, 15, 2 ★
