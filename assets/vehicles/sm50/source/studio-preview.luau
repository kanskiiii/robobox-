-- Edit-time preview. Run this file with payload set to a batch from the asset's studio JSON.
local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local HttpService = game:GetService("HttpService")
local History = game:GetService("ChangeHistoryService")

local SCALE = 1 / 0.28
local config = previewConfig or {
    rootName = "SM50_AssetPreview",
    assetId = "sm50",
    placement = Vector3.new(9, 0, 0),
    floorOffset = 0.001269,
}
local ROOT_NAME = config.rootName
local PLACEMENT = config.placement
local function metres(a)
    return Vector3.new(a[1], a[2], a[3]) * SCALE
end

local root = workspace:FindFirstChild(ROOT_NAME)
if not root and not config.catalog then
    local ignored = {}
    for _, child in workspace:GetChildren() do
        if child:GetAttribute("PreviewOnly") or child:IsA("SpawnLocation") then
            table.insert(ignored, child)
        end
    end
    local query = RaycastParams.new()
    query.FilterType = Enum.RaycastFilterType.Exclude
    query.FilterDescendantsInstances = ignored
    local hit = workspace:Raycast(PLACEMENT + Vector3.yAxis * 30, -Vector3.yAxis * 100, query)
    local ground = hit and hit.Position.Y or 0
    root = Instance.new("Model")
    root.Name = ROOT_NAME
    root.WorldPivot = CFrame.new(PLACEMENT.X, ground + config.floorOffset * SCALE, PLACEMENT.Z)
    root:SetAttribute("AssetId", config.assetId)
    root:SetAttribute("PreviewOnly", true)
    root:SetAttribute("MetresPerStud", 0.28)
    root.Parent = workspace
end
if root then
    assert(root:GetAttribute("AssetId") == config.assetId and root:GetAttribute("PreviewOnly") == true)
end
local origin = root and root:GetPivot() or CFrame.identity
local function getGroup(name)
    if config.catalog then
        local assets = game.ReplicatedStorage:FindFirstChild("Assets")
        if not assets then
            assets = Instance.new("Folder")
            assets.Name = "Assets"
            assets.Parent = game.ReplicatedStorage
        end
        local group = assets:FindFirstChild(name)
        if not group then
            group = Instance.new("Folder")
            group.Name = name
            group.Parent = assets
        end
        if name == "Vehicles" then
            local vehicle = group:FindFirstChild("sm50")
            if not vehicle then
                vehicle = Instance.new("Folder")
                vehicle.Name = "sm50"
                vehicle.Parent = group
            end
            return vehicle
        end
        return group
    end
    local group = root:FindFirstChild(name)
    if not group then
        group = Instance.new("Folder")
        group.Name = name
        group.Parent = root
    end
    return group
end

if type(payload) == "table" then
    local previous = root:FindFirstChild("CollisionProxies")
    if previous then previous:Destroy() end
    local group = getGroup("CollisionProxies")
    for _, config in payload do
        local part = Instance.new("Part")
        part.Name = config.name
        part.Shape = config.shape == "Cylinder" and Enum.PartType.Cylinder or Enum.PartType.Block
        part.Size = metres(config.size)
        part.CFrame = origin * CFrame.new(metres(config.center))
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Transparency = 1
        part:SetAttribute("TargetComponent", config.target)
        part.Parent = group
    end
    History:SetWaypoint("Stage " .. config.assetId .. " collision proxies")
    return #payload
end

local bytes = EncodingService:DecompressBuffer(
    EncodingService:Base64Decode(buffer.fromstring(payload)), Enum.CompressionAlgorithm.Zstd)
local headerLength = buffer.readu32(bytes, 0)
local meta = HttpService:JSONDecode(buffer.readstring(bytes, 4, headerLength))
local cursor = 4 + headerLength
local group = getGroup(meta.category)
local meshCount, triangleCount = 0, 0
local function makeLayer(layer, worldPivot)
    local raw, ids, normals = {}, {}, {}
    local lo = Vector3.new(math.huge, math.huge, math.huge)
    local hi = -lo
    for i = 1, layer.v do
        local p = Vector3.new(buffer.readf32(bytes,cursor),buffer.readf32(bytes,cursor+4),
            buffer.readf32(bytes,cursor+8)) * SCALE
        cursor += 12
        raw[i] = p
        lo = lo:Min(p)
        hi = hi:Max(p)
    end
    local center = (lo + hi) * 0.5
    local editable = AssetService:CreateEditableMesh()
    local normalCache = {}
    for i, p in raw do
        ids[i] = editable:AddVertex(p - center)
        local key = buffer.readu8(bytes,cursor)*65536 + buffer.readu8(bytes,cursor+1)*256
            + buffer.readu8(bytes,cursor+2)
        if not normalCache[key] then
            local n = Vector3.new(buffer.readi8(bytes,cursor),buffer.readi8(bytes,cursor+1),
                buffer.readi8(bytes,cursor+2)).Unit
            normalCache[key] = editable:AddNormal(n)
        end
        normals[i] = normalCache[key]
        cursor += 3
    end
    local faceList = {}
    for i = 1, layer.f do
        local a,b,c = buffer.readu16(bytes,cursor)+1,buffer.readu16(bytes,cursor+2)+1,
            buffer.readu16(bytes,cursor+4)+1
        cursor += 6
        local face = editable:AddTriangle(ids[a], ids[b], ids[c])
        editable:SetFaceNormals(face, {normals[a], normals[b], normals[c]})
        if layer.hasColors then faceList[i] = {face,a,b,c} end
    end
    if layer.hasColors then
        local cache, colors = {}, {}
        for i = 1, layer.v do
            local index = buffer.readu8(bytes,cursor)+1
            cursor += 1
            if not cache[index] then
                local material = meta.palette[meta.colorKeys[index]]
                cache[index] = editable:AddColor(Color3.fromHex(material.hex), 1)
            end
            colors[i] = cache[index]
        end
        for _, f in faceList do
            editable:SetFaceColors(f[1], {colors[f[2]], colors[f[3]], colors[f[4]]})
        end
    end
    local part = AssetService:CreateMeshPartAsync(Content.fromObject(editable),
        {CollisionFidelity=Enum.CollisionFidelity.Box})
    local mat = meta.palette[layer.key]
    part.Name = layer.key
    part.Color = Color3.fromHex(mat.hex)
    part.Material = Enum.Material[mat.studioMaterial]
    part.Transparency = mat.transparency
    part.CastShadow = mat.transparency == 0
    part.Anchored = not config.catalog
    part.CanCollide = false
    part.CanTouch = false
    part.CFrame = worldPivot * CFrame.new(center)
    part.PivotOffset = CFrame.new(-center)
    part:SetAttribute("TriangleCount", layer.f)
    part:SetAttribute("MaterialKey", layer.key)
    return part
end
for _, definition in meta.parts do
    if config.catalog then
        assert(#definition.layers == 1, "Catalog entries require exactly one MeshPart")
        local part = makeLayer(definition.layers[1], CFrame.identity)
        part.Name = definition.name
        part:SetAttribute("AssetId", config.assetId .. "." .. definition.name)
        part:SetAttribute("PreviewOnly", true)
        for name, localPosition in definition.attachments do
            local attachment = Instance.new("Attachment")
            attachment.Name = name
            attachment.Position = part.CFrame:PointToObjectSpace(metres(localPosition))
            attachment.Parent = part
        end
        local existing = group:FindFirstChild(part.Name)
        if existing then
            assert(existing:GetAttribute("AssetId") == part:GetAttribute("AssetId")
                and existing:GetAttribute("PreviewOnly"), "Catalog entry already exists: " .. part.Name)
            existing:Destroy()
        end
        part.Parent = group
        meshCount += 1
        triangleCount += definition.layers[1].f
        task.wait()
        continue
    end
    local component = Instance.new("Model")
    component.Name = definition.name
    component:SetAttribute("AssetId", config.assetId .. "." .. definition.name)
    local pivot = origin * CFrame.new(metres(definition.pivot))
    component.WorldPivot = pivot
    local first
    for _, layer in definition.layers do
        local part = makeLayer(layer, pivot)
        part.Parent = component
        first = first or part
        meshCount += 1
        triangleCount += layer.f
    end
    component.PrimaryPart = first
    for name, localPosition in definition.attachments do
        local attachment = Instance.new("Attachment")
        attachment.Name = name
        attachment.Position = first.CFrame:PointToObjectSpace(pivot:PointToWorldSpace(metres(localPosition)))
        attachment.Parent = first
    end
    local existing = group:FindFirstChild(component.Name)
    if existing then existing:Destroy() end
    component.Parent = group
    task.wait()
end
assert(cursor == buffer.len(bytes), "Preview batch contained trailing data")
History:SetWaypoint("Build " .. config.assetId .. " " .. meta.category .. " preview")
return {category=meta.category,components=#meta.parts,meshes=meshCount,triangles=triangleCount}
