import { readFileSync, writeFileSync } from 'node:fs';
import { add, cross, length, mul, sub, unit } from './geometry.mjs';

const assets = new URL('../../', import.meta.url);
const vehicle = new URL('export/vehicles/SB50-game.glb', assets);
const manifest = JSON.parse(readFileSync(new URL('manifests/SB50-game.json', assets)));
const original = readFileSync(vehicle);
const jsonSize = original.readUInt32LE(12);
const gltf = JSON.parse(original.subarray(20, 20 + jsonSize));
const binary = Buffer.from(original.subarray(28 + jsonSize));
const initialMeshes = gltf.meshes;
const initialNodes = new Map(gltf.nodes.map(node => [node.name, node]));
const midpoint = (a, b) => a.map((value, axis) => (value + b[axis]) / 2);
const subtract = (a, b) => a.map((value, axis) => value - b[axis]);

// Roblox gets one named MeshPart per node with centred mesh-local coordinates.
gltf.nodes = [{ name: 'SB50_StudioImport', children: [] }];
gltf.scenes = [{ nodes: [0] }];
gltf.meshes = [];
const tangents = [];
let bufferSize = binary.length;
const parts = [];
const labels = new Set();

const dot = (a,b) => a.reduce((sum,value,axis) => sum + value*b[axis], 0);
function viewFor(accessor) {
  const view = gltf.bufferViews[accessor.bufferView];
  return (view.byteOffset ?? 0) + (accessor.byteOffset ?? 0);
}
function assignTangents(primitive) {
  const {POSITION, NORMAL, TEXCOORD_0} = primitive.attributes;
  const positions = gltf.accessors[POSITION], normals = gltf.accessors[NORMAL];
  const texcoords = gltf.accessors[TEXCOORD_0], indices = gltf.accessors[primitive.indices];
  if (indices.componentType !== 5123 || normals.componentType !== 5126 || texcoords.componentType !== 5126) {
    throw new Error('Unsupported tangent input format');
  }
  const read = (accessor, stride, index) => {
    const offset = viewFor(accessor) + stride*4*index;
    return Array.from({length:stride},(_,axis)=>binary.readFloatLE(offset+axis*4));
  };
  const tangent = Array.from({length:positions.count},()=>[0,0,0]);
  const bitangent = Array.from({length:positions.count},()=>[0,0,0]);
  const indexStart = viewFor(indices);
  for (let i=0; i<indices.count; i+=3) {
    const face = [0,1,2].map(j=>binary.readUInt16LE(indexStart+(i+j)*2));
    const [a,b,c] = face.map(j=>read(positions,3,j));
    const [u,v,w] = face.map(j=>read(texcoords,2,j));
    const x = sub(b,a), y = sub(c,a);
    const [du,dv] = sub(v,u), [eu,ev] = sub(w,u);
    const determinant = du*ev - eu*dv;
    if (Math.abs(determinant)<1e-12) continue;
    const t = mul(sub(mul(x,ev),mul(y,dv)),1/determinant);
    const bTex = mul(sub(mul(y,du),mul(x,eu)),1/determinant);
    for (const j of face) {
      tangent[j] = add(tangent[j],t);
      bitangent[j] = add(bitangent[j],bTex);
    }
  }
  const output = Buffer.alloc(positions.count*16);
  for (let i=0;i<positions.count;i++){
    const n = unit(read(normals,3,i));
    const projected = sub(tangent[i],mul(n,dot(n,tangent[i])));
    const fallback = cross(n,Math.abs(n[1])>.9?[1,0,0]:[0,1,0]);
    const t = unit(length(projected)>Math.max(1e-9,length(tangent[i])*1e-7) ? projected : fallback);
    const handedness = dot(cross(n,t),bitangent[i])<0 ? -1 : 1;
    [...t,handedness].forEach((value,axis)=>output.writeFloatLE(value,(i*4+axis)*4));
  }
  const bufferView = gltf.bufferViews.length;
  gltf.bufferViews.push({buffer:0,byteOffset:bufferSize,byteLength:output.length,target:34962});
  bufferSize += output.length;
  tangents.push(output);
  primitive.attributes.TANGENT = gltf.accessors.length;
  gltf.accessors.push({bufferView,componentType:5126,count:positions.count,type:'VEC4'});
}

for (const component of manifest.components) {
  const source = initialNodes.get(component.node);
  const primitives = initialMeshes[source.mesh].primitives;
  if (primitives.length !== component.materials.length) throw new Error(component.node);
  const layers = primitives.map((primitive, index) => {
    const material = component.materials[index];
    const name = 'SB50_' + component.node + '_' + material;
    if (labels.has(name)) throw new Error('Duplicate Studio mesh name ' + name);
    labels.add(name);

    const accessor = gltf.accessors[primitive.attributes.POSITION];
    const view = gltf.bufferViews[accessor.bufferView];
    const center = midpoint(accessor.min, accessor.max);
    const size = subtract(accessor.max, accessor.min);
    if (accessor.componentType !== 5126 || accessor.type !== 'VEC3' || view.byteStride) {
      throw new Error('Unexpected vertex format for ' + name);
    }
    const start = (view.byteOffset ?? 0) + (accessor.byteOffset ?? 0);
    for (let vertex = 0; vertex < accessor.count; vertex++) {
      for (let axis = 0; axis < 3; axis++) {
        const offset = start + (vertex * 3 + axis) * 4;
        binary.writeFloatLE(binary.readFloatLE(offset) - center[axis], offset);
      }
    }
    accessor.min = subtract(accessor.min, center).map(Math.fround);
    accessor.max = subtract(accessor.max, center).map(Math.fround);

    assignTangents(primitive);
    const mesh = gltf.meshes.length;
    gltf.meshes.push({ name: name + "_Geometry", primitives: [primitive] });
    gltf.nodes[0].children.push(gltf.nodes.length);
    gltf.nodes.push({
      name, mesh, translation: source.translation.map((value, axis) => value + center[axis]),
    });
    return { name, material, center, size, triangles: gltf.accessors[primitive.indices].count / 3 };
  });
  parts.push({
    name: component.name, category: component.category, pivot: source.translation,
    attachments: component.attachmentLocalM, layers,
  });
}

const wrap = (data, type, fill = 0) => {
  const padding = Buffer.alloc((4 - data.length % 4) % 4, fill);
  const header = Buffer.alloc(8);
  header.writeUInt32LE(data.length + padding.length);
  header.writeUInt32LE(type, 4);
  return Buffer.concat([header, data, padding]);
};
gltf.buffers[0].byteLength = bufferSize;
const chunks = [
  wrap(Buffer.from(JSON.stringify(gltf)), 0x4e4f534a, 32),
  wrap(Buffer.concat([binary,...tangents]), 0x004e4942),
];
const header = Buffer.alloc(12);
header.write('glTF');
header.writeUInt32LE(2, 4);
header.writeUInt32LE(12 + chunks.reduce((length, chunk) => length + chunk.length, 0), 8);
writeFileSync(new URL('export/vehicles/SB50-StudioImport.glb', assets), Buffer.concat([header, ...chunks]));

const layout = {
  schemaVersion: 1, metresPerStud: manifest.orientation.metresPerStud,
  stats: manifest.stats, palette: manifest.materials, parts,
};
writeFileSync(new URL('manifests/SB50-studio-import.json', assets), JSON.stringify(layout) + '\n');
console.log(`Built ${parts.length} components as ${labels.size} individually named Studio meshes.`);
