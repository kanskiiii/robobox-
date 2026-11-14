-- Build the west practice loop and roadside scenery in Studio Edit mode.
local map = assert(workspace:FindFirstChild("Map"))
local yard = assert(map:FindFirstChild("Yard"))
local ground = assert(map:FindFirstChild("Ground"))
local road = assert(map:FindFirstChild("Road"))
assert(yard.CFrame.RightVector:Dot(Vector3.xAxis) > .999 and road.CFrame.RightVector:Dot(Vector3.xAxis) > .999,
	"This layout expects the existing SM50 yard and main road axes")
local pack = Instance.new("Model")
pack.Name = "WestPracticeLoop"
pack:SetAttribute("TwoStrokeMapVersion", 1)
local yGround = ground.Position.Y + ground.Size.Y / 2
local top = yard.Position.Y + yard.Size.Y / 2
local V, rgb = Vector3.new, Color3.fromRGB
local asphalt, shoulder = rgb(51,54,56), rgb(112,108,94)
local white, yellow = rgb(230,230,217), rgb(231,170,54)
local painted, steel = Enum.Material.SmoothPlastic, Enum.Material.Metal

local function part(parent, name, size, cf, color, material, solid, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material
	p.Anchored = true
	p.CanCollide = solid
	p.CanQuery = solid
	p.CanTouch = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function group(name)
	local item = Instance.new("Model")
	item.Name = name
	item.Parent = pack
	return item
end

-- Long straight for braking practice, with broad 34-stud-radius turns.
local startX = yard.Position.X - yard.Size.X / 2
local east, west = startX - 69, startX - 176
local topZ = yard.Position.Z - 7
local radius = 34
local centerZ = topZ - radius
local southZ = topZ - 2 * radius
local width = 15
local paving = group("Paving")
local markings = group("Painted markings")

local function strip(parent, name, a, b, widthStuds, surface, depth, color, mat, solid, overlap)
	local center = (a + b) / 2
	local cf = CFrame.lookAlong(V(center.X, surface - depth/2, center.Z), (b-a).Unit)
	return part(parent, name, V(widthStuds, depth, (a-b).Magnitude + overlap), cf, color, mat, solid)
end
local function point(x, z) return V(x,0,z) end

local function outline(x, i, sign)
	local angle = math.pi * i / 16
	return point(x + sign * radius * math.sin(angle), centerZ + radius * math.cos(angle))
end
local route = {point(west, topZ), point(east, topZ)}
for i = 1, 16 do table.insert(route, outline(east, i, 1)) end
table.insert(route, point(west, southZ))
for i = 15, 0, -1 do table.insert(route, outline(west, i, -1)) end

for i = 1, #route - 1 do
	local a,b = route[i],route[i+1]
	strip(paving, "Packed gravel shoulder", a,b,width+5,top-.095,.24,shoulder,Enum.Material.Pebble,true,3.6)
	strip(paving, "Practice asphalt", a,b,width,top,.24,asphalt,Enum.Material.Asphalt,true,2.75)
	if (b-a).Magnitude < 30 then
		for _, sign in ipairs({-1,1}) do
			local offset = (b-a).Unit:Cross(Vector3.yAxis) * (sign * (width/2-.75))
			strip(markings,"Turn edge",a+offset,b+offset,.17,top+.025,.024,white,painted,false,0)
		end
	end
end

-- Connect to the yard through the grass. Wide paved spur stays clear of the fuel pump and spawn.
local linkZ = topZ + 18
local link = {point(startX,linkZ),point(east+6,linkZ),point(east-8,topZ+9),point(east-15,topZ)}
for i=1,#link-1 do
	strip(paving,"Yard access shoulder",link[i],link[i+1],17,top-.095,.24,shoulder,Enum.Material.Pebble,true,3.5)
	strip(paving,"Yard access",link[i],link[i+1],12,top,.24,asphalt,Enum.Material.Asphalt,true,2.7)
end

for _, z in ipairs({topZ,southZ}) do
	for _, sign in ipairs({-1,1}) do
		local off = z + sign * (width/2-.75)
		if z == topZ and sign == 1 then
			strip(markings,"Straight edge",point(west,off),point(east-27,off),.17,top+.025,.024,white,painted,false,0)
		else
			strip(markings,"Straight edge",point(west,off),point(east,off),.17,top+.025,.024,white,painted,false,0)
		end
	end
end
for i=0,7 do
	local x=west+12+i*12
	if i<6 then strip(markings,"Brake zone dash",point(x,southZ),point(x+5,southZ),.25,top+.025,.024,yellow,painted,false,0) end
	for _,z in ipairs({southZ-5.7,southZ+5.7}) do
		part(markings,"Brake zone marker",V(.31,.022,2.0),CFrame.new(x,top+.014,z),yellow,painted,false)
	end
end
for col=0,1 do
	for row=0,11 do
		if (col+row)%2==0 then
			part(markings,"Start checker",V(.61,.018,.99),CFrame.new(west+41+col*.62,top+.011,topZ+(row-5.5)),white,painted,false)
		end
	end
end

local facilities=group("Practice facilities")
local function sign(name, caption, detail, position, cf, w)
	local base = cf + position
	for _, dx in ipairs({-w*.37,w*.37}) do
		part(facilities,"Galvanized post",V(.20,5.0,.20),base*CFrame.new(dx,2.5,0),rgb(99,108,113),steel,true)
	end
	local panel = part(facilities,name,V(w,2.36,.22),base*CFrame.new(0,4.43,0),rgb(35,67,77),painted,true)
	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Front
	gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize=Vector2.new(640,210)
	gui.LightInfluence=.35
	gui.Parent=panel
	for i, msg in ipairs({caption,detail}) do
		local text=Instance.new("TextLabel")
		text.BackgroundTransparency=1
		text.Size=UDim2.fromScale(.91,if i==1 then .52 else .23)
		text.Position=UDim2.fromScale(.045,if i==1 then .12 else .66)
		text.Text=msg
		text.TextScaled=true
		text.TextColor3=if i==1 then white else rgb(239,191,104)
		text.Font=if i==1 then Enum.Font.GothamBold else Enum.Font.GothamMedium
		text.Parent=gui
	end
end
sign("Yard entrance sign","PRACTICE LOOP","WEST  /  BRAKING & CORNERING",V(startX-3,yGround,linkZ+8.5),CFrame.Angles(0,-math.pi/2,0),9)
sign("Braking instruction board","BRAKE ZONE","BUILD SPEED  /  BRAKE BETWEEN THE MARKERS",V(west+54,yGround,southZ-11),CFrame.Angles(0,math.pi,0),12)

local function cone(x,z)
	local cf=CFrame.new(x,top,z)
	part(facilities,"Cone foot",V(.93,.12,.93),cf*CFrame.new(0,.06,0),rgb(46,46,47),Enum.Material.Rubber,false)
	for _, section in ipairs({{.64,.20,.21,false},{.53,.24,.43,true},{.38,.26,.68,false},{.24,.26,.94,false}}) do
		part(facilities,"Traffic cone",V(section[2],section[1],section[1]),cf*CFrame.new(0,section[3],0)*CFrame.Angles(0,0,math.pi/2),
			if section[4] then white else rgb(226,102,36),painted,false,Enum.PartType.Cylinder)
	end
end
for i=0,7 do cone(west+12+i*12,southZ-6.6) end
for _, x in ipairs({startX-11,startX-23,east+14}) do cone(x,linkZ+5.7) end

local vegetation=group("Gravel banks and trees")
local random=Random.new(44183)
local leafColors={rgb(53,83,48),rgb(66,96,54),rgb(77,106,62)}
local function tree(x,z)
	local h=random:NextNumber(8.7,13.8)
	local trunkCF=CFrame.new(x,yGround+h*.34,z)*CFrame.Angles(0,0,math.pi/2)
	part(vegetation,"Pine trunk",V(h*.68,.57,.57),trunkCF,rgb(91,70,53),Enum.Material.Wood,true,Enum.PartType.Cylinder)
	for i=1,3 do
		local w=(4-i*.63)*h/11
		local c=leafColors[(i+math.floor(x))%#leafColors+1]
		part(vegetation,"Pine crown",V(w*2,h*.34,w*1.85),CFrame.new(x,yGround+h*(.49+i*.13),z),c,Enum.Material.LeafyGrass,false,Enum.PartType.Ball)
	end
end
for i=0,14 do tree(west-28+i*11.7+random:NextNumber(-3,3),southZ-22+random:NextNumber(-5,5)) end
for i=0,9 do tree(west-radius-18+random:NextNumber(-5,5),southZ-2+i*8.5) end
for i=0,11 do tree(west+i*9.4+random:NextNumber(-3,3),topZ+34+random:NextNumber(-4,4)) end
for i=0,8 do tree(west+13+i*10,centerZ+random:NextNumber(-5,5)) end

local service=group("Roadside shelter")
local shelterX, shelterZ = startX-49, road.Position.Z+road.Size.Z/2+6
local base=CFrame.new(shelterX,yGround,shelterZ)
part(service,"Concrete pad",V(14,.26,6.8),base*CFrame.new(0,.10,0),rgb(133,131,122),Enum.Material.Concrete,true)
for _, x in ipairs({-5.9,5.9}) do
	for _, z in ipairs({-2.15,2.15}) do
		part(service,"Shelter post",V(.29,6.1,.29),base*CFrame.new(x,3.16,z),rgb(61,77,78),steel,true)
	end
end
local shade=part(service,"Shelter roof",V(13.1,.24,5.8),base*CFrame.new(0,6.27,0)*CFrame.Angles(math.rad(-4),0,0),rgb(44,64,67),steel,true)
for i=-5,5 do
	part(service,"Roof seam",V(.065,.075,5.68),shade.CFrame*CFrame.new(i*1.08,.143,0),rgb(79,97,97),steel,false)
end
part(service,"Back windbreak",V(11.65,4.85,.17),base*CFrame.new(0,3.05,2.14),rgb(138,153,146),Enum.Material.Glass,true).Transparency=.29
for _, x in ipairs({-3.7,3.7}) do
	part(service,"Bench legs",V(.18,1.38,1),base*CFrame.new(x,.92,1),rgb(55,63,63),steel,true)
end
for i=0,3 do
	part(service,"Wood bench slat",V(9.35,.14,.29),base*CFrame.new(0,1.59,.52+i*.33),rgb(114,82,55),Enum.Material.Wood,true)
end
sign("Road shelter stop","WEST ROAD","PRACTICE LOOP  /  GARAGE",V(shelterX-11,yGround,shelterZ),CFrame.identity,5.8)

local previous=map:FindFirstChild(pack.Name)
assert(not previous or previous:GetAttribute("TwoStrokeMapVersion"),"An unrelated map model has the same name")
if previous then previous:Destroy() end
pack.Parent=map
return string.format("Installed west practice loop and road shelter with %d instances",#pack:GetDescendants())
