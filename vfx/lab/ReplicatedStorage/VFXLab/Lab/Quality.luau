--[[
	Quality: one place that decides how much an effect may spend.
	Levels: 1 Low (mobile / low graphics), 2 Medium, 3 High. Read from the player's graphics setting,
	or forced with Quality.set(level) (the lab panel does this to preview low-end devices).

	Quality.count(40)      -> 40 on High, 24 on Medium, 12 on Low (rounded, at least 1)
	Quality.allows(3)      -> true only on High: skip optional layers (extra sparks, lights) below it
	Quality.preset()       -> { level, particleScale, maxLights, flipbooks, postFX, shake }
]]
local Quality = {}

local PRESETS = {
	[1] = { level = 1, name = "Low", particleScale = 0.3, maxLights = 1, flipbooks = false, postFX = false, shake = 0.6 },
	[2] = { level = 2, name = "Medium", particleScale = 0.6, maxLights = 2, flipbooks = true, postFX = true, shake = 0.85 },
	[3] = { level = 3, name = "High", particleScale = 1, maxLights = 4, flipbooks = true, postFX = true, shake = 1 },
}

local forced = nil
local changed = Instance.new("BindableEvent")
Quality.Changed = changed.Event

local function fromSettings()
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	if not ok or level == 0 then
		-- 0 is Automatic: the engine picks; assume a mid device.
		return 2
	end
	if level <= 3 then
		return 1
	elseif level <= 7 then
		return 2
	end
	return 3
end

function Quality.level()
	return forced or fromSettings()
end

function Quality.set(level)
	forced = if level then math.clamp(level, 1, 3) else nil
	changed:Fire(Quality.level())
end

function Quality.preset()
	return PRESETS[Quality.level()]
end

function Quality.count(n)
	return math.max(1, math.floor(n * PRESETS[Quality.level()].particleScale + 0.5))
end

function Quality.allows(minLevel)
	return Quality.level() >= minLevel
end

return Quality
