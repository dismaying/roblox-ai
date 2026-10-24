--[[
	_LabSelfTest: pipeline check only, not a designed effect.
	One burst of Roblox's built-in sparkle texture and a 0.3 s light, so the lab can prove that
	registry -> timeline -> cleanup -> networking work end to end. Hidden outside Studio ("_" prefix).
]]
return {
	name = "_LabSelfTest",
	kind = "oneshot",
	tier = 1,
	tags = { "lab" },
	description = "Pipeline check: one sparkle burst and a short light, then full cleanup.",
	params = {
		count = { type = "number", default = 12, min = 1, max = 50 },
		color = { type = "color", default = Color3.fromRGB(255, 255, 255) },
	},
	play = function(ctx, tl)
		local Make, Assets, Quality = ctx.Lab.Make, ctx.Lab.Assets, ctx.Lab.Quality
		local part = Make.part({ CFrame = ctx.origin * CFrame.new(0, 3, 0), Parent = ctx.root })
		local emitter = Make.emitter(part, {
			Texture = Assets.tex("DefaultSparkle"),
			Color = Make.cseq(ctx.params.color),
			Lifetime = NumberRange.new(0.4, 0.7),
			Speed = NumberRange.new(6, 10),
			SpreadAngle = Vector2.new(180, 180),
			Size = Make.seq(0, 0.6, 1, 0),
			Transparency = Make.seq(0, 0, 0.7, 0.2, 1, 1),
			LightEmission = 1,
		})
		tl:track(emitter)
		local light = Make.light(part, "PointLight", { Range = 8, Brightness = 0, Color = ctx.params.color })
		tl:at(0, function()
			emitter:Emit(Quality.count(ctx.params.count))
		end)
		tl:span(0, 0.3, function(a)
			light.Brightness = 2 * (1 - a)
		end, "Quad", "Out")
		tl:mark("End", 0.8) -- last particle fades by 0.7 s
	end,
}
