-- Run in Studio Edit mode to add the personal night preview to the garage.
local target = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.GarageUi
local edits = {
    {[==[local Players = game:GetService("Players")]==], [==[local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")]==]},
    {[==[	local storage = game:GetService("ReplicatedStorage")]==], [==[	local daylight: {clock: number, brightness: number, exposure: number}? = nil
	local nightButton: TextButton
	nightButton = Ui.button("Night preview", function()
		local previous = daylight
		if previous then
			Lighting.ClockTime = previous.clock
			Lighting.Brightness = previous.brightness
			Lighting.ExposureCompensation = previous.exposure
			daylight = nil
			nightButton.Text = "Night preview"
		else
			daylight = {clock = Lighting.ClockTime, brightness = Lighting.Brightness, exposure = Lighting.ExposureCompensation}
			Lighting.ClockTime = 21.5
			Lighting.Brightness = 1.3
			Lighting.ExposureCompensation = -.35
			nightButton.Text = "Restore daylight"
		end
	end, { Position = UDim2.new(0, 18, 1, -18), Size = UDim2.fromOffset(116, 16), Parent = window })
	local storage = game:GetService("ReplicatedStorage")]==]},
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
