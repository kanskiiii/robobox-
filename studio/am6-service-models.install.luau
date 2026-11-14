-- AM6 parts and service markers. Run in Roblox Studio Edit mode.
local assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets")
local parts = assets:WaitForChild("Parts")
local frame = assets.Vehicles.sm50.Frame
local scale = 1 / .28
local V = Vector3.new
local rgb = Color3.fromRGB
local metal, rubber = Enum.Material.Metal, Enum.Material.Rubber
local cast, zinc, dark = rgb(105, 112, 117), rgb(178, 186, 192), rgb(36, 40, 47)
local copper = rgb(148, 76, 43)
local prepared = {}

local function root(name, size, center)
	local body = Instance.new("Part")
	body.Name = name
	body.Size = size * scale
	body.CFrame = CFrame.new(center * scale)
	body.PivotOffset = CFrame.new(-center * scale)
	body.Transparency = 1
	body.CastShadow = false
	body.CanCollide = false
	body.CanQuery = true
	body.CanTouch = false
	body.Massless = true
	body:SetAttribute("AM6ServiceModel", true)
	table.insert(prepared, body)
	return body
end

local function piece(body, name, cf, size, color, material, shape)
	local solid = Instance.new("Part")
	solid.Name = name
	solid.Size = size * scale
	solid.CFrame = body:GetPivot() * (CFrame.new(cf.Position * scale) * cf.Rotation)
	solid.Color = color
	solid.Material = material
	solid.Shape = shape or Enum.PartType.Block
	solid.TopSurface = Enum.SurfaceType.Smooth
	solid.BottomSurface = Enum.SurfaceType.Smooth
	solid.CanCollide = false
	solid.CanTouch = false
	solid.CanQuery = false
	solid.Massless = true
	solid.Parent = body
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1 = body, solid
	weld.C0 = body.CFrame:ToObjectSpace(solid.CFrame)
	weld.Parent = solid
end

local function tube(body, name, start, finish, diameter, color, material)
	local mid = (start + finish) / 2
	local rotation = CFrame.lookAt(mid, finish) * CFrame.Angles(0, math.pi / 2, 0)
	piece(body, name, rotation, V((finish - start).Magnitude, diameter, diameter),
		color, material or metal, Enum.PartType.Cylinder)
end

local function disc(body, name, x1, x2, y, z, diameter, color, material)
	tube(body, name, V(x1, y, z), V(x2, y, z), diameter, color, material)
end

local function attachment(parent, name, localFrame, tool, mm)
	local mark = parent:FindFirstChild(name)
	if not mark then
		mark = Instance.new("Attachment")
		mark.Name = name
		mark.Parent = parent
	end
	mark.CFrame = parent.CFrame:ToObjectSpace(parent:GetPivot() * localFrame)
	if tool then
		mark:SetAttribute("FastenerAxis", true)
		mark:SetAttribute("RequiredTool", tool)
		mark:SetAttribute("HeadSizeMM", mm)
	end
	return mark
end

local function bolt(body, index, position, side, tool, mm)
	local out = V(side, 0, 0)
	attachment(body, "Bolt_" .. index, CFrame.fromMatrix(position * scale, V(0, 0, side), out), tool, mm)
end

local pump = root("Part_waterpump_am6", V(.061, .080, .105), V(.028, .002, -.002))
disc(pump, "Cast impeller housing", .000, .032, 0, 0, .065, cast)
disc(pump, "Paper gasket seam", .021, .025, 0, 0, .063, dark, rubber)
disc(pump, "Beveled die-cast cover lip", .025, .034, 0, 0, .061, zinc)
disc(pump, "Impeller cover face", .034, .038, 0, 0, .055, cast)
disc(pump, "Raised center of impeller cover", .038, .043, 0, 0, .036, cast)
for i, angle in ipairs({math.rad(90), math.rad(210), math.rad(330)}) do
	local y, z = math.sin(angle) * .031, math.cos(angle) * .031
	disc(pump, "Cover fastener boss", .010, .039, y, z, .017, cast)
	bolt(pump, i, V(.043, y, z), 1, "socket", 8)
end
local function spigot(label, start, joint, mouth)
	tube(pump, label .. " cast elbow", start, joint, .024, cast)
	tube(pump, label .. " neck", joint, mouth, .018, zinc)
	local toward = (mouth - joint).Unit
	tube(pump, label .. " hose retaining bead", mouth - toward * .005, mouth - toward * .002, .021, cast)
	tube(pump, label .. " dark bore", mouth - toward * .001, mouth + toward * .001, .012, dark)
	attachment(pump, label, CFrame.lookAt(mouth * scale, (mouth + toward) * scale))
end
spigot("CoolantInlet", V(.018, -.007, -.020), V(.025, -.004, -.040), V(.029, -.004, -.055))
spigot("CoolantOutlet", V(.012, .016, .015), V(.021, .029, .029), V(.029, .042, .036))

local ignition = root("Part_ignition_am6", V(.062, .126, .135), V(-.024, 0, .005))
disc(ignition, "Stator backplate", -.008, .001, 0, 0, .119, cast)
disc(ignition, "Inner rotor flange", -.021, -.007, 0, 0, .084, dark)
for i = 0, 7 do
	local angle = i * math.pi / 4
	local pos = V(-.012, math.cos(angle) * .048, math.sin(angle) * .048)
	local cf = CFrame.new(pos) * CFrame.Angles(angle, 0, 0)
	piece(ignition, "Stator coil pole shoe", cf, V(.013, .018, .023), dark, metal)
	for offset = -2, 2 do
		local strip = cf * CFrame.new(0, offset * .0025, 0)
		piece(ignition, "Copper winding", strip, V(.017, .0018, .0235), copper, metal)
	end
end
disc(ignition, "Flywheel steel rim", -.028, -.014, 0, 0, .095, zinc)
disc(ignition, "Flywheel inertia ring", -.034, -.027, 0, 0, .087, cast)
disc(ignition, "Rotor face", -.037, -.033, 0, 0, .079, zinc)
disc(ignition, "Crank hub", -.044, -.035, 0, 0, .031, cast)
bolt(ignition, 1, V(-.046, 0, 0), -1, "socket", 17)
for i, z in ipairs({-.046, .046}) do
	local y = -.028
	disc(ignition, "Stator screw landing", -.015, -.006, y, z, .016, zinc)
	bolt(ignition, i + 1, V(-.018, y, z), -1, "phillips")
end
piece(ignition, "Pickup sensor", CFrame.new(-.009, .024, .056), V(.018, .020, .021), dark, rubber)
local loom = {V(-.008, .03, .057), V(-.009, .044, .070), V(-.006, .057, .082), V(.008, .068, .096)}
for n = 1, #loom - 1 do tube(ignition, "Pickup wire loom", loom[n], loom[n+1], .0075, dark, rubber) end
attachment(ignition, "WiringExit", CFrame.new(loom[#loom] * scale))

-- Separate cover lets the game expose the rotor and screws when it implements cover removal.
local cover = root("AM6_IgnitionCover", V(.022, .135, .135), V(-.052, 0, 0))
disc(cover, "Cast cover flange", -.046, -.042, 0, 0, .133, cast)
disc(cover, "Dark ignition cover shell", -.061, -.046, 0, 0, .120, dark)
disc(cover, "Beveled center cap", -.065, -.060, 0, 0, .102, cast)
for _, p in ipairs({V(0,.047,.038), V(0,-.050,.034), V(0,-.015,-.060)}) do
	disc(cover, "Cover mounting ear", -.049, -.041, p.Y, p.Z, .018, cast)
end

local engine = assert(frame:FindFirstChild("Mount_EngineBlock"))
local enginePose = frame:GetPivot():ToObjectSpace(engine.WorldCFrame)
attachment(frame, "Mount_WaterPump", enginePose * CFrame.new(V(.087, -.043, -.097) * scale))
attachment(frame, "Mount_IgnitionStator", enginePose * CFrame.new(-.086 * scale, 0, 0))

-- Correct the clutch stack's outward offset while keeping it concentric with the AM6 basket.
local clutchMount = frame:FindFirstChild("Mount_Clutch")
local clutchCf = frame:GetPivot():ToObjectSpace(clutchMount.WorldCFrame)
attachment(frame, "Mount_Clutch", CFrame.new(.101 * scale, clutchCf.Y, clutchCf.Z) * clutchCf.Rotation)
for _, name in ipairs({"Part_clutch_std", "Part_clutch_race"}) do
	local clutch = assert(parts:FindFirstChild(name))
	for i = 1, 5 do
		local mark = assert(clutch:FindFirstChild("Bolt_" .. i))
		local point = clutch:GetPivot():PointToObjectSpace(mark.WorldPosition) / scale
		bolt(clutch, i, V(.037, point.Y, point.Z), 1, "socket", 8)
	end
end

-- The stock sprocket datum already equals the gearbox output and rear chain plane.
-- Move the service nut outward on the shaft without shifting the chain.
for _, count in ipairs({11, 12, 13, 14}) do
	bolt(assert(parts:FindFirstChild("Part_sprocket_f_" .. count)), 1, V(-.010, 0, 0), -1, "socket", 17)
end

for _, item in ipairs(prepared) do
	local previous = parts:FindFirstChild(item.Name)
	if previous then
		assert(previous:GetAttribute("AM6ServiceModel"), "Found an unrelated asset named " .. item.Name)
	end
end
for _, item in ipairs(prepared) do
	local previous = parts:FindFirstChild(item.Name)
	if previous then previous:Destroy() end
	item.Parent = parts
end
return "Installed AM6 water pump, ignition, service cover and fastener markers"
