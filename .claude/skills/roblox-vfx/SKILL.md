---
name: roblox-vfx
description: Use when making Roblox visual effects - particles, beams, trails, highlights, impacts, hit feedback, magic, rewards, weather or ambient effects.
---

# Roblox VFX

## References
- Catalog: `vfx/VFX.md` (36 patterns) and `vfx/EXTRA-REFERENCES.md` (25 briefs). Pictures under `previews/vfx-*`.
- API: `official-docs/api/classes/` ParticleEmitter, Beam, Trail, Attachment, Highlight, PointLight, SpotLight, Fire, Smoke, Explosion. Guides: `official-docs/guides/effects/` (particle-emitters, beams, trails, highlighting, light-sources).
- Modules (`cookbook/vfx/`): `01-hit-spark`, `02-shockwave-ring`, `03-lightning-beam`, `04-weapon-trail`, `05-confetti`, `06-tween-particle-numbersequence`. Camera juice: `cookbook/cutscene/03-camera-shake.luau`.
- Previewing: Jad's Emit Plugin (see `libraries.md`).

## Rules
- Play cosmetic effects on the **client**. The server fires one RemoteEvent to everyone (or nearby players) with position and type; each client spawns the effect. Never replicate hundreds of parts from the server.
- Bursts: `ParticleEmitter.Enabled = false` and `:Emit(n)`; keep Lifetime short.
- Pool emitters/parts you reuse often; destroy one-shots with `Debris:AddItem(obj, lifetime)`.
- Cap counts: keep total Rate modest, use `LightEmission` instead of many layers, few `Highlight`s at once (there is a hard limit of 31 visible).
- `TweenService` cannot tween `NumberSequence`/`ColorSequence`: drive them from a `NumberValue` (`cookbook/vfx/06-...`).
- Use `Neon` sparingly; it blooms with BloomEffect.
- Respect lower graphics quality: scale emission with `UserGameSettings().SavedQualityLevel` where it matters.

## Verify
Watch it in play mode at normal and low graphics; report particle counts and what was only checked in edit mode.
