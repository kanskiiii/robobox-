-- Run in Studio Edit mode to show the server's place version in the garage menu.
local edit = game:GetService("ScriptEditorService")
local changes = {
    {game.ServerScriptService.TwoStrokeServer.Main, [==[World.build()
GarageService.start()]==], [==[game:GetService("ReplicatedStorage"):SetAttribute("TwoStrokePlaceVersion", game.PlaceVersion)
World.build()
GarageService.start()]==]},
    {game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi, [==[	for i, name in TABS do]==], [==[	local versionLabel = Ui.label("", 12, Ui.DIM, { Position = UDim2.new(1, -180, 1, -17),
		Size = UDim2.fromOffset(150, 14), TextXAlignment = Enum.TextXAlignment.Right, Parent = window })
	local storage = game:GetService("ReplicatedStorage")
	local function showPlaceVersion()
		local version = storage:GetAttribute("TwoStrokePlaceVersion")
		versionLabel.Text = if typeof(version) == "number" then "Place version " .. tostring(version) else ""
	end
	storage:GetAttributeChangedSignal("TwoStrokePlaceVersion"):Connect(showPlaceVersion)
	showPlaceVersion()
	for i, name in TABS do]==]},
}

for _, change in changes do
    local target, before, after = table.unpack(change)
    edit:UpdateSourceAsync(target, function(source)
        if source:find(after, 1, true) then return source end
        local first, last = source:find(before, 1, true)
        assert(first and not source:find(before, last+1, true), "Unexpected source in " .. target:GetFullName())
        return source:sub(1, first-1) .. after .. source:sub(last+1)
    end)
end
