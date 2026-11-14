-- Install the SM50 side stand and replace the garage's carryable lift stand.
local assets = game:GetService("ReplicatedStorage").Assets
local parts, frame = assets.Parts, assets.Vehicles.sm50.Frame
local service = game:GetService("ServerScriptService").TwoStrokeServer.GarageService
local stand = assert(workspace.Map:FindFirstChild("MotorcycleStand", true))
assert(stand:IsA("Model"))
local v, rgb = Vector3.new, Color3.fromRGB
local steel, rubber = Enum.Material.Metal, Enum.Material.Rubber
local dark, edge, zinc = rgb(39,43,48), rgb(67,71,75), rgb(148,155,157)
local yellow = rgb(227,164,36)
local kick = Instance.new("Model")
kick.Name = "Kickstand_sm50"

local function piece(model, name, size, at, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, at
	p.Color, p.Material = color, material
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Massless = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = model
	return p
end

local function tube(model, name, a, b, diameter, color, material)
	return piece(model,name,v((b-a).Magnitude,diameter,diameter),
		CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,material,Enum.PartType.Cylinder)
end

local hinge = v(-.43,-.80,.47)
local lean = math.rad(9)
local footX, footZ = -.43,.21
local floorY = -(.55 / .28) * math.cos(lean)
local footY = (floorY - (hinge.X + footX)*math.sin(lean))/math.cos(lean) - hinge.Y
local bottom = v(footX,footY,footZ)
local pad = CFrame.new(bottom)*CFrame.Angles(0,0,-lean)
local center = pad*CFrame.new(0,.031,0)
local root = tube(kick,"Hinge sleeve",v(-.073,0,0),v(.064,0,0),.17,dark,steel)
root.PivotOffset = root.CFrame:Inverse()
kick.PrimaryPart = root
local bend = v(-.20,-.56,.095)
local endpoint = pad:PointToWorldSpace(v(0,.06,0))
tube(kick,"Forged upper leg",v(0,-.04,0),bend,.107,dark,steel)
tube(kick,"Tapered lower leg",bend,endpoint,.084,dark,steel)
tube(kick,"Worn outer rib",bend+v(-.022,-.02,.012),endpoint+v(-.016,.034,.011),.034,edge,steel)
piece(kick,"Stamped foot pad",v(.26,.062,.19),center,dark,steel)
for i=-1,1 do
	piece(kick,"Raised pad rib",v(.207,.017,.022),pad*CFrame.new(0,.066,i*.043),edge,steel)
end
tube(kick,"Pivot pin",v(-.117,0,0),v(.083,0,0),.072,zinc,steel)
tube(kick,"Pivot washer",v(-.087,0,0),v(-.07,0,0),.126,zinc,steel)
local tangA = bend:Lerp(endpoint,.35)
local tangB = tangA+v(-.152,-.038,.088)
tube(kick,"Deploy tang",tangA,tangB,.056,dark,steel)
tube(kick,"Tang tip",tangB,tangB+v(-.036,.003,.018),.070,edge,steel)
local springA, springB = v(-.069,.033,.098), v(-.162,-.43,.094)
local springAxis = (springB-springA).Unit
local span = springAxis:Cross(Vector3.zAxis).Unit*.032
local span2 = springAxis:Cross(span).Unit*.032
local function coil(t)
	local angle=t*math.pi*18
	return springA:Lerp(springB,t)+span*math.cos(angle)+span2*math.sin(angle)
end
for i=0,35 do tube(kick,"Spring winding",coil(i/36),coil((i+1)/36),.022,zinc,steel) end
tube(kick,"Spring hook",springA,coil(0),.021,zinc,steel)
tube(kick,"Spring hook",coil(1),springB,.021,zinc,steel)
local contact = Instance.new("Attachment")
contact.Name = "Foot"
contact.Position = root.CFrame:PointToObjectSpace(bottom)
contact.Parent = root
for _, p in ipairs(kick:GetChildren()) do
	if p~=root then
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = root,p
		w.C0 = root.CFrame:ToObjectSpace(p.CFrame)
		w.Parent = p
	end
	p.Anchored = false
end

local staged = Instance.new("Model")
local origin
if stand:GetAttribute("TwoStrokeStandVersion") then
	origin = stand:GetPivot()
else
	local box, size = stand:GetBoundingBox()
	origin = CFrame.new(box.Position-Vector3.yAxis*size.Y/2)
end
local deck = piece(staged,"Rubber lift saddle",v(1.14,.17,1.35),origin*CFrame.new(0,1.00,0),rgb(42,42,43),rubber)
local rest = Instance.new("Attachment")
rest.Name = "BikeRest"
rest.Position = v(0,.085,0)
rest.Parent = deck
for i=-3,3 do
	piece(staged,"Saddle tread",v(1.02,.018,.054),origin*CFrame.new(0,1.087,i*.173),rgb(53,53,51),rubber)
end
for _, sign in ipairs({-1,1}) do
	local x = .63*sign
	tube(staged,"Powder-coated base runner",origin:PointToWorldSpace(v(x,.18,-.84)),
		origin:PointToWorldSpace(v(x,.18,.84)),.16,yellow,steel)
	for _, z in ipairs({-.44,.44}) do
		tube(staged,"Welded lift upright",origin:PointToWorldSpace(v(x,.20,z)),
			origin:PointToWorldSpace(v(sign*.46,.90,z*.75)),.13,yellow,steel)
	end
	local pos = v(x,.136,.79)
	tube(staged,"Transport wheel",origin:PointToWorldSpace(pos-v(.094,0,0)),
		origin:PointToWorldSpace(pos+v(.094,0,0)),.27,dark,rubber)
	tube(staged,"Wheel hub",origin:PointToWorldSpace(pos-v(.104,0,0)),
		origin:PointToWorldSpace(pos+v(.104,0,0)),.105,zinc,steel)
	piece(staged,"Front rubber skid",v(.26,.105,.32),origin*CFrame.new(x,.0525,-.73),dark,rubber)
end
for _,z in ipairs({-.56,.62}) do
	tube(staged,"Reinforced crossmember",origin:PointToWorldSpace(v(-.62,.25,z)),
		origin:PointToWorldSpace(v(.62,.25,z)),.133,yellow,steel)
end
tube(staged,"Carry handle",origin:PointToWorldSpace(v(-.62,.30,.88)),
	origin:PointToWorldSpace(v(.62,.30,.88)),.14,yellow,steel)
tube(staged,"Carry handle grip",origin:PointToWorldSpace(v(-.29,.30,.88)),
	origin:PointToWorldSpace(v(.29,.30,.88)),.164,dark,rubber)

local before = service.Source
local first = assert(before:find("local function kickstand(model: Model, down: boolean)",1,true))
local insertion = [==[
	local frame = model:FindFirstChild("Frame")
	local mount = frame and frame:FindFirstChild("Mount_Kickstand")
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local library = assets and assets:FindFirstChild("Parts")
	local template = library and library:FindFirstChild("Kickstand_sm50")
	if mount and mount:IsA("Attachment") and template and template:IsA("Model") then
		local assembly = model:FindFirstChild("Kickstand")
		if not assembly then
			local clone = template:Clone()
			clone.Name = "Kickstand"
			local main = assert(clone.PrimaryPart)
			local hinge = Instance.new("Weld")
			hinge.Name = "StandHinge"
			hinge.Part0, hinge.Part1 = root, main
			hinge.C1 = main.PivotOffset
			local angle = (mount:GetAttribute(if down then "DeployedAngle" else "StowedAngle") :: number?) or 0
			local hingeFrame = root.CFrame:ToObjectSpace(mount.WorldCFrame) * CFrame.Angles(math.rad(angle),0,0)
			clone:PivotTo(root.CFrame * hingeFrame)
			hinge.C0 = hingeFrame
			hinge.Parent = main
			clone.Parent = model
			assembly = clone
		end
		if assembly:IsA("Model") and assembly.PrimaryPart then
			local hinge = assembly.PrimaryPart:FindFirstChild("StandHinge")
			if hinge and hinge:IsA("Weld") then
				local angle = (mount:GetAttribute(if down then "DeployedAngle" else "StowedAngle") :: number?) or 0
				hinge.C0 = root.CFrame:ToObjectSpace(mount.WorldCFrame) * CFrame.Angles(math.rad(angle),0,0)
			end
		end
		return
	end
]==]
local candidate = before
if not before:find('local template = library and library:FindFirstChild("Kickstand_sm50")',1,true) then
	local spot=assert(before:find('	local leg = model:FindFirstChild("Kickstand")',first,true))
	candidate=before:sub(1,spot-1)..insertion..before:sub(spot)
end
local standPrep = "	st.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)) * cf.Rotation"
local preserve = "	if not st:GetAttribute(\"TwoStrokeStandVersion\") then\n"..standPrep.."\n	end"
if not candidate:find(preserve, 1, true) then
	local p,q=assert(candidate:find(standPrep,1,true))
	candidate=candidate:sub(1,p-1)..preserve..candidate:sub(q+1)
end

local previous = parts:FindFirstChild(kick.Name)
assert(not previous or previous:GetAttribute("TwoStrokeStandVersion"), "Existing kickstand asset needs review")
local mount = frame:FindFirstChild("Mount_Kickstand") or Instance.new("Attachment")
assert(mount:IsA("Attachment"))
mount.Name = "Mount_Kickstand"
mount.CFrame = frame.CFrame:ToObjectSpace(frame:GetPivot()*CFrame.new(hinge))
mount:SetAttribute("DeployedAngle",0)
mount:SetAttribute("StowedAngle",-92)
mount.Parent = frame
if previous then previous:Destroy() end
kick:SetAttribute("TwoStrokeStandVersion",1)
kick.Parent = parts
stand.PrimaryPart = nil
stand:ClearAllChildren()
for _, p in ipairs(staged:GetChildren()) do p.Parent = stand end
stand.PrimaryPart = deck
deck.PivotOffset = deck.CFrame:ToObjectSpace(origin)
stand:SetAttribute("TwoStrokeStandVersion",1)
stand:SetAttribute("Prepared",nil)
staged:Destroy()
service.Source = candidate
return "Installed SM50 sidestand and garage paddock stand"
