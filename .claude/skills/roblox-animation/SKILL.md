---
name: roblox-animation
description: Use when working with Roblox character or UI animation - loading and playing animations, keyframe markers, combat combos, emotes, IK, or tween-based UI motion.
---

# Roblox animation

## References
- Catalog: `animations/ANIMATIONS.md` (33 patterns), `animations/EXTRA-REFERENCES.md`, style briefs and clips in `visual-refs/animation-refs/` (`STYLE-BRIEFS.md`, `LINKS.md`, MP4s).
- API: `official-docs/api/classes/` Animator, Animation, AnimationTrack, KeyframeMarker, KeyframeSequence, Motor6D, AnimationController, Humanoid. Guides: `official-docs/guides/animation/` (editor, events, curve-editor, inverse-kinematics, graph-editor) and `official-docs/guides/characters/` (emotes, adaptive-animation, character-controller-library).
- Modules: `cookbook/animation/01-play-with-markers.luau`, `cookbook/animation/02-combo-client.luau`.

## Rules
- Load through the `Animator` (`humanoid:FindFirstChildOfClass("Animator"):LoadAnimation(anim)`), never the deprecated `Humanoid:LoadAnimation`. Cache tracks; do not reload every play.
- Player character animations played on the client replicate automatically. NPC animations play on the server.
- Use `AnimationPriority` (Action for attacks) so they override walk/idle.
- Drive gameplay from `GetMarkerReachedSignal("Hit")` etc., but the server validates hits (timing, range, cooldown) - see `roblox-luau-core`.
- Animation assets must be owned by the experience's owner (user or group) or they will not play.
- UI motion uses TweenService on UIScale/Position/GroupTransparency (see `roblox-ui`).
