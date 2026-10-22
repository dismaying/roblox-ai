---
name: roblox-audio
description: Use when adding Roblox sound and music - SFX, UI sounds, ambience, 3D positional audio, mixing with SoundGroups, or wiring audio cues into a map.
---

# Roblox audio

## References
- Catalog: `sfx/SFX.md` (54 patterns), `sfx/EXTRA-REFERENCES.md` (25 briefs).
- API: `official-docs/api/classes/` Sound, SoundGroup, SoundService, the *SoundEffect classes, and the newer Audio* graph (AudioPlayer, AudioEmitter, AudioListener, AudioFader, AudioReverb...). Guides: `official-docs/guides/sound/` and `official-docs/guides/audio/`.
- Modules (`cookbook/sfx/`): `01-play-with-variation`, `02-soundgroup-mix`, `03-positional-sound`, `04-ui-sound-bus`.
- Sources: Roblox Creator Store audio, Kenney, OpenGameArt, Freesound (see `libraries.md`). Only upload audio you have the rights to.

## Rules
- Set `Sound.SoundGroup` explicitly (parenting under a group is not enough). Create Music / SFX / UI / Ambience groups; group volumes multiply.
- UI sounds play locally with `SoundService:PlayLocalSound` (no replication).
- 3D sounds live on a Part or Attachment; set `RollOffMinDistance`/`RollOffMaxDistance` and `RollOffMode` deliberately.
- Repeated SFX: small random pitch/volume variation so they do not sound identical.
- Preload key sounds with `ContentProvider:PreloadAsync`.
- Never invent asset IDs. If an asset is missing, leave the hook (e.g. an attribute or tagged marker) and list it as missing.

## Floodline
The map has `FloodlineAudioHook` markers with empty AssetIds and cue keys like `amb.floodline.water_lapping`, `evt.surge.siren`, `evt.barge.horn` (see `FLOODLINE.md` in the project files). Fill those hooks rather than placing new sounds by hand.
