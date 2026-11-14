-- Add playable SouthCity delivery stops. Run in Studio Edit after the SouthCity installer.
local map = assert(workspace:FindFirstChild("Map"))
local city = assert(map:FindFirstChild("SouthCity"))
local buildings = city:FindFirstChild("Apartments and shops")
local service = game:GetService("ServerScriptService").TwoStrokeServer.Delivery
local patch = [==[
	local city = map and map:FindFirstChild("SouthCity")
	local counters = city and city:FindFirstChild("Delivery counters")
	if counters then
		for _, counter in counters:GetChildren() do
			local marker = counter:FindFirstChild("Pickup")
			if marker and marker:IsA("BasePart") then
				table.insert(out, { name = counter.Name, pos = marker.Position })
			end
		end
	end
]==]
local source = service.Source
if not source:find('FindFirstChild("Delivery counters")', 1, true) then
	local start = assert(source:find("local function restaurants()", 1, true))
	local finish = assert(source:find("\treturn out\nend", start, true))
	source = source:sub(1,finish-1)..patch..source:sub(finish)
end
local roadY = map.Road.Position.Y + map.Road.Size.Y/2
local groundY = map.Ground.Position.Y + map.Ground.Size.Y/2
local V, rgb, M = Vector3.new, Color3.fromRGB, Enum.Material
local ink = rgb(238,234,217)
local counters = Instance.new("Model")
counters.Name = "Delivery counters"
local bays = Instance.new("Model")
bays.Name = "Apartment delivery bays"
local drops = assert(map:FindFirstChild("DeliveryDrops"))
local markers = {}

local function p(parent,n,size,cf,col,mat)
	local part=Instance.new("Part")
	part.Name,part.Size,part.CFrame=n,size,cf
	part.Color,part.Material=col,mat
	part.Anchored,part.CanCollide,part.CanQuery,part.CanTouch=true,false,false,false
	part.CastShadow=false
	part.TopSurface,part.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	part.Parent=parent
	return part
end
local function sign(parent,name,cf,w,h,color,text)
	local panel=p(parent,name,V(w,h,.15),cf,color,M.Metal)
	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Front
	gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize=Vector2.new(500,math.round(500*h/w))
	gui.LightInfluence=.45
	gui.Parent=panel
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(.94,1)
	label.Position=UDim2.fromScale(.03,0)
	label.Text,label.TextColor3,label.Font=text,ink,Enum.Font.GothamBold
	label.BackgroundTransparency,label.TextScaled=1,true
	label.Parent=gui
end
local function marker(parent,name,x,z)
	local target=p(parent,name,V(.5,.15,.5),CFrame.new(x,roadY+.08,z),ink,M.SmoothPlastic)
	target.Transparency=1
	return target
end
local function bayStripe(parent,x,z)
	local color=rgb(213,191,106)
	for _,side in {-1,1} do
		p(parent,"Loading bay end line",V(.13,.016,2.4),CFrame.new(x+side*4.3,roadY+.012,z),color,M.SmoothPlastic)
	end
	p(parent,"Loading bay lane line",V(8.6,.016,.13),CFrame.new(x,roadY+.012,z-1.2),color,M.SmoothPlastic)
end

local function counter(x,z,title,color)
	local shell
	for _,candidate in buildings:GetChildren() do
		local wall=candidate:FindFirstChild("Masonry shell")
		if wall and math.abs(wall.Position.X-x)<.1 and math.abs(wall.Position.Z-z)<.1 then
			shell=wall
			break
		end
	end
	assert(shell, "Missing delivery storefront "..title)
	local shop=Instance.new("Model")
	shop.Name,shop.Parent=title,counters
	local front=shell.CFrame*CFrame.new(0,0,-shell.Size.Z/2-1.37)
	sign(shop,"Pickup fascia",CFrame.new(front.X,groundY+4.85,front.Z)*front.Rotation,
		shell.Size.X*.84,1.15,color,title)
	local light=p(shop,"Pickup light",V(.54,.14,.36),CFrame.new(front.X,groundY+3.84,front.Z),ink,M.Glass)
	local lamp=Instance.new("PointLight")
	lamp.Range,lamp.Brightness,lamp.Color=8,.7,rgb(255,219,177)
	lamp.Parent=light
	local lane=z-27+7.8
	marker(shop,"Pickup",x,lane)
	bayStripe(shop,x,lane)
end
counter(327,-253,"Piekarnia Rynkowa",rgb(124,69,44))
counter(470,-359,"Bistro Południe",rgb(46,82,77))

for _,item in ipairs({{359,-166,"ul. Miodowa 8"},{495,-272,"ul. Rynkowa 21"},{365,-378,"ul. Południowa 14"}}) do
	local x,z,street=item[1],item[2],item[3]
	local model=Instance.new("Model")
	model.Name,model.Parent=street,bays
	bayStripe(model,x,z)
	p(model,"Address post",V(.17,2.7,.17),CFrame.new(x,groundY+1.35,z+4.1),rgb(80,85,85),M.Metal)
	sign(model,"Street address",CFrame.new(x,groundY+2.5,z+4.03),5.7,.8,rgb(51,64,77),street)
	local target=marker(nil,"City_"..street,x,z)
	target:SetAttribute("Street",street)
	target:SetAttribute("SouthCityDelivery",true)
	table.insert(markers,target)
end
for _,child in drops:GetChildren() do
	if child:GetAttribute("SouthCityDelivery") then child:Destroy() end
end
for _,replacement in {counters,bays} do
	local old=city:FindFirstChild(replacement.Name)
	if old then old:Destroy() end
	replacement.Parent=city
end
for _,target in markers do target.Parent=drops end
service.Source=source
return "Installed 2 city pickups and 3 apartment delivery addresses"
