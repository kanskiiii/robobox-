-- Add usable loading bays to Greater City. Run after greater-city.install.luau in Edit mode.
local map = workspace.Map
local metro = assert(map:FindFirstChild("Greater City"))
local drops = assert(map:FindFirstChild("DeliveryDrops"))
local service = game:GetService("ServerScriptService").TwoStrokeServer.Delivery
local roadTop = map.Road.Position.Y + map.Road.Size.Y / 2
local V, rgb, M = Vector3.new, Color3.fromRGB, Enum.Material
local oldTown, north, south = "Old Town and West Quarter", "North Borough", "South Ring"
local locations = {
	{oldTown,-500,-448,"Bar Hala Targowa",true},
	{oldTown,-82,-166,"Kawiarnia Dworcowa",true},
	{north,246,277,"Kawiarnia Muzealna",true},
	{oldTown,-280,-308,"Remiza · ul. Strażacka 7"},
	{north,246,-433,"Przychodnia · ul. Zdrowa 12"},
	{north,246,-263,"Biblioteka · ul. Czytelnicza 6"},
	{north,400,-93,"Szkoła · ul. Szkolna 14"},
	{south,-635,388,"Warsztaty · ul. Kolejowa 38"},
	{south,-635,500,"Ratusz · pl. Miejski 1"},
}
local asphalt, paint, ink = rgb(53,56,59), rgb(231,208,126), rgb(51,72,76)
local layer = Instance.new("Model")
layer.Name = "Landmark delivery bays"
local shops = Instance.new("Folder")
shops.Name = "Delivery counters"
shops.Parent = layer
local staging = {}

local function slab(parent,name,x1,x2,z1,z2,top,depth,color,material,solid)
	local p = Instance.new("Part")
	p.Name,p.Size,p.Position = name,V(x2-x1,depth,z2-z1),V((x1+x2)/2,top-depth/2,(z1+z2)/2)
	p.Color,p.Material = color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch = true,solid,solid,false
	p.TopSurface,p.BottomSurface = Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function sign(parent,label,x,z)
	slab(parent,"Signpost",x-.10,x+.10,z-.08,z+.08,roadTop+3.8,3.7,ink,M.Metal,true)
	local p = slab(parent,"Address sign",x-4.5,x+4.5,z-.18,z,roadTop+4,1.15,ink,M.Metal,false)
	local g = Instance.new("SurfaceGui")
	g.Face,g.SizingMode,g.CanvasSize = Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(500,78)
	g.LightInfluence = .45
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size,t.BackgroundTransparency = UDim2.fromScale(.96,1),1
	t.Position,t.Font,t.TextScaled = UDim2.fromScale(.02,0),Enum.Font.GothamBold,true
	t.Text,t.TextColor3,t.Parent = label,rgb(248,237,205),g
end

for _,item in ipairs(locations) do
	local area,z,x,title,pickup = table.unpack(item)
	local streets = metro[area].Streets
	local curb
	for _,p in streets:GetChildren() do
		if p:IsA("BasePart") and (p.Name=="Sidewalk" or p:GetAttribute("LandmarkBayCurb")) and
			math.abs(p.Position.Z-(z+12))<.05 and math.abs(p.Position.X-x)+8 < p.Size.X/2 then
			curb=p
			break
		end
	end
	assert(curb,"Cannot find the curb for "..title)
	local curbLeft, curbRight = curb.Position.X-curb.Size.X/2, curb.Position.X+curb.Size.X/2
	local curbTop = curb.Position.Y+curb.Size.Y/2
	local model = Instance.new("Model")
	model.Name = title
	model.Parent = pickup and shops or layer
	slab(model,"Curb west of loading bay",curbLeft,x-8,z+10,z+14,curbTop,curb.Size.Y,curb.Color,curb.Material,true)
	slab(model,"Curb east of loading bay",x+8,curbRight,z+10,z+14,curbTop,curb.Size.Y,curb.Color,curb.Material,true)
	slab(model,"Loading apron",x-8,x+8,z+9.98,z+23,roadTop,.23,asphalt,M.Asphalt,true)
	slab(model,"Walk behind the bay",x-8,x+8,z+23,z+26,curbTop,.23,curb.Color,curb.Material,true)
	for _,offset in {-6.6,6.6} do
		slab(model,"Loading stripe",x+offset-.07,x+offset+.07,z+15,z+21.5,roadTop+.013,.012,paint,M.SmoothPlastic,false)
	end
	slab(model,"Loading stripe",x-6.66,x+6.66,z+21.35,z+21.5,roadTop+.013,.012,paint,M.SmoothPlastic,false)
	sign(model,title,x,z+24.4)
	local point = slab(pickup and model or nil,pickup and "Pickup" or "Landmark_"..title,x-.2,x+.2,z+17.8,z+18.2,roadTop+.16,.13,paint,M.SmoothPlastic,false)
	point.Transparency=1
	point:SetAttribute("CityLandmarkStop",true)
	if not pickup then point:SetAttribute("Street",title) end
	table.insert(staging,{curb=curb,drop=not pickup and point or nil})
end

local source = service.Source
if not source:find("Landmark delivery bays",1,true) then
	local first = assert(source:find("local function restaurants()",1,true))
	local finish = assert(source:find("\treturn out\nend",first,true))
	source=source:sub(1,finish-1)..[==[	local metro = map and map:FindFirstChild("Greater City")
	local bays = metro and metro:FindFirstChild("Landmark delivery bays")
	local cityPickups = bays and bays:FindFirstChild("Delivery counters")
	if cityPickups then
		for _, counter in cityPickups:GetChildren() do
			local marker = counter:FindFirstChild("Pickup")
			if marker and marker:IsA("BasePart") then
				table.insert(out, { name = counter.Name, pos = marker.Position })
			end
		end
	end
]==]..source:sub(finish)
end

local previous = metro:FindFirstChild(layer.Name)
if previous then previous:Destroy() end
for _,child in drops:GetChildren() do
	if child:GetAttribute("CityLandmarkStop") then child:Destroy() end
end
layer.Parent=metro
for _,entry in staging do
	local curb=entry.curb
	curb:SetAttribute("LandmarkBayCurb",true)
	curb.Transparency=1
	curb.CanCollide,curb.CanQuery,curb.CanTouch=false,false,false
	if entry.drop then entry.drop.Parent=drops end
end
service.Source=source
return "Added three landmark pickups and six destination loading bays."
