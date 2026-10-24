--[[
	VFXLab server bootstrap. ServerScriptService.VFXLab.LabServer

	- Starts VFX networking (remotes + validated cosmetic requests). The game needs this part too.
	- In Studio only: lets the lab panel ask for any registered effect through the server, so the
	  "Via server" mode tests the real replication path, and keeps the preview rigs anchored in place.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VFX = require(ReplicatedStorage:WaitForChild("VFXLab"):WaitForChild("VFX"))
VFX.startServer()

if RunService:IsStudio() then
	local labEnabled = workspace:FindFirstChild("VFXLab") and workspace.VFXLab:GetAttribute("LabEnabled")
	if labEnabled then
		for _, def in VFX.Registry.list(true) do
			if def.kind ~= "aura" then
				require(ReplicatedStorage.VFXLab.Lab.Net).allowRequests(def.name, 0.1)
			end
		end
	end
end
