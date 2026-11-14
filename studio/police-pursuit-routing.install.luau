-- Keep the patrol's movement budget across waypoints and avoid stale pursuit paths.
local module=game:GetService("ServerScriptService").TwoStrokeServer.PolicePatrol
local source=module.Source
if source:find("local function followPath",1,true) then return "Patrol route update already installed" end
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"PolicePatrol integration point changed: "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
replace([==[	local points=Router.route(cells,officer.pos,target)
	if not points then return end]==],[==[	local points=Router.route(cells,officer.pos,target)
	if not points then
		officer.path=nil
		return
	end]==])
replace([==[	if d.Magnitude < .05 then return true end
	officer.heading=d.Unit
	officer.pos+=officer.heading*math.min(travel,d.Magnitude)
	officer.car:PivotTo(CFrame.lookAlong(officer.pos,officer.heading))
	return d.Magnitude<=travel
end]==],[==[	local distance=d.Magnitude
	if distance<.01 then return true,0 end
	local moved=math.min(travel,distance)
	officer.heading=d.Unit
	officer.pos+=officer.heading*moved
	return moved>=distance,moved
end
local function followPath(officer,remaining)
	while remaining>0 do
		local goal=officer.path[officer.index]
		if not goal then
			officer.path=nil
			if not officer.target then officer.patrol=officer.patrol%#officer.waypoints+1 end
			return
		end
		local arrived,moved=move(officer,goal,remaining)
		if not arrived then return end
		remaining-=moved
		officer.index+=1
	end
end]==])
replace("officer.stoppedSince=nil","officer.stoppedSince=nil\n\t\tofficer.lastDestination=nil")
replace([==[				elseif time>=o.nextPath then
					o.nextPath=time+.9
					chasePath(o,cells,root.Position)
				end]==],[==[				elseif time>=o.nextPath then
					local destination=root.Position
					if not o.path or not o.lastDestination or flat(destination-o.lastDestination).Magnitude>=9 then
						o.lastDestination=destination
						chasePath(o,cells,destination)
					end
					o.nextPath=time+.55
				end]==])
replace([==[			if o.path then
				local goal=o.path[o.index]
				if goal and move(o,goal,(o.target and 62 or 28)*interval) then
					o.index+=1
				elseif not goal then
					o.path=nil
					if not o.target then o.patrol=o.patrol%#o.waypoints+1 end
				end
			elseif not o.target then
				if move(o,o.waypoints[o.patrol],28*interval) then o.patrol=o.patrol%#o.waypoints+1 end
			end]==],[==[			local before=o.pos
			if o.path then
				followPath(o,(o.target and 62 or 28)*interval)
			elseif not o.target then
				if move(o,o.waypoints[o.patrol],28*interval) then o.patrol=o.patrol%#o.waypoints+1 end
			end
			if o.pos~=before then o.car:PivotTo(CFrame.lookAlong(o.pos,o.heading)) end]==])
module.Source=source
return "Improved pursuit turns and rerouting."
