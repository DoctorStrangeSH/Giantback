# Fox Companion — Art Production Brief

**Role in Giantback:** first signature companion and the visual benchmark for every later creature.
**Reference target:** the generated Giantback fox turnaround concept shared in the project conversation on 2026-11-21. Use it as a direction reference, not as a literal texture or a finished production mesh.
**Status:** [~] art direction locked for the next modeling pass; source geometry, UVs, textures and Roblox Studio import are not yet artist-approved.

## 1. Character identity

A warm, brave, curious little fox cub. It should feel like a collectible companion with a clear silhouette at a small mobile-screen size: oversized expressive head, compact rounded body, short sturdy legs, oversized ears, and a large plush tail with a bright cream tip.

Personality cues:
- curious and friendly, never aggressive;
- alert ears and a slight head tilt;
- bright eyes with a readable catchlight;
- soft cheek tufts and a welcoming muzzle;
- tail motion should be a major part of the idle animation.

## 2. Locked palette

Use the existing source MTL colors as the starting palette, then refine them in a hand-authored texture/material pass. Hex values below are rounded display equivalents of the current MTL diffuse colors.

| Region | Current material | Starting color | Art direction |
|---|---|---|---|
| Main coat / ears / legs / tail | fox_orange | #E85C21 | warm orange with subtle lighter forehead and cheek accents |
| Muzzle / chest / tail tip | cream | #FADBA8 | soft warm ivory; keep muzzle readable against orange |
| Inner ears | ear_pink | #D16359 | muted coral rose, not neon |
| Eye / dark details | dark | #140F0D | deep warm brown, avoid flat pure black |
| Eye catchlights | white | #FFFADE | small crisp warm-white highlights |
| Nose | nose | #1F120F | dark cocoa with restrained gloss |

Do not introduce random extra hues. Any new markings must remain inside this warm, cozy palette.

## 3. Silhouette and proportions

- Head is the focal point and should read clearly from front, 3/4 and side.
- Eyes are large and friendly, but retain enough visible iris and sclera to avoid a permanently startled expression.
- Ears are tall, slightly outward-splayed, rounded at the tips, with visible inner-ear inset. Current source ear shells are only six vertices each; remodel them rather than trying to hide the low-poly shape with texture.
- Muzzle is a soft two-cheek shape, not a single flat blob. Preserve a small bridge and rounded nose.
- Add restrained cheek fluff as modeled clumps or sculpted forms; avoid hundreds of thin strands.
- Chest bib should be a readable layered cream shape, not a flat decal.
- Tail is large and expressive, with a smooth tapered base, broad plume and clearly shaped cream tip. Keep tail and tip separate for animation.
- Paws should be short and rounded with subtle toe definition; do not create separate tiny floating toe pieces.

## 4. Surface and rendering style

- Premium stylized 3D game art with hand-painted surface breakup and soft sculpted forms.
- Broad clean forms first; small details only where they improve expression.
- Soft roughness variation on fur; restrained gloss on eyes and nose. Fur micro-relief must remain subtle at gameplay distance (current review target: Noise scale 16, Bump strength 0.004, distance 0.002, Sheen weight 0.08); avoid visible sand-like grain.
- No realistic individual hair strands, photoreal fur, plastic toy shine, harsh outlines, or noisy procedural speckling.
- Use warm key light, gentle fill, soft rim light and contact shadows.
- Character must remain legible without relying on bloom or post-processing.


**Current generator review palette (not yet visually approved):** `fox_orange` RGB `(0.90, 0.065, 0.001)`; `cream` RGB `(0.92, 0.72, 0.48)`. Previous review lighting was Key 175 / Fill 75 / Rim 125, world strength 0.22 and AgX High Contrast. Current pending source pass uses Standard color transform, Key 95 / Fill 42 / Rim 72, and smaller embedded cheek accents. The latest review render still reads too salmon/pastel under AgX lighting, so the orange channel is being made more saturated; cheek pads are also reduced and tucked into the muzzle to avoid detached whisker-dot shapes. The increased green channel is intentional: prior renders read red/coral rather than recognizable fox orange under AgX studio lighting. Re-render and inspect under the same four views before changing the approved color standard.

**Visual review of artifact #145:** all four views are technically clean and the silhouette reads as a friendly collectible fox, with a strong tail and readable eyes. However, the coat still renders salmon/pastel rather than unmistakably orange; the cream cheek pads protrude as separate white dots. This is a visual rejection, not an approval. Latest corrective source pass pushes green/blue channels down and scales/tucks the cheek pads; new render is required before reconsideration.

## 4.3 Visual review — artifact #173

Artifact #173 shows a meaningful improvement: the torso and tail read closer to a saturated orange, and the cheek pads are less prominent. The head still renders noticeably peach/salmon under the review pipeline, so the overall coat is not yet visually consistent. The body/leg intersections remain too segmented and the paws still read as separate cuffs. This is a rejection for final art, but the improvement is worth preserving.

Next source pass:
- switch the review transform from AgX to Standard to avoid highlight desaturation;
- reduce Key / Fill / Rim to 95 / 42 / 72 and world strength to 0.22;
- tuck the cheek accents further into the muzzle (0.042 × 0.026 × 0.010);
- preserve the large tail and the friendly face proportions while improving color consistency.

The next Blender artifact must be inspected before any further shape edits. Do not mark Fox Hero accepted based on CI success alone.

## 4.2 Visual review — artifact #163

The updated four-view Blender artifact was manually inspected. The fox reads as a friendly collectible and the tail silhouette remains the strongest feature. It is still not artist-approved:
- Head highlights render peach/pink despite the orange source material.
- Cream cheek pads remain visibly detached from the muzzle.
- Front and rear legs read too much like straight cylinders at the current camera distance.
The next corrective pass changes the review lighting/contrast, deepens the coat toward saturated orange, and embeds smaller cheek accents into the muzzle silhouette. The body/head proportion should remain intentionally cute and head-forward; do not shrink the head just to make the silhouette more realistic. Tail shape is approved directionally and should be preserved.

## 4.1 Review findings and corrective pass (2026-11-22)

The first successful Blender visual review (four orthographic views; 17 rig groups; clean UV/material/mesh report) is a technical pass, not an art approval. The rendered coat read pink-coral instead of fox orange, procedural fur relief looked grainy, and the cheek tufts projected like whisker spikes. The corrective generator pass therefore:
- shifts the coat from red-coral toward a clearer storybook orange (generator RGB 0.90 / 0.20 / 0.025) and the cream toward warm ivory (0.92 / 0.72 / 0.48);
- lowers key/fill/rim and world illumination to retain color saturation;
- reduces fur noise scale to 16, bump to strength 0.004 / distance 0.002 and sheen weight 0.08;
- replaces pointed cheek tufts with rounded cream cheek pads integrated into the muzzle silhouette.
The updated render must be reviewed again before Fox Hero can be artist-approved. Do not mark the model final based on the successful technical package alone.

## 5. Existing rig groups — preserve names

Keep these source groups separate until the Roblox rig has been checked:

| Source OBJ group | Purpose |
|---|---|
| FoxBody | torso |
| FoxBelly | cream chest/belly bib |
| FoxHead | head |
| FoxMuzzle | muzzle and cheeks |
| FoxEarLeft / FoxEarRight | independently animated ears |
| FoxEarInner | inner-ear color/detail |
| FoxLegFrontLeft / Right | front paws |
| FoxLegBackLeft / Right | rear paws |
| FoxTail | animated tail |
| FoxTailTip | cream tail tip |
| FoxEyes | eyes |
| FoxEyeSparkles | eye catchlights |
| FoxNose | nose |

Runtime renaming is documented in README.md. Do not merge the left/right legs, ears, tail, or tail tip into the body/head mesh. The original source OBJ keeps its legacy 16-group contract. The hero variant deliberately splits the inner-ear inserts into `FoxEarInnerLeft` and `FoxEarInnerRight` (17 groups total) so each insert can follow its corresponding animated ear. The hero generator also writes a source-space pivot sidecar because OBJ does not preserve object origins. If new cheek tufts are added, preserve them as a small number of clean, named objects and update the rig map and CI contract in the same change.

## 6. Production gates

A fox art pass is not complete until all of these are true:

1. Revised ears, cheeks, muzzle and tail silhouette are reviewed in front / 3/4 / side / back views.
2. Mesh topology is clean; no zero-area faces, flipped normals, accidental intersections or paper-thin surfaces.
3. UV islands have no accidental collapse; overlap is intentional and documented; texel density is consistent across face and body.
4. Hand-authored color/roughness details improve expression without noisy fur patterns. The hero blockout now includes subtle paired brows and a curved smile; these remain grouped into FoxHead and FoxMuzzle so the 17-part runtime contract is unchanged.
5. Eyes, nose, muzzle and chest read at a 375 px mobile viewport and at normal in-world follow distance.
6. Tail and four legs remain independently animatable.
7. Roblox Studio import preserves names, uses `fox_companion_hero_rig.json` to restore source-space pivots, and preserves materials and silhouette; PC and mobile review is recorded in ASSET_MANIFEST.md.
8. Only after those checks may the fox be marked [x] and used as the quality benchmark for the moth.

## 7. Explicit non-goals for this pass

- No new fox skins or monetization variants.
- No extra accessories before the base silhouette is approved.
- No dense strand-based fur simulation.
- No replacing the current rig with a single merged mesh.
- No claiming that a generated concept image is a finished mesh, texture atlas or Studio-tested asset.


## Organic head and muzzle pass

The current Fox Hero generator now builds the skull from a dense deformed quad shell with cheek/jaw shaping, and constructs the muzzle as a tapered multi-section loft. These replace the previous stock ellipsoid primitives for the two most visually important facial masses. This is an intermediate procedural sculpting pass, not a hand-sculpted production asset; cheek tufts, body, paws and several details still use primitive-derived forms and need artist review.


## Organic torso pass

FoxBody and FoxBelly are now separate organic Y-axis loft meshes with shaped cross-section profiles. The body profile broadens through the ribcage and tapers toward shoulders/hips; the cream belly uses a shallow inset-like profile. This remains a procedural sculpting foundation and requires Blender renders from front/side/back to validate silhouette and intersections.


## Organic limb pass

Front and rear leg meshes now use their own multi-section loft profiles, with narrower ankle transitions and fuller upper limbs. They remain inside the existing four limb rig groups. Separate paw-end forms are retained for silhouette and material contrast. This is still procedural geometry and requires render-based proportion review.


## Plush tail silhouette pass

FoxTail and FoxTailTip now use a dedicated swept elliptical mesh, with independent width/depth profiles along the centerline. This gives the tail a broader plush cross-section than a round tube while retaining separate animated base/tip groups and cream tip material. Render review is still required to validate silhouette, seams and body intersection.


## Ear silhouette pass

The ear generator now uses 25 profile rings and 32 cross-section sides, a broad lower section, tapered upper third, subtle outward sweep and convex front depth. Inner-ear forms remain separate so pink insets can be refined independently. Review front/side silhouettes and inner-ear intersections in Blender before treating the shape as approved.


## Eye expression pass

Each eye now has a softly arched upper eyelid rim and a secondary catchlight. The eyelid meshes join the existing FoxEyes group; both catchlights join FoxEyeSparkles. This adds more readable expression without increasing the runtime rig group count. Render review is needed to validate placement, eye openness and readability at gameplay distance.


## Cheek silhouette pass

The paired cream cheek accents now use tapered curved-plume geometry, widening through the cheek and narrowing to soft tips. They follow the lower muzzle contour and remain inside FoxMuzzle, replacing the previous round ellipsoid add-ons. Check front and three-quarter renders for symmetry, overlap and readability before approval.


## Soft-fur material pass

Fox orange and cream materials use restrained Noise Texture → Bump micro-relief (scale 28, strength 0.075, distance 0.014) plus a subtle Principled BSDF sheen (weight 0.18, roughness 0.72) to soften broad highlights without producing noisy speckling. The generator records `soft_fur`/`smooth` surface profiles in the mesh report; CI requires `soft_fur` on body, head, ears, paws and tail. Facial glossy materials are intentionally unchanged. Validate under neutral studio lighting and at gameplay distance; this is a subtle surface treatment, not painted fur strands.


## Forelock silhouette pass

The single forehead ellipsoid is replaced by three layered curved-plume tufts: a central swept lock and two smaller side locks. They follow the brow/crown transition and remain in FoxHead, preserving the existing 17-group rig contract. Front and three-quarter renders must confirm that the locks do not obscure the eyes or intersect the ears.


## Paw readability pass

Each of the four paws now has three shallow curved toe separators in a muted warm-brown material. The details are deliberately small and rounded (no claws), and are merged into the existing corresponding front/back leg groups, preserving the 17-group runtime contract. Review front/back-facing visibility, surface contact and readability at gameplay distance.


## Tail tip transition pass

The cream tip profile now begins at the exact terminal centerline and matching width/depth radii of FoxTail, then narrows through five elliptical profile stations. This is intended to remove the visible gap/step at the orange-to-cream join while retaining separate FoxTail and FoxTailTip rig groups. Render inspection is still required to confirm normals, shading continuity and silhouette.


## Automated Blender visual review

A dedicated GitHub Actions workflow now runs the hero generator with Blender 4.2.3 and publishes four PNG review angles (front, side, back, three-quarter), the .blend source, OBJ, rig metadata and mesh-quality report. CI verifies output completeness and the 17-part rig contract. This is a reproducible technical review package, not an artistic sign-off: a human must inspect the images for silhouette, intersections, shading and appeal.


## Blender topology correction

The first real Blender visual-review run exposed two zero-area faces in the FoxHead pole caps. The head generator now creates one vertex per pole and triangle fans to the first/last latitude rings, eliminating coincident pole vertices. Source tests protect this topology strategy. The fix is not considered visually accepted until the next Blender run completes and the four renders are inspected.


## Headless render reliability

The visual-review workflow now serializes renders per branch, cancels superseded runs, forces software OpenGL with surfaceless EGL, and uses a 20-minute timeout. The currently observed render has not produced a downloadable artifact yet; visual approval remains blocked until the PNG views are available and inspected.


## CI preview render performance

For reliable headless software rendering, the four CI review views now use 768×768 output and 16 Eevee TAA render samples. This is a preview/acceptance setting intended to shorten CPU-only render time; it is not the final high-resolution art export. Final presentation renders can be produced at higher resolution after the model is visually accepted.


## First generated visual review — findings (2026-11-22)

The first successful Blender artifact contains four 768×768 PNGs, OBJ, BLEND, rig metadata and mesh report. The mesh report confirms 17 parts, UV layers, zero zero-area faces and zero non-manifold edges. This is a technical geometry pass only, not art approval.

Visual inspection found:
- The front view is upright and readable.
- Side, back and three-quarter review views are rolled, making those views unsuitable for proportion review.
- The current character reads as a simple smooth blockout with separate rounded components; it does not yet meet the requested experienced-artist finish, sculpted fur, or premium companion silhouette.

The review camera now constructs an explicit Y-up orthonormal basis with Matrix instead of relying on track_quat roll behavior. A fresh render is required to verify orientation. After that, prioritize sculptural silhouette, connected transitions, layered cheek/chest/tail forms, ear shaping, paw anatomy, and richer controlled materials. Do not mark Fox Hero art-approved until all views are inspected.


## Second review and lighting pass (2026-11-22)

A fresh artifact from commit `dc089c3` confirms the camera correction: front, side, back and three-quarter views are all upright and readable. The model is recognizable and has a friendly base silhouette, but it still reads as a smooth primitive-based blockout rather than a finished artist-authored companion. The first render is also washed out: orange fur reads pale peach and form separation is weak.

A preview lighting pass now reduces key/fill/rim power (1200/650/950 to 520/260/380) and uses AgX Medium High Contrast. This should improve color retention and form readability without changing exported geometry. A fresh render is required before judging the change. Next art pass should focus on richer orange/cream separation, layered cheek/chest/tail forms, intentional fur clumps, more expressive eye/muzzle proportions and cleaner transitions. Keep all 17 rig groups intact.


## Third art pass — palette and chest silhouette

The contrast pass did not sufficiently restore the intended orange/cream separation: the character still reads pale peach and the neck-to-body transition is too smooth. Updated the linear material palette to a deeper orange and warmer cream, with a richer inner-ear tone. Added three tapered chest-ruff plumes (center/left/right), merged into the existing FoxBelly rig group so the 17 runtime group contract remains unchanged. Source tests now lock the palette, all three ruff elements and their rig grouping.

This is a new geometry/material iteration, not an art approval. Inspect the next four-view render for chest intersections, silhouette readability and color under the preview lighting before proceeding to tail/cheek sculpting.
