"""Build the SM50 rear assets from the detailed SM50.glb using Blender in background mode."""
import math
from pathlib import Path
import struct
import sys
import zlib

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector


OUT = Path(__file__).resolve().parent
SOURCE = Path(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else OUT.parent / "exports" / "SM50.glb"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE.resolve()))


def source_mesh(name):
    obj = bpy.data.objects[name]
    matrix = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = matrix
    return obj


source_names = ("Seat", "Header", "ExpansionChamber", "Silencer", "ExhaustMounts")
original = {name: source_mesh(name) for name in source_names}
for obj in list(bpy.data.objects):
    if obj.name not in source_names:
        bpy.data.objects.remove(obj, do_unlink=True)

# Blender uses +Z up and +Y forward. The glTF exporter converts back to the SM50 basis.
bpy.context.view_layer.update()
seat_pivot = original["Seat"].location.copy()
exhaust_pivot = original["Header"].location.copy()


def material(name, rgb, metalness, roughness):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*rgb, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1)
    shader.inputs["Metallic"].default_value = metalness
    shader.inputs["Roughness"].default_value = roughness
    return result


def mesh(name, verts, faces, mat, bevel=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    topology = bmesh.new()
    topology.from_mesh(data)
    bmesh.ops.recalc_face_normals(topology, faces=list(topology.faces))
    topology.to_mesh(data)
    topology.free()
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(mat)
    if bevel:
        edge = obj.modifiers.new("Rounded pressed edges", 'BEVEL')
        edge.width = bevel
        edge.segments = 2
        normal = obj.modifiers.new("Weighted surface normals", 'WEIGHTED_NORMAL')
        normal.keep_sharp = True
    return obj


def layers(name, contour, thickness, mat, bevel):
    n = len(contour)
    verts = contour + [(x, y, z - thickness) for x, y, z in contour]
    return mesh(name, verts, [tuple(range(n)), tuple(reversed(range(n, n * 2)))]
                + [(i, i + n, (i + 1) % n + n, (i + 1) % n) for i in range(n)], mat, bevel)


def select(objects, active=None):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = active or objects[0]


def export(name, objects):
    select(objects)
    bpy.ops.export_scene.gltf(filepath=str(OUT / name), export_format='GLB',
                             use_selection=True, export_extras=True, export_apply=True)


def combine(name, objects, pivot):
    select(objects)
    for obj in objects:
        bpy.context.view_layer.objects.active = obj
        for modifier in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    select(objects)
    bpy.ops.object.join()
    result = bpy.context.object
    result.name = name
    bpy.context.scene.cursor.location = pivot
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    result.location = (0, 0, 0)
    bpy.context.view_layer.update()
    return result


def single_material(obj, name):
    """Pack flat material swatches into one texture so Roblox imports a single mesh."""
    source_materials = list(obj.data.materials)
    assert len(source_materials) <= 32
    image = bpy.data.images.new(name + " colors", width=128, height=8, alpha=False)
    colors = []
    for mat in source_materials:
        shader = mat.node_tree.nodes.get("Principled BSDF") if mat.use_nodes else None
        colors.append(tuple(shader.inputs["Base Color"].default_value if shader else mat.diffuse_color))
    colors += [(0, 0, 0, 1)] * (32 - len(colors))
    image.pixels.foreach_set([value for _ in range(8) for color in colors for _ in range(4) for value in color])
    image.update()
    image.pack()
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name="Finishes")
    for face in obj.data.polygons:
        u = (face.material_index * 4 + 2) / 128
        for index in face.loop_indices:
            uv.data[index].uv = (u, .5)
        face.material_index = 0
    obj.data.materials.clear()
    finish = material(name, (.4, .4, .4), .08, .37)
    tex = finish.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = 'Closest'
    finish.node_tree.links.new(tex.outputs["Color"], finish.node_tree.nodes.get("Principled BSDF").inputs["Base Color"])
    obj.data.materials.append(finish)


def duplicate(obj):
    copy = obj.copy()
    copy.data = obj.data.copy()
    bpy.context.collection.objects.link(copy)
    copy.matrix_world = obj.matrix_world.copy()
    return copy


blue = material("Cobalt injection-moulded ABS", (0.021, 0.16, 0.61), .05, .31)
dark = material("Black glass-filled nylon", (.018, .023, .030), .03, .54)
ice = material("Glacier blue graphics", (.035, .54, .88), .01, .36)
white = material("Retroreflective white enamel", (.85, .88, .90), .21, .31)
ink = material("Raised black registration", (.013, .016, .022), .07, .43)
band = material("Registration country band", (.019, .077, .40), .03, .38)
gold = material("Star ink", (.95, .62, .086), .0, .45)
steel = material("Zinc plated fastener", (.44, .49, .54), .82, .29)
red = material("Red polycarbonate", (.43, .015, .021), .15, .23)

plate_objects = []


def plate_layer(name, width, height, radius, y, thickness, mat, x=0, z=0):
    outline = []
    for sx, sz, start in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for step in range(5):
            angle = math.radians(start + step * 22.5)
            outline.append((x + sx * (width / 2 - radius) + radius * math.cos(angle),
                            y, z + sz * (height / 2 - radius) + radius * math.sin(angle)))
    n = len(outline)
    verts = outline + [(a, b + thickness, c) for a, b, c in outline]
    obj = mesh(name, verts, [tuple(range(n)), tuple(reversed(range(n, n * 2)))]
               + [(i, i + n, (i + 1) % n + n, (i + 1) % n) for i in range(n)],
               mat, min(thickness / 3, .00055))
    plate_objects.append(obj)
    return obj


def legend(name, content, x, z, width, height, mat, depth):
    data = bpy.data.curves.new(name, 'FONT')
    data.body = content
    data.align_x = 'CENTER'
    data.align_y = 'CENTER'
    data.space_character = 1.08
    data.resolution_u = 4
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(mat)
    obj.rotation_euler.x = math.pi / 2
    obj.location = (x, -.0044, z)
    select([obj])
    bpy.ops.object.convert(target='MESH')
    obj = bpy.context.object
    coords = [v.co.copy() for v in obj.data.vertices]
    x0, x1 = min(p.x for p in coords), max(p.x for p in coords)
    y0, y1 = min(p.y for p in coords), max(p.y for p in coords)
    for vertex in obj.data.vertices:
        vertex.co.x = (vertex.co.x - (x0 + x1) / 2) * width / (x1 - x0)
        vertex.co.y = (vertex.co.y - (y0 + y1) / 2) * height / (y1 - y0)
    relief = obj.modifiers.new("Embossed lettering", 'SOLIDIFY')
    relief.thickness = depth
    plate_objects.append(obj)


plate_layer("Nylon plate carrier", .148, .122, .008, -.0008, .0048, dark)
plate_layer("Pressed aluminium black perimeter", .141, .115, .006, -.0026, .0024, ink)
plate_layer("Reflective aluminium face", .137, .111, .005, -.0037, .0012, white)
plate_layer("Blue country strip", .020, .105, .003, -.0041, .0006, band, x=-.055)
legend("Registration upper line", "TS", .010, .024, .055, .032, ink, .00065)
legend("Registration lower line", "7M42", .010, -.024, .093, .033, ink, .00065)
legend("Country letters", "PL", -.055, -.028, .012, .010, white, .00025)
for i in range(12):
    angle = i * math.tau / 12
    plate_layer("Gold ring marking", .00155, .00155, .0006, -.0045, .00015, gold,
                -.055 + .0061 * math.cos(angle), .017 + .0061 * math.sin(angle))
for x in (-.050, .058):
    plate_layer("Screw washer", .008, .008, .0038, -.0058, .002, steel, x, .047)
    plate_layer("Screw slot", .0037, .0008, .00025, -.0060, .00034, dark, x, .047)

for obj in plate_objects:
    obj["asset"] = "Fictional Project Two-Stroke plate TS 7M42"
plate_export = combine("SM50_LicensePlate", [duplicate(obj) for obj in plate_objects], Vector((0, 0, 0)))
plate_export["asset"] = "Fictional Project Two-Stroke plate TS 7M42"
single_material(plate_export, "License plate finishes")
export("SM50-License-Plate.glb", [plate_export])
bpy.data.objects.remove(plate_export, do_unlink=True)

# Complete tail includes the original padded seat, with a reshaped taper, undertray and plate carrier.
tail = [original["Seat"]]
fender = [(-.090, -.585, .850), (-.083, -.746, .862), (-.054, -.876, .876),
          (-.033, -.920, .881), (.033, -.920, .881), (.054, -.876, .876),
          (.083, -.746, .862), (.090, -.585, .850)]
tail.append(layers("Tapered cobalt tail shell", fender, .015, blue, .004))
tail.append(layers("Black rear undertray",
                   [(-.073, -.610, .837), (-.060, -.824, .849), (-.034, -.892, .859),
                    (.034, -.892, .859), (.060, -.824, .849), (.073, -.610, .837)],
                   .017, dark, .003))
for s in (-1, 1):
    panel = [(s * .095, -.320, .836), (s * .097, -.510, .857),
             (s * .076, -.784, .856), (s * .081, -.701, .811),
             (s * .100, -.467, .768), (s * .106, -.375, .783)]
    tail.append(layers("Side number-panel shell", panel, .011, blue, .003))
    stripe = [(s * .099, -.408, .825), (s * .094, -.535, .836),
              (s * .083, -.707, .846), (s * .090, -.543, .815)]
    tail.append(layers("Ice-blue tail graphic", stripe, .002, ice, .0005))

tail_lamp = [(-.055, -.850, .843), (-.041, -.890, .852),
             (.041, -.890, .852), (.055, -.850, .843)]
tail.append(layers("Slim LED tail housing", tail_lamp, .022, dark, .003))
tail.append(layers("Red tail lens", [(-.047, -.866, .838), (-.039, -.894, .847),
                   (.039, -.894, .847), (.047, -.866, .838)], .010, red, .002))
tail.append(layers("Plate stay", [(-.042, -.838, .830), (-.039, -.902, .763),
                  (.039, -.902, .763), (.042, -.838, .830)], .009, dark, .002))

for obj in plate_objects:
    copy = duplicate(obj)
    old_matrix = obj.matrix_world.copy()
    copy.matrix_world = Matrix.Translation(Vector((0, -.906, .769))) @ Matrix.Rotation(
        math.radians(13), 4, 'X') @ old_matrix
    tail.append(copy)

tail_root = combine("Part_seat_std", tail, seat_pivot)
tail_root["pivot"] = "Stock Mount_Seat, at the origin in this export"
single_material(tail_root, "SM50 rear finishes")
export("SM50-Tail.glb", [tail_root])


def png(name, pixels, size):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    stride = size * 3
    scan = b"".join(b"\0" + pixels[i:i + stride] for i in range(0, len(pixels), stride))
    header = struct.pack(">2I5B", size, size, 8, 2, 0, 0, 0)
    (OUT / name).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
                             + chunk(b"IDAT", zlib.compress(scan, 9)) + chunk(b"IEND", b""))


ATLAS = 512
MATERIALS = ["header", "chamber", "weld", "brushed", "cap", "mount"]
SECTIONS = [.115, .229, .320, .427, .579, .733, .868]
MAPS = {"BaseColor": bytearray(), "Roughness": bytearray(), "Metalness": bytearray(), "Normal": bytearray()}


def clamp(value):
    return max(0, min(1, value))


def blend(value, goal, strength):
    return value + (goal - value) * clamp(strength)


def byte(value):
    return round(max(0, min(255, value)))


for y in range(ATLAS):
    tile_y, row = divmod(y, ATLAS // 2)
    v = clamp((row - 4) / 247)
    for x in range(ATLAS):
        tile_x = min(2, x // 170)
        u = clamp((x - tile_x * 170 - 4) / 161)
        key = MATERIALS[tile_y * 3 + tile_x]
        d = min(abs(u - seam - .002 * math.sin(math.tau * v * 3)) for seam in SECTIONS)
        brushed = math.sin(v * math.tau * 105 + .55 * math.sin(u * 12)) * 2.2
        grain = (math.sin(x * 214.9 + y * 311.7) * 37.91) % 1 - .5
        if key in ("header", "chamber", "weld"):
            if key == "header":
                d = min(abs(u - .10), abs(u - .92))
            oxide = math.exp(-d * 72)
            straw = math.exp(-abs(d - .021) * 85)
            indigo = math.exp(-abs(d - .008) * 180)
            base = (126, 132, 138) if key == "header" else (151, 144, 133)
            if key == "weld":
                base = (112, 102, 93)
            color = tuple(blend(blend(c, o, straw * .63), z, indigo * .61)
                          for c, o, z in zip(base, (153, 111, 60), (63, 79, 112)))
            color = [c + 7 * grain + 2 * brushed - 18 * oxide for c in color]
            roughness, metalness = 104 + 32 * oxide, 237 - 32 * oxide
        else:
            base = {"brushed": (167, 171, 176), "cap": (50, 56, 62), "mount": (96, 100, 102)}[key]
            color = [c + brushed * 2.6 + grain * 5 for c in base]
            roughness = 90 if key == "brushed" else 129
            metalness = 229 if key == "brushed" else 189
        MAPS["BaseColor"].extend(map(byte, color))
        MAPS["Roughness"].extend([byte(roughness + grain * 9)] * 3)
        MAPS["Metalness"].extend([byte(metalness)] * 3)
        MAPS["Normal"].extend((byte(128 + grain * 5), byte(128 + brushed * 1.7), 255))

for key, pixels in MAPS.items():
    png("SM50-Exhaust-" + key + ".png", pixels, ATLAS)

exhaust_material = material("Heat-cycled welded steel / brushed alloy", (.36, .28, .21), .82, .37)
nodes = exhaust_material.node_tree.nodes
links = exhaust_material.node_tree.links
shader = nodes.get("Principled BSDF")
for label, socket in (("BaseColor", "Base Color"), ("Roughness", "Roughness"),
                      ("Metalness", "Metallic"), ("Normal", "Normal")):
    image = bpy.data.images.load(str(OUT / ("SM50-Exhaust-" + label + ".png")))
    if label != "BaseColor":
        image.colorspace_settings.name = 'Non-Color'
    image.pack()
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.label = label
    tex.location = (-650, 450 - list(MAPS).index(label) * 275)
    if label == "Normal":
        normal = nodes.new("ShaderNodeNormalMap")
        normal.inputs["Strength"].default_value = .42
        links.new(tex.outputs["Color"], normal.inputs["Color"])
        links.new(normal.outputs["Normal"], shader.inputs[socket])
    else:
        links.new(tex.outputs["Color"], shader.inputs[socket])

CENTERLINES = {
    "Header": [(0.013,.133,.538),(.018,.159,.526),(.040,.200,.493),(.069,.228,.443),(.086,.247,.402),(.094,.251,.369)],
    "ExpansionChamber": [(.094,.251,.369),(.115,.236,.351),(.134,.207,.343),(.146,.171,.346),(.154,.106,.356),(.159,0,.399),(.158,-.091,.460),(.155,-.189,.523),(.151,-.276,.593),(.151,-.337,.649)],
    "Silencer": [(.151,-.337,.649),(.146,-.401,.695),(.144,-.477,.729),(.143,-.493,.735),(.131,-.699,.785),(.128,-.763,.807)],
    "ExhaustMounts": [(.07,-.67,.817),(.163,-.23,.56)],
}


def project(point, centers):
    nearest = math.inf
    for i, (a, b) in enumerate(zip(centers, centers[1:])):
        direction = b - a
        t = clamp((point - a).dot(direction) / direction.length_squared)
        offset = point - a - direction * t
        dist = offset.length_squared
        if dist < nearest:
            nearest = dist
            tangent = direction.normalized()
            side = Vector((1, 0, 0))
            around = tangent.cross(side).normalized()
            best = (i, t, (math.atan2(offset.dot(around), offset.x) / math.tau) % 1)
    return best


stock = []
for name, centerline in CENTERLINES.items():
    obj = original[name]
    coords = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    materials = [mat.name.lower() for mat in obj.data.materials]
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name="Exhaust atlas")
    centers = [Vector(v) for v in centerline]
    for face in obj.data.polygons:
        source_material = materials[face.material_index]
        key = {"Header": "header", "ExpansionChamber": "chamber", "Silencer": "brushed", "ExhaustMounts": "mount"}[name]
        if "weld" in source_material:
            key = "weld"
        elif name == "Silencer" and ("pipe" in source_material or "anodis" in source_material):
            key = "cap"
        tile = MATERIALS.index(key)
        samples = [project(coords[obj.data.loops[i].vertex_index], centers) for i in face.loop_indices]
        cross_seam = max(p[2] for p in samples) - min(p[2] for p in samples) > .5
        for i, (segment, t, angle) in zip(face.loop_indices, samples):
            u = (segment + t) / (len(centers) - 1)
            if name == "ExpansionChamber":
                stations = [0, .050, *SECTIONS, 1]
                u = blend(stations[segment], stations[segment + 1], t)
            # The angular seam is placed at the inside of the pipe. Use the tile's last edge on seam faces.
            if cross_seam and angle < .5:
                angle = 1
            uv.data[i].uv = ((tile % 3 * 170 + 4 + 161 * u) / ATLAS,
                             1 - (tile // 3 * 256 + 4 + 247 * angle) / ATLAS)
        face.material_index = 0
    obj.data.materials.clear()
    obj.data.materials.append(exhaust_material)
    stock.append(obj)

exhaust_root = combine("Part_exhaust_std", stock, exhaust_pivot)
exhaust_root["pivot"] = "Stock Mount_Exhaust, at the origin in this export"
export("SM50-Exhaust.glb", [exhaust_root])

# Arrange the three assets beside each other in the editable source file.
exhaust_root.location.x = -.46
tail_root.location.x = .50
select(plate_objects)
bpy.context.scene.unit_settings.system = 'METRIC'
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            region = area.spaces.active.region_3d
            region.view_rotation = Quaternion((.873, .426, .111, .209)).normalized()
            region.view_distance = 1.8
            region.view_location = Vector((0, .02, 0))
            area.spaces.active.shading.color_type = 'MATERIAL'
bpy.ops.outliner.orphans_purge(do_recursive=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "SM50-Rear-Assets.blend"), compress=True)
