# Milestone 2 — task specs

Same rules as milestone 1 (numbers in Config, words in Text, server decides, save before show). Built in
long-run mode: Claude tests each task in Studio and logs choices under "Decisions to review" in PLAN.md.
Order: in-game shop group (2.1-2.5) > crates (2.6) > rebirth / book / mutations (2.7-2.9) > extra systems
(2.10-2.16) > trading (2.17) > Robux (2.18-2.20) > models / animation / sound / art (2.21-2.24) > full test (2.25).

## Shared: bonuses (`shared/Bonus`)
One place that multiplies everything: money (rebirths x1.5 each, x2 Cash pass, VIP +10%, Golden Fish treat x2,
mutations per cat), Strength gain (rebirths, x2 Strength pass), walk speed (Speed stat, shoes, x2 Speed pass, like
buff), luck (Lucky pass x2, Lucky Treat x1.5, luck x3 product, server luck) and fishing ease (rod level, Catnip).
Done when: a spec checks each multiplier alone and together.

## 2.1-2.5 Shop (in-game money)
- Window with tabs Rods / Shoes / Pen / Treats / Crates (crates 2.6). `BuyItem(category, id)`.
- Rods: 25 tiers (Wood, Iron, Gold, Crystal, Cosmic x I-V), bought in order; the best owned is used: wider zone,
  faster meter (FishingBar.params rod level) and luck; the held rod's colour follows the material.
- Shoes: 8 pairs in order (CLIENT PENDING: keep or drop; Config.Shoes.Enabled), each adds walk speed.
- Pen: +5 slots per purchase up to 60, price rising each time.
- Treats: Lucky Treat (luck x1.5), Golden Fish (money x2), Catnip (easier minigame), 10 minutes each, buying
  again adds 10 minutes; price follows the player's income.
- Done when: every item buys, saves, takes effect and shows "owned"; refusals for money / order / max.

## 2.6 Crates (in-game money)
Paper / Wood / Gold / Diamond with the blueprint odds, odds shown before buying, no Secret, server roll, saved
before the reveal, the cat goes straight into the pen (refused when the pen is full). `!crate N` runs N rolls for
the odds check.

## 2.7 Rebirth, 2.8 Collection book, 2.9 Mutations
- Rebirth (25): requirement per rebirth (Strength), resets money, Strength, Speed, weights and treadmill levels;
  keeps cats, rods, shoes, pen slots; x1.5 money and Strength per rebirth; opens zones by rebirth count.
- Book: 400 cats, unseen = silhouette (black card), seen when caught / from a crate / traded; a full tier = a
  permanent money bonus; the whole book = a bigger one.
- Mutations: Gold x2, Rainbow x5, Glow x10 (money), rolled on catch / crate for Basic-Legendary only, luck raises
  the chance; shown on the cat (colour / glow) and in My Cats.

## 2.10-2.16 Extra systems
Offline income (max 8 h, welcome-back window) · daily login (7-day cycle, day 7 big) · daily quests (3 a day) ·
playtime gifts · leaderboards (money per second, cat count; lobby boards) · gift codes (admin-made, DataStore) ·
group reward (group 565190385). One Rewards window holds login / gifts / codes / group.

## 2.17 Trading
Request > accept > up to 6 cats each > both Ready > 5 s countdown (changes reset it) > confirm > the server
re-checks ownership, locks and pen room for both, swaps in one step, saves both, logs the trade (TradeLog store).
Leaving cancels. Duplicate-proof: cats are moved by id from one map to the other in the same server step.

## 2.18-2.20 Robux
5 passes and 7 products of blueprint §13 (ids 0 until the developer makes them), one ProcessReceipt, the x2 Speed
button turns into an on / off switch once owned, store window reading the Roblox icons and prices.

## 2.21-2.25
All 400 cat models (CatModel already builds every design: gallery check + mutations look), player animations
(cast, reel, lift, run, swing, carry: Roblox defaults where they fit), sound system + xlsx list for the developer,
GPT prompts for the game icon and thumbnails, full-server test and `docs/LAUNCH_CHECKLIST.md`.
