-- Installs a Roblox-imported assembly or world catalog using manifest geometry.
local function install(imported, manifest)
    assert(typeof(imported) == "Instance" and imported:IsA("Model"), "Select the imported catalog Model")
    local catalogId = manifest.assetId
    assert(catalogId == "sm50-catalog" or catalogId == "senda-catalog" or catalogId == "world-catalog",
        "Unsupported catalog")
    local vehicleId = catalogId == "senda-catalog" and "senda" or "sm50"
    assert(manifest.orientation.metresPerStud == 0.28, "Unexpected catalog scale")

    local history = game:GetService("ChangeHistoryService")
    local storage = game:GetService("ReplicatedStorage")
    local service = game:GetService("AssetService")
    local staged, used = {}, {}
    local function studs(value)
        return Vector3.new(value[1], value[2], value[3]) / manifest.orientation.metresPerStud
    end
    local function folder(parent, name, create)
        if not parent then return nil end
        local item = parent:FindFirstChild(name)
        if item then
            assert(item:IsA("Folder"), item:GetFullName() .. " must be a Folder")
        elseif create then
            item = Instance.new("Folder")
            item.Name = name
            item.Parent = parent
        end
        return item
    end
    local function groupFor(category, create)
        local assets = folder(storage, "Assets", create)
        local group = folder(assets, category, create)
        if category == "Vehicles" then return folder(group, vehicleId, create) end
        return group
    end
    local function findMesh(entry)
        local aliases = {[entry.node]=true, [entry.node .. "_Node"]=true, [entry.node .. "_Geometry"]=true}
        local candidates = {}
        for _, item in imported:GetDescendants() do
            if item:IsA("MeshPart") then
                local ancestor = item
                while ancestor ~= imported do
                    if aliases[ancestor.Name] then
                        table.insert(candidates, item)
                        break
                    end
                    ancestor = ancestor.Parent
                end
            end
        end
        assert(#candidates == 1, entry.node .. " needs exactly one imported MeshPart; found " .. #candidates)
        return candidates[1]
    end
    for _, entry in manifest.components do
        assert(#entry.materials == 1, "Expected one material layer per catalog entry")
        local mesh = findMesh(entry)
        assert(not used[mesh], "Imported mesh matched more than one entry: " .. entry.node)
        used[mesh] = true
        assert(mesh.MeshContent.SourceType == Enum.ContentSourceType.Uri,
            "Import with Upload to Roblox enabled: " .. entry.node)
        assert(mesh.CFrame.RightVector:Dot(Vector3.xAxis) > 0.999
            and mesh.CFrame.UpVector:Dot(Vector3.yAxis) > 0.999,
            "Import with +Y up and -Z forward, with no root rotation: " .. entry.node)
        local group = groupFor(entry.category, false)
        local previous = group and group:FindFirstChild(entry.name)
        if previous then
            assert(previous:IsA("MeshPart") and previous:GetAttribute("AssetId") == entry.assetId,
                "Existing instance has a different asset identity: " .. previous:GetFullName())
        end

        local b = entry.materialBoundsM[entry.materials[1]]
        local size = studs(b.size)
        local center = (studs(b.min) + studs(b.max)) / 2
        local ratio = mesh.MeshSize / size
        assert(ratio.Y > 0 and math.abs(ratio.X - ratio.Y) < 0.08 * ratio.Y
            and math.abs(ratio.Y - ratio.Z) < 0.08 * ratio.Y,
            "Imported mesh bounds do not match the manifest: " .. entry.node)
        local part = mesh:Clone()
        local boxMesh = service:CreateMeshPartAsync(mesh.MeshContent,
            {CollisionFidelity = Enum.CollisionFidelity.Box})
        boxMesh.TextureContent = mesh.TextureContent
        part:ApplyMesh(boxMesh)
        boxMesh:Destroy()
        part.Name = entry.name
        part.Size = size
        part.CFrame = CFrame.new(center)
        part.PivotOffset = CFrame.new(-center)
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part:SetAttribute("AssetId", entry.assetId)
        part:SetAttribute("TriangleCount", entry.triangles)
        part:SetAttribute("PreviewOnly", nil)
        for name, value in entry.attachmentLocalM do
            local marker = part:FindFirstChild(name)
            if marker then
                assert(marker:IsA("Attachment"), "Unexpected child " .. name)
            else
                marker = Instance.new("Attachment")
                marker.Name = name
                marker.Parent = part
            end
            marker.Position = studs(value) - center
        end
        assert(part.MeshContent.SourceType == Enum.ContentSourceType.Uri, entry.node .. " lost its asset URI")
        table.insert(staged, {part=part, previous=previous, category=entry.category})
    end

    local recording = assert(history:TryBeginRecording("Install Two-Stroke durable catalog"))
    local ok, err = pcall(function()
        for _, record in staged do
            local group = groupFor(record.category, true)
            assert(group:FindFirstChild(record.part.Name) == record.previous, "Catalog changed during import")
            if record.previous then record.previous.Parent = nil end
            record.part.Parent = group
        end
    end)
    history:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
    if not ok then error(err) end
    return #staged
end

return install
