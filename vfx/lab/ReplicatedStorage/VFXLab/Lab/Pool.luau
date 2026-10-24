--[[
	Pool: reuse instances for effects that fire often (hit sparks, bullet impacts, footstep dust).
	Cloning and parenting is the expensive part of a one-shot; a pool pays it once.

	local sparks = Pool.new(template, 8, workspace.VFXLabRuntime)   -- prewarm 8 copies, parked out of sight
	local copy = sparks:get()          -- take one (clones more if the pool is empty, up to max)
	sparks:release(copy, 0.5)          -- give it back now or after a delay; it's reset and parked
	sparks:destroy()

	Reset: emitters are disabled and cleared, trails cleared; anything else you changed is your job
	(pass reset = function(copy) ... end).
]]
local Pool = {}
Pool.__index = Pool

local PARK = CFrame.new(0, -10000, 0)

local function park(copy)
	if copy:IsA("Model") then
		copy:PivotTo(PARK)
	elseif copy:IsA("BasePart") then
		copy.CFrame = PARK
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Enabled = false
			d:Clear()
		elseif d:IsA("Trail") then
			d.Enabled = false
			d:Clear()
		elseif d:IsA("Beam") or d:IsA("Light") then
			d.Enabled = false
		end
	end
end

function Pool.new(template, prewarm, parent, options)
	options = options or {}
	local self = setmetatable({
		template = template,
		parent = parent or workspace,
		max = options.max or 64,
		reset = options.reset,
		_free = {},
		_live = {},
		_count = 0,
	}, Pool)
	for _ = 1, prewarm or 0 do
		table.insert(self._free, self:_make())
	end
	return self
end

function Pool:_make()
	local copy = self.template:Clone()
	self._count += 1
	park(copy)
	copy.Parent = self.parent
	return copy
end

function Pool:get()
	local copy = table.remove(self._free)
	if not copy then
		if self._count >= self.max then
			-- Steal the oldest live copy instead of growing without bound.
			local oldest = next(self._live)
			if oldest then
				self._live[oldest] = nil
				park(oldest)
				copy = oldest
			end
		else
			copy = self:_make()
		end
	end
	if copy then
		self._live[copy] = true
	end
	return copy
end

function Pool:release(copy, delay)
	if delay and delay > 0 then
		task.delay(delay, function()
			self:release(copy)
		end)
		return
	end
	if not self._live[copy] then
		return
	end
	self._live[copy] = nil
	if self.reset then
		self.reset(copy)
	end
	park(copy)
	table.insert(self._free, copy)
end

function Pool:destroy()
	for _, copy in self._free do
		copy:Destroy()
	end
	for copy in self._live do
		copy:Destroy()
	end
	self._free, self._live = {}, {}
end

return Pool
