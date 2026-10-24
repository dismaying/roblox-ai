--[[
	VFXLab installer / updater. Run in Studio's command bar (or through Ropilot's edit-context command).
	Downloads every file in vfx/lab/manifest.txt from GitHub and (re)creates the scripts under
	ReplicatedStorage.VFXLab, ServerScriptService.VFXLab and StarterPlayerScripts.VFXLab.
	Only touches those VFXLab folders. Needs Studio HTTP access for plugins / the command bar.
]]
local BRANCH = "claude/project-thread-5u6ptj"
local BASE = "https://raw.githubusercontent.com/dismaying/roblox-ai/" .. BRANCH .. "/vfx/lab/"
local Http = game:GetService("HttpService")
local SERVICES = {
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	ServerScriptService = game:GetService("ServerScriptService"),
	StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"),
}
local function get(path)
	return Http:GetAsync(BASE .. path .. "?t=" .. os.time(), true)
end
local made = {}
for line in string.gmatch(get("manifest.txt"), "[^\r\n]+") do
	local parts = string.split(line, "/")
	local parent = SERVICES[parts[1]]
	assert(parent, "unknown service in manifest: " .. line)
	for i = 2, #parts - 1 do
		local f = parent:FindFirstChild(parts[i])
		if not f then
			f = Instance.new("Folder")
			f.Name = parts[i]
			f.Parent = parent
		end
		parent = f
	end
	local file = parts[#parts]:gsub("%.luau$", "")
	local class = "ModuleScript"
	if file:match("%.server$") then
		file, class = file:gsub("%.server$", ""), "Script"
	elseif file:match("%.client$") then
		file, class = file:gsub("%.client$", ""), "LocalScript"
	end
	local existing = parent:FindFirstChild(file)
	if existing and existing.ClassName ~= class then
		existing:Destroy()
		existing = nil
	end
	local s = existing or Instance.new(class)
	s.Name = file
	s.Source = get(line)
	s.Parent = parent
	table.insert(made, s:GetFullName())
end
print("VFXLab installed " .. #made .. " scripts")
return made
