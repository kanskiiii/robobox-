-- Open the Greater City central station to pedestrians. Run in Studio Edit.
local map=workspace.Map
local approach=assert(map["Greater City"]:FindFirstChild("Central station approach"))
local station=assert(approach:FindFirstChild("DWORZEC CENTRALNY"))
local shell=assert(station:FindFirstChild("Facade"))
local floor=assert(station:FindFirstChild("Stone base"))
local forecourt=assert(approach:FindFirstChild("Station forecourt"))
local shellCFrame, size=shell.CFrame,shell.Size
local width, depth, height=size.X,size.Z,size.Y
local floorY=floor.Position.Y+floor.Size.Y/2
local plazaY=forecourt.Position.Y+forecourt.Size.Y/2
local V,rgb,M=Vector3.new,Color3.fromRGB,Enum.Material
local oak,steel,linen=rgb(119,88,64),rgb(52,67,72),rgb(227,218,190)
local accent=rgb(34,89,93)
local work=Instance.new("Model")
work.Name="Station concourse"
work:SetAttribute("TwoStrokeStationVersion",1)
local old=station:FindFirstChild(work.Name)
assert(not old or old:GetAttribute("TwoStrokeStationVersion"))
local origin=CFrame.new(shellCFrame.X,floorY,shellCFrame.Z)*shellCFrame.Rotation

local function p(name,w,h,d,x,y,z,col,mat,solid,rotation)
	local q=Instance.new("Part")
	q.Name,q.Size,q.CFrame=name,V(w,h,d),origin*CFrame.new(x,y,z)*(rotation or CFrame.identity)
	q.Color,q.Material=col,mat
	q.Anchored,q.CanCollide,q.CanQuery,q.CanTouch=true,solid,solid,false
	q.TopSurface,q.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	q.Parent=work
	return q
end

local half=depth/2
local wallHeight=height-(floorY-(shell.Position.Y-height/2))
local function wall(name,w,h,d,x,y,z)
	return p(name,w,h,d,x,y,z,shell.Color,M.Plaster,true)
end
local function text(name,caption,x,y,z,w,h,color,angle)
	local b=p(name,w,h,.13,x,y,z,color,M.Metal,false,angle)
	local g=Instance.new("SurfaceGui")
	g.Face,g.SizingMode,g.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(480,math.round(480*h/w))
	g.LightInfluence=.35
	g.Parent=b
	local t=Instance.new("TextLabel")
	t.Size,t.BackgroundTransparency=UDim2.fromScale(.94,1),1
	t.Position=UDim2.fromScale(.03,0)
	t.Text,t.TextColor3,t.TextScaled,t.Font=caption,linen,true,Enum.Font.GothamBold
	t.Parent=g
end
for _,x in {-width/2+.35,width/2-.35} do wall("Side wall",.7,wallHeight,depth,x,wallHeight/2,0) end
wall("Rear wall",width,wallHeight,.65,0,wallHeight/2,half-.32)
local front=-half+.31
local door=8.4
for _,side in {-1,1} do
	local at=side*(door/2+width/2)/2
	local span=(width-door)/2
	wall("Front sill wall",span,1.33,.65,at,.665,front)
	wall("Front clerestory wall",span,wallHeight-4.35,.65,at,(wallHeight+4.35)/2,front)
	for _,offset in {-span/2+.25,-span/6,span/6,span/2-.25} do
		p("Station window jamb",.45,3.05,.64,at+offset,2.84,front,steel,M.Metal,true)
	end
	local pane=p("Station window",span-.5,3.02,.18,at,2.84,front, rgb(109,143,150), M.Glass,true)
	pane.Transparency=.50
end
wall("Door header",door,wallHeight-6.3,.65,0,(wallHeight+6.3)/2,front)
for _,x in {-door/2,door/2} do
	p("Entry column",.36,6.26,.7,x,3.13,front-.16,steel,M.Metal,true)
end
p("Concourse ceiling",width-1,.26,depth-1,0,wallHeight-.12,0,linen,M.Plaster,true)
-- Match the plaza to the plinth with a gradual pedestrian ramp.
local near=-half-.10
local far=-half-3.9
local rise=floorY-plazaY
local slope=math.atan(rise/(near-far))
p("Entry ramp",8,.22,(near-far)/math.cos(slope),0,(-rise)/2-.11/math.cos(slope),(near+far)/2,steel,M.Pavement,true,CFrame.Angles(-slope,0,0))
p("Entry landing",8,.20,.66,0,-.10,-half-.10,linen,M.Concrete,true)
for _,x in {-3.8,3.8} do
	p("Ramp edge",.08,.03,3.64,x,-rise/2-.003,(near+far)/2,linen,M.SmoothPlastic,false,CFrame.Angles(-slope,0,0))
end

p("Ticket counter",11,1.82,2.25,-17,.91,4,accent,M.WoodPlanks,true)
p("Counter top",11.36,.16,2.60,-17,1.90,4,oak,M.Wood,true)
p("Ticket counter backing",12.4,4.65,.5,-17,2.32,6.1,steel,M.Metal,true)
text("Ticket counter sign","KASY  /  TICKETS",-17,4.07,5.80,10.8,.65,accent)
text("Waiting room sign","POCZEKALNIA  /  WAITING AREA",15,4.06,12.96,15,.73,accent)
for _,z in {4.8,9.5} do
	for _,x in {9,17} do
		p("Waiting bench seat",6,.19,1.3,x,.89,z,oak,M.WoodPlanks,true)
		p("Waiting bench back",6,1.05,.17,x,1.46,z+.57,oak,M.WoodPlanks,true)
		for _,side in {-1,1} do p("Bench support",.19,.89,.9,x+side*2.2,.445,z,steel,M.Metal,true) end
	end
end
for _,x in {-17,0,17} do
	for _,z in {-6,6} do
		local fixture=p("Concourse light",4.1,.15,.52,x,wallHeight-.32,z,linen,M.Glass,false)
		local l=Instance.new("SurfaceLight")
		l.Face,l.Angle,l.Range,l.Brightness=Enum.NormalId.Bottom,105,15,1.5
		l.Color=rgb(255,227,187)
		l.Parent=fixture
	end
end

-- Preserve the turnout sightline and pedestrian path through the center of the plaza.
for i=0,4 do
	local q=p("Motorcycle bay stripe",.09,.017,5.3,10+i*3.25,plazaY-floorY+.008,-24,linen,M.SmoothPlastic,false)
	q.CastShadow=false
end
p("Motorcycle bay back line",13,.017,.09,16.5,plazaY-floorY+.008,-21.4,linen,M.SmoothPlastic,false)
p("Parking sign post",.15,3.5,.15,17,plazaY-floorY+1.75,-20.7,steel,M.Metal,true)
text("Parking sign","P  MOTOCYKLE",17,plazaY-floorY+3.2,-20.80,4.2,.82,accent)
text("Facade identifier","DWORZEC CENTRALNY",0,7.15,-half-.37,29,1.35,accent)

if old then old:Destroy() end
shell.Transparency=1
shell.CanCollide,shell.CanQuery,shell.CanTouch=false,false,false
for _,item in station:GetChildren() do
	if item.Name=="Door frame" or item.Name=="Door glass" or item.Name=="Entry step"
		or item.Name=="Ground-floor glazing" or (item.Name=="Building sign" and item.Position.Y<floorY+5) then
		item.Transparency=1
		item.CanCollide,item.CanQuery,item.CanTouch=false,false,false
		for _,g in item:GetChildren() do if g:IsA("SurfaceGui") then g.Enabled=false end end
	end
end
work.Parent=station
return "Opened the central station with a walkable concourse, ticket counter and four motorcycle bays."
