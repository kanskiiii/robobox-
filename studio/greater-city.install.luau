-- Expand the existing city and replace its old practice track. Run in Roblox Studio Edit.
local map = assert(workspace:FindFirstChild("Map"))
assert(map:FindFirstChild("SouthCity") and map:FindFirstChild("West City and Workshop"))
local road, ground = map.Road, map.Ground
local roadY, groundY = road.Position.Y + road.Size.Y/2, ground.Position.Y + ground.Size.Y/2
local edgeNorth = road.Position.Z + road.Size.Z/2
local edgeSouth = road.Position.Z - road.Size.Z/2
local V, rgb, M = Vector3.new, Color3.fromRGB, Enum.Material
local asphalt, curb, white = rgb(54,56,59), rgb(165,160,151), rgb(232,225,199)
local ink, glass = rgb(57,66,70), rgb(85,121,137)
local metro = Instance.new("Model")
metro.Name = "Greater City"
metro:SetAttribute("TwoStrokeMapVersion", 1)
local old = map:FindFirstChild(metro.Name)
assert(not old or old:GetAttribute("TwoStrokeMapVersion") == 1)

local function group(parent, name)
	local m = Instance.new("Model")
	m.Name, m.Parent = name, parent
	return m
end
local function part(parent,name,size,cf,color,material,solid,class)
	local p=Instance.new(class or "Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material=name,size,cf,color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function slab(parent,name,x1,x2,z1,z2,top,color,material,solid)
	return part(parent,name,V(x2-x1,.23,z2-z1),CFrame.new((x1+x2)/2,top-.115,(z1+z2)/2),color,material,solid)
end
local function mark(parent,x,z,w,d,color)
	local p=part(parent,"Road paint",V(w,.014,d),CFrame.new(x,roadY+.012,z),color or white,M.SmoothPlastic,false)
	p.CastShadow=false
end
local function sign(parent,name,cf,width,height,color)
	local face=part(parent,"Building sign",V(width,height,.15),cf,color,M.Metal,false)
	local gui=Instance.new("SurfaceGui")
	gui.Face,gui.SizingMode,gui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(520,math.round(520*height/width))
	gui.LightInfluence=.35
	gui.Parent=face
	local t=Instance.new("TextLabel")
	t.Text,t.Font,t.TextColor3=name,Enum.Font.GothamBold,white
	t.BackgroundTransparency,t.TextScaled,t.Size=1,true,UDim2.fromScale(1,1)
	t.Parent=gui
end

local h=10
local function grid(name,xs,zs,links,noEastLane)
	local district=group(metro,name)
	local streets=group(district,"Streets")
	local paint=group(district,"Markings")
	local structures=group(district,"Buildings and landmarks")
	local function paving(x1,x2,z1,z2)
		slab(streets,"Asphalt street",x1,x2,z1,z2,roadY,asphalt,M.Asphalt,true)
	end
	local function sidewalk(x1,x2,z1,z2)
		slab(streets,"Sidewalk",x1,x2,z1,z2,roadY+.13,curb,M.Pavement,true)
	end
	for j,x in ipairs(xs) do
		local south,north=zs[1]-h,zs[#zs]+h
		local link=links[x]
		if link and link<south then south=link end
		if link and link>north then north=link end
		if not (noEastLane and j==#xs) then paving(x-h,x+h,south,north) end
		for i=1,#zs-1 do
			local a,b=zs[i]+h,zs[i+1]-h
			sidewalk(x-h-4,x-h,a,b)
			if not(noEastLane and j==#xs) then sidewalk(x+h,x+h+4,a,b) end
			if not(noEastLane and j==#xs) then
				for z=a+9,b-9,15 do mark(paint,x,z,.18,4.5) end
			end
		end
	end
	for _,z in ipairs(zs) do
		local east = xs[#xs]+h
		if noEastLane and z~=-386 then east=xs[#xs]-h+.22 end
		paving(xs[1]-h,east,z-h,z+h)
		for j=1,#xs-1 do
			local a,b=xs[j]+h,xs[j+1]-h
			sidewalk(a,b,z-h-4,z-h)
			sidewalk(a,b,z+h,z+h+4)
			for x=a+12,b-12,15 do mark(paint,x,z,4.5,.18) end
			for k=-3,3 do mark(paint,a-3,z+k*2.2,2.8,1.14) end
		end
	end
	return structures
end

local shades={rgb(188,181,164),rgb(162,176,171),rgb(190,156,137),rgb(159,171,184),rgb(204,190,161)}
local bands={rgb(43,75,86),rgb(95,69,57),rgb(96,110,90),rgb(95,73,96)}
local buildingCount, landmarkCount=0,0
local function building(parent,name,x,z,width,depth,floors,profile,face)
	buildingCount+=1
	local n=buildingCount
	local model=group(parent,name)
	local cf=CFrame.new(x,groundY,z)*CFrame.Angles(0,face or 0,0)
	local brick=shades[(n-1)%#shades+1]
	local trim=bands[(n-1)%#bands+1]
	local height=floors*5.1
	if profile=="industrial" then height=8.8 end
	if profile=="hall" then height=11.2 end
	local function box(tag,w,y,d,px,py,pz,color,mat,solid)
		return part(model,tag,V(w,y,d),cf*CFrame.new(px,py,pz),color,mat,solid)
	end
	box("Stone base",width+.45,.5,depth+.45,0,.25,0,curb,M.Concrete,true)
	box("Facade",width,height,depth,0,height/2,0,brick,profile=="industrial" and M.Brick or M.Plaster,true)
	box("Roof trim",width+.8,.35,depth+.8,0,height+.12,0,trim,M.Metal,true)
	if profile=="rowhouse" or profile=="hall" or profile=="industrial" then
		local a=math.rad(profile=="industrial" and 16 or 29)
		local run=depth/2+.4
		local rise=depth/2*math.tan(a)
		for _,side in {-1,1} do
			part(model,"Pitched roof",V(width+1,.21,run/math.cos(a)),cf*CFrame.new(0,height+rise-run*math.tan(a)/2,side*run/2)
				*CFrame.Angles(side*a,0,0),trim,M.RoofShingles,true)
			part(model,"Gable infill",V(width,rise,depth/2),cf*CFrame.new(0,height+rise/2,side*depth/4)
				*CFrame.Angles(0,side==1 and math.pi or 0,0),brick,M.Plaster,true,"WedgePart")
		end
		box("Ridge cap",width+1.05,.16,.26,0,height+rise+.05,0,trim,M.Metal,false)
	else
		box("Roof stairwell",width*.37,2.1,depth*.38,width*.15,height+1.2,depth*.14,trim,M.Concrete,true)
	end
	local front=-depth/2
	box("Door frame",3.2,3.75,.22,0,1.93,front-.10,ink,M.Metal,false)
	box("Door glass",2.75,3.3,.045,0,1.92,front-.23,glass,M.Glass,false)
	for _,side in {-1,1} do
		box("Entry step",1.4,.22,.7,side*.85,.11,front-.34,curb,M.Concrete,true)
		box("Ground-floor glazing",width*.20,2.7,.16,side*width*.29,2.15,front-.09,glass,M.Glass,false)
	end
	for i=1,floors-1 do
		local y=i*5.1+2.37
		for _,zSide in {-1,1} do
			box("Window ribbon",width*.79,1.7,.13,0,y,zSide*(depth/2+.065),glass,M.Glass,false)
			for j=-2,2 do
				box("Window mullion",.20,1.76,.21,j*width*.145,y,zSide*(depth/2+.115),trim,M.Metal,false)
			end
		end
	end
	if profile=="industrial" then
		box("Delivery shutter",width*.30,5.7,.20,width*.22,2.93,front-.22,ink,M.DiamondPlate,false)
	elseif profile=="tower" then
		box("Corner glazing",.18,height*.72,depth*.33,width/2+.08,height*.57,0,glass,M.Glass,false)
	end
	if not name:match("^Block") then
		landmarkCount+=1
		sign(model,name,cf*CFrame.new(0,4.35,front-.30),math.min(width*.88,30),1.24,trim)
	end
	return model,cf,height
end

local west=grid("Old Town and West Quarter",{-548,-408,-268,-128,94},{-500,-386,-280,-174,-82,34},
	{[-548]=edgeSouth+.25,[-408]=edgeSouth+.25,[-268]=edgeSouth+.25,[-128]=edgeSouth+.25},true)
-- The four existing west-city eastbound streets start west of the avenue center.
-- Close the short join at the southern extension and connect the former track block.
local node=group(metro,"City junction joins")
slab(node,"West bypass extension",84,104,-510,-395.8,roadY,asphalt,M.Asphalt,true)
slab(node,"Old Town east exit",83.9,104,24,44,roadY,asphalt,M.Asphalt,true)

local nw=grid("North Borough",{-548,-378,-208,-38,168,326,548},{246,400,560},
	{[-548]=edgeNorth-.25,[-208]=edgeNorth-.25,[-38]=edgeNorth-.25,[168]=edgeNorth-.25,[548]=edgeNorth-.25})
local south=grid("South Ring", {94,180,302,414,526},{-635,-500},
	{[94]=-395.8,[180]=-395.8,[302]=-395.8,[414]=-395.8,[526]=-395.8})

local special={
	["-478, -443"]={"HALA TARGOWA","hall"},
	["-338, -227"]={"REMIZA","industrial"},
	["-198, -24"]={"DWORZEC ZACHODNI","hall"},
	["-463, 323"]={"PRZYCHODNIA","tower"},
	["-293, 323"]={"BIBLIOTEKA","hall"},
	["-123, 480"]={"SZKOŁA","hall"},
	["247, 323"]={"MUZEUM TECHNIKI","hall"},
	["437, 480"]={"CENTRUM SPORTU","industrial"},
	["358, -568"]={"WARSZTATY KOLEJOWE","industrial"},
	["470, -568"]={"RATUSZ","tower"},
}
local function landmarkDetails(model,cf,height,name)
	local function add(tag,size,x,y,z,color,material,solid)
		part(model,tag,size,cf*CFrame.new(x,y,z),color,material,solid)
	end
	local copper, cream = rgb(98,137,124), rgb(213,202,177)
	if name=="RATUSZ" then
		add("Council clock tower",V(9,14,9),0,height+6,-2,cream,M.Brick,true)
		add("Copper belfry",V(9.8,2.6,9.8),0,height+13.7,-2,copper,M.Metal,true)
		local clock=part(model,"Clock",V(.2,3.1,3.1),cf*CFrame.new(0,height+8.8,-6.58)*CFrame.Angles(0,math.pi/2,0),white,M.SmoothPlastic,false)
		clock.Shape=Enum.PartType.Cylinder
	elseif name=="REMIZA" or name=="WARSZTATY KOLEJOWE" then
		for _,x in {-12,0,12} do
			add("Service bay door",V(9.3,5.4,.26),x,2.92,-13.20,rgb(143,67,53),M.Metal,false)
			for i=1,5 do add("Door panel seam",V(9,.065,.10),x,.51+i*.81,-13.35,ink,M.Metal,false) end
		end
		add("Operations tower",V(6.2,7.5,6.2),16,height+3,3,cream,M.Brick,true)
	elseif name=="MUZEUM TECHNIKI" or name=="BIBLIOTEKA" then
		add("Entrance canopy",V(19,.32,4),0,5.55,-15.2,copper,M.Metal,true)
		for _,x in {-8,-4,4,8} do
			add("Entrance column",V(.55,5.3,.55),x,2.65,-16.6,cream,M.Concrete,true)
		end
		add("Broad stone step",V(19,.24,3.5),0,.12,-15.4,curb,M.Concrete,true)
	elseif name=="HALA TARGOWA" or name=="CENTRUM SPORTU" then
		for _,x in {-13,0,13} do
			add("Deep entrance awning",V(10,.22,5.2),x,3.65,-15.15,rgb(132,74,55),M.Metal,true)
			add("Entrance glazing",V(8.3,2.9,.16),x,1.77,-13.24,glass,M.Glass,false)
		end
	elseif name=="SZKOŁA" or name=="PRZYCHODNIA" then
		for _,x in {-12,12} do
			add("Side wing",V(12,height*.60,8),x,height*.30,15,cream,M.Plaster,true)
			add("Wing roof",V(12.5,.24,8.5),x,height*.60+.14,15,copper,M.Metal,true)
		end
	else
		add("Platform canopy",V(31,.28,5.8),0,5.4,-15.3,ink,M.Metal,true)
		for _,x in {-12,12} do add("Platform canopy post",V(.32,5.3,.32),x,2.65,-17.2,ink,M.Metal,true) end
	end
end

-- The landmark has its own plot, facade, and massing. Each surrounding row faces a street.
local function develop(parent,xs,zs)
	for i=1,#xs-1 do
		for j=1,#zs-1 do
			local a,b=xs[i],xs[i+1]
			local c,d=zs[j],zs[j+1]
			local x,z=math.floor((a+b)/2), math.floor((c+d)/2)
			local entry=special[("%d, %d"):format(x,z)]
			local park=(i+j*2)%7==0 and not entry
			if park then
				local p=group(parent,"Neighborhood green")
				slab(p,"Garden path",x-20,x+20,z-2,z+2,groundY+.08,curb,M.Pavement,true)
				for m=-2,2 do
					for _,side in {-1,1} do
						local cf=CFrame.new(x+m*8,groundY,z+side*11)
						part(p,"Tree trunk",V(.62,5,.62),cf*CFrame.new(0,2.5,0),rgb(96,77,56),M.Wood,true)
						local crown=part(p,"Tree canopy",V(6,6,6),cf*CFrame.new(0,6.2,0),rgb(67,99,64),M.LeafyGrass,false)
						crown.Shape=Enum.PartType.Ball
					end
				end
			else
				for _,side in {-1,1} do
					local frontZ=side==-1 and c+30 or d-30
					if entry and side==-1 then
						local name,profile=entry[1],entry[2]
						local model,cf,height=building(parent,name,x,frontZ,math.min(44,b-a-31),26,profile=="tower" and 4 or 1,profile,0)
						landmarkDetails(model,cf,height,name)
					else
						for _,dx in {-1,1} do
							local profile=(i+j)%4==0 and "tower" or ((i+j)%3==0 and "rowhouse" or "apartment")
							building(parent,("Block %03d"):format(buildingCount+1),x+dx*math.min(20,(b-a)*.18),frontZ,
								math.min(24,(b-a)*.31),16+(i+j)%3*2,2+(i+j+dx)%3,profile,side==-1 and 0 or math.pi)
						end
					end
				end
			end
		end
	end
end
develop(west,{-548,-408,-268,-128,94},{-500,-386,-280,-174,-82,34})
task.wait()
develop(nw,{-548,-378,-208,-38,168,326,548},{246,400,560})
task.wait()
develop(south,{94,180,302,414,526},{-635,-500})

-- A few tall, readable landmarks fill the skyline around the main entry.
local civic=group(metro,"Central station approach")
local station,stationCF,stationHeight=building(civic,"DWORZEC CENTRALNY",18,161,54,27,1,"hall",0)
part(station,"Station clock tower",V(7.2,12,7.2),stationCF*CFrame.new(0,stationHeight+5,0),shades[1],M.Brick,true)
sign(station,"DWORZEC",stationCF*CFrame.new(0,stationHeight+7,-3.7),5.6,1,ink)
slab(civic,"Station forecourt",-7,43,128,146,roadY+.06,curb,M.Pavement,true)
slab(civic,"Station turnout",8,28,edgeNorth-.12,128.12,roadY,asphalt,M.Asphalt,true)

if old then old:Destroy() end
local groups=metro:GetChildren()
for _,district in groups do district.Parent=nil end
metro.Parent=map
for _,district in groups do
	local children=district:GetChildren()
	for _,g in children do g.Parent=nil end
	district.Parent=metro
	for _,g in children do
		local batch=g:GetChildren()
		if #batch>30 then
			for _,item in batch do item.Parent=nil end
			g.Parent=district
			for i,item in batch do
				item.Parent=g
				if i%24==0 then task.wait() end
			end
		else
			g.Parent=district
		end
		task.wait()
	end
end
for _, name in {"WestPracticeLoop","PracticeLoopLighting","Practice Lot Apron","YardLink"} do
	local p=map:FindFirstChild(name)
	if p then p:Destroy() end
end
return string.format("Removed the practice track; built %d buildings, including %d landmarks.",buildingCount,landmarkCount)
