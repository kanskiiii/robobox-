-- Run in Studio Edit to audit serialized mesh references, and in a client to check fetches.
local RunService = game:GetService("RunService")
local verifyRoundTrip = not RunService:IsRunning()
local verifyFetches = RunService:IsClient() and RunService:IsRunning()
local result = {
    checked = 0, uri = 0, temporary = {}, missing = {}, roots = {},
    roundTripFailures = {}, fetches = 0, fetchFailures = {},
}
local preload = {}
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
        if content.SourceType == Enum.ContentSourceType.Uri and content.Uri ~= "" then
            result.uri += 1
            counts.uri += 1
            sample = sample or item
            if verifyFetches then table.insert(preload, item) end
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

check(workspace)
local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
if assets then
    check(assets)
end

if #preload > 0 then
    local failed = {}
    game:GetService("ContentProvider"):PreloadAsync(preload, function(uri, status)
        result.fetches += 1
        if status ~= Enum.AssetFetchStatus.Success then
            failed[uri] = status.Name
        end
    end)
    result.fetchFailures = failed
end

result.passed = result.checked > 0
    and assets ~= nil
    and result.roots[assets:GetFullName()].checked > 0
    and #result.temporary == 0
    and #result.missing == 0
    and #result.roundTripFailures == 0
    and (not verifyFetches or result.fetches > 0 and next(result.fetchFailures) == nil)
return result
