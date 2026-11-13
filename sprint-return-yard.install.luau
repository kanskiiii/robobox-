-- Run in Studio Edit after installing sprint-best.install.luau.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ServerScriptService.TwoStrokeServer.GarageService] = {
        {[==[function actions.ReturnTestBike(s, which)]==], [==[function actions.ReturnTestBike(s, which, returnRider)]==]},
        {[==[	local root = r.model.PrimaryPart
	if not root then return end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	r.model:PivotTo(r.yardPose)
	notify(s, "Test bike returned to your garage yard.", "good")]==], [==[	local root = r.model.PrimaryPart
	if not root then return end
	local rider: Model? = nil
	if returnRider == true then
		local char, hum = character(s)
		if which ~= "test" or not char or not hum or hum.Health <= 0 or hum.SeatPart then return end
		local map = Workspace:FindFirstChild("Map")
		local road = map and map:FindFirstChild("Road")
		if not road or not road:IsA("BasePart") or not RoadSprint.isNearFinish(road, char:GetPivot().Position) then
			notify(s, "Use this from the sprint finish area.", "warn")
			return
		end
		if s.carrying then
			notify(s, "Put down the part before returning to the yard.", "warn")
			return
		end
		rider = char
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	r.model:PivotTo(r.yardPose)
	if rider then
		local riderRoot = rider.PrimaryPart
		if riderRoot then
			riderRoot.AssemblyLinearVelocity = Vector3.zero
			riderRoot.AssemblyAngularVelocity = Vector3.zero
		end
		rider:PivotTo(r.yardPose * CFrame.new(3.5, 2, 0))
		notify(s, "You and the Zefir are back in the yard.", "good")
	else
		notify(s, "Test bike returned to your garage yard.", "good")
	end]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi] = {
        {[==[		text(practice, if best then ("Session best %.2f s"):format(best) else "From your yard or the sprint finish", 300, 360, Ui.DIM, 12)]==], [==[		text(practice, if best then ("Session best %.2f s"):format(best) else "From your yard or the sprint finish", 300, 215, Ui.DIM, 12)
		Ui.button("Back to Yard", function()
			action:FireServer("ReturnTestBike", "test", true)
		end, { Position = UDim2.fromOffset(530, 3), Size = UDim2.fromOffset(110, 26), Parent = practice })]==]},
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
