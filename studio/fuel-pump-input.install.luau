-- Give pumps a dedicated input and validate the bike being fueled.
local module=game:GetService("ServerScriptService").TwoStrokeServer.GarageService
local source=module.Source
if source:find("Stop the bike before refueling.",1,true) then return "Already installed" end
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"Fuel pump integration point changed: "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
replace([==[		p.Name = "Refuel"
		p.ActionText]==],[==[		p.Name = "Refuel"
		p.KeyboardKeyCode = Enum.KeyCode.R
		p.GamepadKeyCode = Enum.KeyCode.ButtonR3
		p.ActionText]==])
replace([==[			if Jerrycan.fillAtPump(s) then
				return
			end
			local root = s.bike.PrimaryPart :: Part
			if (root.Position - pump.Position).Magnitude > 30 then]==],[==[			local ride = s.driving and s.riding
			if ride and ride.test then
				notify(s, "The borrowed bike is refueled when you remount it.", "info")
				return
			end
			if not ride and Jerrycan.fillAtPump(s) then
				return
			end
			local root = (if ride then ride.model else s.bike).PrimaryPart
			if not root or (root.Position - pump.Position).Magnitude > 30 then]==])
replace([==[			local litres, err = PlayerData.buyFuel(s.data, 1, s.spec.fuelCapacity)]==],[==[			if root.AssemblyLinearVelocity.Magnitude > 4 then
				notify(s, "Stop the bike before refueling.", "warn")
				return
			end
			local litres, err = PlayerData.buyFuel(s.data, 1, s.spec.fuelCapacity)]==])
module.Source=source
return "Refueling now uses R and validates the stopped project bike."
