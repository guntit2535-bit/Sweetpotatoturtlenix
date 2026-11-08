--!strict
-- Plays a default Roblox tool animation for everyone (task 2.22): the character's Animate script reads a
-- "toolanim" StringValue put in the held tool ("Slash" = swing, "Lunge" = stab). Used by the bat swing and
-- the rod cast.

local ToolAnim = {}

function ToolAnim.play(tool: Instance, name: string)
	local old = tool:FindFirstChild("toolanim")
	if old then
		old:Destroy()
	end
	local v = Instance.new("StringValue")
	v.Name = "toolanim"
	v.Value = name
	v.Parent = tool
	task.delay(0.3, function()
		v:Destroy()
	end)
end

return ToolAnim
