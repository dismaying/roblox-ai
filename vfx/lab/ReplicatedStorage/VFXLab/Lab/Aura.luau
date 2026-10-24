--[[
	Aura: equip / unequip lifecycle for character auras.
	Activation -> Formation -> Idle loop (reacts to movement) -> Deactivation -> cleanup.

	An aura definition (see Effects/README) provides:
		build(ctx) -> {
			activate   = function(tl, ctx) end,         -- schedule the intro on tl (a Timeline); optional
			idle       = function(t, dt, state, ctx) end, -- every frame while equipped; state below
			deactivate = function(tl, ctx) end,          -- schedule the outro on tl; optional
		}
	Everything the aura creates must go in ctx.scope (or be parented under something in it):
	unequip() and character removal destroy that scope, so nothing is left running.

	state = { speed, moving, grounded, intensity, time } ; intensity eases toward 1 while idle and
	toward params.movingIntensity (default 1) while moving, so auras can calm down or flare up.
]]
local Clock = require(script.Parent.Clock)
local Scope = require(script.Parent.Scope)
local Timeline = require(script.Parent.Timeline)
local Rig = require(script.Parent.Rig)

local Aura = {}
Aura.__index = Aura

local equipped = setmetatable({}, { __mode = "k" }) -- character -> { [name] = handle }

function Aura.equip(character, def, ctx)
	assert(def.build, "Aura.equip: definition '" .. tostring(def.name) .. "' has no build(ctx)")
	local slots = equipped[character] or {}
	equipped[character] = slots
	if slots[def.name] then
		slots[def.name]:unequip(true)
	end

	local scope = Scope.new()
	ctx.scope = scope
	ctx.character = character
	local self = setmetatable({ def = def, ctx = ctx, scope = scope, character = character, alive = true }, Aura)
	slots[def.name] = self

	local parts = def.build(ctx)
	self.parts = parts or {}

	local state = { speed = 0, moving = false, grounded = true, intensity = 0, time = 0 }
	self.state = state
	local movingIntensity = (ctx.params and ctx.params.movingIntensity) or 1

	if self.parts.activate then
		local tl = Timeline.new(scope)
		self.parts.activate(tl, ctx)
		tl:play()
	end

	if self.parts.idle then
		scope:add(Clock.every(function(dt)
			if not self.alive then
				return false
			end
			state.time += dt
			state.speed = Rig.speed(character)
			state.moving = state.speed > 2
			state.grounded = Rig.grounded(character)
			local goal = if state.moving then movingIntensity else 1
			state.intensity += (goal - state.intensity) * math.min(dt * 4, 1)
			self.parts.idle(state.time, dt, state, ctx)
			return true
		end))
	end

	-- Character gone (death, respawn, leave): clean up immediately, no outro.
	scope:add(character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:unequip(true)
		end
	end))
	local humanoid = Rig.humanoid(character)
	if humanoid then
		scope:add(humanoid.Died:Connect(function()
			self:unequip(false)
		end))
	end
	return self
end

-- Plays the deactivation (unless instant) and then destroys everything the aura made.
function Aura:unequip(instant)
	if not self.alive then
		return
	end
	self.alive = false
	local slots = equipped[self.character]
	if slots and slots[self.def.name] == self then
		slots[self.def.name] = nil
	end
	if instant or not self.parts.deactivate then
		self.scope:destroy()
		return
	end
	-- The outro runs on its own timeline but inside the aura's scope, then the scope goes.
	local tl = Timeline.new()
	self.parts.deactivate(tl, self.ctx)
	tl:play({
		onDone = function()
			self.scope:destroy()
		end,
	})
	-- Safety net: never let an outro keep an aura alive for more than 5 s.
	task.delay(5, function()
		tl:stop()
		self.scope:destroy()
	end)
end

function Aura.get(character, name)
	local slots = equipped[character]
	return slots and slots[name]
end

function Aura.unequipAll(character, instant)
	local slots = equipped[character]
	if not slots then
		return
	end
	for _, handle in slots do
		handle:unequip(instant)
	end
end

return Aura
