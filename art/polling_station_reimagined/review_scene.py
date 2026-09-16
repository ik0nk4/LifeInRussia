"""Final review pass for the authored Blender scene."""
import bpy, os, json
from mathutils import Vector
ROOT=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'polling_station_reimagined.blend'))
o=bpy.data.objects['information_title'];o.location=(-.94,-3.305,2.24)
scene=bpy.context.scene
import runpy
runpy.run_path(os.path.join(ROOT,'surface_finish.py'))
meshes=[o for o in bpy.data.objects if o.type=='MESH']
assert all(all(abs(v-1)<1e-5 for v in o.scale) for o in meshes)
assert all(len(o.data.vertices)>0 for o in meshes)
assert all(len(o.modifiers)==0 for o in meshes)
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,'polling_station_reimagined.glb'),export_format='GLB',use_selection=True,export_yup=True,export_cameras=False,export_lights=False)
bpy.ops.object.select_all(action='DESELECT')
scene.camera=bpy.data.objects['01_entry_overview']
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'polling_station_reimagined.blend'))
for name in ['01_entry_overview','03_voting_and_urn','04_reverse_waiting']:
    scene.camera=bpy.data.objects[name]
    scene.render.filepath=os.path.join(ROOT,'renders',name+'.png')
    bpy.ops.render.render(write_still=True)
# A supplementary roof-off plan, only for reviewing the spatial arrangement.
for o in bpy.data.objects:
    if o.name=='ceiling' or o.name=='service_bay_bulkhead' or o.name.startswith(('acoustic_raft','raft_suspension','linear_luminaire','luminaire_diffuser','ceiling_vent','vent_louvre')):o.hide_render=True
d=bpy.data.cameras.new('plan_review');cam=bpy.data.objects.new('plan_review',d);scene.collection.objects.link(cam);cam.location=(0,0,18);cam.rotation_euler=(0,0,0);d.type='ORTHO';d.ortho_scale=16
scene.camera=cam;scene.render.resolution_x=1600;scene.render.resolution_y=1200
scene.render.filepath=os.path.join(ROOT,'renders','05_plan.png')
bpy.ops.render.render(write_still=True)
print('REVIEW_COMPLETE: unit scale, applied modifiers, nonempty meshes, export checked',flush=True)
