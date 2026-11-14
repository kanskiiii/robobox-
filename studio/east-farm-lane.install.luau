-- Rural lane east of the sprint, installed in Roblox Studio Edit mode.
local map = assert(workspace:FindFirstChild("Map"))
local road = assert(map:FindFirstChild("Road"))
local ground = assert(map:FindFirstChild("Ground"))
local v, rgb = Vector3.new, Color3.fromRGB
local M = Enum.Material
local groundY = ground.Position.Y + ground.Size.Y / 2
local roadY = road.Position.Y + road.Size.Y / 2
local edge = road.Position.Z + road.Size.Z / 2
local x = road.Position.X + 390
local district = Instance.new("Model")
district.Name = "EastFarmLane"
district:SetAttribute("TwoStrokeMapVersion", 1)

local function model(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = district
	return m
end

local function make(parent, name, size, pose, color, material, collide)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, pose
	p.Color, p.Material = color, material
	p.Anchored = true
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local lane = model("Lane and farm entrances")
local function segment(a, b, width, color, material)
	local mid = (a+b)/2
	local cf = CFrame.lookAlong(v(mid.X,roadY-.115,mid.Z),(b-a).Unit)
	make(lane,"Drivable pavement",v(width,.23,(b-a).Magnitude+2),cf,color,material,true)
end

local route = {
	v(x,0,edge),v(x,0,edge+34),v(x+3,0,edge+49),v(x+12,0,edge+62),
	v(x+27,0,edge+69),v(x+47,0,edge+70),v(x+75,0,edge+70),
}
for i=1,#route-1 do segment(route[i],route[i+1],13,rgb(98,93,83),M.Pebble) end
segment(v(x,0,edge),v(x,0,edge+11),14,rgb(57,59,57),M.Asphalt)
segment(v(x+48,0,edge+70),v(x+48,0,edge+86),14,rgb(107,101,89),M.Pebble)
segment(v(x+8,0,edge+56),v(x+21,0,edge+45),10,rgb(107,101,89),M.Pebble)
for _, sign in ipairs({-1,1}) do
	make(lane,"Delineator",v(.24,2.3,.24),CFrame.new(x+sign*8,roadY+1.15,edge+3),rgb(224,222,210),M.SmoothPlastic,true)
	make(lane,"Red reflector",v(.27,.25,.27),CFrame.new(x+sign*8,roadY+2.1,edge+3),rgb(173,61,43),M.SmoothPlastic,false)
end

local fields = model("Field boundaries")
for _, run in ipairs({{x-47,edge+21,31},{x+22,edge+21,62},{x+82,edge+76,27}}) do
	local start, z, length = table.unpack(run)
	for n=0,math.floor(length/4) do
		make(fields,"Fence post",v(.25,2.35,.27),CFrame.new(start+n*4,groundY+1.175,z),rgb(110,93,70),M.Wood,true)
	end
	for _, y in ipairs({.72,1.45}) do
		make(fields,"Fence rail",v(length,.19,.14),CFrame.new(start+length/2,groundY+y,z),rgb(124,104,76),M.Wood,true)
	end
end
local rng=Random.new(389)
for _, plot in ipairs({{x-27,edge+43,7},{x+32,edge+35,7},{x+80,edge+100,7}}) do
	for row=1,plot[3] do
		local strip=make(fields,"Cultivated furrow",v(2.3,.06,15+rng:NextNumber(-2,4)),
			CFrame.new(plot[1]+3.2*row,groundY+.013,plot[2]),rgb(103,83,54),M.Ground,false)
		strip.CastShadow=false
	end
end

local function building(name, pos, width, depth, height, wall, roof)
	local b=model(name)
	local base=CFrame.new(pos.X,groundY,pos.Z)
	make(b,"Stone foundation",v(width+.4,.49,depth+.4),base*CFrame.new(0,.245,0),rgb(115,106,92),M.Concrete,true)
	make(b,"Building shell",v(width,height,depth),base*CFrame.new(0,height/2+.4,0),wall,M.Brick,true)
	local rise=depth*.29
	for _, side in ipairs({-1,1}) do
		local span=math.sqrt((depth/2+.55)^2+rise^2)
		make(b,"Pitched roof",v(width+1.1,.26,span),base*CFrame.new(0,height+.4+rise/2,side*(depth/4+.25))
			*CFrame.Angles(-side*math.atan(rise/(depth/2+.55)),0,0),roof,M.WoodPlanks,true)
	end
	make(b,"Ridge cap",v(width+1.2,.24,.36),base*CFrame.new(0,height+.42+rise,0),roof,M.Metal,true)
	make(b,"Timber door",v(width*.24,height*.71,.19),base*CFrame.new(0,.4+height*.355,-depth/2-.095),rgb(85,76,60),M.WoodPlanks,false)
	for _, side in ipairs({-1,1}) do
		local cx=side*width*.32
		make(b,"Window frame",v(2.05,1.6,.16),base*CFrame.new(cx,height*.55,-depth/2-.1),rgb(67,71,65),M.Wood,false)
		make(b,"Blue-grey pane",v(1.72,1.25,.035),base*CFrame.new(cx,height*.55,-depth/2-.20),rgb(119,145,153),M.Glass,false)
		make(b,"Window divider",v(.08,1.25,.05),base*CFrame.new(cx,height*.55,-depth/2-.23),rgb(70,75,71),M.Wood,false)
	end
end
building("Farmhouse",v(x+48,0,edge+97),21,11,7.4,rgb(168,151,122),rgb(104,62,51))
building("Pump shed",v(x+23,0,edge+43),11,7,5.7,rgb(142,126,106),rgb(77,75,63))

local wayside=model("Farm lane sign")
local panel=make(wayside,"Farm Lane",v(5.7,.95,.16),CFrame.new(x+10,groundY+3.45,edge+5),rgb(52,69,55),M.SmoothPlastic,true)
make(wayside,"Signpost",v(.2,3.4,.2),CFrame.new(x+10,groundY+1.7,edge+5),rgb(95,99,96),M.Metal,true)
local gui=Instance.new("SurfaceGui")
gui.Face=Enum.NormalId.Front
gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
gui.CanvasSize=Vector2.new(430,70)
gui.Parent=panel
local text=Instance.new("TextLabel")
text.Size=UDim2.fromScale(1,1)
text.BackgroundTransparency=1
text.Text="FARM LANE"
text.TextScaled=true
text.TextColor3=rgb(240,234,211)
text.Font=Enum.Font.GothamBold
text.Parent=gui

local prev=map:FindFirstChild(district.Name)
assert(not prev or prev:GetAttribute("TwoStrokeMapVersion"),"An unrelated model already uses the farm lane name")
if prev then prev:Destroy() end
district.Parent=map
return string.format("Installed the East Farm Lane with %d instances",#district:GetDescendants())
