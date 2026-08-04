# Jemmi Tileset Standard v1

Status: specification only; no final art is included.

## Engine facts versus project choices

| Topic | Engine fact | Jemmi v1 choice |
|---|---|---|
| Perspective | Engine supports isometric and orthogonal. | Isometric only for the first slice. |
| Runtime grid | `engine/tileset_config.txt` supplies positive `tile_size`. | `tile_size=96,48`, a 2:1 diamond. |
| Map header | `tilewidth`/`tileheight` are inherited from Tiled and ignored by `Map::load`. | Write 96/48 for authoring clarity, but validate runtime config separately. |
| Collision | Values 0..8 have engine meanings. | Use documented values and require an explicit collision layer. |
| Tiled | Engine README supports Tiled plus Flare Tiled Tools. | Keep `.tmx` sources separate from generated Flare `.txt`. |

The 96x48 scale is a Jemmi choice, deliberately not copied from the reference game’s 192x96 art. Changing it requires a new standard version.

## Dimensions and object bounds

Terrain tiles are exactly `96x48` and contain no pixels outside the diamond unless classified as an overlay. Test all four edges and 2x2 transitions.

Recommended tall-object authoring cell:

```text
object cell: 96 x 192
ground diamond: x=0..95, y=144..191
visual bounds: x=4..91, y=8..184
ground pivot: (48,184)
```

Large buildings may use larger atlas rectangles and multiple map cells, but must declare a footprint and pivot. These are authoring conventions, not parser limits.

## Collision footprints

Collision is independent of pixels:

| Value | Engine meaning | Village use |
|---:|---|---|
| 0 | `BLOCKS_NONE` | roads, floors, passable terrain |
| 1 | `BLOCKS_ALL` | walls, closed doors, solid building mass |
| 2 | `BLOCKS_MOVEMENT` | water or special movement blockers |
| 3/4 | hidden blocking variants | use only when intentionally hidden |
| 5/6 | map-only variants | map-specific rules |
| 7/8 | entity occupancy | dynamic entity blocking |

Fences use the occupied edge, furniture the floor-facing base, and roofs normally have no collision. Every object manifest records `footprint_tiles`, `anchor_tile`, and `collision_policy`; alpha does not imply collision.

## Building and occlusion organization

```text
foundation/walls  collision-bearing lower mass
doors/windows     interaction or wall components
interior floor    walkable ground
roof/upper facade visual occlusion layer
smoke/signs/lights optional high visual layer
furniture         visual plus local collision
```

Keep roofs separate so they can be hidden or cut away without changing gameplay. Tall visual pixels may overlap nearby tiles and actors, but depth uses the base/pivot, not the top of the image. Preview a character behind, beside, and inside each building.

## Directory and atlas layout

```text
art/source/tilesets/<family>/<asset_id>.png
art/clean/tilesets/<family>/<asset_id>.png
art/atlas/tilesets/<family>_v001.png
art/atlas/tilesets/<family>_v001.json
art/manifests/tilesets/<family>.yaml
mods/jemmi_ai_world/images/tilesets/<family>_v001.png
mods/jemmi_ai_world/tilesetdefs/<family>.txt
mods/jemmi_ai_world/maps/
```

Use lowercase snake case and immutable atlas versions. Metadata includes rectangle, source ID, pivot, footprint, collision, occlusion class, license, and SHA-256. Atlas padding is at least 2 px.

Exterior, interior, and shared props use separate families unless palette, scale, pivot, and license are identical. Suggested families are `village_exterior`, `village_interior`, and `shared_props`.

## Tiled export contract

Author Tiled maps as isometric 96x48 maps. Keep `.tmx` and source tilesheet metadata under `art/tiled/` or `tiled/`; generated maps belong under the mod’s `maps/` directory. Required layer names are `ground`, `roads`, `water`, `objects_low`, `objects_high`, and `collision`.

The generated Flare map begins like this:

```ini
[header]
width=<width>
height=<height>
tilewidth=96
tileheight=48
orientation=isometric
tileset=tilesetdefs/<family>.txt
hero_pos=<x>,<y>

[layer]
type=ground
data=...
[layer]
type=collision
data=...
```

Validate every layer row count, row width, tile-ID bound, layer name, spawn, and exit. Do not rely on the engine’s collision-layer synthesis. `MapSaver` currently writes 64x32 header values for procedural output; it is not the authored source of truth and must be post-validated if used later.

## Manifest example

```yaml
id: village_house_wall_a
family: village_exterior
source: art/source/tilesets/village_exterior/village_house_wall_a.png
atlas: village_exterior_v001
anchor_tile: [0, 1]
footprint_tiles: [[0, 1], [1, 1]]
occlusion: roof_high
collision: solid
license: jemmi-original
```
