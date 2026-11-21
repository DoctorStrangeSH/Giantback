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
