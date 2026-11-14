-- Run in Studio Edit mode. Geometry is authored in studs relative to the existing part pivots.
local assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets")
local parts = assets:WaitForChild("Parts")
local V = Vector3.new
local rgb = Color3.fromRGB
local metal = Enum.Material.Metal
local plastic = Enum.Material.SmoothPlastic
local rubber = Enum.Material.Rubber
local alloy, chrome = rgb(144, 155, 168), rgb(205, 217, 228)
local black, graphite = rgb(20, 23, 29), rgb(41, 46, 54)
local blue, ice, white = rgb(20, 104, 209), rgb(74, 196, 246), rgb(230, 237, 244)
local origin
local shell

local function solid(name, size, localFrame, color, material, shape, class)
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = origin * localFrame
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Parent = shell
	local weld = Instance.new("Weld")
	weld.Name = "DetailWeld"
	weld.Part0 = shell
	weld.Part1 = p
	weld.C0 = shell.CFrame:ToObjectSpace(p.CFrame)
	weld.Parent = p
	return p
end

local function box(name, size, center, color, material, rotation)
	return solid(name, size, CFrame.new(center) * (rotation or CFrame.identity), color, material)
end

local function tube(name, a, b, diameter, color, material)
	local mid = (a + b) / 2
	return solid(name, V((b - a).Magnitude, diameter, diameter),
		CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0), color, material, Enum.PartType.Cylinder)
end

local function path(name, points, diameter, color, material)
	for i = 1, #points - 1 do tube(name, points[i], points[i + 1], diameter, color, material) end
end

-- Tessellate a flat polygon with pairs of right triangles so the edges follow the bodywork outline.
local function triangle(name, a, b, c, depth, color, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > bc.Magnitude and ab.Magnitude >= ac.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local back = bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	for _, piece in ipairs({
		{a, b, right, back, math.abs(ab:Dot(back))},
		{a, c, -right, -back, math.abs(ac:Dot(back))},
	}) do
		if piece[5] > 0.008 and height > 0.008 then
			solid(name, V(depth, height, piece[5]), CFrame.fromMatrix((piece[1] + piece[2]) / 2,
				piece[3], up, piece[4]), color, material, nil, "WedgePart")
		end
	end
end

local function panel(name, vertices, depth, color, material)
	for i = 2, #vertices - 1 do
		triangle(name, vertices[1], vertices[i], vertices[i + 1], depth, color, material)
	end
end

local function marker(name, position)
	local a = shell:FindFirstChild(name)
	if not a then
		a = Instance.new("Attachment")
		a.Name = name
		a.Parent = shell
	end
	a.Position = shell.CFrame:PointToObjectSpace(origin:PointToWorldSpace(position))
	return a
end

local function cockpit()
	local sides = { {sign = -1, grip = "GripL", label = "Clutch"}, {sign = 1, grip = "GripR", label = "Brake"} }
	tube("Tapered center bar", V(-0.44, 0, 0), V(0.44, 0, 0), 0.115, alloy, metal)
	for _, side in ipairs(sides) do
		local s = side.sign
		local grip = origin:PointToObjectSpace(shell[side.grip].WorldPosition)
		local inner = grip - V(s * 0.17, 0.008, 0.018)
		local outer = grip + V(s * 0.22, 0.01, 0.025)
		path("Drawn alloy bar", {V(s * 0.36, 0, 0), V(s * 0.55, 0.028, 0.028),
			V(s * 0.78, grip.Y - 0.024, grip.Z - 0.052), outer}, 0.073, alloy, metal)
		tube("Rubber " .. side.grip, inner, outer, 0.113, black, rubber)
		for n = 1, 8 do
			local h = inner:Lerp(outer, n / 9)
			tube("Grip ribs", h, h + V(s * 0.009, 0, 0), 0.118, graphite, rubber)
		end
		tube("Grip flange", inner - V(s * 0.021, 0, 0), inner, 0.154, black, rubber)
		tube("Bar end", outer, outer + V(s * 0.029, 0, 0), 0.115, blue, metal)
		local perch = inner - V(s * 0.057, 0, 0.028)
		box(side.label .. " perch", V(0.112, 0.116, 0.126), perch, graphite, metal)
		local pivot = perch - V(0, 0.02, 0.068)
		marker("Lever_" .. side.label .. "_Pivot", pivot)
		tube("Pivot pin", pivot - V(0, 0.028, 0), pivot + V(0, 0.052, 0), 0.050, chrome, metal)
		path(side.label .. " lever", {pivot, pivot + V(s * 0.09, -0.010, -0.069),
			pivot + V(s * 0.29, -0.023, -0.088), pivot + V(s * 0.43, -0.022, -0.040)}, 0.035, chrome, metal)
		local tip = pivot + V(s * 0.43, -0.022, -0.040)
		tube("Rounded lever end", tip - V(0.024, 0, 0), tip + V(0.024, 0, 0), 0.049, chrome, metal)
		path(side.label .. " line", {perch - V(0, 0.025, 0.05), V(s * 0.69, 0.03, -0.19),
			V(s * 0.46, -0.10, -0.32), V(s * 0.23, -0.24, -0.30)}, 0.023, black, rubber)
		for _, z in ipairs({-0.057, 0.032}) do
			local p = V(s * 0.157, 0.053, z)
			-- The live fastener system draws the visible bolt heads from the existing markers.
			box("Clamp cap", V(0.095, 0.072, 0.073), p - V(0, 0.039, 0), graphite, metal)
		end
	end
	box("Master cylinder", V(0.235, 0.095, 0.137), V(0.74, 0.137, -0.025), graphite, metal)
	box("Reservoir cap", V(0.208, 0.022, 0.113), V(0.74, 0.191, -0.025), black, plastic)
	box("Switch housing", V(0.108, 0.125, 0.142), V(-0.76, 0.113, 0.089), graphite, plastic)
	box("Kill switch", V(0.066, 0.024, 0.061), V(-0.76, 0.184, 0.103), rgb(182, 49, 40), plastic)
	local dash = CFrame.Angles(math.rad(14), 0, 0)
	box("Instrument housing", V(0.46, 0.086, 0.248), V(0, 0.063, -0.234), graphite, plastic, dash)
	local display = box("LCD screen", V(0.36, 0.014, 0.165), V(0, 0.112, -0.233), rgb(107, 144, 144), plastic, dash)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(256, 116)
	gui.LightInfluence = 1
	gui.Parent = display
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Text = "2T"
	text.TextScaled = true
	text.Font = Enum.Font.RobotoMono
	text.TextColor3 = rgb(28, 53, 53)
	text.Parent = gui
end

local function frontFork()
	marker("RidingHeadlight", V(0, 0.34, -0.478))
	for _, s in ipairs({-1, 1}) do
		local top = V(s * 0.365, 0.75, 0.197)
		local axle = V(s * 0.365, -1.7357, -0.9357)
		local middle = top:Lerp(axle, 0.49)
		tube("Anodized fork upper", top, middle, 0.221, graphite, metal)
		tube("Fork cap", top, top + (top - axle).Unit * 0.037, 0.192, chrome, metal)
		tube("Dust seal", middle:Lerp(top, 0.02), middle:Lerp(axle, 0.06), 0.238, black, rubber)
		tube("Chrome stanchion", middle, top:Lerp(axle, 0.87), 0.143, chrome, metal)
		tube("Cast axle leg", top:Lerp(axle, 0.71), axle, 0.193, graphite, metal)
		tube("Axle collar", axle, axle + V(s * 0.078, 0, 0), 0.215, alloy, metal)
		box("Fork guard", V(0.151, 0.51, 0.045), top:Lerp(axle, 0.81) - V(0, 0, 0.105),
			blue, plastic, CFrame.Angles(math.rad(25), 0, 0))
		box("Guard accent", V(0.092, 0.104, 0.012), top:Lerp(axle, 0.76) - V(0, 0, 0.13),
			ice, plastic, CFrame.Angles(math.rad(25), 0, 0))
	end
	box("Lower triple clamp", V(0.865, 0.137, 0.262), V(0, 0.020, -0.135), graphite, metal)
	box("Upper triple clamp", V(0.865, 0.118, 0.222), V(0, 0.627, 0.13), graphite, metal)

	-- Fender corners remain forward of the static tire and above its compression envelope.
	panel("Front fender upper", {V(-0.19, -0.005, 0.09), V(0.19, -0.005, 0.09),
		V(0.274, -0.005, -0.58), V(0.22, -0.005, -1.31), V(0.12, -0.005, -1.77),
		V(-0.12, -0.005, -1.77), V(-0.22, -0.005, -1.31), V(-0.274, -0.005, -0.58)}, 0.080, blue, plastic)
	for _, s in ipairs({-1, 1}) do
		panel("Fender flange", {V(s * 0.267, -0.01, -0.60), V(s * 0.22, -0.01, -1.31),
			V(s * 0.12, -0.01, -1.77), V(s * 0.21, -0.117, -1.27), V(s * 0.261, -0.087, -0.62)}, 0.037, graphite, plastic)
	end
	local function mask(name, points, front, depth, color, material)
		local vertices = {}
		for _, p in ipairs(points) do table.insert(vertices, V(p[1], p[2], front + p[2] * 0.35)) end
		panel(name, vertices, depth, color, material)
	end
	mask("Headlight back shell", {{-.22,.10},{.22,.10},{.37,.38},{.40,.71},{.27,.84},{-.27,.84},{-.40,.71},{-.37,.38}},
		-0.391, 0.13, black, plastic)
	mask("Number plate mask", {{-.19,.13},{.19,.13},{.34,.40},{.36,.70},{.25,.81},{-.25,.81},{-.36,.70},{-.34,.40}},
		-0.482, 0.066, blue, plastic)
	mask("White face insert", {{-.247,.45},{.247,.45},{.288,.71},{.21,.77},{-.21,.77},{-.288,.71}},
		-0.529, 0.025, white, plastic)
	mask("Black lens gasket", {{-.17,.17},{.17,.17},{.288,.39},{.255,.49},{-.255,.49},{-.288,.39}},
		-0.529, 0.042, black, rubber)
	mask("Angular headlight lens", {{-.146,.194},{.146,.194},{.251,.386},{.218,.458},{-.218,.458},{-.251,.386}},
		-0.564, 0.032, rgb(180, 205, 221), Enum.Material.Glass)
	for _, s in ipairs({-1, 1}) do
		mask("Lens reflector", {{s*.023,.252},{s*.12,.252},{s*.197,.389},{s*.023,.389}},
			-0.587, 0.010, white, metal)
		mask("Mask slash", {{s*.306,.458},{s*.33,.50},{s*.333,.675},{s*.279,.611}},
			-0.535, 0.014, ice, plastic)
	end
end

local pending = {}
local function build(name, geometry)
	local old = assert(parts:FindFirstChild(name), "Missing part " .. name)
	shell = Instance.new("Part")
	shell.Name = name
	shell.Size = old.Size
	shell.CFrame = old.CFrame
	shell.PivotOffset = old.PivotOffset
	shell.Anchored = old.Anchored
	shell.CanCollide = old.CanCollide
	shell.CanQuery = old.CanQuery
	shell.CanTouch = old.CanTouch
	shell.Transparency = 1
	shell.CastShadow = false
	for key, value in pairs(old:GetAttributes()) do shell:SetAttribute(key, value) end
	shell:SetAttribute("SM50FrontEndVersion", 1)
	for _, child in old:GetChildren() do
		if child:IsA("Attachment") then child:Clone().Parent = shell end
	end
	origin = shell:GetPivot()
	geometry()
	table.insert(pending, {old = old, new = shell})
end

build("Part_handlebar_std", cockpit)
build("Part_fork_std", frontFork)
for _, replacement in ipairs(pending) do
	replacement.new.Parent = parts
	replacement.old:Destroy()
end

return "Installed the SM50 cockpit and front fork"
