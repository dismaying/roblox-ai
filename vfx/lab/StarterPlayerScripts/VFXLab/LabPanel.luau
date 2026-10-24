--[[
	VFXLab preview panel (Studio only). Pick an effect, a target and parameters, then play it,
	equip it, slow it down or test it on low quality, without editing code.

	Targets: Me (your character), every rig in workspace.VFXLab.Rigs, and every part in
	workspace.VFXLab.Pads. Key: F6 toggles the panel.
]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LabPanel = {}

local COLORS = {
	bg = Color3.fromRGB(18, 19, 26),
	panel = Color3.fromRGB(28, 30, 40),
	item = Color3.fromRGB(40, 43, 58),
	itemOn = Color3.fromRGB(88, 101, 242),
	text = Color3.fromRGB(235, 236, 245),
	dim = Color3.fromRGB(150, 154, 175),
	good = Color3.fromRGB(67, 181, 129),
	bad = Color3.fromRGB(240, 71, 71),
}

local function new(className, props, children)
	local inst = Instance.new(className)
	for k, v in props or {} do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 6) })
end

local function button(text, parent, onClick, width)
	local b = new("TextButton", {
		Text = text,
		Size = UDim2.new(width or 1, width and 0 or 0, 0, 26),
		BackgroundColor3 = COLORS.item,
		TextColor3 = COLORS.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		AutoButtonColor = true,
		Parent = parent,
	}, { corner(5) })
	b.Activated:Connect(onClick)
	return b
end

local function label(text, parent, size)
	return new("TextLabel", {
		Text = text,
		Size = UDim2.new(1, 0, 0, size or 18),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.dim,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = parent,
	})
end

local function list(parent, padding)
	return new("UIListLayout", { Padding = UDim.new(0, padding or 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = parent })
end

local function parseColor(text)
	local r, g, b = string.match(text, "(%d+)%D+(%d+)%D+(%d+)")
	if r then
		return Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
	end
	local hex = string.match(text, "#?(%x%x%x%x%x%x)")
	if hex then
		return Color3.fromHex(hex)
	end
	return nil
end

function LabPanel.start(VFX)
	local player = Players.LocalPlayer
	local Quality = VFX.Lab.Quality
	local Clock = VFX.Lab.Clock
	local lab = workspace:WaitForChild("VFXLab")

	local state = {
		effect = nil,
		targetIndex = 1,
		params = {},
		timeScale = 1,
		viaServer = false,
		running = {},
	}

	local gui = new("ScreenGui", { Name = "VFXLabPanel", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	local root = new("Frame", {
		Size = UDim2.fromOffset(560, 420),
		Position = UDim2.new(0, 16, 1, -436),
		BackgroundColor3 = COLORS.bg,
		BackgroundTransparency = 0.05,
		Parent = gui,
	}, { corner(10), new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	new("TextLabel", { Text = "VFX LAB", Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = root })
	local stats = new("TextLabel", { Text = "", Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(80, 0), BackgroundTransparency = 1, TextColor3 = COLORS.dim, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = root })

	-- Left: effect list
	local effectList = new("ScrollingFrame", {
		Size = UDim2.new(0, 200, 1, -28),
		Position = UDim2.fromOffset(0, 28),
		BackgroundColor3 = COLORS.panel,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = root,
	}, { corner(8), new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }) })
	list(effectList)

	-- Right: controls
	local right = new("ScrollingFrame", {
		Size = UDim2.new(1, -210, 1, -28),
		Position = UDim2.fromOffset(210, 28),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = root,
	})
	list(right, 6)
	local info = label("Pick an effect on the left.", right, 34)
	info.TextColor3 = COLORS.text

	local function row(parent)
		local r = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = parent })
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = r })
		return r
	end

	local function targets()
		local out = { { name = "Me", get = function()
			return player.Character
		end } }
		local rigs = lab:FindFirstChild("Rigs")
		for _, rig in (rigs and rigs:GetChildren() or {}) do
			table.insert(out, { name = "Rig: " .. rig.Name, get = function()
				return rig
			end })
		end
		local pads = lab:FindFirstChild("Pads")
		for _, pad in (pads and pads:GetChildren() or {}) do
			table.insert(out, { name = "Pad: " .. pad.Name, get = function()
				return pad
			end })
		end
		return out
	end

	local targetRow = row(right)
	local targetButton
	targetButton = button("Target: Me", targetRow, function()
		local all = targets()
		state.targetIndex = state.targetIndex % #all + 1
		targetButton.Text = "Target: " .. all[state.targetIndex].name
	end, 0.7)
	button("Go to lab", targetRow, function()
		local spawnPart = lab:FindFirstChild("LabSpawn")
		local char = player.Character
		if spawnPart and char then
			char:PivotTo(spawnPart.CFrame + Vector3.new(0, 4, 0))
		end
	end, 0.29)

	local function currentTarget()
		local all = targets()
		local t = all[math.clamp(state.targetIndex, 1, #all)]
		return t and t.get()
	end

	local paramsFrame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = right })
	list(paramsFrame)

	local function payload()
		local target = currentTarget()
		local p = { params = table.clone(state.params), timeScale = state.timeScale }
		if target and target:IsA("Model") then
			p.caster = if target == player.Character then player else target
			p.origin = target:GetPivot()
		elseif target then
			p.origin = target.CFrame * CFrame.new(0, target.Size.Y / 2, 0)
		end
		-- Abilities aim 30 studs ahead of the caster by default.
		p.target = (p.origin or CFrame.identity) * Vector3.new(0, 0, -30)
		return p
	end

	local actions = row(right)
	button("Play", actions, function()
		if not state.effect then
			return
		end
		local p = payload()
		if state.effect.kind == "aura" then
			info.Text = "Auras: use Equip."
			return
		end
		if state.viaServer then
			p.caster = nil
			VFX.request(state.effect.name, { origin = p.origin, target = p.target, params = p.params })
		else
			local handle = VFX.play(state.effect, p)
			if handle then
				table.insert(state.running, handle)
			end
		end
	end, 0.24)
	button("Equip", actions, function()
		local target = currentTarget()
		if state.effect and state.effect.kind == "aura" and target and target:IsA("Model") then
			VFX.equip(target, state.effect, table.clone(state.params))
		end
	end, 0.24)
	button("Unequip", actions, function()
		local target = currentTarget()
		if state.effect and target and target:IsA("Model") then
			VFX.unequip(target, state.effect.name, false)
		end
	end, 0.24)
	button("Stop all", actions, function()
		for _, h in state.running do
			if h.stop then
				h:stop()
			end
		end
		state.running = {}
		for _, t in targets() do
			local m = t.get()
			if m and m:IsA("Model") then
				require(game:GetService("ReplicatedStorage").VFXLab.Lab.Aura).unequipAll(m, true)
			end
		end
	end, 0.25)

	local speedRow = row(right)
	local speedButtons = {}
	for _, s in { 1, 0.5, 0.25, 0.1 } do
		speedButtons[s] = button(s .. "x", speedRow, function()
			state.timeScale = s
			for value, b in speedButtons do
				b.BackgroundColor3 = if value == s then COLORS.itemOn else COLORS.item
			end
			for _, h in state.running do
				if h.setTimeScale and not h.finished then
					h:setTimeScale(s)
				end
			end
		end, 0.24)
	end
	speedButtons[1].BackgroundColor3 = COLORS.itemOn

	local qualityRow = row(right)
	local qualityButtons = {}
	for i, q in { { "Auto", nil }, { "Low", 1 }, { "Med", 2 }, { "High", 3 } } do
		qualityButtons[i] = button("Q: " .. q[1], qualityRow, function()
			Quality.set(q[2])
			for j, b in qualityButtons do
				b.BackgroundColor3 = if j == i then COLORS.itemOn else COLORS.item
			end
		end, 0.24)
	end
	qualityButtons[1].BackgroundColor3 = COLORS.itemOn

	local modeRow = row(right)
	local modeButton
	modeButton = button("Mode: Local preview", modeRow, function()
		state.viaServer = not state.viaServer
		modeButton.Text = if state.viaServer then "Mode: Via server (replication test)" else "Mode: Local preview"
	end, 0.7)

	local function selectEffect(def)
		state.effect = def
		state.params = VFX.Registry.resolveParams(def, {})
		info.Text = string.format("%s  [%s, tier %s]\n%s", def.name, def.kind or "?", tostring(def.tier or "?"), def.description or "")
		paramsFrame:ClearAllChildren()
		list(paramsFrame)
		for key, spec in def.params or {} do
			local r = row(paramsFrame)
			new("TextLabel", { Text = key, Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = COLORS.dim, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
			if spec.type == "bool" then
				local b
				b = button(tostring(state.params[key]), r, function()
					state.params[key] = not state.params[key]
					b.Text = tostring(state.params[key])
				end, 0.58)
			else
				local current = state.params[key]
				local text = if typeof(current) == "Color3"
					then string.format("%d, %d, %d", current.R * 255, current.G * 255, current.B * 255)
					else tostring(current)
				local box = new("TextBox", {
					Text = text,
					Size = UDim2.new(0.58, 0, 1, 0),
					BackgroundColor3 = COLORS.item,
					TextColor3 = COLORS.text,
					Font = Enum.Font.Code,
					TextSize = 12,
					ClearTextOnFocus = false,
					Parent = r,
				}, { corner(5) })
				box.FocusLost:Connect(function()
					local value
					if spec.type == "color" then
						value = parseColor(box.Text)
					elseif spec.type == "number" then
						value = tonumber(box.Text)
					else
						value = box.Text
					end
					if value ~= nil then
						state.params[key] = value
						state.params = VFX.Registry.resolveParams(def, state.params)
					end
					local v = state.params[key]
					box.Text = if typeof(v) == "Color3" then string.format("%d, %d, %d", v.R * 255, v.G * 255, v.B * 255) else tostring(v)
				end)
			end
		end
	end

	local function rebuildList(defs)
		for _, c in effectList:GetChildren() do
			if c:IsA("GuiButton") or c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		local lastKind = nil
		for _, def in defs do
			if def.kind ~= lastKind then
				lastKind = def.kind
				label(string.upper(def.kind or "?"), effectList)
			end
			button(def.name, effectList, function()
				selectEffect(def)
			end)
		end
		if #defs == 0 then
			label("No effects yet. Add ModuleScripts to ReplicatedStorage.VFXLab.Effects.", effectList, 48)
		end
	end
	rebuildList(VFX.Registry.list(true))

	local toolsRow = row(right)
	button("Reload effects", toolsRow, function()
		rebuildList(VFX.Registry.reload())
		info.Text = "Reloaded."
	end, 0.49)
	button("Check textures", toolsRow, function()
		info.Text = "Checking textures..."
		task.spawn(function()
			local report = VFX.Lab.Assets.check(15)
			print("VFXLab texture check:\n" .. table.concat(report, "\n"))
			info.Text = "Texture report printed to Output (" .. #report .. " entries)."
		end)
	end, 0.49)

	-- Live stats: shared-clock subscribers, runtime instances, emitters.
	task.spawn(function()
		while gui.Parent do
			local runtime = workspace:FindFirstChild("VFXLabRuntime")
			local instances, emitters = 0, 0
			if runtime then
				for _, d in runtime:GetDescendants() do
					instances += 1
					if d:IsA("ParticleEmitter") then
						emitters += 1
					end
				end
			end
			local q = Quality.preset()
			stats.Text = string.format("clock %d | runtime %d inst, %d emitters | %s", Clock.activeCount(), instances, emitters, q.name)
			for i = #state.running, 1, -1 do
				if state.running[i].finished then
					table.remove(state.running, i)
				end
			end
			task.wait(0.5)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F6 then
			root.Visible = not root.Visible
		end
	end)
end

return LabPanel
