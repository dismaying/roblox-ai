--[[
	Make: short builders for VFX instances with effect-friendly defaults.
	Every builder takes a props table; keys are real property names (checked by Roblox at assignment),
	plus `Parent`, which is applied last so the instance is fully set up before it appears.

	Make.seq(0, 1, 0.5, 0.2, 1, 0)        NumberSequence from (time, value) pairs
	Make.seq(2)                            constant
	Make.cseq(Color3a, Color3b)            ColorSequence from colors spread evenly
	Make.cseq({0, c1}, {0.4, c2}, {1, c3}) ColorSequence from (time, color) pairs

	Make.part{ Size = ..., CFrame = ... }  anchored, no collision/query/touch/shadow
	Make.attachment(parent, cframe?)
	Make.emitter(parent, { Rate = 0, ... }) one-shot friendly: Enabled false unless Rate > 0
	Make.beam(a0, a1, props) / Make.trail(a0, a1, props) / Make.light(parent, "PointLight", props)
]]
local Make = {}

local function apply(inst, props)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				inst[key] = value
			end
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
Make.apply = apply

function Make.seq(...)
	local args = { ... }
	if #args == 1 then
		return NumberSequence.new(args[1])
	end
	assert(#args % 2 == 0, "Make.seq needs (time, value) pairs")
	local points = {}
	for i = 1, #args, 2 do
		table.insert(points, NumberSequenceKeypoint.new(args[i], args[i + 1]))
	end
	return NumberSequence.new(points)
end

-- Like seq, but each point is { time, value, envelope } for random ranges.
function Make.seqEnv(points)
	local keypoints = {}
	for _, p in points do
		table.insert(keypoints, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0))
	end
	return NumberSequence.new(keypoints)
end

function Make.cseq(...)
	local args = { ... }
	if typeof(args[1]) == "Color3" then
		if #args == 1 then
			return ColorSequence.new(args[1])
		end
		local points = {}
		for i, color in args do
			table.insert(points, ColorSequenceKeypoint.new((i - 1) / (#args - 1), color))
		end
		return ColorSequence.new(points)
	end
	local points = {}
	for _, p in args do
		table.insert(points, ColorSequenceKeypoint.new(p[1], p[2]))
	end
	return ColorSequence.new(points)
end

function Make.part(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.one * 0.2
	part.Transparency = 1
	return apply(part, props)
end

-- MeshPart.MeshId can't be assigned from game scripts: clone a template (Assets.mesh) instead.
function Make.attachment(parent, cframe, name)
	local a = Instance.new("Attachment")
	if cframe then
		a.CFrame = cframe
	end
	if name then
		a.Name = name
	end
	a.Parent = parent
	return a
end

function Make.emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Enabled = false
	e.LightInfluence = 0
	e.Speed = NumberRange.new(0)
	e.Lifetime = NumberRange.new(0.5)
	apply(e, props)
	if props and props.Rate and props.Rate > 0 and props.Enabled == nil then
		e.Enabled = true
	end
	if parent and not (props and props.Parent) then
		e.Parent = parent
	end
	return e
end

function Make.beam(a0, a1, props)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.LightInfluence = 0
	b.FaceCamera = true
	apply(b, props)
	if not (props and props.Parent) then
		b.Parent = a0.Parent
	end
	return b
end

function Make.trail(a0, a1, props)
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.LightInfluence = 0
	apply(t, props)
	if not (props and props.Parent) then
		t.Parent = a0.Parent
	end
	return t
end

function Make.light(parent, className, props)
	local l = Instance.new(className or "PointLight")
	l.Shadows = false
	apply(l, props)
	if not (props and props.Parent) then
		l.Parent = parent
	end
	return l
end

return Make
