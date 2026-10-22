---
name: roblox-environment-lighting
description: Use when setting Roblox Lighting, Atmosphere, Sky, Clouds, post-processing, wind, time of day or the overall mood of a map.
---

# Roblox environment and lighting

## References
- API: `official-docs/api/classes/` Lighting, Atmosphere, Sky, Clouds, BloomEffect, BlurEffect, ColorCorrectionEffect, DepthOfFieldEffect, SunRaysEffect, PointLight, SpotLight, SurfaceLight. Enums for `Technology` in `official-docs/api/enums/`.
- Guides: `official-docs/guides/environment/` (lighting, atmosphere, skybox, clouds, global-wind, post-processing-effects) and `official-docs/guides/effects/light-sources.md`.

## Rules
- Keep **one** Atmosphere, one Sky and one of each post effect under `Lighting`; duplicates conflict. (Floodline currently has two Atmospheres - ask which to keep before deleting.)
- Choose `Lighting.Technology` deliberately (Future for interiors with many lights, ShadowMap otherwise) and note the mobile cost.
- Set mood with `Ambient`, `OutdoorAmbient`, `ClockTime`, `Brightness`, `ExposureCompensation`, then Atmosphere `Density`/`Haze`/`Color`, then ColorCorrection. Change one thing at a time and take a screenshot.
- Limit shadow-casting lights; turn `Shadows` off on small decorative lights.
- Never invent Sky texture asset IDs; list a missing skybox as missing.
- Before overwriting Lighting, back up current settings (clone children to ServerStorage) so the change can be reverted.
