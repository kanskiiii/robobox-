-- Run in Studio Edit mode after sprint-practice.install.luau.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ServerScriptService.TwoStrokeServer.RoadSprint] = {
        {[==[type Run = {]==], [==[function Sprint.isNearFinish(road: BasePart, position: Vector3): boolean
	local localPosition = road.CFrame:PointToObjectSpace(position)
	local finish = lanes[#lanes]
	return localPosition.X >= finish - 8 and localPosition.X <= finish + 250
		and math.abs(localPosition.Z) <= road.Size.Z / 2 + 6
		and math.abs(localPosition.Y) <= 8
end

type Run = {]==]},
    },
    [game.ServerScriptService.TwoStrokeServer.GarageService] = {
        {[==[	if not within(s, World.bays[s.bay].Position, 75) then
		notify(s, "Return to your garage yard to start sprint practice.", "warn")
		return
	end
	local map = Workspace:FindFirstChild("Map")
	local road = map and map:FindFirstChild("Road")
	local root = r.model.PrimaryPart
	if not road or not road:IsA("BasePart") or not root or not r.spec.canRide then return end]==], [==[	local map = Workspace:FindFirstChild("Map")
	local road = map and map:FindFirstChild("Road")
	local root = r.model.PrimaryPart
	if not road or not road:IsA("BasePart") or not root or not r.spec.canRide then return end
	local nearYard = within(s, World.bays[s.bay].Position, 75)
	if not nearYard and not RoadSprint.isNearFinish(road, char:GetPivot().Position) then
		notify(s, "Start sprint practice from your garage yard or the sprint finish.", "warn")
		return
	end]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi] = {
        {[==[Parent = practice })
	end]==], [==[Parent = practice })
		text(practice, "From your yard or the sprint finish", 300, 360, Ui.DIM, 12)
	end]==]},
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
