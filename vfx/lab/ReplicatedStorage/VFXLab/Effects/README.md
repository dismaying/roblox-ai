# Effects

Every ModuleScript under this folder (any depth) that returns a table with a `name` is an effect the
lab and the game can play. Organise with folders: `Auras/`, `Combat/`, `Elemental/`, `Environment/`,
`Cinematic/`, `UI/`.

Start from `ReplicatedStorage.VFXLab.Templates` (AuraTemplate, AbilityTemplate).

- Use `ctx.Lab.*` for library modules. In Studio the registry requires a *clone* of each effect so
  edits reload, which means `script.Parent` is nil inside an effect.
- Everything you create goes in `ctx.scope` or under `ctx.root`. No `while` loops and no
  RunService connections of your own: use `tl:span` / `tl:loop` (one-shots) or `idle` (auras).
- Scale particle counts with `ctx.Lab.Quality.count(n)` and gate optional layers with
  `Quality.allows(level)`.
- Textures come from `ctx.Lab.Assets.tex(name)`, never pasted ids.
- Random variation from `ctx.rng` so every client sees the same thing.
- Camera shake, FOV and impact frames only when `ctx.isLocal` (or the player is near).
