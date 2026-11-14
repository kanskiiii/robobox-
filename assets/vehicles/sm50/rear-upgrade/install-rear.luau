-- Import both GLBs with Upload to Roblox enabled. Set each name below if Studio renames the mesh.
local uploadFolder = workspace:WaitForChild("SM50RearImports", 5)
assert(uploadFolder, "Put the two imported meshes in Workspace.SM50RearImports")
local parts = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Parts")
local meshFacesPositiveZ = true -- Common Roblox GLB import. Set false for an import already facing -Z.
local scale = 1 / 0.28
local specifications = {
	{ name = "Part_seat_std", min = Vector3.new(-.106, -.1384928, -.366), max = Vector3.new(.106, .08594, .575) },
	{ name = "Part_exhaust_std", min = Vector3.new(-.01895864, -.2412713, -.1388474), max = Vector3.new(.198907, .287767, .8988898) },
}
local staged = {}

for _, spec in ipairs(specifications) do
	local incoming = {}
	for _, node in ipairs(uploadFolder:GetDescendants()) do
		if node:IsA("MeshPart") and node.Name == spec.name then table.insert(incoming, node) end
	end
	assert(#incoming == 1, "Expected one uploaded mesh named " .. spec.name)
	local mesh = incoming[1]
	assert(mesh.MeshContent.SourceType == Enum.ContentSourceType.Uri, "Upload the mesh to Roblox first")
	assert(mesh:FindFirstChildOfClass("SurfaceAppearance") or mesh.TextureID ~= "",
		"Import the texture with " .. spec.name)
	local old = assert(parts:FindFirstChild(spec.name), "Missing original " .. spec.name)
	local part = mesh:Clone()
	local size = (spec.max - spec.min) * scale
	local ratio = mesh.MeshSize / size
	assert(ratio.Y > 0 and math.abs(ratio.X / ratio.Y - 1) < .08 and math.abs(ratio.Z / ratio.Y - 1) < .08,
		"Check scale and axis settings for " .. spec.name)
	part.Name = old.Name
	part.Size = size
	part.Color = Color3.new(1, 1, 1)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = old.CanQuery
	part.Massless = true
	for _, child in ipairs(part:GetChildren()) do
		if not child:IsA("SurfaceAppearance") then child:Destroy() end
	end
	local center = (spec.min + spec.max) * (.5 * scale)
	local facing = if meshFacesPositiveZ then CFrame.Angles(0, math.pi, 0) else CFrame.identity
	part.PivotOffset = (CFrame.new(center) * facing):Inverse()
	part:PivotTo(old:GetPivot())
	for key, value in pairs(old:GetAttributes()) do part:SetAttribute(key, value) end
	part:SetAttribute("SM50RearUpgrade", true)
	for _, marker in ipairs(old:GetChildren()) do
		if marker:IsA("Attachment") then
			local copy = marker:Clone()
			copy.CFrame = part.CFrame:ToObjectSpace(marker.WorldCFrame)
			copy.Parent = part
		end
	end
	table.insert(staged, {old = old, part = part})
end

for _, entry in ipairs(staged) do
	entry.old:Destroy()
	entry.part.Parent = parts
end
print("Installed stock SM50 exhaust and rear assembly. Start a fresh playtest to rebuild the bike.")
