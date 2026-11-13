-- Run in Studio Edit mode to animate the installed front assembly while riding.
local controller = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.BikeController
local changes = {
    {[==[local rear: Wheel? = nil]==], [==[local rear: Wheel? = nil
local steeringMounts: { [string]: Weld } = {}]==]},
    {[==[	local oldF, oldR = front, rear]==], [==[	local oldF, oldR = front, rear
	table.clear(steeringMounts)
	for _, slot in { "FrontFork", "Handlebar", "FrontBrake", "FrontFender", "HeadlightMask" } do
		local part = m:FindFirstChild("Slot_" .. slot)
		local mount = part and part:FindFirstChild("Mount")
		if mount and mount:IsA("Weld") and typeof(mount:GetAttribute("BaseC0")) == "CFrame" then
			steeringMounts[slot] = mount
		end
	end]==]},
    {[==[	-- wheel visuals (local only)
	for _, w in { f, b } do]==], [==[	-- Turn the front assembly around the steering head, in chassis space.
	local fork = steeringMounts.FrontFork
	local pivot = if fork then (fork:GetAttribute("BaseC0") :: CFrame).Position else f.offset
	local steering = CFrame.new(pivot) * CFrame.Angles(0, -steerAngle, 0) * CFrame.new(-pivot)
	local frontTravel = CFrame.new(0, (math.clamp(f.compression, 0, f.travel) - f.sag) * SPM, 0)
	for slot, mount in steeringMounts do
		local base = mount:GetAttribute("BaseC0") :: CFrame
		mount.C0 = steering * (if slot == "FrontBrake" then frontTravel else CFrame.identity) * base
	end
	for _, w in { f, b } do]==]},
    {[==[			weld.C0 = CFrame.new(0, drop, 0) * w.baseC0 * CFrame.Angles(-w.spin, 0, 0)]==], [==[			local turn = if w == f then steering else CFrame.identity
			weld.C0 = turn * CFrame.new(0, drop, 0) * w.baseC0 * CFrame.Angles(-w.spin, 0, 0)]==]},
    {[==[	model, root, spec, front, rear = nil, nil, nil, nil, nil]==], [==[	for _, mount in steeringMounts do
		mount.C0 = mount:GetAttribute("BaseC0") :: CFrame
	end
	table.clear(steeringMounts)
	model, root, spec, front, rear = nil, nil, nil, nil, nil]==]},
}
game:GetService("ScriptEditorService"):UpdateSourceAsync(controller, function(source)
    for _, edit in changes do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected BikeController source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end)
