-- Run in the Studio Command Bar in Edit mode to reproduce the stock suspension change.
local parts = game.ReplicatedStorage.TwoStroke.Parts
local editor = game:GetService("ScriptEditorService")
local changes = {
    {module=parts.PartCatalog, edits={
        {"springRate = 12000, damping = 950, travel = 0.20", "springRate = 12000, damping = 950, travel = 0.12"},
        {"springRate = 18000, damping = 1300, travel = 0.20", "springRate = 18000, damping = 1300, travel = 0.11"},
    }},
    {module=parts.VehicleSpec, edits={
        {"frontTravel = stat(asm, \"FrontFork\", \"travel\", 0.2)", "frontTravel = stat(asm, \"FrontFork\", \"travel\", 0.12)"},
        {"rearTravel = stat(asm, \"RearShock\", \"travel\", 0.2)", "rearTravel = stat(asm, \"RearShock\", \"travel\", 0.11)"},
    }},
}
local function revised(source, change)
    for _, edit in change.edits do
        local start, finish = source:find(edit[1], 1, true)
        if start then
            assert(not source:find(edit[1], finish + 1, true), "Ambiguous source in " .. change.module.Name)
            source = source:sub(1, start - 1) .. edit[2] .. source:sub(finish + 1)
        else
            assert(source:find(edit[2], 1, true), "Unexpected source in " .. change.module.Name)
        end
    end
    return source
end
for _, change in changes do revised(change.module.Source, change) end
for _, change in changes do
    editor:UpdateSourceAsync(change.module, function(source) return revised(source, change) end)
end
print("Stock SM50 suspension set to 120 mm front and 110 mm rear")
