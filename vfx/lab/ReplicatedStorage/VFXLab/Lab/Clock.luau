--[[
	Clock: one Heartbeat connection shared by every running effect.
	Subscribers get (dt) each frame and unsubscribe by returning false or calling the returned function.
	The connection exists only while something is subscribed, so an idle lab costs nothing.
	A subscriber that errors is removed and reported once, so one broken effect cannot spam or stall the rest.

	local stop = Clock.every(function(dt) ... end)
	stop()
]]
local RunService = game:GetService("RunService")

local Clock = {}

local subscribers = {}
local count = 0
local connection = nil

local function step(dt)
	for fn in subscribers do
		local ok, keep = pcall(fn, dt)
		if not ok then
			warn("VFXLab.Clock: subscriber error, removed: " .. tostring(keep))
			subscribers[fn] = nil
			count -= 1
		elseif keep == false then
			subscribers[fn] = nil
			count -= 1
		end
	end
	if count <= 0 and connection then
		count = 0
		connection:Disconnect()
		connection = nil
	end
end

function Clock.every(fn)
	if not subscribers[fn] then
		subscribers[fn] = true
		count += 1
	end
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
	return function()
		if subscribers[fn] then
			subscribers[fn] = nil
			count -= 1
		end
	end
end

function Clock.activeCount()
	return count
end

return Clock
