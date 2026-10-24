--[[
	Timeline: schedule an effect's beats on its own clock, then play, slow, freeze or cancel it as one thing.
	Driven by the shared Clock (one Heartbeat for everything). Owns a Scope: whatever the steps create
	is cleaned up when the timeline ends or is stopped, even halfway through.

	local tl = Timeline.new()                    -- or Timeline.new(parentScope)
	tl:at(0, function(scope) ... end)            -- one-off at t (seconds); gets the timeline's scope
	tl:span(0.1, 0.4, function(alpha, scope) end, "Quad", "Out")   -- runs every frame for 0.4 s, alpha eased 0..1
	tl:loop(0.5, 2, function(t, dt, scope) end)  -- every frame from 0.5 for 2 s (math.huge = until stopped)
	tl:mark("Impact", 0.35)                      -- named time; tl:at("Impact", fn) and tl:at("Impact+0.1", fn)
	tl:play({ timeScale = 1, onDone = fn })      -- starts; ends after the last step unless :hold()
	tl:setTimeScale(0.2)  tl:freeze(0.08)  tl:stop()

	Steps added after play() still run if their time hasn't passed.
	Time scale also feeds ParticleEmitter.TimeScale for emitters registered with tl:track(emitter).
]]
local Clock = require(script.Parent.Clock)
local Scope = require(script.Parent.Scope)
local Motion = require(script.Parent.Motion)

local Timeline = {}
Timeline.__index = Timeline

function Timeline.new(parentScope)
	local scope = if parentScope then parentScope:child() else Scope.new()
	local self = setmetatable({
		scope = scope,
		time = 0,
		length = 0,
		playing = false,
		finished = false,
		_events = {},
		_spans = {},
		_marks = {},
		_emitters = {},
		_scale = 1,
		_holdOpen = false,
		_onDone = {},
		_onStep = {},
	}, Timeline)
	scope:add(function()
		self:_finish(true)
	end)
	return self
end

function Timeline:_resolve(t)
	if type(t) == "number" then
		return t
	end
	local name, offset = string.match(t, "^([%w_]+)([%+%-][%d%.]+)$")
	name = name or t
	local base = self._marks[name]
	assert(base, "Timeline: unknown mark '" .. tostring(name) .. "'")
	return base + (tonumber(offset) or 0)
end

function Timeline:mark(name, t)
	self._marks[name] = t
	self.length = math.max(self.length, t)
	return self
end

function Timeline:at(t, fn)
	t = self:_resolve(t)
	table.insert(self._events, { at = t, fn = fn })
	self.length = math.max(self.length, t)
	return self
end

function Timeline:span(t, duration, fn, style, direction)
	t = self:_resolve(t)
	table.insert(self._spans, { from = t, duration = math.max(duration, 1e-3), fn = fn, style = style, direction = direction })
	self.length = math.max(self.length, t + duration)
	return self
end

function Timeline:loop(t, duration, fn)
	t = self:_resolve(t)
	table.insert(self._spans, { from = t, duration = duration, fn = fn, raw = true })
	if duration ~= math.huge then
		self.length = math.max(self.length, t + duration)
	end
	return self
end

-- Keep the timeline alive past its last step (auras, channels) until stop().
function Timeline:hold()
	self._holdOpen = true
	return self
end

-- Let the timeline's time scale drive an emitter's TimeScale (slow-mo / hitstop for particles).
function Timeline:track(emitter)
	self._emitters[emitter] = emitter.TimeScale
	emitter.TimeScale = self._emitters[emitter] * self._scale
	return emitter
end

function Timeline:onDone(fn)
	if self.finished then
		task.spawn(fn)
	else
		table.insert(self._onDone, fn)
	end
	return self
end

function Timeline:onStep(fn)
	table.insert(self._onStep, fn)
	return self
end

function Timeline:_applyScale(scale)
	self._scale = scale
	for emitter, authored in self._emitters do
		if emitter.Parent then
			emitter.TimeScale = authored * scale
		end
	end
end

function Timeline:setTimeScale(scale)
	self._freezeToken = nil
	self:_applyScale(math.clamp(scale, 0, 4))
	return self
end

function Timeline:freeze(seconds)
	if self._freezeToken == nil then
		self._resumeScale = self._scale
	end
	local token = {}
	self._freezeToken = token
	self:_applyScale(0)
	task.delay(seconds, function()
		if self._freezeToken == token and not self.finished then
			self._freezeToken = nil
			self:_applyScale(self._resumeScale or 1)
		end
	end)
	return self
end

function Timeline:_advance(dt)
	if self.finished then
		return false
	end
	local scaled = dt * self._scale
	self.time += scaled
	local now = self.time

	for _, fn in self._onStep do
		fn(now, scaled)
	end

	-- Swap the lists out first: a step may add steps or stop the timeline.
	local events = self._events
	self._events = {}
	table.sort(events, function(a, b)
		return a.at < b.at
	end)
	for _, event in events do
		if self.finished then
			return false
		end
		if event.at <= now then
			event.fn(self.scope)
		else
			table.insert(self._events, event)
		end
	end

	local spans = self._spans
	self._spans = {}
	for _, s in spans do
		if self.finished then
			return false
		end
		local keep = true
		if now >= s.from then
			local elapsed = now - s.from
			if s.raw then
				s.fn(elapsed, scaled, self.scope)
				keep = elapsed < s.duration
			else
				local alpha = math.min(elapsed / s.duration, 1)
				s.fn(if s.style then Motion.ease(alpha, s.style, s.direction) else alpha, self.scope)
				keep = alpha < 1
			end
		end
		if keep then
			table.insert(self._spans, s)
		end
	end

	if self.finished then
		return false
	end
	if not self._holdOpen and now >= self.length and #self._events == 0 and #self._spans == 0 then
		self:stop()
		return false
	end
	return true
end

function Timeline:play(options)
	assert(not self.playing, "Timeline: already playing")
	options = options or {}
	self.playing = true
	if options.onDone then
		table.insert(self._onDone, options.onDone)
	end
	if options.timeScale then
		self:_applyScale(options.timeScale)
	end
	self._stopClock = Clock.every(function(dt)
		return self:_advance(dt)
	end)
	self:_advance(0)
	return self
end

function Timeline:_finish(fromScope)
	if self.finished then
		return
	end
	self.finished = true
	self.playing = false
	if self._stopClock then
		self._stopClock()
	end
	for _, fn in self._onDone do
		task.spawn(fn)
	end
	self._onDone = {}
	if not fromScope then
		self.scope:destroy()
	end
end

function Timeline:stop()
	self:_finish(false)
end

Timeline.destroy = Timeline.stop

return Timeline
