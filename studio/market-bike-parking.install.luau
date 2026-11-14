-- Market Square motorcycle parking. Run in Studio Edit mode after SouthCity.
local map=workspace.Map
local city=assert(map:FindFirstChild("SouthCity"))
local streets=assert(city:FindFirstChild("Streets"))
local square=assert(city:FindFirstChild("Market square"))
local plaza=assert(square:FindFirstChild("Stone plaza"))
local roadY=map.Road.Position.Y+map.Road.Size.Y/2
local x,z=454,-266
local width=24
local V,rgb,M=Vector3.new,Color3.fromRGB,Enum.Material
local lot=Instance.new("Model")
lot.Name="Market Square Bike Parking"
lot:SetAttribute("TwoStrokeMapVersion",1)
local other=city:FindFirstChild(lot.Name)
assert(not other or other:GetAttribute("TwoStrokeMapVersion"))
local old
local sidewalkReference=streets:FindFirstChild("Market parking curb reference")
for _,p in streets:GetChildren() do
	if p.Name=="Cross-street sidewalk" and math.abs(p.Position.Z-(z-2))<.1
		and math.abs(p.Position.X-x)<p.Size.X/2 then old=p break end
end
assert(old or sidewalkReference,"Market sidewalk missing")
local ref=old or sidewalkReference
local function part(name, size, pose, color, material, solid, shape)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material=name,size,pose,color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	if shape then p.Shape=shape end
	p.Parent=lot
	return p
end
local function rect(name,x1,x2,z1,z2,top,depth,color,material,solid)
	return part(name,V(x2-x1,depth,z2-z1),CFrame.new((x1+x2)/2,top-depth/2,(z1+z2)/2),color,material,solid)
end
local concrete,asphalt,white,steel=ref.Color,rgb(47,50,51),rgb(230,224,195),rgb(63,73,77)
local lo,hi=ref.Position.X-ref.Size.X/2,ref.Position.X+ref.Size.X/2
local curbTop=ref.Position.Y+ref.Size.Y/2
local a,b=x-width/2,x+width/2
assert(lo<a and hi>b)
rect("West curb",lo,a,z-4,z,curbTop,.24,concrete,M.Pavement,true)
rect("East curb",b,hi,z-4,z,curbTop,.24,concrete,M.Pavement,true)
rect("Flush driveway",a,b,z-4,z,roadY,.25,asphalt,M.Asphalt,true)
local top=plaza.Position.Y+plaza.Size.Y/2+.012
rect("Parking apron",a,b,z,z+11,top,.23,asphalt,M.Asphalt,true)
for i=0,6 do
	local xx=x+(i-3)*3.45
	rect("Bay stripe",xx-.045,xx+.045,z+4.1,z+9.7,top+.014,.012,white,M.SmoothPlastic,false)
end
rect("Bay end line",x-10.35,x+10.35,z+9.6,z+9.72,top+.014,.012,white,M.SmoothPlastic,false)
for _,side in {-1,1} do
	local xx=x+side*11.45
	part("Bollard",V(.27,1.8,.27),CFrame.new(xx,top+.90,z+8.7),steel,M.Metal,true)
	part("Reflective collar",V(.29,.26,.29),CFrame.new(xx,top+1.46,z+8.7),rgb(213,169,56),M.SmoothPlastic,false)
end
local function tube(name,a,b,diameter)
	part(name,V((b-a).Magnitude,diameter,diameter),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),steel,M.Metal,true,Enum.PartType.Cylinder)
end
for i=-1,1 do
	local xx=x+i*5
	local left,right=V(xx-.75,top,z+10.7),V(xx+.75,top,z+10.7)
	tube("Rack upright",left,left+V(0,1.53,0),.135)
	tube("Rack rail",left+V(0,1.53,0),right+V(0,1.53,0),.135)
	tube("Rack upright",right,right+V(0,1.53,0),.135)
end
local xx=b+1.05
part("Parking signpost",V(.16,4.6,.16),CFrame.new(xx,curbTop+2.3,z-1.25),steel,M.Metal,true)
local board=part("Motorcycle parking sign",V(4.6,1.55,.14),CFrame.new(xx,curbTop+4.08,z-1.36),rgb(28,71,120),M.Metal,false)
local gui=Instance.new("SurfaceGui")
gui.Face,gui.SizingMode,gui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(500,145)
gui.Parent=board
local text=Instance.new("TextLabel")
text.Size=UDim2.fromScale(1,1)
text.BackgroundTransparency,text.TextScaled=1,true
text.Text,text.TextColor3,text.Font="P  MOTOCYKLE",white,Enum.Font.GothamBold
text.Parent=gui

if old then
	old.Name="Market parking curb reference"
	old.Transparency=1
	old.CanCollide,old.CanQuery,old.CanTouch=false,false,false
end
if other then other:Destroy() end
lot.Parent=city
return "Six motorcycle bays and a flush market street entrance installed"
