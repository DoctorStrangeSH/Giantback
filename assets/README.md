# Giantback Asset Library

This directory is the single source of truth for authored and imported game assets.

## Directory map

| Directory | Contents | Runtime destination |
|---|---|---|
| `source_models/` | Editable OBJ/MTL and source-art briefs; never overwritten by import/export | Not replicated directly |
| `models/` | Reviewed, import-ready model exports and per-asset metadata | `ServerStorage/AssetLibrary/Models` or `ReplicatedStorage/AssetLibrary/Models` |
| `textures/` | Authored texture maps and atlases | `ReplicatedStorage/AssetLibrary/Textures` |
| `icons/` | UI icons and collection thumbnails | `ReplicatedStorage/AssetLibrary/Icons` |
| `audio/` | Licensed/original SFX and music source files | `ReplicatedStorage/AssetLibrary/Audio` |
| `animation_sources/` | Blender/source animation files and export notes | Source-only; published Roblox animation IDs live in metadata |
| `references/` | Approved visual references and art direction snapshots | Not replicated |

## Import pipeline

1. Keep editable source files in `source_models/` or `animation_sources/`.
2. Generate previews/exports into the local ignored `build/` directory. Never overwrite source files.
3. Validate geometry, dimensions, UVs, materials, names and license/provenance.
4. Review the export in Blender, then import it in Roblox Studio.
5. Record the resulting Roblox asset ID, scale, pivot, collision settings and Studio acceptance in the relevant manifest.
6. Only reviewed assets are added to the runtime AssetLibrary in the Roblox place.

## Runtime placement rules

- `ServerStorage`: private templates, enemy rigs, rewards and server-only construction assets.
- `ReplicatedStorage`: client-visible models, icons, textures, audio and shared effects.
- `Workspace`: live placed world instances only; never use as the permanent source library.
- `StarterGui` / `StarterPlayer`: UI and client runtime code, not source-art storage.

Do not copy a source OBJ/MTL into a runtime service. Import it as a Roblox model/MeshPart and review its pivot, collision and performance first.

## Status

The existing six OBJ/MTL source pairs remain in `source_models/`. Their manifest records pending Roblox Studio imports and art acceptance. Empty catalog folders are intentional staging points, not claims that production assets already exist.
