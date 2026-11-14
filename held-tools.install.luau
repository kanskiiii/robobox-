-- Install first-person models from the matching garage tool geometry.
local assets = game.ReplicatedStorage.Assets
local cases = assets:FindFirstChild("ToolCases")
assert(cases and cases:FindFirstChild("SpannerSet") and cases:FindFirstChild("RatchetSet"), "Install tool-cases.install.luau first")
local scale = 1 / .28
local staged = Instance.new("Folder")
local up = CFrame.Angles(math.pi/2, 0, 0)
local sizes = {8, 10, 12, 13, 14, 17, 19}

local function glovePart(model, name, position, dimensions, color, rotation)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.one
    part.CFrame = CFrame.new(position * scale) * (rotation or CFrame.identity)
    part.Color = color
    part.Material = Enum.Material.Fabric
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = dimensions * scale
    mesh.Parent = part
    part.Parent = model
end

local function addGlove(model)
    local cloth = Color3.fromRGB(31, 34, 37)
    local armor = Color3.fromRGB(51, 54, 58)
    glovePart(model, "Palm", Vector3.new(.037,-.016,-.016), Vector3.new(.077,.088,.036), cloth, CFrame.Angles(0,0,-.23))
    glovePart(model, "Wrist", Vector3.new(.070,-.070,-.017), Vector3.new(.067,.084,.043), cloth, CFrame.Angles(0,0,-.44))
    glovePart(model, "Thumb", Vector3.new(.021,.030,.012), Vector3.new(.050,.022,.022), armor, CFrame.Angles(0,0,.33))
    for i = 1,4 do
        local y = .015-(i-1)*.019
        glovePart(model, "Finger_"..i, Vector3.new(.006,y,.010), Vector3.new(.045,.017,.022), cloth, CFrame.Angles(0,.25,0))
        glovePart(model, "Knuckle_"..i, Vector3.new(.026,y,.023), Vector3.new(.024,.015,.009), armor)
    end
end

local function build(case, name, gripName, orientation)
    local item = case:FindFirstChild(name)
    local visible = item and item:FindFirstChild("VisibleTool")
    local grip = visible and visible:FindFirstChild(gripName)
    assert(grip and grip:IsA("BasePart"), "Missing grip for "..name)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("CodexHeldTool", true)
    local gripOrigin = CFrame.new(grip.Position)
    for _, part in visible:GetChildren() do
        if not part:IsA("BasePart") then continue end
        local detail = part:Clone()
        detail.CFrame = orientation * gripOrigin:ToObjectSpace(part.CFrame)
        detail.Anchored = true
        detail.CanCollide = false
        detail.CanQuery = false
        detail.CanTouch = false
        detail.CastShadow = false
        detail.Parent = model
    end
    model.WorldPivot = CFrame.identity
    addGlove(model)
    model.Parent = staged
    return model, gripOrigin
end

local spanner, ratchet = cases.SpannerSet, cases.RatchetSet
local rightToUp = up * CFrame.Angles(0,math.pi/2,0)
for _, mm in sizes do
    build(spanner, "Spanner_"..mm, "ForgedHandle", rightToUp)
end
build(spanner,"Screwdriver","Handle",up)
build(spanner,"Pliers","Handles",up)
build(spanner,"PlugWrench","SlidingTBar",CFrame.Angles(-math.pi/2,0,0))
local driver, gripOrigin = build(ratchet,"Ratchet","Handle",up)
local socket = ratchet.Socket_10.VisibleTool.ChromeBody:Clone()
local head = ratchet.Ratchet.VisibleTool.ChromeHead
socket.Name = "FittedSocket"
socket.CFrame = up * gripOrigin:ToObjectSpace(CFrame.new(head.Position + Vector3.new(0,-.013*scale,0)) * socket.CFrame.Rotation)
socket.Anchored = true
socket.Parent = driver

local target = assets:FindFirstChild("HeldTools")
if not target then
    target = Instance.new("Folder")
    target.Name = "HeldTools"
    target.Parent = assets
end
for _, model in staged:GetChildren() do
    local previous = target:FindFirstChild(model.Name)
    assert(not previous or previous:GetAttribute("CodexHeldTool"), "Existing held model: "..model.Name)
end
for _, model in staged:GetChildren() do
    local previous = target:FindFirstChild(model.Name)
    if previous then previous:Destroy() end
    model.Parent = target
end
staged:Destroy()
