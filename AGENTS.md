# LifeInRussia — Codex Instructions

## Project
- Engine: Godot 4.x
- Language: GDScript
- Repository: LifeInRussia
- Game type: small 3D narrative/simulation game with day-to-day consequences and branching world states.

## Working rules
- Never commit directly to `main`.
- Work only on the task explicitly requested.
- Do not refactor unrelated systems.
- Keep scenes small, modular and reusable.
- Avoid monolithic scripts and giant scenes.
- Prefer composition over deep inheritance.
- Separate gameplay/state logic from presentation when practical.
- Do not hardcode large amounts of dialogue, events or day content into NPC scripts.
- Prefer data-driven content for dialogue, events and day-specific changes.
- Do not add addons, plugins or external dependencies unless explicitly requested.
- Preserve existing project conventions unless a task explicitly changes them.
- Keep file/folder names in lowercase snake_case where practical.
- Use clear, descriptive node and script names.
- Do not modify `project.godot` unless the task requires project settings.
- Before finishing, check for GDScript parser errors and obvious broken references.
- If a task is ambiguous, prefer the smallest safe implementation rather than inventing new systems.

## Git workflow
- Branch naming: `feature/...`, `fix/...`, `content/...`, `chore/...`.
- One task should normally map to one branch / pull request.
- Keep commits focused.
- Do not mix unrelated cleanup with feature work.

## Documentation
Read relevant files in `docs/` before implementing systems. Update documentation when a task materially changes architecture or workflow.
