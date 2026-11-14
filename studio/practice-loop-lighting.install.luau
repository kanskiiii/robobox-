-- Add working light poles to the practice loop without placing obstacles on the pavement.
local map = assert(workspace:FindFirstChild("Map"))
local loop = assert(map:FindFirstChild("WestPracticeLoop"))
local yard, ground = map.Yard, map.Ground
local groundY = ground.Position.Y + ground.Size.Y / 2
local west = yard.Position.X - yard.Size.X / 2 - 176
local north = yard.Position.Z - 7
local rig = Instance.new("Model")
rig.Name = "PracticeLoopLighting"
rig:SetAttribute("TwoStrokeMapVersion", 1)
local v = Vector3.new
local rgb = Color3.fromRGB

local function part(parent, name, size, cf, color, material, solid)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = solid, solid, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function lamp(x, z, facing)
	local model = Instance.new("Model")
	model.Name = "Practice light pole"
	model.Parent = rig
	local cf = CFrame.new(x, groundY, z) * CFrame.Angles(0, facing, 0)
	local iron = rgb(61,68,71)
	local yellow = rgb(214,159,52)
	part(model,"Concrete plinth",v(1.05,.38,1.05),cf*CFrame.new(0,.19,0),rgb(111,109,100),Enum.Material.Concrete,true)
	part(model,"Galvanized pole",v(.28,12,.28),cf*CFrame.new(0,6.25,0),iron,Enum.Material.Metal,true)
	part(model,"Reflective sleeve",v(.31,.47,.31),cf*CFrame.new(0,1.23,0),yellow,Enum.Material.SmoothPlastic,false)
	part(model,"Cantilever",v(.21,.24,2.2),cf*CFrame.new(0,12.22,-1),iron,Enum.Material.Metal,false)
	part(model,"Lamp hood",v(1.02,.27,.73),cf*CFrame.new(0,12.2,-2.06),iron,Enum.Material.Metal,false)
	local lens = part(model,"LED array",v(.77,.07,.55),cf*CFrame.new(0,12.03,-2.06),
		rgb(251,229,181),Enum.Material.Glass,false)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Color = rgb(255,230,188)
	light.Angle = 104
	light.Brightness = 2.45
	light.Range = 32
	light.Shadows = true
	light.Parent = lens
end

lamp(west+158,north+27,0)
lamp(west+92,north+11,0)
lamp(west+17,north+11,0)
lamp(west-44,north-34,-math.pi/2)
lamp(west+30,north-79,math.pi)
lamp(west+89,north-79,math.pi)
lamp(west+151,north-35,math.pi/2)
assert(#loop.Paving:GetChildren() > 0)
local previous = map:FindFirstChild(rig.Name)
assert(not previous or previous:GetAttribute("TwoStrokeMapVersion"), "Unrelated lighting model already uses that name")
if previous then previous:Destroy() end
rig.Parent = map
return "Installed seven practice-loop light poles"
