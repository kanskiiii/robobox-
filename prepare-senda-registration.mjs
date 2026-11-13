import {readFileSync, writeFileSync} from 'node:fs';
import {components, datums} from './assets/vehicles/sm50/source/senda.mjs';

const path = new URL('assets/vehicles/sm50/exports/SendaSM50Catalog-pbr.manifest.json', import.meta.url);
const manifest = JSON.parse(readFileSync(path, 'utf8'));
const donors = {
  front_sprocket_11:'sprocket_f_11', rear_sprocket_53:'sprocket_r_53', block:'block_am6',
  piston:'piston_40', cylinder:'cylinder_50', head:'head_std', plug:'plug_std',
  clutch:'clutch_std', cdi:'cdi_restricted', carb:'carb_17', airbox:'filter_std',
  exhaust:'exhaust_std', radiator:'radiator_std',
};
const extraRequires = {
  FrontFender:['FrontFork'], HeadlightMask:['FrontFork'], SidePanelL:['Seat'], SidePanelR:['Seat'],
  TailPlate:['Seat'], FlywheelStator:['EngineBlock'], IgnitionCoil:['Ignition'],
  CoolantHoses:['Radiator','CylinderHead'], OilTank:['FuelTank'], OilPump:['EngineBlock'],
  OilLine:['OilTank','OilPump'], Kickstarter:['EngineBlock'], GearLever:['EngineBlock'],
};
const stats = {
  block:{stroke:.04,primary:78/21}, piston:{bore:.03988}, cylinder:{bore:.03988}, carb:{diameter:.0175},
  tank_std:{capacity:7}, wheel_front_17:{radius:.296}, wheel_rear_17:{radius:.307},
  fork_std:{travel:.12}, shock_std:{travel:.11},
};
const parts = manifest.components.filter(part => part.name !== 'Frame').map(part => {
  const id = part.name.slice('Part_sd_'.length);
  const slot = components.find(x => x.name === part.name).interaction.slice('Install at Mount_'.length);
  if (!datums['Mount_' + slot]) throw Error('Missing Senda mount ' + slot);
  return {
    id:'sd_'+id, slot, donor:donors[id] ?? id, extra:extraRequires[slot],
    size:part.dimensionsM, offset:part.pivotM.map((x,i)=>i===2?-x:x),
    bolts:Object.keys(part.attachmentLocalM).filter(k=>/^Bolt_\d+$/.test(k)).length,
    stats:stats[id] ?? {},
  };
});
if (new Set(parts.map(p=>p.slot)).size !== 38) throw Error('Duplicate Senda slots');

const encoded = JSON.stringify(JSON.stringify(parts));
const block = `-- Senda catalog registration
do
    local data = game:GetService("HttpService"):JSONDecode(${encoded})
    local stock = Catalog.vehicles.sm50
    local vehicle = table.clone(stock)
    vehicle.id, vehicle.name = "senda", "Senda SM 50"
    vehicle.frontAxle, vehicle.rearAxle = {0,-.25,.70}, {0,-.25,-.665}
    vehicle.slots = {}
    local rowsBySlot = {}
    for _, row in data do rowsBySlot[row.slot] = row end
    local function addSlot(row, slot)
        local donor = parts[row.donor]
        if not row.extra then assert(slot and donor, "Missing stock definition for " .. row.slot) end
        local slotType = slot and slot.accepts or row.id
        local name = slot and slot.name or row.id:sub(4):gsub("_"," ")
        local def = donor and table.clone(donor) or {
            name=name, mass=.2, price=40, tool="spanner", stats={}, shape="block",
            color={40,47,58}, desc="Senda service part",
        }
        def.id, def.fits, def.slotType = row.id, {"senda"}, slotType
        def.bolts, def.size = row.bolts, row.size
        def.stats = table.clone(def.stats)
        for key, value in row.stats do def.stats[key] = value end
        if row.id == "sd_carb" then
            def.tune = table.clone(def.tune or {})
            if def.tune.mainJet then
                def.tune.mainJet = table.clone(def.tune.mainJet)
                def.tune.mainJet.default = 85
            end
        end
        P(def)
        table.insert(vehicle.slots, S(row.slot, name, slotType, slot and slot.requires or row.extra,
            row.offset, slot and slot.needed or "optional"))
    end
    for _, slot in stock.slots do
        addSlot(assert(rowsBySlot[slot.id], "Missing Senda slot " .. slot.id), slot)
    end
    local pending = {}
    for _, row in data do if row.extra then table.insert(pending, row) end end
    local installedSlots = {}
    for _, slot in vehicle.slots do installedSlots[slot.id] = true end
    while #pending > 0 do
        local before = #pending
        for i = #pending, 1, -1 do
            local row = pending[i]
            local ready = true
            for _, id in row.extra do if not installedSlots[id] then ready = false end end
            if ready then
                addSlot(row, nil)
                installedSlots[row.slot] = true
                table.remove(pending, i)
            end
        end
        assert(#pending < before, "Unresolved Senda slot dependency")
    end
    Catalog.vehicles.senda = vehicle
end

`;
const command = `-- Run in Studio Edit after the Senda GLB installer.
local storage = game:GetService("ReplicatedStorage")
local assets = storage:FindFirstChild("Assets")
assert(assets and assets.Vehicles and assets.Vehicles:FindFirstChild("senda"), "Install the durable Senda catalog first")
local function check(part, identity)
    assert(part and part:IsA("MeshPart") and part.MeshContent.SourceType == Enum.ContentSourceType.Uri
        and part:GetAttribute("AssetId") == identity, "Missing durable Senda mesh: " .. identity)
end
check(assets.Vehicles.senda:FindFirstChild("Frame"), "senda-catalog.Frame")
local data = game:GetService("HttpService"):JSONDecode(${encoded})
for _, row in data do
    check(assets.Parts:FindFirstChild("Part_" .. row.id), "senda-catalog.Part_" .. row.id)
end
local catalog = storage.TwoStroke.Parts.PartCatalog
local block = [==[${block}]==]
game:GetService("ScriptEditorService"):UpdateSourceAsync(catalog, function(source)
    if source:find("-- Senda catalog registration", 1, true) then return source end
    local marker = "function Catalog.getPart"
    local index = assert(source:find(marker, 1, true), "Unexpected PartCatalog source")
    return source:sub(1,index-1) .. block .. source:sub(index)
end)
print("Registered Senda and all " .. #data .. " removable parts. Restart play to load the catalog.")
`;
writeFileSync(new URL('SendaSM50Catalog.register.luau',path),command);
