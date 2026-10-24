--[[
	VFXLab client bootstrap. StarterPlayerScripts.VFXLab.LabClient

	- Starts the VFX client (server broadcasts + replicated auras). The game needs this part too.
	- In Studio, when workspace.VFXLab has LabEnabled = true, opens the lab preview panel.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VFX = require(ReplicatedStorage:WaitForChild("VFXLab"):WaitForChild("VFX"))
VFX.startClient()

local labFolder = workspace:WaitForChild("VFXLab", 5)
if RunService:IsStudio() and labFolder and labFolder:GetAttribute("LabEnabled") then
	require(script.Parent:WaitForChild("LabPanel")).start(VFX)
end
