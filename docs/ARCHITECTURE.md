# Architecture

## Status
Initial guardrails only. Do not over-engineer before gameplay requirements are defined.

## Goals
- Keep systems understandable for two developers plus Codex.
- Minimize scene merge conflicts.
- Keep narrative/event content separate from low-level NPC implementation.
- Make day-to-day world changes easy to author later.

## Proposed project layout

```text
assets/
  audio/
  materials/
  models/
  textures/

data/
  dialogue/
  events/
  days/

scenes/
  characters/
  locations/
  props/
  ui/

scripts/
  characters/
  components/
  ui/

systems/
  game_state/
  interaction/
  events/
  day_cycle/

ui/

docs/
```

Directories may change when concrete systems are designed.

## Principles

### Scenes
- Prefer small scenes composed into larger locations.
- Avoid one giant world scene edited by everyone.
- Reusable props/NPC pieces should be their own scenes where practical.

### Systems
- Shared/global gameplay state should live in explicit systems rather than random NPC scripts.
- Avoid putting unrelated responsibilities into one manager.
- Add Autoload singletons only when a genuine project-wide lifetime is required.

### Content/data
Dialogue, events and day-specific world changes should become data-driven where it reduces duplication and improves authoring.

Do not choose a complex data format yet. Godot Resources, JSON or another format should be selected per system when requirements are clear.

### Dependencies
Game-specific code should not depend on third-party addons unless the team explicitly approves them.

## Likely future systems
These are expected areas, not implementation requirements yet:
- player controller;
- interaction system;
- dialogue/presentation;
- game state / flags;
- day progression;
- event conditions and consequences;
- save/load;
- world-state presentation.

Each should be designed only when its gameplay requirements are understood.
