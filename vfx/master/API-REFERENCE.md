# Roblox VFX API reference (verified)

Stage 2 of the VFX toolkit. Each fact is tagged with its source:
- **[probe]** was read from Roblox Studio 0.744 on 2026-10-24.
- **[docs]** is from `official-docs/` (Creator Hub, CC BY 4.0) in this repo.
- **[web]** is a Creator Hub page fetched 2026-10-24.

Nothing here is guessed. If a property isn't listed, check `official-docs/api/classes/<Class>.yaml` before using it.

## ParticleEmitter

Parent it to a **BasePart** or an **Attachment**. On a part, particles spawn inside the part's volume or shape and fly out of `EmissionDirection`. On an attachment, they spawn at the attachment and fly along its orientation. [docs]

| Property | Type / default [probe] | What it does / limits |
|---|---|---|
| `Enabled` | bool, true | Stops new particles; live ones finish. `Clear()` removes them. [docs] |
| `Rate` | number, 20 | Particles per second. Engine cap **400/s per emitter (100/s on mobile)** [docs]. Studio stores larger values but they are capped. |
| `Lifetime` | NumberRange, 5–10 | Seconds; **capped at 20** internally [docs]. |
| `Speed` | NumberRange, 5 | Studs/s at birth. Negative values fly backwards. Changing it doesn't affect live particles. [docs] |
| `Acceleration` | Vector3, 0 | Studs/s² applied over the particle's life (gravity, buoyancy). |
| `Drag` | number, 0 | Seconds to lose half the speed (bigger = slower decay). Negative accepted. [probe] |
| `SpreadAngle` | Vector2, (0,0) | Degrees off the emission axis on X and Y. (180,180) = all directions. |
| `EmissionDirection` | NormalId, Top | Face of the parent part to emit from. |
| `Shape` | Box/Sphere/Cylinder/Disc | Sphere and Cylinder **don't display correctly on an Attachment**; use a part [docs]. |
| `ShapeStyle` | Volume/Surface | Inside the shape, or on its surface only. |
| `ShapeInOut` | Outward/Inward/InAndOut | Inward = particles fly toward the centre (charge-up!). |
| `ShapePartial` | 0–1, 1 | Cylinder: radius on the emission side. Disc: inner radius (ring emitter). Sphere: hemisphere angle. |
| `Size` | NumberSequence | Size over life, with envelope = random range. Big particles cost fill-rate. [docs] |
| `Squash` | NumberSequence | >0 = tall and thin, <0 = wide and flat. Rain streaks, stretch sparks. |
| `Transparency` | NumberSequence | Most important property: fade in and out or particles pop. [docs] |
| `Color` | ColorSequence | Tint over life. |
| `LightEmission` | 0–1 | 0 = normal blend, 1 = **additive** (glows, black is invisible). Grayscale textures without alpha need 1. [docs] |
| `LightInfluence` | 0–1, 0 | How much scene lighting tints particles. 0 = unaffected (energy); 1 = lit (smoke, dust, rain). |
| `Brightness` | number, 1 | Scales emitted light when LightInfluence is 0 (accepts >1 for HDR-ish glow with Bloom). |
| `Orientation` | FacingCamera / FacingCameraWorldUp / VelocityParallel / VelocityPerpendicular | VelocityParallel = streaks along motion (sparks). VelocityPerpendicular = flat to motion; with Speed 0 it doesn't draw, so use 0.001 (Ropilot Emit.check). |
| `Rotation`, `RotSpeed` | NumberRange (degrees, degrees/s) | Random start angle and spin. |
| `ZOffset` | number (studs) | Pushes render toward or away from the camera without resizing. Use it to layer emitters. |
| `LockedToPart` | bool | Particles move with the parent (auras, rings on a character). |
| `VelocityInheritance` | 0–1 | Fraction of the parent's velocity added at birth (projectile trails). |
| `VelocitySpread` | number | Extra spread (degrees) applied to velocity. |
| `WindAffectsDrag` | bool | Follows global wind when Drag > 0. |
| `TimeScale` | 0–1 | Simulation speed. **Clamped to 0..1** [probe]: slow-mo and hitstop only, never fast-forward. |
| `Texture` | content | PNG with transparent background works best [docs]. |
| `FlipbookLayout` | None/Grid2x2/Grid4x4/Grid8x8/Custom | Custom uses `FlipbookSizeX/Y`. A 1024×1024 8×8 sheet holds 64 frames [docs]. Leave transparent gutters between frames. |
| `FlipbookMode` | Loop/OneShot/PingPong/Random | OneShot spreads frames over Lifetime and ignores Framerate [docs]. |
| `FlipbookFramerate` | NumberRange | **Max 30 fps** [docs]. |
| `FlipbookStartRandom` | bool | Random start frame. With Framerate 0, each particle is a random static frame. |
| `FlipbookBlendFrames` | bool, true | Crossfade between frames. |
| `Emit(n)` | method | Burst n particles now. With Rate 0 / Enabled false this is how one-shots work. |
| `Clear()` | method | Remove all live particles. |

Low-memory clients **turn flipbooks off automatically** (old phones). Reuse textures, and keep a non-flipbook fallback look that still reads. [docs]

## Beam

A quad strip drawn between `Attachment0` and `Attachment1`, bent as a cubic Bézier. [docs]
- Control points: P1 is `CurveSize0` studs along **+X of Attachment0**; P2 is `CurveSize1` studs along **−X of Attachment1**. Rotate the attachments to steer the curve.
- `Segments` default 10, **clamped to 1000** [probe]. Use more for tight curves, fewer for straight beams.
- `Width0`, `Width1`, `Color` (ColorSequence along the length), `Transparency` (NumberSequence along the length).
- `LightEmission`, `LightInfluence`, `Brightness` [probe].
- `FaceCamera`: ribbon always turned to the camera (lasers, lightning). Off: lies in the attachments' plane (ground cracks, flat slashes).
- `TextureMode`:
  - `Stretch`: repeats `TextureLength` **times**.
  - `Wrap` / `Static`: repeats every `TextureLength` **studs**.
- `TextureSpeed` scrolls the texture (energy flow). `SetTextureOffset(offset)` sets the phase by script [probe].
- `ZOffset` for layering.

## Trail

A ribbon left behind as two attachments move. [docs]
- `Lifetime` seconds (**clamped to 20** [probe]); `MinLength`, `MaxLength` (0 = unlimited).
- `WidthScale` (NumberSequence over the trail's length): taper the tail.
- `Color` and `Transparency` over the trail's age.
- `LightEmission`, `LightInfluence`, `Brightness`, `FaceCamera`.
- `TextureMode`:
  - `Stretch` stretches with lifetime and shrinks when you stop.
  - `Wrap` tiles, fixed to the attachments.
  - `Static` is stamped in the world (footprints, tyre marks).
- `Clear()` erases it. Call it after a teleport so you don't get a streak across the map.

## Attachments and space

- An `Attachment` has `CFrame` / `Position` / `Orientation` relative to its parent part, and `WorldCFrame` / `WorldPosition` in world space. Its **X axis** (`Axis`) and **Y axis** (`SecondaryAxis`) steer beams and particles.
- R15 rigs come with attachments on each part: `RootRigAttachment`, `RightGripAttachment` (in RightHand), `LeftGripAttachment`, `WaistCenterAttachment`, `NeckAttachment`, `HatAttachment` (Head), `BodyFrontAttachment` / `BodyBackAttachment` (UpperTorso) and others. Effects parented to these follow animation for free.
- `CFrame * CFrame.new(x,y,z)` offsets in the first CFrame's local space; `CFrame + Vector3` offsets in world space.

## Geometry for VFX

- **MeshPart**: `MeshId`, `TextureID`, `DoubleSided` [probe] (needed for single-sheet VFX meshes seen from both sides), `Transparency`, `Material`, `Color`, `CastShadow`, `CanCollide`, `CanQuery`, `CanTouch`.
  - **Max 20,000 triangles per mesh** [web: art/modeling/specifications].
  - Animate with CFrame and Size tweens. Fading a texture: `TextureID` ignores Transparency changes on the alpha, so use a **Decal on the part** and fade `Decal.Transparency` (Ropilot Emit's convention).
- **SpecialMesh**: `MeshType` (Sphere, Cylinder, FileMesh…), `Scale` (tweenable without resizing the part), `Offset`, `VertexColor`.
- **Decal / Texture**: `Texture`, `Color3` (tint), `Transparency`, `ZIndex`. Texture adds `StudsPerTileU/V` and `OffsetStudsU/V`, which you can tween to scroll.
- **Neon material** glows and blooms. Use it for cores, not for everything.
- **Highlight**: `FillColor/Transparency`, `OutlineColor/Transparency`, `DepthMode` AlwaysOnTop/Occluded. At most **255 highlights render at once** on a client; extras are silently ignored [docs].

## Light and post-processing

- `PointLight` (`Range`, `Brightness`, `Color`, `Shadows`), `SpotLight` / `SurfaceLight` (`Angle`, `Face`, `Range`). Flash a light on impacts for 0.05–0.2 s; avoid many shadowed lights.
- `BloomEffect` (`Intensity`, `Size`, `Threshold`), `ColorCorrectionEffect` (`Brightness`, `Contrast`, `Saturation`, `TintColor`): impact frames and transformations. Also `BlurEffect.Size`, `DepthOfFieldEffect`, `SunRaysEffect`, `Atmosphere`, `ColorGradingEffect.TonemapperPreset` [probe].
- **Client-only post-processing**: put effects in `Lighting` (or the camera) from a LocalScript for a per-player impact frame, so you don't flash every player.

## Scripting APIs used for VFX

- `TweenService:Create(inst, TweenInfo, goals)` tweens numbers, Vector3, CFrame, Color3, UDim2 and similar. **It cannot tween NumberSequence or ColorSequence**: drive those from a NumberValue or by hand each frame (`cookbook/vfx/06`).
- `TweenService:GetValue(alpha, style, direction)` gives eased alpha for your own loops.
- `RunService.Heartbeat` / `PreSimulation` / `RenderStepped` (`BindToRenderStep` for camera work). **One shared connection for all effects** beats one per effect.
- `ContentProvider:PreloadAsync({instances})` so the first play isn't blank; `GetAssetFetchStatus(uri)`.
- `Debris:AddItem(inst, t)` for fire-and-forget cleanup; prefer explicit pooling for frequent effects.
- `AnimationTrack:GetMarkerReachedSignal(name)` for hit frames; `AnimationTrack.TimePosition`, `AdjustSpeed` (hitstop on the animation too).
- `UserSettings():GetService("UserGameSettings").SavedQualityLevel` is the player's graphics level [probe]. Scale counts by it.
- `AssetService:CreateEditableImage` / `CreateEditableMesh` exist in 0.744 [probe]. They are runtime-generated textures and meshes, with permission and memory rules; treat them as advanced and optional.

## Assets: textures, meshes, rights

- **Textures**: PNG with alpha. Flipbooks are square sheets (1024×1024) in 2×2, 4×4 or 8×8 grids with gutters [docs]. Ropilot's `vfx_textures` checker requires 1024×1024 for flipbooks.
- **Upload**: images go through the Asset Manager / Toolbox, or `ropilot_blender_upload_images` (owned by the Studio user; may sit in moderation for a while).
- **Asset privacy** [web: projects/assets/privacy]:
  - Images, decals and meshes are **Open Use by default** unless the creator turned on Asset Privacy. Restricted assets **don't load at runtime** in a game without permission, and Studio's Output prints an error.
  - Open Use cannot be reversed.
  - So a third-party texture ID may work today in one game and not another. Check in a playtest.
- **Meshes**: FBX/OBJ import; watertight is expected for avatar items, but VFX sheets can be open. Use `DoubleSided`. Max 20k triangles.

## Performance facts to design around

- **Overdraw**: many overlapping transparent particles cost GPU [docs]. Fewer, better-textured particles beat many plain ones.
- **Fill-rate**: big particles near the camera are expensive [docs].
- Mobile caps Rate at 100/s per emitter [docs] and may drop flipbooks under memory pressure.
- Check quality levels: Studio Settings → Editor Quality Level lowest and highest [docs].
