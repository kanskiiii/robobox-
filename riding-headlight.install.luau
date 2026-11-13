-- Run in Studio Edit mode to add the riding headlight.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ServerScriptService.TwoStrokeServer.GarageService] = {
        {[==[local function stopDriving(s: Session)]==], [==[function actions.ToggleHeadlight(s)
	local ride = s.riding
	if not s.driving or not ride then return end
	local assembly = ride.model:FindFirstChild(
		if ride.asm.vehicle == "senda" then "Slot_HeadlightMask" else "Slot_FrontFork"
	)
	local visual = assembly and assembly:FindFirstChild("Visual")
	if not visual or not visual:IsA("BasePart") then return end

	local mount = visual:FindFirstChild("RidingHeadlight")
	if not mount then
		local lens = Instance.new("Attachment")
		lens.Name = "RidingHeadlight"
		lens.CFrame = visual.PivotOffset * (if ride.asm.vehicle == "senda"
			then CFrame.new(0, -.14, -.30) else CFrame.new(0, .36, -.40))
		lens.Parent = visual
		mount = lens
	end
	local beam = mount:FindFirstChildOfClass("SpotLight")
	if not beam then
		beam = Instance.new("SpotLight")
		beam.Name = "Beam"
		beam.Enabled = false
		beam.Face = Enum.NormalId.Front
		beam.Angle = 58
		beam.Range = 48
		beam.Brightness = 4
		beam.Color = Color3.fromRGB(255, 242, 213)
		beam.Parent = mount
	end
	beam.Enabled = not beam.Enabled
	notify(s, if beam.Enabled then "Headlight on" else "Headlight off", "info")
end

local function stopDriving(s: Session)]==]},
        {[==[	s.driving = false
	s.riding = nil]==], [==[	s.driving = false
	s.riding = nil
	local lamp = r.model:FindFirstChild("RidingHeadlight", true)
	if lamp then lamp:Destroy() end]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.BikeController] = {
        {[==[Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.I, Enum.KeyCode.C, Enum.KeyCode.K,]==], [==[Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.I, Enum.KeyCode.C, Enum.KeyCode.K, Enum.KeyCode.L,]==]},
        {[==[	elseif key == Enum.KeyCode.I or key == Enum.KeyCode.DPadUp then]==], [==[	elseif key == Enum.KeyCode.L then
		Remotes.get("Action"):FireServer("ToggleHeadlight")
	elseif key == Enum.KeyCode.I or key == Enum.KeyCode.DPadUp then]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.Hud] = {
        {[==[I ignition  C choke  K kick  Space get off]==], [==[I ignition  C choke  K kick  L headlight  Space get off]==]},
    },
}
local function revise(target, source, edits)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected source in " .. target:GetFullName())
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end
for target, edits in changes do revise(target, editor:GetEditorSource(target), edits) end
for target, edits in changes do
    editor:UpdateSourceAsync(target, function(source) return revise(target, source, edits) end)
end
