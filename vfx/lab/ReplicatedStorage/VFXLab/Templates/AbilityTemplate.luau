--[[
	Copy into ReplicatedStorage.VFXLab.Effects/<Folder>/<Name>. Not loaded from Templates.

	Combat timeline: Anticipation -> Charge -> Release -> Impact -> Residual -> Cleanup.
	Put the beats on named marks so timing is tuned in one place and the server's hit time matches:
	the SERVER decides the hit (hitbox at "Impact"); clients only draw it.
	If an animation drives the ability, align marks to its KeyframeMarkers (see cookbook/animation/01).
]]
return {
	name = "MyAbility",
	kind = "ability",
	tier = 3,
	tags = { "combat" },
	description = "One sentence.",
	params = {
		color = { type = "color", default = Color3.fromRGB(120, 200, 255) },
		power = { type = "number", default = 1, min = 0.5, max = 3 },
	},
	play = function(ctx, tl)
		local Make, Motion, CameraFX = ctx.Lab.Make, ctx.Lab.Motion, ctx.Lab.CameraFX
		tl:mark("Anticipation", 0)
		tl:mark("Charge", 0.12)
		tl:mark("Release", 0.45)
		tl:mark("Impact", 0.55)
		tl:mark("Residual", 0.7)
		tl:mark("End", 1.6)

		tl:at("Anticipation", function(scope) end) -- small pull-in, gather particles (ShapeInOut Inward)
		tl:at("Charge", function(scope) end) -- glow builds, light ramps, sound rises
		tl:at("Release", function(scope) end) -- projectile / slash / beam leaves
		tl:at("Impact", function(scope)
			-- brightest frame: flash, sparks, shockwave, light pop; hitstop: tl:freeze(0.06)
			if ctx.isLocal and CameraFX then
				CameraFX.shake(0.4)
			end
		end)
		tl:at("Residual", function(scope) end) -- smoke, embers, ground scorch fade
	end,
}
