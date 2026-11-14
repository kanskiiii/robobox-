-- Run after tool-cases.install.luau in Studio Edit mode.
local target = game.ServerScriptService.TwoStrokeServer.ToolCases
local edits = {
    {[==[	local lid = m:FindFirstChild("Lid") :: BasePart]==], [==[	local lid = m:FindFirstChild("Lid") :: BasePart
	if m:GetAttribute("CodexToolCase") then
		-- The decorative shell has non-queryable geometry. Aim at its rim to carry it.
		local width, height, depth = body.Size.X, body.Size.Y, body.Size.Z
		body.CanCollide = false
		body.CanQuery = false
		local floor = Instance.new("Part")
		floor.Name = "CaseFloor"
		floor.Size = Vector3.new(width - .04, .05, depth - .04)
		floor.CFrame = body.CFrame * CFrame.new(0, (.05 - height) / 2, 0)
		floor.Transparency = 1
		floor.CanTouch = false
		floor.Parent = body
		for _, side in {-1, 1} do
			for _, longEdge in {true, false} do
				local grip = Instance.new("Part")
				grip.Name = "CaseGrip"
				grip.Size = if longEdge then Vector3.new(width, height, .055)
					else Vector3.new(.055, height, depth - .11)
				local offset = if longEdge then Vector3.new(0, 0, side * (depth - .055) / 2)
					else Vector3.new(side * (width - .055) / 2, 0, 0)
				grip.CFrame = body.CFrame * CFrame.new(offset)
				grip.Transparency = 1
				grip.CanCollide = false
				grip.CanTouch = false
				grip.Parent = body
			end
		end
	end]==]},
    {[==[	c.openPrompt.ActionText = if c.open then "Close" else "Open"]==], [==[	if c.model:GetAttribute("CodexToolCase") then
		c.lid.CanQuery = not c.open
	end
	c.openPrompt.ActionText = if c.open then "Close" else "Open"]==]},
}
game:GetService("ScriptEditorService"):UpdateSourceAsync(target, function(source)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected ToolCases source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end)
