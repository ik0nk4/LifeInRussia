# Polling station interior

The entry point is `scenes/locations/polling_station.tscn`. It retains the existing
Player, UI, IntroController and both InteractionArea node paths.

- `polling_station_room.tscn`: room shell, entrance recess, windows, ceiling panels,
  signage and furniture placement. The room is approximately 8 x 11 m, 3 m high.
- `scenes/props/`: reusable commission desk, chair, voting booth, gathered curtain,
  ballot box and a separate scene for small room details.
- `assets/materials/polling_station/`: shared matte paint, subtly textured floor,
  wood laminate, fabric, metal and diffused glazing. Noise textures are native
  Godot resources; no addons or external asset dependencies.
- `assets/models/polling_station/`: rounded chair cushions and gathered curtain.
  These are static OBJ source assets, editable/replacable without gameplay changes.

Keep the central aisle and the front of the booth clear. The gathered curtain is
visual only; rigid booth panels and writing shelf have collisions. The entrance
recess is enclosed behind the player so the player cannot walk outside the room.
The window surfaces represent diffused glazing, not another explorable space.

## Manual check

1. Run the project, select New Game and walk through the entrance.
2. Inspect reception, waiting chairs, notices and lighting at normal eye height.
3. Enter the booth, look down at the ballot on the shelf and press E.
4. Select a party and confirm; back out of the booth and approach the urn.
5. Look toward its lid and press E. Confirm the existing completion screen appears.
6. Check walls, desk, chairs, booth panels and urn block movement without snagging
   the normal route. Check text readability at the intended game resolution.

Automated checks in Godot 4.7.2 covered menu-to-location loading, player capsule
movement along this route, obstacle sweeps, interaction-ray hits, ballot selection
and submission. The scene was also rendered and inspected using Forward+ / D3D12.

At the time of this change, the existing intro UI ends with a completion message.
Its source contains no fade or Day 1 transition. This visual task leaves that
behavior unchanged; no Day 1 scene or progression system was added.

## Experimental ultra-quality pass

The `content/polling-station-ultra` experiment uses the same location and gameplay
paths. No project settings, party data, player controller or intro/UI logic changed.
It targets the existing Forward+ renderer, not a new minimum hardware baseline.

- Warm projected afternoon light through the three windows contrasts with cool
  glazing and softer ceiling illumination. The window projector is an authored SVG
  light mask, not an exterior scene. SDFGI, SSAO, SSIL and restrained glow belong to
  this location's Environment resource.
- `polling_station_quality.gd`, attached to WorldEnvironment, enables 4x MSAA, TAA
  and a 4096 positional shadow atlas for the location. Previous viewport values are
  restored on exit; the main menu and future locations do not inherit the override.
- Metre-scaled shaders provide 600 mm terrazzo slabs, darker perimeter tiles,
  aggregate, roughness variation, two-tone wall paint and directional oak laminate.
  Fine procedural detail fades with pixel footprint to reduce distance aliasing.
- Rounded static OBJ meshes replace only the desk top, booth shelf and urn body/lid.
  Original collision shapes, furniture positions and interaction transforms remain.
- Reusable `window_blinds`, `desk_accessories`, `chair_hardware`, `urn_hardware`,
  `ballot_print`, `booth_fittings`, `civic_notices` and `polling_station_finish`
  scenes hold decoration.
  The finish scene contains the 600 mm ceiling grid, light louvres, ventilation,
  radiator ribs/valves, skirting, wall trim and entry door fittings. These small
  surface details do not add obstacles in the walking route.
- Superseded floor/ceiling joint meshes and simple luminous ceiling panels were
  removed. The light fittings replace those panels at the same positions.

### Reproducible validation

Run with a Godot 4 executable from the repository root:

```powershell
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tools/validation/polling_station_visual_check.gd
```

The check opens the menu and emits its actual New Game button signal, moves the
player capsule along the route, checks both interaction rays, selects/confirms a
party through UI signals, submits the ballot and checks the existing completion
panel. Capsule sweeps cover the desk, chair, booth shelf, urn, back wall and entry
boundary. It also checks viewport restoration when returning to the menu.

For five rendered review views, omit `--headless` and append
`-- --capture-dir=C:/Temp/polling_ultra`. Screenshots are generated outside the
repository. This is a deterministic scene check, not a replacement for manually
walking with mouse/keyboard and testing the E key.

Manual acceptance: inspect light/shadow stability while moving, readability of
the ballot and signs, close-up furniture surfaces, entrance/booth clearance and
frame time at your target resolution. GI, multiple shadowed lights and combined
MSAA/TAA are intentionally expensive; assess performance on target hardware.
There is still no implemented fade or Day 1 scene to validate in this repository.

Validated with Godot 4.7.2: headless import and gameplay/route check passed;
Forward+ / D3D12 rendered checks also passed on an RX 9060 XT. Five 1600 x 1000
views were inspected (entrance, commission desk, booth ballot, urn, entry doors).
These short automated captures are not a sustained performance benchmark.
