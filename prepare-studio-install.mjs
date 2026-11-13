import {readFileSync, writeFileSync} from 'node:fs';

const root = new URL('./', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const installer = read('assets/vehicles/sm50/source/install-catalog.luau');
const resolver = read('assets/vehicles/sm50/source/resolve-preview-mesh.luau');
const repair = read('assets/vehicles/sm50/source/repair-preview-meshes.luau');
const paths = {
  'ZefirSM50Catalog': 'assets/vehicles/sm50/exports/ZefirSM50Catalog.manifest.json',
  'TwoStrokeWorldCatalog': 'assets/environment/starter-garage/exports/TwoStrokeWorldCatalog.manifest.json',
  'SendaSM50Catalog': 'assets/vehicles/sm50/exports/SendaSM50Catalog-pbr.manifest.json',
};

for (const [name, path] of Object.entries(paths)) {
  const manifest = JSON.parse(read(path));
  const metadata = JSON.stringify({
    assetId: manifest.assetId,
    orientation: manifest.orientation,
    components: manifest.components.map(({name, node, category, assetId, materials, materialBoundsM,
      attachmentLocalM, triangles}) => ({
      name, node, category, assetId, materials, materialBoundsM, attachmentLocalM, triangles,
    })),
  });
  const command = `-- Select the imported ${name} model, then run this in Studio's Command Bar.
-- Set false when the raw mesh already faces -Z. The tested Roblox import faces +Z.
local meshFacesPositiveZ = true
local install = (function()
${installer}
end)()
local selection = game:GetService("Selection"):Get()
assert(#selection == 1, "Select exactly one imported catalog Model")
local manifest = game:GetService("HttpService"):JSONDecode([==[${metadata}]==])
local count = install(selection[1], manifest, meshFacesPositiveZ)
print("Installed " .. count .. " Two-Stroke catalog entries")
`;
  writeFileSync(new URL(path.replace('.manifest.json', '.install.luau'), root), command);
}

const index = JSON.parse(read('assets/ASSET_MANIFEST.json'));
const previews = {
  SM50_AssetPreview: 'assets/ASSET_MANIFEST.json',
  StarterGarage_AssetPreview: 'assets/' + index.relatedAssets.starterGarage,
  CommuterScooter_AssetPreview: 'assets/' + index.relatedAssets.commuterScooter,
  PerformanceScooter_AssetPreview: 'assets/' + index.relatedAssets.performanceScooter,
  RuralRoadKit_AssetPreview: 'assets/' + index.relatedAssets.ruralRoadKit,
  RuralHouse_AssetPreview: 'assets/' + index.relatedAssets.ruralHouse,
  RoadsideProps_AssetPreview: 'assets/' + index.relatedAssets.roadsideProps,
};
const repairModules = `local buildResolver = (function()
${resolver}
end)()
local repair = (function()
${repair}
end)()
`;
const runRepair = `local result = repair(previews, buildResolver(imports))
if #result.missing > 0 then
    error("No meshes replaced. Unresolved meshes:\\n" .. table.concat(result.missing, "\\n"))
end
print("Replaced " .. result.changed .. " temporary meshes")
`;

for (const [previewName, path] of Object.entries(previews)) {
  const manifest = JSON.parse(read(path));
  const metadata = JSON.stringify({
    assetId: manifest.assetId,
    orientation: manifest.orientation,
    components: manifest.components.map(({node, assetId, materials, materialBoundsM}) =>
      ({node, assetId, materials, materialBoundsM})),
  });
  const outputPath = 'assets/' + manifest.export.replace(/\.glb$/, '.repair.luau');
  writeFileSync(new URL(outputPath, root), `-- Select the uploaded ${manifest.name} Model before running this command.
${repairModules}
local selection = game:GetService("Selection"):Get()
assert(#selection == 1 and selection[1]:IsA("Model"), "Select the imported root Model")
local manifest = game:GetService("HttpService"):JSONDecode([==[${metadata}]==])
local preview = workspace:FindFirstChild("${previewName}")
assert(preview and preview:IsA("Model") and preview:GetAttribute("PreviewOnly")
    and preview:GetAttribute("AssetId") == manifest.assetId, "Expected preview is missing")
assert(selection[1] ~= preview and not selection[1]:IsDescendantOf(preview), "Select the imported Model")
local previews = {preview}
local imports = {[manifest.assetId] = {model=selection[1], manifest=manifest}}
${runRepair}`);
}

writeFileSync(new URL('assets/vehicles/sm50/exports/ZefirSM50Displays.repair.luau', root),
  `-- Install the Zefir catalog before running this command. No selection is required.
${repairModules}
local previews = {}
for _, name in {"ZefirSM50_AssemblyPreview", "ZefirSM50_EngineServicePreview"} do
    local preview = workspace:FindFirstChild(name)
    if preview and preview:IsA("Model") and preview:GetAttribute("PreviewOnly")
        and preview:GetAttribute("AssetId") == "sm50-catalog" then
        table.insert(previews, preview)
    end
end
assert(#previews > 0, "No Zefir catalog displays found")
local imports = {}
${runRepair}`);
