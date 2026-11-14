-- Post the patrol speed limit on the main road and district approaches.
local map=workspace.Map
local metro=assert(map:FindFirstChild("Greater City"))
local police=game:GetService("ServerScriptService").TwoStrokeServer.PolicePatrol
local limit=assert(tonumber(police.Source:match("local LIMIT=(%d+)")))
local road=map.Road
local width=road.Size.Z/2
local z=road.Position.Z
local signs=Instance.new("Model")
signs.Name="Posted speed limits"
signs:SetAttribute("TwoStrokeSpeedLimitSigns",true)
local old=metro:FindFirstChild(signs.Name)
assert(not old or old:GetAttribute("TwoStrokeSpeedLimitSigns"))
local V,rgb,M=Vector3.new,Color3.fromRGB,Enum.Material
local metal,red,white,ink=rgb(106,115,116),rgb(194,41,42),rgb(246,242,221),rgb(34,33,31)
local q=RaycastParams.new()
q.FilterType=Enum.RaycastFilterType.Exclude
q.FilterDescendantsInstances=old and {old} or {}
local function make(parent,name,size,cf,color,material,shape,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame=name,size,cf
	p.Color,p.Material,p.Shape=color,material,shape
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function build(name,x,z,direction)
	local hit=workspace:Raycast(V(x,1.4,z),V(0,-4,0),q)
	assert(hit and (hit.Material==M.Grass or hit.Material==M.Pavement or hit.Material==M.Concrete),name.." footing obstructed")
	local m=Instance.new("Model")
	m.Name,m.Parent=name,signs
	local frame=CFrame.lookAlong(V(x,hit.Position.Y,z),direction)
	make(m,"Footing",V(.4,.16,.4),frame*CFrame.new(0,.08,0),metal,M.Concrete,Enum.PartType.Block,true)
	make(m,"Galvanized pole",V(.13,4.6,.13),frame*CFrame.new(0,2.3,0),metal,M.Metal,Enum.PartType.Block,true)
	-- Use a circle in the SurfaceGui so the numerals and border share one clean face.
	local panel=make(m,"Limit face",V(2.6,2.6,.09),frame*CFrame.new(0,4.8,-.11),metal,M.Metal,Enum.PartType.Block,false)
	panel.Transparency=1
	local ui=Instance.new("SurfaceGui")
	ui.Face,ui.SizingMode,ui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(220,220)
	ui.LightInfluence=.25
	ui.Parent=panel
	local disc=Instance.new("Frame")
	disc.Size,disc.BackgroundColor3=UDim2.fromScale(1,1),red
	disc.BorderSizePixel=0
	disc.Parent=ui
	local edge=Instance.new("UICorner");edge.CornerRadius=UDim.new(1,0);edge.Parent=disc
	local face=Instance.new("TextLabel")
	face.Position,face.Size=UDim2.fromScale(.105,.105),UDim2.fromScale(.79,.79)
	face.BackgroundColor3,face.TextColor3=white,ink
	face.BorderSizePixel=0
	face.Font,face.TextSize,face.Text=Enum.Font.GothamBlack,86,tostring(limit)
	face.Parent=disc
	local round=edge:Clone()
	round.Parent=face
end

for _,x in {-571,-376,-150,62,263,477} do
	build("Main road eastbound",x,z+width+1.2,-Vector3.xAxis)
	build("Main road westbound",x+7,z-width-1.2,Vector3.xAxis)
end
for _,p in ipairs({
	{-115,-116,-1,"Old Town"}, {-561,170,1,"North Borough"}, {-221,171,1,"Library approach"},
	{289,-110,-1,"West City"}, {427,-449,-1,"South Ring"}, {513,-143,-1,"SouthCity"},
}) do
	build(p[4],p[1],p[2],-Vector3.zAxis*p[3])
end
if old then old:Destroy() end
signs.Parent=metro
return ("Posted %d km/h at %d locations"):format(limit,#signs:GetChildren())
