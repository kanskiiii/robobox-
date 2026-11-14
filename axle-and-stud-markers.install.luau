-- Apply after fastener-heads.install.luau.
local builder = game.ServerScriptService.TwoStrokeServer.BikeBuilder
local editor = game:GetService("ScriptEditorService")
local before = [==[		local out = pos - centre
		out = if out.Magnitude > 1e-3 then out.Unit else Vector3.yAxis]==]
local after = [==[		local out = pos - centre
		if at and at:IsA("Attachment") and at:GetAttribute("FastenerAxis") then
			out = slotPart.CFrame:VectorToObjectSpace(at.WorldCFrame.UpVector)
		else
			out = if out.Magnitude > 1e-3 then out.Unit else Vector3.yAxis
		end]==]
local function revise(source)
    if source:find(after, 1, true) then return source end
    local first, last = source:find(before, 1, true)
    assert(first and not source:find(before, last + 1, true), "Unexpected BikeBuilder source")
    return source:sub(1, first - 1) .. after .. source:sub(last + 1)
end
revise(editor:GetEditorSource(builder))
-- Run in Studio Edit after the Zefir and Senda meshes are installed.
local parts = game.ReplicatedStorage.Assets.Parts
local studsPerMetre = 1 / .28
local markers = {}

local function add(partName, number, position, out)
    local part = parts:FindFirstChild("Part_" .. partName)
    if not part or not part:IsA("MeshPart") then return end
    local name = "Bolt_" .. number
    local marker = part:FindFirstChild(name)
    assert(not marker or marker:IsA("Attachment"), "Invalid " .. partName .. "." .. name)
    local tangent = if math.abs(out.Y) > .95 then Vector3.zAxis else Vector3.yAxis
    local pose = CFrame.fromMatrix(position * studsPerMetre, out:Cross(tangent).Unit, out)
    table.insert(markers, {part = part, name = name, marker = marker, pose = part.PivotOffset * pose})
end

-- The axle fastener sits past the outside of the fork or swingarm.
-- Keep one service fastener per axle so saved assemblies keep their tightening state.
for _, prefix in {"", "sd_"} do
    add(prefix .. "wheel_front_17", 1, Vector3.new(-.132, 0, 0), -Vector3.xAxis)
    add(prefix .. "wheel_rear_17", 1, Vector3.new(.164, 0, 0), Vector3.xAxis)
end

local topStuds = {
    cylinder_50 = {.1337, .027, -.028},
    sd_cylinder = {.1337, .027, -.028},
    head_std = {.0341, .025, 0},
    head_hc = {.0341, .025, 0},
    sd_head = {.0341, .025, 0},
}
for partName, spec in topStuds do
    local height, spacing, offset = table.unpack(spec)
    add(partName, 1, Vector3.new(spacing, height, offset + spacing), Vector3.yAxis)
    add(partName, 2, Vector3.new(-spacing, height, offset + spacing), Vector3.yAxis)
    add(partName, 3, Vector3.new(-spacing, height, offset - spacing), Vector3.yAxis)
    add(partName, 4, Vector3.new(spacing, height, offset - spacing), Vector3.yAxis)
end
for _, entry in markers do
    local marker = entry.marker or Instance.new("Attachment")
    marker.Name = entry.name
    marker.CFrame = entry.pose
    marker:SetAttribute("FastenerAxis", true)
    marker.Parent = entry.part
end

editor:UpdateSourceAsync(builder, revise)
