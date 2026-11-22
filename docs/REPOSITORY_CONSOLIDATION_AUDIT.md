# Giantback repository consolidation audit — 2026-11-22

## Scope and safety

Read-only audit of all current branches, pull requests, commit histories and recursive Git trees. No branch or file was deleted. No merge was forced.

## Branch inventory

| Branch | Files | Relation to main | Disposition |
|---|---:|---:|---|
| main | 8 | default | Published baseline; only a small subset of reboot |
| feat/cozy-world-visual-pass | 61 | 704 ahead, 4 behind | Recommended canonical world/reboot base; latest farm and visual work |
| feat/world-resource-harvesting | 53 | 615 ahead, 4 behind | Older harvesting implementation; superseded |
| integration/harvesting-on-cozy-world | 55 | 622 ahead, 4 behind | First integration attempt; superseded |
| integration/harvesting-on-cozy-world-v2 | 58 | 694 ahead, 4 behind | Most complete harvesting/workshop/combat integration, but based on an older cozy-world snapshot |

## Pull requests

- PR #1: cozy-world -> main; open, merge-conflicted (GitHub reports mergeable_state=dirty), 59 changed files.
- PR #4: integration v2 -> cozy-world; open, merge-conflicted (mergeable_state=dirty), 9 changed files and 74 commits.
- PR #2 and #3 are already closed historical attempts.

## Duplicate and divergence findings

Recursive tree/blob comparison across all five branches found:
- 37 paths shared by multiple branches with identical blob content. These are shared identical files across branch histories, not duplicate files inside one branch.
- 21 shared paths have different content between branches.
- Divergent implementation files include Album.client.luau, World.server.luau, HUD.client.luau, WorldVisuals.server.luau, build.py, PROJECT_SPEC.md, ROADMAP.md, README.md, validate-place workflow, asset manifest/briefs, tests and Blender scripts.
- Core OBJ/MTL assets (fox, moth, cottage, island, bridge and farm bed) have identical blobs across branches where present. No evidence of duplicate copies under alternate filenames was found in the tree comparison.
- Main's four newest commits touch only PROJECT_SPEC.md, tests/test_resource_collection_contract.py and tests/test_bridge_repair_contract.py; these overlap with larger feature branches and need semantic reconciliation.

## Critical profile schema conflict found in detailed gameplay comparison

- Current cozy-world `World.server.luau` writes `old.schemaVersion = 6` and persists the newer four-crop farm selection via `savedFarm.selectedCropId`.
- Integration V2 writes `old.schemaVersion = 10` and adds saved tools, tool levels, sword ownership, smelter queue and related island building state.
- These are not interchangeable schema labels. The merge must combine both normalizers/snapshot writers and preserve all existing keys; simply copying V2's migration block or changing the version number would risk losing farm/bridge/scout progress.
- Current `tests/test_resource_collection_contract.py` explicitly expects schema 6; V2 tests expect schema 10. Tests must be consolidated to validate the final migration path and old-profile fixtures, not merely string-replaced.
- PR #4 description has been corrected to reflect the actual divergence and required migration work. It remains Draft and unmergeable.

## Recommended consolidation order

1. Keep feat/cozy-world-visual-pass as canonical reboot/world base. It has the latest farm UI and four-crop implementation.
2. Reapply harvesting/workshop gameplay from integration v2 onto the latest cozy-world state. Do not replace the whole tree with stale v2: it is 84 commits behind current cozy-world and risks losing newer work.
3. Resolve World.server.luau, Album.client.luau and HUD.client.luau deliberately; reconcile PROJECT_SPEC.md, ROADMAP.md, tests/test_resource_collection_contract.py and .github/workflows/validate-place.yml.
4. Run full Python contract tests, Roblox place build, embedded-script validation and Studio acceptance before updating main.
5. After consolidated PR is merged and verified, close superseded PRs and delete obsolete branches only after confirming their unique commits are preserved.

## Incremental integration slice — PR #5

- Created `integration/giantback-consolidation` from the latest cozy-world HEAD.
- Imported only additive client-side harvesting feedback from V2 into `Album.client.luau`: local tool swing, hit progress/crack overlays, impact particles, final break feedback, reward pickup and optional camera shake.
- Left `World.server.luau`, `HUD.client.luau`, farm logic, profile schema and world visuals untouched. The client can display V2 `ResourceHit`/resource-state events, but the current server has not yet been ported to emit multi-hit events; the complete harvesting feature is not yet live.
- Added the consolidation branch to the push validation matrix and added it as an allowed PR target in the base workflow.
- Draft PR #5 opened against `feat/cozy-world-visual-pass`.
- Validation run #1198 on the consolidation branch passed: Python contract tests, Roblox place build, generated-place/embedded-script validation and artifact upload.
- This is a deliberately isolated client visual slice, not the complete gameplay merge and not ready to merge into `main`.

## Current status

- [x] Enumerated branches and PRs.
- [x] Compared commit divergence against main.
- [x] Compared recursive trees and blob SHAs.
- [x] Identified canonical base and integration source.
- [x] Re-ran latest cozy-world CI after adding this audit: Validate Giantback #1195 PASS; Fox Hero visual acceptance #314 PASS; Lunar Moth visual review #95 PASS.
- [x] Confirmed integration v2 validation run #1182 PASS (183 contract tests, place build and embedded-script checks as recorded in PR #4).
- [ ] Reapply integration v2 gameplay onto latest cozy-world.
- [ ] Resolve conflicts and merge consolidated result into main.
- [ ] Remove obsolete branches after verifying all unique work is preserved.

## Why merge/deletion was not forced

Both open PRs currently report dirty merge states. The audit commit and latest cozy-world branch checks are green (#1195, #314, #95). Integration v2's own CI run #1182 is also green, but a passing branch build does not resolve its 85-commit divergence or shared-file conflicts. Integration v2 is materially behind the current cozy-world branch, and shared gameplay files diverged. Blind merging or branch deletion could discard newer farm/world work or the only copy of gameplay changes. The safe next action is a conflict-resolved integration commit followed by CI, not force-merging or deleting refs.


## Follow-up audit — 2026-11-22 16:07 UTC+3

This section supersedes the earlier branch/PR counts above where they differ. The historical findings are retained for traceability.

### Current branch inventory

The repository currently has seven branches besides `main`:

- `feat/cozy-world-visual-pass`
- `feat/harvesting-feedback-on-latest`
- `feat/world-resource-harvesting`
- `feat/combat-c0-contract`
- `integration/harvesting-on-cozy-world`
- `integration/harvesting-on-cozy-world-v2`
- `integration/giantback-consolidation`

### Current PR and validation snapshot

- PR #7, `Giantback C1 — combat, Rootvault expedition and Seal Keeper boss`, remains Draft and targets `feat/cozy-world-visual-pass`.
- PR #7 describes the consolidated combat/expedition slice: server-authoritative combat, telegraphed attacks, block/dodge, persistent first-clear rewards, the Rootvault rooms/traps/chests, three boss phases, minions and client-only procedural pose/VFX layers.
- Latest validation recorded in PR #7: 222 Python contract tests PASS; Roblox place generation PASS; generated-place validation reports 71 named instances and 6 embedded scripts. This is automated validation only, not Roblox Studio acceptance.
- PR #1 remains open as the original reboot PR. No merged PRs were returned by the current merged-PR search. `main` has not been changed by this follow-up.

### Fresh divergence check

Comparing `integration/giantback-consolidation` with `feat/cozy-world-visual-pass` now reports a diverged history: integration has 49 commits not in the feature branch, while the feature branch has 3 commits not in integration. The comparison identifies changes in `World.server.luau`, `HUD.client.luau`, `Album.client.luau`, `ROADMAP.md`, `PROJECT_SPEC.md`, validation workflow, tests and repository docs. This is not a fast-forward and must not be resolved by force-pushing either branch.

Other old harvesting branches also diverge substantially from the current cozy-world branch; `feat/combat-c0-contract` is particularly stale. Their unique commits must be reviewed before any deletion.

### Updated safe disposition

1. Keep `feat/cozy-world-visual-pass` as the canonical product baseline.
2. Treat the PR #7 integration head as the active consolidated gameplay candidate; inspect its exact base/head and conflict status before merging.
3. Reconcile the three commits unique to the canonical base with the 49 integration commits, preserving the latest farm/profile work and the combat/Rootvault implementation.
4. Re-run CI after reconciliation; require Roblox Studio acceptance for combat, multiplayer rewards, boss phases, mobile/gamepad controls and reconnect persistence.
5. Only after the consolidated result is accepted and merged, close superseded PRs and delete old branches after confirming every unique change is preserved.

No branch was deleted, no force push was performed, and `main` was not modified during this follow-up.
