-- Align the stock SM50 to the garage lift's BikeRest attachment in Studio Edit.
local rs = game:GetService("ReplicatedStorage")
local frame = rs.Assets.Vehicles.sm50.Frame
local stand = assert(workspace.Map:FindFirstChild("MotorcycleStand",true))
local rest = assert(stand:FindFirstChild("BikeRest",true))
local service = game:GetService("ServerScriptService").TwoStrokeServer.GarageService
local source = service.Source
local original = [==[		local pos = base.Position + Vector3.new(0, BikeBuilder.RIDE_HEIGHT + STAND_LIFT, 0)
		model:PivotTo(CFrame.lookAt(pos, pos + flat))]==]
local replacement = [==[		local pos = base.Position + Vector3.new(0, BikeBuilder.RIDE_HEIGHT + STAND_LIFT, 0)
		local heading = CFrame.lookAlong(Vector3.zero, flat)
		local frameVisual = model:FindFirstChild("Frame")
		local contact = frameVisual and frameVisual:FindFirstChild("LiftContact")
		local saddle = st:FindFirstChild("BikeRest", true)
		if contact and contact:IsA("Attachment") and saddle and saddle:IsA("Attachment") then
			local offset = root.CFrame:PointToObjectSpace(contact.WorldPosition)
			pos = saddle.WorldPosition - heading:VectorToWorldSpace(offset)
		end
		model:PivotTo(CFrame.new(pos) * heading)]==]
local a,b = source:find(original,1,true)
if a then source = source:sub(1,a-1)..replacement..source:sub(b+1)
else assert(source:find(replacement,1,true),"Stand placement source changed") end

local saddle = rest.Parent
assert(saddle:IsA("BasePart"))
local riser = stand:FindFirstChild("Rubber lift riser") or Instance.new("Part")
assert(riser:IsA("BasePart"))
riser.Name = "Rubber lift riser"
riser.Size = Vector3.new(.89,.30,.95)
riser.CFrame = saddle.CFrame*CFrame.new(0,.235,0)
riser.Color = Color3.fromRGB(46,46,46)
riser.Material = Enum.Material.Rubber
riser.Massless,riser.Anchored = true,true
riser.CanCollide,riser.CanQuery,riser.CanTouch = false,false,false
riser.Parent = stand
rest.Position = Vector3.new(0,.385,0)

local contact = frame:FindFirstChild("LiftContact") or Instance.new("Attachment")
assert(contact:IsA("Attachment"))
contact.Name = "LiftContact"
-- Contact on the underside of the SM50 crankcase, in chassis-relative studs.
contact.Position = frame.CFrame:PointToObjectSpace(frame:GetPivot():PointToWorldSpace(Vector3.new(0,-.925,-.05)))
contact.Parent = frame
service.Source = source
return "SM50 now aligns to BikeRest with a rubber lift riser"
