-- Run in Studio Edit mode to add grip markers to the already imported Zefir.
local bar = game.ReplicatedStorage.Assets.Parts:FindFirstChild("Part_handlebar_std")
assert(bar and bar:IsA("MeshPart"), "Install the Zefir handlebar first")
local metresPerStud = .28
for name, x in {GripL = -.328963, GripR = .328963} do
    local marker = bar:FindFirstChild(name)
    if marker then
        assert(marker:IsA("Attachment"), "Unexpected handlebar child " .. name)
    else
        marker = Instance.new("Attachment")
        marker.Name = name
        marker.Position = bar.PivotOffset:PointToWorldSpace(Vector3.new(x, .043, .051) / metresPerStud)
        marker.Parent = bar
    end
end
