"""Build the editable SB50 scene and render its vehicle review views."""
from pathlib import Path
import math
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "assets"
PREVIEWS = ASSETS / "previews"

def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()

def area(name, location, target, energy, size, color):
    light = bpy.data.lights.new(name, "AREA")
    light.energy = energy
    light.shape = "DISK"
    light.size = size
    light.color = color
    obj = bpy.data.objects.new(name, light)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    aim(obj, target)

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    game_mesh = "--game" in sys.argv
    mesh = "SB50-game.glb" if game_mesh else "SB50-inspection.glb"
    bpy.ops.import_scene.gltf(filepath=str(ASSETS / "export/vehicles" / mesh))
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.length_unit = "METERS"
    scene["Vehicle"] = "STREETBORN SB50"
    scene["Game coordinates"] = "+Y up, -Z forward; 0.28 m per Roblox stud"
    scene["Axle separation (m)"] = 1.38
    if "--source-only" in sys.argv:
        bpy.ops.file.pack_all()
        bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "source/blender/SB50.blend"), compress=True)
        return

    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 880
    scene.render.resolution_y = 600
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 89
    scene.view_settings.view_transform = "AgX"

    world = bpy.data.worlds.new("Neutral studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (.29, .34, .43, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = .36
    scene.world = world

    bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.003))
    floor = bpy.context.object
    floor.name = "Review cyclorama"
    material = bpy.data.materials.new("Warm grey cyclorama")
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (.16,.17,.18,1)
    bsdf.inputs["Roughness"].default_value = .86
    floor.data.materials.append(material)

    area("Key", (2.3,1.65,3), (0,0,.55), 365, 2.8, (1,.92,.82))
    area("Fill", (-2,1,1.8), (0,0,.5), 249, 2.4, (.74,.86,1))
    area("Rim", (0,-2.8,2.6), (0,0,.55), 435, 2.7, (1,.89,.75))

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    scene.camera = camera
    views = [
        ("01-front", (0,3.8,1.0), (0,0,.60), 1.99),
        ("02-rear", (0,-3.7,1.02), (0,0,.60), 1.99),
        ("03-left", (-3.6,0,1.03), (0,0,.57), 2.45),
        ("04-right", (3.6,0,1.03), (0,0,.57), 2.45),
        ("05-front-quarter", (3.0,2.0,1.49), (0,0,.56), 2.40),
        ("06-rear-quarter", (-2.9,-1.97,1.41), (0,0,.56), 2.40),
        ("07-engine", (-2.1,.55,.65), (0,.01,.50), .88),
        ("08-rider-perspective", (-1.35,-2.7,1.65), (0,.12,.58), None),
    ]
    if game_mesh:
        views = [view for view in views if view[0].startswith(("03", "04", "05", "06"))]
    for filename, location, target, width in views:
        camera.location = location
        aim(camera, target)
        camera.data.type = "ORTHO" if width else "PERSP"
        camera.data.ortho_scale = width or 2.4
        camera.data.lens = 42
        scene.render.filepath = str(PREVIEWS / (("game-" if game_mesh else "") + filename + ".jpg"))
        bpy.ops.render.render(write_still=True)

if __name__ == "__main__":
    main()
