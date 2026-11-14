-- Add a pull-over outcome to the existing police pursuit. Run in Studio Edit.
local server=game:GetService("ServerScriptService").TwoStrokeServer
local client=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local patrol,garage=server.PolicePatrol,server.GarageService
local p,g=patrol.Source,garage.Source
local function replace(source,before,after)
	local a,b=source:find(before,1,true)
	assert(a,"Police integration point changed: "..before)
	return source:sub(1,a-1)..after..source:sub(b+1)
end
if not p:find("PULL_OVER_SECONDS",1,true) then
	p=replace(p,"local CATCH=11","local CATCH=11\nlocal PULL_OVER_SECONDS=1.05\nlocal STOPPED_SPEED=3.5")
	p=replace(p,"local function clear(officer,latest)\n\t\tif officer.target then wanted[officer.target]=nil end",[==[local function clear(officer,latest)
		if officer.target then
			wanted[officer.target]=nil
			local s=api.sessions[officer.target]
			if s and api.status then api.status(s,nil) end
		end
		officer.stoppedSince=nil]==])
	p=replace(p,"\t\t\t\tif not root or time-o.start>MAX_CHASE",[==[				local stopped = rider and rider.speed <= STOPPED_SPEED
				if stopped and flat(root.Position-o.pos).Magnitude<MAX_SIGHT and sees(o,s,root.Position,false) then
					o.stoppedSince=o.stoppedSince or time
				else
					o.stoppedSince=nil
				end
				local yielded=o.stoppedSince and time-o.stoppedSince>=PULL_OVER_SECONDS
				if not root or time-o.start>MAX_CHASE]==])
	p=replace(p,"elseif flat(root.Position-o.pos).Magnitude<CATCH and sees(o,s,root.Position,false) then",
		"elseif flat(root.Position-o.pos).Magnitude<CATCH and (not stopped or yielded) and sees(o,s,root.Position,false) then")
	p=replace(p,"api.cite(s,o.reason)","api.cite(s,o.reason,yielded==true)")
	p=replace(p,'api.notify(r.s, "POLICE · Pull over. Patrol saw "..violation..".", "warn")',
		'if api.status then api.status(r.s,violation) end\n\t\t\t\t\t\t\tapi.notify(r.s, "POLICE · Pull over. Patrol saw "..violation..".", "warn")')
	-- Clear stale replicable speed samples when a player leaves without a citation.
	p=replace(p,"for player in pairs(cooldown) do if not api.sessions[player] then cooldown[player]=nil;previous[player]=nil end end",
		"for player in pairs(cooldown) do if not api.sessions[player] then cooldown[player]=nil end end\n\t\tfor player in pairs(previous) do if not api.sessions[player] then previous[player]=nil end end")
end
if not g:find('SetAttribute("PolicePursuit"',1,true) then
	g=replace(g,[==[		cite = function(s: Session, reason: string)
			local fine = math.min(s.data.money, 60)]==],[==[		status = function(s: Session, reason: string?)
			s.player:SetAttribute("PolicePursuit", reason)
		end,
		cite = function(s: Session, reason: string, yielded: boolean)
			local fine = math.min(s.data.money, if yielded then 30 else 60)]==])
	g=replace(g,[==[notify(s, ("Police stopped you for %s. Fine: %d zł."):format(reason, fine), "warn")]==],
		[==[notify(s, if yielded then ("You pulled over for %s. Reduced fine: %d zł."):format(reason,fine)
				else ("Police stopped you for %s. Fine: %d zł."):format(reason,fine), "warn")]==])
end
local ui=client:FindFirstChild("PoliceStatusUI") or Instance.new("LocalScript")
assert(ui:IsA("LocalScript"))
ui.Name="PoliceStatusUI"
ui.Source=[==[
local player=game:GetService("Players").LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="TwoStrokePoliceStatus"
gui.DisplayOrder=12
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local card=Instance.new("Frame")
card.Name="PullOver"
card.AnchorPoint=Vector2.new(.5,0)
card.Position=UDim2.new(.5,0,0,13)
card.Size=UDim2.new(.88,0,0,48)
card.BackgroundColor3=Color3.fromRGB(31,50,82)
card.BorderSizePixel=0
card.Visible=false
card.Parent=gui
local constraint=Instance.new("UISizeConstraint")
constraint.MaxSize=Vector2.new(322,48)
constraint.Parent=card
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,10)
corner.Parent=card
local border=Instance.new("UIStroke")
border.Color=Color3.fromRGB(113,169,232)
border.Thickness=2
border.Parent=card
local text=Instance.new("TextLabel")
text.Size=UDim2.new(1,-18,1,-8)
text.Position=UDim2.fromOffset(9,4)
text.BackgroundTransparency=1
text.TextColor3=Color3.fromRGB(244,244,242)
text.TextWrapped=true
text.Font=Enum.Font.GothamBold
text.TextSize=14
text.Parent=card
local function sync()
	local reason=player:GetAttribute("PolicePursuit")
	card.Visible=typeof(reason)=="string"
	if card.Visible then text.Text="POLICE · Pull over for a reduced fine\n"..reason end
end
player:GetAttributeChangedSignal("PolicePursuit"):Connect(sync)
sync()
]==]
patrol.Source,garage.Source=p,g
ui.Parent=client
return "Police now recognize a pull-over and show a pursuit banner."
