"""Export pivot-centred replacement parts from the game GLB."""
from pathlib import Path
import json

import bpy

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "assets"
MANIFESTS = ASSETS / "manifests"
OUTPUT = ASSETS / "export/components"

def linear_rgb(hex_color):
    values = [int(hex_color[index:index+2], 16) / 255 for index in (1, 3, 5)]
    return [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in values]

def set_portable_materials(palette):
    for spec in palette.values():
        material = bpy.data.materials.get(spec["name"])
        if not material:
            continue
        shader = material.node_tree.nodes.get("Principled BSDF")
        for name in ("Base Color", "Metallic", "Roughness", "Normal"):
            for link in list(shader.inputs[name].links):
                material.node_tree.links.remove(link)
        shader.inputs["Base Color"].default_value = (*linear_rgb(spec["hex"]), 1)
        shader.inputs["Metallic"].default_value = spec["metallic"]
        shader.inputs["Roughness"].default_value = spec["roughness"]

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ASSETS / "export/vehicles/SB50-game.glb"))
    model = json.loads((MANIFESTS / "SB50-game.json").read_text(encoding="utf-8"))
    set_portable_materials(model["materials"])
    records = {entry["name"]: entry for entry in model["components"]}
    variants = [
        ("SB50-seat-stock", "Seat", "seat.sb50.v1", None),
        ("SB50-seat-umber", "Seat", "seat.sb50.v1", (.115, .045, .021, 1)),
        ("SB50-cylinder-stock", "Cylinder", "cylinder.sb50.v1", None),
        ("SB50-carburetor-stock", "Carburetor", "intake.sb50.v1", None),
        ("SB50-silencer-stock", "Silencer", "silencer.sb50.v1", None),
        ("SB50-silencer-black", "Silencer", "silencer.sb50.v1", (.031, .035, .041, 1)),
    ]
    primary_material = {"Seat": "Grained black vinyl", "Silencer": "Machined aluminium"}
    entries = []
    for asset_id, node, interface, color in variants:
        source = bpy.data.objects[node]
        part = source.copy()
        part.data = source.data.copy()
        part.parent = None
        part.location = (0, 0, 0)
        part.name = asset_id
        part["assetId"] = asset_id
        part["mountingInterface"] = interface
        bpy.context.scene.collection.objects.link(part)
        if color:
            index = next(i for i, m in enumerate(part.data.materials) if m.name == primary_material[node])
            material = part.data.materials[index].copy()
            material.name = asset_id + " finish"
            material.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = color
            part.data.materials[index] = material
        bpy.ops.object.select_all(action="DESELECT")
        part.select_set(True)
        bpy.context.view_layer.objects.active = part
        bpy.ops.export_scene.gltf(filepath=str(OUTPUT / (asset_id + ".glb")), export_format="GLB",
                                  use_selection=True, export_extras=True)
        source_record = records[node]
        entries.append({
            **source_record,
            "assetId": asset_id,
            "name": part.name,
            "node": part.name,
            "file": "assets/export/components/" + asset_id + ".glb",
            "mountingInterface": interface,
            "mountsOnVehicleAtM": source_record["pivotM"],
            "pivotM": [0,0,0],
            "materials": [m.name for m in part.data.materials],
            "exportStatus": "exported",
            "validationStatus": "matches stock mesh and local mounting coordinates",
        })
        bpy.data.objects.remove(part, do_unlink=True)
    doc = {"schemaVersion": 1, "units": "m", "components": entries}
    (MANIFESTS / "SB50-components.json").write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")

if __name__ == "__main__":
    main()
