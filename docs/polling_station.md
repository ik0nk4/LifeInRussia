# Polling station interior

The gameplay entry point remains `scenes/locations/polling_station.tscn`. The scene
keeps the established Player, UI, IntroController and interaction paths:

- `VotingBooth/InteractionArea`
- `BallotBox/InteractionArea`

`polling_station_reimagined_environment.tscn` is the active presentation layer. It
instances the Blender-authored GLB at metre scale, adds stable primitive collision,
and owns location-specific lighting and rendering quality. The superseded blockout,
old prop scenes and their dedicated materials, meshes, shaders and light texture
have been removed from the project.

## Layout and coordinates

Godot imports the Blender Z-up source as Y-up without an additional scene transform.
The entrance is on the positive-Z side and the player faces into the room on spawn.

- Player spawn: `(4.25, 0, 3.75)`
- First voting booth: `(2.45, 0, -3.82)`
- Ballot box: `(2.55, 0, -0.38)`
- Commission desks: around `(-3.5, 0, -2.8)`
- Waiting area: along the negative-X windows

The visual GLB is intentionally collision-free. `Collision` in the environment
wrapper contains boxes for the floor, walls, entrance doors, commission furniture,
information panel, booth panels and shelves, ballot box, waiting furniture and
water station. Curtains, plants, lettering and desk accessories have no collision.

The Blender source, GLB, baked colour textures and art review renders are under
`art/polling_station_reimagined/`. The GLB materials remain ordinary imported
metallic/roughness materials. Godot lighting is authored separately and does not
depend on Blender presentation lights.

## Automated check

Run with Godot 4.7.2 or newer from the repository root:

```powershell
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tools/validation/polling_station_visual_check.gd
```

The validation opens the actual main menu, starts a new game, confirms the imported
environment is active and legacy visual instances are absent, walks the player
capsule from the entrance into the first booth, opens the ballot, selects a party,
walks to the ballot box and submits the vote. It also sweeps the capsule against
critical collision and checks that the location rendering override is restored on
exit.

Rendered review views can be captured with a non-headless run and
`-- --capture-dir=<absolute directory>`.

## Manual check

1. Start a new game from the menu and check the initial view and spawn clearance.
2. Walk around both sides of the information panel and commission desks.
3. Enter the first booth, look at the ballot and press E.
4. Select a party and confirm; verify movement returns.
5. Approach the ballot box, look at its upper half and press E.
6. Check collision along booth panels, the entrance doors, walls and waiting area.
7. Inspect window transparency, booth task light, shadows and performance on the
   target machine.

## Street and return

Look at the entrance doors from inside and press E to go outside. The small
`polling_station_street.tscn` courtyard contains a tiled pavement, road, crossing,
apartment facades, trees, lamps, benches and a signed entrance. Look at that entrance and press
E to return. Both transitions are available before and after voting.

Submitting a vote keeps movement enabled and changes the ballot-box hint to
confirm acceptance. It no longer opens the blocking completion panel. Leaving
and returning preserves the selected party and prevents voting a second time.
This is the beginning of exploration; there is still no day progression.

The automated check also exercises round trips before selecting a party, with a
completed ballot, and after submission, including door ray detection and camera
environment restoration. For a manual check, repeat these trips, use Escape to
pause outside, then start a new game to verify that the ballot state resets.

## Rendering and movement revision

- Walkable surfaces meet at y=0 with disjoint footprints. The distant ground is
  lower; road paint is slightly raised. This removes the former ground/road/
  pavement z-fighting. The visible fences and garden walls bound the small area.
- Street placement is offset 100 m from the interior, keeping even background
  building collision away from the polling room.
- Location rendering uses MSAA 4x without TAA. SDFGI and SSIL are disabled; indoor
  ambient fill is tuned for the existing local lights, with SSAO retained.
- Player position is interpolated between physics ticks and camera mouse rotation
  is not delayed by interpolation. Teleporting clears the old interpolation state.
- The door fade pauses with the game and restores movement after completion.

Additional validation:

```powershell
godot --headless --path . --script res://tools/validation/street_movement_check.gd
godot --path . --script res://tools/validation/street_render_review.gd
```

The movement check uses actual movement and E actions, checks the walkable crossing,
boundary collision, outdoor pause and return spawn. The rendered review writes
views and frame/GPU timings to `.godot/street_review/` and samples the live camera
at render cadence. It expects at least 90 moving frames out of 100, no backward
steps, and no position jump above 15 cm in these unobstructed paths. Frame timings
depend on hardware and VSync; this is not a universal FPS guarantee.

Rebuild the modular street with `python tools/art/build_street.py`. Edit that
source for persistent layout changes; rebuilding overwrites generated street
scenes and palette materials. The ground shader and environment resource are
hand-authored and are not overwritten.
