-- Apply to the v9 game in Studio Edit mode. The Senda demo requires installed meshes and registration.
local server = game.ServerScriptService.TwoStrokeServer.GarageService
local client = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.Interaction
local changes = {
    {module=server, edits={
        {[==[	testBike: any,]==], [==[	testBike: any,
	sendaTestBike: any,]==]},
        {[==[{ project: any, test: any }]==], [==[{ project: any, test: any, sendaTest: any? }]==]},
        {[==[(which ~= "project" and which ~= "test")]==], [==[(which ~= "project" and which ~= "test" and which ~= "sendaTest")]==]},
        {[==[local function spawnTestBike(s: Session)
	local asm = Assembly.new("sm50")
	for _, slot in Catalog.vehicles.sm50.slots do
		local id = TEST_BUILD[slot.id]]==], [==[local function spawnTestBike(s: Session, vehicleId: string?)
	local idForBike = vehicleId or "sm50"
	local isSenda = idForBike == "senda"
	local vehicle = Catalog.vehicles[idForBike]
	local build = TEST_BUILD
	if isSenda then
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local vehicles = assets and assets:FindFirstChild("Vehicles")
		local senda = vehicles and vehicles:FindFirstChild("senda")
		local frame = senda and senda:FindFirstChild("Frame")
		local meshes = assets and assets:FindFirstChild("Parts")
		if not vehicle or not frame or not frame:IsA("MeshPart")
			or frame.MeshContent.SourceType ~= Enum.ContentSourceType.Uri or not meshes then
			return
		end
		build = {}
		local bySlot = {}
		for _, def in Catalog.parts do
			if def.id:sub(1, 3) == "sd_" and table.find(def.fits, "senda") then
				if bySlot[def.slotType] then return end
				bySlot[def.slotType] = def.id
			end
		end
		for _, slot in vehicle.slots do
			local partId = bySlot[slot.accepts]
			local mesh = partId and meshes:FindFirstChild("Part_" .. partId)
			if not mesh or not mesh:IsA("MeshPart") or mesh.MeshContent.SourceType ~= Enum.ContentSourceType.Uri then
				return
			end
			build[slot.id] = partId
		end
	end
	local asm = Assembly.new(idForBike)
	for _, slot in vehicle.slots do
		local id = build[slot.id]]==]},
        {[==[local model = BikeBuilder.create("sm50", s.player.Name .. "_TestBike")]==], [==[local suffix = if isSenda then "_SendaTestBike" else "_TestBike"
	local model = BikeBuilder.create(idForBike, s.player.Name .. suffix)]==]},
        {[==[CFrame.new(-2.2 * SPM, BikeBuilder.RIDE_HEIGHT, 6.2 * SPM)]==], [==[CFrame.new((if isSenda then -3.6 else -2.2) * SPM, BikeBuilder.RIDE_HEIGHT, 6.2 * SPM)]==]},
        {[==[mount.ObjectText = "Test bike (fully built)"]==], [==[mount.ObjectText = if isSenda then "Senda SM 50 (test bike)" else "Test bike (fully built)"]==]},
        {[==[	s.testBike = r
	rides[s] = rides[s] or { project = nil, test = nil }
	rides[s].test = r]==], [==[	rides[s] = rides[s] or { project = nil, test = nil }
	if isSenda then
		s.sendaTestBike = r
		rides[s].sendaTest = r
	else
		s.testBike = r
		rides[s].test = r
	end]==]},
        {[==[testBike = nil, engineTemp]==], [==[testBike = nil, sendaTestBike = nil, engineTemp]==]},
        {[==[	spawnTestBike(s)
]==], [==[	spawnTestBike(s)
	spawnTestBike(s, "senda")
]==]},
        {[==[		s.testBike.model:Destroy()
	end]==], [==[		s.testBike.model:Destroy()
	end
	if s.sendaTestBike then
		s.sendaTestBike.model:Destroy()
	end]==]},
    }},
    {module=client, edits={
        {[==[		elseif inst.Name == player.Name .. "_TestBike" then]==], [==[		elseif inst.Name == player.Name .. "_SendaTestBike" then
			return "sendaTest"
		elseif inst.Name == player.Name .. "_TestBike" then]==]},
        {[==[(if bike == "test" then "[G] ride test bike" else "[G] ride")]==], [==[(if bike == "sendaTest" then "[G] ride Senda test bike" elseif bike == "test" then "[G] ride test bike" else "[G] ride")]==]},
    }},
}
local function revise(source, change)
    for _, edit in change.edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected " .. change.module.Name .. " source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end
for _, change in changes do revise(change.module.Source, change) end
local editor = game:GetService("ScriptEditorService")
for _, change in changes do
    editor:UpdateSourceAsync(change.module, function(source) return revise(source, change) end)
end
