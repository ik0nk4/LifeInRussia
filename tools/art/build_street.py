"""Author the small courtyard as editable, modular Godot scenes. No dependencies.

Run from any directory with Python 3. Repeated primitives are grouped by material
in MultiMeshes. Nothing is generated during gameplay. Coordinates are in metres.
"""
from collections import defaultdict
from pathlib import Path
import json
import math
import random

ROOT = Path(__file__).resolve().parents[2]
PROPS = ROOT / "scenes/props/street"
MATERIALS = ROOT / "art/street/materials"
PALETTE = {
    "cream": (0.73, 0.69, 0.57), "ivory": (0.88, 0.86, 0.75),
    "sage": (0.46, 0.53, 0.43), "brick": (0.58, 0.36, 0.26),
    "plinth": (0.31, 0.34, 0.32), "metal": (0.12, 0.20, 0.20),
    "glass": (0.22, 0.36, 0.40), "glass_light": (0.39, 0.49, 0.48),
    "wood": (0.44, 0.28, 0.14), "bark": (0.41, 0.40, 0.33),
    "leaf": (0.38, 0.47, 0.21), "leaf_light": (0.53, 0.57, 0.27),
    "leaf_dark": (0.25, 0.36, 0.19), "soil": (0.27, 0.28, 0.21),
    "asphalt": (0.26, 0.28, 0.27), "paving": (0.60, 0.59, 0.53),
    "curb": (0.68, 0.68, 0.61), "paint": (0.81, 0.78, 0.64),
    "lamp": (0.95, 0.89, 0.68), "red": (0.51, 0.20, 0.15),
}


def numbers(values):
    return ", ".join(f"{v:.5f}".rstrip("0").rstrip(".") if v else "0" for v in values)


def vec(values):
    return f"Vector3({numbers(values)})"


class Scene:
    def __init__(self, name):
        self.name = name
        self.groups = defaultdict(list)
        self.colliders = []
        self.nodes = []
        self.externals = {}

    def shape(self, material, position, size, kind="box", yaw=0, solid=False):
        self.groups[(material, kind)].append((position, size, yaw))
        if solid:
            self.colliders.append((position, size, yaw))

    def box(self, material, position, size, solid=False, yaw=0):
        self.shape(material, position, size, solid=solid, yaw=yaw)

    def instance(self, name, path, position=(0, 0, 0), yaw=0, scale=1):
        resource = "scene_" + Path(path).stem
        self.externals[resource] = ('PackedScene', path)
        self.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{resource}")]\n'
                          f'position = {vec(position)}\nrotation_degrees = Vector3(0, {yaw}, 0)\n'
                          f'scale = Vector3({scale}, {scale}, {scale})')

    def label(self, name, text, position, size=40, pixel=0.005, color="ivory", yaw=0):
        self.nodes.append(f'[node name="{name}" type="Label3D" parent="."]\n'
                          f'position = {vec(position)}\nrotation_degrees = Vector3(0, {yaw}, 0)\n'
                          f'text = {json.dumps(text, ensure_ascii=False)}\nfont_size = {size}\n'
                          f'pixel_size = {pixel}\nmodulate = Color({numbers(PALETTE[color])}, 1)\n'
                          'outline_size = 0\nshaded = true\ndouble_sided = false')

    def save(self, path):
        resources = []
        nodes = [f'[node name="{self.name}" type="Node3D"]\nphysics_interpolation_mode = 2']
        for material, kind in self.groups:
            self.externals[material] = ('Material', f'res://art/street/materials/{material}.tres')
            key = material + "_" + kind
            if kind == "box":
                primitive = 'BoxMesh"\nsize = Vector3(1, 1, 1)'
            elif kind == "cylinder":
                primitive = 'CylinderMesh"\ntop_radius = 0.5\nbottom_radius = 0.5\nheight = 1\nradial_segments = 10\nrings = 1'
            else:
                primitive = 'SphereMesh"\nradius = 0.5\nheight = 1\nradial_segments = 16\nrings = 8'
            typ, props = primitive.split('"\n', 1)
            resources.append(f'[sub_resource type="{typ}" id="mesh_{key}"]\n{props}\nmaterial = ExtResource("{material}")')
            buffer = []
            for (x, y, z), (sx, sy, sz), yaw in self.groups[(material, kind)]:
                c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
                buffer.extend((c*sx, 0, s*sz, x, 0, sy, 0, y, -s*sx, 0, c*sz, z))
            resources.append(f'[sub_resource type="MultiMesh" id="batch_{key}"]\ntransform_format = 1\n'
                             f'instance_count = {len(self.groups[(material, kind)])}\nmesh = SubResource("mesh_{key}")\n'
                             f'buffer = PackedFloat32Array({numbers(buffer)})')
            nodes.append(f'[node name="{key}" type="MultiMeshInstance3D" parent="."]\nmultimesh = SubResource("batch_{key}")')
        if self.colliders:
            nodes.append('[node name="Collision" type="StaticBody3D" parent="."]')
        for i, (position, size, yaw) in enumerate(self.colliders):
            resources.append(f'[sub_resource type="BoxShape3D" id="collision_{i}"]\nsize = {vec(size)}')
            nodes.append(f'[node name="Shape{i}" type="CollisionShape3D" parent="Collision"]\n'
                         f'position = {vec(position)}\nrotation_degrees = Vector3(0, {yaw}, 0)\nshape = SubResource("collision_{i}")')
        externals = [f'[ext_resource type="{typ}" path="{p}" id="{key}"]' for key, (typ, p) in self.externals.items()]
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("\n\n".join(['[gd_scene format=3]'] + externals + resources + nodes + self.nodes) + "\n", encoding="utf-8")


def materials():
    MATERIALS.mkdir(parents=True, exist_ok=True)
    for name, color in PALETTE.items():
        if name in ("paving", "asphalt"):
            text = ('[gd_resource type="ShaderMaterial" format=3]\n\n'
                    '[ext_resource type="Shader" path="res://art/street/materials/ground.gdshader" id="shader"]\n\n'
                    '[resource]\nshader = ExtResource("shader")\n'
                    f'shader_parameter/base_color = Color({numbers(color)}, 1)\n'
                    f'shader_parameter/tile_strength = {0.12 if name == "paving" else 0.0}\n')
        else:
            text = ('[gd_resource type="StandardMaterial3D" format=3]\n\n[resource]\n'
                    f'albedo_color = Color({numbers(color)}, 1)\nroughness = {0.3 if "glass" in name else 0.87}\n'
                    'metallic_specular = 0.25\n')
        (MATERIALS / f"{name}.tres").write_text(text, encoding="utf-8")


def window(scene, x, y, z, width=1.45, height=1.65):
    scene.box("plinth", (x, y, z), (width+0.22, height+0.22, 0.15))
    scene.box("ivory", (x, y, z+0.09), (width, height, 0.08))
    for dx in (-width/4, width/4):
        scene.box("glass" if dx < 0 else "glass_light", (x+dx, y, z+0.14), (width/2-0.075, height-0.12, 0.035))
    scene.box("ivory", (x, y+height*0.19, z+0.18), (width, 0.05, 0.04))
    scene.box("ivory", (x, y-height/2-0.045, z+0.18), (width+0.28, 0.09, 0.37))


def station():
    s = Scene("StationFacade")
    # Front at z=0, building recedes behind it. Door at x=6.
    s.box("cream", (-4.625, 2.15, -2.6), (18.75, 4.3, 5.2), True)
    s.box("cream", (10.625, 2.15, -2.6), (6.75, 4.3, 5.2), True)
    s.box("cream", (6, 3.65, -2.6), (2.5, 1.3, 5.2), True)
    for x, width in [(-4.625,18.75),(10.625,6.75)]:
        s.box("plinth", (x, 0.3, 0.045), (width,0.6,0.13))
        s.box("ivory", (x, 0.66, 0.09), (width,0.12,0.23))
    s.box("ivory", (0,4.25,-2.5), (28.6,0.22,5.6))
    s.box("metal", (0,4.43,-2.5), (28.8,0.14,5.8))
    for x in (-12,-8.7,-5.4,-2.1,1.2,10.5):
        window(s,x,2.2,0.05,2.0,2.1)
    for x in (-13.6,3.5,8.45,13.6):
        s.box("ivory",(x,2.1,0.12),(0.28,4,0.22))
    s.box("metal",(6,1.43,0.02),(2.5,2.86,0.12),True)
    for x in (5.38,6.62):
        s.box("glass",(x,1.67,0.1),(1.12,1.95,0.045))
        s.box("sage",(x,0.37,0.1),(1.12,0.59,0.05))
        s.box("ivory",(x,1.05,0.18),(0.04,0.43,0.06))
    s.box("metal",(6,2.97,0.6),(3.45,0.15,1.65))
    s.box("ivory",(6,3.065,0.6),(3.55,0.05,1.75))
    s.box("metal",(6,3.63,0.13),(4.65,0.8,0.17))
    s.label("Title","ИЗБИРАТЕЛЬНЫЙ УЧАСТОК",(6,3.75,0.23),40,0.0035)
    s.label("Number","№ 0147  /  ВХОД",(6,3.44,0.23),32,0.0032)
    s.box("metal",(3.95,1.7,0.17),(0.78,0.9,0.12))
    s.label("Hours","РЕЖИМ РАБОТЫ\n08:00 — 20:00",(3.95,1.7,0.245),28,0.0026)
    s.box("wood",(-0.7,1.65,0.16),(1.75,1.3,0.16))
    for i in range(3):
        s.box("paint",(-1.23+i*0.53,1.66,0.255),(0.43,0.84,0.025))
        for line in range(6):
            s.box("plinth",(-1.23+i*0.53,1.9-line*0.07,0.271),(0.28,0.014,0.005))
    for x in (-13.85,13.85):
        s.shape("metal",(x,2.1,0.22),(0.09,4.2,0.09),"cylinder")
    s.save(PROPS/"station_facade.tscn")


def apartment():
    s=Scene("ApartmentBlock")
    s.box("cream",(0,6,-3),(18,12,6),True)
    s.box("sage",(0,0.63,0.055),(18,1.26,0.13))
    for x in (-8.9,8.9):
        s.box("ivory",(x,6,0.12),(0.25,12,0.23))
    for y in (1.3,4.0,6.8,9.6,11.9):
        s.box("ivory",(0,y,0.07),(18.2,0.12,0.21))
    s.box("plinth",(0,12.13,-3),(18.5,0.25,6.5))
    for y in (2.5,5.3,8.1,10.9):
        for x in (-7.2,-4.3,-1.45,1.45,4.3,7.2):
            window(s,x,y,0.06,1.35,1.6)
        for x in (-4.3,4.3):
            if y < 4:
                continue
            s.box("ivory",(x,y-0.95,0.55),(2.15,0.14,1.05))
            s.box("sage",(x,y-0.5,1.02),(2.15,0.75,0.10))
            for dx in (-1.02,1.02):
                s.box("metal",(x+dx,y-0.5,0.6),(0.055,0.85,0.86))
            s.box("metal",(x,y-0.07,1.04),(2.22,0.055,0.07))
    s.box("metal",(0,1.15,0.12),(1.55,2.3,0.16))
    s.box("glass",(0,1.6,0.22),(1.25,1.08,0.035))
    s.box("plinth",(0,2.42,0.65),(2.5,0.15,1.4))
    s.label("Address","ЛИПОВАЯ, 12",(0,3.0,0.25),32,0.0035,color="metal")
    for x in (-8.6,8.6):
        s.shape("plinth",(x,5.9,0.2),(0.1,11.8,0.1),"cylinder")
    s.save(PROPS/"apartment_block.tscn")


def furniture():
    s=Scene("Bench")
    for z in (-0.21,-0.07,0.07,0.21):
        s.box("wood",(0,0.47,z),(1.85,0.065,0.11))
    for y in (0.71,0.86,1.01):
        s.box("wood",(0,y,-0.24),(1.85,0.11,0.065))
    for x in (-0.69,0.69):
        s.box("metal",(x,0.25,0),(0.075,0.5,0.43))
        s.box("metal",(x,0.67,-0.26),(0.06,0.76,0.07))
    s.colliders.append(((0,0.5,0),(1.9,1.05,0.6),0))
    s.save(PROPS/"bench.tscn")
    s=Scene("StreetLamp")
    s.shape("metal",(0,2.25,0),(0.085,4.5,0.085),"cylinder")
    s.shape("plinth",(0,0.13,0),(0.28,0.26,0.28),"cylinder")
    s.box("metal",(0,4.42,0.35),(0.12,0.12,0.75))
    s.box("metal",(0,4.34,0.68),(0.44,0.15,0.64))
    s.box("lamp",(0,4.25,0.68),(0.35,0.025,0.52))
    s.colliders.append(((0,2.25,0),(0.2,4.5,0.2),0))
    s.save(PROPS/"street_lamp.tscn")
    s=Scene("LindenTree")
    s.shape("bark",(0,1.9,0),(0.20,3.8,0.20),"cylinder")
    rng=random.Random(43)
    for i in range(25):
        angle=i*2.4
        radius=rng.uniform(0.35,1.15)
        height=rng.uniform(3.2,5.3)
        if height > 4.8:
            radius *= 0.55
        position=(math.cos(angle)*radius,height,math.sin(angle)*radius)
        size=rng.uniform(1.05,1.5)
        s.shape(("leaf","leaf_light","leaf_dark")[i%3],position,(size,size*1.25,size*0.85),"sphere",yaw=i*17)
    s.colliders.append(((0,1.5,0),(0.35,3,0.35),0))
    s.save(PROPS/"linden_tree.tscn")


def street():
    s=Scene("PollingStationStreet")
    # The background sits well below the slabs, never coplanar with them.
    s.box("soil",(0,-0.4,4),(150,0.1,120))
    # Non-overlapping slabs. The walkable tops all meet at y=0.
    s.box("paving",(0,-0.15,-2.5),(42,0.3,5),True)
    s.box("asphalt",(0,-0.15,3),(42,0.3,6),True)
    s.box("paving",(0,-0.15,7.5),(42,0.3,3),True)
    s.box("soil",(0,-0.15,12),(42,0.3,6),True)
    s.instance("Station","res://scenes/props/street/station_facade.tscn",(0,0,-5))
    s.instance("WestResidence","res://scenes/props/street/apartment_block.tscn",(-11,0,13.5),180)
    s.instance("EastResidence","res://scenes/props/street/apartment_block.tscn",(10,0,14.7),180)
    for x in (-16,-10,-3,12,18):
        s.box("curb",(x,0.12,-1.6),(2.2,0.24,2.1))
        s.box("soil",(x,0.25,-1.6),(1.94,0.05,1.84))
        s.colliders.append(((x,0.12,-1.6),(2.2,0.24,2.1),0))
        s.instance(f"TreeNear{x}","res://scenes/props/street/linden_tree.tscn",(x,0.27,-1.6),x*11)
    for x in (-18,-5,4,18):
        s.instance(f"TreeFar{x}","res://scenes/props/street/linden_tree.tscn",(x,0,10.2),x*9,1.15)
    for x in (-7,0,10):
        s.instance(f"Bench{x}","res://scenes/props/street/bench.tscn",(x,0,-4.1))
        s.box("metal",(x+1.4,0.4,-4),(0.4,0.8,0.4),True)
        s.box("plinth",(x+1.4,0.82,-4),(0.46,0.05,0.46))
    for x in (-19,-6,8,19):
        s.instance(f"Lamp{x}","res://scenes/props/street/street_lamp.tscn",(x,0,6.7),180)
    # Kerbs stop at the flush pedestrian crossing, preserving an accessible route.
    for z in (0,6):
        for x in range(-20,21):
            if 3 <= x <= 7:
                continue
            s.box("curb",(x,0.045,z),(0.95,0.09,0.20))
    for z in (0.55,1.6,2.65,3.7,4.75,5.8):
        s.box("paint",(5,0.008,z),(3.1,0.012,0.43))
    for x in range(-19,20,4):
        if 2 <= x <= 7:
            continue
        s.box("paint",(x,0.008,3),(1.6,0.012,0.085))
    # Visible fences bound the playable courtyard, with a distant streetscape behind.
    for x in (-20.5,20.5):
        s.colliders.append(((x,1.4,3.65),(0.3,2.8,18.4),0))
        for z in range(-5,13):
            s.box("metal",(x,0.72,z),(0.09,1.44,0.09))
        for y in (0.4,1.13):
            s.box("metal",(x,y,3.65),(0.07,0.06,18.4))
        for z in (-2,8):
            s.instance(f"BoundaryTree{x}_{z}","res://scenes/props/street/linden_tree.tscn",(x,0,z),30,1.2)
    for x in (-17.3,17.3):
        s.box("sage",(x,0.7,-5),(6.8,1.4,0.35),True)
        s.box("ivory",(x,1.43,-5),(7,0.09,0.46))
    s.colliders.append(((0,1.5,12.3),(42,3,0.3),0))
    for x in range(-20,21,2):
        s.shape("leaf_dark",(x,0.65,12),(2.2,1.3,1.4),"sphere")
    # Adjacent buildings add depth without enclosing the street in blank walls.
    s.instance("DistantWest","res://scenes/props/street/apartment_block.tscn",(-28,0,12),120)
    s.instance("DistantEast","res://scenes/props/street/apartment_block.tscn",(29,0,16),210)
    s.instance("EntranceInteraction","res://scenes/components/interaction_area.tscn",(6,1.6,-4.8))
    s.nodes[-1]+='\ninteraction_hint = "Войти на участок (E)"'
    # Area shape is enlarged locally, without a scaled collision body.
    s.nodes.append('[node name="CollisionShape3D" parent="EntranceInteraction" index="0"]\nscale = Vector3(3, 2, 1)')
    s.nodes.append('[node name="ExitSpawn" type="Marker3D" parent="."]\nposition = Vector3(6, 0, -3.6)\nrotation_degrees = Vector3(0, 180, 0)')
    s.nodes.append('[node name="Sun" type="DirectionalLight3D" parent="."]\nrotation_degrees = Vector3(-42, -32, 0)\n'
                   'light_color = Color(1, 0.94, 0.82, 1)\nlight_energy = 1.15\nshadow_enabled = true\n'
                   'directional_shadow_max_distance = 65.0\ndirectional_shadow_mode = 1\nshadow_blur = 1.4')
    s.save(ROOT/"scenes/locations/polling_station_street.tscn")


if __name__ == "__main__":
    materials()
    station()
    apartment()
    furniture()
    street()
    print("Street scenes rebuilt.")
