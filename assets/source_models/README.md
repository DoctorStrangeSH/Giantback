# Original Giantback source models

All OBJ/MTL files in this directory are original procedural source meshes created for Giantback. No third-party marketplace model or copied game asset is included.

| Source | Intended use | Parts/materials |
|---|---|---|
| fox_companion.obj | Fox companion | body, head, muzzle, ears, legs, tail, eyes |
| moth_companion.obj | Moon moth companion | body, head, separately grouped left/right upper/lower wings, wing tips, antennae and eyes, glow core |
| home_cottage.obj | Starter home | foundation, walls, gabled roof, door, windows, chimney, porch |
| farm_bed.obj | Raised farm bed | frame, soil, carrot roots, crop leaves |
| bridge_segment.obj | Modular bridge | deck, supports, rails, rope |
| home_island.obj | Home island terrain | organic island top and tapered cliff source |


## Source axes and scale

All six sources use Y-up coordinates. Dimensions and intended anchors are recorded in ASSET_MANIFEST.md and protected by CI scale-drift tests. The fox and cottage face toward -Z; the bridge segment runs along X and may need rotation when placed in the world. Keep the original source pivots on first import. In particular, the moth's positive minimum Y is a deliberate floating pose, not a ground-contact model.

OBJ files currently contain no authored UV coordinates or vertex normals. Treat the MTL colors as the initial material palette only. During Studio import, inspect shading and material appearance closely; do not assume textured detail or final smooth shading is present. If the importer produces faceting or material loss, return to the source-art pass rather than patching it with random runtime Parts.

## Import into Roblox Studio

1. Open the 3D Importer and select the OBJ file. Keep its matching MTL file beside it.
2. Import as a Model and inspect scale, pivot, material names, normals and collision.
3. For companion models, keep the named parts separate so they can be rigged and animated.
4. For buildings and props, merge static pieces only when it reduces draw calls without losing needed material/animation separation.
5. Publish approved MeshParts to the Giantback Roblox experience and record their asset IDs in the asset manifest.
6. Do not replace current production models until the imported asset has been checked in Studio on PC and mobile.

The OBJ sources are not yet wired into the running place: Roblox requires imported/published MeshPart asset IDs before a place can reference them. The current Parts-based visuals remain temporary blockout until that Studio import step is completed.


## Fox rig import mapping

Keep the following pieces separate on import. Duplicate runtime names are intentional and allow the common follower animator to move each paw and ear independently.

| OBJ object | Runtime MeshPart name |
|---|---|
| FoxBody | Body |
| FoxBelly | Chest bib |
| FoxHead | Head |
| FoxMuzzle | Muzzle |
| FoxEarLeft / Right | Ear |
| FoxEarInner | Inner ear |
| FoxLegFrontLeft / Right | Paw |
| FoxLegBackLeft / Right | Paw |
| FoxTail | Tail |
| FoxTailTip | Tail tip |
| FoxEyes | Eye |
| FoxEyeSparkles | Eye shine |
| FoxNose | Nose |

Keep the four legs and tail groups separate; do not merge them into the body mesh.

## Companion rig import mapping

The Moth OBJ deliberately keeps animated pieces in separate left/right objects. During Studio import, rename the imported MeshParts to the runtime rig names below (duplicate names are intentional; the follower animator uses each part's local X position to choose its side).

| OBJ object | Runtime MeshPart name |
|---|---|
| MothBody | Body |
| MothHead | Moth head |
| MothUpperWingLeft / Right | Wing |
| MothUpperWingRoot | Wing root (static) |
| MothLowerWingLeft / Right | Wing lower |
| MothLowerWingRoot | Wing root (static) |
| MothWingTipLeft / Right | Wing tip |
| MothAntennaLeft / Right | Antenna |
| MothEyeLeft / Right | Moth eye |
| MothGlowCore | Moonlight glow |

The matching pivot locations are validated by the runtime blockout contract, but must still be checked after import. Do not merge the left/right animated groups into one MeshPart.
