-- Workshop relocation and West City expansion. Run in Studio Edit mode.
local map = assert(workspace:FindFirstChild("Map"))
local road = assert(map:FindFirstChild("Road"))
local garage = assert(map:FindFirstChild("Garage"))
assert(map:FindFirstChild("SouthCity"))
local yard = assert(map:FindFirstChild("Yard"))
local ground = assert(map:FindFirstChild("Ground"))
local bay = assert(map:FindFirstChild("GarageBay"))
local V, rgb, M = Vector3.new, Color3.fromRGB, Enum.Material
local roadTop = road.Position.Y + road.Size.Y/2
local groundTop = ground.Position.Y + ground.Size.Y/2
local paved = rgb(55,57,60)
local stone = rgb(174,166,152)
local paint = rgb(238,231,206)
local metal = rgb(57,64,68)
local white = rgb(244,235,212)
local offset = V(224,0,-43)-V(bay.Position.X,0,bay.Position.Z)
local expansion = Instance.new("Model")
expansion.Name = "West City and Workshop"
expansion:SetAttribute("TwoStrokeMapVersion", 1)

local function group(name, parent)
	local m=Instance.new("Model")
	m.Name,m.Parent=name,parent or expansion
	return m
end
local function part(parent,name,size,cf,color,mat,solid,class)
	local p=Instance.new(class or "Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material=name,size,cf,color,mat
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local streets = group("West City streets")
local markings = group("West City markings")
local workshop = group("Workshop forecourt")
local buildings = group("West City buildings")
local function slab(parent,name,x1,x2,z1,z2,top,color,mat)
	return part(parent,name,V(x2-x1,.28,z2-z1),CFrame.new((x1+x2)/2,top-.14,(z1+z2)/2),color,mat,true)
end
local function street(name,x1,x2,z1,z2)
	slab(streets,name,x1,x2,z1,z2,roadTop,paved,M.Asphalt)
end
local function walk(x1,x2,z1,z2)
	slab(streets,"Sidewalk",x1,x2,z1,z2,roadTop+.15,stone,M.Pavement)
end
local function stripe(parent,x,z,w,d,top,color)
	local p=part(parent,"Paint marking",V(w,.012,d),CFrame.new(x,top+.007,z),color,M.SmoothPlastic,false)
	p.CastShadow=false
end

-- Connections overlap the existing asphalt by a small amount at each junction.
local avenues={94,180,302}
local rows={-82,-174,-280,-386}
local roadEdge=road.Position.Z-road.Size.Z/2
street("West bypass",84,104,-396,roadEdge+.25)
street("Inner avenue",170,190,-396,-71.85)
for _,z in rows do
	street("West City cross street",83.9,292.25,z-10,z+10)
	for j=1,#avenues-1 do
		local a,b=avenues[j],avenues[j+1]
		for side=-1,1,2 do
			local p,q=z+side*10,z+side*14
			if not (z==-82 and side==1 and a==180) then walk(a+10,b-10,math.min(p,q),math.max(p,q)) end
		end
		for x=a+20,b-20,12 do stripe(markings,x,z,4,.19,roadTop,paint) end
	end
end
for _,x in {94,180} do
	for i=1,#rows-1 do
		local a,b=rows[i+1]+10,rows[i]-10
		walk(x-14,x-10,a,b)
		walk(x+10,x+14,a,b)
		for z=a+8,b-8,13 do stripe(markings,x,z,.18,4,roadTop,paint) end
	end
end

local yardTop=yard.Position.Y+yard.Size.Y/2
local function ramp(name,x1,x2,z1,z2,y1,y2)
	local slope=(y2-y1)/(z2-z1)
	local rise=math.atan(slope)
	local cf=CFrame.new((x1+x2)/2,(y1+y2)/2-.13/math.cos(rise),(z1+z2)/2)*CFrame.Angles(-rise,0,0)
	part(workshop,name,V(x2-x1,.26,(z2-z1)/math.cos(rise)),cf,paved,M.Asphalt,true)
end
ramp("Main road workshop driveway",212,236,42.35,roadEdge+.17,yardTop,roadTop)
-- Link the existing city entrance directly to the east edge of the workshop yard.
slab(workshop,"Side driveway",282.99,292.15,14,26,roadTop,paved,M.Asphalt)
local sideRun=4
local sideAngle=math.atan((roadTop-yardTop)/sideRun)
part(workshop,"Side driveway grade",V(sideRun/math.cos(sideAngle),.24,12),CFrame.new(281,(roadTop+yardTop)/2-.12/math.cos(sideAngle),20)
	*CFrame.Angles(0,0,sideAngle),paved,M.Asphalt,true)
-- Close the garage threshold while keeping the door and tool chest accessible.
slab(workshop,"Concrete entrance apron",216,232,-33.12,-29.2,yardTop,rgb(137,135,127),M.Concrete)
for i=0,4 do stripe(workshop,246+i*4,28,.10,8,yardTop,paint) end
stripe(workshop,254,24,16,.11,yardTop,paint)
for _,x in {208,240} do
	part(workshop,"Workshop light pole",V(.24,10,.24),CFrame.new(x,yardTop+5,-20),metal,M.Metal,true)
	local lens=part(workshop,"Workshop fixture",V(.92,.17,.66),CFrame.new(x,yardTop+10,-20),white,M.Glass,false)
	local light=Instance.new("SpotLight")
	light.Face,light.Angle,light.Range,light.Brightness=Enum.NormalId.Bottom,105,24,1.55
	light.Parent=lens
end
local fascia=part(workshop,"Workshop fascia",V(11,1.1,.16),CFrame.new(224,9.5,-31.95)*CFrame.Angles(0,math.pi,0),rgb(38,62,70),M.Metal,false)
local gui=Instance.new("SurfaceGui")
gui.Face,gui.SizingMode,gui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(660,75)
gui.Parent=fascia
local label=Instance.new("TextLabel")
label.Size,label.BackgroundTransparency=UDim2.fromScale(1,1),1
label.Font,label.TextColor3,label.TextScaled=Enum.Font.GothamBold,white,true
label.Text,label.Parent="TWO-STROKE WORKSHOP",gui

local colors={rgb(192,182,159),rgb(176,184,171),rgb(199,165,143),rgb(171,178,185),rgb(202,194,177)}
local function building(i,x,z,side)
	local m=group(("West block %02d"):format(i),buildings)
	local cf=CFrame.new(x,groundTop,z)*CFrame.Angles(0,side==1 and 0 or math.pi,0)
	local w,d=19+i%3*1.8,16+i%2*2
	local stories=2+i%3
	local h=stories*5.2
	local color=colors[(i-1)%#colors+1]
	local roof= i%2==0 and rgb(102,65,55) or rgb(65,68,73)
	local function detail(name,size,x0,y0,z0,col,mat,solid)
		return part(m,name,size,cf*CFrame.new(x0,y0,z0),col,mat,solid)
	end
	detail("Plastered walls",V(w,h,d),0,h/2,0,color,M.Plaster,true)
	detail("Masonry base",V(w+.15,.6,d+.15),0,.3,0,rgb(106,104,98),M.Concrete,true)
	local pitch=math.rad(26)
	local half=d/2
	local rise=half*math.tan(pitch)
	for _,sgn in {-1,1} do
		local run=half+.53
		part(m,"Roof slope",V(w+1.1,.19,run/math.cos(pitch)),cf*CFrame.new(0,h+rise-run*math.tan(pitch)/2,sgn*run/2)
			*CFrame.Angles(sgn*pitch,0,0),roof,M.RoofShingles,true)
		part(m,"Roof gable",V(w,rise,half),cf*CFrame.new(0,h+rise/2,sgn*half/2)
			*CFrame.Angles(0,sgn==1 and math.pi or 0,0),color,M.Plaster,true,"WedgePart")
	end
	detail("Ridge cap",V(w+1.18,.13,.26),0,h+rise+.06,0,roof,M.Metal,false)
	detail("Entry",V(2.5,3.6,.19),0,1.98,-d/2-.10,metal,M.Metal,false)
	for floor=0,stories-1 do
		for col=-2,2 do
			if floor==0 and col==0 then continue end
			local xx,yy=col*w*.17,2.45+floor*5.2
			detail("Window surround",V(2.32,1.96,.16),xx,yy,-d/2-.06,white,M.Wood,false)
			detail("Window glass",V(1.97,1.58,.06),xx,yy,-d/2-.16,rgb(82,111,127),M.Glass,false)
			detail("Window sill",V(2.46,.13,.30),xx,yy-.99,-d/2-.13,stone,M.Concrete,false)
		end
	end
end

local count=0
for _,z in {-112,-145,-204,-249,-310,-355,-416} do
	for _,x in {119,147,210,241,271} do
		count+=1
		building(count,x,z,(z==-145 or z==-249 or z==-355) and 1 or -1)
	end
end

local old=map:FindFirstChild(expansion.Name)
assert(not old or old:GetAttribute("TwoStrokeMapVersion"))
if offset.Magnitude>.01 then
	local movable={"Garage","GarageBay","Computer","Yard","FuelPump","Prop_fuel_pump","GarageLight","Spawn","DeliverySpot"}
	local items={}
	for _,name in movable do table.insert(items,(assert(map:FindFirstChild(name),name))) end
	local collision=assert(map:FindFirstChild("GarageCollision"))
	local verity=assert(map.VerityDecorations:FindFirstChild("Garage Verity"))
	local display=map:FindFirstChild("Dualtron Stand")
	local apron=yard:Clone()
	apron.Name="Practice Lot Apron"
	apron.Parent=map
	for _,p in items do p:PivotTo(p:GetPivot()+offset) end
	for _,p in collision:GetDescendants() do if p:IsA("BasePart") then p.CFrame+=offset end end
	if display then for _,p in display:GetChildren() do if p:IsA("PVInstance") then p:PivotTo(p:GetPivot()+offset) end end end
	verity:PivotTo(verity:GetPivot()+offset)
end
if old then old:Destroy() end
expansion.Parent=map
return ("Moved the garage and added %d West City buildings"):format(count)
