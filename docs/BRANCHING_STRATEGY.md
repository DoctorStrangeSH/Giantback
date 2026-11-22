# Giantback branch policy

## One canonical development line

The only long-lived development branch is `feat/cozy-world-visual-pass`. `main` is the release branch and receives only a tested, accepted 1.0 release.

Routine work is committed directly to the canonical line. Do not create another feature or integration branch for small follow-up tasks. A short-lived branch is allowed only when a change is genuinely isolated and its PR targets the canonical branch.

## Current staged PRs

- PR #6 — harvesting feedback. Keep staged until Roblox Studio acceptance; then integrate into the canonical branch.
- PR #7 — Combat C0, currently stacked on PR #6. Rebase/retarget only after #6 is integrated and rerun CI.
- PR #4 — legacy V2 migration source. It is not an integration candidate as a whole; selectively port city/sword/progression features after profile migration design.
- PR #1 — eventual release PR to `main`; do not merge while the 1.0 acceptance checklist is incomplete.

PRs #2, #3 and #5 are closed and superseded. Their branches are recovery references, not active development lines.

## Rules

1. Never merge a branch solely because its name says integration.
2. Before any merge, inspect ahead/behind counts, changed files, profile schema and unique gameplay systems.
3. Never downgrade profile schema or overwrite newer saved fields.
4. One gameplay system has one canonical implementation. Port unique behavior, not whole divergent files.
5. Every integration must pass contract tests, place build and embedded-script validation.
6. Roblox Studio acceptance is a separate required gate for gameplay behavior; CI alone does not prove the game works in Studio.
7. Keep the branch count low. Do not open a new PR to fix a PR that can be amended safely.
8. Delete superseded branch refs only after their unique changes are preserved and a recovery point is no longer needed.
