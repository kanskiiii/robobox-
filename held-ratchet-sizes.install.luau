-- Run after held-tools.install.luau in Studio Edit mode.
local assets = game.ReplicatedStorage.Assets
local held = assets.HeldTools
local ratchet = held.Ratchet
local tray = assets.ToolCases.RatchetSet
local fitted = ratchet.FittedSocket
local sizes = {8, 10, 12, 13, 14, 17, 19}
for _, mm in sizes do
    local name = "Ratchet_" .. mm
    local previous = held:FindFirstChild(name)
    assert(not previous or previous:GetAttribute("CodexHeldTool"), "Existing held tool: " .. name)
end
for _, mm in sizes do
    local name = "Ratchet_" .. mm
    local model = ratchet:Clone()
    model.Name = name
    local socket = tray["Socket_" .. mm].VisibleTool.ChromeBody:Clone()
    socket.Name = "FittedSocket"
    socket.CFrame = fitted.CFrame
    socket.Anchored = true
    model.FittedSocket:Destroy()
    socket.Parent = model
    local previous = held:FindFirstChild(name)
    if previous then previous:Destroy() end
    model.Parent = held
end

local target = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.Interaction
game:GetService("ScriptEditorService"):UpdateSourceAsync(target, function(source)
    local before = [==[	local heldAsset = if heldLib and heldName and want > 0 then heldLib:FindFirstChild(heldName) else nil]==]
    local after = [==[	if heldLib and held and held.id == "socket_set" then
		local sizedName = "Ratchet_" .. tostring(held.size)
		if heldLib:FindFirstChild(sizedName) then heldName = sizedName end
	end
	local heldAsset = if heldLib and heldName and want > 0 then heldLib:FindFirstChild(heldName) else nil]==]
    if source:find(after, 1, true) then return source end
    local first, last = source:find(before, 1, true)
    assert(first and not source:find(before, last + 1, true), "Unexpected Interaction source")
    return source:sub(1, first - 1) .. after .. source:sub(last + 1)
end)
