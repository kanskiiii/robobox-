-- Run in Studio Edit mode to install the road sprint.
local server = game.ServerScriptService.TwoStrokeServer
local editor = game:GetService("ScriptEditorService")
local before = [==[function GarageService.start()
]==]
local after = [==[function GarageService.start()
	local road = Workspace:WaitForChild("Map"):FindFirstChild("Road")
	if road and road:IsA("BasePart") then
		require(script.Parent.RoadSprint).start(road, function(player: Player): Model?
			local s = sessions[player]
			local ride = s and s.riding
			return if s and s.driving and ride then ride.model else nil
		end)
	end
]==]
local source = editor:GetEditorSource(server.GarageService)
assert(source:find(after, 1, true) or source:find(before, 1, true), "Unexpected GarageService source")
local sprint = server:FindFirstChild("RoadSprint")
assert(not sprint or sprint:IsA("ModuleScript"), "RoadSprint is reserved for the course module")
if not sprint then
    sprint = Instance.new("ModuleScript")
    sprint.Name = "RoadSprint"
    sprint.Parent = server
end
editor:UpdateSourceAsync(sprint, function()
    return [==[--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("TwoStroke").Net.Remotes)
local notify = Remotes.get("Notify")
local Sprint = {}

local lanes = {38, 105, 176, 250}
local halfWidth = 5.25
local laneCenter = 6

type Run = {
	bike: Model,
	last: Vector3,
	started: number?,
	nextGate: number,
}

local function makeGate(parent: Folder, road: BasePart, offset: number, label: string, color: Color3)
	local surface = road.CFrame * CFrame.new(offset, road.Size.Y / 2, laneCenter)
	local stripe = Instance.new("Part")
	stripe.Name = label
	stripe.Size = Vector3.new(.3, .05, halfWidth * 2)
	stripe.CFrame = surface * CFrame.new(0, .04, 0)
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.CanTouch = false
	stripe.CanQuery = false
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.Color = color
	stripe.Parent = parent

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(148, 32)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	sign.MaxDistance = 120
	sign.Parent = stripe
	local title = Instance.new("TextLabel")
	title.BackgroundColor3 = Color3.fromRGB(20, 24, 29)
	title.BackgroundTransparency = .12
	title.TextColor3 = color
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.Size = UDim2.fromScale(1, 1)
	title.Text = label
	title.Parent = sign
end

function Sprint.start(road: BasePart, getBike: (Player) -> Model?)
	local course = Instance.new("Folder")
	course.Name = "RoadSprint"
	course.Parent = road.Parent
	for index, offset in lanes do
		local label = if index == 1 then "SPRINT START  →" elseif index == #lanes then "SPRINT FINISH" else "CHECKPOINT " .. (index - 1)
		local color = if index == 1 or index == #lanes then Color3.fromRGB(116, 236, 176) else Color3.fromRGB(255, 208, 109)
		makeGate(course, road, offset, label, color)
	end

	local runs: { [Player]: Run } = {}
	local bests: { [Player]: number } = {}
	local function cancel(player: Player, run: Run)
		if run.started then
			notify:FireClient(player, "Sprint cancelled. Ride east through the start to retry.", "warn")
		end
		run.started = nil
		run.nextGate = 1
	end

	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
		bests[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < .08 then return end
		local sampleTime = elapsed
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		for _, player in Players:GetPlayers() do
			local bike = getBike(player)
			local root = bike and bike.PrimaryPart
			local run = runs[player]
			if not bike or not root then
				if run then cancel(player, run) end
				runs[player] = nil
				continue
			end
			local position = road.CFrame:PointToObjectSpace(root.Position)
			if not run or run.bike ~= bike then
				if run then cancel(player, run) end
				runs[player] = {bike = bike, last = position, nextGate = 1}
				continue
			end
			local previous = run.last
			run.last = position
			if (position - previous).Magnitude > 12 + 200 * sampleTime
				or math.abs(position.Z - laneCenter) > halfWidth + .5
				or math.abs(position.Y) > 7
				or (run.started and now - run.started > 90) then
				cancel(player, run)
				continue
			end
			local gate = lanes[run.nextGate]
			if previous.X >= gate or position.X < gate then continue end
			local fraction = (gate - previous.X) / (position.X - previous.X)
			local crossing = previous:Lerp(position, fraction)
			if math.abs(crossing.Z - laneCenter) > halfWidth or math.abs(crossing.Y) > 7 then
				cancel(player, run)
				continue
			end
			local crossedAt = now - sampleTime * (1 - fraction)
			if not run.started then
				run.started = crossedAt
				run.nextGate = 2
				notify:FireClient(player, "Sprint started. Follow the marked lane.", "info")
			elseif run.nextGate == #lanes then
				local time = crossedAt - run.started
				local best = bests[player]
				if not best or time < best then
					bests[player] = time
					notify:FireClient(player, ("Sprint %.2f s · New session best"):format(time), "good")
				else
					notify:FireClient(player, ("Sprint %.2f s · Best %.2f s"):format(time, best), "good")
				end
				run.started = nil
				run.nextGate = 1
			else
				notify:FireClient(player, ("Checkpoint %d/2 · %.2f s"):format(run.nextGate - 1, crossedAt - run.started), "info")
				run.nextGate += 1
			end
		end
	end)
end

return Sprint
]==]
end)
editor:UpdateSourceAsync(server.GarageService, function(current)
    if current:find(after, 1, true) then return current end
    local start, finish = current:find(before, 1, true)
    assert(start and not current:find(before, finish + 1, true), "Unexpected GarageService source")
    return current:sub(1, start - 1) .. after .. current:sub(finish + 1)
end)
