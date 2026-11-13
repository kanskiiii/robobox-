-- Call after the durable catalogs and display assets have been imported and
-- verified. The resolver returns a URI-backed MeshPart for a preview MeshPart.
local function repair(previews, resolve)
    local history = game:GetService("ChangeHistoryService")
    local service = game:GetService("AssetService")
    local replacements, cache, missing = {}, {}, {}

    for _, preview in previews do
        for _, part in preview:GetDescendants() do
            if not part:IsA("MeshPart") or part.MeshContent.SourceType == Enum.ContentSourceType.Uri then
                continue
            end
            local source, expectedSize = resolve(part)
            if not source or source.MeshContent.SourceType ~= Enum.ContentSourceType.Uri then
                table.insert(missing, part:GetFullName())
                continue
            end
            local template = cache[source]
            if not template then
                template = service:CreateMeshPartAsync(source.MeshContent,
                    {CollisionFidelity = Enum.CollisionFidelity.Box})
                template.TextureContent = source.TextureContent
                cache[source] = template
            end
            local intended = expectedSize or part.Size
            local referenceSize = Vector3.new(math.max(intended.X, .001),
                math.max(intended.Y, .001), math.max(intended.Z, .001))
            local ratio = template.MeshSize / referenceSize
            if ratio.Y <= 0 or math.abs(ratio.X / ratio.Y - 1) > .08
                or math.abs(ratio.Z / ratio.Y - 1) > .08 then
                table.insert(missing, part:GetFullName() .. " has incompatible imported bounds")
                continue
            end
            table.insert(replacements, {part = part, template = template, source = source, size = intended})
        end
    end
    if #missing > 0 then
        for _, template in cache do template:Destroy() end
        return {changed = 0, missing = missing}
    end
    if #replacements == 0 then return {changed = 0, missing = missing} end

    local token = assert(history:TryBeginRecording("Repair Two-Stroke preview meshes"))
    local ok, err = pcall(function()
        for _, entry in replacements do
            local part = entry.part
            local frame, offset = part.CFrame, part.PivotOffset
            part:ApplyMesh(entry.template)
            part.Size, part.CFrame, part.PivotOffset = entry.size, frame, offset
            local appearance = entry.source:FindFirstChildWhichIsA("SurfaceAppearance")
            if appearance and not part:FindFirstChildWhichIsA("SurfaceAppearance") then
                part.Color = Color3.new(1, 1, 1)
                appearance:Clone().Parent = part
            end
            part:SetAttribute("PreviewOnly", nil)
            assert(part.MeshContent.SourceType == Enum.ContentSourceType.Uri, part:GetFullName())
        end
    end)
    history:FinishRecording(token, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
    for _, template in cache do template:Destroy() end
    if not ok then error(err) end
    return {changed = #replacements, missing = missing}
end

return repair
