---
name: roblox-camera-cutscenes
description: Use when building Roblox camera work - cutscenes, intro fly-overs, boss intros, dialogue shots, camera shake, FOV kicks, letterbox and fade transitions.
---

# Roblox camera and cutscenes

## References
- Catalog: `cutscenes/CUTSCENES.md` (18 patterns: intro fly-over, dolly, orbit reveal, letterbox, over-the-shoulder dialogue, boss intro, countdown, victory podium, killcam, hit-stop, fade, comic split, tutorial guide, map reveal, item spotlight, jumpscare, visual-novel scene, rig-animated scene) and `cutscenes/EXTRA-REFERENCES.md`.
- API: `official-docs/api/classes/Camera.yaml`, TweenService, RunService. Guides: `official-docs/guides/camera/`.
- Modules (`cookbook/cutscene/`): `01-camera-cutscene`, `02-letterbox`, `03-camera-shake`, `04-fov-sprint`. Library: RbxCameraShaker (`libraries.md`).

## Rules
- Camera code is client-only (LocalScript). The server tells clients when to play a cutscene.
- Set `Camera.CameraType = Enum.CameraType.Scriptable` for the shot, then restore `Custom` and `CameraSubject` to the Humanoid, even if the cutscene errors (wrap in `pcall` / use a cleanup function).
- Place invisible, anchored, non-colliding marker parts for shot positions and tween between their CFrames, rather than hard-coding coordinates. With StreamingEnabled, make sure the markers and scene are streamed in (`Player:RequestStreamAroundAsync` or `ModelStreamingMode = Persistent`).
- Let players skip long cutscenes; disable player controls during the shot and re-enable after.
- Keep shake subtle and offer a reduced-motion setting.
