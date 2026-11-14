-- Install an operating roadside petrol station west of the workshop.
local map=workspace.Map
local road=map.Road
local roadY=road.Position.Y+road.Size.Y/2
local z=road.Position.Z+road.Size.Z/2
local x=-331
local service=game:GetService("ServerScriptService").TwoStrokeServer.GarageService
local source=service.Source
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"GarageService changed at "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
if not source:find("RoadsideFuelStation",1,true) then
	replace("\tif pump then\n\t\tlocal p = Instance.new(\"ProximityPrompt\")",
		"\tlocal function connectFuelPump(pump: BasePart)\n\t\tlocal p = Instance.new(\"ProximityPrompt\")\n\t\tp.Name = \"Refuel\"")
	replace('if not s then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tif Jerrycan.fillAtPump(s) then',
		'if not s or not within(s, pump.Position, 16) then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tif Jerrycan.fillAtPump(s) then')
	replace("\n\tlocal deliveryMap = Workspace:FindFirstChild(\"Map\")",[==[
	if pump then connectFuelPump(pump) end
	local deliveryMap = Workspace:FindFirstChild("Map")
	local station = deliveryMap and deliveryMap:FindFirstChild("RoadsideFuelStation")
	if station then
		for _, marker in station:GetChildren() do
			if marker.Name == "FuelPump" and marker:IsA("BasePart") then connectFuelPump(marker) end
		end
	end]==])
end
local V,rgb,M=Vector3.new,Color3.fromRGB,Enum.Material
local white,steel,teal=rgb(237,228,205),rgb(53,65,69),rgb(31,111,112)
local asphalt=rgb(50,54,56)
local station=Instance.new("Model")
station.Name="RoadsideFuelStation"
station:SetAttribute("TwoStrokeFuelStation",1)
local old=map:FindFirstChild(station.Name)
assert(not old or old:GetAttribute("TwoStrokeFuelStation"))
local function part(name,w,h,d,px,y,pz,color,material,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.Position,p.Color,p.Material=name,V(w,h,d),V(x+px,roadY+y,z+pz),color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=station
	return p
end
local function paint(name,w,d,px,pz,col)
	part(name,w,.018,d,px,.012,pz,col,M.SmoothPlastic,false).CastShadow=false
end
local function sign(name,caption,w,h,px,y,pz,color)
	local panel=part(name,w,h,.15,px,y,pz,color,M.Metal,false)
	local gui=Instance.new("SurfaceGui")
	gui.Face,gui.SizingMode,gui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(520,math.round(520*h/w))
	gui.LightInfluence=.22
	gui.Parent=panel
	local text=Instance.new("TextLabel")
	text.Size,text.BackgroundTransparency=UDim2.fromScale(1,1),1
	text.Text,text.TextScaled,text.TextColor3,text.Font=caption,true,white,Enum.Font.GothamBlack
	text.Parent=gui
end
for _,px in {-21,21} do
	part("Driveway",14,.24,18,px,-.12,8.9,asphalt,M.Asphalt,true)
	for _,dx in {-5.9,5.9} do paint("Driveway edge",.12,13,px+dx,8,white) end
end
part("Drive-through forecourt",62,.24,29,0,-.12,26,asphalt,M.Asphalt,true)
part("Pump island",25,.32,3.6,0,.16,25,rgb(145,145,136),M.Concrete,true)
part("Canopy",32,.4,16,0,9.5,25,teal,M.Metal,true)
for _,px in {-11.6,11.6} do
	part("Canopy support",.45,9.1,.50,px,4.84,25,steel,M.Metal,true)
end
sign("Canopy fascia","STACJA PALIW",26,1.3,0,9.42,16.94,teal)
for _,px in {-5.5,5.5} do
	local p=part("FuelPump",1.5,2.6,1.0,px,1.62,25,teal,M.Metal,true)
	local attachment=Instance.new("Attachment")
	attachment.Name="NozzleSide"
	attachment.Position=V(0,0,-.55)
	attachment.Parent=p
	part("Pump base",1.70,.20,1.16,px,.42,25,steel,M.Metal,true)
	part("Pump display",1.22,.67,.10,px,2.24,24.46,steel,M.Glass,false)
	sign("Fuel grade sign","95",.65,.34,px,1.66,24.40,teal)
	part("Hose",.10,1.36,.12,px+.82,1.45,24.9,steel,M.Rubber,false)
	part("Nozzle",.24,.36,.25,px+.82,2.12,24.83,steel,M.Metal,false)
	paint("Refueling bay edge",.12,7,px-3.8,20,white)
	paint("Refueling bay edge",.12,7,px+3.8,20,white)
	local lens=part("Canopy light",3.3,.10,.70,px,9.24,22,white,M.Glass,false)
	local light=Instance.new("SpotLight")
	light.Face,light.Angle,light.Range,light.Brightness=Enum.NormalId.Bottom,112,17,1.55
	light.Parent=lens
end
part("Shop building shell",31,7.3,12,0,3.65,46,rgb(180,176,161),M.Plaster,true)
part("Shop roof cap",32,.30,12.6,0,7.49,46,steel,M.Metal,true)
part("Shop path",31,.16,3.1,0,.08,39.6,rgb(154,149,137),M.Pavement,true)
sign("Shop sign","SKLEP",11,.89,0,5.85,39.89,teal)
for _,px in {-9,9} do
	part("Shop window frame",8,3,.19,px,2.65,39.89,steel,M.Metal,false)
	part("Shop window glass",7.55,2.56,.07,px,2.65,39.77,rgb(87,121,132),M.Glass,false)
end
part("Shop door",2.6,3.9,.18,0,2,39.88,steel,M.Metal,false)
sign("Roadside sign","PALIWO  →",7.5,1.18,-12,4.05,7,teal)
part("Roadside sign post",.20,4.8,.20,-12,2.40,7.2,steel,M.Metal,true)
if old then old:Destroy() end
station.Parent=map
service.Source=source
return "Added roadside fuel station and connected both pumps to the workshop refueling system."
