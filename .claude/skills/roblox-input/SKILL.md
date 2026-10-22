---
name: roblox-input
description: Use when handling Roblox player input - keyboard, mouse, touch and gamepad bindings, mobile buttons, abilities, sprint, interact prompts.
---

# Roblox input

## References
- Guides: `official-docs/guides/input/` (input-action-system, mouse-and-keyboard, mobile, gamepad, micro-gamepad).
- API: `official-docs/api/classes/` UserInputService, ContextActionService, ProximityPrompt, ProximityPromptService, GuiService. Guide: `official-docs/guides/ui/proximity-prompts.md`.

## Rules
- Support keyboard/mouse, touch and gamepad for every action. Prefer the Input Action System or `ContextActionService:BindAction` (it can create a mobile button) over raw `UserInputService` checks.
- Ignore input when `gameProcessedEvent` is true (the player is typing in chat or a TextBox).
- Use `ProximityPrompt` for world interactions (doors, loot, valves, extraction); it handles all platforms. Validate the action on the server in `Triggered`.
- Detect the last input type with `UserInputService.LastInputTypeChanged` / `PreferredInput` to swap button hints.
- Input is client-side; the server receives intent only (see `roblox-luau-core`).
