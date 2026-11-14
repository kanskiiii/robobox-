-- Place Verity decorations and a town scooter display in Studio Edit mode.
local map=workspace.Map
local town=assert(map:FindFirstChild("SouthTown"))
local source=assert(map:FindFirstChild("Dualtron Stand")):FindFirstChild("Yard Scooter Display")
local shelf=map["Dualtron Stand"]:FindFirstChild("WallShelf")
local V=Vector3.new
local rgb=Color3.fromRGB
local y=map.Ground.Position.Y+map.Ground.Size.Y/2
local folder=Instance.new("Model")
folder.Name="VerityDecorations"
folder:SetAttribute("TwoStrokeMapVersion",1)

local function part(parent,name,shape,size,pose,color)
	local p=Instance.new("Part")
	p.Name,p.Shape,p.Size,p.CFrame,p.Color=name,shape,size,pose,color
	p.Material=Enum.Material.SmoothPlastic
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,false,false,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function verity(name,x,z,base,r,view)
	local m=Instance.new("Model")
	m.Name=name
	local pivot=CFrame.new(x,base+r,z)*CFrame.Angles(0,view,0)
	local ball=part(m,"Yellow sphere",Enum.PartType.Ball,V(2*r,2*r,2*r),pivot,rgb(255,213,0))
	m.PrimaryPart=ball
	local function surface(u,v,offset)
		return V(u*r,v*r,-math.sqrt(1-u*u-v*v)*r-offset*r)
	end
	local black=rgb(18,15,7)
	for _,side in {-1,1} do
		local eye=surface(side*.285,.225,.002)
		part(m,"Oval eye",Enum.PartType.Ball,V(.186*r,.35*r,.053*r),
			pivot*CFrame.lookAt(eye,eye+eye.Unit),black)
	end
	local function line(a,b)
		part(m,"Smile stroke",Enum.PartType.Cylinder,V((a-b).Magnitude+.018*r,.064*r,.064*r),
			pivot*CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),black).CastShadow=false
	end
	for i=0,15 do
		local a=-.66+1.32*i/16
		local b=-.66+1.32*(i+1)/16
		line(surface(a,-.49+.90*a*a,.007),surface(b,-.49+.90*b*b,.007))
	end
	for _,u in {-.66,.66} do
		local p=surface(u,-.49+.90*u*u,.009)
		part(m,"Smile dimple",Enum.PartType.Ball,V(.102*r,.096*r,.08*r),pivot*CFrame.new(p),black).CastShadow=false
	end
	m.Parent=folder
end
-- Exactly one sits inside the garage, left of the opening, clear of the order drop at (-5,7).
verity("Garage Verity",-7.9,2.6,.70,.64,math.pi)
verity("Yard Verity",13,13,.67,1.18,math.pi)
verity("Loop Entrance Verity",-60,70,y,2.1,-math.pi/2)
verity("Loop Fence Verity",-175,54,y,1.55,0)
verity("Brake Zone Verity",-180,-40,y,1.78,math.pi)
verity("Shelter Verity",-96,112,y,1.28,0)
verity("Farm Junction Verity",376,112,y,1.65,0)
verity("Farm Lane Verity",418,178,y,1.3,0)
verity("Farm Drive Verity",450,190,y,1.5,0)
verity("Town Welcome Verity",317,70,y,2.1,math.pi)
verity("Market Verity",432,-44,y,3.4,math.pi/2)
verity("Market Garden Verity",430,-49,y,.94,math.pi/2)
verity("Town Green Verity",442,-37,y,1.2,-math.pi/2)
verity("South Block Verity",377,-97,y,1.5,math.pi)
verity("East Block Verity",510,-32,y,1.55,-math.pi/2)
verity("Garden Verity",457,-96,y,1.15,math.pi)

local kiosk=Instance.new("Model")
kiosk.Name="Dualtron town display"
kiosk.Parent=folder
local display=assert(source):Clone()
display.Parent=kiosk
local function static(model)
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored=true
			p.CanCollide,p.CanTouch,p.CanQuery=false,false,false
		elseif p:IsA("LuaSourceContainer") or p:IsA("ProximityPrompt") or p:IsA("ClickDetector") then
			p:Destroy()
		end
	end
end
static(display)
local function place(model,x,z,floor,rotation)
	model:PivotTo(CFrame.new(x,floor,z)*CFrame.Angles(0,rotation,0))
	local box,size=model:GetBoundingBox()
	model:PivotTo(model:GetPivot()+V(x-box.X,floor-(box.Y-size.Y/2),z-box.Z))
end
local plinth=part(kiosk,"Scooter display plinth",Enum.PartType.Block,V(8,.45,5.6),
	CFrame.new(399,y+.225,-36),rgb(118,115,107))
plinth.Material=Enum.Material.Concrete
plinth.CanCollide=true
plinth.CanQuery=true
place(display,399,-36,y+.45,math.pi/2)
local shopShelf=assert(shelf):Clone()
shopShelf.Parent=kiosk
static(shopShelf)
place(shopShelf,394.2,-36,y,0)

local ss=game:GetService("ServerStorage")
local review=ss:FindFirstChild("_TownPropReview")
local bench=review and review:FindFirstChild("Park Bench")
if bench then
	-- Retain only passive geometry from the free Creator Store model.
	local clean=Instance.new("Model")
	clean.Name="Market benches"
	clean:SetAttribute("CreatorStoreAssetId",393609716)
	for _,p in bench:GetDescendants() do
		if p.ClassName=="Part" then
			local copy=Instance.new("Part")
			copy.Name,copy.Size,copy.CFrame=p.Name,p.Size,p.CFrame
			copy.Color,copy.Material,copy.Shape=p.Color,p.Material,p.Shape
			copy.Anchored=true
			copy.CanCollide,copy.CanQuery,copy.CanTouch=false,false,false
			copy.Parent=clean
		end
	end
	if #clean:GetChildren()>0 then
		clean.Parent=kiosk
		if clean:GetScale()~=1 then clean:ScaleTo(1) end
		clean:ScaleTo(.76)
		place(clean,440,-48,y,math.pi*.5)
	end
else
	local previous=map:FindFirstChild(folder.Name)
	local imported=previous and previous:FindFirstChild("Market benches",true)
	if imported then imported:Clone().Parent=kiosk end
end

local previous=map:FindFirstChild(folder.Name)
assert(not previous or previous:GetAttribute("TwoStrokeMapVersion"))
if previous then previous:Destroy() end
folder.Parent=map
if review then review:Destroy() end
return tostring(#folder:GetChildren()-1).." Verity models and one Dualtron display installed"
