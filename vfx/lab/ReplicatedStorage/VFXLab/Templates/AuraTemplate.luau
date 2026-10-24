--[[
	Copy this into ReplicatedStorage.VFXLab.Effects/<Folder>/<Name> and fill it in.
	Not loaded by the registry (Templates is not scanned).

	Aura stages: Activation -> Formation -> Idle loop (+ movement response) -> Deactivation.
	Rules: everything goes in ctx.scope or under ctx.root; no while-loops; no RunService connections
	of your own (idle() already runs every frame on the shared clock); scale counts with Quality.count().
]]
return {
	name = "MyAura",
	kind = "aura",
	tier = 2, -- 1 Minimal .. 5 Cinematic (complexity, not quality)
	tags = { "aura" },
	description = "One sentence: the look and the feeling.",
	params = {
		color = { type = "color", default = Color3.fromRGB(255, 90, 90) },
		scale = { type = "number", default = 1, min = 0.25, max = 4 },
		movingIntensity = { type = "number", default = 0.6, min = 0, max = 2 },
	},
	build = function(ctx)
		local Make, Rig, Motion = ctx.Lab.Make, ctx.Lab.Rig, ctx.Lab.Motion
		local root = Rig.root(ctx.character)
		local socket = ctx.scope:add(Rig.socket(ctx.character, "HumanoidRootPart", CFrame.new(0, -2.8, 0), "AuraFloor"))
		-- Build layers here (emitters on sockets, LockedToPart = true for things that should ride along).

		return {
			activate = function(tl)
				-- tl:at(0, ...) burst in;  tl:span(0, 0.4, function(a) ... end, "Back", "Out") grow in
			end,
			idle = function(t, dt, state)
				-- state.intensity (eased 0..1+), state.moving, state.speed, state.grounded
				-- e.g. rotate a ring: ring.CFrame = root.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, t, 0)
			end,
			deactivate = function(tl)
				-- stop emission, shrink/fade, then the scope is destroyed for you
			end,
		}
	end,
}
