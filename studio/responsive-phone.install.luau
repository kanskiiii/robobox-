-- Make the phone usable on touch and short displays. Run in Studio Edit mode.
local phone=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient.Phone
local source=phone.Source
if source:find("local function fitPhone",1,true) then return "Responsive phone already installed" end
local function replace(before,after)
	local a,b=source:find(before,1,true)
	assert(a,"Phone integration point changed: "..before)
	source=source:sub(1,a-1)..after..source:sub(b+1)
end
replace("local HIDDEN = UDim2.new(1, -24, 1, 470)",[==[local phoneScale: UIScale
local touchButton: TextButton
local phoneTween: Tween?
local HIDDEN = UDim2.new(1, -24, 1, 540)]==])
replace([==[local function setOpen(open: boolean)
	isOpen = open
	modalBtn.Visible = open -- a visible modal button frees the mouse in first person
	TweenService:Create(body, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Position = if open then SHOWN else HIDDEN }):Play()]==],[==[local function fitPhone()
	local viewport=gui.AbsoluteSize
	if viewport.X<1 or viewport.Y<1 then return end
	phoneScale.Scale=math.min(1,math.max(.05,(viewport.X-36)/270),math.max(.05,(viewport.Y-28)/520))
end

local function setOpen(open: boolean)
	isOpen = open
	modalBtn.Visible = open
	touchButton.Visible = UserInputService.TouchEnabled and not open
	if phoneTween then phoneTween:Cancel() end
	if open then body.Visible=true end
	local tween=TweenService:Create(body,TweenInfo.new(.21,Enum.EasingStyle.Quad),{Position=if open then SHOWN else HIDDEN})
	phoneTween=tween
	tween.Completed:Once(function(playback)
		if playback==Enum.PlaybackState.Completed and not isOpen then body.Visible=false end
		if phoneTween==tween then phoneTween=nil end
	end)
	tween:Play()]==])
replace('DisplayOrder = 15, IgnoreGuiInset = true,','DisplayOrder = 15, IgnoreGuiInset = false,')
replace([==[	-- tab that peeks out while the phone is put away
	text("[P] phone", 12, DIM, { Position = UDim2.new(0, 0, 0, -22), Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Center, Parent = body })]==],[==[	body.Visible=false
	phoneScale=new("UIScale",{Parent=body})
	touchButton=button("Phone",CARD,{
		Name="PhoneTouchToggle",Parent=gui,Size=UDim2.fromOffset(77,45),AnchorPoint=Vector2.new(1,.5),
		Position=UDim2.new(1,-14,.32,0),TextSize=15,Visible=UserInputService.TouchEnabled,
	})
	touchButton.Activated:Connect(function() setOpen(true) end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPhone)
	fitPhone()]==])
replace([==[	text("LTE  87%", 12, TEXT, { Position = UDim2.new(1, -92, 0, 8), Size = UDim2.fromOffset(70, 18), TextXAlignment = Enum.TextXAlignment.Right, Parent = screen })]==],[==[	local close=button("Close",CARD,{Name="ClosePhone",Position=UDim2.new(1,-66,0,4),
		Size=UDim2.fromOffset(57,28),TextSize=12,Parent=screen})
	close.Activated:Connect(function() setOpen(false) end)]==])
phone.Source=source
return "Installed responsive phone layout and touch access."
