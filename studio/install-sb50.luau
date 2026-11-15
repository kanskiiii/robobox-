local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Install SB50 in Edit mode")
local assets = game:GetService("ServerStorage"):WaitForChild("Assets"):WaitForChild("Vehicles")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local contract = require(shared.Vehicle.AssetContract)
local def = require(shared.Config.Vehicles.SB50)
local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local HttpService = game:GetService("HttpService")
local History = game:GetService("ChangeHistoryService")
local scale = 1 / .28
local origin = CFrame.new(0, def.comHeightM * scale, 0)
local candidateName = "_SB50Install"
local function studs(a)
	return Vector3.new(a[1], a[2], a[3]) * scale
end

local function marker(part, name, worldPosition)
	local att = Instance.new("Attachment")
	att.Name = name
	att.Position = part.CFrame:PointToObjectSpace(worldPosition)
	att.Parent = part
end

local function weld(part, parent)
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = parent
	joint.Part1 = part
	joint.Parent = part
end

local function rigidPart(class, name, size, cf, parent, root)
	local part = Instance.new(class)
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Transparency = 1
	part.CanCollide = root == true
	part.CanQuery = root == true
	part.CanTouch = class == "VehicleSeat"
	part.Massless = root ~= true
	part.Anchored = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function kinematic(chassis, part, name)
	local joint = Instance.new("Weld")
	joint.Name = name
	joint.Part0 = chassis
	joint.Part1 = part
	joint.C0 = chassis.CFrame:ToObjectSpace(part.CFrame)
	joint.Parent = chassis
end

local function model(parent, name)
	local instance = Instance.new("Model")
	instance.Name = name
	instance.Parent = parent
	return instance
end

if request.mode == "begin" then
	assert(math.abs(def.wheelbaseM - 1.38) < .001 and def.steering.rakeDeg == 25, "SB50 coordinates changed")
	assert(math.abs(def.wheel.frontRadiusM - .296) < .001 and math.abs(def.wheel.rearRadiusM - .307) < .001,
		"SB50 tire radii changed")
	local draft = assets:FindFirstChild(candidateName)
	if draft then
		assert(draft:GetAttribute("StreetbornAsset") == "SB50", "Unexpected staging object")
		draft:Destroy()
	end
	local bike = model(assets, candidateName)
	bike:SetAttribute("StreetbornAsset", "SB50")
	bike:SetAttribute("MetresPerStud", .28)
	local chassis = rigidPart("Part", "Chassis", Vector3.new(.9, 1.2, 4), origin, bike, true)
	chassis.CustomPhysicalProperties = PhysicalProperties.new(3.2, .4, .1, 1, 1)
	chassis.RootPriority = 10
	bike.PrimaryPart = chassis
	marker(chassis, "CenterOfMass", origin.Position)
	local seat = rigidPart("VehicleSeat", "Seat", studs({.155,.05,.41}), CFrame.new(studs({0,.875,.275})), bike)
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.HeadsUpDisplay = false
	weld(seat, chassis)
	for _, name in {"Front", "Rear"} do
		local front = name == "Front"
		local z = (front and (def.comFromRearM - def.wheelbaseM) or def.comFromRearM) * scale
		local radius = def.wheel[string.lower(name) .. "RadiusM"]
		local susp = def.suspension[string.lower(name)]
		local frontShare = def.comFromRearM / def.wheelbaseM
		local loadShare = front and frontShare or (1 - frontShare)
		local gravity = require(shared.Util.Units).GRAVITY
		local sag = (def.massKg + def.riderMassKg) * gravity * loadShare / susp.stiffnessNpm
		local axle = Vector3.new(0, radius * scale, z)
		marker(chassis, name .. "SuspensionMount", axle + Vector3.yAxis * ((susp.restLengthM - sag) * scale))
		local wheel = rigidPart("Part", name .. "Wheel", Vector3.new(.08,.08,.08), CFrame.new(axle), bike)
		kinematic(chassis, wheel, name .. "WheelWeld")
	end
	local steering = model(bike, "Steering")
	local steeringCF = CFrame.new(studs({0,.876,-.384})) * CFrame.Angles(math.rad(def.steering.rakeDeg), 0, 0)
	local pivot = rigidPart("Part","SteeringPivot",Vector3.new(.1,.1,.1),steeringCF,steering)
	steering.PrimaryPart = pivot
	kinematic(chassis, pivot, "SteeringWeld")
	model(bike, "Body").PrimaryPart = nil
	return "SB50 staging rig built"
end

local bike = assert(assets:FindFirstChild(candidateName), "Run begin first")
assert(bike:GetAttribute("StreetbornAsset") == "SB50", "Unexpected staging object")

local mapProperties = {
	baseColor = "ColorMapContent",
	metalness = "MetalnessMapContent",
	roughness = "RoughnessMapContent",
	normal = "NormalMapContent",
}

if request.mode == "mapChunk" then
	assert(mapProperties[request.map], "Unknown PBR map")
	assert(typeof(request.index) == "number" and request.index >= 1 and request.index % 1 == 0)
	local name = string.format("_PBR_%s_%d", request.map, request.index)
	local record = bike:FindFirstChild(name) or Instance.new("StringValue")
	record.Name = name
	record.Value = request.payload
	record.Parent = bike
	return name
end

if request.mode == "finishAtlas" then
	assert(request.size == 384, "Unexpected SB50 game atlas resolution")
	local maps = {}
	local chunks = {}
	local size = Vector2.new(request.size, request.size)
	for map in mapProperties do
		local pieces = {}
		for i = 1, request.counts[map] do
			local record = assert(bike:FindFirstChild(string.format("_PBR_%s_%d", map, i)), "Missing PBR chunk")
			table.insert(pieces, record.Value)
			table.insert(chunks, record)
		end
		local pixels = EncodingService:DecompressBuffer(
			EncodingService:Base64Decode(buffer.fromstring(table.concat(pieces))), Enum.CompressionAlgorithm.Zstd)
		assert(buffer.len(pixels) == size.X * size.Y * 4, "Invalid PBR image buffer")
		local editable = assert(AssetService:CreateEditableImage({Size = size}), "EditableImage allocation failed")
		editable:WritePixelsBuffer(Vector2.zero, size, pixels)
		local result, content = AssetService:CreateDataModelContentAsync(Content.fromObject(editable))
		editable:Destroy()
		assert(result == Enum.CreateContentResult.Success, map .. ": " .. tostring(result))
		maps[map] = content
	end
	local appearance = Instance.new("SurfaceAppearance")
	appearance.Name = "_PBRTemplate"
	for map, property in mapProperties do
		appearance[property] = maps[map]
		assert(appearance[property].SourceType == Enum.ContentSourceType.Opaque, "PBR map was not embedded")
	end
	local previous = bike:FindFirstChild(appearance.Name)
	if previous then previous:Destroy() end
	appearance.Parent = bike
	for _, record in chunks do record:Destroy() end
	return "Four SB50 PBR maps embedded"
end

local function ownerFor(name)
	if name:match("^Front") and (name:match("Tire$") or name:match("Rim$") or name:match("Hub$")
		or name:match("SpokeSet$") or name == "FrontBrakeDisc") then
		return bike.FrontWheel, bike.FrontWheel
	end
	if name:match("^Rear") and (name:match("Tire$") or name:match("Rim$") or name:match("Hub$")
		or name:match("SpokeSet$") or name == "RearBrakeDisc" or name == "RearSprocket") then
		return bike.RearWheel, bike.RearWheel
	end
	local steeringParts = {
		SteeringAssembly=true, FrontBrakeCaliper=true, FrontFender=true, Headlight=true,
		HeadlightMask=true, Handlebar=true, LeftGrip=true, ThrottleGrip=true, ClutchLever=true,
		FrontBrakeLever=true, FrontBrakeMasterCylinder=true, InstrumentCluster=true,
		Mirror_L=true, Mirror_R=true,
	}
	if steeringParts[name] or name:match("^Fork") then
		return bike.Steering, bike.Steering.PrimaryPart
	end
	return bike.Body, bike.Chassis
end

if request.mode == "batch" then
	local bytes = EncodingService:DecompressBuffer(
		EncodingService:Base64Decode(buffer.fromstring(request.payload)), Enum.CompressionAlgorithm.Zstd)
	local headerSize = buffer.readu32(bytes, 0)
	local spec = HttpService:JSONDecode(buffer.readstring(bytes, 4, headerSize))
	assert(spec.format == 2, "Expected SB50 PBR mesh payload")
	local appearance = assert(bike:FindFirstChild("_PBRTemplate"), "Build the atlas first")
	local cursor = 4 + headerSize
	local triangles = 0
	for _, component in spec.parts do
		local parent, root = ownerFor(component.name)
		local instance = model(nil, component.name == "Seat" and "SeatPad" or component.name)
		local pivot = studs(component.pivot)
		instance:SetAttribute("AssetId", "sb50." .. component.name)
		instance:SetAttribute("ComponentCategory", spec.category)
		for _, layer in component.layers do
			local verts, ids, normals, bank = {}, {}, {}, {}
			local low = Vector3.new(math.huge, math.huge, math.huge)
			local high = -low
			for i = 1, layer.v do
				local vertex = Vector3.new(buffer.readf32(bytes,cursor), buffer.readf32(bytes,cursor+4),
					buffer.readf32(bytes,cursor+8)) * scale
				cursor += 12
				verts[i] = vertex
				low = low:Min(vertex)
				high = high:Max(vertex)
			end
			assert((high - low).Magnitude < 32, "Unexpected mesh extent: " .. component.name)
			for i = 1, layer.v do
				local key = buffer.readu8(bytes,cursor)*65536 + buffer.readu8(bytes,cursor+1)*256
					+ buffer.readu8(bytes,cursor+2)
				bank[key] = Vector3.new(buffer.readi8(bytes,cursor), buffer.readi8(bytes,cursor+1),
					buffer.readi8(bytes,cursor+2)).Unit
				normals[i] = key
				cursor += 3
			end
			local center = (low + high) / 2
			local editable = assert(AssetService:CreateEditableMesh(), "EditableMesh allocation failed")
			local normalIds, uvIds = {}, {}
			for key, normal in bank do
				normalIds[key] = editable:AddNormal(normal)
			end
			for i, vertex in verts do
				ids[i] = editable:AddVertex(vertex - center)
			end
			for i = 1, layer.v do
				local u = buffer.readu16(bytes,cursor) / 65535
				local v = buffer.readu16(bytes,cursor+2) / 65535
				cursor += 4
				uvIds[i] = editable:AddUV(Vector2.new(u, v))
			end
			assert(not layer.hasColors, "Expected one material per layer")
			for _ = 1, layer.f do
				local a = buffer.readu16(bytes,cursor)+1
				local b = buffer.readu16(bytes,cursor+2)+1
				local c = buffer.readu16(bytes,cursor+4)+1
				cursor += 6
				local face = editable:AddTriangle(ids[a], ids[b], ids[c])
				editable:SetFaceNormals(face, {normalIds[normals[a]], normalIds[normals[b]], normalIds[normals[c]]})
				editable:SetFaceUVs(face, {uvIds[a],uvIds[b],uvIds[c]})
			end
			local result, content = AssetService:CreateDataModelContentAsync(Content.fromObject(editable))
			assert(result == Enum.CreateContentResult.Success, component.name .. ": " .. tostring(result))
			local part = AssetService:CreateMeshPartAsync(content, {CollisionFidelity=Enum.CollisionFidelity.Box})
			editable:Destroy()
			assert(part.MeshContent.SourceType == Enum.ContentSourceType.Opaque, "Mesh was not embedded")
			local surface = spec.palette[layer.key]
			part.Name = layer.key
			if surface.transparency == 0 then
				local pbr = appearance:Clone()
				pbr.Name = "SB50Finish"
				pbr.Parent = part
			end
			part.Material = Enum.Material[surface.studioMaterial]
			part.Color = Color3.fromHex(surface.hex)
			part.Transparency = surface.transparency
			part.CastShadow = surface.transparency == 0
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.CFrame = CFrame.new(pivot + center)
			part.PivotOffset = CFrame.new(-center)
			part:SetAttribute("TriangleCount", layer.f)
			part.Parent = instance
			if not instance.PrimaryPart then instance.PrimaryPart = part end
			weld(part, root)
			triangles += layer.f
		end
		for name, point in component.attachments do
			marker(instance.PrimaryPart, name, pivot + studs(point))
		end
		local previous = parent:FindFirstChild(instance.Name)
		if previous then previous:Destroy() end
		instance.Parent = parent
	end
	assert(cursor == buffer.len(bytes), "Payload length mismatch")
	return string.format("%s: %d components, %d triangles", spec.category, #spec.parts, triangles)
end

assert(request.mode == "finish", "Unknown install mode")
local meshCount, triangles, components = 0, 0, 0
for _, instance in bike:GetDescendants() do
	if instance:IsA("MeshPart") then
		assert(instance.MeshContent.SourceType == Enum.ContentSourceType.Opaque, "Missing embedded mesh")
		local finish = instance:FindFirstChild("SB50Finish")
		if instance.Transparency == 0 then
			assert(finish and finish:IsA("SurfaceAppearance"), "Missing surface finish: " .. instance:GetFullName())
			for _, property in mapProperties do
				assert(finish[property].SourceType == Enum.ContentSourceType.Opaque, "Missing opaque PBR map")
			end
		end
		meshCount += 1
		triangles += instance:GetAttribute("TriangleCount")
	elseif instance:IsA("Model") and instance:GetAttribute("AssetId") then
		components += 1
	end
end
assert(meshCount == request.meshes and components == request.components and triangles == request.triangles,
	"Staged counts differ from the manifest")
local dash = bike.Steering:FindFirstChild("Dash")
if not dash then
	dash = rigidPart("Part","Dash",Vector3.new(.33,.22,.02),
		CFrame.new(studs({0,1.035,-.404})) * CFrame.Angles(math.rad(-39),0,0),bike.Steering)
	weld(dash, bike.Steering.PrimaryPart)
	require(shared.Vehicle.PlaceholderBikeBuilder).buildDash(dash)
end
local ok, problems = contract.validate(bike)
assert(ok, table.concat(problems, "; "))
local previous = assets:FindFirstChild("SB50")
assert(not previous or previous:GetAttribute("StreetbornAsset") == "SB50", "Existing SB50 has a different owner")
History:SetWaypoint("Before SB50 installation")
if previous then previous:Destroy() end
bike.Name = "SB50"
bike._PBRTemplate:Destroy()
bike:SetAttribute("SurfaceRevision", "PBR-2")
bike:SetAttribute("EmbeddedMeshCount", meshCount)
bike:SetAttribute("TriangleCount", triangles)
History:SetWaypoint("Install STREETBORN SB50")
return string.format("AssetContract v%d passed: %d components, %d meshes, %d triangles",
	contract.VERSION, components, meshCount, triangles)
