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


## Main-only history reconciliation — 2026-11-22

The four commits present only on `main` were reviewed:

- `c7bd076` and `ee9bfb3`: added `PROJECT_SPEC.md` and a resource collection contract test.
- `56436f2`: removed a misplaced bridge contract test from `main`.
- `c862381`: added tests for personal wood/stone gathering and first bridge repair.

The two files from those commits already exist in the canonical development line and are more advanced there:
- Canonical `PROJECT_SPEC.md` includes the harvesting 2.0 and Ironworking 1.0 implementation status sections absent from the main version.
- Canonical `tests/test_resource_collection_contract.py` contains the newer schema-9 monotonic-migration checks, tool respawn/equipment checks, server-limited multi-hit gathering, client feedback, iron ore and persistent smelter checks. The main-only test file is an older schema-8 contract and lacks these later guarantees.

Decision: these four main-only commits are **functionally superseded**, not missing work. Do not merge the older files over canonical. Their useful requirements (personal gathering and bridge repair) are represented in the current specification/tests and current world implementation. Preserve the commit history on `main` until release reconciliation; no force-push or blind merge is justified.

## Latest CI status

- PR #1 (reboot base): automated place validation and visual-review jobs passed; remains Draft and is not mergeable against historical `main`.
- PR #4 is closed as an archive/migration reference; its V2 branch remains available for selective city/sword/progression migration. Do not merge the divergent branch wholesale.
- PR #6 was closed without merging because its complete changes are included in consolidated PR #7.
- PR #7 now targets `feat/cozy-world-visual-pass` directly and contains harvesting feedback plus Combat C0. Its automated contract tests and generated-place validation passed.
- Roblox Studio acceptance remains outstanding for harvesting interaction and combat setup.



## Canonical branch and PR audit — 2026-11-22 (latest)

Canonical development remains `feat/cozy-world-visual-pass`. It is the source of truth for active work; `main` remains the eventual release line and is not a safe merge target yet.

### Consolidated PR #7

- PR #7 (`feat/combat-c0-contract` → `feat/cozy-world-visual-pass`) is open, Draft, and now reports `mergeable=true` / `mergeable_state=clean`.
- Latest head: `2aa259738c00953efe19f7a4fa08a989126b2c08`.
- Latest GitHub Actions run #45009463762 completed successfully: 189 contract tests, Roblox place build, embedded-script validation and artifact upload.
- The PR combines harvesting presentation feedback with the dedicated server-owned Combat C0 request protocol and its tests. C0 is intentionally non-playable: no damage, enemy health mutation or reward granting.
- Keep PR #7 Draft until Roblox Studio acceptance covers R6/R15 tool animation, hit alignment, resource break/regrowth, local-only feedback, mobile readability and multiplayer. Do not merge based on CI alone.

### Current branch divergence against canonical

The following figures are from GitHub compare against `feat/cozy-world-visual-pass`:

| Branch | Ahead | Behind | Decision |
|---|---:|---:|---|
| `feat/harvesting-feedback-on-latest` | 7 | 9 | PR #6 is closed/superseded by PR #7; retain as recovery ref until PR #7 is accepted |
| `feat/world-resource-harvesting` | 68 | 206 | PR #2 is closed; historical harvesting source, do not merge wholesale |
| `integration/giantback-consolidation` | 3 | 46 | PR #5 is closed; historical integration snapshot |
| `integration/harvesting-on-cozy-world` | 9 | 140 | PR #3 is closed; historical integration snapshot |
| `integration/harvesting-on-cozy-world-v2` | 74 | 133 | PR #4 is closed archive; preserve V2 city/sword/progression as selective migration source |
| `main` | 4 | 753 | release history; canonical is far ahead and must not be force-synced |

### Cleanup decision

- Active development branches: only `feat/cozy-world-visual-pass` and the short-lived PR #7 head `feat/combat-c0-contract`.
- PRs #2–#6 are closed. PR #1 remains a Draft release PR to historical `main`; it is not ready to merge.
- The old refs are not active development lines. They remain recovery/archive refs until their unique commits have been verified as preserved or deliberately archived.
- No branch was deleted and no history was rewritten during this audit. The connected GitHub actions available in this session support branch listing/comparison and file/PR updates, but do not expose a branch-ref deletion operation. Do not claim the refs were removed.
- Do not merge any of the divergent integration branches wholesale. Port only a reviewed unique feature onto the canonical branch, then run CI and Studio acceptance.


### C0 remote argument validation hardening

A code review found that the original callback accepted only a single named optional payload. Roblox RemoteEvent can forward more than one trailing argument, and Lua would silently discard arguments beyond the named parameter. The callback now captures all trailing arguments and rejects any argument count above zero, including explicit nil. A regression contract test covers this case. CI is rerun on the updated PR head.


### C1 combat implementation staged in PR #7

- Added a server-authoritative sword attack hitbox, target registry, enemy telegraph/approach loop, block and dodge handling.
- Added PC, gamepad and touch input bindings through `Combat.client.luau`.
- Added profile schema v10 idempotent reward ledger for `GroveGrunt01`.
- CI is being rerun. Studio still needs one tagged combat region and one tagged enemy rig before gameplay acceptance.


## PR #7 follow-up — C1 and Rootvault checkpoint (2026-11-22)

This section supersedes the earlier PR #7/C1 status above.

### Git ancestry verified

GitHub compare confirms `feat/combat-c0-contract` is a strict fast-forward descendant of `feat/cozy-world-visual-pass`:

- Canonical base SHA: `865c93ef84f1d59f2a808b81ee76b0ae883235bb`.
- PR head SHA validated by Actions: `14b8b8585f0d06600d0269696bf508e3e2a241f1`.
- 173 commits ahead, 0 behind; merge base equals canonical base.
- Therefore PR #7 does not require cherry-picking or history reconciliation before merge. The previous description of this branch as stale/diverged was incorrect for this exact current ref comparison.

### Current PR #7 scope

The PR now contains the C1 combat loop, generated Grove training glade and enemy archetypes, per-contributor first-clear rewards, Forest Trial rune puzzle, Rootvault traversal/key gate, three Rootvault enemies and Seal Keeper three-phase boss with ground slam and minion activation. It also includes client-side combat input, feedback, enemy health display and procedural pose/VFX layers.

### Latest automated validation

- GitHub Actions run `45021490760` completed successfully.
- Job `build-and-validate`: all steps completed with conclusion `success`.
- PR description records 222 Python contract tests passing, Roblox place generation passing, and generated-place validation passing (71 named instances, 6 embedded scripts).
- Artifact `Giantback-visual-build` exists, is not expired, and is associated with head SHA `14b8b8585f0d06600d0269696bf508e3e2a241f1`.

### Remaining release gates

PR #7 remains Draft because the following cannot be proven by source contracts or generated-place CI:

- Roblox Studio playtest of the generated training glade, all NPC navigation and hitbox alignment.
- Co-op reward isolation and DataStore persistence through reconnects.
- Rootvault room traversal, pressure traps, lever/door state, key/sigil/chest progression.
- Boss phase transitions, ground slam warning, minion activation and health UI on PC/mobile/gamepad.
- Authored animation clips, final boss transformation, impact audio and final balance.

Keep `feat/cozy-world-visual-pass` as canonical baseline and PR #7 as its linear integration candidate. Do not merge to `main` or mark PR ready until Studio acceptance is recorded. No branch was deleted and no history was rewritten.


## Follow-up verification — 2026-11-22 (reward hardening + branch matrix)

### Combat reward reliability

- Added bounded retry (up to five attempts with exponential backoff) around the server-owned reward callback.
- The profile reward callback now treats an already-persisted encounter completion as successful idempotent delivery; failed saves still roll back the in-session grant and allow retry.
- Added two contract tests for retry/backoff/disconnect handling and duplicate-delivery semantics.
- Updated `ROADMAP.md` and `docs/COMBAT_SYSTEM_1.0.md` to describe the full staged C1/Rootvault scope and remaining Studio gates.
- The last confirmed CI result remains run `45021490760` on the earlier 222-test head. The two new tests and subsequent documentation/code commits have not yet been confirmed by a fresh Actions run; do not report the current head as CI-green.

### Current branch comparison

Compared each remaining branch against `feat/cozy-world-visual-pass` after the latest PR #7 commits:

| Branch | Ahead | Behind | Handling |
|---|---:|---:|---|
| `feat/combat-c0-contract` | 179 | 0 | Active linear PR #7 integration candidate |
| `feat/harvesting-feedback-on-latest` | 7 | 12 | Superseded recovery branch; do not merge wholesale |
| `feat/world-resource-harvesting` | 68 | 209 | Historical source; do not merge wholesale |
| `integration/giantback-consolidation` | 4 | 49 | Historical integration snapshot |
| `integration/harvesting-on-cozy-world` | 9 | 143 | Historical integration snapshot |
| `integration/harvesting-on-cozy-world-v2` | 74 | 136 | Archive/recovery source for selective migration only |
| `main` | 4 | 756 | Release branch; not a safe target for syncing this development line |

The PR #7 head is now 179 commits ahead and zero behind the canonical development base, so it remains a fast-forward integration candidate. The six other refs are divergent and must not be merged or deleted before their unique content is explicitly inventoried. No branch deletion capability is exposed in the connected GitHub actions used here; no branch was deleted and no history was rewritten.


### Enemy rig compatibility follow-up

A source review of the client animation binder found that it only recognized R6 Motor6D names with spaces (for example `Right Shoulder`). Standard R15 rigs use compact names (for example `RightShoulder`), so those rigs could silently skip the procedural animation layer. The binder now normalizes joint names by lowercasing and removing whitespace, and uses canonical shoulder/hip/root/neck keys. Added a contract test and generated-place workflow markers for this compatibility path. Actual R6/R15 pose quality still requires Studio review.

Latest PR #7 head after this fix is a linear descendant of the canonical base; automated CI for the new commits is not yet confirmed by the available commit-run lookup. Keep the PR Draft and do not merge until current CI and Studio acceptance are recorded.


### R15 torso-chain follow-up

A second compatibility pass found that R15 rigs use `Root` and `Waist`, whereas the initial alias fix only normalized the R6 `RootJoint` name. The procedural animator now resolves `RootJoint` or `Root` and applies the corresponding subtle torso pose to `Waist` when present. Contract coverage and generated-place markers were extended. The PR remains Draft pending current CI and Studio acceptance.


### Charged sword attack follow-up

Added a server-timed hold/release sword attack. The server owns charge start time and computes damage (30–52) from a 0.45–1.6s valid charge; clients cannot submit duration, damage or target. The action is mapped to keyboard R, gamepad ButtonX and a touch hold control. Abandoned charges expire after four seconds; block/dodge/respawn and normal attacks cannot preserve or bypass the charge. Stronger impact push is reduced against bosses. Three contract tests and generated-place markers cover the server rules, client mappings and cancellation behavior.

The current changes are committed to the linear PR #7 candidate branch. Fresh GitHub Actions results and Roblox Studio acceptance are still required; touch hold semantics and physical tuning remain unverified in Studio.


### Fox / Moth combat companion ability slice

Added a first server-authoritative combat ability for each currently implemented companion. Fox selects the nearest living registered enemy in the player's current combat region within 18 studs and deals 24 damage; Moth heals ready allies in the same region within 14 studs for up to 18 HP each. Both require the matching owned-and-equipped companion, share a 14-second per-player cooldown that survives character respawns, and cannot be used while blocking or charging. Keyboard C, gamepad ButtonY and touch controls map to one payload-free server action. Added contract coverage for ownership, region boundaries, reward contribution, healing cap, cooldown persistence, input mapping and rejection feedback. Updated product spec, combat spec and roadmap.

The branch remains a linear descendant of the canonical baseline. CI and Roblox Studio acceptance must still confirm the current head; specifically verify live pet equip state, co-op healing boundaries, and mobile touch layout.


### Companion combat presentation follow-up

The first combat abilities now have server-confirmed local presentation. Fox's success payload carries the server-selected enemy ID; the client resolves the registered enemy and shows an amber spark burst plus a short ground pulse. Moth's success payload carries only user IDs actually healed by the server; the client shows violet/lunar pulses on those allies. These local effects are presentation-only and cannot deal damage, heal, or grant rewards. Contract tests cover payload provenance, enemy resolution, ally lookup and the visual hooks.

Latest validated head before this audit note: GitHub Actions #1641 — 236 Python contract tests PASS, Roblox place build PASS, generated-place validation PASS (71 named instances, 6 embedded scripts), artifact upload PASS. Studio playtesting remains required.


## Live branch re-audit — 2026-11-22 17:50 UTC

This section supersedes the older branch-count and ahead/behind snapshots above. Values were re-read from GitHub compare against the canonical development base `feat/cozy-world-visual-pass`.

| Branch | Ahead | Behind | Current handling |
|---|---:|---:|---|
| `feat/combat-c0-contract` | 317 | 0 | Active PR #7 integration candidate; strict fast-forward descendant |
| `feat/harvesting-feedback-on-latest` | 7 | 12 | Superseded recovery ref; do not merge wholesale |
| `feat/world-resource-harvesting` | 68 | 209 | Historical harvesting source; do not merge wholesale |
| `integration/giantback-consolidation` | 4 | 49 | Historical snapshot; do not merge wholesale |
| `integration/harvesting-on-cozy-world` | 9 | 143 | Historical snapshot; do not merge wholesale |
| `integration/harvesting-on-cozy-world-v2` | 74 | 136 | Archive/recovery source; only selectively port reviewed unique features |
| `main` | 4 | 756 | Stable/release line; do not force-sync or merge the development branch yet |

Repository currently exposes eight branches total: the seven refs above plus the canonical `feat/cozy-world-visual-pass`. No extra integration branch is needed. In particular, `integration/giantback-consolidation` is not the active integration line: it is 4 commits ahead and 49 behind canonical, so it must not receive current work or be treated as the merge target.

### Current PR and validation

- PR #7 remains the sole active gameplay integration PR: `feat/combat-c0-contract` → `feat/cozy-world-visual-pass`.
- PR #7 remains Draft. Its latest recorded validation is Actions run #1795: 267 Python contract tests PASS, Roblox place build PASS, generated-place validation PASS (71 named instances, 6 embedded scripts), artifact upload PASS.
- This validation proves source contracts and place generation only. Roblox Studio multiplayer, DataStore reconnect, PC/mobile/gamepad acceptance, animation quality and balance remain manual release gates.
- `main` was not modified by this audit. No branch was deleted and no history was rewritten.

### Safe next consolidation procedure

1. Keep all new gameplay work on the PR #7 head branch; keep `feat/cozy-world-visual-pass` as its base.
2. Keep the six divergent historical refs read-only until each unique feature has a named disposition and preservation evidence.
3. Do not merge `integration/giantback-consolidation` or either harvesting integration branch wholesale.
4. After Studio acceptance and release review, merge PR #7 into the canonical development base; only then prepare a separate, tested release integration into `main`.
5. Branch deletion is not performed by the available connected GitHub operations in this session; do not report cleanup as complete until refs are actually deleted through an authorized GitHub operation.


## Branch and CI cleanup follow-up — 2026-11-22 16:33 UTC

### Live state after workflow cleanup

- Canonical development branch: `feat/cozy-world-visual-pass`.
- Active integration branch: `feat/combat-c0-contract`, PR #7 targets the canonical branch.
- Release branch: `main`; PR #1 remains Draft and must not be merged before 1.0 acceptance.
- Current branch inventory remains eight refs total. No ref was deleted and no history was rewritten.
- PR #7 is still Draft and GitHub reports it mergeable, but it remains unmerged pending Studio acceptance.

### Duplicate Actions trigger reduction

Updated `.github/workflows/validate-place.yml` on both the canonical branch and PR #7 head:
- `push` now runs only for `main` and `feat/cozy-world-visual-pass`.
- `pull_request` now runs only when targeting `main` or `feat/cozy-world-visual-pass`.
- Feature-branch commits with an open PR are therefore validated by the PR event instead of also launching a duplicate push run.
- Historical integration branches were removed from the trigger list.

Validation after this change:
- Canonical push run #2043: PASS (contract tests, place build, generated-place validation, artifact upload).
- PR #7 run #2044: all validation steps reported success; final run completion was still pending at the time of this note.
- Previous PR #7 head run #2042: PASS.

### Branch tree comparison against active PR head

A recursive tree comparison found no file paths that exist only on any of the five historical refs below and are absent from `feat/combat-c0-contract`. This does **not** prove that their older file contents are identical: several branches still have divergent blobs for gameplay, UI, build, tests, asset briefs and workflow files.

| Historical ref | Relation to active PR head | Current disposition |
|---|---|---|
| `feat/harvesting-feedback-on-latest` | Active PR head is a descendant; no branch-only paths | Superseded recovery ref; candidate for deletion after backup |
| `feat/world-resource-harvesting` | Diverged; 68 branch-only commits | Historical source; preserve until semantic diff is signed off |
| `integration/giantback-consolidation` | Diverged; 4 branch-only commits | Historical snapshot; do not merge wholesale |
| `integration/harvesting-on-cozy-world` | Diverged; 9 branch-only commits | Historical snapshot; preserve until semantic diff is signed off |
| `integration/harvesting-on-cozy-world-v2` | Diverged; 74 branch-only commits | Archive/recovery source; preserve until semantic diff is signed off |

The active PR head is currently 464 commits ahead and 1 commit behind the canonical branch because the workflow trigger cleanup was committed independently to both refs. The workflow contents are aligned. Do not force-reset either ref; if GitHub offers a normal update-branch operation, use it and rerun PR validation.

### Remaining cleanup gates

- [x] Reduce duplicate feature push + PR validation triggers.
- [x] Confirm the latest canonical validation after the trigger edit.
- [x] Confirm PR #7 validation steps after the trigger edit.
- [ ] Complete semantic review of divergent historical file blobs, especially `World.server.luau`, `Album.client.luau`, `HUD.client.luau`, `build.py` and tests.
- [ ] Create an explicit recovery backup before deleting any historical ref.
- [ ] Delete superseded refs through an authorized GitHub branch-delete operation. The connected GitHub actions available in this session expose no branch-delete operation; deletion has not been performed.
- [ ] Keep PR #7 Draft until Roblox Studio multiplayer, save/rejoin, PC/mobile/gamepad and animation acceptance is complete.
- [ ] Keep PR #1 Draft until the 1.0 release checklist is accepted.
