# VFX tool audit (Stage 1)

Audited 2026-10-24 on Marko's PC (`johan`), Roblox Studio **0.744.0.7441077**, place "Ore to Empire" (73768822561307), via the Ropilot plugin. Everything below was read from the installed files or probed in Studio's edit context unless marked otherwise.

## Summary

| Tool | Status | What it gives us |
|---|---|---|
| Roblox Studio 0.744 | Connected through Ropilot | Edit-context Lua, playtests (client + server Lua), screenshots, frame-by-frame VFX capture |
| **VFX Studio v3.9.3** (Sytranom, Creator Store plugin 135581141962270) | Installed and running | Texture library (9,178 IDs), mesh library (523 MeshParts), live-edit panels, emit preview, bezier curve editor, helper scripts |
| Ropilot `ReplicatedStorage.VFX.Emit` (v2) | Installed in the place | Runtime player for attribute-driven effects: delays, bursts, durations, mesh Start/End motion, lights, time scale, hitstop, follow |
| Ropilot Blender bridge | Working (Blender 5.2.1 LTS, headless) | Procedural textures/flipbooks (numpy), VFX meshes (arc, ring, cone, swirl, shell), upload images as Marko's assets, import meshes into Studio |
| Rojo 7.7.1 | Installed | Sync repo code into Studio (not used by this lab yet) |
| Other plugins | RigEdit Lite, Load Character, Avatar Importer/Editor, RobloxLSP, HealthBar | Load Character / RigEdit help with R15 preview rigs |

"VFX Forge v2.4.0-rc1" in the original brief was a naming mistake. Marko confirmed the plugin he owns is **VFX Studio** (2026-10-24). VFX Forge (zilibobi, itch.io) is a different, paid plugin and is not installed.

## VFX Studio v3.9.3: what it really does

Source read from `%LOCALAPPDATA%\Roblox\3307882053\InstalledPlugins\135581141962270\...\Plugin.rbxm` (599 scripts). Version string: `Modules/Shared/VersionInfo.lua` → `CurrentVersion = "3.9.3"`. It checks `raw.githubusercontent.com/Sytranom/VFXStudio/.../latestversion.txt` for updates.

### Library (left nav: Textures, Mesh, Properties, Scripts, Sounds, VFX)
- **Textures: 9,178 image asset IDs** in 18 categories: Form 1203, Flare 990, Other 896, Impact 863, Beam 781, Circle 644, Smoke 601, Slashes 583, Text 536, Spec 430, Lightning 331, Fire 299, Swirl 288, Energy 244, Grid 168, Ground 119, Water 112, Star 90.
  - 2,752 are flipbooks: 202 are 2x2, 1,947 are 4x4 and 603 are 8x8, mostly 1024 px.
  - Exported to [`vfx-studio-texture-index.csv`](vfx-studio-texture-index.csv) (id, name, category, grid, resolution, credit) so any session can search it without the plugin.
  - These are community uploads. Most have no credit recorded; 167 are credited to `limited_qj2`. They load only if each asset is Open Use (the Roblox default for images) or shared with this experience. **Check that each ID loads in a playtest before shipping it** (see "Open checks").
- **Meshes: 523 MeshParts** (about 260 unique shapes): 168 "Shock" variants, InwardShockwave, Shockwave, rings, spirals, whirls, half-spheres, icospheres, crystals, rocks, smash/crater pieces, gears, slashes, beam meshes, "GravityBallShockwave" (with its own script).
- **Scripts** (inserted into the game on demand):
  - `RockModule`: craters, rock explosions, crater rows.
  - `CameraShaker`, `BoatTween`, `Bezier`, `WindShake`, `SmartBone`, `VoxBreaker` (voxel destruction).
  - `BubbleModule`, `TekrinnDialogue`, `Cmdr`, `Knit`, `TopbarPlus`.
  - Small scripts: `Bobbing`, `RotateScript`, `Figure8MoveScript`, `HueShift`, `Shake`, `Motor6DMovement/Rotation`, `ParticleVisualizer`, `SillyTimescale`, `EmitVFXv2`.
- **Properties presets**: save chosen properties of an emitter and re-apply them to others. **VFX / Sounds**: save your own effects and sounds into the library (stored in plugin settings, per user).
- **Upload panel**: register a texture from a Decal or asset ID with layout (Static/2x2/4x4/8x8), FPS and resolution. It catalogs an existing asset; it does not upload images.

### Floating editor panels (shown when a ParticleEmitter / Beam is selected)
- **Emit panel**: Count, Delay and Duration are written as attributes **`EmitCount`, `EmitDelay`, `EmitDuration`** on the instance (the shared convention Ropilot's Emit also reads).
  - Buttons: Emit, Loop (with delay) and Trail preview (moves the selection in a circle with radius and speed).
  - Code: generates a one-shot trigger script.
  - Advanced: Tween / Camera Shake / Impact Frame steps (see the limitation below).
  - Mesh and Sound tabs say "Soon".
- **Sliders panel**:
  - Hue/Saturation/Lightness shift across the whole selection.
  - **Retime** (0.1–2x) scales emitter Lifetime, Speed, Drag, Acceleration, Rate, FlipbookFramerate and RotSpeed, Beam TextureSpeed and Trail Lifetime.
  - **Scale** (0.1–3x) scales particle Size, Speed and Acceleration, and Beam widths and curves.
- **Bezier panel**: draws a curve with envelopes and writes it as a `NumberSequence` (Size, Transparency, Squash…) onto selected emitters. 13 easing presets (Linear, Sine, Quad…Quint, Expo, Circ, Back).
- Settings: keybinds (Emit once, Toggle loop, Toggle trail, Insert/Replace, Pen tool), themes, "Use JSON attributes".

### Limitations found in the source
1. **Advanced steps do not play in a live game.**
   - Tween and Camera-Shake steps are saved into a `Configuration` named `TweenData` / `CameraData` (attributes or JSON).
   - Impact Frames are saved as `ColorCorrectionEffect` children with `Delay`/`Duration` attributes.
   - Only the plugin's own editor reads them. Its generated script and `EmitVFXv2` ignore them.
   - Our runtime must implement these, or we keep them in code.
2. `EmitVFXv2` and the generated trigger script use `task.wait` per emitter with no cleanup, time scale or cancellation. The generated script clones every Beam per play. Use them for quick preview only.
3. No mesh or sound sequencing yet ("Soon" in v3.9.3).
4. The library is huge but uneven. Many textures are named only "Texture" or "Images/…". Pick by looking at them, not by name.
5. Asset rights: library meshes and textures belong to their uploaders. Fine as a starting point; for signature effects make original textures and meshes in Blender (Stage 5 does this).

### How we use it
- **Sculpting look and timing by hand:** select an emitter, then use HSL, Retime, Scale and the bezier panel to shape Size and Transparency curves, and Emit/Loop to preview. The attributes it writes are exactly what our runtime plays.
- **Texture shopping:** browse by category in the plugin, or grep the CSV.
- **Shockwave/crater meshes:** insert from the Mesh library; use `RockModule` for ground debris.
- The runtime, sequencing, auras, combat sync and networking are our own code (see `ARCHITECTURE.md`).

## Ropilot tooling relevant to VFX
- `ropilot_vfx_capture`: plays an effect template and returns frames at chosen moments. It holds each frame, can run slow-mo, works in edit mode or the playtest client, and runs `Emit.check`. This is our visual test harness.
- `ReplicatedStorage.VFX.Emit` (installed by Ropilot, editable). Its attribute contract:
  - ParticleEmitter: `EmitDelay`, `EmitCount` (≤500), `EmitDuration`.
  - Beam/Trail/Light: `EmitDelay`, `EmitDuration`.
  - Mesh motion: a `Start`/`End` part pair inside a Model/Folder with `Duration`, `Easing`, `EasingDirection`, `Spin`.
  - Effect root: `EffectDuration`.
  - The handle supports `setTimeScale`, `freeze` (hitstop), `stop`, `add` (child effects on the same clock), `follow`/`offset`, `preload` and `check`.
  - Effects are capped at 30 s.
- Blender helpers (`ropilot` module): `draw_texture`, `draw_flipbook`, `flipbook` (render animation to a 1024² sheet), numpy texture tools (noise, cells, polar, strokes, warp, blobs), VFX meshes (`vfx_arc`, `vfx_ring`, `vfx_cone`, `vfx_swirl`, `vfx_shell`, `vfx_surface`). Textures are previewable in Studio immediately as `rbxasset://textures/ropilot/...` (this PC only) and are uploaded with `ropilot_blender_upload_images`.

## Engine facts probed in Studio 0.744 (edit context)
- **ParticleEmitter** properties:
  - Acceleration, Brightness, Color, Drag, EmissionDirection, Enabled.
  - FlipbookBlendFrames, FlipbookFramerate, FlipbookLayout, FlipbookMode, FlipbookSizeX/Y, FlipbookStartRandom.
  - Lifetime, LightEmission, LightInfluence, LockedToPart, Orientation, Rate, Rotation, RotSpeed.
  - Shape, ShapeInOut, ShapePartial, ShapeStyle, Size, Speed, SpreadAngle, Squash.
  - Texture, TimeScale, Transparency, VelocityInheritance, VelocitySpread, WindAffectsDrag, ZOffset.
  - Methods: `Emit`, `Clear`.
  - Defaults: Rate 20, Lifetime 5–10, Speed 5, LightInfluence 0, Brightness 1.
- **Beam**:
  - Properties: Attachment0/1, Brightness, Color, CurveSize0/1, Enabled, FaceCamera, LightEmission, LightInfluence, Segments, Texture, TextureLength, TextureMode, TextureSpeed, Transparency, Width0/1, ZOffset.
  - `SetTextureOffset` works. **Segments clamp to 1000** (set 5000 → read 1000).
- **Trail**:
  - Properties: Attachment0/1, Brightness, Color, Enabled, FaceCamera, Lifetime, LightEmission, LightInfluence, MaxLength, MinLength, Texture, TextureLength, TextureMode, Transparency, WidthScale.
  - **Lifetime clamps to 20** (set 100 → 20).
- `ParticleEmitter.TimeScale` clamps to 0–1 (set 3 → 1).
- Some values do **not** clamp when read back (Lifetime 50, Rate 5000, FlipbookFramerate 120). The docs say the engine caps them internally: Lifetime 20 s; Rate 400/s per emitter (100 on mobile); flipbook 30 fps. Design within the documented caps.
- **Other classes and services:**
  - `Highlight`: DepthMode is AlwaysOnTop/Occluded.
  - `MeshPart.DoubleSided` exists.
  - `SurfaceAppearance.AlphaMode` exists.
  - `BillboardGui`/`SurfaceGui` have `Brightness` and `LightInfluence`.
  - `ColorGradingEffect.TonemapperPreset` exists.
- **Enums:** ParticleFlipbookLayout = None/Grid2x2/Grid4x4/Grid8x8/Custom. ParticleOrientation = FacingCamera/FacingCameraWorldUp/VelocityParallel/VelocityPerpendicular. TextureMode = Stretch/Wrap/Static.
- `AssetService:CreateEditableImage` and `CreateEditableMesh` both succeed in this Studio (runtime use has extra permission rules; not relied on).
- `UserGameSettings.SavedQualityLevel` is readable (Automatic in Studio).

## Open checks
- Texture IDs from the VFX Studio library: `ContentProvider:GetAssetFetchStatus` reports `None` in edit mode until something requests the asset, and an edit-mode `PreloadAsync` of 40 IDs didn't return within 60 s. Each texture a demo uses is checked in a playtest client in Stage 6.
- Lobby work happens in the same place. All lab content lives under folders named `VFXLab` (Workspace around 5000,0,5000; ReplicatedStorage; StarterPlayerScripts), so it can be exported as one model and deleted cleanly.
