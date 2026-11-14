-- Rotate the stock SM50 throttle sleeve using the existing cockpit simulation.
local rs=game:GetService("ReplicatedStorage")
local bar=rs.Assets.Parts.Part_handlebar_std
assert(bar:GetAttribute("SM50FrontEndVersion")==1)
local grip=assert(bar:FindFirstChild("Rubber GripR"))
local scriptObject=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient.CockpitControls
local source=scriptObject.Source
local function replace(old,new)
	local start,finish=source:find(old,1,true)
	assert(start,"CockpitControls changed at "..old)
	source=source:sub(1,start-1)..new..source:sub(finish+1)
end
if not source:find("ThrottleTwist",1,true) then
	replace("local controls = {}", "local controls = {}\nlocal throttle")
	replace("\ttable.clear(controls)",[==[	if throttle then
		for weld, rest in pairs(throttle.rest) do
			if weld.Parent then weld.C0 = rest end
		end
		throttle = nil
	end
	table.clear(controls)]==])
	replace("\tmountedBar = bar",[==[	mountedBar = bar
	local axis = bar:FindFirstChild("ThrottleTwist")
	if axis and axis:IsA("Attachment") then
		local rest = {}
		for _, piece in bar:GetChildren() do
			if piece:GetAttribute("SM50ThrottleSleeve") then
				local weld = piece:FindFirstChild("DetailWeld")
				if weld and weld:IsA("Weld") then rest[weld] = weld.C0 end
			end
		end
		throttle = { pivot=axis.Position, direction=axis.CFrame.RightVector, rest=rest, amount=0 }
	end]==])
	replace("\tfor _, control in ipairs(controls) do\n\t\tlocal amount = hud",[==[	if throttle then
		throttle.amount += (math.clamp(hud.throttle or 0, 0, 1) - throttle.amount) * (1 - math.exp(-dt * 18))
		local turn = CFrame.new(throttle.pivot) * CFrame.fromAxisAngle(throttle.direction, math.rad(36) * throttle.amount)
			* CFrame.new(-throttle.pivot)
		for weld, rest in pairs(throttle.rest) do weld.C0 = turn * rest end
	end
	for _, control in ipairs(controls) do
		local amount = hud]==])
end

local axis=bar:FindFirstChild("ThrottleTwist") or Instance.new("Attachment")
axis.Name="ThrottleTwist"
axis.CFrame=bar.CFrame:ToObjectSpace(grip.CFrame)
axis.Parent=bar
for _,piece in bar:GetChildren() do
	if piece:IsA("BasePart") and bar:GetPivot():PointToObjectSpace(piece.Position).X>0 then
		if piece==grip or piece.Name=="Grip ribs" or piece.Name=="Grip flange" then
			piece:SetAttribute("SM50ThrottleSleeve",true)
		end
	end
end

-- The indexed collar makes the rotation visible from the saddle.
local index=bar:FindFirstChild("Throttle index")
if not index then
	index=Instance.new("Part")
	index.Name="Throttle index"
	index.Size=Vector3.new(.071,.012,.015)
	index.Color=Color3.fromRGB(220,193,104)
	index.Material=Enum.Material.SmoothPlastic
	index.CanCollide,index.CanQuery,index.CanTouch,index.Massless=false,false,false,true
	index.CFrame=grip.CFrame*CFrame.new(-.176,.078,0)
	local weld=Instance.new("Weld")
	weld.Name,weld.Part0,weld.Part1="DetailWeld",bar,index
	weld.C0=bar.CFrame:ToObjectSpace(index.CFrame)
	weld.Parent=index
	index.Parent=bar
end
index:SetAttribute("SM50ThrottleSleeve",true)
scriptObject.Source=source
return "Stock SM50 throttle sleeve animated"
