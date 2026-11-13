-- LocalScript in StarterPlayerScripts.TwoStrokeClient.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local poses = {}
-- The installed handlebar mesh pivot is its clamp. Values are in studs.
local gripX, gripY, gripZ = .313 * 1.051 / .28, .043 / .28, .051 / .28

local function clear(player)
    local pose = poses[player]
    if not pose then return end
    poses[player] = nil
    if pose.waist.Parent then pose.waist[pose.property] = pose.rest end
    for _, item in pose.created do item:Destroy() end
end

local function attach(player, character, humanoid, seat, chassis, bar)
    local upper = character:FindFirstChild("UpperTorso")
    local waist = upper and upper:FindFirstChild("Waist")
    if not waist then return nil end
    local joint, property = waist, "C0"
    if waist:IsA("AnimationConstraint") then
        joint, property = waist.Attachment0, "CFrame"
        if not joint then return nil end
    elseif not waist:IsA("Motor6D") then
        return nil
    end
    local arms = {}
    for _, side in {"Left", "Right"} do
        local arm = character:FindFirstChild(side .. "UpperArm")
        local hand = character:FindFirstChild(side .. "Hand")
        if not arm or not hand then return nil end
        arms[side] = {arm, hand}
    end

    local pose = {
        humanoid=humanoid, seat=seat, chassis=chassis, bar=bar, waist=joint,
        property=property, rest=joint[property], pitch=0, roll=0, lastSpeed=nil, accel=0, created={},
    }
    poses[player] = pose
    for _, side in {"Left", "Right"} do
        local sign = side == "Left" and -1 or 1
        local target = Instance.new("Attachment")
        target.Name = "Rider" .. side .. "Grip"
        target.CFrame = bar.PivotOffset * CFrame.new(sign * gripX, gripY + .06, gripZ)
        target.Parent = bar
        table.insert(pose.created, target)

        local ik = Instance.new("IKControl")
        ik.Name = "TwoStroke" .. side .. "Arm"
        ik.Type = Enum.IKControlType.Position
        ik.ChainRoot, ik.EndEffector = table.unpack(arms[side])
        ik.Target = target
        ik.SmoothTime = .055
        ik.Weight = 1
        ik.Parent = humanoid
        table.insert(pose.created, ik)
    end
    return pose
end

local removing = Players.PlayerRemoving:Connect(clear)
local update = RunService.PreAnimation:Connect(function(dt)
    if dt <= 0 then return end
    local blend = 1 - math.exp(-dt * 10)
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local seat = humanoid and humanoid.SeatPart
        local bike = seat and seat.Name == "RiderSeat" and seat.Parent
        local chassis = bike and bike:FindFirstChild("Chassis")
        local slot = bike and bike:FindFirstChild("Slot_Handlebar")
        local bar = slot and slot:FindFirstChild("Visual")
        if not humanoid or humanoid.Health <= 0 or humanoid.RigType ~= Enum.HumanoidRigType.R15
            or not chassis or not chassis:IsA("BasePart") or not bar or not bar:IsA("BasePart") then
            clear(player)
            continue
        end
        local pose = poses[player]
        if pose and (pose.humanoid ~= humanoid or pose.seat ~= seat or pose.bar ~= bar
            or pose.chassis ~= chassis) then
            clear(player)
            pose = nil
        end
        pose = pose or attach(player, character, humanoid, seat, chassis, bar)
        if not pose then continue end

        local forwardSpeed = chassis.AssemblyLinearVelocity:Dot(chassis.CFrame.LookVector)
        local accel = pose.lastSpeed and math.clamp((forwardSpeed - pose.lastSpeed) / dt, -36, 36) or 0
        pose.lastSpeed = forwardSpeed
        pose.accel += (accel - pose.accel) * blend
        local speedWeight = math.clamp(math.abs(forwardSpeed) / 60, 0, 1)
        local yawRate = chassis.AssemblyAngularVelocity:Dot(chassis.CFrame.UpVector)
        local pitch = math.rad(-25 - 7 * speedWeight + 5 * pose.accel / 36)
        local roll = math.rad(math.clamp(yawRate * 5, -7, 7)) * speedWeight
        pose.pitch += (pitch - pose.pitch) * blend
        pose.roll += (roll - pose.roll) * blend
        pose.waist[pose.property] = pose.rest * CFrame.Angles(pose.pitch, 0, pose.roll)
    end
end)
script.Destroying:Connect(function()
    update:Disconnect()
    removing:Disconnect()
    for player in poses do clear(player) end
end)
