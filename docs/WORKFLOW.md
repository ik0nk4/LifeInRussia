# Workflow

## Branches
`main` must stay playable and reviewable.

Use short-lived branches:
- `feature/...` — gameplay or technical features
- `fix/...` — bug fixes
- `content/...` — scenes, dialogue, level/content work
- `chore/...` — repository/tooling/maintenance

Examples:
- `feature/player-controller`
- `feature/interaction-system`
- `content/day-1-neighbor`
- `fix/door-collision`

## Daily flow
1. Pull the latest `main`.
2. Pick one small task.
3. Create a branch from `main`.
4. Implement only that task.
5. Run the project and verify the changed flow.
6. Commit with a clear message.
7. Open a pull request to `main`.
8. The other developer reviews/tests it.
9. Merge when it works.
10. Delete the branch after merge.

## Working with Codex
Give Codex a narrow task with acceptance criteria.

Good:
> Implement a basic interactable component for NPCs. The player should detect one nearby interactable and emit an interaction event. Do not implement dialogue yet.

Bad:
> Make the NPC system.

Codex should work in a dedicated task branch and follow `AGENTS.md`.

## Avoiding merge conflicts
- Do not edit the same large `.tscn` scene at the same time.
- Assign ownership of a scene while someone is actively changing it.
- Split the world into smaller scenes and instantiate them.
- Prefer separate resources/data files instead of embedding everything into one scene.
- Before starting work, pull/rebase from current `main`.

## Pull requests
A PR should answer:
- What changed?
- How can it be tested?
- Does it change architecture/data format?
- Are there known limitations?

Keep PRs small enough to understand in a few minutes.

## Commits
Suggested prefixes:
- `feat:`
- `fix:`
- `content:`
- `docs:`
- `chore:`

Examples:
- `feat: add player interaction raycast`
- `content: add apartment hallway blockout`
- `fix: prevent interaction through walls`
