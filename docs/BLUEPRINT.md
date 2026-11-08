# Sweetpotatoturtlenix — Blueprint (approved by the client)

Original (published, Thai): https://claude.ai/artifact/3nUvFj5R3RTyLbKtYvs6n4
This file is the English copy of the approved blueprint and the developer's brief of 2026-11-08; both
match item for item. Anything not written here is NOT in the job and is priced separately.
Balance numbers marked "starting value" live in `src/shared/Config.luau` and are tuned after playtests.

The game: walk a 360° map, find hidden cats, catch them with a fishing rod against other players, carry
the cat back to your pen in the lobby while everyone tries to knock it out of your hands with a baseball
bat, then lift weights and run the treadmill to get strong and fast enough for heavier, rarer cats.
8 players per server, phone first. English default, Thai second (switch in Settings, saved).

## 1. Map (360°)
- The lobby is in the centre of the map: a **safe zone** (no hitting) holding the **8 player pens**.
- Around it, 5 ring zones from the inside out: **Backyard > Town Market > Forest > Snow Mountain >
  Sky Islands**. The further out, the rarer and heavier the cats.
- The next zone opens with a **minimum Strength or a Rebirth**; the zone gate says what is missing.
- Each zone has **30–60 hiding spots** (on roofs, in bushes, behind rocks, under bridges).
- A caught or escaped cat **respawns at another spot in 30–90 s**.

## 2. Catching with a fishing rod
- Strength must reach the cat's weight first (a 50 kg cat needs 50 Strength). If not, a message says
  the Strength needed.
- Cast the rod > the cat is hooked and struggles > **bar minigame**: hold to move the green zone so it
  covers the cat until the meter is full. Meter empty = the cat breaks free and hides somewhere new.
- Rarer cats move faster and change direction more often, and their green zone is smaller. A better rod
  makes the green zone wider and fills the meter faster.
- Meter full = the cat is caught: a card shows its name, tier and weight, and the cat is in your hands.

## 3. Fighting over a cat
- Several players can fish the same cat at the same time. The **first to fill the meter wins**; the cat
  leaves its spot and everyone else is dropped from the minigame at once.
- The winner **carries the cat automatically** (a cat icon floats above their head) and must run into
  the lobby and walk to **their own pen** to put it in. The cat starts earning at once.

## 4. Baseball bat
- Everyone has a bat in the hotbar (next to the rod), with a short cooldown.
- It hits anyone **outside the lobby**; players who are **fishing cannot be hit**.
- Hit while carrying a cat: the cat **drops where the hit happened** and the carrier is **knocked far
  away**. Everyone (the hitter included) can fish the dropped cat. If nobody catches it within **60 s**,
  it goes back into hiding at a new spot. This repeats until the carrier gets it into their pen.

## 5. Cats: 400 designs, 6 tiers
Made from several base body shapes with different colours, patterns and accessories (hats, wings,
auras); higher tiers have more effects.

| Tier | Designs | Weight |
|---|---|---|
| Basic | 150 | 1–10 kg |
| Rare | 110 | 10–60 kg |
| Epic | 70 | 60–300 kg |
| Legendary | 45 | 300–1,500 kg |
| Mythical | 20 | 1,500–8,000 kg |
| Secret | 5 | 10,000–50,000 kg |

- Every cat rolls its weight inside its tier's range. Heavier cats earn more.
- Basic–Legendary are all the same size. Mythical is 1.3–2x bigger and Secret 3–6x bigger, by weight.

## 6. Pens
- One pen per player in the lobby. Starts with **10 slots**, expands up to **60**.
- Cats walk around in the pen. Money goes **straight into the wallet** (no coin box to collect).
- **My Cats** window: view, sell, lock favourites.

## 7. Pen sign and likes
- In front of each pen: the owner's name + like count + a Like button.
- Whoever presses Like gets a **x2 speed buff for 5 minutes**. One like per pen per day.

## 8. Weights, 25 levels
- Stand at the spot and the character lifts by itself. Strength per rep by level. Strength has no cap
  and is always shown on the right of the screen.
- Upgrade with money at the sign next to the equipment. The look changes every 5 levels:
  **dumbbell > barbell > bench press > weight machine > giant barbell**.

## 9. Treadmill, 25 levels
- Next to the weights. Stand on it and the character runs by itself; it gives Speed. Upgrade with money.

## 10. Events
- **Mythical**: random every **10–20 minutes**, random spot. Server-wide announcement, a light beam into
  the sky, an arrow pointing the way, a countdown at the bottom right. Nobody catches it in **3 minutes**
  = it escapes.
- **Secret**: every **40 minutes**. A bigger announcement, the sky changes colour, event music, a huge
  cat, the hardest catch in the game.
- A caught event cat must be carried back to the pen like any other cat (and can be knocked loose).

## 11. Character progress
- **Rod, 25 tiers**: Wood > Iron > Gold > Crystal > Cosmic, 5 tiers each; wider green zone, faster
  meter, more luck; the look changes every tier.
- **Shoes, 8 pairs**: faster walking.
- **Rebirth, 25 times**: resets money, Strength, Speed, weights and treadmill levels; gives **x1.5 money
  and x1.5 Strength permanently**, opens new zones; cats and items stay.
- **Collection book, 400 cats**: unseen cats are black silhouettes; a full set gives a permanent bonus.

## 12. Shop (in-game money)
Tabs: Rods, Shoes, Pen, Treats, Crates. Prices are balanced against income before launch.
- Pen expansion.
- **Cat treats**, 10 minutes each: Lucky Treat (luck x1.5), Golden Fish (money x2), Catnip (easier
  minigame).
- **Cat crates**, 4 kinds, odds shown before buying, an opening animation, the cat goes straight into
  the pen. **No Secret in crates** (event only).

| Crate | Basic | Rare | Epic | Legendary | Mythical |
|---|---|---|---|---|---|
| Paper | 75% | 22% | 3% | – | – |
| Wood | 40% | 40% | 17% | 3% | – |
| Gold | – | 50% | 38% | 12% | – |
| Diamond | – | – | 62% | 37.5% | 0.5% |

## 13. Robux (the client confirms every price)
Game passes (5):
- **x2 Speed**: a big button on the left under Shop, softly blinking; once bought it becomes an on/off
  toggle. (Permanent or timed, and the price: waiting for the client.)
- **x2 Cash**, **x2 Strength**, **Lucky** (rare cats x2), **VIP** (VIP tag + money +10%).

Developer products (7, can be bought again):
- **+20 cat slots**: the price rises every purchase (several products in price steps).
- **Cash packs**, 4 sizes, based on the player's current income.
- **Strength pack**.
- **Luck x3, 15 minutes**.
- **Server luck, 15 minutes**: everyone in the server; the buyer's name is announced.
- **Summon a Mythical cat**: spawns at once, everyone can fight for it.
- **Starter pack**: once per player; a rod, money and treats.

NOT sold: auto-collect pass (money is automatic) and auto-lift pass (lifting is automatic).

## 14. Extra systems (8)
Daily login (7-day cycle, day 7 big reward) · Mutations (Gold / Rainbow / Glow, money x2–x10, Basic to
Legendary only) · Offline income (max 8 hours) · Daily quests · Playtime gifts · Leaderboards (money per
second + cat count) · Gift codes · Group reward.

## 15. Trading cats
In the same server: send a request > the other accepts > each side puts in **up to 6 cats** > both press
**Ready**, a **5 s countdown** (any change = press Ready again) > Confirm > the server checks both
sides still own everything, swaps at once and saves immediately. Leaving mid-trade cancels it (nobody
loses a cat). Locked cats cannot be traded. The pen must have room. Every trade is logged. Duplicated
cats must be impossible (100%).

## 16. HUD
Left: Shop, x2 Speed, My Cats, Trade · Right: Strength (kg) + weights and treadmill levels ·
Bottom-left: Speed and money · Bottom-centre: hotbar with bat + rod · Bottom-right: event countdown.

## 17. Art style
Bright Roblox-style blocks, bright green checkered grass, saturated colours, cartoon effects (waterfalls,
flower petals, glow). Each zone has a theme (e.g. a Japanese garden with red gates, pink blossom trees,
bamboo, waterfalls). Big bright UI buttons with icon + text. Everything made new; nothing copied from
other games (the client's reference pictures are only a direction).

## Milestones (8,500 THB: 500 deposit paid, then 2 x 4,000)
- **Milestone 1 (4,000, paid when it passes the test)**: 360 map + lobby + 5 zones + hiding spots,
  catching, fighting over cats + carrying home + baseball bat, weight vs Strength, data for all 400
  cats, pens + automatic money + sign / likes, weights + treadmill, HUD, Mythical / Secret events, saves.
- **Milestone 2 (4,000, paid at full delivery)**: shop, crates, 25 rods, shoes, rebirth, collection
  book, Robux store + x2 Speed button, the 8 extra systems, trading, all 400 cat models, animation,
  sound, game icon + thumbnails, full-server test.

## Terms
- Revisions: 2 rounds on things in this blueprint. Bug fixes: free for 30 days after delivery, delivered
  systems only.
- Delivery: the game in a Roblox group + a backup file; the group is transferred after approval and
  full payment.
- NOT included: custom music, promo video, advertising, more than 400 cat designs or a unique body shape
  for every cat, looking after the game after the bug-fix period, any system not in this blueprint.

## Waiting for the client (in Config with defaults; work does not wait)
- x2 Speed: permanent game pass or timed, and the Robux price.
- Roblox group: does the client have one, or does the team create it (pass / product ids are 0 until then).
- Keep shoes alongside the treadmill (both add speed), or drop the shoes.
