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


## Fresh-base harvesting feedback port — PR #6 (2026-11-22)

- The canonical `feat/cozy-world-visual-pass` advanced after the first consolidation branch was cut. The old `integration/giantback-consolidation` head is now 37 commits behind that canonical branch and must not be merged as-is.
- Rechecked the canonical server implementation: it already contains persistent Axe/Pickaxe ownership and levels, server-validated equipped tools, multi-hit wood/stone/iron harvesting, personal cooldowns, workbench upgrades, and persisted personal smelting. The old audit note saying the server protocol still needed to be ported is superseded by the current canonical branch and ROADMAP.
- Reapplied the client-only harvesting presentation onto a fresh branch from the latest canonical HEAD: `feat/harvesting-feedback-on-latest`.
- PR #6 changes only `Album.client.luau`, `ROADMAP.md`, and the validation workflow. It adds local swing, hit cracks/progress, impact particles, reward pickup, final break and regrowth feedback; no server/profile/farm/pet/island implementation is replaced.
- Added the new branch to push validation and the canonical branch as a PR validation target. GitHub Actions run #45007978624 passed: gameplay/world contract tests, Roblox place build, generated-place/embedded-script validation and artifact upload.
- PR #6 remains Draft pending Roblox Studio acceptance (R6/R15 animation, impact alignment, resource break/regrowth, local-only behavior and mobile readability). It is not merged to `main`.
- PR #5 is superseded by this fresh-base port. Keep the old integration branch until PR #6 is merged and all remaining unique audit/history content is confirmed preserved.


## Full branch inventory and consolidation decision — 2026-11-22

There are exactly seven non-`main` branches at the time of this audit:

| Branch | Role | Decision |
|---|---|---|
| `feat/cozy-world-visual-pass` | Current reboot/world base; PR #1 to `main` | **Canonical development line**. Do not replace it with an old integration branch. |
| `feat/harvesting-feedback-on-latest` | Fresh-base harvesting feedback, PR #6 | Keep as a staged change until Studio acceptance; then integrate into canonical. |
| `feat/combat-c0-contract` | Combat C0, PR #7 stacked on PR #6 | Keep as a staged change; integrate after #6 and CI verification. |
| `integration/harvesting-on-cozy-world-v2` | Older, divergent harvesting/city/economy implementation, PR #4 | **Preserve as migration source**. Not safe to merge wholesale. |
| `feat/world-resource-harvesting` | Earlier harvesting implementation, schema 8, PR #2 closed | Superseded as an active line by V2; retain until V2 feature inventory is migrated. |
| `integration/harvesting-on-cozy-world` | Earlier integration attempt, PR #3 closed | Superseded by V2; retain only as temporary recovery history. |
| `integration/giantback-consolidation` | Stale PR #5 source, 37 commits behind canonical | Superseded by the fresh-base PR #6; do not merge wholesale. |

### Important compatibility finding

The V2 branch is not just another copy of harvesting. Its `World.server.luau` has schema 10, sword ownership/equipment, level-3 tool progression, a city-building smelter and additional resource/building state. The canonical branch has schema 9, level-2 tool progression and a personal home smelter. These are competing implementations with different profile shapes and gameplay assumptions.

Therefore:
- Do not delete or merge V2 until its unique city/sword/progression features are explicitly ported or deliberately removed from the 1.0 scope.
- The older schema-8 harvesting branch is not a merge target; V2 is the richer migration source for those overlapping systems.
- The old consolidation branch is superseded by PR #6's fresh-base client feedback port.
- PR #2, #3 and #5 are already closed. PR #1 remains the eventual release PR; PR #6 and #7 are staged feature PRs; PR #4 is the outstanding legacy feature source.

### Single-line development policy

- Canonical branch: `feat/cozy-world-visual-pass`.
- No new parallel feature branches for routine work.
- Keep PR #6 and #7 staged until acceptance, then integrate sequentially into the canonical branch.
- Port selected V2 features into the canonical line as small, tested changes; never merge its 74-commit divergent history wholesale.
- `main` is release-only. Do not attempt the 744-commit divergence as a blind merge; first reconcile the four main-only commits and the canonical release history.
- The second AI is working on a different project; no Giantback two-agent file ownership or conflict protocol is required.

### Branch deletion limitation

The connected GitHub capability available for this session can inspect refs, create/update refs and manage PRs, but does not expose a branch-delete operation. Superseded branch refs must therefore remain as recovery points until they can be deleted through GitHub's branch UI or a connection with repository ref-deletion permission. Do not simulate deletion by force-moving a branch.
