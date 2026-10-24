--[[
	Net: how effects reach every player without the server building them.

	Rule: gameplay (damage, hit detection, cooldowns, rewards) happens on the SERVER. Visuals are built on
	each CLIENT. The server sends one small message: which effect, where, and a few params.

	Server:
		Net.broadcast(name, payload, options?)    to everyone, or options.near = Vector3 + options.radius,
		                                          or options.except = player (they already predicted it)
		Net.equipAura(player, name, params)       replicated aura state (late joiners get it too)
		Net.unequipAura(player, name)
		Net.allowRequests(name, cooldown)         lets clients ask the server to broadcast a cosmetic effect
	Client:
		Net.request(name, payload)                ask the server (validated, rate-limited) to broadcast
		Net.onPlay(fn)                            fn(name, payload) for broadcasts (VFX wires this up)

	payload = { origin = CFrame?, target = Vector3?, caster = Player?, params = {...}, seed = number }
	The seed lets every client pick the same random variations.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local root = ReplicatedStorage:WaitForChild("VFXLab")
local REMOTE_NAMES = { "Play", "Request" }

local function remote(name)
	local folder = root:FindFirstChild("Remotes")
	if RunService:IsServer() then
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = root
		end
		local r = folder:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
		return r
	end
	folder = folder or root:WaitForChild("Remotes")
	return folder:WaitForChild(name)
end

-- ---------------------------------------------------------------- server

local allowed = {} -- name -> cooldown seconds
local lastRequest = {} -- player -> { [name] = time }
local MAX_PAYLOAD_DISTANCE = 300 -- origin must be near the requesting character

function Net.allowRequests(name, cooldown)
	allowed[name] = cooldown or 0.25
end

function Net.broadcast(name, payload, options)
	assert(RunService:IsServer(), "Net.broadcast is server-only")
	payload = payload or {}
	payload.seed = payload.seed or math.random(1, 2 ^ 30)
	local play = remote("Play")
	options = options or {}
	if not options.near and not options.except then
		play:FireAllClients(name, payload)
		return
	end
	for _, player in Players:GetPlayers() do
		if player ~= options.except then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not options.near or (root and (root.Position - options.near).Magnitude <= (options.radius or 250)) then
				play:FireClient(player, name, payload)
			end
		end
	end
end

function Net.equipAura(player, name, params)
	assert(RunService:IsServer(), "Net.equipAura is server-only")
	-- Stored as an attribute on the player so late joiners and respawns see it without extra messages.
	local list = player:GetAttribute("VFXAuras")
	local auras = if type(list) == "string" and list ~= "" then string.split(list, ",") else {}
	if not table.find(auras, name) then
		table.insert(auras, name)
	end
	player:SetAttribute("VFXAuras", table.concat(auras, ","))
	player:SetAttribute("VFXAura_" .. name, if params then game:GetService("HttpService"):JSONEncode(params) else nil)
end

function Net.unequipAura(player, name)
	local list = player:GetAttribute("VFXAuras")
	local auras = if type(list) == "string" and list ~= "" then string.split(list, ",") else {}
	local i = table.find(auras, name)
	if i then
		table.remove(auras, i)
	end
	player:SetAttribute("VFXAuras", table.concat(auras, ","))
	player:SetAttribute("VFXAura_" .. name, nil)
end

function Net.startServer(registry)
	assert(RunService:IsServer())
	remote("Play")
	local request = remote("Request")
	request.OnServerEvent:Connect(function(player, name, payload)
		-- Validate everything: type, allow-list, cooldown, distance. Cosmetic only, never gameplay.
		if type(name) ~= "string" or not allowed[name] then
			return
		end
		local def = registry and registry.get(name)
		if not def then
			return
		end
		local now = os.clock()
		local times = lastRequest[player] or {}
		lastRequest[player] = times
		if times[name] and now - times[name] < allowed[name] then
			return
		end
		times[name] = now
		payload = if type(payload) == "table" then payload else {}
		local clean = { caster = player, params = registry.resolveParams(def, payload.params) }
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		if typeof(payload.origin) == "CFrame" and (payload.origin.Position - hrp.Position).Magnitude <= MAX_PAYLOAD_DISTANCE then
			clean.origin = payload.origin
		else
			clean.origin = hrp.CFrame
		end
		if typeof(payload.target) == "Vector3" and (payload.target - hrp.Position).Magnitude <= MAX_PAYLOAD_DISTANCE then
			clean.target = payload.target
		end
		if def.serverValidate and not def.serverValidate(player, clean) then
			return
		end
		Net.broadcast(name, clean, { except = if payload.predicted then player else nil })
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

-- ---------------------------------------------------------------- client

function Net.request(name, payload)
	remote("Request"):FireServer(name, payload)
end

function Net.onPlay(fn)
	return remote("Play").OnClientEvent:Connect(fn)
end

Net.REMOTE_NAMES = REMOTE_NAMES
return Net
