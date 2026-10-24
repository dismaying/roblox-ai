--[[
	Rig: find the places on a character that effects attach to, for R15 (and R6 where it exists).

	Rig.root(character)                     HumanoidRootPart
	Rig.part(character, "RightHand")        a body part, nil if missing
	Rig.attachment(character, "RightGrip")  named rig attachment ("RightGrip" -> RightGripAttachment)
	Rig.socket(character, name, cframe?)    a new Attachment parented to the named part (Scope it!)
	Rig.isR15(character)
	Rig.speed(character)                    horizontal speed in studs/s (for movement-reactive auras)
	Rig.grounded(character)

	Common R15 attachments: RootRigAttachment, WaistCenterAttachment, BodyFrontAttachment, BodyBackAttachment,
	NeckAttachment, HatAttachment (Head), FaceFrontAttachment, LeftGripAttachment, RightGripAttachment,
	LeftFootAttachment, RightFootAttachment, LeftShoulderAttachment, RightShoulderAttachment.
]]
local Rig = {}

local R6_FALLBACK = {
	RightHand = "Right Arm",
	LeftHand = "Left Arm",
	UpperTorso = "Torso",
	LowerTorso = "Torso",
	RightFoot = "Right Leg",
	LeftFoot = "Left Leg",
}

function Rig.humanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

function Rig.isR15(character)
	local h = Rig.humanoid(character)
	return h ~= nil and h.RigType == Enum.HumanoidRigType.R15
end

function Rig.root(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

function Rig.part(character, name)
	if not character then
		return nil
	end
	return character:FindFirstChild(name) or (R6_FALLBACK[name] and character:FindFirstChild(R6_FALLBACK[name]))
end

function Rig.attachment(character, name)
	if not character then
		return nil
	end
	local full = if string.sub(name, -10) == "Attachment" then name else name .. "Attachment"
	for _, d in character:GetDescendants() do
		if d:IsA("Attachment") and d.Name == full and d.Parent and d.Parent:IsA("BasePart") then
			return d
		end
	end
	return nil
end

function Rig.socket(character, partName, cframe, name)
	local part = Rig.part(character, partName)
	assert(part, "Rig.socket: character has no part " .. tostring(partName))
	local a = Instance.new("Attachment")
	a.Name = name or "VFXSocket"
	a.CFrame = cframe or CFrame.identity
	a.Parent = part
	return a
end

function Rig.speed(character)
	local root = Rig.root(character)
	if not root then
		return 0
	end
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

function Rig.grounded(character)
	local h = Rig.humanoid(character)
	return h ~= nil and h.FloorMaterial ~= Enum.Material.Air
end

return Rig
