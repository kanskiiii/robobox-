-- Run in Studio Edit mode after installing road-sprint.install.luau.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ReplicatedStorage.TwoStroke.Net.Remotes] = {
        {[==["Action", "Telemetry"]==], [==["Action", "Telemetry", "Sprint"]==]},
    },
    [game.ServerScriptService.TwoStrokeServer.RoadSprint] = {
        {[==[local notify = Remotes.get("Notify")]==], [==[local notify = Remotes.get("Notify")
local sprintState = Remotes.get("Sprint")]==]},
        {[==[		if run.started then
			notify]==], [==[		if run.started then
			sprintState:FireClient(player, "cancel")
			notify]==]},
        {[==[				notify:FireClient(player, "Sprint started. Follow the marked lane.", "info")]==], [==[				sprintState:FireClient(player, "running", crossedAt, run.nextGate)]==]},
        {[==[				run.started = nil
				run.nextGate = 1]==], [==[				sprintState:FireClient(player, "finished", time, bests[player])
				run.started = nil
				run.nextGate = 1]==]},
        {[==[				notify:FireClient(player, ("Checkpoint %d/2 · %.2f s"):format(run.nextGate - 1, crossedAt - run.started), "info")
				run.nextGate += 1]==], [==[				run.nextGate += 1
				sprintState:FireClient(player, "running", run.started, run.nextGate)]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.Hud] = {
        {[==[local RunService = game:GetService("RunService")]==], [==[local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("TwoStroke").Net.Remotes)]==]},
        {[==[	-- wheelie meter:]==], [==[	local sprint = Ui.label("", 16, Ui.TEXT, {
		Name = "SprintTimer", AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 70),
		Size = UDim2.fromOffset(296, 30), TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = Ui.BG, BackgroundTransparency = .12, Visible = false, Parent = gui,
	})
	Ui.corner(6).Parent = sprint
	local startTime: number? = nil
	local nextGate = 2
	local showUntil = 0
	Remotes.get("Sprint").OnClientEvent:Connect(function(phase: string, value: number?, extra: number?)
		if phase == "running" and value and extra then
			startTime, nextGate = value, extra
			sprint.TextColor3 = Ui.TEXT
		elseif phase == "finished" and value and extra then
			startTime = nil
			showUntil = workspace:GetServerTimeNow() + 7
			sprint.Text = ("Sprint %.2f s   ·   Best %.2f s"):format(value, extra)
			sprint.TextColor3 = Ui.GOOD
		else
			startTime = nil
			showUntil = 0
		end
	end)

	-- wheelie meter:]==]},
        {[==[		local h = Controller.hud]==], [==[		local now = workspace:GetServerTimeNow()
		sprint.Visible = startTime ~= nil or now < showUntil
		if startTime then
			local goal = if nextGate <= 3 then ("Checkpoint %d/2"):format(nextGate - 1) else "Finish"
			sprint.Text = ("%.1f s   ·   %s"):format(math.max(0, now - startTime), goal)
		end
		local h = Controller.hud]==]},
    },
}
for target, edits in changes do
    editor:UpdateSourceAsync(target, function(source)
        for _, edit in edits do
            if source:find(edit[2], 1, true) then continue end
            local first, last = source:find(edit[1], 1, true)
            assert(first and not source:find(edit[1], last + 1, true), "Unexpected source in " .. target:GetFullName())
            source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
        end
        return source
    end)
end
