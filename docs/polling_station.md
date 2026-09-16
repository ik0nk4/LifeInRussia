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

The current repository still ends the introduction with the existing completion
panel. There is no Day 1 scene, fade controller or next-scene path in the project,
so this integration does not invent a transition destination.
