import {readFileSync, writeFileSync} from 'node:fs';

const root = new URL('./', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const installer = read('assets/vehicles/sm50/source/install-catalog.luau');
const paths = {
  'ZefirSM50Catalog': 'assets/vehicles/sm50/exports/ZefirSM50Catalog.manifest.json',
  'TwoStrokeWorldCatalog': 'assets/environment/starter-garage/exports/TwoStrokeWorldCatalog.manifest.json',
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
local install = (function()
${installer}
end)()
local selection = game:GetService("Selection"):Get()
assert(#selection == 1, "Select exactly one imported catalog Model")
local manifest = game:GetService("HttpService"):JSONDecode([==[${metadata}]==])
local count = install(selection[1], manifest)
print("Installed " .. count .. " Two-Stroke catalog entries")
`;
  writeFileSync(new URL(path.replace('.manifest.json', '.install.luau'), root), command);
}
