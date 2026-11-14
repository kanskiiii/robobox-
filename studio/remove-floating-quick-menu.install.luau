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
local phone = client.Phone
local phoneSource = phone.Source
if not phoneSource:find("Phone.openShop", 1, true) then
	local at = assert(phoneSource:find('\ttext("P put away', 1, true))
	phoneSource = phoneSource:sub(1,at-1) .. [==[
	local shopButton = button("Garage Shop", Color3.fromRGB(133, 77, 233), {
		Name = "GarageShop", Position = UDim2.fromOffset(16, 443), Size = UDim2.new(1, -32, 0, 33), Parent = screen,
	})
	shopButton.Activated:Connect(function()
		if Phone.openShop and Phone.openShop() then setOpen(false) end
	end)
]==] .. phoneSource:sub(at)
	phoneSource = phoneSource:gsub("local Phone = {}", "local Phone: { [string]: any } = {}")
	phone.Source = phoneSource
end
if not shop.Source:find("Phone.openShop = open", 1, true) then
	local current = shop.Source
	local at = assert(current:find("\tbuy.Activated:Connect", 1, true))
	current = current:sub(1,at-1) .. "\tPhone.openShop = open\n" .. current:sub(at)
	current = current:gsub("\t\tfetchPrice%(%)\n\tend", "\t\tfetchPrice()\n\t\treturn true\n\tend")
	shop.Source = current
end
return "Removed floating menu. Open Garage Shop from the phone or with M."
