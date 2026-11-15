"""Build and review the Stride C10 commuter scooter."""
from pathlib import Path
import math
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from review import ASSETS, PREVIEWS, aim, area

def render(camera, name, location, target, width):
    scene = bpy.context.scene
    camera.location = location
    aim(camera, target)
    camera.data.ortho_scale = width
    scene.render.filepath = str(PREVIEWS / ("StrideC10-" + name + ".jpg"))
    bpy.ops.render.render(write_still=True)

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ASSETS / "export/vehicles/StrideC10.glb"))
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.length_unit = "METERS"
    scene["Vehicle"] = "STREETBORN Stride C10"
    scene["Wheelbase (m)"] = .938
    scene["Roblox scale"] = "0.28 metres per stud"
    scene["Fold rotation (degrees)"] = 85.5
    if "--source-only" in sys.argv:
        bpy.ops.file.pack_all()
        bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "source/blender/StrideC10.blend"), compress=True)
        return

    scene.render.engine = "CYCLES"
    scene.cycles.samples = 14
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 880
    scene.render.resolution_y = 650
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 89
    scene.view_settings.view_transform = "AgX"
    world = bpy.data.worlds.new("Review")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (.38,.44,.52,1)
    world.node_tree.nodes["Background"].inputs[1].default_value = .32
    scene.world = world

    bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.002))
    material = bpy.data.materials.new("Studio floor")
    material.diffuse_color = (.17,.20,.23,1)
    bpy.context.object.data.materials.append(material)
    area("Key", (2,1.8,2.7), (0,0,.5), 320, 2.35, (.94,.98,1))
    area("Fill", (-1.9,1.4,1.7), (0,0,.48), 185, 2.5, (1,.89,.80))
    area("Rim", (0,-1.8,2.6), (0,0,.5), 360, 2.25, (.83,.92,1))
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    scene.camera = camera
    views = [
        ("01-front", (0,2.8,1.0), (0,0,.52), 1.75),
        ("02-rear", (0,-2.8,1.0), (0,0,.52), 1.75),
        ("03-left", (-2.7,0,.91), (0,0,.52), 1.64),
        ("04-right", (2.7,0,.91), (0,0,.52), 1.64),
        ("05-front-quarter", (1.7,1.32,1.19), (0,0,.51), 1.68),
        ("06-rear-quarter", (-1.8,-1.48,1.09), (0,0,.51), 1.74),
        ("07-rider-view", (-.63,-1.67,1.42), (0,-.048,.50), 1.92),
    ]
    selected = next((arg.split("=", 1)[1].split(",") for arg in sys.argv if arg.startswith("--views=")), None)
    for view in views:
        if selected and view[0].split("-", 1)[0] not in selected:
            continue
        render(camera, *view)

    if selected:
        return

    hide_for_service = ["Floorboard", "BatteryPack", "ControllerHousing"]
    for name in hide_for_service:
        bpy.data.objects[name].hide_render = True
    render(camera, "08-service-bay", (-.84,.44,1.16), (0,0,.128), .90)
    for name in hide_for_service:
        bpy.data.objects[name].hide_render=False

    hinge=Vector((0,.338,.279))
    rotate=Matrix.Translation(hinge) @ Matrix.Rotation(math.radians(85.5),4,"X") @ Matrix.Translation(-hinge)
    for name in ["SteeringStem","Handlebar","LeftGrip","RightGrip","BrakeLever",
                 "ThumbThrottle","Display","Headlamp","TransportHook"]:
        obj=bpy.data.objects[name]
        obj.matrix_world=rotate @ obj.matrix_world
    bpy.data.objects["WiringHarness"].hide_render=True
    render(camera, "09-folded", (1.4,1.20,.74), (0,0,.22), 1.48)

if __name__ == "__main__":
    main()
