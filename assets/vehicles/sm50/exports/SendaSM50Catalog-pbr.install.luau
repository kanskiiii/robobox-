-- Select the imported SendaSM50Catalog model, then run this in Studio's Command Bar.
-- Set false when the raw mesh already faces -Z. The tested Roblox import faces +Z.
local meshFacesPositiveZ = true
local install = (function()
-- Installs a Roblox-imported assembly or world catalog using manifest geometry.
local function install(imported, manifest, meshFacesPositiveZ)
    assert(typeof(imported) == "Instance" and imported:IsA("Model"), "Select the imported catalog Model")
    local catalogId = manifest.assetId
    assert(catalogId == "sm50-catalog" or catalogId == "senda-catalog" or catalogId == "world-catalog",
        "Unsupported catalog")
    local vehicleId = catalogId == "senda-catalog" and "senda" or "sm50"
    assert(manifest.orientation.metresPerStud == 0.28, "Unexpected catalog scale")
    -- Roblox can bake the imported mesh's forward direction into its vertices.
    -- Restore the catalog basis around the mesh centre, keeping mount pivots canonical.
    local meshBasis = if meshFacesPositiveZ then CFrame.Angles(0, math.pi, 0) else CFrame.identity

    local history = game:GetService("ChangeHistoryService")
    local storage = game:GetService("ReplicatedStorage")
    local service = game:GetService("AssetService")
    local staged, used = {}, {}
    local function studs(value)
        return Vector3.new(value[1], value[2], value[3]) / manifest.orientation.metresPerStud
    end
    local function folder(parent, name, create)
        if not parent then return nil end
        local item = parent:FindFirstChild(name)
        if item then
            assert(item:IsA("Folder"), item:GetFullName() .. " must be a Folder")
        elseif create then
            item = Instance.new("Folder")
            item.Name = name
            item.Parent = parent
        end
        return item
    end
    local function groupFor(category, create)
        local assets = folder(storage, "Assets", create)
        local group = folder(assets, category, create)
        if category == "Vehicles" then return folder(group, vehicleId, create) end
        return group
    end
    local function findMesh(entry)
        local aliases = {[entry.node]=true, [entry.node .. "_Node"]=true, [entry.node .. "_Geometry"]=true}
        local candidates = {}
        for _, item in imported:GetDescendants() do
            if item:IsA("MeshPart") then
                local ancestor = item
                while ancestor ~= imported do
                    if aliases[ancestor.Name] then
                        table.insert(candidates, item)
                        break
                    end
                    ancestor = ancestor.Parent
                end
            end
        end
        assert(#candidates == 1, entry.node .. " needs exactly one imported MeshPart; found " .. #candidates)
        return candidates[1]
    end
    for _, entry in manifest.components do
        assert(#entry.materials == 1, "Expected one material layer per catalog entry")
        local mesh = findMesh(entry)
        assert(not used[mesh], "Imported mesh matched more than one entry: " .. entry.node)
        used[mesh] = true
        assert(mesh.MeshContent.SourceType == Enum.ContentSourceType.Uri,
            "Import with Upload to Roblox enabled: " .. entry.node)
        assert(mesh.CFrame.RightVector:Dot(Vector3.xAxis) > 0.999
            and mesh.CFrame.UpVector:Dot(Vector3.yAxis) > 0.999,
            "Import with +Y up and -Z forward, with no root rotation: " .. entry.node)
        local group = groupFor(entry.category, false)
        local previous = group and group:FindFirstChild(entry.name)
        if previous then
            assert(previous:IsA("MeshPart") and previous:GetAttribute("AssetId") == entry.assetId,
                "Existing instance has a different asset identity: " .. previous:GetFullName())
        end

        local b = entry.materialBoundsM[entry.materials[1]]
        local size = studs(b.size)
        local center = (studs(b.min) + studs(b.max)) / 2
        local ratio = mesh.MeshSize / size
        assert(ratio.Y > 0 and math.abs(ratio.X - ratio.Y) < 0.08 * ratio.Y
            and math.abs(ratio.Y - ratio.Z) < 0.08 * ratio.Y,
            "Imported mesh bounds do not match the manifest: " .. entry.node)
        local part = mesh:Clone()
        local boxMesh = service:CreateMeshPartAsync(mesh.MeshContent,
            {CollisionFidelity = Enum.CollisionFidelity.Box})
        boxMesh.TextureContent = mesh.TextureContent
        part:ApplyMesh(boxMesh)
        boxMesh:Destroy()
        part.Name = entry.name
        part.Size = size
        part.CFrame = CFrame.new(center) * meshBasis
        part.PivotOffset = part.CFrame:Inverse()
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part:SetAttribute("AssetId", entry.assetId)
        part:SetAttribute("TriangleCount", entry.triangles)
        part:SetAttribute("PreviewOnly", nil)
        for name, value in entry.attachmentLocalM do
            local marker = part:FindFirstChild(name)
            if marker then
                assert(marker:IsA("Attachment"), "Unexpected child " .. name)
            else
                marker = Instance.new("Attachment")
                marker.Name = name
                marker.Parent = part
            end
            marker.Position = part.CFrame:PointToObjectSpace(studs(value))
        end
        assert(part.MeshContent.SourceType == Enum.ContentSourceType.Uri, entry.node .. " lost its asset URI")
        table.insert(staged, {part=part, previous=previous, category=entry.category})
    end

    local recording = history:TryBeginRecording("Install Two-Stroke durable catalog")
    local ok, err = pcall(function()
        for _, record in staged do
            local group = groupFor(record.category, true)
            assert(group:FindFirstChild(record.part.Name) == record.previous, "Catalog changed during import")
            record.destination = group
            if record.previous then record.previous.Parent = nil end
            record.part.Parent = group
        end
    end)
    if recording then
        history:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
    end
    if not ok then
        for _, record in staged do
            record.part:Destroy()
            if record.destination and record.previous and not record.previous.Parent then
                record.previous.Parent = record.destination
            end
        end
        error(err)
    end
    return #staged
end

return install

end)()
local selection = game:GetService("Selection"):Get()
assert(#selection == 1, "Select exactly one imported catalog Model")
local manifest = game:GetService("HttpService"):JSONDecode([==[{"assetId":"senda-catalog","orientation":{"units":"m","up":"+Y","forward":"-Z","riderLeft":"-X","metresPerStud":0.28},"components":[{"name":"Frame","node":"Frame","category":"Vehicles","assetId":"senda-catalog.Frame","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.220368,-0.287954,-0.47411],"max":[0.220368,0.402361,0.785415],"size":[0.440736,0.690315,1.259525]}},"attachmentLocalM":{"Mount_FrontFork":[0,0.326,-0.398],"Mount_Handlebar":[0,0.456,-0.348],"Mount_FrontWheel":[0,-0.25,-0.7],"Mount_FrontBrake":[0.083,-0.25,-0.7],"Mount_Swingarm":[0,-0.102,0.19],"Mount_RearShock":[0,0.176,0.258],"Mount_RearWheel":[0,-0.25,0.665],"Mount_RearBrake":[0.103,-0.25,0.665],"Mount_RearSprocket":[-0.109,-0.25,0.665],"Mount_EngineBlock":[0,-0.175,-0.063],"Mount_Clutch":[0.071,-0.179,0.039],"Mount_FrontSprocket":[-0.109,-0.148,0.16],"Mount_Piston":[0,-0.006425,-0.099552],"Mount_Cylinder":[0,-0.061,-0.087],"Mount_CylinderHead":[0,0.072514,-0.117708],"Mount_SparkPlug":[0,0.1037,-0.124881],"Mount_Carburetor":[0,-0.018,0.081],"Mount_AirFilter":[0,0.086,0.306],"Mount_Exhaust":[0.013,-0.012,-0.147],"Mount_Ignition":[-0.08,0.15,0.3],"Mount_Chain":[-0.109,-0.148,0.16],"Mount_Radiator":[-0.077,0.151,-0.254],"Mount_FuelTank":[0,0.253,-0.17],"Mount_FuelLine":[-0.058,0.264,0.081],"Mount_Seat":[0,0.27,0.26],"Mount_FrontFender":[0,0.29,-0.5],"Mount_HeadlightMask":[0,0.43,-0.56],"Mount_SidePanelL":[-0.122,0.261,0.67],"Mount_SidePanelR":[0.122,0.261,0.67],"Mount_TailPlate":[0,0.286,0.665],"Mount_CoolantHoses":[0,0.1037,-0.124881],"Mount_Kickstarter":[0.123,-0.129,0.108],"Mount_GearLever":[-0.111,-0.196,0.094],"Mount_FlywheelStator":[-0.112,-0.148,-0.028],"Mount_IgnitionCoil":[0.075,0.174,-0.25],"Mount_OilTank":[0.075,0.138,0.37],"Mount_OilPump":[0.112,-0.102,-0.075],"Mount_OilLine":[0.092,0.087,0.36]},"triangles":3472},{"name":"Part_sd_wheel_front_17","node":"Part_sd_wheel_front_17","category":"Parts","assetId":"senda-catalog.Part_sd_wheel_front_17","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.05,-0.296,-0.296],"max":[0.05,0.296,0.296],"size":[0.1,0.592,0.592]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":3808},{"name":"Part_sd_wheel_rear_17","node":"Part_sd_wheel_rear_17","category":"Parts","assetId":"senda-catalog.Part_sd_wheel_rear_17","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.065,-0.307,-0.307],"max":[0.065,0.307,0.307],"size":[0.13,0.614,0.614]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":3808},{"name":"Part_sd_brake_front_std","node":"Part_sd_brake_front_std","category":"Parts","assetId":"senda-catalog.Part_sd_brake_front_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.02,-0.1395,-0.1395],"max":[0.0255,0.148331,0.1395],"size":[0.0455,0.287831,0.279]}},"attachmentLocalM":{"Bolt_1":[0,0.035,0],"Bolt_2":[0,-0.035,0]},"triangles":2432},{"name":"Part_sd_brake_rear_std","node":"Part_sd_brake_rear_std","category":"Parts","assetId":"senda-catalog.Part_sd_brake_rear_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.02,-0.1065,-0.1065],"max":[0.0255,0.126033,0.1065],"size":[0.0455,0.232533,0.213]}},"attachmentLocalM":{"Bolt_1":[0,0.035,0],"Bolt_2":[0,-0.035,0]},"triangles":2432},{"name":"Part_sd_handlebar_std","node":"Part_sd_handlebar_std","category":"Parts","assetId":"senda-catalog.Part_sd_handlebar_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.415,-0.05159,-0.114],"max":[0.415,0.076,0.085307],"size":[0.83,0.12759,0.199307]}},"attachmentLocalM":{"Bolt_1":[-0.046819,0.015,0.009],"Bolt_2":[0.046819,0.015,0.009],"Bolt_3":[-0.046819,0.015,-0.016],"Bolt_4":[0.046819,0.015,-0.016]},"triangles":5112},{"name":"Part_sd_fork_std","node":"Part_sd_fork_std","category":"Parts","assetId":"senda-catalog.Part_sd_fork_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.137,-0.609,-0.334957],"max":[0.137,0.122582,0.041723],"size":[0.274,0.731582,0.37668]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":4072},{"name":"Part_sd_swingarm_std","node":"Part_sd_swingarm_std","category":"Parts","assetId":"senda-catalog.Part_sd_swingarm_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.163842,-0.23,-0.025293],"max":[0.163842,0.042271,0.513],"size":[0.327684,0.272271,0.538293]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":648},{"name":"Part_sd_shock_std","node":"Part_sd_shock_std","category":"Parts","assetId":"senda-catalog.Part_sd_shock_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.037,-0.313,-0.018],"max":[0.061,0.018,0.176],"size":[0.098,0.331,0.194]}},"attachmentLocalM":{"Bolt_1":[0,0,0],"Bolt_2":[0,-0.297,0.16]},"triangles":2936},{"name":"Part_sd_seat_std","node":"Part_sd_seat_std","category":"Parts","assetId":"senda-catalog.Part_sd_seat_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.098082,-0.023703,-0.37],"max":[0.098082,0.064685,0.43],"size":[0.196165,0.088388,0.8]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":160},{"name":"Part_sd_front_fender","node":"Part_sd_front_fender","category":"Parts","assetId":"senda-catalog.Part_sd_front_fender","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.087531,-0.081901,-0.548],"max":[0.087531,0.027,0.15],"size":[0.175062,0.108901,0.698]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":180},{"name":"Part_sd_headlight_mask","node":"Part_sd_headlight_mask","category":"Parts","assetId":"senda-catalog.Part_sd_headlight_mask","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.084958,-0.12,-0.07],"max":[0.084958,0.13,0.08],"size":[0.169916,0.25,0.15]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":204},{"name":"Part_sd_side_panel_l","node":"Part_sd_side_panel_l","category":"Parts","assetId":"senda-catalog.Part_sd_side_panel_l","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.015,-0.147,-0.39],"max":[0.0085,0,0],"size":[0.0235,0.147,0.39]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":120},{"name":"Part_sd_side_panel_r","node":"Part_sd_side_panel_r","category":"Parts","assetId":"senda-catalog.Part_sd_side_panel_r","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.0085,-0.147,-0.39],"max":[0.015,0,0],"size":[0.0235,0.147,0.39]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":120},{"name":"Part_sd_tail_plate","node":"Part_sd_tail_plate","category":"Parts","assetId":"senda-catalog.Part_sd_tail_plate","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.079351,-0.130863,-0.165],"max":[0.079351,0.028824,0.249],"size":[0.158702,0.159686,0.414]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":920},{"name":"Part_sd_tank_std","node":"Part_sd_tank_std","category":"Parts","assetId":"senda-catalog.Part_sd_tank_std","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.125,-0.161,-0.265],"max":[0.125,0.055462,0.14],"size":[0.25,0.216462,0.405]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":352},{"name":"Part_sd_fuel_line","node":"Part_sd_fuel_line","category":"Parts","assetId":"senda-catalog.Part_sd_fuel_line","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.004375,-0.265,-0.011396],"max":[0.099097,0.002,0.013399],"size":[0.103472,0.267,0.024795]}},"attachmentLocalM":{"Bolt_1":[0,0,0],"Bolt_2":[0.058,-0.282,0]},"triangles":160},{"name":"Part_sd_piston","node":"Part_sd_piston","category":"Parts","assetId":"senda-catalog.Part_sd_piston","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.0198,-0.021913,-0.022688],"max":[0.0198,0.022551,0.023038],"size":[0.0396,0.044464,0.045726]}},"attachmentLocalM":{"Bolt_1":[0,0.019,0],"Bolt_2":[0,-0.019,0]},"triangles":1264},{"name":"Part_sd_cylinder","node":"Part_sd_cylinder","category":"Parts","assetId":"senda-catalog.Part_sd_cylinder","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.061,-0.016314,-0.076084],"max":[0.061,0.133709,0.05631],"size":[0.122,0.150023,0.132393]}},"attachmentLocalM":{"Bolt_1":[0.048,0,0],"Bolt_2":[0,0,0.048],"Bolt_3":[-0.048,0,0],"Bolt_4":[0,0,-0.048]},"triangles":2320},{"name":"Part_sd_head","node":"Part_sd_head","category":"Parts","assetId":"senda-catalog.Part_sd_head","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.053,-0.022834,-0.052246],"max":[0.053,0.034158,0.053669],"size":[0.106,0.056992,0.105915]}},"attachmentLocalM":{"Bolt_1":[0.037,0,0],"Bolt_2":[0,0,0.037],"Bolt_3":[-0.037,0,0],"Bolt_4":[0,0,-0.037]},"triangles":848},{"name":"Part_sd_plug","node":"Part_sd_plug","category":"Parts","assetId":"senda-catalog.Part_sd_plug","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.006062,-0.004269,-0.011665],"max":[0.006062,0.03868,0.00727],"size":[0.012124,0.042949,0.018936]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":240},{"name":"Part_sd_clutch","node":"Part_sd_clutch","category":"Parts","assetId":"senda-catalog.Part_sd_clutch","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.0235,-0.048,-0.048],"max":[0.033684,0.048,0.048],"size":[0.057184,0.096,0.096]}},"attachmentLocalM":{"Bolt_1":[0,0.022,0],"Bolt_2":[0,0.006798,0.020923],"Bolt_3":[0,-0.017798,0.012931],"Bolt_4":[0,-0.017798,-0.012931],"Bolt_5":[0,0.006798,-0.020923]},"triangles":5692},{"name":"Part_sd_cdi","node":"Part_sd_cdi","category":"Parts","assetId":"senda-catalog.Part_sd_cdi","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.025571,-0.01967,-0.625],"max":[0.084,0.055994,-0.022097],"size":[0.109571,0.075664,0.602903]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":136},{"name":"Part_sd_carb","node":"Part_sd_carb","category":"Parts","assetId":"senda-catalog.Part_sd_carb","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.026536,-0.053691,-0.102863],"max":[0.038265,0.0385,0.055301],"size":[0.064801,0.092191,0.158164]}},"attachmentLocalM":{"Bolt_1":[0,0.003,-0.038],"Bolt_2":[0,0.011,0.05]},"triangles":716},{"name":"Part_sd_airbox","node":"Part_sd_airbox","category":"Parts","assetId":"senda-catalog.Part_sd_airbox","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.068702,-0.113748,-0.182242],"max":[0.068702,0.116813,0.155],"size":[0.137403,0.230561,0.337242]}},"attachmentLocalM":{"Bolt_1":[-0.073,0.055,0.067]},"triangles":296},{"name":"Part_sd_exhaust","node":"Part_sd_exhaust","category":"Parts","assetId":"senda-catalog.Part_sd_exhaust","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.018959,-0.241271,-0.138847],"max":[0.198907,0.287767,0.89889],"size":[0.217866,0.529038,1.037737]}},"attachmentLocalM":{"Bolt_1":[0,0,0],"Bolt_2":[0.139,0.02,0.366],"Bolt_3":[0.117,0.244,0.789]},"triangles":3172},{"name":"Part_sd_front_sprocket_11","node":"Part_sd_front_sprocket_11","category":"Parts","assetId":"senda-catalog.Part_sd_front_sprocket_11","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.008,-0.028886,-0.029183],"max":[0.003,0.029183,0.028886],"size":[0.011,0.05807,0.05807]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":552},{"name":"Part_sd_rear_sprocket_53","node":"Part_sd_rear_sprocket_53","category":"Parts","assetId":"senda-catalog.Part_sd_rear_sprocket_53","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.006,-0.101975,-0.101975],"max":[0.006,0.10193,0.10193],"size":[0.012,0.203905,0.203905]}},"attachmentLocalM":{"Bolt_1":[0,0.05,0],"Bolt_2":[0,0.025,0.043301],"Bolt_3":[0,-0.025,0.043301],"Bolt_4":[0,-0.05,0],"Bolt_5":[0,-0.025,-0.043301],"Bolt_6":[0,0.025,-0.043301]},"triangles":2736},{"name":"Part_sd_chain_420","node":"Part_sd_chain_420","category":"Parts","assetId":"senda-catalog.Part_sd_chain_420","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.0096,-0.196708,-0.029999],"max":[0.0096,0.029691,0.584853],"size":[0.0192,0.226399,0.614852]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":7040},{"name":"Part_sd_block","node":"Part_sd_block","category":"Parts","assetId":"senda-catalog.Part_sd_block","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.1045,-0.084,-0.165],"max":[0.102,0.167804,0.268],"size":[0.2065,0.251804,0.433]}},"attachmentLocalM":{"Bolt_1":[0,-0.021,-0.152],"Bolt_2":[0,-0.039,0.164],"Bolt_3":[0,0.064,0.211]},"triangles":10264},{"name":"Part_sd_radiator","node":"Part_sd_radiator","category":"Parts","assetId":"senda-catalog.Part_sd_radiator","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.038706,-0.081,-0.027],"max":[0.192706,0.063,0.045],"size":[0.231413,0.144,0.072]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":1184},{"name":"Part_sd_coolant_hoses","node":"Part_sd_coolant_hoses","category":"Parts","assetId":"senda-catalog.Part_sd_coolant_hoses","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.100979,-0.233891,-0.151126],"max":[0.084983,0.103089,0.011498],"size":[0.185962,0.33698,0.162624]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":288},{"name":"Part_sd_kickstarter","node":"Part_sd_kickstarter","category":"Parts","assetId":"senda-catalog.Part_sd_kickstarter","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.00947,-0.007794,-0.009],"max":[0.051,0.137,0.05399],"size":[0.06047,0.144794,0.06299]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":200},{"name":"Part_sd_gear_lever","node":"Part_sd_gear_lever","category":"Parts","assetId":"senda-catalog.Part_sd_gear_lever","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.063,-0.041,-0.188],"max":[0.008571,0.009899,0.009],"size":[0.071571,0.050899,0.197]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":200},{"name":"Part_sd_flywheel_stator","node":"Part_sd_flywheel_stator","category":"Parts","assetId":"senda-catalog.Part_sd_flywheel_stator","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.019,-0.058,-0.058],"max":[0.025,0.058,0.058],"size":[0.044,0.116,0.116]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":576},{"name":"Part_sd_ignition_coil","node":"Part_sd_ignition_coil","category":"Parts","assetId":"senda-catalog.Part_sd_ignition_coil","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.077858,-0.074861,-0.025],"max":[0.021637,0.02262,0.129527],"size":[0.099495,0.097482,0.154527]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":96},{"name":"Part_sd_oil_tank","node":"Part_sd_oil_tank","category":"Parts","assetId":"senda-catalog.Part_sd_oil_tank","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.038356,-0.062977,-0.1],"max":[0.038356,0.07,0.1],"size":[0.076713,0.132977,0.2]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":120},{"name":"Part_sd_oil_pump","node":"Part_sd_oil_pump","category":"Parts","assetId":"senda-catalog.Part_sd_oil_pump","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.01,-0.026,-0.026],"max":[0.025,0.026,0.026],"size":[0.035,0.052,0.052]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":64},{"name":"Part_sd_oil_line","node":"Part_sd_oil_line","category":"Parts","assetId":"senda-catalog.Part_sd_oil_line","materials":["vertex"],"materialBoundsM":{"vertex":{"min":[-0.003902,-0.19297,-0.435488],"max":[0.048995,0.003666,0.0017],"size":[0.052897,0.196636,0.437188]}},"attachmentLocalM":{"Bolt_1":[0,0,0]},"triangles":64}]}]==])
local count = install(selection[1], manifest, meshFacesPositiveZ)
print("Installed " .. count .. " Two-Stroke catalog entries")
