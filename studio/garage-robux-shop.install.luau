-- Run in Studio Edit mode. Adds the Robux shop and quick navigation.
local root = game:GetService("ReplicatedStorage")
local client = game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local server = game:GetService("ServerScriptService").TwoStrokeServer
local main, phone = client.Main, client.Phone
local function splice(source, before, after)
	local a,b = source:find(before,1,true)
	if not a then assert(source:find(after,1,true),"Missing integration point: "..before); return source end
	return source:sub(1,a-1)..after..source:sub(b+1)
end
local mainSource = main.Source
if not mainSource:find("local Shop = require",1,true) then
	mainSource=splice(mainSource,"local Phone = require(script.Parent.Phone)","local Phone = require(script.Parent.Phone)\nlocal Shop = require(script.Parent.Shop)")
	mainSource=splice(mainSource,"Phone.start()","Phone.start()\nShop.start()")
	mainSource=splice(mainSource,"lastState = state","lastState = state\n\tShop.setMoney(state.money)")
	for _, pair in ipairs({{"Interaction.paused = outfitOpen or ComputerUI.isOpen","Interaction.paused = outfitOpen or ComputerUI.isOpen or Shop.isOpen"},{"Interaction.paused = outfitOpen or open","Interaction.paused = outfitOpen or open or Shop.isOpen"}}) do
		mainSource=splice(mainSource,pair[1],pair[2])
	end
	mainSource=splice(mainSource,'game:GetService("UserInputService").InputBegan:Connect(function(io, processed)','Shop.Changed.Event:Connect(function(open)\n\tInteraction.paused = outfitOpen or ComputerUI.isOpen or open\nend)\nComputerUI.Changed.Event:Connect(function(open)\n\tif open then Shop.close() end\nend)\nOutfitUI.Changed.Event:Connect(function(open)\n\tif open then Shop.close() end\nend)\ngame:GetService("UserInputService").InputBegan:Connect(function(io, processed)')
end
local phoneSource=phone.Source
if not phoneSource:find("function Phone.toggle()",1,true) then
	phoneSource=splice(phoneSource,"function Phone.start()","function Phone.toggle()\n\tsetOpen(not isOpen)\nend\n\nfunction Phone.start()")
end

local configSource=[==[
return { PitCrew = 2089881138 }
]==]
local serverSource=[==[
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local root = game:GetService("ReplicatedStorage")
local passId = require(root.TwoStroke.ShopConfig).PitCrew
local remote = root.TwoStroke.ShopEquip

local function paint(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then return end
	local existing = head:FindFirstChild("PitCrewNameplate")
	if existing then existing:Destroy() end
	if not player:GetAttribute("OwnsPitCrew") or not player:GetAttribute("PitCrewEquipped") then return end
	local tag = Instance.new("BillboardGui")
	tag.Name = "PitCrewNameplate"
	tag.Size = UDim2.fromOffset(112,25)
	tag.StudsOffsetWorldSpace = Vector3.new(0,2.65,0)
	tag.MaxDistance = 65
	tag.AlwaysOnTop = true
	tag.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundColor3 = Color3.fromRGB(255,199,66)
	label.TextColor3 = Color3.fromRGB(36,23,62)
	label.Text = "★  PIT CREW"
	label.TextSize = 15
	label.Font = Enum.Font.GothamBlack
	label.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = label
end

local function grant(player)
	player:SetAttribute("PitCrewEquipped",true)
	player:SetAttribute("OwnsPitCrew",true)
	paint(player)
end

local function check(player)
	local ok, owned = pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,player.UserId,passId)
	if player.Parent ~= Players then return end
	if ok and owned and not player:GetAttribute("OwnsPitCrew") then grant(player) end
	player:SetAttribute("PitCrewOwnershipReady",ok or player:GetAttribute("OwnsPitCrew")==true)
end

local function add(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head",8)
		if player.Character==character then paint(player) end
	end)
	task.spawn(check,player)
end

Players.PlayerAdded:Connect(add)
for _,player in Players:GetPlayers() do add(player) end
Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,id,bought)
	if id==passId and bought and player.Parent==Players then
		grant(player)
		player:SetAttribute("PitCrewOwnershipReady",true)
	end
end)
remote.OnServerEvent:Connect(function(player,equipped)
	if typeof(equipped)~="boolean" or not player:GetAttribute("OwnsPitCrew") then return end
	if player:GetAttribute("PitCrewEquipped")==equipped then return end
	player:SetAttribute("PitCrewEquipped",equipped)
	paint(player)
end)
]==]
local uiSource=[==[
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local root = game:GetService("ReplicatedStorage")
local config = require(root.TwoStroke.ShopConfig)
local Controller = require(script.Parent.BikeController)
local Garage = require(script.Parent.GarageUi)
local Phone = require(script.Parent.Phone)
local Computer = require(script.Parent.ComputerUI)
local Outfit = require(script.Parent.OutfitUI)
local player = Players.LocalPlayer

local Shop = { isOpen=false, Changed=Instance.new("BindableEvent") }
local ink,white = Color3.fromRGB(36,23,62),Color3.fromRGB(255,251,240)
local purple = Color3.fromRGB(133,77,233)
local gold = Color3.fromRGB(255,195,61)
local mint = Color3.fromRGB(119,222,153)
local sky = Color3.fromRGB(115,216,248)
local dim,round,coin
local price,loading,prompting
local outfitOpen=false

local function new(class,parent,props)
	local object=Instance.new(class)
	for key,value in pairs(props) do object[key]=value end
	object.Parent=parent
	return object
end
local function shape(gui,radius,thickness)
	new("UICorner",gui,{CornerRadius=UDim.new(0,radius)})
	if thickness then new("UIStroke",gui,{Color=ink,Thickness=thickness,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
end
local function gradient(gui,a,b)
	new("UIGradient",gui,{Color=ColorSequence.new(a,b),Rotation=90})
end
local function label(parent,name,text,x,y,w,h,size,color)
	return new("TextLabel",parent,{Name=name,Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
		TextSize=size,TextColor3=color or ink,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBlack,BackgroundTransparency=1})
end
local function button(parent,name,text,x,y,w,h,color)
	local b=new("TextButton",parent,{Name=name,Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
		TextSize=19,TextColor3=ink,Font=Enum.Font.GothamBlack,BackgroundColor3=color,BorderSizePixel=0})
	shape(b,12,2.5)
	return b
end
local function canOpen()
	return not Controller.active and not Computer.isOpen and not outfitOpen
end
function Shop.close()
	if not Shop.isOpen then return end
	Shop.isOpen=false
	dim.Visible=false
	Shop.Changed:Fire(false)
end
function Shop.setMoney(amount)
	if coin and typeof(amount)=="number" then coin.Text=("%d zł"):format(amount) end
end

function Shop.start()
	local playerGui=player:WaitForChild("PlayerGui")
	local gui=new("ScreenGui",playerGui,{Name="TwoStrokeShop",DisplayOrder=30,ResetOnSpawn=false})
	local dock=new("Frame",gui,{Name="QuickMenu",Size=UDim2.fromOffset(124,193),Position=UDim2.fromOffset(15,84),BackgroundTransparency=1})
	local dockScale=new("UIScale",dock,{Scale=1})
	local store=button(dock,"Shop","★  SHOP",0,0,118,49,gold)
	local garage=button(dock,"BikeMenu","▶  BIKE",0,57,118,42,sky)
	local phone=button(dock,"JobsMenu","✉  JOBS",0,107,118,42,mint)
	coin=label(dock,"Wallet","— zł",0,159,118,31,17,white)
	coin.TextXAlignment=Enum.TextXAlignment.Center
	coin.BackgroundTransparency=0
	coin.BackgroundColor3=ink
	shape(coin,12)

	dim=new("TextButton",gui,{Name="Overlay",Text="",AutoButtonColor=false,Size=UDim2.fromScale(1,1),
		BackgroundColor3=ink,BackgroundTransparency=.34,Visible=false,Modal=true})
	local panel=new("Frame",dim,{Name="ShopPanel",Size=UDim2.fromOffset(584,412),Position=UDim2.fromScale(.5,.5),
		AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=white,BorderSizePixel=0,Active=true})
	shape(panel,23,4)
	round=new("UIScale",panel,{Scale=1})
	local header=new("Frame",panel,{Name="Header",Size=UDim2.new(1,-12,0,77),Position=UDim2.fromOffset(6,6),BackgroundColor3=purple,BorderSizePixel=0})
	shape(header,19)
	gradient(header,Color3.fromRGB(163,103,255),Color3.fromRGB(114,54,207))
	label(header,"Title","★  GARAGE SHOP",18,7,420,59,32,white)
	local close=button(header,"Close","×",515,14,42,43,Color3.fromRGB(255,126,123))
	close.TextSize=29
	close.Activated:Connect(Shop.close)
	dim.Activated:Connect(Shop.close)

	local hero=new("Frame",panel,{Name="PitCrewCard",Position=UDim2.fromOffset(21,99),Size=UDim2.fromOffset(542,196),
		BackgroundColor3=gold,BorderSizePixel=0,ClipsDescendants=true})
	shape(hero,19,3)
	gradient(hero,Color3.fromRGB(255,230,120),Color3.fromRGB(255,168,54))
	local medal=new("Frame",hero,{Name="Medal",Position=UDim2.fromOffset(27,36),Size=UDim2.fromOffset(114,114),BackgroundColor3=Color3.fromRGB(255,229,138)})
	shape(medal,57,4)
	local emblem=label(medal,"Emblem","★",0,0,114,110,67,ink)
	emblem.TextXAlignment=Enum.TextXAlignment.Center
	label(hero,"Name","Pit Crew Badge",165,18,360,47,30)
	local description=label(hero,"Description","Permanent gold nameplate for your rider.",165,70,337,48,18)
	description.TextWrapped=true
	local buy=button(hero,"Purchase","Checking price…",165,131,322,48,mint)
	local bottom=label(panel,"Info","",25,306,530,28,15)
	local tips=new("Frame",panel,{Name="JobsCard",Position=UDim2.fromOffset(21,345),Size=UDim2.fromOffset(542,50),BackgroundColor3=sky,BorderSizePixel=0})
	shape(tips,12,2)
	label(tips,"JobsHint","Earn zł with deliveries",15,0,340,50,17)
	local jobs=button(tips,"OpenJobs","Jobs  ›",415,6,115,37,white)

	local function refresh()
		local owned=player:GetAttribute("OwnsPitCrew")
		local ready=player:GetAttribute("PitCrewOwnershipReady")
		local equipped=player:GetAttribute("PitCrewEquipped")
		buy.Interactable=owned or (ready==true and price~=nil and not prompting)
		buy.Text=if owned then (if equipped then "Owned · Unequip" else "Owned · Equip")
			elseif prompting then "Roblox checkout open"
			elseif price and ready then ("Buy for %d Robux"):format(price)
			elseif loading or ready==nil then "Checking store…"
			else "Currently unavailable"
		buy.BackgroundColor3=if buy.Interactable then mint else Color3.fromRGB(226,223,219)
		bottom.Text=if owned then "Your badge shows above your rider when equipped."
			elseif price and ready then "One-time purchase through Roblox."
			elseif not loading and ready~=nil then "Close and reopen the shop to try again." else ""
	end
	local function fetchPrice()
		if loading then return end
		loading=true
		refresh()
		task.spawn(function()
			local ok,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,config.PitCrew,Enum.InfoType.GamePass)
			price=if ok and info.IsForSale and typeof(info.PriceInRobux)=="number" then info.PriceInRobux else nil
			loading=false
			refresh()
		end)
	end
	local function open()
		if Shop.isOpen or not canOpen() then return end
		Shop.isOpen=true
		dim.Visible=true
		Shop.Changed:Fire(true)
		panel.Position=UDim2.fromScale(.5,.519)
		TweenService:Create(panel,TweenInfo.new(.19,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
			{Position=UDim2.fromScale(.5,.5)}):Play()
		fetchPrice()
	end
	buy.Activated:Connect(function()
		if player:GetAttribute("OwnsPitCrew") then
			root.TwoStroke.ShopEquip:FireServer(not player:GetAttribute("PitCrewEquipped"))
		elseif buy.Interactable and not prompting then
			prompting=true
			refresh()
			local ok=pcall(Marketplace.PromptGamePassPurchase,Marketplace,player,config.PitCrew)
			if not ok then prompting=false; price=nil; refresh() end
		end
	end)
	Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id)
		if p==player and id==config.PitCrew then prompting=false; refresh() end
	end)
	for _,attribute in {"OwnsPitCrew","PitCrewEquipped","PitCrewOwnershipReady"} do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	store.Activated:Connect(open)
	garage.Activated:Connect(function() if canOpen() then Shop.close(); Garage.open("Bike") end end)
	local function openJobs() if canOpen() then Shop.close(); Phone.toggle() end end
	phone.Activated:Connect(openJobs)
	jobs.Activated:Connect(openJobs)
	Outfit.Changed.Event:Connect(function(opened) outfitOpen=opened end)
	Input.InputBegan:Connect(function(input,used)
		if input.KeyCode==Enum.KeyCode.Escape and Shop.isOpen then Shop.close()
		elseif not used and input.KeyCode==Enum.KeyCode.M and not Input:GetFocusedTextBox() then
			if Shop.isOpen then Shop.close() else open() end
		end
	end)
	RunService.RenderStepped:Connect(function()
		local size=gui.AbsoluteSize
		round.Scale=math.min(1,(size.X-26)/584,(size.Y-24)/412)
		dockScale.Scale=if size.X<600 then .78 else 1
		dock.Visible=canOpen() and not Shop.isOpen
		if Shop.isOpen and not canOpen() then Shop.close() end
	end)
	refresh()
end
return Shop
]==]

local function install(parent,class,name,source)
	local instance=parent:FindFirstChild(name) or Instance.new(class)
	assert(instance:IsA(class),name.." has the wrong class")
	instance.Name=name
	if source then instance.Source=source end
	instance.Parent=parent
end
install(root.TwoStroke,"ModuleScript","ShopConfig",configSource)
install(root.TwoStroke,"RemoteEvent","ShopEquip")
install(server,"Script","ShopPasses",serverSource)
install(client,"ModuleScript","Shop",uiSource)
main.Source,phone.Source=mainSource,phoneSource
return "Installed Garage Shop, quick navigation and Pit Crew pass"
