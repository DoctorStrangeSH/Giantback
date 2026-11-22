# Lunar Moth Companion — Art Production Brief

**Role in Giantback:** second signature companion; the magical exploration counterpart to the Fox Hero.
**Source baseline:** `assets/source_models/moth_companion.obj` + `moth_companion.mtl`. Keep the original files as rollback references; create a separate hero iteration rather than overwriting them.
**Status:** [~] gameplay identity and source palette documented; current OBJ/MTL are a BLOCKOUT baseline, not artist-approved. UVs, painted textures, animation rig, Blender review and Roblox Studio import remain open.

## 0. Existing source audit — 2026-11-22

The original `moth_companion.obj` was parsed directly before planning the hero rebuild:
- 1,306 vertices; 1,980 faces (1,978 triangles and 2 quads).
- 15 named objects: body, head, upper/lower wing left/right, upper/lower wing roots, wing tips left/right, antennae left/right, eyes left/right and glow core.
- Seven MTL materials are assigned across the objects.
- 0 zero-area faces and 0 edges shared by more than two faces in the source audit.
- 616 boundary edges remain; the source includes open surface shells and requires manual normal/thickness review before reuse.
- **0 UV coordinates** are present. This is a hard production gap: the existing MTL colors are not a painted wing texture.

This confirms the original source is a useful shape/layout BLOCKOUT with separable wing objects, but not a finished hero asset. Preserve it unchanged as rollback baseline. The new hero model must add authored UVs, closed/thickened wing surfaces where appropriate, hand-painted wing motifs and an independently validated four-wing rig.

## 0.3 Visual review — first successful Hero artifact (#20)

The corrected generator passed the full Blender geometry/material/UV gate and produced all four views. This is a successful technical milestone, but the art review is **rejected for final approval**.

Observed in the actual renders:
- The four wing meshes are distinct and clean, but the silhouette reads as narrow pointed panels rather than broad, soft moth wings; upper/lower wings overlap awkwardly in 3/4 and side views.
- The body reads as three stacked primitive spheres (head/thorax/abdomen), not one soft plush insect silhouette.
- Antennae read as disconnected gold beads rather than curved sensory feelers.
- Wing colors are present and readable, but the design lacks a memorable moon motif and the creature is still too generic/blockout-like.

Corrective source pass:
- broaden the upper/lower wing silhouettes and shorten their spanwise length to create softer, rounded wings;
- replace bead antennae with curved Bezier feelers and club tips;
- combine thorax/abdomen into one elongated body shell while retaining gold abdomen bands as decoration;
- add a small gold crescent inlay with a lilac offset inset on each wing, positioned on the visible surface as the creature's signature moon motif;
- preserve the four separate UV-mapped wing groups and existing palette.

This pass still requires a fresh render and manual review. Do not treat the first successful geometry gate as art approval or as a Roblox-ready rig.

## 0.2 First Blender CI finding and correction

The first real Blender execution successfully generated the BLEND/OBJ and all four renders, but the geometry gate rejected zero-area faces on `MothWingUpperLeft`. Root cause: the wing-width profile collapsed to zero at the root/tip rows while still emitting quad strips. The width profile now has a small nonzero floor (10% of the broad profile), preserving a narrow root/tip silhouette without collapsing the surface. A regression test locks this minimum-width rule.

The corrected generator is awaiting a fresh Blender run. The previous failure is not waived; the mesh must pass zero-area and manifold checks before manual art review.

## 0.1 Hero generator milestone — 2026-11-22

A separate Blender 4.2 generator now exists at `tools/blender/build_moth_companion.py`; it does not overwrite the legacy OBJ. It builds four distinct thick wing meshes with UV layers and separate upper/lower left/right names, the ivory body, face, antenna segments, gold abdomen bands and luminous core. It exports a BLEND, OBJ/MTL, rig-contract JSON, grouped mesh report and four review renders.

A dedicated CI workflow `.github/workflows/lunar-moth-visual-review.yml` validates the 10 stable rig groups, four wing groups, UVs, geometry and materials, then uploads a review artifact. Source-contract tests live in `tests/test_lunar_moth_hero_workflow.py`.

**Important:** this is the first hero-model generation pass, not an approved final asset. The JSON documents intended wing pivots and animation states; it is not yet a Roblox animation rig. Blender execution, artifact review, wing silhouette/material polish, Studio import and runtime animation remain open gates.

## 1. Character identity

A tiny, gentle moon-moth that feels like a magical forest spirit: curious, calm, welcoming and quietly luminous. It should be instantly distinguishable from the Fox by its hovering silhouette, broad patterned wings, delicate antennae and soft light core.

Personality cues:
- floats rather than walks; gentle bobbing and slight forward lean when following;
- wings move in a soft alternating rhythm, never like a fast insect;
- antennae react subtly to nearby secrets;
- face is sweet and readable, not scary or biologically realistic;
- glow is a magical accent, not a bloom effect needed to see the model.

## 2. Gameplay identity — preserve the reason to collect it

The Moth is the secret-finder companion:
- reveals hidden MoonBloom flowers in the Moonlit Grove;
- illuminates ancient runes and helps reveal the personal Moon Gate route;
- emits a short lunar sparkle burst when its ability milestone is reached;
- provides clear local feedback to its owner without granting other players' personal discoveries.

Do not turn the moth into a generic flying pet. Its silhouette, glow and wing patterns should communicate discovery and moonlight.

## 3. Locked palette direction

Use the existing MTL as a palette starting point, not as final painted materials.

| Region | Existing material | Direction |
|---|---|---|
| Main body / face | `moth_cream` | warm moon-ivory; soft, not pure white |
| Upper wing panels | `wing_lilac` | rich lavender, broad clean shapes |
| Secondary wing panels | `wing_pink` | muted rose-pink, not candy neon |
| Accent wing panels | `wing_cyan` | restrained luminous turquoise |
| Wing/body ornament | `moth_gold` | warm champagne-gold |
| Eyes / tiny markings | `dark` | deep plum-brown |
| Core / glow accents | `glow` | pale moon-cyan with a soft turquoise edge |

Keep the palette to these coordinated hues. Avoid rainbow gradients, random neon spots and high-frequency wing noise. The cyan glow should contrast with the lavender/pink wing panels without washing them out.

## 4. Silhouette and proportions

- Head and thorax form one soft, readable central body; avoid a stack of disconnected spheres.
- Abdomen is gently segmented, tapering toward the rear; segment seams are broad and subtle.
- Four wings are required: two larger upper wings and two smaller lower wings, each with its own pivot/group.
- Wings must have a broad moth-like leaf/heart silhouette with softly scalloped edges, not thin flat triangles.
- Left/right wings should be mirrored in overall shape but may use balanced asymmetric painted markings.
- Wing thickness and edge bevel must catch light at gameplay distance; avoid paper-thin surfaces.
- Antennae are curved and feathery in silhouette, but simplified enough for mobile performance.
- Eyes are large, warm and friendly; mouth and facial details remain minimal.
- A small luminous core sits on the upper thorax. It must not obscure the face.
- Keep the hover pose stable and centered; do not bake a large vertical offset into the mesh pivot.

## 5. Wing artwork and surface

- Build broad, hand-painted wing panels with 2–4 large motifs per wing: moon crescents, petal arcs and soft vein lines.
- Use clean color blocks with gentle gradients; no tiny speckles or dense insect scales.
- Add a restrained pearlescent edge and subtle translucent feel, but preserve opaque readable color in Roblox lighting.
- The wing pattern should remain recognizable at mobile camera distance.
- Body material is soft velvet/fuzzy cloth, not shiny plastic.
- Glow uses a restrained emissive-style core plus runtime PointLight; the mesh must remain readable with bloom disabled.
- No photoreal insect anatomy, hairy macro details, harsh black outlines or noisy procedural textures.

## 6. Rig and animation requirements

Stable named groups/pivots are required:
- `MothHead`
- `MothThorax`
- `MothAbdomen` (segment groups may be separate if needed)
- `MothWingUpperLeft`, `MothWingUpperRight`
- `MothWingLowerLeft`, `MothWingLowerRight`
- `MothAntennaLeft`, `MothAntennaRight`
- `MothGlowCore`

Minimum animation set:
1. **Idle hover:** slow vertical bob, gentle body tilt, asynchronous wing phases.
2. **Follow:** smooth hovering movement with wings accelerating slightly during travel.
3. **Reveal secret:** turn toward the point of interest, wings open, core brightens and a small crescent/petal sparkle appears.
4. **Ability burst:** short brighter pulse and outward fan of lunar motes; cosmetic only and must not change server rewards.
5. **Rest:** wings fold partially and glow dims without going fully dark.

Wing pivots must be independent and must not intersect the body during a full flap cycle. Antennae motion should be subtle and secondary.

## 7. Technical and performance gates

- Separate editable source and generated review outputs; never overwrite the original OBJ/MTL baseline.
- Produce BLEND, OBJ/MTL, rig JSON, mesh report and four review views (front, 3/4, side, back).
- Every mesh group needs non-empty geometry, UVs and assigned materials.
- Reject zero-area faces and non-manifold edges; inspect normals and intersections manually.
- Keep wing groups separate for runtime animation. Verify mirrored pivots and wing clearance.
- Include a close-up view for wing markings and a gameplay-distance view for readability.
- Target a modest mobile-friendly mesh budget; prefer clean broad surfaces over dense geometry. Record actual counts in the report rather than assuming the budget passed.
- Roblox Studio import, scale, pivots, animation and mobile performance are separate acceptance gates; Blender CI alone does not close them.

## 8. Visual acceptance checklist

The Moth is NOT artist-approved until all are true:
- [ ] reads immediately as a magical moth, not a butterfly or generic fairy;
- [ ] four wings have broad, beautiful, clearly separated silhouettes;
- [ ] body and face are expressive and readable at gameplay distance;
- [ ] lavender / rose / cyan / gold palette is harmonious and not neon;
- [ ] moonlit core is visible without bloom dependency;
- [ ] wing markings remain crisp on mobile;
- [ ] idle/follow/reveal animations are graceful and collision-free;
- [ ] mesh, UV, materials, rig and performance reports pass;
- [ ] imported and inspected in Roblox Studio.

## 9. Production sequence

1. Inspect and document the current OBJ/MTL geometry and pivots.
2. Create a separate sculpted hero model with four independent wing groups.
3. Add hand-painted wing panels and a restrained luminous core.
4. Generate four-view Blender review package and inspect it manually.
5. Correct silhouette/materials before any runtime replacement.
6. Import into Studio and validate scale, pivots, animation and mobile readability.
