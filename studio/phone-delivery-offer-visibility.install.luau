-- Keep delivery offers visible when the player has the map or gear screen open.
local client=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local phone,map=client.Phone,client.CityMap
local source=phone.Source
if source:find("CityMap.showJobs()",1,true) then return "Delivery visibility fix already installed" end
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"Phone integration point changed: "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
replace("local CityMap = require(script.Parent.CityMap)", "local CityMap = require(script.Parent.CityMap)\nlocal Outfit = require(script.Parent.OutfitUI)")
replace("local function setOpen(open: boolean)\n\tisOpen = open", "local function setOpen(open: boolean)\n\tif open and Outfit.isOpen then return end\n\tisOpen = open")
replace("UserInputService.TouchEnabled and not open", "UserInputService.TouchEnabled and not open and not Outfit.isOpen")
replace("Visible=UserInputService.TouchEnabled,", "Visible=UserInputService.TouchEnabled and not Outfit.isOpen,")
replace("\t\tif not hadOffer then\n\t\t\tding()", "\t\tif not hadOffer then\n\t\t\tCityMap.showJobs()\n\t\t\tding()")
replace("\tbuild()\n\trender()",[==[	build()
	render()
	Outfit.Changed.Event:Connect(function(open)
		if open then
			setOpen(false)
		else
			touchButton.Visible = UserInputService.TouchEnabled
			if state.offer then setOpen(true) end
		end
	end)]==])
local mapSource=map.Source
if not mapSource:find("function CityMap.showJobs()",1,true) then
	local a=assert(mapSource:find("return CityMap",1,true))
	map.Source=mapSource:sub(1,a-1)..[==[function CityMap.showJobs()
	if panel then panel.Visible=false end
end
]==]..mapSource:sub(a)
end
phone.Source=source
return "New delivery offers now bring Jobs forward and wait for rider gear to close."
