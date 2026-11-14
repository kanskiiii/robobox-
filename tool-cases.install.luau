-- Run in Studio Edit mode. Requires the ToolCases ModuleScript from Claude's handoff.
local module = game.ServerScriptService.TwoStrokeServer.ToolCases
local editor = game:GetService("ScriptEditorService")
local edits = {
    {[==[				w.Part0, w.Part1 = body, p]==], [==[				w.Part0 = if p:IsDescendantOf(lid) then lid else body
				w.Part1 = p]==]},
    {[==[				p.Transparency = if show then 0 else 1]==], [==[				local custom = p:GetAttribute("ToolCaseHitbox") == true
				p.Transparency = if show and not custom then 0 else 1
				local detail = if custom then p:FindFirstChild("VisibleTool") else nil
				if detail then
					for _, child in detail:GetDescendants() do
						if child:IsA("BasePart") then child.Transparency = if show then 0 else 1 end
						if child:IsA("SurfaceGui") then child.Enabled = show end
					end
				end]==]},
}
local function revise(source)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected ToolCases source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end
revise(editor:GetEditorSource(module))

-- Run in Studio Edit mode to build the durable tool case models.
local assets = game.ReplicatedStorage.Assets
local library = assets:FindFirstChild("ToolCases")
if not library then
    library = Instance.new("Folder")
    library.Name = "ToolCases"
    library.Parent = assets
end

local scale = 1 / .28
local shell = Color3.fromRGB(31, 34, 38)
local edge = Color3.fromRGB(54, 58, 63)
local foam = Color3.fromRGB(65, 65, 68)
local recess = Color3.fromRGB(34, 35, 38)
local orange = Color3.fromRGB(232, 110, 25)
local steel = Color3.fromRGB(186, 193, 200)
local chrome = Color3.fromRGB(222, 229, 235)
local dark = Color3.fromRGB(47, 48, 50)
local red = Color3.fromRGB(145, 44, 30)
local metal, plastic, fabric = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Fabric

local function at(x, y, z)
    return CFrame.new(Vector3.new(x, y, z) * scale)
end

local function solid(parent, name, x, y, z, width, height, depth, color, material, shape, rotation)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.one
    p.CFrame = at(x, y, z) * (rotation or CFrame.identity)
    p.Material = material
    p.Color = color
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Massless = true
    p.CastShadow = false
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = shape or Enum.MeshType.Brick
    mesh.Scale = Vector3.new(width, height, depth) * scale
    mesh.Parent = p
    p.Parent = parent
    return p
end

local function bar(parent, name, x1, z1, x2, z2, y, width, height, color, material)
    local delta = Vector3.new(x2-x1, 0, z2-z1)
    return solid(parent, name, (x1+x2)/2, y, (z1+z2)/2, width, height, delta.Magnitude,
        color, material, nil, CFrame.lookAt(Vector3.zero, delta))
end

local function disc(parent, name, x, y, z, diameter, height, color, material)
    return solid(parent, name, x, y, z, height, diameter, diameter, color, material,
        Enum.MeshType.Cylinder, CFrame.Angles(0, 0, math.pi/2))
end

local function ring(parent, name, x, y, z, diameter, thickness, height, segments, color)
    local radius = diameter / 2
    for i = 1, segments do
        local first = (i-1)*2*math.pi/segments
        local last = i*2*math.pi/segments
        bar(parent, name, x+radius*math.cos(first), z+radius*math.sin(first),
            x+radius*math.cos(last), z+radius*math.sin(last), y, thickness, height, color, metal)
    end
end

local function frame(parent, name, w, d, y, height, color)
    for _, sign in {-1, 1} do
        solid(parent,name,0,y,sign*(d/2-.004),w-.019,height,.008,color,plastic)
        solid(parent,name,sign*(w/2-.004),y,0,.008,height,d-.019,color,plastic)
        for _, zSign in {-1, 1} do
            disc(parent,name,sign*(w/2-.009),y,zSign*(d/2-.009),.018,height,color,plastic)
        end
    end
end

local function hitbox(model, name, x, y, z, w, h, d)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(w,h,d) * scale
    p.CFrame = at(x,y,z)
    p.Transparency = 1
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Massless = true
    p:SetAttribute("ToolCaseHitbox",true)
    p.Parent = model
    local detail = Instance.new("Folder")
    detail.Name = "VisibleTool"
    detail.Parent = p
    return p, detail
end

local function stamp(parent, x, y, z, mm, width)
    local face = solid(parent,"SizeStamp",x,y,z,width,.002,.007,steel,metal)
    local text = Instance.new("SurfaceGui")
    text.Face = Enum.NormalId.Top
    text.CanvasSize = Vector2.new(120,55)
    text.LightInfluence = 1
    text.Parent = face
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(39,43,49)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = tostring(mm)
    label.Parent = text
end

local function caseModel(kind, w, h, d, trim)
    local model = Instance.new("Model")
    model.Name = kind
    model:SetAttribute("CodexToolCase", true)
    local body = hitbox(model,"Body",0,0,0,w,h,d)
    body.CanCollide = true
    body.CanQuery = false
    local base = Instance.new("Folder")
    base.Name = "CaseShell"
    base.Parent = body
    solid(base,"Bottom",0,-h/2+.004,0,w-.012,.008,d-.012,shell,plastic)
    frame(base,"Sidewall",w,d,-.002,h-.004,shell)
    frame(base,"Rim",w,d,h/2-.004,.008,trim)
    solid(base,"FittedTray",0,h/2-.024,0,w-.024,.008,d-.024,
        if kind=="RatchetSet" then Color3.fromRGB(173,76,20) else foam,fabric)
    local lid = hitbox(model,"Lid",0,h/2+.007,0,w,.014,d)
    local details = lid.VisibleTool
    solid(details,"LidPanel",0,h/2+.008,0,w-.016,.010,d-.016,shell,plastic)
    frame(details,"LidEdge",w,d,h/2+.006,.014,trim)
    for _, sign in {-1,1} do
        solid(base,"Latch",sign*w*.28,.008,d/2+.002,.032,.023,.009,trim,plastic)
        solid(details,"LatchCatch",sign*w*.28,h/2+.007,d/2+.003,.032,.009,.008,edge,plastic)
        solid(base,"HingeKnuckle",sign*w*.28,h/2-.002,-d/2-.002,.052,.009,.011,edge,plastic)
        solid(base,"HandlePost",sign*w*.115,-.002,d/2+.013,.010,.014,.030,edge,plastic)
    end
    solid(base,"HandleGrip",0,-.002,d/2+.026,w*.24,.015,.012,edge,plastic)
    local hinge = Instance.new("Attachment")
    hinge.Name = "Hinge"
    hinge.Position = Vector3.new(0,-.007,-d/2)*scale
    hinge.Parent = lid
    model.PrimaryPart = body
    return model
end

local sizes = {8,10,12,13,14,17,19}
local spanners = caseModel("SpannerSet",.46,.07,.34,edge)
bar(spanners,"DiagonalDivider",-.092,-.144,-.020,.144,.023,.009,.015,edge,plastic)

for index, mm in sizes do
    local length = .12+(mm-8)*.01
    local x, z = .152-(index-1)*.009, -.114+(index-1)*.039
    local diameter = .015+mm*.00055
    local rear, front = x-length*.42, x+length*.42
    solid(spanners,"FoamCutout",x,.016,z,length+.009,.003,diameter+.007,recess,fabric)
    local _, details = hitbox(spanners,"Spanner_"..mm,x,.023,z,length,.018,diameter)
    bar(details,"ForgedHandle",rear,z,front-.010,z,.023,.007+mm*.00012,.005,steel,metal)
    ring(details,"RingEnd",rear,.023,z,diameter,.0032,.005,10,chrome)
    local jaw = mm/2000+.0015
    for _, sign in {-1,1} do
        bar(details,"OpenJaw",front-.011,z+sign*.003,front+.005,z+sign*jaw,.023,.0045,.006,chrome,metal)
    end
    stamp(details,x,.027,z,mm,.014)
end

local function toolPocket(model, name,x,z,w,d)
    solid(model,"FoamCutout",x,.016,z,w+.006,.003,d+.007,recess,fabric)
    local _, details = hitbox(model,name,x,.024,z,w,.022,d)
    return details
end

local driver = toolPocket(spanners,"Screwdriver",-.188,-.011,.022,.224)
bar(driver,"Shaft",-.188,-.116,-.188,.030,.023,.004,.004,chrome,metal)
bar(driver,"Handle",-.188,.027,-.188,.094,.023,.017,.016,orange,plastic)
bar(driver,"GripInset",-.188,.038,-.188,.082,.031,.012,.003,dark,plastic)
bar(driver,"PhillipsTip",-.188,-.119,-.188,-.106,.023,.003,.003,steel,metal)

local plug = toolPocket(spanners,"PlugWrench",-.127,.023,.069,.119)
bar(plug,"Tube",-.127,-.029,-.127,.076,.023,.017,.016,steel,metal)
bar(plug,"SlidingTBar",-.158,-.014,-.097,-.014,.030,.005,.005,chrome,metal)

local pliers = toolPocket(spanners,"Pliers",-.067,.055,.051,.132)
disc(pliers,"Pivot",-.067,.025,.026,.015,.008,steel,metal)
for _, sign in {-1,1} do
    bar(pliers,"Jaws",-.067+sign*.003,.027,-.067+sign*.008,-.006,.025,.006,.006,chrome,metal)
    bar(pliers,"Handles",-.067+sign*.004,.031,-.067+sign*.017,.107,.024,.009,.013,red,plastic)
end
solid(spanners,"Ruler",-.135,.023,-.135,.117,.002,.012,steel,metal)
for index = 0, 13 do
    solid(spanners,"RulerMark",-.188+index*.008,.0244,-.135,.0006,.001,if index%5==0 then .009 else .004,dark,metal)
end

local ratchet = caseModel("RatchetSet",.30,.06,.20,orange)
local xRatchet = -.093
solid(ratchet,"RatchetPocket",xRatchet,.012,.007,.046,.004,.165,recess,fabric)
local _, ratchetTool = hitbox(ratchet,"Ratchet",xRatchet,.020,.007,.037,.025,.160)
disc(ratchetTool,"ChromeHead",xRatchet,.020,-.056,.029,.014,chrome,metal)
bar(ratchetTool,"Lever",xRatchet,-.064,xRatchet+.008,-.058,.027,.004,.004,dark,metal)
bar(ratchetTool,"Shank",xRatchet,-.051,xRatchet,.075,.021,.008,.009,steel,metal)
bar(ratchetTool,"Handle",xRatchet,.015,xRatchet,.078,.020,.019,.016,dark,plastic)
bar(ratchetTool,"GripInset",xRatchet,.023,xRatchet,.070,.027,.009,.003,orange,plastic)

for index, mm in sizes do
    local col, row = (index-1)%4, (index-1)//4
    local x, z = -.039+col*.043, -.058+row*.048
    local diameter = (mm+6)/1000
    disc(ratchet,"SocketPost",x,.012,z,diameter+.006,.006,orange,plastic)
    local _, socket = hitbox(ratchet,"Socket_"..mm,x,.018,z,diameter+.004,.023,diameter+.004)
    disc(socket,"ChromeBody",x,.017,z,diameter,.016,steel,metal)
    disc(socket,"DarkBore",x,.0256,z,mm/1000,.002,dark,metal)
    ring(socket,"SixPointMouth",x,.027,z,mm/1000+.003,.0018,.003,6,chrome)
    stamp(socket,x,.027,z+.013,mm,.012)
end
bar(ratchet,"ExtensionPocket",-.031,.055,.122,.055,.013,.019,.005,recess,fabric)
bar(ratchet,"ExtensionBar",-.026,.055,.115,.055,.020,.009,.009,chrome,metal)
disc(ratchet,"SparePlugSocket",.112,.017,-.008,.026,.017,steel,metal)

for _, model in {spanners,ratchet} do
    local old = library:FindFirstChild(model.Name)
    assert(not old or old:GetAttribute("CodexToolCase"), "Existing tool case template: "..model.Name)
end
for _, model in {spanners,ratchet} do
    local old = library:FindFirstChild(model.Name)
    if old then old:Destroy() end
    model.Parent = library
end

editor:UpdateSourceAsync(module, revise)
