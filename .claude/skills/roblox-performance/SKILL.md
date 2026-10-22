---
name: roblox-performance
description: Use when checking or improving Roblox performance - part counts, streaming, mobile frame rate, memory, network, MicroProfiler - or before calling a map or system ready for many players.
---

# Roblox performance

## References
- Guides: `official-docs/guides/performance-optimization/` (design, identify, improve, monitor, scene-analysis, test-on-hardware, microprofiler/).

## Checklist
- Measure first: Developer Console (F9) memory and network, MicroProfiler (Ctrl+F6), Studio's Scene Analysis. Report numbers, not impressions.
- Parts: anchor everything static, turn off `CanCollide`/`CanTouch`/`CanQuery` on decoration, `CastShadow` off on small props. Merge repeated detail into meshes where possible; avoid huge unions.
- StreamingEnabled: keep it on for large maps; mark only landmarks and gameplay-critical models `Persistent`; use `StreamingTargetRadius` sensibly; client code must handle parts not existing yet.
- Lights and effects: cap shadow-casting lights and particle rates; pool and clean up (see `roblox-vfx`).
- Scripts: no per-frame loops on the server for many objects; event-driven over polling; disconnect connections; no `while true do wait()`.
- Network: send small RemoteEvent payloads, throttle frequent ones, never replicate cosmetic-only changes from the server.
- Test on a low-end phone (or Studio emulation plus lowest graphics) and with several players before calling it ready. Say what was not tested.
