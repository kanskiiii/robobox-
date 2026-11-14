-- Extend SouthTown and keep only the garage Verity. Studio Edit mode.
local map = workspace.Map
assert(map:FindFirstChild("SouthTown"), "Install SouthTown first")
local props = assert(map:FindFirstChild("VerityDecorations"))
local garageVerity = assert(props:FindFirstChild("Garage Verity"))
local city = Instance.new("Model")
city.Name = "SouthCity"
city:SetAttribute("TwoStrokeMapVersion", 1)
local previous = map:FindFirstChild(city.Name)
assert(not previous or previous:GetAttribute("TwoStrokeMapVersion"))
local V, rgb, M = Vector3.new, Color3.fromRGB, Enum.Material
local baseY = map.Ground.Position.Y + map.Ground.Size.Y / 2
local roadY = map.Road.Position.Y + map.Road.Size.Y / 2
local asphalt, curb, mark = rgb(57,59,61), rgb(167,162,151), rgb(229,227,212)

local function group(parent,name)
	local m=Instance.new("Model")
	m.Name,m.Parent=name,parent
	return m
end
local function part(parent,name,size,cf,color,material,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material=name,size,cf,color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local streets=group(city,"Streets")
local paint=group(city,"Lane markings")
local function slab(name,x1,x2,z1,z2,pavement)
	return part(streets,name,V(x2-x1,.24,z2-z1),CFrame.new((x1+x2)/2,roadY-.12+(pavement and .15 or 0),(z1+z2)/2),
		pavement and curb or asphalt,pavement and M.Pavement or M.Asphalt,true)
end
local function stripe(x,z,w,d)
	part(paint,"Road paint",V(w,.013,d),CFrame.new(x,roadY+.012,z),mark,M.SmoothPlastic,false).CastShadow=false
end

local avenues={302,414,526}
local cross={-82,-174,-280,-386}
for _,x in avenues do
	slab("City avenue",x-10,x+10,-396,-81,false)
	for i=1,#cross-1 do
		local north,south=cross[i],cross[i+1]
		slab("Avenue sidewalk",x-14,x-10,south+10,north-10,true)
		slab("Avenue sidewalk",x+10,x+14,south+10,north-10,true)
		for z=south+20,north-20,12 do stripe(x,z,.18,4.5) end
		if i~=1 then
			for j=-3,3 do stripe(x+j*2.3,north-14,1.25,3.1) end
		end
	end
end
for i=2,#cross do
	local z=cross[i]
	slab("Cross street",292,536,z-10,z+10,false)
	for j=1,#avenues-1 do
		local a,b=avenues[j],avenues[j+1]
		slab("Cross-street sidewalk",a+10,b-10,z-14,z-10,true)
		slab("Cross-street sidewalk",a+10,b-10,z+10,z+14,true)
		for x=a+21,b-21,12 do stripe(x,z,4.5,.18) end
		for k=-3,3 do stripe(a+14,z+k*2.3,3.1,1.25) end
	end
end

local buildings=group(city,"Apartments and shops")
local facadeColors={
	rgb(191,181,161),rgb(168,175,168),rgb(181,158,138),rgb(152,166,175),rgb(198,194,178),
}
local glass, frame, brick = rgb(88,118,131),rgb(57,64,68),rgb(133,91,75)
local storeNames={"PIEKARNIA","SKLEP","KAWIARNIA","ROWERY","APTEKA","MARKET"}
local function sign(parent,cf,w,label,color)
	local board=part(parent,"Shop fascia",V(w,1.15,.18),cf,color,M.Metal,false)
	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Front
	gui.CanvasSize=Vector2.new(450,70)
	gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.LightInfluence=.45
	gui.Parent=board
	local text=Instance.new("TextLabel")
	text.Size=UDim2.fromScale(1,1)
	text.Text=label
	text.TextColor3=mark
	text.Font=Enum.Font.GothamBold
	text.BackgroundTransparency=1
	text.TextScaled=true
	text.Parent=gui
end
local function block(index,x,z,facing,floors,retail)
	local name=retail and storeNames[(index-1)%#storeNames+1] or ("Apartments %02d"):format(index)
	local m=group(buildings,name)
	local width,depth=22+(index%3)*2,17+(index%2)*2
	local height=floors*5.3
	local shell=facadeColors[(index-1)%#facadeColors+1]
	local base=CFrame.new(x,baseY,z)*CFrame.Angles(0,facing,0)
	local function build(n,s,c,col,mat,solid)
		return part(m,n,s,base*c,col,mat,solid)
	end
	build("Masonry shell",V(width,height,depth),CFrame.new(0,height/2,0),shell,M.Plaster,true)
	build("Stone plinth",V(width+.24,.62,depth+.22),CFrame.new(0,.31,0),rgb(109,107,101),M.Concrete,true)
	build("Roof cornice",V(width+.8,.4,depth+.8),CFrame.new(0,height+.13,0),rgb(111,110,103),M.Concrete,true)
	build("Recessed roof cap",V(width-.7,.23,depth-.7),CFrame.new(0,height+.37,0),frame,M.Slate,true)
	build("Roof access",V(4,1.5,3),CFrame.new(width*.25,height+1.1,1),brick,M.Brick,true)
	for _,side in {-1,1} do
		build("Brick corner pier",V(.63,height,.21),CFrame.new(side*(width/2-.37),height/2,-depth/2-.08),brick,M.Brick,false)
	end
	for level=1,floors-1 do
		local y=level*5.3+2.53
		for column=-2,2 do
			local f=CFrame.new(column*width*.17,y,-depth/2-.08)
			build("Window surround",V(2.65,2.5,.15),f,frame,M.Metal,false)
			local tint=(index+column+level)%5==0 and rgb(158,154,131) or glass
			build("Window glazing",V(2.37,2.2,.04),f*CFrame.new(0,0,-.085),tint,M.Glass,false)
			build("Window sill",V(2.8,.16,.41),f*CFrame.new(0,-1.29,-.10),mark,M.Concrete,false)
		end
	end
	build("Entrance frame",V(2.7,4.3,.28),CFrame.new(0,2.2,-depth/2-.13),frame,M.Metal,false)
	build("Entrance glass",V(2.25,3.9,.06),CFrame.new(0,2.1,-depth/2-.29),glass,M.Glass,false)
	for _,side in {-1,1} do
		local f=CFrame.new(side*width*.25,2.36,-depth/2-.12)
		build("Ground floor surround",V(retail and 6.7 or 3.6,3.5,.22),f,frame,M.Metal,false)
		build("Ground floor glass",V(retail and 6.2 or 3.23,3.12,.04),f*CFrame.new(0,0,-.128),glass,M.Glass,false)
	end
	if retail then
		sign(m,base*CFrame.new(0,4.85,-depth/2-.26),width*.84,name,rgb(54,78,77))
		build("Shop awning",V(width*.91,.17,2.2),CFrame.new(0,4.03,-depth/2-1.17)*CFrame.Angles(-.12,0,0),rgb(88,102,96),M.Fabric,false)
	end
end

local index=0
for i=2,#cross do
	local z=cross[i]
	for _,x in {327,358,389,439,470,501} do
		for _,side in {-1,1} do
			-- Reserve two lots for the square and avoid the existing houses north of the first street.
			local squareLot=i==3 and side==1 and (x==439 or x==470)
			if not squareLot then
				index+=1
				block(index,x,z+side*27,side==1 and 0 or math.pi,2+(index*7+i)%4,side==1 and (i==3 or index%4==0))
			end
		end
	end
end

local square=group(city,"Market square")
part(square,"Stone plaza",V(60,.20,26),CFrame.new(454,baseY+.10,-253),rgb(159,151,139),M.Cobblestone,true)
for _,x in {433,475} do
	for _,z in {-260,-246} do
		part(square,"Tree planter",V(5.8,.65,5.8),CFrame.new(x,baseY+.36,z),curb,M.Concrete,true)
		part(square,"Tree trunk",V(.66,6,.66),CFrame.new(x,baseY+3.4,z),rgb(100,76,54),M.Wood,true)
		local crown=part(square,"Tree crown",V(6.8,5.7,6.2),CFrame.new(x,baseY+7.2,z),rgb(68,101,65),M.LeafyGrass,false)
		crown.Shape=Enum.PartType.Ball
	end
end
for _,x in {445,463} do
	part(square,"Bench seat",V(6,.22,1.38),CFrame.new(x,baseY+1.1,-250),rgb(113,75,50),M.WoodPlanks,true)
	for _,dx in {-2,2} do
		part(square,"Bench legs",V(.24,1,.8),CFrame.new(x+dx,baseY+.54,-250),frame,M.Metal,true)
	end
end

local lights=group(city,"Streetlights")
for i=2,#cross do
	for _,x in {343,385,458,498} do
		local z=cross[i]+12.6
		part(lights,"Street pole",V(.23,10.5,.23),CFrame.new(x,baseY+5.25,z),frame,M.Metal,true)
		part(lights,"Streetlight arm",V(.18,.17,2.55),CFrame.new(x,baseY+10.39,z-1.22),frame,M.Metal,false)
		local lens=part(lights,"Streetlight lens",V(.75,.12,.48),CFrame.new(x,baseY+10.30,z-2.36),mark,M.Glass,false)
		local light=Instance.new("SpotLight")
		light.Face,light.Angle,light.Range,light.Brightness=Enum.NormalId.Bottom,105,27,1.7
		light.Parent=lens
	end
end

for _, child in props:GetChildren() do
	if child~=garageVerity and child:IsA("Model") and child:FindFirstChild("Yellow sphere") then child:Destroy() end
end
if previous then previous:Destroy() end
city.Parent=map
return ("Built %d city buildings. Kept %s."):format(index,garageVerity.Name)
