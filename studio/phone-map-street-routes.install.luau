-- Add routing on top of the phone's existing baked street map.
local client=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local map=client.CityMap
local source=map.Source
local function change(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"CityMap integration point changed: "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end

local router=[==[
-- Rasterize road rectangles at six-stud intervals. Keep the route on connected
-- pavement and use the exact delivery position for its existing destination dot.
local Router={}
local STEP=6
local STRIDE=512
local SHIFT=256
local function key(x,z)
	return (z+SHIFT)*STRIDE+x+SHIFT
end
local function unpackCell(k)
	return k%STRIDE-SHIFT,math.floor(k/STRIDE)-SHIFT
end

function Router.new(roads)
	local cells={}
	for _,r in ipairs(roads) do
		local cx,cz,w,d,yaw=table.unpack(r)
		local cosine,sine=math.cos(yaw),math.sin(yaw)
		local halfX,halfZ=w/2,d/2
		local extentX,extentZ=math.abs(cosine)*halfX+math.abs(sine)*halfZ,
			math.abs(sine)*halfX+math.abs(cosine)*halfZ
		for x=math.ceil((cx-extentX)/STEP),math.floor((cx+extentX)/STEP) do
			for z=math.ceil((cz-extentZ)/STEP),math.floor((cz+extentZ)/STEP) do
				local dx,dz=x*STEP-cx,z*STEP-cz
				if math.abs(cosine*dx-sine*dz)<=halfX+.12
					and math.abs(sine*dx+cosine*dz)<=halfZ+.12 then
					cells[key(x,z)]=true
				end
			end
		end
	end
	return cells
end
local function nearest(cells,position,radius)
	local ix,iz=math.round(position.X/STEP),math.round(position.Z/STEP)
	local distance=radius*radius
	local result
	local limit=math.ceil(radius/STEP)
	for z=iz-limit,iz+limit do
		for x=ix-limit,ix+limit do
			local k=key(x,z)
			if cells[k] then
				local dx,dz=x*STEP-position.X,z*STEP-position.Z
				local d=dx*dx+dz*dz
				if d<distance then result,distance=k,d end
			end
		end
	end
	return result
end

local function push(heap,value)
	local i=#heap+1
	while i>1 do
		local parent=math.floor(i/2)
		if heap[parent].score<=value.score then break end
		heap[i]=heap[parent]
		i=parent
	end
	heap[i]=value
end
local function pop(heap)
	local top=heap[1]
	local last=table.remove(heap)
	if #heap==0 then return top end
	local i=1
	while i*2<=#heap do
		local child=i*2
		if heap[child+1] and heap[child+1].score<heap[child].score then child+=1 end
		if heap[child].score>=last.score then break end
		heap[i]=heap[child]
		i=child
	end
	heap[i]=last
	return top
end
local directions={{1,0,1},{-1,0,1},{0,1,1},{0,-1,1},{1,1,1.4142},{-1,1,1.4142},{1,-1,1.4142},{-1,-1,1.4142}}

function Router.route(cells,origin,destination)
	local start,goal=nearest(cells,origin,100),nearest(cells,destination,85)
	if not start or not goal then return end
	local gx,gz=unpackCell(goal)
	local function heuristic(x,z)
		local a,b=math.abs(gx-x),math.abs(gz-z)
		return math.max(a,b)+.4142*math.min(a,b)
	end
	local queue,cost,previous={{cell=start,score=0,cost=0}},{[start]=0},{}
	while #queue>0 do
		local node=pop(queue)
		if node.cost~=cost[node.cell] then continue end
		if node.cell==goal then
			local points={}
			local distance=cost[goal]*STEP
			local cell,lastDX,lastDZ=goal,nil,nil
			while cell do
				local x,z=unpackCell(cell)
				local following=previous[cell]
				local dx,dz
				if following then
					local a,b=unpackCell(following)
					dx,dz=x-a,z-b
				end
				if #points==0 or dx~=lastDX or dz~=lastDZ then
					table.insert(points,Vector2.new(x*STEP,z*STEP))
				end
				lastDX,lastDZ=dx,dz
				cell=following
			end
			return points,distance
		end
		local x,z=unpackCell(node.cell)
		for _,d in ipairs(directions) do
			local dx,dz,weight=table.unpack(d)
			local nextCell=key(x+dx,z+dz)
			if not cells[nextCell] then continue end
			if dx~=0 and dz~=0 and (not cells[key(x+dx,z)] or not cells[key(x,z+dz)]) then continue end
			local nextCost=node.cost+weight
			if not cost[nextCell] or nextCost<cost[nextCell] then
				cost[nextCell],previous[nextCell]=nextCost,node.cell
				push(queue,{cell=nextCell,cost=nextCost,score=nextCost+heuristic(x+dx,z+dz)})
			end
		end
	end
end
return Router
]==]

if not source:find("local function refreshRoute",1,true) then
	change("local CityMap = {}",[==[local Router = require(script.Parent.CityMapRouter)
local CityMap = {}
local routeLayer, routeCells
local routeOrigin, routeTarget, routeDistance
local nextRouteTime=0]==])
	change('local function dot(parent,name,color,size,layer)',[==[local function refreshRoute(origin,destination,followDelivery)
	if not origin or not destination then
		if routeTarget then routeLayer:ClearAllChildren() end
		routeOrigin,routeTarget,routeDistance=nil,nil,nil
		return
	end
	local now=os.clock()
	if routeTarget==destination and routeOrigin
		and ((origin-routeOrigin).Magnitude<25 or now<nextRouteTime) then return end
	routeOrigin,routeTarget=origin,destination
	nextRouteTime=now+.7
	routeLayer:ClearAllChildren()
	routeCells=routeCells or Router.new(roads)
	local points,distance=Router.route(routeCells,origin,destination)
	routeDistance=distance
	if not points then return end
	for i=2,#points do
		local a,b=point(points[i-1].X,points[i-1].Y),point(points[i].X,points[i].Y)
		local delta=b-a
		if delta.Magnitude<.1 then continue end
		local mid=(a+b)/2
		make("Frame",routeLayer,{Name="RouteSegment",Position=UDim2.fromOffset(mid.X,mid.Y),
			AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(delta.Magnitude+1.5,3),
			Rotation=math.deg(math.atan2(delta.Y,delta.X)),BackgroundColor3=followDelivery and gold or blue,
			BorderSizePixel=0,ZIndex=23})
	end
end
local function dot(parent,name,color,size,layer)]==])
	change("	playerDot=dot(chart",[==[	routeLayer=make("Frame",chart,{Name="Route",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=23})
	playerDot=dot(chart]==])
	change('	if selected and position then',[==[	local selectedTarget = selected and Vector3.new(selected[3],0,selected[4])
	refreshRoute(position,target or selectedTarget,target~=nil)
	if target and routeDistance then
		note.Text=("%s  ·  %d m by road"):format(jobName or "Delivery",math.round(routeDistance*.28))
	end
	if selected and position then]==])
	change('detail.Text=("%d m away"):format(math.round(delta.Magnitude*.28))',[==[detail.Text=if not target and routeDistance then ("%d m by road"):format(math.round(routeDistance*.28))
			else ("%d m straight-line"):format(math.round(delta.Magnitude*.28))]==])
end
local yard=workspace.Map.Yard
local yardRow=("{%.2f,%.2f,%.2f,%.2f,0}"):format(yard.Position.X,yard.Position.Z,yard.Size.X,yard.Size.Z)
if not source:find("local workshopYard",1,true) then
	change("local Router = require(script.Parent.CityMapRouter)", "local Router = require(script.Parent.CityMapRouter)\nlocal workshopYard = "..yardRow.."\ntable.insert(roads, workshopYard)")
end
local module=client:FindFirstChild("CityMapRouter") or Instance.new("ModuleScript")
assert(module:IsA("ModuleScript"))
module.Name="CityMapRouter"
module.Source=router
module.Parent=client
map.Source=source
return "Phone map now routes to the current delivery or selected landmark."
