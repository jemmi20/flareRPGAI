# Jemmi Sprite Standard v1

Status: specification only; no final art is included. This defines original art for a new Flare game and does not require matching Flare Game v1.15 art.

## Engine facts versus project choices

| Topic | Engine fact | Jemmi v1 choice |
|---|---|---|
| Directions | `DIRECTIONS=8` is hard-coded. | Artist order: `S, SW, W, NW, N, NE, E, SE`; exporter maps it to engine indexes. |
| Pixel size | Animation parser imposes no fixed pixel canvas. | Humanoid frame: 128x192 RGBA. |
| Pivot | `render_offset` is subtracted from the map-screen point; it is the virtual floor point. | Bottom-center pivot `(64,184)`, with transparent clearance below. |
| Playback | `play_once`, `looped`, `back_forth`. | Idle back/forth; locomotion/work looped; actions play once. |
| Definitions | Uncompressed grids and compressed `frame=` records. | Normalize frames, assemble an atlas, emit compressed records. |
| Layering | No general skeletal compositor. | Fixed aligned raster layers only. |

All dimensions and counts below are project choices, not engine requirements.

## Canvas and pivot

Every normalized humanoid frame is `128x192`. `(0,0)` is top-left; ground contact is `(64,184)`. Feet may touch but not extend below `y=184`. Normal visible bounds are `x=16..112`, `y=8..184`. Transparent padding is intentional and must remain identical across all frames in a state/layer. A cropped atlas rectangle must translate the pivot instead of changing the world position. Full-canvas compressed records use `offsetx=64,offsety=184`.

The pivot is navigation/collision position, not the visual center. Collision is authored separately from alpha pixels.

## Direction mapping

| Engine index | Direction |
|---:|---|
| 0 | SW |
| 1 | W |
| 2 | NW |
| 3 | N |
| 4 | NE |
| 5 | E |
| 6 | SE |
| 7 | S |

This is the engine parser’s actual mapping. Artist files use `s`, `sw`, `w`, `nw`, `n`, `ne`, `e`, `se`; manifests are authoritative over atlas row order.

## Animation contract

Counts are per direction.

| State | Frames | Duration | Type | Requirement |
|---|---:|---:|---|---|
| `idle` | 4 | 1200ms | `back_forth` | required |
| `walk` | 8 | 640ms | `looped` | required |
| `run` | 8 | 480ms | `looped` | runners |
| `attack` | 6 | 480ms | `play_once` | combatants |
| `hit` | 3 | 180ms | `play_once` | damageable actors |
| `death` | 8 | 800ms | `play_once` | actors that die |
| `interact` | 4 | 360ms | `play_once` | visible interactions |
| `sit` | 2 | held | held/play once | reserved optional |
| `sleep` | 4 | 1600ms | `back_forth` | reserved optional |

Work extends the contract with `work_<verb>` IDs such as `work_farm`, `work_sweep`, `work_carry`, `work_smith`, `work_cook`, `work_read`, and `work_shop`. Work timing and active frames are manifest data; names never cause gameplay effects.

## Names, sheets, and layers

```text
art/source/characters/<character_id>/<layer>/<state>/<direction>_<frame>.png
art/clean/characters/<character_id>/<layer>/<state>/<direction>_<frame>.png
art/atlas/characters/<character_id>.png
mods/jemmi_ai_world/images/characters/<character_id>.png
mods/jemmi_ai_world/animations/characters/<character_id>.txt
tools/assets/manifests/characters/<character_id>.yaml
```

Use lowercase snake case and stable semantic IDs. A preview sheet may use 8 direction rows and frames left-to-right. Atlas padding is at least 2 transparent pixels. Layer order is `shadow`, `body`, `clothing`, `hair`, `equipment`, `weapon`, `fx`; all layers share canvas, direction, state, frame count, timing, and pivot. Missing layers are transparent frames.

Shadows are separate, nominally `48x16` centered at `(64,184)`, and never part of body collision. Manifest anchors are `grip_primary`, `grip_secondary`, `weapon_tip`, and `shield_center`; approved attack anchor drift is at most 2 px.

## Flare definition mapping

The generator emits one `frame=` record for each logical frame and engine direction:

```ini
image=images/characters/villager_mara.png
[idle]
frames=4
duration=1200ms
type=back_forth
frame=0,S,x,y,w,h,64,184
```

Compressed format is preferred because it supports per-frame atlas rectangles and pivots. The generator rejects missing directions, indexes outside `0..frames-1`, rectangles outside the atlas, and inconsistent state counts. Attack impact is explicit with `active_frame`; it is never inferred from artwork.
