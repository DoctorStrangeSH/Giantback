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


## Character art direction

The fox is the first quality benchmark for all companion art. Follow [FOX_ART_BRIEF.md](FOX_ART_BRIEF.md) for its locked palette, silhouette, rig-group preservation and production acceptance gates. The concept reference is a direction target only; it is not a production mesh or texture atlas. Do not mark the fox complete until the geometry, UVs, textures and Roblox Studio import have been reviewed.

## Source axes and scale

All six sources use Y-up coordinates. Dimensions and intended anchors are recorded in ASSET_MANIFEST.md and protected by CI scale-drift tests. The fox and cottage face toward -Z; the bridge segment runs along X and may need rotation when placed in the world. Keep the original source pivots on first import. In particular, the moth's positive minimum Y is a deliberate floating pose, not a ground-contact model.

OBJ files now include generated per-face normals, but no UV coordinates. Treat the MTL colors as the initial material palette only. During Studio import, inspect shading and material appearance closely; the flat normals may reveal faceting on curved forms, and no textured detail is present. If the importer produces faceting or material loss, return to the source-art pass rather than patching it with random runtime Parts.

## Generated source normals (preliminary)

Each face corner now has an explicit normalized, crease-aware smoothing normal in OBJ (v//vn). Normals are angle-weighted across adjacent faces sharing a source vertex, with a 50-degree crease threshold to retain hard edges. This is a procedural source-art improvement, not a substitute for artist review: curved companion surfaces and tiny details still need visual inspection and possible hand-tuned smoothing in a DCC tool and Roblox Studio.

UV coordinates are still intentionally absent. Do not interpret the material colors as finished textures or the meshes as final production art. Proper UV unwrap, texture painting, eye/face polish, and Studio import acceptance remain open.




## Non-destructive UV preview pipeline

A Blender 4.2.x helper is available at `tools/blender/prepare_source_uv.py`. It imports the six named source meshes, runs Smart UV Project and packs a shared 0–1 atlas while preserving the named mesh objects, then exports preview OBJ/MTL files with UVs and normals to a separate output directory.

Example from the repository root:

```bash
blender --background --python tools/blender/prepare_source_uv.py -- --input assets/source_models --output build/uv_preview --assets fox_companion moth_companion
```

This is an automated UV blockout only. It does not paint textures, author final seams, or approve the look. Preview files must be opened and inspected in Blender, then imported into Roblox Studio before the source manifest can be marked accepted. Original source OBJ/MTL files are never overwritten.


## UV preview safety and visual acceptance

The preview tool has a few safeguards:

- Input and output directories must be different.
- Existing preview OBJ/MTL/manifest files are not overwritten unless `--overwrite-previews` is explicitly supplied.
- Each exported OBJ is parsed again: it must contain vertices, UVs, normals and faces; every face corner must reference valid UV and normal indices; UV coordinates must remain inside the 0–1 atlas.
- The manifest records source and preview SHA-256 hashes plus exported vertex/UV/normal/face counts. This makes it possible to compare previews without changing the editable source.

Run the fox first, inspect it, then process the remaining assets:

```bash
blender --background --python tools/blender/prepare_source_uv.py -- --input assets/source_models --output build/uv_preview --assets fox_companion
blender --background --python tools/blender/prepare_source_uv.py -- --input assets/source_models --output build/uv_preview --assets fox_companion --overwrite-previews
```

The second command is only for intentionally replacing a previous preview. To avoid overwriting, use a fresh output folder instead.



### UV collapse diagnostics

The pure-Python OBJ validator also calculates the 2D shoelace area of every exported face in UV space. Faces whose UV polygon collapses to a line or point are rejected, and the report records the summed UV face area and the number of collapsed faces. This catches a class of broken unwraps that a simple 0–1 bounds check cannot detect.

This is not a complete overlap or texel-density analyzer: overlapping islands and uneven scale still require checker-texture inspection in Blender.

### Export validation is independently tested

The Blender script delegates OBJ validation to `tools/blender/obj_export_validation.py`, a pure-Python module with no Blender dependency. CI exercises real temporary OBJ fixtures, including valid positive and negative-relative indices, invalid vertex/UV/normal references, missing UV data, and UV coordinates outside the atlas. The Blender export step also requires the generated MTL file to exist and be referenced by the OBJ.

This validates the exported file structure, not Blender's actual UV unwrap quality. The script still needs a real Blender 4.2 run and human visual review.


### Reproducible UV checker texture

Generate a checker PNG without Blender or third-party Python packages:

```bash
python tools/blender/generate_uv_checker.py --output build/uv_checker.png
```

Defaults: 1024×1024, 8×8 large tiles, each split into 8×8 smaller checks. The warm/cool high-contrast pattern and fine grid make stretched, rotated or unevenly scaled UV islands easier to spot. The generator refuses to overwrite an existing file unless `--overwrite` is passed.

In Blender, create an Image Texture node, open `build/uv_checker.png`, connect it to the Principled BSDF Base Color for preview only, and inspect the fox from front, sides, back and underside. Remove the checker material before painting/authoring production textures. This checker is a diagnostic aid, not final game art.


### Automated checker render for visual review

After generating the checker PNG and exporting a UV preview OBJ, Blender can create a repeatable lit still plus an editable review scene:

```bash
blender --background --python tools/blender/render_uv_preview.py -- --input build/uv_preview/fox_companion.obj --checker build/uv_checker.png --output build/uv_review/fox_companion_uv.png
```

The script imports only the preview OBJ, requires UV layers on every mesh, assigns a temporary checker material, frames the model with an orthographic camera and three area lights, then writes a PNG and a companion `.blend` scene. Existing outputs are protected unless `--overwrite` is explicitly supplied. It does not edit source OBJ/MTL files or create production textures.

Use the rendered still as a quick diagnostic, then open the saved scene and inspect front, back, both sides, top and underside. The render is not an artistic beauty pass and does not approve UV seams or texel density. A human must still inspect the UV Editor and record acceptance evidence in ASSET_MANIFEST.md.

### Required manual review before accepting a UV preview

1. Open the exported OBJ in Blender 4.2.x and inspect the UV Editor with a checker texture.
2. Confirm there are no collapsed or overlapping islands except intentional mirrored/stacked regions.
3. Check seams on the muzzle, ears, paws, tail and eye parts; Smart UV seams are only a starting point.
4. Check texel density across body/head and small details; adjust islands manually where visible stretching appears.
5. Paint or author a proper texture set and verify MTL/material assignments.
6. Export/import into Roblox Studio, verify object names, pivots, materials and shading on PC and a mobile-sized viewport.
7. Only after review, add preview/texture references and Studio acceptance evidence to ASSET_MANIFEST.md.

CI validates file structure and index safety; it cannot approve seam quality, texture painting, visual style or Roblox Studio appearance. UV and texture status therefore remains [~] until a human visual review is recorded.


## Fox hero mesh generation

A separate first-pass hero mesh generator is available at `tools/blender/build_fox_companion.py`. It builds a softer, more expressive fox silhouette with shaped ears and inner-ear inserts, layered cheeks, a cream chest, rounded paws, large readable eyes and a curved two-part tail.

Run with Blender 4.2.x:

```bash
blender --background --python tools/blender/build_fox_companion.py -- --output-dir build/fox_hero
```

Outputs are isolated in the selected build folder: `fox_companion_hero.obj`, `fox_companion_hero.mtl`, `fox_companion_hero.blend` and `fox_companion_hero.png`. The generator refuses a non-empty output folder unless `--overwrite` is explicit. The original `fox_companion.obj/.mtl` are not modified.

This is the first sculpted-form silhouette/material blockout, not finished production art. Smart UV is only an automatic unwrap; hand-painted fur detail, seam/overlap review, animation pivots, Blender 4.2 runtime render and Roblox Studio acceptance are still required. Preserve the sixteen documented rig group names when evaluating the exported OBJ.

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
