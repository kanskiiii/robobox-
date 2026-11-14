-- Share the phone router with the delivery server and charge time for distance by road.
local rs=game:GetService("ReplicatedStorage")
local client=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local service=game:GetService("ServerScriptService").TwoStrokeServer
local delivery=service.Delivery
local localRouter=assert(client:FindFirstChild("CityMapRouter"))
local sharedRouter=rs.TwoStroke:FindFirstChild("CityMapRouter") or Instance.new("ModuleScript")
local sharedRoads=rs.TwoStroke:FindFirstChild("CityRoads") or Instance.new("ModuleScript")
assert(sharedRouter:IsA("ModuleScript") and sharedRoads:IsA("ModuleScript"))

local mapSource=client.CityMap.Source
local baked=mapSource:match("local roads = (%b{})")
local yard=mapSource:match("local workshopYard = (%b{})")
assert((baked and yard) or sharedRoads.Parent,"Install the phone map and street routes first")
local roadSource
if baked and yard then
	roadSource="return "..baked:sub(1,-2)..",\n"..yard.."\n}"
	-- The baked table is static. Validate it before swapping the source.
	local read=assert(loadstring(roadSource))
	assert(#read()>50,"Phone road data is incomplete")
end

local source=delivery.Source
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"Delivery changed at "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
if not source:find("local function travelDist",1,true) then
	replace('local Remotes = require(Shared.Net.Remotes)',[==[local Remotes = require(Shared.Net.Remotes)
local Router = require(Shared.CityMapRouter)
local roadCells = Router.new(require(Shared.CityRoads))]==])
	replace('local function app(s: any): any',[==[local function travelDist(a: Vector3, b: Vector3): number
	local direct = flatDist(a,b)
	local points, byRoad = Router.route(roadCells,a,b)
	if not points or not byRoad then return direct end
	local goal,start = points[1],points[#points]
	local offRoad = (goal - Vector2.new(b.X,b.Z)).Magnitude + (start - Vector2.new(a.X,a.Z)).Magnitude
	return math.max(direct,byRoad+offRoad)
end

local function app(s: any): any]==])
	replace('local pickupM = flatDist(from, pickup) / SPM','local pickupM = travelDist(from, pickup) / SPM')
	replace('local dropM = flatDist(pickup, dropPos) / SPM','local dropM = travelDist(pickup, dropPos) / SPM')
	replace('pickupM = math.floor(pickupM), dropM = math.floor(dropM), pay = pay,','pickupM = math.floor(pickupM), dropM = math.floor(dropM), exactDropM = dropM, pay = pay,')
	replace('local metres = flatDist(order.pickup, order.drop) / SPM','local metres = order.exactDropM or travelDist(order.pickup, order.drop) / SPM')
	replace('pay = offer.pay, deadline = nil, estimate = nil,','pay = offer.pay, exactDropM = offer.exactDropM, deadline = nil, estimate = nil,')
end

if roadSource then
	sharedRoads.Source=roadSource
	mapSource=mapSource:gsub("local roads = %b{}",'local roads = require(game:GetService("ReplicatedStorage").TwoStroke.CityRoads)',1)
	mapSource=mapSource:gsub("\nlocal workshopYard = %b{}\ntable%.insert%(roads, workshopYard%)","",1)
end
if localRouter.Source:find("function Router.route",1,true) then sharedRouter.Source=localRouter.Source end
assert(sharedRouter.Source:find("function Router.route",1,true))
sharedRoads.Name,sharedRouter.Name="CityRoads","CityMapRouter"
sharedRoads.Parent,sharedRouter.Parent=rs.TwoStroke,rs.TwoStroke
localRouter.Source='return require(game:GetService("ReplicatedStorage").TwoStroke.CityMapRouter)'
client.CityMap.Source=mapSource
delivery.Source=source
return "Delivery offer distance, payout and deadline now use the shared street router"
