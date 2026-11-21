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
- Soft roughness variation on fur; restrained gloss on eyes and nose.
- No realistic individual hair strands, photoreal fur, plastic toy shine, harsh outlines, or noisy procedural speckling.
- Use warm key light, gentle fill, soft rim light and contact shadows.
- Character must remain legible without relying on bloom or post-processing.

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
