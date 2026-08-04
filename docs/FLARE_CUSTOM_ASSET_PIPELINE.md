# Flare custom asset pipeline

Status: implementation specification; no final art is included.

```text
source art -> cleaned frames -> validation -> atlas/metadata
           -> Flare definitions -> isolated preview map -> smoke test
```

The source of truth is editable art plus manifests. Generated runtime files are disposable and no gameplay C++ changes are required.

## Source to cleaned frames

Artists may use Aseprite, Krita, Blender, or another tool, but export through one conversion step: preserve the editable source; convert to sRGB RGBA PNG; remove accidental matte pixels; normalize humanoids to 128x192 with pivot `(64,184)`; normalize terrain to 96x48; normalize tall objects to the declared object canvas; and write source license, creator, ID, state, direction, pivot, and dimensions to the manifest.

Reference Flare assets are inputs for study only, not production inputs.

## Validation scripts and checks

Planned scripts under `tools/assets/`:

```text
validate_frames.ps1
check_pivots.ps1
check_tilesets.ps1
build_atlases.ps1
generate_flare_animations.ps1
build_asset_preview.ps1
validate_all.ps1
```

`validate_frames.ps1` fails on non-RGBA input, wrong canvas, missing direction/frame, inconsistent counts, nontransparent required padding, pixels below the pivot, excessive bounds, missing state, or missing license metadata.

`check_pivots.ps1` validates the pivot, ground-line continuity, cropped-rectangle offset translation, shadow centering, and weapon anchor drift. A walk-frame ground contact may not jump more than 2 px. It emits a diagnostic image and never rewrites art.

`check_tilesets.ps1` validates 96x48 terrain diamonds, object bounds, atlas padding, declared footprints, collision policies, and pivots. Collision is never inferred from alpha.

## Atlas assembly

`build_atlases.ps1` consumes only cleaned frames and manifests, sorts by stable ID/state/engine direction/frame, packs with at least 2 px transparent padding, and writes versioned PNG plus JSON/YAML rectangle metadata. It preserves source hashes and generator version and rejects dimension/pivot changes without a standard or content-schema update.

The atlas layout is not a gameplay contract. Definitions always use metadata rectangles.

## Flare animation generation

`generate_flare_animations.ps1` emits:

```text
mods/jemmi_ai_world/images/characters/<id>.png
mods/jemmi_ai_world/animations/characters/<id>.txt
```

It writes `frames`, `duration`, `type`, and compressed records in the engine’s supported form:

```ini
[attack]
frames=6
duration=480ms
type=play_once
active_frame=3
frame=0,S,x,y,w,h,64,184
```

It maps `SW=0,W=1,NW=2,N=3,NE=4,E=5,SE=6,S=7`, checks all eight directions for every logical frame, validates atlas rectangles and integer offsets, and uses explicit active frames for attack timing. Compressed definitions are preferred; uncompressed definitions are diagnostic-only.

## Isolated in-engine preview

`build_asset_preview.ps1` creates a disposable preview mod, for example:

```text
mods/jemmi_asset_preview/
  settings.txt
  engine/gameplay.txt
  images/characters/
  animations/characters/
  images/tilesets/
  tilesetdefs/
  maps/asset_preview.txt
```

The map places characters on a walkable 96x48 grid and tests behind/beside/in-front positions for tall objects. It exercises idle, walk, run, attack, hit, death, interact, sit, sleep, and work states, plus collision and map depth.

The preview smoke test must confirm no missing-file/parser errors; stable eight-direction pivots; no walk/run drift; correct attack active timing; correct hit/death termination; declared collision footprints; intended occlusion; map transition; and save/load.

## CI contract

The eventual entry point is:

```powershell
pwsh -File tools/assets/validate_all.ps1 `
  -Characters art/manifests/characters `
  -Tilesets art/manifests/tilesets `
  -Output build/assets
```

It runs frame, pivot, atlas, definition, tileset, and map checks, then starts the source-built executable against isolated preview data with a temporary APPDATA/config root. It must not use the reference `flare.exe` or mutate the reference Flare Game distribution. Output is JSON plus a human report with source commit, manifest hash, generator version, and output hashes.

## Replacement workflow

Keep the stable asset ID; edit source art or manifest; run full validation and preview; generate a new atlas version and Flare definition; inspect pivot/footprint/occlusion diagnostics; run the source-built smoke test; then update the new mod’s generated files and record old/new hashes. Gameplay code refers to stable IDs and engine animation state names, never atlas coordinates or artist paths.

A changed frame count, pivot, footprint, collision policy, or interaction timing is an explicit content/schema change requiring updated tests. Ordinary art replacement remains a content-only change.

## Boundaries

This pipeline does not modify the renderer, animation parser, collision code, or map loader; does not use reference art as production art; does not introduce skeletal runtime behavior; does not infer collision from alpha; and does not generate final art.
