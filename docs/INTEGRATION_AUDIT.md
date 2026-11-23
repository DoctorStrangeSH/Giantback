# Giantback — integration audit (2026-11-23)

Source of truth: `PROJECT_SPEC.md`. Integration target: `main`. Working candidate: `feat/combat-c0-contract` ([PR #8](https://github.com/DoctorStrangeSH/Giantback/pull/8)).

## Verified repository state

- Before PR #8, `main` used the legacy `build.py` with the moving Mossback. **PR #8 merged on 2026-11-23** (`2b397d8ebfbe5ff4775e8743b182c770c8df43b9`), so `main` now contains the reboot source tree. Studio playtest is not yet verified.
- Initially, the candidate branch was 1416 commits ahead and 6 behind `main`, with 120 changed files.
- **Resolved 2026-11-23:** two-parent merge commit `dbf583b931fa7c208cacb122970c658eb96613e8` preserves both `main` and the gameplay branch. The candidate now has 0 commits behind `main` and PR #8 was successfully merged.
- Resolution retains the newer reboot specification and the refactored resource collection contract, rather than copying the older `main` variants; the old companion growth test removed from `main` is not restored—the newer modular contract on the feature branch remains. CI and Studio acceptance are still required.
- Branch count: seven non-main branches.

## Branch delta compared with candidate

These figures represent GitHub's compare endpoint at audit time; `ahead` is not equivalent to valuable features, and `behind` is not proof that changes were ported identically.

| Branch | Ahead | Behind | Action |
| --- | ---: | ---: | --- |
| `feat/harvesting-feedback-on-latest` | 0 | 665 | Ancestor; candidate contains its commit history |
| `feat/cozy-world-visual-pass` | 0 | 646 | Ancestor; candidate contains its commit history |
| `feat/world-resource-harvesting` | 68 | 869 | Inspect its 68 unique commits/diff before retiring |
| `integration/giantback-consolidation` | 4 | 709 | Inspect four unique commits/diff |
| `integration/harvesting-on-cozy-world` | 9 | 803 | Inspect nine unique commits/diff |
| `integration/harvesting-on-cozy-world-v2` | 74 | 796 | Inspect 74 unique commits/diff; not safe to delete |

## Integration quality gate

- [x] Reconcile `main`'s six commits and resolve PR merge conflicts without rewriting either history (merge commit `dbf583b`).
- [ ] Review unique commits of the four diverged branches and port only missing, tested functionality.
- [x] Validate Giantback place CI runs #2210 and #2211 succeeded for the reconciliation merge; build / contract automation passed. This does not validate Studio runtime.
- [ ] Verify Roblox Studio runtime, script warnings and asset imports in Edit/Play.
- [ ] Studio Play: spawn on owned island, gather resources, repair bridge, discover Fox, follow scent trail, obtain MoonSeed, rejoin and verify persistence.
- [ ] Studio Play: equip Moth, reveal MoonBloom and verify server-owned personal reward.
- [ ] Two-player Studio Play: permissions, individual resource cooldowns and pet discoveries.
- [ ] Mobile and gamepad checks; confirm single readable primary goal and no overlapping modal windows.
- [ ] Artistic approval for imported MeshPart assets; do not delete working blockouts until their replacements are demonstrated in Studio.
- [x] Update `README.md` with the merged mainline status.
- [ ] Reconcile `ROADMAP.md` statuses with Studio-verified scope before release.

**Never mark 1.0 DONE from CI alone.** The user must be able to launch the integrated place in Roblox Studio and test each new gameplay slice.

## Post-merge source reconciliation — 2026-11-23

- Verified against `main` after PR #8: `World.server.luau` does not contain `Mossling`, `SwordOfTheWanderer`, or `TrainingDummy`; `HUD.client.luau` does not contain those identifiers either. These V2 features must **not** be marked integrated.
- Verified `Album.client.luau` requires the `HarvestMotion` and `ResourceNodeVisibility` modules and `build.py` embeds both modules. Harvest feedback refactoring is in the main build path.
- Verified schema writer uses `math.max(tonumber(old.schemaVersion) or 0, 11)`; do not downgrade this when porting older V2 logic.
- GitHub compare after PR #8: `feat/combat-c0-contract`, `feat/cozy-world-visual-pass`, and `feat/harvesting-feedback-on-latest` are ancestors of `main`. Other four refs have unique history and must not be bulk-merged.
- Priority recovery order: Sword recipe/equipment + training dummy; Mossling opponent; tier-three tools; optional V2 harvest presentation only if missing. Each must be ported to current modules with server checks, profile migration tests and Studio playtest.
- **Do not delete historical recovery branches until that checklist is closed.**
