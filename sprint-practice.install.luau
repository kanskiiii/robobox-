-- Run in Studio Edit mode after the road sprint and yard-bike return installers.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ServerScriptService.TwoStrokeServer.RoadSprint] = {
        {[==[type Run = {]==], [==[function Sprint.stagingPose(road: BasePart, rideHeight: number): CFrame
	local position = road.CFrame:PointToWorldSpace(Vector3.new(lanes[1] - 14, road.Size.Y / 2 + rideHeight, laneCenter))
	return CFrame.lookAt(position, position + road.CFrame.RightVector)
end

type Run = {]==]},
    },
    [game.ServerScriptService.TwoStrokeServer.GarageService] = {
        {[==[function actions.ReturnTestBike(s, which)]==], [==[local RoadSprint = require(script.Parent.RoadSprint)

function actions.StartSprintPractice(s)
	local set = rides[s]
	local r: Ride? = set and set.test
	local char, hum = character(s)
	if not r or not char or not hum or hum.Health <= 0 then return end
	if s.driving or hum.SeatPart then
		notify(s, "Get off your bike before starting sprint practice.", "warn")
		return
	end
	if not within(s, World.bays[s.bay].Position, 75) then
		notify(s, "Return to your garage yard to start sprint practice.", "warn")
		return
	end
	local map = Workspace:FindFirstChild("Map")
	local road = map and map:FindFirstChild("Road")
	local root = r.model.PrimaryPart
	if not road or not road:IsA("BasePart") or not root or not r.spec.canRide then return end
	local target = RoadSprint.stagingPose(road, BikeBuilder.RIDE_HEIGHT)
	for _, other in sessions do
		if other ~= s then
			local rider = other.player.Character
			local otherRoot = rider and rider.PrimaryPart
			if otherRoot and (otherRoot.Position - target.Position).Magnitude < 10 then
				notify(s, "The sprint staging lane is busy. Try again in a moment.", "warn")
				return
			end
		end
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	r.model:PivotTo(target)
	startRide(s, r)
end

function actions.ReturnTestBike(s, which)]==]},
        {[==[require(script.Parent.RoadSprint).start(road, function(player: Player): Model?]==], [==[RoadSprint.start(road, function(player: Player): Model?]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi] = {
        {[==[	local problems = {}]==], [==[	if not state.driving then
		local practice = row(32)
		text(practice, "Road sprint", 10, 145, Ui.DIM)
		Ui.button("Start on Zefir", function()
			gui.Enabled = false
			action:FireServer("StartSprintPractice")
		end, { Position = UDim2.fromOffset(155, 3), Size = UDim2.fromOffset(130, 26), Parent = practice })
	end
	local problems = {}]==]},
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
