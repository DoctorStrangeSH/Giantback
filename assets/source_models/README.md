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

## Import into Roblox Studio

1. Open the 3D Importer and select the OBJ file. Keep its matching MTL file beside it.
2. Import as a Model and inspect scale, pivot, material names, normals and collision.
3. For companion models, keep the named parts separate so they can be rigged and animated.
4. For buildings and props, merge static pieces only when it reduces draw calls without losing needed material/animation separation.
5. Publish approved MeshParts to the Giantback Roblox experience and record their asset IDs in the asset manifest.
6. Do not replace current production models until the imported asset has been checked in Studio on PC and mobile.

The OBJ sources are not yet wired into the running place: Roblox requires imported/published MeshPart asset IDs before a place can reference them. The current Parts-based visuals remain temporary blockout until that Studio import step is completed.

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
