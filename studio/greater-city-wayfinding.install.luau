-- Roadside direction signs for the expanded city. Run in Studio Edit.
local map=workspace.Map
local metro=assert(map:FindFirstChild("Greater City"))
local road=map.Road
local roadZ=road.Position.Z
local kerb=road.Size.Z/2
local V,rgb,M=Vector3.new,Color3.fromRGB,Enum.Material
local layer=Instance.new("Model")
layer.Name="City direction signs"
layer:SetAttribute("TwoStrokeWayfinding",true)
local old=metro:FindFirstChild(layer.Name)
assert(not old or old:GetAttribute("TwoStrokeWayfinding"))
local ink,white,steel=rgb(35,82,84),rgb(249,240,207),rgb(104,118,118)
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances=old and {old} or {}

local function piece(group,name,size,cf,col,mat,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material=name,size,cf,col,mat
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=group
	return p
end
local function board(name,x,z,delta,caption,turn,color)
	local ground=assert(workspace:Raycast(V(x,2.1,z),V(0,-5,0),params),"No ground for "..name)
	assert(ground.Material~=M.Asphalt,"Sign post would sit on asphalt: "..name)
	local model=Instance.new("Model")
	model.Name,model.Parent=name,layer
	local base=CFrame.lookAlong(V(x,ground.Position.Y,z),delta)
	local width=math.max(7,#caption*.31+2.2)
	for _,dx in {-width*.29,width*.29} do
		piece(model,"Galvanized sign post",V(.16,4.5,.16),base*CFrame.new(dx,2.25,0),steel,M.Metal,true)
		piece(model,"Post anchor",V(.35,.10,.35),base*CFrame.new(dx,.05,0),rgb(126,124,114),M.Concrete,true)
	end
	local panel=piece(model,"Directional panel",V(width,1.55,.18),base*CFrame.new(0,4.25,-.12),color or ink,M.Metal,false)
	local gui=Instance.new("SurfaceGui")
	gui.Face,gui.SizingMode,gui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(720,135)
	gui.LightInfluence=.2
	gui.Parent=panel
	local edge=Instance.new("Frame")
	edge.Position,edge.Size=UDim2.fromScale(.025,.08),UDim2.fromScale(.95,.84)
	edge.BackgroundTransparency=1
	edge.Parent=gui
	local border=Instance.new("UIStroke")
	border.Color,border.Thickness=white,4
	border.Parent=edge
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,10)
	corner.Parent=edge
	local t=Instance.new("TextLabel")
	t.Text,t.TextColor3,t.TextScaled,t.Font=caption,white,true,Enum.Font.GothamBold
	t.Size,t.Position,t.BackgroundTransparency=UDim2.fromScale(.74,.68),UDim2.fromScale(.065,.16),1
	t.Parent=gui
	local a=t:Clone()
	a.Name,a.Text,a.Size,a.Position="Turn",turn,UDim2.fromScale(.13,.70),UDim2.fromScale(.79,.15)
	a.Parent=gui
end

-- Main-road approach signs are offset from the junction, visible in both directions.
local upper,lower=roadZ+kerb+2.9,roadZ-kerb-2.9
local entries={
	{-128,"STARE MIASTO",false},
	{-38,"DZIELNICA PÓŁNOCNA",true},
	{18,"DWORZEC CENTRALNY",true},
	{224,"WARSZTAT MOTOCYKLOWY",false,rgb(64,75,118)},
	{302,"CENTRUM",false},
	{390,"UL. POLNA",true},
}
for _,entry in ipairs(entries) do
	local x,name,onNorth,color=table.unpack(entry)
	-- Both sides point toward the same destination from the traveler's perspective.
	board(name.." eastbound",x-15,upper,-Vector3.xAxis,name,onNorth and "→" or "←",color)
	board(name.." westbound",x+15,lower,Vector3.xAxis,name,onNorth and "←" or "→",color)
end

local function yardBoard(name,x,z,face,title,turn)
	board(name,x,z,face,title,turn,rgb(62,78,112))
end
yardBoard("Workshop exit to main road",206,36,-Vector3.zAxis,"DROGA GŁÓWNA","↑")
yardBoard("Workshop exit to city",269,33,-Vector3.xAxis,"CENTRUM","↑")
yardBoard("Workshop forecourt fuel",249,8,-Vector3.zAxis,"PALIWO","→")

if old then old:Destroy() end
layer.Parent=metro
return string.format("%d directional signs installed",#layer:GetChildren())
