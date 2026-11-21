# Giantback Asset Manifest

| Source file | Roblox MeshPart asset ID | Scale | Pivot | Studio checked | Notes |
|---|---|---|---|---|---|
| fox_companion.obj | pending import | pending | pending | no | keep tail and legs riggable |
| moth_companion.obj | pending import | pending | pending | no | keep wing groups separate |
| home_cottage.obj | pending import | pending | pending | no | static building |
| farm_bed.obj | pending import | pending | pending | no | crop visuals may be separate |
| bridge_segment.obj | pending import | pending | pending | no | snap points to be verified |
| home_island.obj | pending import | pending | pending | no | cliff/grass material split |

## Rig import notes

- The Moth source OBJ has independent left/right upper wings, lower wings, wing tips, antennae and eyes. Keep these object groups separate on import; merge only the two small static wing-root groups if desired.
- Runtime names and mapping are documented in assets/source_models/README.md. The client animator expects duplicate names for left/right animated MeshParts and determines the side from each part's local X offset.
- The Fox OBJ already separates head, muzzle, ears, four legs, tail, tail tip, eyes and nose. Keep the four legs and tail groups separate; use the explicit runtime mapping in assets/source_models/README.md before replacing the Parts-based blockout.
