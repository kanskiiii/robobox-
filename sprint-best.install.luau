-- Run after the sprint retry and HUD installers in Studio Edit mode.
local target = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi
local edits = {
    {[==[local state: any = nil]==], [==[local state: any = nil
local sprintBest: number? = nil]==]},
    {[==[		text(practice, "From your yard or the sprint finish", 300, 360, Ui.DIM, 12)]==], [==[		local best = sprintBest
		text(practice, if best then ("Session best %.2f s"):format(best) else "From your yard or the sprint finish", 300, 360, Ui.DIM, 12)]==]},
    {[==[	UserInputService.InputBegan:Connect(function(io, processed)]==], [==[	Remotes.get("Sprint").OnClientEvent:Connect(function(phase, _, best)
		if phase == "finished" and typeof(best) == "number" then
			sprintBest = best
			render()
		end
	end)

	UserInputService.InputBegan:Connect(function(io, processed)]==]},
}
game:GetService("ScriptEditorService"):UpdateSourceAsync(target, function(source)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected GarageUi source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end)
