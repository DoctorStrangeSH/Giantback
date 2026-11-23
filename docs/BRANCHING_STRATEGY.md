# Giantback branch policy

## One canonical development line

The only long-lived development branch is `feat/cozy-world-visual-pass`. `main` is the release branch and receives only a tested, accepted 1.0 release.

Routine work is committed directly to the canonical line. Do not create another feature or integration branch for small follow-up tasks. A short-lived branch is allowed only when a change is genuinely isolated and its PR targets the canonical branch.

## Current staged PRs

- PR #7 — consolidated harvesting feedback + Combat C0 integration directly into the canonical branch. Keep Draft until Roblox Studio acceptance.
- PR #6 — closed as superseded by PR #7; its commits remain in PR #7's head history.
- PR #4 — closed archive reference for V2 city/sword/progression features; selectively port only after profile migration design.
- PR #1 — eventual release PR to `main`; do not merge while the 1.0 acceptance checklist is incomplete.

PRs #2, #3, #4, #5 and #6 are closed and superseded or archived. Their branches are recovery references, not active development lines.

## Rules

1. Never merge a branch solely because its name says integration.
2. Before any merge, inspect ahead/behind counts, changed files, profile schema and unique gameplay systems.
3. Never downgrade profile schema or overwrite newer saved fields.
4. One gameplay system has one canonical implementation. Port unique behavior, not whole divergent files.
5. Every integration must pass contract tests, place build and embedded-script validation.
6. Roblox Studio acceptance is a separate required gate for gameplay behavior; CI alone does not prove the game works in Studio.
7. Keep the branch count low. Do not open a new PR to fix a PR that can be amended safely.
8. Delete superseded branch refs only after their unique changes are preserved and a recovery point is no longer needed.
