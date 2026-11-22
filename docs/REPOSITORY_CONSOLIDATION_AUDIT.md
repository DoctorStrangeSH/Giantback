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

## Forward-compatible profile safety patch — 2026-11-22

- The current schema-v6 save path previously assigned `old.schemaVersion = 6` unconditionally. That could downgrade a profile previously written by the V2 schema-v10 branch.
- Updated the write to `math.max(tonumber(old.schemaVersion) or 0, 6)`, preserving a newer version marker rather than decreasing it.
- Added `IronOre` and `IronIngot` to the current inventory key registry so these V2 inventory values are loaded, exposed to attributes, and included in the existing inventory snapshot rather than being omitted.
- Added regression assertions in resource collection tests; updated fox-scout and farm schema tests for monotonic schema versioning.
- Updated generated-place workflow marker to assert the new forward-compatible schema expression.
- CI run #1204: contract tests and Roblox place build passed, but generated-place marker validation failed because the workflow still expected the old literal schema-v6 assignment. That stale marker has now been corrected in commit `bc95193`; a fresh run is required before marking this patch green.
- This is a preservation patch only. It does not yet implement V2 tools, resource hit state, smelting or combat.

## Recommended consolidation order

1. Keep feat/cozy-world-visual-pass as canonical reboot/world base. It has the latest farm UI and four-crop implementation.
2. Reapply harvesting/workshop gameplay from integration v2 onto the latest cozy-world state. Do not replace the whole tree with stale v2: it is 84 commits behind current cozy-world and risks losing newer work.
3. Resolve World.server.luau, Album.client.luau and HUD.client.luau deliberately; reconcile PROJECT_SPEC.md, ROADMAP.md, tests/test_resource_collection_contract.py and .github/workflows/validate-place.yml.
4. Run full Python contract tests, Roblox place build, embedded-script validation and Studio acceptance before updating main.
5. After consolidated PR is merged and verified, close superseded PRs and delete obsolete branches only after confirming their unique commits are preserved.

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
