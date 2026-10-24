--[[
	Assets: one place for every texture id and mesh template an effect uses.
	Effects ask for assets by name (Assets.tex("SoftGlow")), never paste raw ids, so swapping a
	placeholder for a final upload is a one-line change here, and the lab can check all of them load.

	Textures live in the TEXTURES table below: name -> { id = "rbxassetid://...", source, status }.
		status: "final" (ours, uploaded), "library" (VFX Studio library / third party: check it loads),
		        "builtin" (rbxasset:// shipped with Roblox), "placeholder" (must be replaced before release)
	Mesh templates are MeshParts under ReplicatedStorage.VFXLab.Assets.Meshes (MeshId can't be set by
	game scripts, so effects clone these): Assets.mesh("Shockwave").

	Assets.check() -> report of every texture's fetch status (run in a playtest client).
]]
local ContentProvider = game:GetService("ContentProvider")

local Assets = {}

-- Built-in textures ship with every client, so they always load. Add uploaded ones below them.
local TEXTURES = {
	DefaultSparkle = { id = "rbxasset://textures/particles/sparkles_main.dds", source = "Roblox built-in", status = "builtin" },
}
Assets.TEXTURES = TEXTURES

local meshFolder = script.Parent.Parent:FindFirstChild("Assets") and script.Parent.Parent.Assets:FindFirstChild("Meshes")

function Assets.tex(name)
	local entry = TEXTURES[name]
	if not entry then
		warn("VFXLab.Assets: unknown texture '" .. tostring(name) .. "', using DefaultSparkle")
		return TEXTURES.DefaultSparkle.id
	end
	return entry.id
end

function Assets.register(name, id, source, status)
	TEXTURES[name] = { id = id, source = source, status = status or "library" }
end

function Assets.mesh(name)
	local template = meshFolder and meshFolder:FindFirstChild(name)
	assert(template, "VFXLab.Assets: no mesh template '" .. tostring(name) .. "' in VFXLab.Assets.Meshes")
	return template:Clone()
end

function Assets.check(timeout)
	local uris, byUri = {}, {}
	for name, entry in TEXTURES do
		table.insert(uris, entry.id)
		byUri[entry.id] = name
	end
	local results = {}
	local done = false
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(uris, function(uri, status)
				results[byUri[uri] or uri] = status.Name
			end)
		end)
		done = true
	end)
	local deadline = os.clock() + (timeout or 15)
	while not done and os.clock() < deadline do
		task.wait(0.1)
	end
	local report = {}
	for name, entry in TEXTURES do
		table.insert(report, string.format("%-24s %-12s %-11s %s", name, results[name] or "Timeout", entry.status, entry.id))
	end
	table.sort(report)
	return report
end

return Assets
