# Giantback — integration audit (2026-11-23)

Source of truth: `PROJECT_SPEC.md`. Integration target: `main`. Working candidate: `feat/combat-c0-contract` ([PR #8](https://github.com/DoctorStrangeSH/Giantback/pull/8)).

## Verified repository state

- `main` still uses the legacy `build.py` layout with the moving Mossback, while the current product spec requires fixed home islands and a hub.
- Candidate branch is 1416 commits ahead and 6 behind `main` (comparison at audit time), with 120 changed files.
- GitHub marks PR #8 not mergeable at creation. Resolve conflicts first; do not force-update `main` or erase those six commits.
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

- [ ] Reconcile `main`'s six commits and resolve PR merge conflicts.
- [ ] Review unique commits of the four diverged branches and port only missing, tested functionality.
- [ ] Verify Python tests and Roblox place export; check embedded scripts and asset manifests.
- [ ] Studio Play: spawn on owned island, gather resources, repair bridge, discover Fox, follow scent trail, obtain MoonSeed, rejoin and verify persistence.
- [ ] Studio Play: equip Moth, reveal MoonBloom and verify server-owned personal reward.
- [ ] Two-player Studio Play: permissions, individual resource cooldowns and pet discoveries.
- [ ] Mobile and gamepad checks; confirm single readable primary goal and no overlapping modal windows.
- [ ] Artistic approval for imported MeshPart assets; do not delete working blockouts until their replacements are demonstrated in Studio.
- [ ] Update `README.md` and `ROADMAP.md` to match shipped `main` after merge.

**Never mark 1.0 DONE from CI alone.** The user must be able to launch the integrated place in Roblox Studio and test each new gameplay slice.
