-- Remove the floating quick menu while keeping the Garage Shop and phone.
local client = game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local shop, main = client.Shop, client.Main
local source = shop.Source

local function removeBlock(startText, nextText)
	local start = source:find(startText, 1, true)
	if not start then return end
	local finish = assert(source:find(nextText, start, true), "Quick menu structure changed")
	source = source:sub(1, start - 1) .. source:sub(finish)
end

removeBlock("\tlocal dock=new(", "\tdim=new(")
removeBlock("function Shop.setMoney(amount)", "function Shop.start()")
for _, line in ipairs({
	"local Garage = require(script.Parent.GarageUi)",
	"\tstore.Activated:Connect(open)",
	'\tgarage.Activated:Connect(function() if canOpen() then Shop.close(); Garage.open("Bike") end end)',
	"\tphone.Activated:Connect(openJobs)",
	"\t\tdockScale.Scale=if size.X<600 then .78 else 1",
	"\t\tdock.Visible=canOpen() and not Shop.isOpen",
}) do
	local first, last = source:find(line .. "\n", 1, true)
	if first then source = source:sub(1,first-1) .. source:sub(last+1) end
end
source = source:gsub("local dim,round,coin", "local dim,round")
assert(not source:find("QuickMenu", 1, true) and not source:find("dock", 1, true))
shop.Source = source
main.Source = main.Source:gsub("\n\tShop%.setMoney%(state%.money%)", "")
return "Floating menu removed; M opens the shop and P opens the phone"
