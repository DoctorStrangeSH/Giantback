#!/usr/bin/env python3
"""Generate a separate Lunar Moth Hero review asset with four animated wing groups.

Run with Blender 4.2.x:
  blender --background --python tools/blender/build_moth_companion.py -- --output-dir build/moth_hero
The legacy moth_companion.obj is never modified.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

GROUPS = (
    "MothHead", "MothThorax", "MothAbdomen",
    "MothWingUpperLeft", "MothWingUpperRight",
    "MothWingLowerLeft", "MothWingLowerRight",
    "MothAntennaLeft", "MothAntennaRight", "MothGlowCore",
)


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args(argv)


def mat(name, color, roughness=0.72, metallic=0.0, emission=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    shader = m.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    if "Emission Color" in shader.inputs:
        shader.inputs["Emission Color"].default_value = (*color, 1)
        shader.inputs["Emission Strength"].default_value = emission
    m["giantback_surface_profile"] = "smooth"
    return m


def sphere(name, location, scale, material, segments=32, rings=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    if not obj.data.uv_layers:
        obj.data.uv_layers.new(name="UVMap")
    return obj


def crescent(name, center, side, material):
    # A filled crescent silhouette (not overlapping oval discs), mirrored per wing.
    cx, cy, cz = center
    outer_radius, inner_radius, inner_offset = 0.145, 0.128, 0.078
    points = []
    for step in range(25):
        angle = math.radians(60 + step * 240 / 24)
        points.append((
            cx + side * outer_radius * math.cos(angle),
            cy + outer_radius * math.sin(angle),
            cz,
        ))
    for step in range(25):
        angle = math.radians(-90 + step * 180 / 24)
        points.append((
            cx + side * (inner_offset + inner_radius * math.cos(angle)),
            cy + inner_radius * math.sin(angle),
            cz,
        ))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(points, [], [tuple(range(len(points)))])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(material)
    uv = mesh.uv_layers.new(name="MoonUV")
    for polygon in mesh.polygons:
        polygon.use_smooth = False
        for loop_index in polygon.loop_indices:
            vertex = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            uv.data[loop_index].uv = (vertex.x - cx + 0.5, vertex.y - cy + 0.5)
    solidify = obj.modifiers.new("Moon inlay thickness", "SOLIDIFY")
    solidify.thickness = 0.018
    bevel = obj.modifiers.new("Soft moon edge", "BEVEL")
    bevel.width = 0.008
    bevel.segments = 2
    return obj


def wing(name, side, upper, materials):
    # Four individually pivoted, thick, scalloped wing shells. X is span, Y is lift.
    span = 1.42 if upper else 1.04
    length = 0.82 if upper else 0.66
    rows, cols = 18, 14
    root_x, root_y, root_z = side * 0.20, 1.52 if upper else 1.28, 0.10 if upper else 0.30
    verts, uvs, faces, material_ids = [], [], [], []
    for layer in (0, 1):
        for r in range(rows + 1):
            t = r / rows
            # Wide outer lobe, pinched root, softly scalloped trailing edge.
            width = (0.10 + 0.90 * (math.sin(math.pi * (t ** 0.78)) ** 0.72)) * (0.30 + 0.70 * t) * span * 1.42
            if t > 0.72:
                width *= 1.0 + 0.055 * math.sin((t - 0.72) * math.pi * 7.0)
            for col in range(cols + 1):
                s = col / cols * 2.0 - 1.0
                x = root_x + side * (t * span + s * width * 0.5)
                y = root_y + t * length + (1.0 - s * s) * 0.11 * math.sin(math.pi * t)
                z = root_z + 0.20 * t * t + 0.10 * (1.0 - s * s) - layer * 0.055
                verts.append((x, y, z))
                uvs.append((col / cols, t))
    layer_size = (rows + 1) * (cols + 1)
    def idx(layer, r, col):
        return layer * layer_size + r * (cols + 1) + col
    # front and back grids
    for layer in (0, 1):
        for r in range(rows):
            for col in range(cols):
                a, b, c, d = idx(layer,r,col), idx(layer,r,col+1), idx(layer,r+1,col+1), idx(layer,r+1,col)
                faces.append((a,b,c,d) if layer == 0 else (d,c,b,a))
                material_ids.append(0 if r < 7 else (1 if col < cols*0.58 else 2))
    # sealed perimeter strips
    boundary = []
    boundary += [(0,c) for c in range(cols+1)]
    boundary += [(r,cols) for r in range(1,rows+1)]
    boundary += [(rows,c) for c in range(cols-1,-1,-1)]
    boundary += [(r,0) for r in range(rows-1,0,-1)]
    for k,(r,c) in enumerate(boundary):
        nr,nc = boundary[(k+1)%len(boundary)]
        faces.append((idx(0,r,c),idx(0,nr,nc),idx(1,nr,nc),idx(1,r,c)))
        material_ids.append(3)
    mesh=bpy.data.meshes.new(name+"Mesh")
    mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj)
    for m in materials: mesh.materials.append(m)
    for poly,mid in zip(mesh.polygons,material_ids): poly.material_index=mid; poly.use_smooth=True
    uv=mesh.uv_layers.new(name="WingUV")
    for poly in mesh.polygons:
        for loop_index in poly.loop_indices:
            vi=mesh.loops[loop_index].vertex_index
            uv.data[loop_index].uv=uvs[vi % layer_size]
    obj["pivot_hint"]="root at thorax; animate local X rotation with mirrored phase"
    obj["wing_role"]="upper" if upper else "lower"
    return obj


def moth_leg(name, side, start_y, end_y, material):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 12
    curve.bevel_depth = 0.028
    curve.bevel_resolution = 3
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(2)
    coords = [
        (side * 0.22, start_y, -0.10),
        (side * 0.39, (start_y + end_y) * 0.5, -0.16),
        (side * 0.56, end_y, -0.12),
    ]
    for point, co in zip(spline.bezier_points, coords):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    foot = sphere(name + "Foot", coords[-1], (0.075, 0.045, 0.07), material, 16, 10)
    return [obj, foot]


def antenna(name, side, material):
    # A single curved, tapered stem with a soft club tip; no floating bead segments.
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 16
    curve.bevel_depth = 0.022
    curve.bevel_resolution = 4
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(3)
    coords = [
        (side * 0.12, 2.12, -0.43),
        (side * 0.16, 2.31, -0.40),
        (side * 0.31, 2.43, -0.35),
        (side * 0.43, 2.34, -0.30),
    ]
    for point, co in zip(spline.bezier_points, coords):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    tip = sphere(name + "Club", coords[-1], (0.045, 0.065, 0.045), material, 20, 12)
    return [obj, tip]


def configure_scene(output):
    scene=bpy.context.scene
    scene.render.engine="BLENDER_EEVEE_NEXT"
    scene.eevee.taa_render_samples=16
    scene.render.resolution_x=768; scene.render.resolution_y=768; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.view_settings.view_transform="Standard"
    scene.world.color=(0.22,0.22,0.22)
    world=scene.world
    world.use_nodes=True
    world.node_tree.nodes["Background"].inputs["Color"].default_value=(0.16,0.18,0.24,1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value=0.35
    for name,loc,power,size in [
        ("Key",(3.4,4.8,-4.5),520,4.0),("Fill",(-3.5,2.4,-1.0),230,3.5),("Rim",(0,4,4),360,3.0)]:
        data=bpy.data.lights.new(name,"AREA"); data.energy=power; data.shape="DISK"; data.size=size
        obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj); obj.location=loc
        obj.rotation_euler=(Vector((0,1.2,0))-obj.location).to_track_quat("-Z","Y").to_euler()
    camera_data=bpy.data.cameras.new("MothReviewCamera"); camera=bpy.data.objects.new("MothReviewCamera",camera_data)
    scene.collection.objects.link(camera); camera_data.type="ORTHO"; camera_data.ortho_scale=4.6
    scene.camera=camera
    return camera


def render_views(camera, output):
    scene=bpy.context.scene
    center=Vector((0,1.45,0.12))
    views={
      "three_quarter":Vector((4.0,2.6,-5.0)),
      "front":Vector((0,1.8,-6.0)),
      "side":Vector((6.0,1.8,0.0)),
      "back":Vector((0,1.8,6.0)),
    }
    for name,direction in views.items():
        camera.location=center+direction
        camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
        scene.render.filepath=str(output/f"moth_companion_hero_{name}.png")
        bpy.ops.render.render(write_still=True)


def mesh_report(objects, output):
    # Aggregate decorative mesh pieces into stable gameplay rig groups.
    def group_for(name):
        if name == "MothHead" or name.startswith("MothEye"):
            return "MothHead"
        if name == "MothThorax" or name.startswith("MothThoraxLeg"):
            return "MothThorax"
        if name == "MothAbdomen" or name.startswith("AbdomenBand"):
            return "MothAbdomen"
        if name.startswith("MothWingUpper"):
            return name
        if name.startswith("MothWingLower"):
            return name
        if name.startswith("WingMoonUpper"):
            return "MothWingUpper" + ("Left" if name.endswith("Left") else "Right")
        if name.startswith("WingMoonLower"):
            return "MothWingLower" + ("Left" if name.endswith("Left") else "Right")
        if name.startswith("MothAntennaLeft"):
            return "MothAntennaLeft"
        if name.startswith("MothAntennaRight"):
            return "MothAntennaRight"
        if name == "MothGlowCore":
            return "MothGlowCore"
        return None

    grouped = {name: [] for name in GROUPS}
    for obj in objects:
        key = group_for(obj.name)
        if key:
            grouped[key].append(obj)
    parts = {}
    for name, members in grouped.items():
        mesh_members = [obj for obj in members if obj.type == "MESH"]
        if not mesh_members:
            continue
        zero_area = 0
        nonmanifold = 0
        for obj in mesh_members:
            bm = bmesh.new()
            bm.from_mesh(obj.data)
            zero_area += sum(face.calc_area() < 1e-10 for face in bm.faces)
            nonmanifold += sum(not edge.is_manifold for edge in bm.edges)
            bm.free()
        materials = sorted({m.name for obj in mesh_members for m in obj.data.materials if m})
        profiles = {m.name: m.get("giantback_surface_profile", "smooth")
                    for obj in mesh_members for m in obj.data.materials if m}
        parts[name] = {
            "vertices": sum(len(obj.data.vertices) for obj in mesh_members),
            "faces": sum(len(obj.data.polygons) for obj in mesh_members),
            "zero_area_faces": zero_area,
            "non_manifold_edges": nonmanifold,
            "uv_layers": min(len(obj.data.uv_layers) for obj in mesh_members),
            "materials": materials,
            "material_profiles": profiles,
        }
    report = {"part_count": len(parts), "parts": parts}
    (output / "moth_companion_hero_mesh_report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8")
    return report

def main():
    options=args(); output=options.output_dir
    if output.exists() and any(output.iterdir()) and not options.overwrite:
        raise SystemExit(f"{output} is not empty; pass --overwrite to replace generated review files")
    output.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    ivory=mat("moon_ivory",(0.93,0.86,0.73),0.88)
    lilac=mat("wing_lilac",(0.48,0.31,0.76),0.68)
    rose=mat("wing_rose",(0.82,0.48,0.67),0.72)
    cyan=mat("wing_cyan",(0.24,0.70,0.76),0.62,emission=0.12)
    gold=mat("moon_gold",(0.88,0.62,0.28),0.48,metallic=0.25)
    plum=mat("deep_plum",(0.12,0.075,0.17),0.35)
    glow=mat("moon_core",(0.48,0.88,0.88),0.28,emission=1.2)
    parts=[]
    parts.append(sphere("MothThorax",(0,1.20,0),(0.30,0.72,0.27),ivory,48,32))
    parts.append(sphere("MothHead",(0,1.91,-0.20),(0.40,0.37,0.34),ivory,40,28))
    
    for i in range(3):
        parts.append(sphere(
            f"AbdomenBand{i}",
            (0,0.72+i*0.19,-0.145),
            (0.235,0.025,0.045),
            gold,
            24,
            12
        ))
    for side,suffix in [(-1,"Left"),(1,"Right")]:
        parts.append(sphere("MothEye"+suffix,(side*0.20,1.97,-0.493),(0.075,0.095,0.035),plum,24,16))
        parts.extend(antenna("MothAntenna"+suffix,side,gold))
        for leg_index, (start_y, end_y) in enumerate(((1.02,0.70),(0.84,0.52),(0.66,0.36))):
            parts.extend(moth_leg("MothThoraxLeg"+suffix+str(leg_index+1),side,start_y,end_y,ivory))
    parts.append(sphere("MothGlowCore",(0,1.53,-0.34),(0.115,0.13,0.075),glow,32,20))
    wing_mats=[lilac,rose,cyan,gold]
    for side,suffix in [(-1,"Left"),(1,"Right")]:
        for upper,wing_name in ((True,"Upper"),(False,"Lower")):
            parts.append(wing("MothWing"+wing_name+suffix,side,upper,wing_mats))
            span = 1.42 if upper else 1.04
            length = 0.82 if upper else 0.66
            root_x = side * 0.20
            root_y = 1.52 if upper else 1.28
            root_z = 0.10 if upper else 0.30
            t = 0.57
            mark_x = root_x + side * t * span
            mark_y = root_y + t * length + 0.055
            mark_z = root_z + 0.20 * t * t + 0.10 - 0.055 - 0.012
            parts.append(crescent(
                "WingMoon" + wing_name + suffix,
                (mark_x, mark_y, mark_z),
                side,
                gold
            ))
    # Every required rig group is represented by one or more named mesh objects.
    rig={"version":1,"character":"LunarMothHero","forward_axis":"-Z","up_axis":"+Y",
         "parts":list(GROUPS),"wing_groups":["MothWingUpperLeft","MothWingUpperRight","MothWingLowerLeft","MothWingLowerRight"],
         "animation_states":["idle_hover","follow","reveal_secret","ability_burst","rest"],
         "notes":"Review blockout only; independent wing pivots are metadata hints, not a Roblox-ready animation rig."}
    (output/"moth_companion_hero_rig.json").write_text(json.dumps(rig,indent=2),encoding="utf-8")
    camera=configure_scene(output)
    scene=bpy.context.scene
    scene.render.film_transparent=False
    mesh_report(parts,output)
    blend=output/"moth_companion_hero.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.wm.obj_export(filepath=str(output/"moth_companion_hero.obj"),export_materials=True,export_uv=True)
    render_views(camera,output)
    print("Lunar Moth Hero review package generated:",output)


if __name__=="__main__":
    main()
