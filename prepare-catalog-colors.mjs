import {writeFileSync} from 'node:fs';
import * as bike from './assets/vehicles/sm50/source/catalog.mjs';
import * as world from './assets/environment/starter-garage/source/world-catalog.mjs';
import {cross, length, sub} from './assets/vehicles/sm50/source/geometry.mjs';

const overrides = {
  Frame:'frame', Part_fork_std:'anodized', Part_handlebar_std:'anodized',
  Part_tank_std:'body', Part_seat_std:'seat', Part_wheel_front_17:'rubber',
  Part_wheel_rear_17:'rubber', Part_shock_std:'raceRed', Garage_Bay:'plaster',
};
const rows = [];
for (const [catalog, prefix] of [[bike, 'sm50-catalog'], [world, 'world-catalog']]) {
  for (const part of catalog.components) {
    const mesh = part.layers.vertex;
    const area = new Map();
    for (const [a, b, c] of mesh.triangles) {
      const material = mesh.colors[a];
      const weight = length(cross(sub(mesh.vertices[b],mesh.vertices[a]), sub(mesh.vertices[c],mesh.vertices[a])));
      area.set(material, (area.get(material) ?? 0) + weight);
    }
    const key = overrides[part.name] ?? [...area].sort((a,b)=>b[1]-a[1])[0][0];
    const [, hex, , , material] = catalog.materials[key];
    rows.push({assetId:prefix + '.' + part.name, name:part.name, category:part.category, hex, material});
  }
}
const command = `-- Run in Studio Edit mode after importing the durable catalogs.
local entries = game:GetService("HttpService"):JSONDecode([==[${JSON.stringify(rows)}]==])
local assets = game.ReplicatedStorage:FindFirstChild("Assets")
assert(assets, "Install the catalogs first")
local staged = {}
local worldPalette = {}
for _, entry in entries do
    local group = entry.category == "Vehicles" and assets.Vehicles.sm50 or assets[entry.category]
    local part = group:FindFirstChild(entry.name)
    assert(part and part:IsA("MeshPart") and part:GetAttribute("AssetId") == entry.assetId,
        "Missing catalog entry " .. entry.name)
    assert(part.MeshContent.SourceType == Enum.ContentSourceType.Uri, "Temporary mesh: " .. entry.name)
    local style = {color=Color3.fromHex(entry.hex), material=Enum.Material[entry.material]}
    table.insert(staged, {part=part, style=style, previousColor=part.Color, previousMaterial=part.Material})
    if entry.category == "World" then worldPalette[entry.assetId] = style end
end
local map = workspace:FindFirstChild("Map")
if map then
    for _, part in map:GetDescendants() do
        if part:IsA("MeshPart") and part.MeshContent.SourceType == Enum.ContentSourceType.Uri then
            local style = worldPalette[part:GetAttribute("AssetId")]
            if style then
                table.insert(staged, {part=part, style=style, previousColor=part.Color, previousMaterial=part.Material})
            end
        end
    end
end
local history = game:GetService("ChangeHistoryService")
local token = history:TryBeginRecording("Apply Two-Stroke catalog colors")
local ok, err = pcall(function()
    for _, entry in staged do
        local part = entry.part
        part.Color = entry.style.color
        part.Material = entry.style.material
    end
end)
if token then
    history:FinishRecording(token, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
elseif not ok then
    for _, entry in staged do
        entry.part.Color = entry.previousColor
        entry.part.Material = entry.previousMaterial
    end
end
if not ok then error(err) end
return #staged
`;
writeFileSync(new URL('assets/vehicles/sm50/exports/TwoStrokeCatalog.colors.luau',import.meta.url),command);
