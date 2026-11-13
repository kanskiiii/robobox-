-- Apply after inserting the durable catalog GLB. Supply the imported Model and
-- its decoded manifest. This checks all entries before replacing any previews.
local function install(imported, manifest)
    local History = game:GetService("ChangeHistoryService")
    local storage = game:GetService("ReplicatedStorage")
    local assets = assert(storage:FindFirstChild("Assets"), "Missing ReplicatedStorage.Assets")
    local staged = {}
    local function groupFor(category)
        if category == "Vehicles" then
            return assets.Vehicles.sm50
        end
        return assets[category]
    end

    for _, entry in manifest.components do
        local node = imported:FindFirstChild(entry.node, true)
            or imported:FindFirstChild(entry.node .. "_Node", true)
            or imported:FindFirstChild(entry.node .. "_Geometry", true)
        assert(node, "Missing imported component " .. entry.node)
        local mesh = node:IsA("MeshPart") and node or node:FindFirstChildWhichIsA("MeshPart", true)
        assert(mesh and mesh.MeshContent.SourceType == Enum.ContentSourceType.Uri,
            "Component requires durable Roblox mesh content: " .. entry.node)
        local group = groupFor(entry.category)
        local previous = assert(group:FindFirstChild(entry.name), "Missing staged component " .. entry.name)
        assert(previous:IsA("MeshPart") and previous:GetAttribute("PreviewOnly"),
            "Existing component is not a staged preview: " .. entry.name)
        local part = mesh:Clone()
        -- Imported node origins can be moved by the importer. Match the checked preview's
        -- dimensions and bounds-relative pivot while retaining the durable mesh content.
        local d = entry.dimensionsM
        local expectedSize = Vector3.new(d[1], d[2], d[3]) / manifest.orientation.metresPerStud
        local sourceRatio = mesh.MeshSize / expectedSize
        assert(sourceRatio.Y > 0 and math.abs(sourceRatio.X - sourceRatio.Y) < 0.08 * sourceRatio.Y
            and math.abs(sourceRatio.Y - sourceRatio.Z) < 0.08 * sourceRatio.Y,
            "Imported mesh axes or size do not match the staged component: " .. entry.name)
        part.Name = entry.name
        part.CFrame = previous.CFrame
        part.PivotOffset = previous.PivotOffset
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        local service = game:GetService("AssetService")
        local boxCollision = service:CreateMeshPartAsync(part.MeshContent,
            {CollisionFidelity = Enum.CollisionFidelity.Box})
        boxCollision.TextureContent = part.TextureContent
        part:ApplyMesh(boxCollision)
        boxCollision:Destroy()
        part.Size = expectedSize
        part:SetAttribute("AssetId", entry.assetId)
        part:SetAttribute("TriangleCount", entry.triangles)
        for _, old in previous:GetChildren() do
            if old:IsA("Attachment") then
                assert(not part:FindFirstChild(old.Name), "Duplicate attachment " .. old.Name)
                old:Clone().Parent = part
            end
        end
        table.insert(staged, {part = part, previous = previous, group = group})
    end

    local recording = History:TryBeginRecording("Install Two-Stroke durable catalog")
    assert(recording, "Studio could not start an undo recording")
    local ok, err = pcall(function()
        for _, record in staged do
            record.previous.Parent = nil
            record.part.Parent = record.group
            assert(record.part.MeshContent.SourceType == Enum.ContentSourceType.Uri)
        end
    end)
    History:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
    if not ok then error(err) end
    return #staged
end

return install
