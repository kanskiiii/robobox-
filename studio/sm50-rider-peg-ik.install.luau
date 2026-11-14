-- Install SM50 footpeg IK and local hand movement for the existing cockpit levers.
local client=game:GetService("StarterPlayer").StarterPlayerScripts.TwoStrokeClient
local scriptObject=client.RiderPose
local source=scriptObject.Source
local function replace(old,new)
	local a,b=source:find(old,1,true)
	assert(a,"RiderPose integration point changed: "..old)
	source=source:sub(1,a-1)..new..source:sub(b+1)
end
if not source:find("local function addFootTargets",1,true) then
	replace("local poses = {}",'local Controller = require(script.Parent.BikeController)\nlocal poses = {}')
	replace("local function attach(player", [==[local function addFootTargets(pose, character)
    local bike = pose.chassis.Parent
    local frame = bike and bike:FindFirstChild("Frame")
    if not frame or not frame:IsA("BasePart") then return end
    for _, side in {"Left", "Right"} do
        local mark = frame:FindFirstChild("RiderFootPeg" .. side)
        local upper = character:FindFirstChild(side .. "UpperLeg")
        local foot = character:FindFirstChild(side .. "Foot")
        if not mark or not mark:IsA("Attachment") or not upper or not foot or not foot:IsA("BasePart") then continue end
        local target = Instance.new("Attachment")
        target.Name = "Rider" .. side .. "FootTarget"
        target.CFrame = mark.CFrame * CFrame.new(0, foot.Size.Y * .48, 0)
        target.Parent = frame
        table.insert(pose.created, target)
        local ik = Instance.new("IKControl")
        ik.Name = "TwoStroke" .. side .. "Leg"
        ik.Type = Enum.IKControlType.Position
        ik.ChainRoot, ik.EndEffector = upper, foot
        ik.Target, ik.SmoothTime, ik.Weight = target, .075, .88
        ik.Parent = pose.humanoid
        table.insert(pose.created, ik)
    end
end

local function attach(player]==])
	replace("accel=0, created={},", "accel=0, created={}, hands={},")
	replace("        target.Parent = bar", [==[        pose.hands[side] = {target=target, rest=target.Position}
        target.Parent = bar]==])
	replace("    return pose\nend", "    addFootTargets(pose, character)\n    return pose\nend")
	replace("        pose.waist[pose.property] = pose.rest * CFrame.Angles(pose.pitch, 0, pose.roll)",[==[        pose.waist[pose.property] = pose.rest * CFrame.Angles(pose.pitch, 0, pose.roll)
        if player == Players.LocalPlayer and Controller.active and Controller.getRoot() == chassis then
            for side, hand in pose.hands do
                local input = if side == "Left" then Controller.hud.clutch else Controller.hud.frontBrake
                local offset = bar.PivotOffset:VectorToWorldSpace(Vector3.new(0, -.026, -.055)) * math.clamp(input or 0, 0, 1)
                hand.target.Position = hand.target.Position:Lerp(hand.rest + offset, blend)
            end
        else
            for _, hand in pose.hands do hand.target.Position = hand.rest end
        end]==])
end
local frame=game:GetService("ReplicatedStorage").Assets.Vehicles.sm50.Frame
for _,side in {"Left","Right"} do
	local name="RiderFootPeg"..side
	local a=frame:FindFirstChild(name) or Instance.new("Attachment")
	assert(a:IsA("Attachment"))
	local sign=if side=="Left" then -1 else 1
	-- Peg center and upper serration surface, using the stock frame's authored metre coordinates.
	local peg = Vector3.new(sign*.175,.382-.55,.239-.014)/.28
	a.Name=name
	a.CFrame=frame.PivotOffset*CFrame.new(peg)
	a.Parent=frame
end
scriptObject.Source=source
return "Installed stock SM50 footpeg targets and rider hand movement"
