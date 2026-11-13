-- Run in Studio Edit mode to add the garage's test-bike return action.
local editor = game:GetService("ScriptEditorService")
local changes = {
    [game.ServerScriptService.TwoStrokeServer.GarageService] = {
        {[==[type Ride = { model: Model, asm: Assembly.State, test: boolean, spec: VehicleSpec.Spec }]==], [==[type Ride = { model: Model, asm: Assembly.State, test: boolean, spec: VehicleSpec.Spec, yardPose: CFrame? }]==]},
        {[==[local function setCharacterMassless(char: Model, massless: boolean)]==], [==[function actions.ReturnTestBike(s, which)
	if which ~= "test" and which ~= "sendaTest" then return end
	local set = rides[s]
	local r: Ride? = set and set[which]
	if not r or not r.yardPose then return end
	local seat = r.model:FindFirstChild("RiderSeat")
	if s.driving or (seat and seat:IsA("Seat") and seat.Occupant) then
		notify(s, "Get off your bike before returning a test bike.", "warn")
		return
	end
	local root = r.model.PrimaryPart
	if not root then return end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	r.model:PivotTo(r.yardPose)
	notify(s, "Test bike returned to your garage yard.", "good")
end

local function setCharacterMassless(char: Model, massless: boolean)]==]},
        {[==[		if sessions[s.player] == s and s.riding ~= r then]==], [==[		local root = r.model.PrimaryPart
		if sessions[s.player] == s and s.riding ~= r and root and not root.Anchored then]==]},
        {[==[local r: Ride = { model = model, asm = asm, test = true, spec = BikeBuilder.sync(model, asm, false) }]==], [==[local r: Ride = { model = model, asm = asm, test = true, spec = BikeBuilder.sync(model, asm, false), yardPose = model:GetPivot() }]==]},
        {[==[		money = s.data.money, tools = s.data.tools, parts = s.data.parts, bike = s.data.bike,]==], [==[		money = s.data.money, tools = s.data.tools, parts = s.data.parts, bike = s.data.bike,
		hasSendaTestBike = s.sendaTestBike ~= nil,]==]},
    },
    [game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi] = {
        {[==[	local problems = {}]==], [==[	local yard = row(32)
	text(yard, "Yard test bikes", 10, 145, Ui.DIM)
	Ui.button("Return Zefir", function()
		action:FireServer("ReturnTestBike", "test")
	end, { Position = UDim2.fromOffset(155, 3), Size = UDim2.fromOffset(130, 26), Parent = yard })
	if state.hasSendaTestBike then
		Ui.button("Return Senda", function()
			action:FireServer("ReturnTestBike", "sendaTest")
		end, { Position = UDim2.fromOffset(295, 3), Size = UDim2.fromOffset(130, 26), Parent = yard })
	end
	local problems = {}]==]},
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
