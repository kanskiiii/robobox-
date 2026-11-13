-- Run in Studio Edit mode, then run in a fresh session after saving.
-- Set verifyRoundTrip to true to check one representative durable part per root.
local result = { checked = 0, uri = 0, temporary = {}, missing = {}, roots = {}, roundTripFailures = {} }
local function check(root)
    local counts = {checked = 0, uri = 0, temporary = 0, missing = 0}
    local sample
    for _, item in root:GetDescendants() do
        if not item:IsA("MeshPart") then
            continue
        end
        result.checked += 1
        counts.checked += 1
        local content = item.MeshContent
        if content.SourceType == Enum.ContentSourceType.Uri then
            result.uri += 1
            counts.uri += 1
            sample = sample or item
        elseif content.SourceType == Enum.ContentSourceType.Object then
            table.insert(result.temporary, item:GetFullName())
            counts.temporary += 1
        else
            table.insert(result.missing, item:GetFullName())
            counts.missing += 1
        end
    end
    result.roots[root:GetFullName()] = counts
    if verifyRoundTrip and sample then
        local serializer = game:GetService("SerializationService")
        local ok, same = pcall(function()
            local reopened = serializer:DeserializeInstancesAsync(serializer:SerializeInstancesAsync({sample}))[1]
            local matches = reopened.MeshContent.SourceType == Enum.ContentSourceType.Uri
                and reopened.MeshContent.Uri == sample.MeshContent.Uri
            reopened:Destroy()
            return matches
        end)
        if not ok or not same then table.insert(result.roundTripFailures, sample:GetFullName()) end
    end
end

for _, item in workspace:GetChildren() do
    if item:GetAttribute("PreviewOnly") or item:GetAttribute("AssetId") then
        check(item)
    end
end
local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
if assets then
    check(assets)
end

return result
