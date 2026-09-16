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
