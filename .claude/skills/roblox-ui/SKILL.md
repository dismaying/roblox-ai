---
name: roblox-ui
description: Use when designing or building Roblox GUI - HUDs, menus, shops, inventories, notifications, dialogue boxes - including picking a visual style and making it work on mobile, desktop and gamepad.
---

# Roblox UI

## Pick a direction first
1. Browse `ui-styles/GUI-STYLES.md` (112 styles) and `ui-styles/EXTRA-REFERENCES.md` (40 composition briefs). Choose **one** primary style per game.
2. Open that style's folder: its README has the palette, a Roblox recipe and pictures. Calibrate colour, corner radius, stroke and spacing from the pictures. Pictures belong to their creators: reference only, never import them.
3. More pictures by genre in `previews/` (for example `shooter-user-interface`, `tower-defense-user-interface`, `visual-novel-user-interface`) and the owner's own refs in `visual-refs/studs-ui/`, `visual-refs/sports/`, `visual-refs/icons/`.

## Build rules
- Check properties in `official-docs/api/classes/` (Frame, TextLabel, UIStroke, UICorner, UIGradient, UIListLayout, UIGridLayout, UIFlexItem, CanvasGroup, ScrollingFrame, UIScale, UIAspectRatioConstraint...). Guides: `official-docs/guides/ui/` (position-and-size, list-flex-layouts, grid-table-layouts, buttons, rich-text, 9-slice, styling).
- Size with Scale, not Offset, for containers; use `UIAspectRatioConstraint` for squares/icons and `UITextSizeConstraint` instead of huge `TextScaled` ranges.
- One `ScreenGui` per screen area with `ResetOnSpawn = false` for persistent HUD; set `ScreenInsets` / respect the safe area (see `cookbook/ui/06-responsive-scale.luau`).
- Touch targets at least ~44 px on phones; nothing important under the thumbstick or jump button corners.
- Gamepad: set `Selectable`, `NextSelection*` and `GuiService.SelectedObject` when a menu opens.
- Animate with `TweenService` on `UIScale`/`CanvasGroup.GroupTransparency` so layout does not shift. TweenService cannot tween text: tween a `NumberValue` (`cookbook/ui/03-count-up.luau`).
- Shops and rewards: UI only displays and requests; the server decides (see `roblox-luau-core`).
- Text players type must go through `TextService:FilterStringAsync` before others see it (`official-docs/guides/ui/text-filtering.md`).

## Ready-made modules (`cookbook/ui/`)
`01-hover-scale`, `02-pop-in-open`, `03-count-up`, `04-shine-sweep`, `05-error-shake`, `06-responsive-scale`, `07-toast-stack`. UI click/hover sounds: `cookbook/sfx/04-ui-sound-bus.luau`.

## Verify
Test in Studio's Device emulator at a phone, tablet and 1080p size and with a gamepad, and say which you checked.
