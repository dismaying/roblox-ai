---
name: roblox-luau-core
description: Use for any Roblox Luau scripting - client/server split, RemoteEvents, server-authoritative gameplay, Rojo layout, cleanup - and before writing code that touches the Roblox API.
---

# Roblox Luau core

Repo paths below are relative to the `roblox-ai` repo root.

## Before writing code
1. Look up every class you touch in `official-docs/api/classes/<Class>.yaml` (114 classes) and enum values in `official-docs/api/enums/`. Do not guess property names. If a class is not bundled (for example `RemoteEvent`, `DataStoreService`, `CollectionService`, `PathfindingService`), check the live docs at https://create.roblox.com/docs/reference/engine.
2. Check `cookbook/README.md` for an existing module and read its `Status:` header before reusing it.

## Where code runs
- `ServerScriptService` (Script): game state, damage, rewards, purchases, saving, spawning.
- `StarterPlayerScripts` / `StarterGui` (LocalScript): input, camera, UI, local-only effects and UI sounds.
- `ReplicatedStorage` (ModuleScript, RemoteEvent/RemoteFunction): shared modules and the remotes both sides use.
- `ServerStorage`: server-only assets, backups, templates.
- With Rojo, mirror this in `src/server`, `src/client`, `src/shared` and keep the project file syncing scripts only, so it never overwrites Workspace builds or Lighting.

## Server authority (non-negotiable)
- The client sends intent ("I swung", "I want to buy X"), never results ("I hit for 50", "give me 100 coins").
- On every `OnServerEvent`: check argument types, the player's character is alive, distance/line of sight, cooldowns and rate limits. Ignore bad requests without erroring.
- Rewards, currency, inventory, progression and damage change only on the server. Example: `cookbook/animation/02-combo-client.luau`.
- Avoid `RemoteFunction` server→client calls (a client can hang the server thread).

## Idioms
- `local Players = game:GetService("Players")` at the top; never index services as `game.Players`.
- Use `task.wait`, `task.spawn`, `task.delay`, never `wait`/`spawn`/`delay`.
- Tag instances with `CollectionService` (or Attributes) instead of searching by name; the Floodline map already uses tags such as `FloodlineLoot`, `FloodlineExtraction`, `FloodlineTeamSpawn`.
- `WaitForChild` on the client for anything that replicates; not needed on the server for things already in place.
- Store per-connection cleanup: keep `RBXScriptConnection`s and `Disconnect` them, `Destroy` instances, use `Debris:AddItem` for timed effects. Handle `Players.PlayerRemoving` and `Humanoid.Died`.
- Use type annotations (`--!strict` where practical) and small ModuleScripts with one job each.
- `pcall` every DataStore, MarketplaceService and HTTP call; retry with backoff; save on `PlayerRemoving` and `game:BindToClose`.

## Reporting
State exactly what was tested (compiled, run in Studio play mode, multi-client test) and what was not. Never call code tested unless you ran it.
