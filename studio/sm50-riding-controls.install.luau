-- Run in Studio Edit mode after the SM50 front-end installer.
local client = game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local bar = game:GetService("ReplicatedStorage").Assets.Parts.Part_handlebar_std
assert(bar:GetAttribute("SM50FrontEndVersion") == 1, "Install the SM50 front end first")

local edits = {}
local function replace(name, old, new)
	local scriptObject = client[name]
	local source = edits[scriptObject] or scriptObject.Source
	local start, stop = string.find(source, old, 1, true)
	if not start then
		assert(string.find(source, new, 1, true), "Unexpected " .. name .. " source at " .. old)
		return
	end
	assert(not string.find(source, old, stop + 1, true), name .. " has an ambiguous match")
	edits[scriptObject] = source:sub(1, start - 1) .. new .. source:sub(stop + 1)
end

replace("BikeController", "down(Enum.KeyCode.LeftControl) or down(Enum.KeyCode.RightControl) then 1 else 0, padClutch",
	"down(Enum.KeyCode.LeftShift) or down(Enum.KeyCode.RightShift) then 1 else 0, padClutch")
replace("BikeController", "down(Enum.KeyCode.LeftShift) or down(Enum.KeyCode.RightShift) then 1 else 0, padWheelie",
	"down(Enum.KeyCode.LeftControl) or down(Enum.KeyCode.RightControl) then 1 else 0, padWheelie")
for _, words in ipairs({
	{"Shift = lean back", "Ctrl = lean back"},
	{"off Shift", "off Ctrl"},
	{"Shift held:", "Ctrl held:"},
	{"Shift released:", "Ctrl released:"},
	{"pull the clutch (Ctrl)", "pull the clutch (Shift)"},
}) do replace("BikeController", words[1], words[2]) end
replace("Hud", "Ctrl clutch  Shift wheelie", "Shift clutch  Ctrl wheelie")
replace("Tutorial", "Ctrl is the clutch", "Shift is the clutch")
replace("Main", "Pull the clutch (Ctrl)", "Pull the clutch (Shift)")
replace("Main", "Hold Shift to wheelie", "Hold Ctrl to wheelie")
replace("BikeController", "clutch = 0, throttle = 0, fault", "clutch = 0, throttle = 0, frontBrake = 0, wheelie = 0, fault")
local publishInputs = "hud.clutch = input.clutch\n\thud.frontBrake = frontBrake\n\thud.wheelie = riderBack"
if not string.find(client.BikeController.Source, publishInputs, 1, true) then
	replace("BikeController", "hud.clutch = input.clutch", publishInputs)
end

local cockpit = [==[
-- LocalScript in StarterPlayerScripts.TwoStrokeClient.
local RunService = game:GetService("RunService")
local Controller = require(script.Parent.BikeController)
local mountedBar
local controls = {}

local function clear()
	for _, control in ipairs(controls) do
		for weld, rest in pairs(control.rest) do
			if weld.Parent then weld.C0 = rest end
		end
	end
	table.clear(controls)
	mountedBar = nil
end

local function bind(bar)
	mountedBar = bar
	for _, data in ipairs({{"Clutch", "clutch"}, {"Brake", "frontBrake"}}) do
		local pivot = bar:FindFirstChild("Lever_" .. data[1] .. "_Pivot")
		if not pivot or not pivot:IsA("Attachment") then continue end
		local rest = {}
		local axis = bar.PivotOffset.UpVector
		local side = math.sign(bar.PivotOffset:PointToObjectSpace(pivot.Position).X)
		for _, piece in ipairs(bar:GetChildren()) do
			if piece:GetAttribute("SM50Lever") == data[1] then
				local weld = piece:FindFirstChild("DetailWeld")
				if weld and weld:IsA("Weld") then rest[weld] = weld.C0 end
			end
		end
		table.insert(controls, {
			pivot = pivot.Position, axis = axis, side = side, input = data[2], rest = rest, amount = 0,
		})
	end
end

local render = RunService.PreSimulation:Connect(function(dt)
	local chassis = Controller.getRoot()
	local slot = chassis and chassis.Parent:FindFirstChild("Slot_Handlebar")
	local visual = Controller.active and slot and slot:FindFirstChild("Visual")
	if visual ~= mountedBar then
		clear()
		if visual and visual:IsA("BasePart") then bind(visual) end
	end
	for _, control in ipairs(controls) do
		local amount = Controller.hud[control.input] or 0
		control.amount += (amount - control.amount) * (1 - math.exp(-dt * 20))
		local angle = math.rad(-14) * control.side * control.amount
		local rotation = CFrame.new(control.pivot) * CFrame.fromAxisAngle(control.axis, angle)
			* CFrame.new(-control.pivot)
		for weld, rest in pairs(control.rest) do weld.C0 = rotation * rest end
	end
end)
script.Destroying:Connect(function()
	render:Disconnect()
	clear()
end)
]==]

local scriptObject = client:FindFirstChild("CockpitControls") or Instance.new("LocalScript")
assert(scriptObject:IsA("LocalScript"))
for object, source in pairs(edits) do object.Source = source end
for _, p in ipairs(bar:GetChildren()) do
	if p:IsA("BasePart") then
		local name = p.Name:match("^(%a+) lever$")
		if p.Name == "Rounded lever end" then
			name = if bar:GetPivot():PointToObjectSpace(p.Position).X < 0 then "Clutch" else "Brake"
		end
		if name == "Clutch" or name == "Brake" then p:SetAttribute("SM50Lever", name) end
	end
end
scriptObject.Name = "CockpitControls"
scriptObject.Source = cockpit
scriptObject.Parent = client
return "Restored Shift clutch and Ctrl wheelie, animated the SM50 brake and clutch levers"
