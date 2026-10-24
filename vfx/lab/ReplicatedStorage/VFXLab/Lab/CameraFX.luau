--[[
	CameraFX: screen-level juice for the LOCAL player only (call it on the client).
	One RenderStep binding handles every shake, so overlapping hits add up instead of fighting.

	CameraFX.shake(amount, duration?)      trauma-style shake; amount ~0.2 light, 0.5 heavy, 1 huge
	CameraFX.fovPunch(delta, duration?)    widen then ease back (e.g. 8 degrees on a dash)
	CameraFX.flash(props, duration?)       client-only ColorCorrection pulse: { Brightness, Contrast, Saturation, TintColor }
	CameraFX.impactFrame(duration?, style) high-contrast / inverted frame for big hits ("Invert" | "White" | "Dark")

	All of it is scaled by Quality.preset().shake and skipped where Quality says post-FX are off.
	Players who set reduced motion in your settings menu: set CameraFX.enabled = false.
]]
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Quality = require(script.Parent.Quality)

local CameraFX = { enabled = true }

local trauma = 0
local traumaDecay = 1.6
local bound = false
local seed = math.random() * 1000
local lastOffset = CFrame.identity

local function unbind()
	if bound then
		RunService:UnbindFromRenderStep("VFXLabShake")
		bound = false
	end
end

local function bind()
	if bound then
		return
	end
	bound = true
	RunService:BindToRenderStep("VFXLabShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		-- Remove last frame's offset first so the default camera script isn't fought.
		camera.CFrame = camera.CFrame * lastOffset:Inverse()
		trauma = math.max(0, trauma - traumaDecay * dt)
		if trauma <= 0 then
			lastOffset = CFrame.identity
			unbind()
			return
		end
		local t = os.clock() * 22
		local s = trauma * trauma
		lastOffset = CFrame.Angles(
			math.rad(math.noise(seed, t) * 4 * s),
			math.rad(math.noise(seed + 10, t) * 4 * s),
			math.rad(math.noise(seed + 20, t) * 6 * s)
		)
		camera.CFrame = camera.CFrame * lastOffset
	end)
end

function CameraFX.shake(amount, duration)
	if not CameraFX.enabled then
		return
	end
	trauma = math.clamp(trauma + amount * Quality.preset().shake, 0, 1)
	traumaDecay = if duration then 1 / math.max(duration, 0.05) else 1.6
	bind()
end

function CameraFX.fovPunch(delta, duration)
	local camera = workspace.CurrentCamera
	if not (CameraFX.enabled and camera) then
		return
	end
	duration = duration or 0.35
	local base = camera:GetAttribute("VFXBaseFOV") or camera.FieldOfView
	camera:SetAttribute("VFXBaseFOV", base)
	camera.FieldOfView = base + delta
	local tween = TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { FieldOfView = base })
	tween.Completed:Once(function()
		camera:SetAttribute("VFXBaseFOV", nil)
	end)
	tween:Play()
end

function CameraFX.flash(props, duration)
	if not (CameraFX.enabled and Quality.preset().postFX) then
		return
	end
	duration = duration or 0.25
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VFXLabFlash"
	for k, v in props do
		cc[k] = v
	end
	cc.Parent = Lighting
	local tween = TweenService:Create(cc, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
		Contrast = 0,
		Saturation = 0,
		TintColor = Color3.new(1, 1, 1),
	})
	tween.Completed:Once(function()
		cc:Destroy()
	end)
	tween:Play()
end

function CameraFX.impactFrame(duration, style)
	if not (CameraFX.enabled and Quality.preset().postFX) then
		return
	end
	duration = duration or 0.06
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VFXLabImpactFrame"
	if style == "White" then
		cc.Brightness = 0.6
		cc.Contrast = 1
		cc.Saturation = -1
	elseif style == "Dark" then
		cc.Brightness = -0.4
		cc.Contrast = 2
		cc.Saturation = -1
	else
		-- "Invert": strong contrast and desaturation with a cold tint reads as a negative frame.
		cc.Contrast = 3
		cc.Saturation = -1
		cc.TintColor = Color3.fromRGB(200, 220, 255)
	end
	cc.Parent = Lighting
	task.delay(duration, function()
		cc:Destroy()
	end)
end

return CameraFX
