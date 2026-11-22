# Giantback — 3D Asset Import Guide

## Why this step exists
Giantback keeps editable OBJ/MTL source meshes in Git. Roblox places reference uploaded MeshPart asset IDs, not raw repository paths. The source models must therefore be imported and published through Roblox Studio before they can replace current in-game blockouts.

## Import order
1. home_island — verify scale, organic top surface, cliff materials and collision.
2. home_cottage — verify silhouette, pivot, windows, roof and porch.
3. bridge_segment — verify deck width, rails and snap points.
4. farm_bed — verify crop visibility and player interaction height.
5. fox_companion — keep body, head, legs and tail as separate riggable parts.
6. moth_companion — keep upper/lower wings and antennae separate for animation.

## Studio workflow
1. Open the Giantback place in Roblox Studio.
2. Open the 3D Importer.
3. Select an OBJ source from assets/source_models and keep its matching MTL beside it.
4. Import as a Model. Inspect materials, normals, scale, pivot and individual object names.
5. For pets, preserve named parts and create Motor6D/Weld rig joints. Do not weld the animated wings or tail into the body.
6. Set collision fidelity to an appropriate simplified hull for large static models; use non-collidable decorative subparts.
7. Publish each approved MeshPart to the Giantback experience.
8. Record each published asset ID, scale, pivot and source filename in assets/source_models/ASSET_MANIFEST.md.
9. Only after the imported model passes Studio review should scripts switch from the old blockout.

## Acceptance
- No missing materials or inverted normals.
- Correct scale against the Roblox avatar.
- Pet silhouette reads at normal follow distance.
- Fox tail and moth wings animate independently.
- Home and bridge collision do not trap players.
- Mobile performance remains acceptable.
- Asset ownership and permissions are confirmed for the experience.

Do not replace working production models with an untested import. The OBJ/MTL sources are ready, but the in-place game replacement remains pending until Roblox Studio has published MeshPart IDs.


## Automatic staging after Studio import (Asset Pipeline 1.0)

The repository includes `tools/roblox/organize_imported_assets.luau`, a Roblox Studio Command Bar helper. This **does not** import OBJ files, publish MeshPart IDs or replace current gameplay models. It only categorizes already-imported models.

1. Import the six sources with Roblox Studio's 3D Importer as described above.
2. Select the imported Model instances in Explorer (not their individual MeshPart children). Expected import names are `fox_companion`, `moth_companion`, `home_cottage`, `farm_bed`, `bridge_segment`, and `home_island`. Alternatively, set a Model's `GiantbackAssetKey` attribute to the matching source name.
3. Copy `tools/roblox/organize_imported_assets.luau` into the Studio Command Bar. With `local APPLY = false`, it prints only a preview of placements and warnings.
4. Inspect the plan and warnings in Output. To perform the moves, change `local APPLY = true` and run again with the same selection.
5. Models are moved only into `AssetLibrary/Models` folders in `ReplicatedStorage` (Fox/Moth) or `ServerStorage` (buildings/environment). The script never deletes/replaces existing models.
6. Imported models are marked `GiantbackImportStatus = NeedsStudioReview`. Review rigging, material fidelity, scale, permissions and collision, then record approved IDs in `assets/source_models/ASSET_MANIFEST.md`.

The current world and follower scripts still use their existing blockout implementations. Staging a model **does not** enable it in gameplay. Switching to imported models is a separate, validated rollout after Studio acceptance.

### Safety gates

- Only selected `Model` instances containing at least one `MeshPart` qualify.
- Unknown names, duplicates and occupied target names are skipped with warnings.
- The source OBJ/MTL files and current `Workspace` / `HomeIslandTemplate` instances are not modified by the organizer.
- Before saving/publishing the place, check all staged assets manually; rollback by undoing the move or reopening the last saved place.


## Approved Fox/Moth runtime template — guarded opt-in

The companion client now resolves optional imported templates at:
- `ReplicatedStorage/AssetLibrary/Models/Companions/FoxCompanion`
- `ReplicatedStorage/AssetLibrary/Models/Companions/MothCompanion`

Both still use the existing `ReplicatedStorage/Fox` and `ReplicatedStorage/Moth` blockouts by default. The imported model is selected **only** if all of the following are true:

1. The Model contains a MeshPart named `Body` and at least one MeshPart named `Tail` (Fox) or `Wing` (Moth).
2. The imported Model has `GiantbackAssetKey = fox_companion` or `moth_companion` respectively.
3. The imported Model is explicitly marked `GiantbackImportStatus = Approved`.
4. The imported Model is explicitly marked `GiantbackRuntimeReady = true`.
5. A Studio-tested part-based animation mapping has been confirmed with `GiantbackProceduralAnimationCompatible = true`.

**Do not set these flags just to enable an unfinished mesh.** Roblox Studio must verify that moving mesh parts have valid pivots, correct local names, no conflicting welds/constraints, and no collision or camera issues. The current procedural animator changes each BasePart CFrame directly and cannot animate an arbitrary skinned rig/armature without additional implementation.

The feature affects the client follower clones. Wild encounter art and other world geometry remain existing blockouts until their own integration is accepted. Approval flags are stored on the imported Studio Model, not in source OBJ files. They are not automatically restored by running `python build.py`: the generated .rbxlx does not contain uploaded MeshPart assets.

If an import is missing, incomplete or unapproved, `companionTemplate` falls back to the playable companion template without changing server-owned gameplay state. After a template is approved, respawn/re-equip to instantiate a new follower clone.
