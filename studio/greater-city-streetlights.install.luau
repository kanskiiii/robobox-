-- Add street lighting to the Greater City districts in Studio Edit mode.
local map = workspace.Map
local metro = assert(map:FindFirstChild("Greater City"))
local client = game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local previous = metro:FindFirstChild("District streetlights")
assert(not previous or previous:GetAttribute("TwoStrokeStreetlights"))
local collection = game:GetService("CollectionService")
local tag = "GreaterCityStreetlight"
local V,rgb,M = Vector3.new,Color3.fromRGB,Enum.Material
local steel = rgb(62,72,75)
local lensColor = rgb(251,231,182)
local layer = Instance.new("Model")
layer.Name = "District streetlights"
layer:SetAttribute("TwoStrokeStreetlights", true)
local roadHeight = map.Road.Position.Y + map.Road.Size.Y/2
local function part(parent,name,size,pose,color,material,solid)
	local p = Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material = name,size,pose,color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch = true,solid,solid,false
	p.TopSurface,p.BottomSurface = Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function lamp(group,x,z,y,direction)
	local model=Instance.new("Model")
	model.Name="Streetlight"
	model.Parent=group
	local base=CFrame.lookAlong(V(x,y,z),direction)
	part(model,"Concrete footing",V(.76,.24,.76),base*CFrame.new(0,.12,0),rgb(127,122,114),M.Concrete,true)
	part(model,"Steel pole",V(.24,10.2,.24),base*CFrame.new(0,5.18,0),steel,M.Metal,true)
	part(model,"Arm",V(.17,.18,2.8),base*CFrame.new(0,10.17,-1.35),steel,M.Metal,false)
	part(model,"Lamp hood",V(.66,.23,.95),base*CFrame.new(0,10.12,-2.63),steel,M.Metal,false)
	local lens=part(model,"Lens",V(.48,.06,.73),base*CFrame.new(0,9.98,-2.63),rgb(166,154,129),M.Glass,false)
	collection:AddTag(lens,tag)
	local light=Instance.new("SpotLight")
	light.Name="StreetLED"
	light.Face,light.Angle,light.Range,light.Brightness=Enum.NormalId.Bottom,112,25,1.7
	light.Color,light.Enabled=lensColor,false
	light.Parent=lens
end
local count=0
for _,name in {"Old Town and West Quarter","North Borough","South Ring"} do
	local district=metro[name]
	local group=Instance.new("Model")
	group.Name,group.Parent=name,layer
	local paving=district.Streets
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={paving}
	local accepted={}
	for _,p in paving:GetChildren() do
		if p.Name~="Sidewalk" or not p.CanQuery then continue end
		local alongX=p.Size.X>p.Size.Z
		local length=alongX and p.Size.X or p.Size.Z
		if length<32 then continue end
		for _,fraction in ipairs(length>90 and {-.28,.28} or {0}) do
			local offset=alongX and V(length*fraction,0,0) or V(0,0,length*fraction)
			local at=p.Position+offset
			local close=false
			for _,prior in ipairs(accepted) do
				if (prior-at).Magnitude<36 then close=true break end
			end
			if close then continue end
			local across=alongX and Vector3.zAxis or Vector3.xAxis
			for _,sign in {-1,1} do
				local direction=across*sign
				local lane=workspace:Raycast(at+direction*4+V(0,3,0),V(0,-5,0),params)
				if lane and lane.Material==M.Asphalt and math.abs(lane.Position.Y-roadHeight)<.02 then
					lamp(group,at.X,at.Z,p.Position.Y+p.Size.Y/2,direction)
					table.insert(accepted,at)
					count+=1
					break
				end
			end
		end
	end
end
assert(count>=30,"Not enough streetlight sites were found")
if previous then previous:Destroy() end
layer.Parent=metro

-- Use the client's lighting clock to support both world time and local night preview.
local controller=client:FindFirstChild("DistrictStreetlights") or Instance.new("LocalScript")
assert(controller:IsA("LocalScript"))
controller.Name="DistrictStreetlights"
controller.Source=[==[
local collection=game:GetService("CollectionService")
local lighting=game:GetService("Lighting")
local tag="GreaterCityStreetlight"
local daylight=Color3.fromRGB(166,154,129)
local lit=Color3.fromRGB(251,231,182)
local night
local function refresh(lens)
	local light=lens:FindFirstChild("StreetLED")
	if not light then return end
	light.Enabled=night
	lens.Color=night and lit or daylight
	lens.Material=night and Enum.Material.Neon or Enum.Material.Glass
end
local function update()
	local hour=lighting.ClockTime
	local value=hour>=18.5 or hour<6.25
	if value==night then return end
	night=value
	for _,lens in collection:GetTagged(tag) do refresh(lens) end
end
collection:GetInstanceAddedSignal(tag):Connect(function(lens)
	task.defer(refresh,lens)
end)
update()
lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
]==]
controller.Parent=client
return ("Installed %d dusk-to-dawn streetlights"):format(count)
