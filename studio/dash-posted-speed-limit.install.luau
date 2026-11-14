-- Show the server's posted speed limit on the bike LCD.
local rs=game:GetService("ReplicatedStorage")
local shared=rs.TwoStroke
local server=game:GetService("ServerScriptService").TwoStrokeServer
local dash=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient.Dash
local patrol=server.PolicePatrol
local limit=assert(tonumber(patrol.Source:match("local LIMIT=(%d+)")),"Patrol limit is missing")
local function replace(source,before,after)
	local a,b=source:find(before,1,true)
	assert(a,"Dashboard integration point changed: "..before)
	return source:sub(1,a-1)..after..source:sub(b+1)
end
local p,d=patrol.Source,dash.Source
if not p:find('shared:SetAttribute("PostedSpeedLimitKmh"',1,true) then
	p=replace(p,"function Police.start(api)",[==[function Police.start(api)
	if not api.station then shared:SetAttribute("PostedSpeedLimitKmh",LIMIT) end]==])
end
if not d:find('shared:GetAttribute("PostedSpeedLimitKmh"',1,true) then
	d=replace(d,"local Dash = {}",[==[local shared = game:GetService("ReplicatedStorage"):WaitForChild("TwoStroke")
local Dash = {}]==])
	d=replace(d,"local GHOST =",[==[local ALERT = Color3.fromRGB(136, 35, 25)
local GHOST =]==])
	d=replace(d,"Text = \"\", TextXAlignment = Enum.TextXAlignment.Right })\n\treturn { part",[==[Text = "", Name = "DashWarning", TextXAlignment = Enum.TextXAlignment.Right })
	return { part]==])
	d=replace(d,[==[	local w = ""
	if (hud.tempC or 0) > 112 then
		w = "TEMP!"
	elseif hud.fuelCapacity and hud.fuelCapacity > 0 and (hud.fuelL or 0) / hud.fuelCapacity < 0.12 then
		w = "FUEL"
	end
	sc.warn.Text = w]==],[==[	local limit = shared:GetAttribute("PostedSpeedLimitKmh")
	local w, color = "", INK
	if (hud.tempC or 0) > 112 then
		w, color = "TEMP!", ALERT
	elseif hud.fuelCapacity and hud.fuelCapacity > 0 and (hud.fuelL or 0) / hud.fuelCapacity < 0.12 then
		w, color = "FUEL", ALERT
	elseif typeof(limit) == "number" then
		w = ("LIM %d"):format(limit)
		-- The wheel sensor speed can differ from the chassis speed during a skid.
		if (hud.speedKmh or 0) > limit then color = ALERT end
	end
	sc.warn.Text, sc.warn.TextColor3 = w, color]==])
end
shared:SetAttribute("PostedSpeedLimitKmh",limit)
patrol.Source,dash.Source=p,d
return ("LCD now shows the enforced %d km/h speed limit."):format(limit)
