--[[
	Motion: small math helpers for procedural VFX movement. Pure functions, no instances, safe anywhere.

	Motion.ease(alpha, "Quad", "Out")          eased 0..1 (TweenService curves)
	Motion.bezier(t, p0, p1, p2, p3?)          quadratic or cubic Bezier point (Vector3)
	Motion.orbit(t, radius, speed, tilt?)      offset on a circle in the XZ plane, optionally tilted (CFrame angles)
	Motion.wobble(t, seed, freq)               smooth noise in -1..1 (math.noise)
	Motion.wobble3(t, seed, freq)              Vector3 of three independent wobbles
	Motion.pulse(t, freq, min, max)            sine between min and max
	Motion.spring(state, target, dt, freq, damping)  critically damped-ish spring for numbers or Vector3
	Motion.lerp(a, b, t)                       numbers, Vector3, Color3, CFrame
	Motion.ring(n, radius, phase?)             n evenly spaced offsets on a circle
]]
local TweenService = game:GetService("TweenService")

local Motion = {}

function Motion.ease(alpha, style, direction)
	return TweenService:GetValue(
		math.clamp(alpha, 0, 1),
		Enum.EasingStyle[style or "Quad"],
		Enum.EasingDirection[direction or "Out"]
	)
end

function Motion.bezier(t, p0, p1, p2, p3)
	local u = 1 - t
	if p3 == nil then
		return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t)
	end
	return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
end

function Motion.orbit(t, radius, speed, tilt)
	local angle = t * speed
	local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	if tilt then
		offset = tilt:VectorToWorldSpace(offset)
	end
	return offset
end

function Motion.wobble(t, seed, freq)
	return math.clamp(math.noise(t * (freq or 1), seed or 0, 0.5) * 2, -1, 1)
end

function Motion.wobble3(t, seed, freq)
	seed = seed or 0
	return Vector3.new(Motion.wobble(t, seed, freq), Motion.wobble(t, seed + 17.3, freq), Motion.wobble(t, seed + 41.9, freq))
end

function Motion.pulse(t, freq, min, max)
	local s = (math.sin(t * freq * math.pi * 2) + 1) / 2
	return (min or 0) + ((max or 1) - (min or 0)) * s
end

-- state = { x = current, v = velocity }; returns the new x. Works for numbers and Vector3.
function Motion.spring(state, target, dt, freq, damping)
	freq = freq or 4
	damping = damping or 1
	local omega = 2 * math.pi * freq
	local accel = (target - state.x) * (omega * omega) - state.v * (2 * damping * omega)
	state.v += accel * dt
	state.x += state.v * dt
	return state.x
end

function Motion.lerp(a, b, t)
	local kind = typeof(a)
	if kind == "number" then
		return a + (b - a) * t
	elseif kind == "CFrame" or kind == "Vector3" or kind == "Color3" then
		return a:Lerp(b, t)
	end
	error("Motion.lerp: unsupported type " .. kind)
end

function Motion.ring(n, radius, phase)
	local out = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2 + (phase or 0)
		out[i] = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
	end
	return out
end

return Motion
