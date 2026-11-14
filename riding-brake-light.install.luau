-- Run in Studio Edit mode after riding-headlight.install.luau.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ServerScriptService.TwoStrokeServer.GarageService] = {
        {[==[local function stopDriving(s: Session)]==], [==[function actions.BrakeLight(s, braking)
	local ride = s.riding
	if not s.driving or not ride or typeof(braking) ~= "boolean" then return end
	local slot = ride.model:FindFirstChild(if ride.asm.vehicle == "senda" then "Slot_TailPlate" else "Slot_Seat")
	local visual = slot and slot:FindFirstChild("Visual")
	if not visual or not visual:IsA("BasePart") then return end
	local existing = visual:FindFirstChild("RidingBrakeLight")
	if existing then
		local light = existing:FindFirstChildOfClass("PointLight")
		local marker = existing:FindFirstChildOfClass("BillboardGui")
		if light then light.Enabled = braking end
		if marker then marker.Enabled = braking end
		return
	end
	if not braking then return end

	local lens = Instance.new("Attachment")
	lens.Name = "RidingBrakeLight"
	lens.CFrame = visual.PivotOffset
		* (if ride.asm.vehicle == "senda" then CFrame.new(0, 0, .10) else CFrame.new(0, -.08, 2.02))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 24, 14)
	light.Brightness = 2
	light.Range = 8
	light.Parent = lens
	local marker = Instance.new("BillboardGui")
	marker.Size = UDim2.fromScale(.31, .09)
	marker.MaxDistance = 110
	marker.LightInfluence = 0
	marker.Parent = lens
	local red = Instance.new("Frame")
	red.BackgroundColor3 = Color3.fromRGB(255, 56, 36)
	red.BorderSizePixel = 0
	red.Size = UDim2.fromScale(1, 1)
	red.Parent = marker
	lens.Parent = visual
end

local function stopDriving(s: Session)]==]},
        {[==[	if lamp then lamp:Destroy() end]==], [==[	if lamp then lamp:Destroy() end
	local brake = r.model:FindFirstChild("RidingBrakeLight", true)
	if brake then brake:Destroy() end]==]},
        {[==[	s.lastTelemetry = now
	local function n]==], [==[	s.lastTelemetry = now
	if typeof(t.braking) == "boolean" then actions.BrakeLight(s, t.braking) end
	local function n]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.BikeController] = {
        {[==[local frontBrake = 0]==], [==[local frontBrake = 0
local brakeLight = false]==]},
        {[==[	telemetryClock += dt]==], [==[	local braking = frontBrake > .08 or input.rearBrake > .08
	if braking ~= brakeLight then
		brakeLight = braking
		Remotes.get("Action"):FireServer("BrakeLight", braking)
	end
	telemetryClock += dt]==]},
        {[==[tempC = es.tempC, running = es.running,]==], [==[tempC = es.tempC, running = es.running, braking = braking,]==]},
        {[==[	front, rear = nil, nil]==], [==[	front, rear = nil, nil
	brakeLight = false]==]},
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
