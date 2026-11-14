-- Add road-facing delivery bays and named customer drop markers in Studio Edit mode.
local map = assert(workspace:FindFirstChild("Map"))
local farm = assert(map:FindFirstChild("EastFarmLane"), "Install East Farm Lane first")
local road = map.Road
local v, rgb = Vector3.new, Color3.fromRGB
local M = Enum.Material
local roadY = road.Position.Y + road.Size.Y / 2
local edge = road.Position.Z + road.Size.Z / 2
local folder = map:FindFirstChild("DeliveryDrops")
assert(not folder or folder:IsA("Folder"), "An unrelated instance uses the DeliveryDrops name")
local scenery = Instance.new("Model")
scenery.Name = "SignedDeliveryBays"
scenery:SetAttribute("TwoStrokeMapVersion", 1)
local pending = {}

local function make(parent, name, size, position, material, color, solid)
	local item = Instance.new("Part")
	item.Name, item.Size, item.Position = name, size, position
	item.Material, item.Color = material, color
	item.Anchored = true
	item.CanCollide, item.CanQuery, item.CanTouch = solid, solid, false
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function drop(name, x, z, farmDrive)
	local group = Instance.new("Model")
	group.Name = name
	group.Parent = scenery
	if not farmDrive then
		make(group,"Asphalt pull-off",v(19,.22,10),v(x,roadY-.11,z-1.5),M.Asphalt,rgb(63,65,63),true)
		for _, side in ipairs({-1,1}) do
			make(group,"Bay edge",v(.15,.015,7.5),v(x+side*7.2,roadY+.01,z-1),M.SmoothPlastic,rgb(220,213,189),false)
		end
	end
	local line = z + (if farmDrive then 5.2 else 4.1)
	make(group,"Mailbox post",v(.23,2.15,.24),v(x-4.5,roadY+1.07,line),M.Wood,rgb(107,87,61),true)
	make(group,"Mailbox",v(1.12,.75,.78),v(x-4.5,roadY+2.16,line),M.Metal,rgb(69,88,78),true)
	make(group,"Mailbox red flag",v(.085,.48,.25),v(x-3.91,roadY+2.44,line),M.Metal,rgb(180,61,50),false)
	local board=make(group,"Street address",v(4.8,1.05,.15),v(x+2,roadY+2.1,line),M.Wood,rgb(65,80,70),false)
	make(group,"Address post",v(.21,2.18,.21),v(x+2,roadY+1.09,line+.14),M.Wood,rgb(108,83,60),true)
	local ui=Instance.new("SurfaceGui")
	ui.Face=Enum.NormalId.Front
	ui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
	ui.CanvasSize=Vector2.new(410,95)
	ui.LightInfluence=.5
	ui.Parent=board
	local text=Instance.new("TextLabel")
	text.Size=UDim2.fromScale(.96,1)
	text.Position=UDim2.fromScale(.02,0)
	text.Text=name
	text.TextColor3=rgb(244,237,219)
	text.TextScaled=true
	text.BackgroundTransparency=1
	text.Font=Enum.Font.GothamMedium
	text.Parent=ui
	local marker=make(nil,"Codex_"..name,v(.55,.18,.55),v(x,roadY+.09,z),M.SmoothPlastic,rgb(255,255,255),false)
	marker.Transparency=1
	marker:SetAttribute("Street", name)
	marker:SetAttribute("SignedDeliveryBay", true)
	table.insert(pending,marker)
end

drop("ul. Polna 12",road.Position.X+438,edge+81,true)
drop("ul. Lipowa 28",road.Position.X-205,edge+3,false)
drop("ul. Kolejowa 6",road.Position.X-461,edge+3,false)
drop("ul. Ogrodowa 17",road.Position.X+306,edge+3,false)

local prev=map:FindFirstChild(scenery.Name)
assert(not prev or prev:GetAttribute("TwoStrokeMapVersion"), "Unrelated delivery scenery already uses this name")
if not folder then
	folder=Instance.new("Folder")
	folder.Name="DeliveryDrops"
	folder.Parent=map
end
for _,existing in ipairs(folder:GetChildren()) do
	if existing:GetAttribute("SignedDeliveryBay") then existing:Destroy() end
end
if prev then prev:Destroy() end
scenery.Parent=map
for _,marker in ipairs(pending) do marker.Parent=folder end
return "Installed four signed delivery destinations"
