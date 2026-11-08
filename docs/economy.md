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
