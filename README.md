# Sweetpotatoturtlenix

Roblox cat-catching game for a client, built with Rojo. Scope: `docs/BLUEPRINT.md`. Tasks:
`docs/PLAN.md`. Rules for working on it: `CLAUDE.md`.

## Run it in Studio
1. PowerShell in this folder: `rokit install` (first time only), then `rojo serve`
2. Studio: open the game's place, Plugins tab -> Rojo -> Connect.
3. Press Play. Output shows `[Sweetpotato] server ready` and `[Sweetpotato] client ready`.

## Check before every commit
```
lune run scripts/check.luau
rojo build -o build/check.rbxlx
```

## Third-party code
ProfileStore by loleris (MAD STUDIO), Apache License 2.0: `third_party_licenses/ProfileStore-LICENSE`.
