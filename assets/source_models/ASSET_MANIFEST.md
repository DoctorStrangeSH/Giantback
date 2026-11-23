# Giantback Asset Manifest

| Source file | Roblox MeshPart asset ID | Scale | Pivot | Studio checked | Notes |
|---|---|---|---|---|---|
| fox_companion.obj | pending import | pending | pending | no | current source; retained as rollback baseline |
| fox_companion_hero.obj | generated in CI review artifact #229; next silhouette cleanup pending render | pending | see generated `fox_companion_hero_rig.json` | no | #229 passed Blender technical gates and four-view render. Manual review: orange coat and large tail read well; paws are orange but retain cuff-like leg overlap seam; forehead tufts look like horns/bumps; brows too heavy; torso/leg transitions still segmented. Latest source pass shrinks tufts/brows and raises/deepens paws to hide seams. Await fresh render and manual acceptance; Roblox Studio import not done. |
| moth_companion.obj | Hero generator artifact #56 passed Blender technical gate; fourth art correction pass in progress | pending | four UV-mapped wings; enlarged crescents, compact plush thorax, larger face, shorter thicker legs in latest source; fresh render/review pending | no | #56 generated four views and passed geometry/UV/material gates. Manual review: body still too tapered/narrow from front/side, legs too wire-like, crescents too small. New source pass shortens and widens body, enlarges head/eyes/moons, shortens and thickens legs. Fresh Blender artifact + manual review required; Roblox Studio import/runtime animation not done. |
| home_cottage.obj | pending import | pending | pending | no | static building |
| farm_bed.obj | pending import | pending | pending | no | crop visuals may be separate |
| bridge_segment.obj | pending import | pending | pending | no | snap points to be verified |
| home_island.obj | pending import | pending | pending | no | cliff/grass material split |



## Source-space dimensions and import anchors

Dimensions below are measured from the editable OBJ vertex bounds in source units (X, Y, Z). They are regression guardrails, not Roblox avatar-scale acceptance.

| Source | X | Y | Z | Import anchor / orientation |
|---|---:|---:|---:|---|
| fox_companion.obj | 1.36 | 2.65 | 3.54 | feet near Y=0; face points toward -Z |
| moth_companion.obj | 3.18 | 1.97 | 1.11 | body centered near X=0; wings span ±X; hovering source pose |
| home_cottage.obj | 12.55 | 11.38 | 13.85 | foundation floor at Y=0; front door faces -Z |
| farm_bed.obj | 7.51 | 1.39 | 4.85 | bottom near Y=0; long side along X |
| bridge_segment.obj | 6.20 | 2.50 | 5.50 | centered around X/Z=0; deck top at Y=0.375 |
| home_island.obj | 68.73 | 20.95 | 52.86 | grass surface around Y=4.7–4.95; cliff extends downward |

Coordinate convention: Y is up. The fox and cottage front faces point toward -Z. Bridge length is along X in the source file; rotate the segment for the required world direction after import. Preserve the source pivots until Studio scale and placement are reviewed. The moth's positive minimum Y is intentional in its floating source pose; align its runtime follower offset in Studio rather than editing the OBJ pivot blindly.

## Surface data status

| Source data | Status | Notes |
|---|---|---|
| Polygon normals | [~] Crease-aware generated normals | Angle-weighted per-corner normals, 50° crease threshold; visual artist review still required |
| UV coordinates | [ ] Not authored | Proper unwrap and texture painting remain open |
| MTL materials | [~] Base color palette | Material IDs/colors are source placeholders, not finished PBR textures |

## Source geometry snapshot

The current editable OBJ sources were measured in Git (not imported Roblox MeshParts):

| Source | Vertices | Faces | Named object groups |
|---|---:|---:|---:|
| fox_companion.obj | 2,450 | 3,744 | 16 |
| moth_companion.obj | 1,306 | 1,980 | 15 |
| home_cottage.obj | 558 | 615 | 11 |
| farm_bed.obj | 1,354 | 1,884 | 4 |
| bridge_segment.obj | 328 | 358 | 4 |
| home_island.obj | 274 | 376 | 3 |

These values are provisional source-mesh guardrails only. They do not prove mobile performance: imported MeshPart count, materials, collision fidelity, draw calls and real device frame time still require Roblox Studio profiling. Zero-area source faces have been removed and CI now rejects their reintroduction, in addition to guarding against accidental geometry growth.

## Rig import notes

- The Moth source OBJ has independent left/right upper wings, lower wings, wing tips, antennae and eyes. Keep these object groups separate on import; merge only the two small static wing-root groups if desired.
- Runtime names and mapping are documented in assets/source_models/README.md. The client animator expects duplicate names for left/right animated MeshParts and determines the side from each part's local X offset.
- The Fox OBJ already separates head, muzzle, ears, four legs, tail, tail tip, eyes and nose. Keep the four legs and tail groups separate; use the explicit runtime mapping in assets/source_models/README.md before replacing the Parts-based blockout.
