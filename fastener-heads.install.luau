-- Run in Studio Edit mode to install fastener templates and hook up their visuals.
local builder = game.ServerScriptService.TwoStrokeServer.BikeBuilder
local editor = game:GetService("ScriptEditorService")
local edits = {
    {[==[	local max = Fasteners.maxSteps(def)
	for i = 1, def.bolts do]==], [==[	local max = Fasteners.maxSteps(def)
	local templateName = if def.tool == "screwdriver" then "Screw_Phillips"
		elseif def.tool == "pliers" then "Clip_R"
		elseif def.tool == "plug_wrench" then "Plug_Hex21"
		else "Hex_" .. tostring(def.boltSize or 10)
	local templates = assets("Fasteners")
	local template = templates and templates:FindFirstChild(templateName)
	for i = 1, def.bolts do]==]},
    {[==[		nut.Parent = folder
		BikeBuilder.setBoltSteps]==], [==[		nut.Parent = folder
		if template and template:IsA("Model") then
			nut.Transparency = 1
			local head = template:Clone()
			head.Name = "Head"
			head:PivotTo(nut.CFrame)
			for _, part in head:GetDescendants() do
				if part:IsA("BasePart") then
					local joint = Instance.new("WeldConstraint")
					joint.Part0 = nut
					joint.Part1 = part
					joint.Parent = part
				end
			end
			head.Parent = nut
		end
		BikeBuilder.setBoltSteps]==]},
    {[==[	w.C0 = CFrame.new(base + out * (1 - t) * BOLT_TRAVEL)]==], [==[	local position = base + out * (1 - t) * BOLT_TRAVEL
	local tangent = if math.abs(out.Y) > .95 then Vector3.zAxis else Vector3.yAxis
	local right = out:Cross(tangent).Unit
	w.C0 = CFrame.fromMatrix(position, right, out) * CFrame.Angles(0, (max - steps) * math.pi / 3, 0)]==]},
}
local function revise(source)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected BikeBuilder source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end
revise(editor:GetEditorSource(builder))
local existing = game.ReplicatedStorage.Assets:FindFirstChild("Fasteners")
local first = existing and existing:FindFirstChild("Hex_8")
local body = first and first:FindFirstChild("Body")
-- Replace the staged prototype, which used a clamped Part size.
if existing and #existing:GetChildren() == 10 and body and body:IsA("Part")
    and math.abs(body.Size.Z - .05) < .0001 and not body:FindFirstChildOfClass("SpecialMesh") then
    existing:Destroy()
    existing = nil
end
if not existing then
    -- Run in Studio Edit to stage the fastener templates.
    local assets = game.ReplicatedStorage.Assets
    assert(not assets:FindFirstChild("Fasteners"), "Fastener templates already exist")
    local templates = Instance.new("Folder")
    templates.Name = "Fasteners"
    local steel = Color3.fromRGB(128, 133, 141)
    local dark = Color3.fromRGB(46, 49, 54)
    local studsPerMillimetre = 1 / 280
    
    local function piece(parent, name, size, cf, color, meshType)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = Vector3.one
        part.CFrame = cf
        part.Color = color
        part.Material = Enum.Material.Metal
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = meshType or Enum.MeshType.Brick
        mesh.Scale = size
        mesh.Parent = part
        part.Parent = parent
    end
    
    local function template(name)
        local model = Instance.new("Model")
        model.Name = name
        model.WorldPivot = CFrame.identity
        model.Parent = templates
        return model
    end
    
    local function hex(name, mm)
        local flats = mm * studsPerMillimetre
        local height = math.max(.012, flats * .46)
        local side = flats / math.sqrt(3)
        local head = template(name)
        piece(head, "Body", Vector3.new(side, height, flats), CFrame.new(0, height / 2, 0), steel)
        for _, sign in {-1, 1} do
            for _, endSign in {-1, 1} do
                -- The slope joins the center bar to the point of the hexagon.
                local cf = CFrame.fromMatrix(
                    Vector3.new(sign * side * .75, height / 2, endSign * flats / 4),
                    Vector3.yAxis * (-sign * endSign), -Vector3.xAxis * sign, -Vector3.zAxis * endSign
                )
                piece(head, "Corner", Vector3.new(height, side / 2, flats / 2), cf, steel, Enum.MeshType.Wedge)
            end
        end
    end
    
    for _, mm in {8, 10, 12, 13, 14, 17, 19} do
        hex("Hex_" .. mm, mm)
    end
    hex("Plug_Hex21", 21)
    
    local screw = template("Screw_Phillips")
    piece(screw, "Head", Vector3.new(.012, .028, .028), CFrame.new(0, .006, 0) * CFrame.Angles(0, 0, math.pi / 2), steel, Enum.MeshType.Cylinder)
    for _, angle in {0, math.pi / 2} do
        piece(screw, "Drive", Vector3.new(.018, .002, .003), CFrame.new(0, .012, 0) * CFrame.Angles(0, angle, 0), dark)
    end
    
    local clip = template("Clip_R")
    for _, angle in {0, 45, 90, 135, 180, 225, 270} do
        local cf = CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, .003, .014)
        piece(clip, "Wire", Vector3.new(.013, .006, .005), cf, steel)
    end
    
    templates.Parent = assets
end
editor:UpdateSourceAsync(builder, revise)
