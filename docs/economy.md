# Economy (task 1.6)

Simulation: `lune run tools/sim/economy.luau` (uses `src/shared/CatRules` + `Config`). One player, no rebirth,
10 pen slots, a catch every 45 s in the best open zone (only cats their Strength can hold), lifting when the next
zone needs more Strength, buying the next weights level when affordable. Options scale the weights costs
(A x0.5, B x1, C x2).

| Option | Zone 2 | Zone 3 | Zone 4 | Zone 5 | Pen income 1 h | 3 h | Weights Lv at 6 h |
|---|---|---|---|---|---|---|---|
| A fast | 5 min | 9 min | 17 min | 42 min | 23.8K/s | 29.3K/s | 19 |
| **B normal (picked)** | 6 min | 10 min | 19 min | 51 min | 17.2K/s | 29.2K/s | 18 |
| C slow | 6 min | 11 min | 21 min | 60 min | (sim quirk) | 29.2K/s | 17 |

Picked **B** in long-run mode (logged under "Decisions to review"): real play is slower than the sim (other
players take cats, the minigame fails, bat hits drop cats), and milestone 2 adds pen slots (10 -> 60), rebirths
(x1.5 money and Strength each), rods and treats. Retune after the first multi-player playtest.

## The numbers (Config)
- Cat income = `Tiers[t].Rate` x kg per second: Basic 0.5, Rare 0.8, Epic 1.2, Legendary 2, Mythical 4, Secret 8.
  Weight roll `min + (max - min) * u^2` (heavy cats rarer); Sky Islands roll heavier (skew 0.8).
- Selling pays 120 s of the cat's income.
- Weights: Strength per second at level L = 0.1 x 1.33^(L-1) (L25: 92/s); next level costs 100 x 2.5^(L-1).
- Treadmill: Speed per second 0.2 x 1.4^(L-1); next level 40 x 1.85^(L-1). Walk speed = 16 + 9 ln(1 + Speed/10),
  at most 60 studs/s; the like buff doubles the part above 16 for 5 minutes.
- Zone gates (Strength or rebirths): Market 10 / 1, Forest 60 / 2, Snow 300 / 4, Sky 1,500 / 6.
- Zone odds: Backyard Basic 90 Rare 10 · Market Basic 30 Rare 60 Epic 10 · Forest Rare 35 Epic 55 Legendary 10 ·
  Snow Epic 45 Legendary 55 · Sky Epic 20 Legendary 80 (heavier). Mythical and Secret come only from events
  (and the Diamond crate's 0.5% Mythical in milestone 2).

---

# R4: numbers up to 99 Sx (developer, 2026-11-08: "สูงสุดอยู่ที่99SX" = 99 sextillion, money / Strength / Speed)

Simulation: `lune run tools/sim/economy_sx.luau` (a stand-alone model of the new curves; one player from a new
save to rebirth 25: a catch every 45 s in the best zone it can hold, lifting 60 % of the rest, buying weights
levels when affordable, rebirthing as soon as Strength allows; pen slots 10 + 2 per rebirth).

## The proposed shape (same for every option)
- Cat weights on a log ladder: Basic 1-100 kg, Rare 100-10K, Epic 10K-1M, Legendary 1M-100M; event cats Mythical
  100M-1B, Secret 1B-1.18B. Rolled `min * (max / min) ^ (u ^ 2)` (heavy cats rarer).
- **Each rebirth makes every cat in the world x3.6 heavier** (wild, event and crate cats), so Strength always
  matters: at rebirth 25 the heaviest Secret cat is 99 Sx.
- A cat earns `rate x kg ^ 0.6` per second (heavier cats earn more, but slower than their weight), x1.5 money per
  rebirth as now.
- Weights: Strength per second `1.6 ^ (level - 1)`, x ~3.95 per rebirth (instead of x1.5); level costs
  `Cost0 x ~1.78 ^ (level - 1) x 3 ^ rebirths`. Treadmill the same shape for Speed.
- Rebirth need: `Need0 x 4 ^ rebirths` Strength. Zone gates x3.6 per rebirth (or the rebirth count, as now).
- Walk speed from the Speed stat **relative to the current life** (Speed / 3.95 ^ rebirths), so walking feels the
  same every life and the stat can still grow to Sx.
- Hard cap 99 Sx on Money, Strength, Speed and cat weight. Big numbers: the money leaderboard stores log10 x 1000;
  old saves are converted once (each value moved to the same place on the new ladder); the save key is unchanged.

## Options (pace only)

| Option | Zone 2 / 3 / 4 / 5 (first life) | Rebirth 1 | Rebirth 10 | Rebirth 25 | At rebirth 25 |
|---|---|---|---|---|---|
| A fast | 2 / 6 / 16 / 23 min | 46 min | 5 h | **13 h** | Strength 38 Sx, money 4 Sx |
| **B normal (recommended)** | 2 / 7 / 20 / 32 min | 1 h 22 | 10 h | **26 h** | Strength 42 Sx, money 13 Sx |
| C slow | 2 / 11 / 29 / 45 min | 2 h 17 | 18 h | **50 h** | Strength 47 Sx, money 39 Sx |

After rebirth 25 the numbers keep growing until the 99 Sx cap. Real play is slower than the sim (other players
take cats, the minigame fails, bats drop cats), so B in the sim is roughly 1.5-2x longer for a real player.

---

# W5 (revision 3 items 9 + 14): end game at about 50 hours, dearer crates (2026-11-13)

Simulation: `lune run tools/sim/endgame.luau` (options in `tools/sim/endgame_options.luau`). Unlike the older sims it
runs the game's own shared modules (Config, CatRules, Shop, Crates, Mutation). One active free player: a cat trip every
60 s (85 % caught), lifting half the rest of the time, buying weights levels, pen slots and the next rod when it can,
a crate now and then, rebirthing as soon as it may. End game = rebirth 25.

Today: rebirth 25 at 31 h, but rod 25 at 3 h, 60 pen slots at 35 min, and crates cost seconds of income (the Diamond
crate, 900K, is under a second of income at the end of the first life).

| Option | Rebirth 1 / 10 / 20 / 25 | Rod 25 | 60 pen slots | Diamond crate | Changes |
|---|---|---|---|---|---|
| A faster | 1h45 / 13h / 32h / **44 h** | 28 h | 10 h | ~2-5 min of income | Strength x3.85 a rebirth, rods x5 a level, pen x12 a step, crates half of B |
| **B (recommended)** | 1h46 / 14h / 37h / **53 h** | 35 h | 11 h | ~5-8 min | x3.8, rods x5.5, pen x14, crates 40K / 2.5M / 75M / 900M |
| C slower | 1h48 / 15h / 42h / **64 h** | 50 h | 15 h | ~14-16 min | x3.75, rods x6, pen x16, crates x3 of B |

All options: crates x3.4 a rebirth (was x3; income grows about that fast). The sim player never stops, so a real
player (other players taking cats, bat hits, walking, breaks) takes longer.
