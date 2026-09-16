# Polling station / civic hall 0147

Independent Blender environment concept, authored from an empty scene. The existing
game location is only a functional reference. This folder does not integrate or
replace any Godot scene.

## Spatial design

- Interior: 14 × 10 m, 3.8 m clear height; 300 mm exterior walls.
- Off-centre double entrance on the south side opens onto a broad diagonal view.
- The north-west commission bay has a lowered oak portal, a petrol acoustic
  backdrop, two workstations and storage. It is the first visual destination.
- Window-side waiting seats and an independent information panel keep dwell time
  away from the registration and voting route.
- Two booths occupy the north-east side. Their shelves are 790 mm high; gathered
  curtains leave openings of approximately 1.2 m. Curtains are modelled static.
- The ballot box is an independent island south of the booths, visible from the
  entrance. Circulation returns through the open centre.
- Entry mat, radiators, water cooler, bin, plants, printed forms, sockets and a
  fire extinguisher give the space everyday use without cluttering the main route.

Blender coordinates: +Z up; entrance (4.25, -4.2, 0), commission approach
(-3.4, 1.6, 0), booths (2.45 / 4.65, 3.5, 0), urn (2.55, 0.38, 0).
These are placement references, not gameplay markers or implemented triggers.

## Deliverables

- `polling_station_reimagined.blend`: editable grouped source, materials, lighting
  rig, four eye-level review cameras.
- `polling_station_reimagined.glb`: all environment meshes and PBR materials;
  no cameras or presentation lights.
- `renders/`: review images, rendered in Blender Cycles with AgX.
- `build_scene.py`: reproducible Blender authoring script; no external packages.
- `scene_stats.json`: generated geometry counts.
- `textures/`: small baked colour maps for stone and wood, also packed in the
  Blender file and embedded in the GLB. No procedural shader dependency.

Collections: architecture, commission, waiting, voting_booths, ballot_box,
entrance, signage, daily_details, lighting_fixtures, presentation.
The meshes remain individually named and editable. Bevels, fabric thickness and
normals are baked into export geometry. Object rotation and scale are applied;
positions stay in shared world coordinates. Signs are meshes, with no font
dependency at import. Material surfaces use ordinary glTF metallic/roughness PBR.

## Subsequent import

Use the supplied GLB at scale 1. Blender metres map to engine metres; the exporter
converts Z-up to glTF Y-up. The room floor is at zero. Retain the shared origins
when splitting groups into reusable assets.

Lighting in the images is a Blender presentation rig. Recreate daylight, ceiling
illumination and exposure in the target engine; emissive fixture materials alone
will not reproduce the Cycles lighting. Transmission on the ballot box, door and
window panels uses glTF material transmission; inspect its interpretation in the
target renderer and adjust opacity/refraction as needed.

Add simplified collision separately to architecture and major furniture. Do not
generate detailed collision on curtains, lettering, plants or desk accessories.
There are no collision shapes, navigation, spawn nodes, interactions, characters
or scripts in this art delivery. Doors and curtains are static geometry. No
exterior is modelled beyond the window surfaces. Route clearance and final
camera/light settings should be checked after gameplay integration.

Regenerate using Blender 5.2:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python art/polling_station_reimagined/build_scene.py
```

`review_scene.py` rerenders the final views and a roof-off plan from the saved
blend. `surface_finish.py` supplies the baked surface maps used by both scripts.
The supplied scene contains 841 separate meshes and approximately 201k triangles.
It is an environment art source; batch small static details during subsequent
integration if the target platform needs fewer draw calls.

The build loads Windows Arial for the Cyrillic signs and converts all text to
meshes. The finished blend and GLB do not need the font installed.
