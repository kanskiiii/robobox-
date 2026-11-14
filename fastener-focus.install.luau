-- Run in Studio Edit mode to add fastener focus and tool-size feedback.
local target = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.Interaction
local edits = {
    {[==[-- workbench view ---------------------------------------------------------------------------------]==], [==[local boltGlow: SelectionBox
local function showBoltFocus(target: Target?): string?
	if not target or target.kind ~= "bolt" then
		boltGlow.Adornee = nil
		return nil
	end
	local slot = target.inst.Parent and target.inst.Parent.Parent
	local partId = slot and slot:GetAttribute("PartDef")
	local def = if typeof(partId) == "string" then Catalog.getPart(partId) else nil
	if not def or not def.tool then
		boltGlow.Adornee = nil
		return nil
	end
	local _, tool, size = currentTool()
	local compatible = tool == def.tool
		or ((tool == "spanner" or tool == "socket") and (def.tool == "spanner" or def.tool == "socket"))
	local status: string? = nil
	if not compatible then
		status = if def.tool == "socket" or def.tool == "spanner" then "Use a spanner or ratchet" else "Use " .. def.tool:gsub("_", " ")
	elseif def.boltSize then
		if not size then status = "Pick a size"
		elseif size < def.boltSize then status = "Too small"
		elseif size > def.boltSize then status = "Too big" end
	end
	boltGlow.Color3 = if status then Color3.fromRGB(255, 205, 74) else Color3.fromRGB(114, 255, 146)
	boltGlow.Adornee = target.inst
	return status
end

-- workbench view ---------------------------------------------------------------------------------]==]},
    {[==[	updateTags()
	local t = aim()]==], [==[	updateTags()
	local t = aim()
	local status = showBoltFocus(t)]==]},
    {[==[steps, max)
	elseif t and t.kind == "installed"]==], [==[steps, max)
		if status then hint.Text ..= "   " .. status end
	elseif t and t.kind == "installed"]==]},
    {[==[local function onFrame(frameDt: number?)]==], [==[local function onFrame(frameDt: number?)
	boltGlow.Adornee = nil]==]},
    {[==[	local text = if t then describe(t) else ""
	hint.Text = text]==], [==[	local status = showBoltFocus(t)
	hint.Text = status or (if t then describe(t) else "")]==]},
    {[==[function Interaction.start()
	buildUi()]==], [==[function Interaction.start()
	buildUi()
	boltGlow = Instance.new("SelectionBox")
	boltGlow.Name = "FastenerFocus"
	boltGlow.LineThickness = .012
	boltGlow.SurfaceTransparency = 1
	boltGlow.Parent = gui]==]},
}
game:GetService("ScriptEditorService"):UpdateSourceAsync(target, function(source)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected Interaction source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end)
