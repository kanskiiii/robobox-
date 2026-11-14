-- Add the east fuel station, police station, and server-operated patrols.
local map=workspace.Map
local road=map.Road
local sourceStation=assert(map:FindFirstChild("RoadsideFuelStation"),"Install the west fuel station first")
local rs=game:GetService("ReplicatedStorage")
local shared=rs.TwoStroke
assert(shared:FindFirstChild("CityMapRouter") and shared:FindFirstChild("CityRoads"))
local server=game:GetService("ServerScriptService").TwoStrokeServer
local garage=server.GarageService
local source=garage.Source
local V,rgb,M=Vector3.new,Color3.fromRGB,Enum.Material
local paint,base,blue,glass=rgb(239,234,217),rgb(57,64,69),rgb(34,78,135),rgb(99,133,148)
local asphalt=rgb(54,57,60)
local roadY=road.Position.Y+road.Size.Y/2
local edge=road.Position.Z+road.Size.Z/2

local function part(parent,name,size,cf,color,material,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color,p.Material=name,size,cf,color,material
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid,solid,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function sign(parent,name,caption,size,cf,color)
	local p=part(parent,name,size,cf,color,M.Metal,false)
	local ui=Instance.new("SurfaceGui")
	ui.Face,ui.SizingMode,ui.CanvasSize=Enum.NormalId.Front,Enum.SurfaceGuiSizingMode.FixedSize,Vector2.new(600,math.round(600*size.Y/size.X))
	ui.LightInfluence=.26
	ui.Parent=p
	local label=Instance.new("TextLabel")
	label.Text,label.Font,label.TextColor3,label.TextScaled=caption,Enum.Font.GothamBold,paint,true
	label.Size,label.BackgroundTransparency=UDim2.fromScale(1,1),1
	label.Parent=ui
end
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"GarageService integration point changed: "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
if not source:find("PolicePatrol.start",1,true) then
	replace('local Delivery = require(script.Parent.Delivery)','local Delivery = require(script.Parent.Delivery)\nlocal PolicePatrol = require(script.Parent.PolicePatrol)')
	replace([==[	local station = deliveryMap and deliveryMap:FindFirstChild("RoadsideFuelStation")
	if station then
		for _, marker in station:GetChildren() do
			if marker.Name == "FuelPump" and marker:IsA("BasePart") then connectFuelPump(marker) end
		end
	end]==],[==[	for _, name in {"RoadsideFuelStation", "EastFuelStation"} do
		local station = deliveryMap and deliveryMap:FindFirstChild(name)
		if not station then continue end
		for _, marker in station:GetChildren() do
			if marker.Name == "FuelPump" and marker:IsA("BasePart") then connectFuelPump(marker) end
		end
	end
	PolicePatrol.start({
		sessions = sessions,
		notify = notify,
		cite = function(s: Session, reason: string)
			local fine = math.min(s.data.money, 60)
			s.data.money -= fine
			if s.driving then stopDriving(s) else sendState(s) end
			notify(s, ("Police stopped you for %s. Fine: %d zł."):format(reason, fine), "warn")
		end,
	})]==])
end
local east=sourceStation:Clone()
east.Name="EastFuelStation"
east:SetAttribute("TwoStrokePublicFuel",true)
east:PivotTo(east:GetPivot()+V(907,0,0))
-- Compact the forecourt to leave the North Borough turnoff clear.
for _,p in east:GetChildren() do
	if not p:IsA("BasePart") then continue end
	if p.Name=="Driveway" or p.Name=="Driveway edge" then
		if p.Position.X<576 then p:Destroy() else p.Position+=V(-8,0,0) end
	elseif p.Name=="Drive-through forecourt" then
		p.Size=V(34,p.Size.Y,p.Size.Z)
	elseif p.Name=="Pump island" then
		p.Size=V(17,p.Size.Y,p.Size.Z)
	elseif p.Name=="Canopy support" and p.Position.X>576 then
		p.Position-=V(3,0,0)
	elseif p.Name=="Roadside sign" or p.Name=="Roadside sign post" then
		p.Position+=V(10,0,0)
	end
end
for _,p in east:GetDescendants() do if p:IsA("ProximityPrompt") then p:Destroy() end end
sign(east,"East station sign","PALIWO WSCHÓD",V(13,1.05,.15),CFrame.new(576,4.9,edge+13),rgb(31,105,115))

local district=Instance.new("Model")
district.Name="PoliceStation"
district:SetAttribute("TwoStrokePolice",1)
local cf=CFrame.new(-93,roadY,edge+38)
local function box(name,w,h,d,x,y,z,c,m,solid)
	return part(district,name,V(w,h,d),cf*CFrame.new(x,y,z),c,m,solid)
end
box("Police forecourt",55,.25,31,0,-.125,-16,asphalt,M.Asphalt,true)
box("Flush entrance",18,.25,15,0,-.125,-31,asphalt,M.Asphalt,true)
box("Station main building",36,10.8,15,-2,5.4,6,rgb(182,184,174),M.Brick,true)
box("Dark brick plinth",36.5,.64,15.5,-2,.32,6,base,M.Concrete,true)
box("Station roof",37,.35,16,-2,10.91,6,base,M.Metal,true)
box("Patrol garage wing",14,7,14,23,3.5,5,rgb(171,175,174),M.Plaster,true)
box("Garage roof",14.7,.35,14.7,23,7.07,5,base,M.Metal,true)
box("Garage shutter",10,5.6,.23,23,2.85,-2.09,base,M.Metal,false)
for i=1,7 do box("Shutter rail",9.9,.07,.11,23,.52+i*.62,-2.23,rgb(89,99,102),M.Metal,false) end
for _,x in {-15,-7,5,11} do
	for _,y in {2.6,7.2} do
		box("Station glazing frame",3.6,2.35,.19,x,y,-1.56,base,M.Metal,false)
		box("Station glazing",3.26,2.02,.05,x,y,-1.69,glass,M.Glass,false)
	end
end
box("Front door",3.3,3.8,.22,-1,1.9,-1.67,blue,M.Metal,false)
box("Blue facade stripe",36.09,.52,.24,-2,5.25,-1.56,blue,M.Metal,false)
sign(district,"Police station sign","POLICJA",V(14,1.35,.15),cf*CFrame.new(-1,5.35,-1.79),blue)
sign(district,"Speed limit","55 km/h",V(4.6,1.0,.15),cf*CFrame.new(-13,3.12,-27),blue)
box("Speed sign post",.17,3.2,.17,-13,1.6,-26.88,base,M.Metal,true)
for _,x in {-6,6,18} do
	box("Parking stripe",.12,.018,7,x,.012,-7,paint,M.SmoothPlastic,false)
end

local function car(name,start)
	local m=Instance.new("Model")
	m.Name=name
	local function b(n,w,h,d,x,y,z,c,material)
		return part(m,n,V(w,h,d),CFrame.new(start+V(x,y,z)),c,material,false)
	end
	local chassis=b("Patrol chassis",4.4,1.05,8.6,0,.97,0,paint,M.Metal)
	m.PrimaryPart=chassis
	chassis.PivotOffset=CFrame.new(0,-.97,0)
	b("Blue beltline",4.48,.35,7.8,0,1.07,0,blue,M.Metal)
	b("Patrol cabin",3.88,1.32,4.5,0,1.98,.36,glass,M.Glass)
	b("Roof",3.95,.20,4.22,0,2.65,.34,paint,M.Metal)
	b("Light bar",3.34,.20,.41,0,2.86,.12,base,M.Metal)
	for _,side in {-1,1} do
		local emitter=b(side<0 and "BeaconLeft" or "BeaconRight",.68,.22,.37,side*.94,3.01,.12,blue,M.Glass)
		local light=Instance.new("PointLight")
		light.Enabled,light.Brightness,light.Range,light.Color=false,1.35,13,rgb(59,131,255)
		light.Parent=emitter
		b("Front lamp",.92,.36,.08,side*1.36,.98,-4.32,rgb(237,234,184),M.Glass)
		b("Tail lamp",.80,.27,.08,side*1.40,1.01,4.32,rgb(158,49,44),M.Glass)
		for _,z in {-2.5,2.5} do
			local wheel=b("Patrol tire",.45,1.47,1.47,side*2.13,.74,z,base,M.Rubber)
			wheel.Shape=Enum.PartType.Cylinder
		end
	end
	sign(m,"Rear marking","POLICJA",V(2.3,.38,.09),CFrame.new(start+V(0,1.06,4.34))*CFrame.Angles(0,math.pi,0),blue)
	return m
end
car("Central patrol",V(-93,roadY,edge+14)).Parent=district
car("South patrol",V(302,roadY,-383)).Parent=district

local policeSource=[==[
local RunService=game:GetService("RunService")
local rs=game:GetService("ReplicatedStorage")
local shared=rs:WaitForChild("TwoStroke")
local Router=require(shared.CityMapRouter)
local Police={}
local TICK=.15
local LIMIT=55
local MAX_SIGHT=92
local MAX_CHASE=48
local CATCH=11
local MIN_WHEELIE=math.sin(math.rad(16))
local function flat(p) return Vector3.new(p.X,0,p.Z) end
local function sees(officer,target,position,cone)
	local delta=flat(position-officer.pos)
	if delta.Magnitude>MAX_SIGHT then return false end
	if cone and delta.Magnitude>10 and delta.Unit:Dot(officer.heading)<.34 then return false end
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	local ignored={officer.car}
	if target.player and target.player.Character then table.insert(ignored,target.player.Character) end
	if target.riding and target.riding.model then table.insert(ignored,target.riding.model) end
	params.FilterDescendantsInstances=ignored
	local from=officer.pos+Vector3.yAxis*2.8
	return not workspace:Raycast(from,position+Vector3.yAxis*.4-from,params)
end
local function chasePath(officer,cells,target)
	local points=Router.route(cells,officer.pos,target)
	if not points then return end
	local route={}
	for i=#points,1,-1 do table.insert(route,Vector3.new(points[i].X,officer.pos.Y,points[i].Y)) end
	officer.path,officer.index=route,1
end
local function beacons(officer,flash)
	for i,name in ipairs({"BeaconLeft","BeaconRight"}) do
		local lens=officer.car[name]
		local lit=officer.target~=nil and (flash+i)%2==0
		lens.Material=lit and Enum.Material.Neon or Enum.Material.Glass
		lens.PointLight.Enabled=lit
	end
end
local function move(officer,goal,travel)
	local d=flat(goal-officer.pos)
	if d.Magnitude < .05 then return true end
	officer.heading=d.Unit
	officer.pos+=officer.heading*math.min(travel,d.Magnitude)
	officer.car:PivotTo(CFrame.lookAlong(officer.pos,officer.heading))
	return d.Magnitude<=travel
end
function Police.start(api)
	local map=workspace:FindFirstChild("Map")
	local station=api.station or (map and map:FindFirstChild("PoliceStation"))
	if not station then return end
	local roads=require(shared.CityRoads)
	local cells=Router.new(roads)
	local y=(map and map.Road.Position.Y+map.Road.Size.Y/2) or .5
	local mainZ=map.Road.Position.Z
	local function point(x,z) return Vector3.new(x,y,z) end
	local circuits={
		["Central patrol"]={point(-93,mainZ+6),point(-548,mainZ+6),point(-548,246),point(-208,246),point(-208,mainZ-5),point(510,mainZ-5),point(510,mainZ+5),point(-93,mainZ+5)},
		["South patrol"]={point(302,-386),point(302,-82),point(526,-82),point(526,-500),point(180,-500),point(180,-386),point(302,-386)},
	}
	local officers={}
	for name,waypoints in pairs(circuits) do
		local car=station:FindFirstChild(name)
		if car and car:IsA("Model") and car.PrimaryPart then
			table.insert(officers,{car=car,pos=car:GetPivot().Position,heading=Vector3.new(0,0,-1),index=1,waypoints=waypoints,patrol=1})
		end
	end
	local wanted,previous,cooldown={},{},{}
	local elapsed,step=0,0
	local time=0
	local function clear(officer,latest)
		if officer.target then wanted[officer.target]=nil end
		officer.target,officer.path=nil,nil
		chasePath(officer,cells,latest)
	end
	return RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt
		if elapsed<TICK then return end
		time+=elapsed
		local interval=elapsed
		elapsed=0
		step+=1
		local riding={}
		for player,s in pairs(api.sessions) do
			local ride=s.driving and s.riding
			local root=ride and ride.model.PrimaryPart
			if root then
				local prior=previous[player]
				local shift=prior and flat(root.Position-prior).Magnitude
				local speed=shift and shift<65 and shift/interval*1.008 or 0
				riding[player]={root=root,s=s,speed=speed}
				previous[player]=root.Position
			else previous[player]=nil end
		end
		for player in pairs(cooldown) do if not api.sessions[player] then cooldown[player]=nil;previous[player]=nil end end
		for _,o in officers do
			local target=o.target
			if target then
				local s=api.sessions[target]
				local rider=riding[target]
				local root=rider and rider.root or s and s.player.Character and s.player.Character:FindFirstChild("HumanoidRootPart")
				if not root or time-o.start>MAX_CHASE or flat(root.Position-o.pos).Magnitude>155 then
					if s then api.notify(s,"You lost the police patrol.","info") end
					cooldown[target]=time+6
					clear(o,o.waypoints[o.patrol])
				elseif flat(root.Position-o.pos).Magnitude<CATCH and sees(o,s,root.Position,false) then
					cooldown[target]=time+12
					api.cite(s,o.reason)
					clear(o,o.waypoints[o.patrol])
				elseif time>=o.nextPath then
					o.nextPath=time+.9
					chasePath(o,cells,root.Position)
				end
			else
				for player,r in pairs(riding) do
					if wanted[player] or (cooldown[player] or 0)>time then continue end
					local root=r.root
					local violation=if r.speed>LIMIT then "speeding" elseif r.speed>8 and root.CFrame.LookVector.Y>MIN_WHEELIE then "a wheelie" else nil
					if violation and sees(o,r.s,root.Position,true) then
						if o.observed==player and o.offense==violation and time-(o.lastSeen or 0)<=interval+.025 then
							o.observedTime+=interval
						else
							o.observed,o.offense,o.observedTime=player,violation,0
						end
						o.lastSeen=time
						if o.observedTime>=.45 then
							o.target,o.reason,o.start,o.nextPath=player,violation,time,time
							wanted[player]=o
							o.observed=nil
							api.notify(r.s, "POLICE · Pull over. Patrol saw "..violation..".", "warn")
						end
						break
					elseif o.observed==player then
						o.observed=nil
					end
				end
			end
			if o.path then
				local goal=o.path[o.index]
				if goal and move(o,goal,(o.target and 62 or 28)*interval) then
					o.index+=1
				elseif not goal then
					o.path=nil
					if not o.target then o.patrol=o.patrol%#o.waypoints+1 end
				end
			elseif not o.target then
				if move(o,o.waypoints[o.patrol],28*interval) then o.patrol=o.patrol%#o.waypoints+1 end
			end
			o.car:SetAttribute("Pursuing",o.target~=nil)
			beacons(o,step)
		end
	end)
end
return Police
]==]
local module=server:FindFirstChild("PolicePatrol") or Instance.new("ModuleScript")
assert(module:IsA("ModuleScript"))
module.Name,module.Source="PolicePatrol",policeSource
module.Parent=server
for _,model in {east,district} do
	local old=map:FindFirstChild(model.Name)
	if old then old:Destroy() end
	model.Parent=map
end
garage.Source=source

-- Add the destinations and their connectors to the existing phone street chart.
local cityMap=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient.CityMap
local cityRoads=shared.CityRoads
local chart=cityMap.Source
if not chart:find('"East Gas Station"',1,true) then
	local start,finish=assert(chart:find("local pins = %b{}"))
	local pins=chart:sub(start,finish-1)
	chart=chart:sub(1,start-1)..pins..(',\n{"F","West Gas Station",-331,%.2f},\n{"E","East Gas Station",576,%.2f},\n{"P","Police Station",-93,%.2f}\n}'):format(edge+19,edge+19,edge+11)..chart:sub(finish+1)
	chart=chart:gsub("Size=UDim2.fromOffset%(21,21%)","Size=UDim2.fromOffset(17,17)")
	cityMap.Source=chart
end
if not cityRoads.Source:find("-- Public services",1,true) then
	local roadData=cityRoads.Source:match("return (%b{})")
	if roadData then
		local extra={}
		for _,model in {sourceStation,east,district} do
			for _,p in model:GetChildren() do
				if p:IsA("BasePart") and p.Material==M.Asphalt then
					table.insert(extra,("{%.2f,%.2f,%.2f,%.2f,0}"):format(p.Position.X,p.Position.Z,p.Size.X,p.Size.Z))
				end
			end
		end
		cityRoads.Source="return "..roadData:sub(1,-2)..",\n-- Public services\n"..table.concat(extra,",\n").."\n}"
	end
end
return "Installed the east gas station, police station and two patrols."
