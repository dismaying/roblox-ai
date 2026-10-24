--[[
	VFX: the one module game code talks to. ReplicatedStorage.VFXLab.VFX

	Client (visuals):
		VFX.play(name, payload?)        play an effect locally now -> Timeline (or aura handle)
		VFX.equip(character, name, params?) / VFX.unequip(character, name, instant?)
		VFX.startClient()               listen for server broadcasts and replicated auras (call once)
	Server (gameplay owner):
		VFX.broadcast(name, payload, options?)  every client plays it (see Lab/Net)
		VFX.equipAura(player, name, params?) / VFX.unequipAura(player, name)
		VFX.startServer()               create remotes, accept validated cosmetic requests

	payload = { origin = CFrame | Vector3 | Instance, target = Vector3 | Instance, caster = Player | Model,
	            params = {...}, seed = number, timeScale = number, parent = Instance }

	Effects receive ctx = {
		Lab        = every Lab module (Make, Motion, Rig, CameraFX, Assets, Pool, Quality, Timeline, Scope),
		scope      = cleanup owner (everything you create goes here or under ctx.root),
		root       = a Folder in workspace.VFXLabRuntime holding this play's instances,
		origin     = CFrame,  target = Vector3?,  character = Model?,  caster = Player?,
		params     = resolved params (defaults filled, numbers clamped),
		rng        = Random.new(seed) (same on every client),
		isLocal    = true when the local player is the caster (gate camera shake / UI on this),
		quality    = Quality.preset(),
	}
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Lab = script.Parent:WaitForChild("Lab")
local Scope = require(Lab.Scope)
local Timeline = require(Lab.Timeline)
local Registry = require(Lab.Registry)
local Quality = require(Lab.Quality)
local Aura = require(Lab.Aura)
local Net = require(Lab.Net)

local LabModules = {
	Scope = Scope,
	Timeline = Timeline,
	Quality = Quality,
	Make = require(Lab.Make),
	Motion = require(Lab.Motion),
	Rig = require(Lab.Rig),
	Pool = require(Lab.Pool),
	Assets = require(Lab.Assets),
	Clock = require(Lab.Clock),
	CameraFX = if RunService:IsClient() then require(Lab.CameraFX) else nil,
}

local VFX = { Lab = LabModules, Registry = Registry }

local function runtimeFolder()
	local f = workspace:FindFirstChild("VFXLabRuntime")
	if not f then
		f = Instance.new("Folder")
		f.Name = "VFXLabRuntime"
		f.Parent = workspace
	end
	return f
end

local function toCFrame(at)
	local kind = typeof(at)
	if kind == "CFrame" then
		return at
	elseif kind == "Vector3" then
		return CFrame.new(at)
	elseif kind == "Instance" then
		if at:IsA("Attachment") then
			return at.WorldCFrame
		elseif at:IsA("BasePart") then
			return at.CFrame
		elseif at:IsA("Model") then
			return at:GetPivot()
		elseif at:IsA("Player") and at.Character then
			return at.Character:GetPivot()
		end
	end
	return nil
end

local function characterOf(caster)
	if typeof(caster) ~= "Instance" then
		return nil
	end
	if caster:IsA("Player") then
		return caster.Character
	elseif caster:IsA("Model") then
		return caster
	end
	return nil
end

local function makeCtx(def, payload, scope)
	payload = payload or {}
	local character = characterOf(payload.caster)
	local origin = toCFrame(payload.origin) or (character and character:GetPivot()) or CFrame.identity
	local target = payload.target
	if typeof(target) == "Instance" then
		local cf = toCFrame(target)
		target = cf and cf.Position
	end
	local root = Instance.new("Folder")
	root.Name = def.name
	root.Parent = payload.parent or runtimeFolder()
	scope:add(root)
	local caster = payload.caster
	return {
		Lab = LabModules,
		def = def,
		scope = scope,
		root = root,
		origin = origin,
		target = target,
		character = character,
		caster = caster,
		params = Registry.resolveParams(def, payload.params),
		rng = Random.new(payload.seed or math.random(1, 2 ^ 30)),
		isLocal = RunService:IsClient()
			and caster ~= nil
			and (caster == Players.LocalPlayer or caster == Players.LocalPlayer.Character),
		quality = Quality.preset(),
	}
end

function VFX.play(name, payload)
	local def = if type(name) == "table" then name else Registry.get(name)
	if not def then
		warn("VFX.play: no effect named " .. tostring(name))
		return nil
	end
	payload = payload or {}

	if def.kind == "aura" then
		local character = characterOf(payload.caster) or (typeof(payload.origin) == "Instance" and payload.origin:IsA("Model") and payload.origin)
		assert(character, "VFX.play: aura '" .. def.name .. "' needs payload.caster (a Player or character Model)")
		return VFX.equip(character, def, payload.params)
	end

	if def.kind == "template" then
		-- Attribute-driven effect (VFX Studio / Ropilot Emit convention) played by ReplicatedStorage.VFX.Emit.
		local emitModule = game:GetService("ReplicatedStorage"):FindFirstChild("VFX")
		emitModule = emitModule and emitModule:FindFirstChild("Emit")
		assert(emitModule, "VFX.play: template effects need ReplicatedStorage.VFX.Emit")
		local Emit = require(emitModule)
		return Emit.play(def.template, toCFrame(payload.origin) or CFrame.identity, { parent = runtimeFolder() })
	end

	assert(def.play, "VFX.play: effect '" .. def.name .. "' has no play(ctx, tl)")
	local tl = Timeline.new()
	local ctx = makeCtx(def, payload, tl.scope)
	ctx.timeline = tl
	local ok, err = pcall(def.play, ctx, tl)
	if not ok then
		warn("VFX.play: " .. def.name .. " failed while scheduling: " .. tostring(err))
		tl:stop()
		return nil
	end
	-- Hard cap: no one-shot outlives 30 s unless it asked to hold (environment / cinematic loops).
	if not tl._holdOpen then
		tl.scope:add(task.delay(30, function()
			tl:stop()
		end))
	end
	tl:play({ timeScale = payload.timeScale })
	return tl
end

function VFX.equip(character, nameOrDef, params)
	local def = if type(nameOrDef) == "table" then nameOrDef else Registry.get(nameOrDef)
	assert(def and def.kind == "aura", "VFX.equip: '" .. tostring(nameOrDef) .. "' is not an aura")
	local scope = Scope.new()
	local ctx = makeCtx(def, { caster = character, params = params }, scope)
	local handle = Aura.equip(character, def, ctx)
	-- Aura.equip makes its own scope; fold the ctx folder's scope into it.
	handle.scope:add(scope)
	return handle
end

function VFX.unequip(character, name, instant)
	local handle = Aura.get(character, name)
	if handle then
		handle:unequip(instant)
	end
end

-- ------------------------------------------------------------------ networking

function VFX.broadcast(name, payload, options)
	Net.broadcast(name, payload, options)
end

function VFX.equipAura(player, name, params)
	Net.equipAura(player, name, params)
end

function VFX.unequipAura(player, name)
	Net.unequipAura(player, name)
end

function VFX.request(name, payload)
	Net.request(name, payload)
end

function VFX.startServer()
	Net.startServer(Registry)
end

-- Auras this client equipped because the server said so (lab previews are left alone).
local replicated = setmetatable({}, { __mode = "k" })

local function syncAuras(player)
	-- Mirror the player's replicated aura list onto their current character.
	local character = player.Character
	if not character then
		return
	end
	local list = player:GetAttribute("VFXAuras")
	local wanted = {}
	if type(list) == "string" and list ~= "" then
		for _, name in string.split(list, ",") do
			wanted[name] = true
		end
	end
	local mine = replicated[character] or {}
	replicated[character] = mine
	for name in wanted do
		if not Aura.get(character, name) and Registry.get(name) then
			mine[name] = true
			local raw = player:GetAttribute("VFXAura_" .. name)
			local params = nil
			if type(raw) == "string" then
				local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
				params = if ok then decoded else nil
			end
			VFX.equip(character, name, params)
		end
	end
	for name in table.clone(mine) do
		if not wanted[name] then
			mine[name] = nil
			local handle = Aura.get(character, name)
			if handle then
				handle:unequip(false)
			end
		end
	end
end

function VFX.startClient()
	assert(RunService:IsClient(), "VFX.startClient is client-only")
	Net.onPlay(function(name, payload)
		VFX.play(name, payload)
	end)
	local function watch(player)
		player:GetAttributeChangedSignal("VFXAuras"):Connect(function()
			syncAuras(player)
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			syncAuras(player)
		end)
		if player.Character then
			task.spawn(syncAuras, player)
		end
	end
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
end

return VFX
