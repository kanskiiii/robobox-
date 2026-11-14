-- Repair the rural roofs and add two connected residential blocks. Run in Studio Edit.
local map = assert(workspace:FindFirstChild("Map"))
local road, ground = map.Road, map.Ground
local groundY = ground.Position.Y + ground.Size.Y/2
local roadY = road.Position.Y + road.Size.Y/2
local approach = road.Position.Z-road.Size.Z/2
local model = Instance.new("Model")
model.Name = "SouthTown"
model:SetAttribute("TwoStrokeMapVersion",1)
local V, rgb, M = Vector3.new, Color3.fromRGB, Enum.Material
local asphalt, concrete = rgb(52,54,57), rgb(170,164,153)
local cream, trim = rgb(219,213,197), rgb(58,62,66)

local function section(parent,name)
	local item=Instance.new("Model")
	item.Name=name
	item.Parent=parent
	return item
end
local function part(parent,name,size,cf,color,material,collision,class)
	local p=Instance.new(class or "Part")
	p.Name,p.Size,p.CFrame=name,size,cf
	p.Color,p.Material=color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,collision,collision,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function roof(parent,base,w,d,eave,pitch,color)
	local half=d/2
	local rise=half*math.tan(pitch)
	local run=half+.61
	for _,side in {-1,1} do
		local rotation=CFrame.Angles(side*pitch,0,0)
		local cf=base*CFrame.new(0,eave+rise-run*math.tan(pitch)/2,side*run/2)*rotation
		part(parent,"Sloped roof",V(w+1.22,.20,run/math.cos(pitch)),cf,color,M.RoofShingles,true)
		part(parent,"Metal gutter",V(w+1.27,.11,.13),base*CFrame.new(0,eave-.32,side*(run+.035)),trim,M.Metal,false)
		-- Wedge high edge faces the ridge; two solid halves close the space above the walls.
		local orient=CFrame.Angles(0,side==1 and math.pi or 0,0)
		part(parent,"Gable infill",V(w,rise,half),base*CFrame.new(0,eave+rise/2,side*half/2)*orient,
			parent:GetAttribute("GableColor") or cream,M.Plaster,true,"WedgePart")
	end
	part(parent,"Ridge cap",V(w+1.3,.15,.28),base*CFrame.new(0,eave+rise+.055,0),color,M.Metal,false)
end
local farm=assert(map:FindFirstChild("EastFarmLane"))
local stagedFarm={}
for _,name in {"Farmhouse","Pump shed"} do
	local building=assert(farm:FindFirstChild(name))
	local wall=assert(building:FindFirstChild("Building shell"))
	local shell=Instance.new("Model")
	shell.Name="Gabled roof assembly"
	shell:SetAttribute("GableColor",wall.Color)
	local base=CFrame.new(wall.Position.X,groundY,wall.Position.Z)
	roof(shell,base,wall.Size.X,wall.Size.Z,wall.Position.Y+wall.Size.Y/2-groundY,
		math.rad(name=="Farmhouse" and 32 or 25),name=="Farmhouse" and rgb(113,59,49) or rgb(69,66,61))
	table.insert(stagedFarm,{building,shell})
end

local streets=section(model,"Streets and sidewalks")
local paint=section(model,"Road markings")
local function roadRect(name,x1,x2,z1,z2)
	part(streets,name,V(x2-x1,.24,z2-z1),CFrame.new((x1+x2)/2,roadY-.12,(z1+z2)/2),asphalt,M.Asphalt,true)
end
local function pavement(x1,x2,z1,z2)
	part(streets,"Sidewalk",V(x2-x1,.23,z2-z1),CFrame.new((x1+x2)/2,roadY+.045,(z1+z2)/2),concrete,M.Pavement,true)
end
local function stripe(x,z,w,d,color)
	part(paint,"Road paint",V(w,.014,d),CFrame.new(x,roadY+.011,z),color or cream,M.SmoothPlastic,false)
end
local xWest,xEast=302,526
local half=10
local north,south=20,-82
for _,x in {xWest,xEast} do
	roadRect("Town connection",x-half,x+half,south-half,approach+.1)
	pavement(x-half-4,x-half,south+15,north-15)
	pavement(x+half,x+half+4,south+15,north-15)
	for z=south+19,north-19,12 do stripe(x,z,.22,4) end
	for i=-3,3 do stripe(x+i*2.35,approach-8,1.1,3.0) end
	stripe(x-4.8,approach-3,7.3,.28)
end
for _,z in {north,south} do
	roadRect("Residential street",xWest-half,xEast+half,z-half,z+half)
	for _,side in {-1,1} do
		local a=z+side*half
		local b=a+side*4
		pavement(xWest+14,xEast-14,math.min(a,b),math.max(a,b))
	end
	for x=xWest+21,xEast-21,13 do stripe(x,z,4,.22) end
end
-- One cross street breaks up the blocks; sidewalk runs stop before the junction.
local middle=414
roadRect("Market cross street",middle-8,middle+8,south+10,north-10)
for z=south+19,north-19,12 do stripe(middle,z,.2,4) end
for _,z in {north,south} do
	for _,p in streets:GetChildren() do
		if p.Name=="Sidewalk" and p.Size.X>100 and math.abs(p.Position.Z-z)==12 then
			local a,b=p.Position.X-p.Size.X/2,p.Position.X+p.Size.X/2
			local c,d=p.Position.Z-2,p.Position.Z+2
			p:Destroy()
			pavement(a,middle-8,c,d)
			pavement(middle+8,b,c,d)
		end
	end
end

local buildings=section(model,"Residential blocks")
local pallets={
	{rgb(193,177,149),rgb(120,64,53)}, {rgb(177,191,181),rgb(66,74,78)},
	{rgb(207,183,147),rgb(139,73,55)}, {rgb(189,175,166),rgb(80,67,66)},
}
local function house(i,x,z,facing,storeys)
	local h=section(buildings,("House %02d"):format(i))
	local pair=pallets[(i-1)%#pallets+1]
	local w,d=20+(i%3)*1.5,13+(i%2)*2
	local height=5.3*storeys
	local base=CFrame.new(x,groundY,z)*CFrame.Angles(0,facing,0)
	local foundation=rgb(118,113,103)
	part(h,"Raised stone foundation",V(w+.45,.6,d+.45),base*CFrame.new(0,.30,0),foundation,M.Cobblestone,true)
	part(h,"Plastered walls",V(w,height,d),base*CFrame.new(0,height/2+.48,0),pair[1],M.Plaster,true)
	h:SetAttribute("GableColor",pair[1])
	roof(h,base,w,d,height+.48,math.rad(29+i%4*2.5),pair[2])
	part(h,"Brick chimney",V(1.16,4.1,1.0),base*CFrame.new(w*.27,height+2.4,d*.13),rgb(126,87,72),M.Brick,true)
	part(h,"Chimney coping",V(1.4,.2,1.24),base*CFrame.new(w*.27,height+4.39,d*.13),trim,M.Concrete,false)
	local door=rgb(84,65,49)
	part(h,"Timber front door",V(1.95,3.63,.18),base*CFrame.new(0,2.3,-d/2-.10),door,M.WoodPlanks,false)
	part(h,"Door lintel",V(2.27,.16,.21),base*CFrame.new(0,4.17,-d/2-.12),trim,M.Wood,false)
	part(h,"Front step",V(2.62,.42,.9),base*CFrame.new(0,.21,-d/2-.5),foundation,M.Concrete,true)
	for floor=0,storeys-1 do
		for _,side in {-1,1} do
			local f=base*CFrame.new(w*.29*side,3.1+floor*5.0,-d/2-.09)
			part(h,"Recessed window surround",V(2.45,2.02,.17),f,cream,M.Wood,false)
			part(h,"Window glass",V(2.10,1.7,.06),f*CFrame.new(0,0,-.1),rgb(90,111,120),M.Glass,false)
			part(h,"Window mullion",V(.08,1.72,.11),f*CFrame.new(0,0,-.15),cream,M.Wood,false)
			part(h,"Window sill",V(2.66,.14,.33),f*CFrame.new(0,-1.03,-.12),cream,M.Concrete,false)
		end
	end
	part(h,"Front walkway",V(2.4,.08,7),base*CFrame.new(0,.041,-d/2-4.0),concrete,M.Pavement,false)
end
local id=0
for _,x in {331,364,392,436,467,499} do
	for _,row in {{48,0},{-5,math.pi},{-57,0},{-110,math.pi}} do
		-- Leave the middle street sightlines and the direct approaches open.
		if not ((x==392 or x==436) and row[1]==-57) then
			id+=1
			house(id,x,row[1],row[2],if id%3==0 then 1 else 2)
		end
	end
end

local old=map:FindFirstChild(model.Name)
assert(not old or old:GetAttribute("TwoStrokeMapVersion"),"Unrelated town model already exists")
if old then old:Destroy() end
model.Parent=map
for _,entry in stagedFarm do
	local building, replacement=table.unpack(entry)
	for _,child in building:GetChildren() do
		if child.Name=="Pitched roof" or child.Name=="Ridge cap" or child.Name==replacement.Name then child:Destroy() end
	end
	replacement.Parent=building
end
return ("Installed %d houses and rebuilt both farm roofs"):format(id)
