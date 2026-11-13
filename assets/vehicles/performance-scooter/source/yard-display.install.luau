-- Run in Studio Edit mode. Reuses the Thunder3 visual meshes from dualtron test.rbxl.
local AssetService = game:GetService("AssetService")
local displayName = "Yard Scooter Display"
local accent = Color3.fromRGB(36, 166, 150)
local accents = {
    NeckAccent = true,
    SideWallL = true,
    SideWallR = true,
    FrontRim = true,
    RearRim = true,
}

-- Source mesh ID, position, dimensions, and paint. All source parts face 180 degrees around Y.
local parts = {
    {"BarBolts", "102452294525362", Vector3.new(0, 4.4, -0.46921), Vector3.new(1.27992, 0.136, 0.025), Color3.fromRGB(180, 180, 180)},
    {"BrakeLeverL", "71486822803289", Vector3.new(-0.87482, 4.36431, -0.70041), Vector3.new(0.49087, 0.10592, 0.12899), Color3.fromRGB(180, 180, 180)},
    {"BrakeLeverR", "80502089390044", Vector3.new(0.87482, 4.36431, -0.70041), Vector3.new(0.49087, 0.10592, 0.12899), Color3.fromRGB(180, 180, 180)},
    {"BrakeMasterL", "106745076863403", Vector3.new(-0.64, 4.46, -0.59171), Vector3.new(0.12, 0.18, 0.15), Color3.fromRGB(20, 20, 20)},
    {"BrakeMasterR", "133595185447244", Vector3.new(0.64, 4.46, -0.59171), Vector3.new(0.12, 0.18, 0.15), Color3.fromRGB(20, 20, 20)},
    {"Btn_Hazard", "126180629055061", Vector3.new(-0.53999, 4.175, -0.43671), Vector3.new(0.06382, 0.064, 0.02), Color3.fromRGB(180, 180, 180)},
    {"Btn_Horn", "93078091863441", Vector3.new(-0.545, 4.295, -0.43671), Vector3.new(0.06382, 0.064, 0.02), Color3.fromRGB(180, 180, 180)},
    {"Btn_Light", "85529169005143", Vector3.new(-0.7, 4.175, -0.43671), Vector3.new(0.06382, 0.064, 0.02), Color3.fromRGB(180, 180, 180)},
    {"Btn_Swag", "85800700400937", Vector3.new(-0.62, 4.255, -0.43671), Vector3.new(0.06382, 0.064, 0.02), Color3.fromRGB(180, 180, 180)},
    {"Btn_Turbo", "138637594735743", Vector3.new(0.72, 4.26, -0.45169), Vector3.new(0.07, 0.06, 0.03), Color3.fromRGB(200, 28, 28)},
    {"Btn_TurnL", "125492209382428", Vector3.new(-0.7, 4.295, -0.44171), Vector3.new(0.06016, 0.06, 0.03037), Color3.fromRGB(20, 20, 20)},
    {"Btn_TurnR", "90208090589120", Vector3.new(-0.64, 4.295, -0.44171), Vector3.new(0.06016, 0.06, 0.03037), Color3.fromRGB(20, 20, 20)},
    {"Cables", "74974839684019", Vector3.new(-0.12442, 2.83351, -0.81271), Vector3.new(0.88148, 3.45598, 1.00103), Color3.fromRGB(20, 20, 20)},
    {"DisplayMount", "93293943957255", Vector3.new(0, 4.49, -0.5517), Vector3.new(0.3, 0.1, 0.12), Color3.fromRGB(20, 20, 20)},
    {"FoldClamp", "95983542130181", Vector3.new(0, 1.95645, -1.07111), Vector3.new(0.32, 0.3687, 0.38411), Color3.fromRGB(20, 20, 20)},
    {"FoldLever", "120092738974190", Vector3.new(0.19, 2.02497, -1.05957), Vector3.new(0.06, 0.41986, 0.14412), Color3.fromRGB(180, 180, 180)},
    {"FrontArmL", "99653256581865", Vector3.new(-0.34, 0.74372, -1.46979), Vector3.new(0.075, 0.62799, 0.4729), Color3.fromRGB(30, 30, 30)},
    {"FrontArmR", "74792907585673", Vector3.new(0.34, 0.74372, -1.46979), Vector3.new(0.075, 0.62799, 0.4729), Color3.fromRGB(30, 30, 30)},
    {"FrontAxleNutL", "75259094827643", Vector3.new(-0.38, 0.5, -1.64999), Vector3.new(0.04, 0.0866, 0.09478), Color3.fromRGB(180, 180, 180)},
    {"FrontAxleNutR", "84964247539882", Vector3.new(0.38, 0.5, -1.64999), Vector3.new(0.04, 0.0866, 0.09478), Color3.fromRGB(180, 180, 180)},
    {"FrontCaliper", "109760276202969", Vector3.new(-0.23, 0.71, -1.51999), Vector3.new(0.09, 0.24139, 0.25612), Color3.fromRGB(180, 180, 180)},
    {"FrontCartridgeL", "135162452248089", Vector3.new(-0.35001, 0.97787, -1.27496), Vector3.new(0.14, 0.1999, 0.19979), Color3.fromRGB(15, 15, 15)},
    {"FrontCartridgeR", "134605680416022", Vector3.new(0.35001, 0.97787, -1.27496), Vector3.new(0.14, 0.1999, 0.19979), Color3.fromRGB(15, 15, 15)},
    {"FrontWheelDisc", "70533502082778", Vector3.new(-0.2, 0.5, -1.64999), Vector3.new(0.01, 0.56, 0.56), Color3.fromRGB(180, 180, 180)},
    {"FrontFender", "88049136711368", Vector3.new(0, 0.87745, -1.47968), Vector3.new(0.38, 0.41999, 0.77394), Color3.fromRGB(30, 30, 30)},
    {"FrontHub", "76123081323204", Vector3.new(0, 0.5, -1.64999), Vector3.new(0.48, 0.5, 0.5), Color3.fromRGB(20, 20, 20)},
    {"FrontRim", "135931480695069", Vector3.new(0, 0.5, -1.64999), Vector3.new(0.28, 0.67, 0.67), Color3.fromRGB(180, 180, 180)},
    {"FrontWheel", "133264229625518", Vector3.new(0, 0.5, -1.64999), Vector3.new(0.3, 0.97, 0.97375), Color3.fromRGB(15, 15, 15)},
    {"GripL", "82722815868187", Vector3.new(-0.86488, 4.4, -0.53976), Vector3.new(0.46977, 0.1899, 0.2139), Color3.fromRGB(15, 15, 15)},
    {"GripR", "108979288924626", Vector3.new(0.86488, 4.4, -0.53976), Vector3.new(0.46977, 0.1899, 0.2139), Color3.fromRGB(15, 15, 15)},
    {"SteerBody", "112658547222326", Vector3.new(0, 2.69523, -0.94766), Vector3.new(2.18, 3.57906, 0.96192), Color3.fromRGB(30, 30, 30)},
    {"SwitchBoxL", "70902399258487", Vector3.new(-0.62, 4.3025, -0.54919), Vector3.new(0.28, 0.415, 0.205), Color3.fromRGB(30, 30, 30)},
    {"ThrottlePuck", "73727570597641", Vector3.new(0.52032, 4.45075, -0.67377), Vector3.new(0.19617, 0.21151, 0.33412), Color3.fromRGB(30, 30, 30)},
    {"ThrottleFace", "89708060663420", Vector3.new(0.52, 4.5018, -0.72183), Vector3.new(0.16983, 0.10281, 0.15212), Color3.fromRGB(20, 20, 20)},
    {"ThrottleLever", "72620100236002", Vector3.new(0.7048, 4.50504, -0.79721), Vector3.new(0.22241, 0.1297, 0.14666), Color3.fromRGB(20, 20, 20)},
    {"TurboBox", "73654808522307", Vector3.new(0.72, 4.25, -0.50171), Vector3.new(0.11, 0.13, 0.09), Color3.fromRGB(30, 30, 30)},
    {"ringHazard", "110497579532092", Vector3.new(-0.53999, 4.175, -0.4437), Vector3.new(0.086, 0.08571, 0.01141), Color3.fromRGB(180, 180, 180)},
    {"ringHorn", "132332781552893", Vector3.new(-0.545, 4.295, -0.4437), Vector3.new(0.086, 0.08571, 0.01141), Color3.fromRGB(180, 180, 180)},
    {"ringLight", "112659031573855", Vector3.new(-0.7, 4.175, -0.4437), Vector3.new(0.086, 0.08571, 0.01141), Color3.fromRGB(180, 180, 180)},
    {"ringSwag", "74659505452842", Vector3.new(-0.62, 4.175, -0.4437), Vector3.new(0.086, 0.08571, 0.01141), Color3.fromRGB(180, 180, 180)},
    {"Belly", "77568873862481", Vector3.new(0, 0.61, 0.07001), Vector3.new(0.92, 0.08, 1.76), Color3.fromRGB(20, 20, 20)},
    {"Frame", "112142832314361", Vector3.new(0, 0.83, -0.07001), Vector3.new(1.12, 0.36, 2.28), Color3.fromRGB(30, 30, 30)},
    {"DeckRubber", "104061646672335", Vector3.new(0, 1.0225, -0.035), Vector3.new(0.94, 0.025, 2.07), Color3.fromRGB(15, 15, 15)},
    {"FootPadRubber", "100456960008238", Vector3.new(0, 1.545, 1.64001), Vector3.new(0.74, 0.012, 0.4), Color3.fromRGB(15, 15, 15)},
    {"Footrest", "106750086687199", Vector3.new(0, 1.2425, 1.36499), Vector3.new(0.8, 0.585, 1.01), Color3.fromRGB(30, 30, 30)},
    {"HeadLampHousingL", "126430128053647", Vector3.new(-0.34351, 1.32, -1.29849), Vector3.new(0.327, 0.274, 0.337), Color3.fromRGB(20, 20, 20)},
    {"HeadLampHousingR", "86296957216400", Vector3.new(0.34351, 1.32, -1.29849), Vector3.new(0.327, 0.274, 0.337), Color3.fromRGB(20, 20, 20)},
    {"Kickstand", "128054447774311", Vector3.new(-0.56448, 0.36313, 0.62949), Vector3.new(0.29641, 0.68295, 0.32487), Color3.fromRGB(180, 180, 180)},
    {"Neck", "120672723317696", Vector3.new(0, 1.15882, -0.99475), Vector3.new(0.67165, 0.90657, 0.72169), Color3.fromRGB(30, 30, 30)},
    {"NeckAccent", "93851530049426", Vector3.new(0, 1.33, -1), Vector3.new(0.42, 0.18337, 0.22129), Color3.fromRGB(200, 28, 28)},
    {"PlateFace", "101971965228012", Vector3.new(0, 0.52, 2.242), Vector3.new(0.3, 0.19766, 0.03867), Color3.fromRGB(30, 30, 30)},
    {"RearArmL", "128002991767471", Vector3.new(-0.34, 0.63596, 1.27762), Vector3.new(0.075, 0.44833, 0.81532), Color3.fromRGB(30, 30, 30)},
    {"RearArmR", "95589140019054", Vector3.new(0.34, 0.63596, 1.27762), Vector3.new(0.075, 0.44833, 0.81532), Color3.fromRGB(30, 30, 30)},
    {"RearAxleNutL", "89368686619841", Vector3.new(-0.38, 0.5, 1.64999), Vector3.new(0.04, 0.0866, 0.09478), Color3.fromRGB(180, 180, 180)},
    {"RearAxleNutR", "81915359896946", Vector3.new(0.38, 0.5, 1.64999), Vector3.new(0.04, 0.0866, 0.09478), Color3.fromRGB(180, 180, 180)},
    {"RearCaliper", "110639290150973", Vector3.new(-0.23, 0.71, 1.78), Vector3.new(0.09, 0.24139, 0.25612), Color3.fromRGB(180, 180, 180)},
    {"RearCartridgeL", "83835990697615", Vector3.new(-0.35001, 0.77, 0.89987), Vector3.new(0.14, 0.21989, 0.21977), Color3.fromRGB(15, 15, 15)},
    {"RearCartridgeR", "102423125008844", Vector3.new(0.35001, 0.77, 0.89987), Vector3.new(0.14, 0.21989, 0.21977), Color3.fromRGB(15, 15, 15)},
    {"RearWheelDisc", "98358659436937", Vector3.new(-0.2, 0.5, 1.64999), Vector3.new(0.01, 0.56, 0.56), Color3.fromRGB(180, 180, 180)},
    {"RearFender", "107296499041555", Vector3.new(0, 0.7289, 1.86313), Vector3.new(0.494, 0.74287, 0.7919), Color3.fromRGB(30, 30, 30)},
    {"RearHub", "97360268396446", Vector3.new(0, 0.5, 1.64999), Vector3.new(0.48, 0.5, 0.5), Color3.fromRGB(20, 20, 20)},
    {"RearPivotCapL", "114196096282845", Vector3.new(-0.42999, 0.77, 0.89999), Vector3.new(0.02, 0.13961, 0.14), Color3.fromRGB(180, 180, 180)},
    {"RearPivotCapR", "140312134577658", Vector3.new(0.42999, 0.77, 0.89999), Vector3.new(0.02, 0.13961, 0.14), Color3.fromRGB(180, 180, 180)},
    {"RearRim", "102465775225421", Vector3.new(0, 0.5, 1.64999), Vector3.new(0.28, 0.67, 0.67), Color3.fromRGB(180, 180, 180)},
    {"RearWheel", "116848574688800", Vector3.new(0, 0.5, 1.64999), Vector3.new(0.3, 0.97, 0.97375), Color3.fromRGB(15, 15, 15)},
    {"SideWallL", "77595860691782", Vector3.new(-0.58501, 0.82, 0.20001), Vector3.new(0.09, 0.3, 1.6), Color3.fromRGB(30, 30, 30)},
    {"SideWallR", "99449532573288", Vector3.new(0.58501, 0.82, 0.20001), Vector3.new(0.09, 0.3, 1.6), Color3.fromRGB(30, 30, 30)},
    {"SpeakerGrille", "94200837710149", Vector3.new(0, 1.3, -1.39001), Vector3.new(0.2, 0.2, 0.06), Color3.fromRGB(180, 180, 180)},
    {"TailLightHousing", "129455829004597", Vector3.new(0, 1.42, 1.89999), Vector3.new(0.56, 0.1, 0.07), Color3.fromRGB(20, 20, 20)},
}

local map = workspace:FindFirstChild("Map")
assert(map, "The Two-Stroke map is required")
local yard = map:FindFirstChild("Yard")
assert(yard and yard:IsA("BasePart"), "The garage yard is required")
local localPosition = yard.CFrame:PointToObjectSpace(Vector3.new(13, 0, 18))
local surface = yard.CFrame:PointToWorldSpace(Vector3.new(localPosition.X, yard.Size.Y / 2, localPosition.Z))
local placement = CFrame.new(surface) * CFrame.Angles(0, math.rad(-28), 0)
local sourceRotation = CFrame.Angles(0, math.pi, 0)

local display = Instance.new("Model")
display.Name = displayName
display.WorldPivot = placement
local ok, errorMessage = pcall(function()
    for i, spec in parts do
        local name, id, position, size, color = table.unpack(spec)
        local mesh = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id))
        mesh.Name = name
        mesh.Size = size
        mesh.CFrame = placement * CFrame.new(position) * sourceRotation
        mesh.Color = if accents[name] then accent else color
        mesh.Material = if accents[name] then Enum.Material.Metal else Enum.Material.SmoothPlastic
        mesh.Anchored = true
        mesh.CanCollide = false
        mesh.CanTouch = false
        mesh.CanQuery = false
        mesh.Parent = display
        if i % 8 == 0 then task.wait() end
    end
end)
if not ok then
    display:Destroy()
    error(errorMessage)
end
local previous = map:FindFirstChild(displayName)
if previous then previous:Destroy() end
display.Parent = map
return ("Installed %d scooter meshes"):format(#parts)
