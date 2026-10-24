--[[
	Scope: owns everything an effect creates and cleans it up in one call.
	Add instances, connections, threads, tweens or functions; Destroy() releases them in reverse order.
	A scope can own child scopes, so an ability's scope cleans its sub-effects too.

	local scope = Scope.new()
	scope:add(part)                         -- Destroy()ed
	scope:add(conn)                         -- Disconnect()ed
	scope:add(function() ... end)           -- called
	scope:add(task.delay(1, fn))            -- task.cancel()ed
	scope:destroy()
]]
local Scope = {}
Scope.__index = Scope

function Scope.new()
	return setmetatable({ _items = {}, destroyed = false }, Scope)
end

-- Returns the item so calls can be chained: local p = scope:add(Instance.new("Part"))
function Scope:add(item)
	if self.destroyed then
		Scope._release(item)
		return item
	end
	table.insert(self._items, item)
	return item
end

function Scope:child()
	local sub = Scope.new()
	self:add(sub)
	return sub
end

function Scope._release(item)
	local kind = typeof(item)
	if kind == "Instance" then
		if item:IsA("Tween") then
			item:Cancel()
		end
		item:Destroy()
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "thread" then
		pcall(task.cancel, item)
	elseif kind == "function" then
		item()
	elseif kind == "table" and type(item.destroy) == "function" then
		item:destroy()
	elseif kind == "table" and type(item.Destroy) == "function" then
		item:Destroy()
	end
end

function Scope:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		local ok, err = pcall(Scope._release, items[i])
		if not ok then
			warn("VFXLab.Scope: cleanup step failed: " .. tostring(err))
		end
	end
end

Scope.Destroy = Scope.destroy

return Scope
