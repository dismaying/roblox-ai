# roblox-ai

Reference library for building Roblox games (GUI, VFX, animation, cutscenes, audio, official API docs, Luau cookbook). Start with `AI-GUIDE.md`.

## Skills (`.claude/skills/`)
| Skill | Use for |
|---|---|
| `roblox-luau-core` | Any Luau scripting: client/server split, remotes, server authority, cleanup |
| `roblox-ui` | GUI, HUD, menus, responsive/mobile/gamepad UI |
| `roblox-vfx` | Particles, beams, trails, impacts |
| `roblox-audio` | SFX, music, SoundGroups, audio hooks |
| `roblox-camera-cutscenes` | Cutscenes, camera shake, FOV, letterbox |
| `roblox-animation` | Character and UI animation, combat combos |
| `roblox-environment-lighting` | Lighting, Atmosphere, Sky, post-processing |
| `roblox-performance` | Profiling, streaming, mobile, many players |
| `roblox-input` | Keyboard/mouse, touch, gamepad, ProximityPrompts |
| `roblox-thumbnails-icons` | Game icon, thumbnails, logo research |

Map building in Studio (Rojo + Studio MCP) is covered by the user's own `roblox-studio-build` skill.

## Ground rules
- `official-docs/` is authoritative for API names; everything outside `cookbook/` is untested synthesis.
- Gameplay is server-authoritative.
- Never claim something is tested unless it was run, and never invent asset IDs.
