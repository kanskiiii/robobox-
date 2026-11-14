-- Add a street map to the existing phone. Replay in Edit after the current city installers.
local client=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local phone=client.Phone
local source=phone.Source
local function insert(before,replacement)
	local a,b=source:find(before,1,true)
	assert(a,"Phone integration point changed: "..before)
	source=source:sub(1,a-1)..replacement..source:sub(b+1)
end
if not source:find('local CityMap = require',1,true) then
	insert("local SPM = 1 / 0.28",'local SPM = 1 / 0.28\nlocal CityMap = require(script.Parent.CityMap)')
	insert('\tlocal shopButton = button("Garage Shop"','\tlocal cityButton = button("City Map", Color3.fromRGB(48, 105, 130), {\n\t\tName = "CityMapButton", Position = UDim2.fromOffset(16,443), Size = UDim2.fromOffset(100,33), Parent = screen,\n\t})\n\tCityMap.mount(screen, cityButton)\n\tlocal shopButton = button("Garage Shop"')
	insert('Name = "GarageShop", Position = UDim2.fromOffset(16, 443), Size = UDim2.new(1, -32, 0, 33)', 'Name = "GarageShop", Position = UDim2.fromOffset(124, 443), Size = UDim2.new(1, -140, 0, 33)')
	insert("\tlocal at = myPos()","\tlocal at = myPos()\n\tCityMap.update(at, order and order.target, order and (if order.phase == \"pickup\" then order.restaurant else order.street))")
end

-- Bake the roads from the actual Edit map so the full chart loads even with StreamingEnabled.
local map=assert(workspace:FindFirstChild("Map"))
local rows={}
local function road(p)
	local cf=p.CFrame
	if p.Size.X<4 or p.Size.Z<4 then return end
	local _,yaw=cf:ToOrientation()
	table.insert(rows,("{%.2f,%.2f,%.2f,%.2f,%.4f}"):format(cf.X,cf.Z,p.Size.X,p.Size.Z,yaw))
end
road(map.Road)
for _,n in {"Greater City","West City and Workshop","SouthTown","SouthCity","EastFarmLane"} do
	local district=assert(map:FindFirstChild(n))
	for _,p in district:GetDescendants() do
		if p:IsA("BasePart") and (p.Material==Enum.Material.Asphalt or (n=="EastFarmLane" and p.Name=="Drivable pavement")) then road(p) end
	end
end
table.sort(rows)
local pins={}
local function pin(name,title,x,z)
	table.insert(pins,("{%q,%q,%.2f,%.2f}"):format(name,title,x,z))
end
local bay=map.GarageBay.Position
pin("G","Workshop",bay.X,bay.Z)
local metro=map["Greater City"]
for _,spec in ipairs({
	{"M","Market Hall","HALA TARGOWA"},
	{"S","Central Station","DWORZEC CENTRALNY"},
	{"L","Library","BIBLIOTEKA"},
	{"T","Technical Museum","MUZEUM TECHNIKI"},
	{"R","Town Hall","RATUSZ"},
}) do
	local landmark=assert(metro:FindFirstChild(spec[3],true),spec[3])
	local p=landmark.Facade.Position
	pin(spec[1],spec[2],p.X,p.Z)
end

local uiSource=[==[
local roads = ROAD_DATA
local pins = PIN_DATA
local CityMap = {}
local chart, panel, playerDot, deliveryDot, title, detail, note
local selected
local mapSize = 222
local minX,minZ,mapWidth=-622,-658,1318
local ink=Color3.fromRGB(231,241,232)
local dim=Color3.fromRGB(160,182,180)
local blue=Color3.fromRGB(112,218,255)
local gold=Color3.fromRGB(255,190,90)
local mint=Color3.fromRGB(111,236,166)

local function make(class,parent,props)
	local object=Instance.new(class)
	for k,v in pairs(props) do object[k]=v end
	object.Parent=parent
	return object
end
local function round(gui,radius)
	make("UICorner",gui,{CornerRadius=UDim.new(0,radius)})
end
local function point(x,z)
	return Vector2.new(math.clamp((x-minX)/mapWidth,0,1)*mapSize,math.clamp((z-minZ)/mapWidth,0,1)*mapSize)
end
local function dot(parent,name,color,size,layer)
	local d=make("Frame",parent,{Name=name,Size=UDim2.fromOffset(size,size),AnchorPoint=Vector2.new(.5,.5),
		BackgroundColor3=color,BorderSizePixel=0,ZIndex=layer,Visible=false})
	round(d,20)
	make("UIStroke",d,{Color=Color3.fromRGB(25,47,52),Thickness=1.5})
	return d
end
local function label(parent,name,value,x,y,w,h,size,color)
	return make("TextLabel",parent,{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
		Text=value,TextWrapped=true,TextSize=size,TextColor3=color,BackgroundTransparency=1,ZIndex=22,
		TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBold})
end

function CityMap.mount(screen,button)
	panel=make("Frame",screen,{Name="CityMap",Position=UDim2.fromOffset(4,27),Size=UDim2.new(1,-8,0,449),
		BackgroundColor3=Color3.fromRGB(21,33,40),BorderSizePixel=0,Visible=false,ZIndex=20,Active=true})
	round(panel,17)
	label(panel,"Heading","CITY MAP",14,10,155,22,19,ink)
	local close=make("TextButton",panel,{Name="Back",Position=UDim2.new(1,-67,0,7),Size=UDim2.fromOffset(57,29),
		BackgroundColor3=Color3.fromRGB(47,73,82),Text="Jobs",TextColor3=ink,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=22})
	round(close,8)
	chart=make("Frame",panel,{Name="StreetGrid",Position=UDim2.fromOffset(10,45),Size=UDim2.fromOffset(mapSize,mapSize),
		ClipsDescendants=true,BackgroundColor3=Color3.fromRGB(38,62,56),BorderSizePixel=0,ZIndex=21})
	round(chart,9)
	for _,r in ipairs(roads) do
		local p=point(r[1],r[2])
		make("Frame",chart,{Name="Street",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(p.X,p.Y),
			Size=UDim2.fromOffset(math.max(1,r[3]/mapWidth*mapSize),math.max(1,r[4]/mapWidth*mapSize)),
			Rotation=-math.deg(r[5]),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(161,173,158),ZIndex=22})
	end
	for _,p in ipairs(pins) do
		local loc=point(p[3],p[4])
		local marker=make("TextButton",chart,{Name="Pin_"..p[1],Text=p[1],TextColor3=ink,TextSize=11,Font=Enum.Font.GothamBold,
			AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(loc.X,loc.Y),Size=UDim2.fromOffset(21,21),
			BackgroundColor3=Color3.fromRGB(50,101,107),BorderSizePixel=0,ZIndex=24})
		round(marker,10)
		marker.Activated:Connect(function()
			selected=p
			title.Text=p[2]
			detail.Text=""
		end)
	end
	playerDot=dot(chart,"PlayerLocation",mint,9,26)
	deliveryDot=dot(chart,"DeliveryLocation",gold,11,25)
	label(panel,"PlayerKey","● You",14,276,83,20,12,mint)
	label(panel,"DeliveryKey","● Delivery stop",104,276,124,20,12,gold)
	title=label(panel,"Place","Tap a landmark",15,312,209,28,17,ink)
	detail=label(panel,"Distance","",15,343,209,24,14,blue)
	note=label(panel,"CurrentDelivery","No active delivery",15,374,209,52,13,dim)
	button.Activated:Connect(function() panel.Visible=true end)
	close.Activated:Connect(function() panel.Visible=false end)
end

local function move(dotObject,world)
	dotObject.Visible=world~=nil
	if world then
		local site=point(world.X,world.Z)
		dotObject.Position=UDim2.fromOffset(site.X,site.Y)
	end
end
function CityMap.update(position,target,jobName)
	if not panel or not panel.Visible then return end
	move(playerDot,position)
	move(deliveryDot,target)
	note.Text=target and ("Delivery  ·  "..(jobName or "Current stop")) or "No active delivery"
	if selected and position then
		local delta=Vector2.new(position.X-selected[3],position.Z-selected[4])
		detail.Text=("%d m away"):format(math.round(delta.Magnitude*.28))
	end
end
return CityMap
]==]
uiSource=uiSource:gsub("ROAD_DATA",function() return "{\n"..table.concat(rows,",\n").."\n}" end)
uiSource=uiSource:gsub("PIN_DATA",function() return "{\n"..table.concat(pins,",\n").."\n}" end)
local module=client:FindFirstChild("CityMap") or Instance.new("ModuleScript")
assert(module:IsA("ModuleScript"))
module.Name="CityMap"
module.Source=uiSource
module.Parent=client
phone.Source=source
return ("Baked %d road tiles and %d landmark pins into the phone map"):format(#rows,#pins)
