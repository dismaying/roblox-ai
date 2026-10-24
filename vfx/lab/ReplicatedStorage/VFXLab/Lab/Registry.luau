--[[
	Registry: the list of effects the lab (and the game) can play.
	Every ModuleScript under ReplicatedStorage.VFXLab.Effects (any depth) that returns a table with a
	`name` is an effect definition. Folders are just for organising (Auras/, Combat/, Environment/...).
	Names starting with "_" are lab-only (hidden outside Studio).

	Registry.get("CosmicHalo") -> definition
	Registry.list()            -> sorted array of definitions
	Registry.reload()          -> re-require after you edit an effect (lab panel button)

	Definition fields (see Effects/README):
		name, kind ("aura" | "oneshot" | "ability" | "environment" | "cinematic" | "template"),
		tier (1-5), tags = {}, description,
		params = { key = { type = "number"|"color"|"bool", default, min, max } },
		build(ctx)      for kind "aura"
		play(ctx, tl)   for everything else: schedule beats on tl (a Timeline)
		template        for kind "template": name/path of an attribute-driven effect played by Ropilot Emit
		serverValidate(player, params) -> bool   optional extra check before a client request is broadcast
]]
local RunService = game:GetService("RunService")

local Registry = {}

local effectsFolder = script.Parent.Parent:WaitForChild("Effects")
local cache = nil

local function load()
	cache = {}
	for _, module in effectsFolder:GetDescendants() do
		if module:IsA("ModuleScript") then
			-- Clone so reload() picks up edits (require caches by instance).
			local source = if RunService:IsStudio() then module:Clone() else module
			local ok, def = pcall(require, source)
			if ok and type(def) == "table" and type(def.name) == "string" then
				def.module = module
				if cache[def.name] then
					warn("VFXLab.Registry: duplicate effect name " .. def.name .. " in " .. module:GetFullName())
				end
				cache[def.name] = def
			elseif not ok then
				warn("VFXLab.Registry: " .. module:GetFullName() .. " failed to load: " .. tostring(def))
			end
		end
	end
end

function Registry.get(name)
	if not cache then
		load()
	end
	return cache[name]
end

function Registry.list(includeLabOnly)
	if not cache then
		load()
	end
	local out = {}
	for name, def in cache do
		if includeLabOnly or string.sub(name, 1, 1) ~= "_" or RunService:IsStudio() then
			table.insert(out, def)
		end
	end
	table.sort(out, function(a, b)
		if (a.kind or "") ~= (b.kind or "") then
			return (a.kind or "") < (b.kind or "")
		end
		return a.name < b.name
	end)
	return out
end

function Registry.reload()
	load()
	return Registry.list(true)
end

-- Fills missing params with defaults and clamps numbers, so a definition never sees junk.
function Registry.resolveParams(def, params)
	local out = {}
	params = params or {}
	for key, spec in def.params or {} do
		local v = params[key]
		if spec.type == "number" then
			v = if type(v) == "number" and v == v then v else spec.default
			if spec.min then
				v = math.max(v, spec.min)
			end
			if spec.max then
				v = math.min(v, spec.max)
			end
		elseif spec.type == "color" then
			v = if typeof(v) == "Color3" then v else spec.default
		elseif spec.type == "bool" then
			v = if type(v) == "boolean" then v else spec.default
		else
			v = if v ~= nil then v else spec.default
		end
		out[key] = v
	end
	return out
end

return Registry
