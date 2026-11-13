-- Imports is keyed by the preview root's AssetId. Each value contains the
-- imported Model and the corresponding decoded manifest.
local function buildResolver(imports)
    local byAsset = {}
    local catalog = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
    local function matchesBounds(mesh, bounds)
        if not bounds then return false end
        local d = bounds.size
        local expected = Vector3.new(d[1], d[2], d[3])
        local actual = mesh.MeshSize
        if expected.Y <= 0 or actual.Y <= 0 then return false end
        local normalized = actual * (expected.Y / actual.Y)
        return math.abs(normalized.X - expected.X) <= math.max(.001, expected.X * .025)
            and math.abs(normalized.Z - expected.Z) <= math.max(.001, expected.Z * .025)
    end
    for id, data in imports do
        local byComponent = {}
        for _, entry in data.manifest.components do
            local node = data.model:FindFirstChild(entry.node, true)
                or data.model:FindFirstChild(entry.node .. "_Node", true)
                or data.model:FindFirstChild(entry.node .. "_Geometry", true)
            if not node then continue end
            local meshes = {}
            if node:IsA("MeshPart") then table.insert(meshes, node) end
            for _, child in node:GetDescendants() do
                if child:IsA("MeshPart") then table.insert(meshes, child) end
            end
            local candidates = {}
            for _, key in entry.materials do
                local matches = {}
                for _, mesh in meshes do
                    if mesh:GetAttribute("MaterialKey") == key or mesh.Name == key then
                        table.insert(matches, mesh)
                    end
                end
                if #matches == 1 then
                    candidates[key] = matches[1]
                elseif #entry.materials == 1 and #meshes == 1 then
                    candidates[key] = meshes[1]
                elseif entry.materialBoundsM then
                    local shaped = {}
                    for _, mesh in meshes do
                        if matchesBounds(mesh, entry.materialBoundsM[key]) then
                            table.insert(shaped, mesh)
                        end
                    end
                    if #shaped == 1 then candidates[key] = shaped[1] end
                end
            end
            local used = {}
            for _, mesh in candidates do
                used[mesh] = (used[mesh] or 0) + 1
            end
            for key, mesh in candidates do
                if used[mesh] > 1 then
                    candidates[key] = nil
                else
                    local b = entry.materialBoundsM and entry.materialBoundsM[key]
                    local d = b and b.size or entry.dimensionsM
                    local size = Vector3.new(d[1], d[2], d[3]) / data.manifest.orientation.metresPerStud
                    candidates[key] = {mesh = mesh, size = size}
                end
            end
            byComponent[entry.assetId] = candidates
        end
        byAsset[id] = byComponent
    end

    return function(part)
        local ownId = part:GetAttribute("AssetId")
        if ownId and catalog and part:IsDescendantOf(workspace) then
            if ownId:sub(1, 13) == "sm50-catalog." then
                local source = ownId == "sm50-catalog.Frame" and catalog.Vehicles.sm50.Frame
                    or catalog.Parts:FindFirstChild(part.Name)
                if source then return source, source.Size end
            end
        end
        local component = part.Parent
        local componentId = component and component:GetAttribute("AssetId")
        local material = part:GetAttribute("MaterialKey")
        if not componentId or not material then return nil end
        local root = component.Parent and component.Parent.Parent
        local id = root and root:GetAttribute("AssetId")
        local candidates = byAsset[id]
        local matches = candidates and candidates[componentId]
        local selected = matches and matches[material]
        if selected then return selected.mesh, selected.size end
        return nil
    end
end

return buildResolver
