# Phase 4: revision round 2 (2026-11-09)

The developer's 4 points (with the client's 3 reference pictures for the cats), turned into tasks V1-V5.
This is the **second and last** revision round of the contract (blueprint Terms: 2 rounds on things in the
blueprint). ★ = the developer (and, for the cats, the client) approves a render / preview first.

| Developer's point | Task | In the blueprint? |
|---|---|---|
| 1 Fishing animation: the right hand holds the rod, the left turns a reel that is not where the rod's reel is | V2 | yes (animation) |
| 2 Cat models: the client wants a pixel + LEGO (voxel) style, from 3 reference pictures; designed in Blender | V1 + V5 | yes (400 cat models) |
| 3 Map: more detail; the fountain should look real, the rivers look rushed; scan the whole map and fix | V3 | yes (360 map, zones) |
| 4 A tutorial for new players | V4 | **no**: a new system (blueprint "NOT included: any system not in this blueprint") |

Order: V1 first, because it waits on approvals (Claude renders, the developer and the client look) while
V2-V4 are built; V5 (all cats) after V1 is approved.

---

## V1 ★ Cat style board (Blender)
- The client's pictures come from another game ("Steal An Egg"): they only show a direction (blocky voxel /
  pixel creatures with a thick dark outline). Nothing is copied: every cat is our own design.
- Claude models one original cat in Blender in 3 labelled options, same pose, same colours:
  - A "Pixel": small voxels (a fine grid), pixel-art face, dark outline.
  - B "Brick": chunkier LEGO-like blocks, a few round studs on the back, bright plastic.
  - C "Mix": a voxel body with a big expressive pixel face (closest to the pictures), soft outline.
- Then the chosen option on 4 base shapes (e.g. Loaf, Chonky, Long, Tiny) with 2-3 colourways and a pattern,
  so the client can see how the 400 vary. Render sheet -> developer -> client -> "ผ่าน".
- How it is built for the game (the reason for this plan): each base shape is split in Blender into colour
  regions (fur, second colour, pattern layer, eyes, nose, inner ears) and moving parts (head, legs, tail).
  Every region is its own mesh with plain vertex positions and no texture, so the game colours it by
  `MeshPart.Color`: one set of meshes per shape serves all 400 colourways, patterns and accessories (about
  100 meshes in total, uploaded once by the developer, Creator = the group). The cat data (shape, fur,
  second, pattern, accessory) stays the same, so saves, the book and trades keep working.

## V2 Fishing animation that matches the rod
- Now: PlayerPoses "reel" lifts the right arm forward and swings the left arm in circles in the air.
- New pose from the R5 rod (reel on the rod's left side, about 1 stud above the grip; handle on the reel):
  both hands on the rod: the right hand at the grip, the rod held up and forward (RodGrip), the left hand on
  the reel handle turning small circles (elbows bend, R15). The rod tips up and down a little while the cat
  pulls. The cast keeps the tool "Slash".
- Checked in Studio by putting the left hand on the reel handle (measured from the mesh), rod level 1 / 25.
- Test: Studio Play: fish a cat, the left hand turns at the reel, the line still starts at the rod tip.

## V3 Map detail pass
1. Survey: Claude captures every area in Studio (lobby, the 8 pens, the fountain, the 5 zones, every creek,
   waterfall, bridge and the sky islands) and lists what looks rushed (one page with pictures).
2. Fixes in MapTools (MapKit pieces + BuildMap layout), rebuilt zone by zone with a backup of the old map:
   - Fountain: a real stone fountain: round tiered basins with rims and carved edges, water as layered
     sheets falling from tier to tier, a splash ring and a few drops (ParticleEmitter), a soft light at night.
   - Rivers / creeks: winding beds instead of straight strips: banks with stones and sand, plants and reeds,
     small falls, lily pads, flowing water (a texture-less moving shine), stepping stones; bridges fitted to
     the banks.
   - Waterfalls: layered falls with foam at the bottom and mist.
   - Each zone: more small props on the ground (grass tufts, flowers, rocks, paths, signs) without adding
     colliders in the way; StreamingEnabled keeps phones light. Hiding spots stay where they are (the wild
     cat system uses them).
- Test: Studio captures before / after for every area, a phone run (frame rate), every hiding spot still
  works (`!wild`).

## V4 New-player tutorial (not in the blueprint)
- Steps, each with a short bubble (EN / TH), a glowing arrow / path to the target and a check that moves on
  by itself when the player does it:
  1. Welcome: what the game is about (one bubble).
  2. Walk to the Backyard (arrow to the gate).
  3. Find a cat hiding in a bush (arrow to the nearest cat they can catch).
  4. Take the rod and hold the button to reel it in (points at the hold button).
  5. Carry it home to your pen (arrow to the pen; the bat warning: others can knock it loose).
  6. Train at your weights (arrow; jump to stop).
  7. Open the Shop and see the next rod (points at the Shop button). Done: a small money gift.
- Saved per player (`TutorialStep`, a new save field, default 0 for new players; existing players start as
  done), a Skip button, can be replayed from Settings. Server checks each step from what already happens
  (catch, delivery, training), so nothing new is trusted from the client.
- Test: a fresh save (`!reset` on a test account) walks through every step on PC and phone; skip; replay.

## V5 ★ All 400 cats in the new style
- After V1: every base shape modelled, split into regions, the patterns and accessories as meshes; a sheet of
  all shapes x patterns x accessories ★; export -> the developer imports (Creator = the group) -> CatModel
  rebuilt on the meshes (colours from the cat data), CatAnims moved to the new head / legs / tail, portraits
  (book, My Cats, Caught! card, crate opening) re-checked. Old saves need nothing (same data).
- Test: Studio Play: wild cats in every zone, carry, pens with many cats (frame rate on a phone), book,
  trade, crate opening.

## What the developer does in this phase
- Shows the V1 sheet to the client and answers "ผ่าน" or what to change.
- Decides how V4 (the tutorial, not in the blueprint) is handled with the client: an extra price or free.
- Tells the client this is the last free revision round (blueprint Terms).
- Imports the V5 cat meshes (Creator = the group) and the V3 map changes are saved / published.
