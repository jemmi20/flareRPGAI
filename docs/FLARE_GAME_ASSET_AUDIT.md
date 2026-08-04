# Flare Game v1.15 reference asset audit

Audit date: 2026-08-04

Reference root inspected read-only:

`C:\Users\jemit\Documents\flare game game+engine`

The reference distribution was not modified. No `jemmi_ai_world` was created.

## Scope and classification

This is an inventory of files that are present in the working Flare Game v1.15 distribution, not a list of features supported by the engine.

- **directly reusable**: the reference data contains the required file and its format can be used by a separate Flare mod, subject to attribution and ShareAlike obligations.
- **acceptable prototype placeholder**: usable for a prototype but visibly generic, incomplete for the intended production role, or tightly coupled to the reference campaign.
- **unsuitable**: present but wrong for the requested village slice.
- **missing**: no matching asset was found in the inspected data.

## Repository and mod boundaries

The distribution contains four mods:

```text
mods/default
mods/fantasycore
mods/empyrean_campaign
mods/centered_statbars
```

`fantasycore` is the shared content layer. `empyrean_campaign` supplies the campaign-specific maps, NPC definitions, dialogue, quests, and additional ruins art. `default` is engine support content. `centered_statbars` is a UI override. A separate game should add a new mod and declare its dependencies/ordering; it should not edit `fantasycore` or `empyrean_campaign` in place.

The actual game data uses simple INI-like text files and exported isometric map text. For example, `mods/empyrean_campaign/maps/black_oak_city.txt` contains `width=100`, `height=100`, `tilewidth=192`, `tileheight=96`, `orientation=isometric`, a `tileset=tilesetdefs/tileset_grassland.txt` reference, `[layer]` sections containing comma-separated tile IDs, and `[event]`, `[enemy]`, and `[npc]` sections. The same structure is used by `black_oak_farm.txt`, `goblin_camp.txt`, and `lochport.txt`.

## 1. Tilesets and decoration assets

### Runtime tileset images and definitions

| Area | Exact files | Classification | Evidence / limits |
|---|---|---|---|
| Grassland, roads, terrain, water, vegetation, structures | `mods/fantasycore/images/tilesets/tileset_grassland.png`; `tileset_grassland_water.png`; `mods/fantasycore/tilesetdefs/tileset_grassland.txt` | directly reusable | The definition contains terrain tiles and large structure/decor tile rectangles. The campaign maps use this tileset. |
| Cave and underground surfaces | `mods/fantasycore/images/tilesets/tileset_cave.png`; `mods/fantasycore/tilesetdefs/tileset_cave.txt` | acceptable prototype placeholder | Suitable for caves, not village exteriors. |
| Dungeon floors, walls, doors, interior-like decoration | `mods/fantasycore/images/tilesets/tileset_dungeon.png`; `mods/fantasycore/tilesetdefs/tileset_dungeon.txt` | directly reusable | Good source for generic interiors and dungeon furniture-like objects; it is not a complete furnished house kit. |
| Snow terrain | `mods/fantasycore/images/tilesets/tileset_snowplains.png`; `tileset_snowplains_ice.png`; `tileset_snowplains_other.png`; `tileset_snowplains_water.png`; corresponding files in `mods/fantasycore/tilesetdefs/` | unsuitable for first temperate village slice | Present, but wrong biome unless the village is snow-themed. |
| Campaign ruins | `mods/empyrean_campaign/images/tilesets/tileset_ruins.png` | acceptable prototype placeholder | Useful ruined structures and masonry; not a coherent intact village kit. |

The grassland map export explicitly references the following decoration sheets under the source/export tree:

```text
../../../tiled/tilesheets/tiled_collision.png
../../../tiled/tilesheets/grassland.png
../../../tiled/tilesheets/grassland_water.png
../../../tiled/tilesheets/grassland_structures.png
../../../tiled/tilesheets/grassland_trees.png
../../../tiled/tilesheets/tiled_set_rules.png
../../../tiled/tilesheets/grassland_2x2.png
```

`black_oak_city.txt` also references `grassland_rottentower.png`. These are real map references in the reference data, not inferred engine capabilities. The runtime-facing packed tileset definitions use `images/tilesets/tileset_grassland.png` and related images.

### Requested village categories

| Requested use | Finding | Classification |
|---|---|---|
| Village exteriors | Grassland terrain plus structure and tree sheets; demonstrated by Black Oak City/Farm | directly reusable as a base |
| Houses | Structure tiles are present and used by settlement maps, but no isolated, documented house-kit directory was found | acceptable prototype placeholder |
| Shops | No dedicated shop exterior/interior tileset was found. Merchant NPCs exist, but merchant buildings are map compositions | missing as a dedicated kit; use existing structure tiles provisionally |
| Roads | Grassland terrain/road compositions are present in settlement maps | directly reusable |
| Fences | No filename or standalone fence set was found; fence-like map decoration may be embedded in the structure sheet | acceptable prototype placeholder until tile IDs are catalogued visually |
| Farms | `black_oak_farm.txt` is a real farm map using grassland structures/terrain | directly reusable as a map reference/prototype |
| Interiors | Dungeon, stronghold, tower, crypt, and temple map tiles are present | acceptable prototype placeholder for village interiors |
| Furniture | No dedicated furniture asset directory or furniture tileset was found. Interior decoration is embedded in broad dungeon/structure sheets | missing as a coherent reusable furniture set; generic placeholders are acceptable |

## 2. Humanoid and NPC sprite sets

### Appearance files found

The main humanoid NPC sheets are:

```text
mods/fantasycore/images/npcs/guild_man.png
mods/fantasycore/images/npcs/knight.png
mods/fantasycore/images/npcs/peasant_man1.png
mods/fantasycore/images/npcs/peasant_man2.png
mods/fantasycore/images/npcs/peasant_woman1.png
mods/fantasycore/images/npcs/peasant_woman2.png
mods/fantasycore/images/npcs/wandering_trader.png
```

Obelisk sheets also exist (`return_obelisk1.png`, `return_obelisk2.png`) but are not humanoid civilians. Campaign NPC files add portraits and role/dialogue definitions, not new civilian animation sets.

The player/avatar appearance system is layered male/female art under:

```text
mods/fantasycore/images/avatar/male/
mods/fantasycore/images/avatar/female/
mods/fantasycore/images/avatar/male_dark/
mods/fantasycore/images/avatar/female_dark/
```

It includes heads, default body parts, cloth/leather/chain/plate equipment, shields, and weapons. These are player equipment layers, not proof of matching civilian work animations.

### NPC animation definitions

| Appearance | Exact animation definition | Defined animations / frames | Directional finding | Classification |
|---|---|---|---|---|
| Guild man | `mods/fantasycore/animations/npcs/guild_man.txt` | `stance`, 12 frames | The engine hard-codes 8 directions; the file has direction-indexed frame records | acceptable prototype placeholder |
| Guild man variants | `guild_man1.txt`, `guild_man2.txt` | `INCLUDE animations/npcs/guild_man.txt` | Same animation set | acceptable prototype placeholder |
| Knight | `mods/fantasycore/animations/npcs/knight.txt` | `stance`, 4 frames | 8-direction sheet layout | acceptable prototype placeholder |
| Peasant man 1/2 | `peasant_man1.txt`, `peasant_man2.txt` | `stance`, 4 frames each, `duration=1600ms`, `type=back_forth` | 8 direction rows are represented by the `frame=index,direction,...` records | directly reusable for idle civilians; missing for full behavior |
| Peasant woman 1/2 | `peasant_woman1.txt`, `peasant_woman2.txt` | `stance`, 4 frames each, `duration=1600ms`, `type=back_forth` | 8-direction layout | directly reusable for idle civilians; missing for full behavior |
| Wandering trader | `wandering_trader.txt` | `stance`, 6 frames | 8-direction layout | acceptable prototype placeholder |

The representative peasant definition points to `images/npcs/peasant_man1.png` and contains only `[stance]`. The NPC definitions used by merchants point to these civilian animation files; for example `mods/empyrean_campaign/npcs/florin.txt` uses `animations=animations/npcs/peasant_man1.txt`.

### Requested animation coverage

The player animation set is complete enough for combat:

```text
mods/fantasycore/animations/hero.txt
  stance  4 frames, 800ms, back_forth
  run     8 frames, 533ms, looped
  swing   4 frames, 400ms, play_once
  block   2 frames, 66ms, play_once
  hit     2 frames, 133ms, play_once
  die     6 frames, 800ms, play_once
  cast    4 frames, 400ms, play_once
  shoot   4 frames, 400ms, play_once
```

For the humanoid NPC files listed above, the inspected definitions provide only `stance`. No civilian-specific `run`, `walk`, `swing`, `block`, `hit`, `die`, farming, smithing, shopkeeping, carrying, or other work animation was found in those files. Enemy animation files do contain combat/death states, but they are unsuitable substitutes for civilian work:

```text
mods/fantasycore/animations/enemies/
```

Therefore:

- idle/stance civilians: **directly reusable**;
- eight-direction coverage: **present in the actual NPC sheet format**;
- walking animations for those civilian sets: **missing**;
- civilian combat animations: **missing**;
- civilian hit/death animations: **missing**;
- civilian/work animations: **missing**;
- player combat animation set: **directly reusable**, but it is not an NPC work set.

## 3. Existing maps with relevant examples

### Settlements and exteriors

```text
mods/empyrean_campaign/maps/black_oak_city.txt    title=Black Oak City
mods/empyrean_campaign/maps/black_oak_farm.txt    title=Black Oak Farm
mods/empyrean_campaign/maps/lochport.txt          title=Lochport
mods/empyrean_campaign/maps/stonewood.txt         title=Stonewood
mods/empyrean_campaign/maps/perdition_harbor.txt  title=Perdition Harbor
mods/empyrean_campaign/maps/fort_amir.txt         title=Fort Amir
mods/empyrean_campaign/maps/fort_nasu.txt         title=Fort Nasu
```

`black_oak_city.txt` and `black_oak_farm.txt` are the strongest village-prototype references because they use the grassland tileset and contain structures, paths, map transitions, and event/entity sections. `black_oak_city.txt` transitions to `maps/black_oak_farm.txt`; the farm transitions back to the city.

### Camps and civilian/merchant examples

```text
mods/empyrean_campaign/maps/goblin_camp.txt
mods/empyrean_campaign/maps/arrival.txt
mods/empyrean_campaign/maps/stonewood.txt
```

`goblin_camp.txt` contains an actual `[npc]` block for `npcs/abasi.txt`. `abasi.txt` is a vendor and includes merchant stock. Other real merchant definitions include:

```text
mods/empyrean_campaign/npcs/florin.txt       Florin, Apothecary
mods/empyrean_campaign/npcs/yora.txt         Yora, Enchanter
mods/empyrean_campaign/npcs/udana.txt        Udana, Metalworker
mods/empyrean_campaign/npcs/loren.txt        Loren, Undead Trader
mods/empyrean_campaign/npcs/abasi.txt        traveling merchant
mods/empyrean_campaign/npcs/bakat.txt        goblin packrat/vendor
```

The map files use `[npc]`, `[enemy]`, and `[event]` sections. NPC placement uses fields such as `type=npc`, `location=x,y,w,h`, `filename=npcs/...`, and status requirements. There is no separate NPC database or skeletal entity format in the data.

### Interiors and buildings

The distribution has interior-like maps, but they are mostly dungeon/fortress/crypt spaces rather than domestic village interiors:

```text
mods/empyrean_campaign/maps/underworld_stronghold_1.txt
mods/empyrean_campaign/maps/underworld_stronghold_2.txt
mods/empyrean_campaign/maps/wizards_tower_1.txt
mods/empyrean_campaign/maps/wizards_tower_2.txt
mods/empyrean_campaign/maps/wizards_tower_3.txt
mods/empyrean_campaign/maps/temple_of_mez_1.txt
mods/empyrean_campaign/maps/temple_of_mez_2.txt
mods/empyrean_campaign/maps/temple_of_mez_3.txt
mods/empyrean_campaign/maps/st_maria_1.txt
mods/empyrean_campaign/maps/st_maria_2.txt
mods/empyrean_campaign/maps/st_maria_3.txt
mods/empyrean_campaign/maps/iron_labyrinth_f1.txt
mods/empyrean_campaign/maps/iron_labyrinth_f2.txt
mods/empyrean_campaign/maps/iron_labyrinth_f3.txt
```

Classification: **acceptable prototype placeholder** for an interior layout study; a furnished house/shop interior is **missing** as a purpose-built example.

## 4. Licensing and reuse

The reference `README.md` states:

- Flare Engine: GPL version 3 or later.
- Flare game art and data: CC-BY-SA 3.0, with later versions permitted.
- Liberation, Bona Nova SC, Noto, and Marck Script fonts: SIL Open Font License 1.1.

The same distribution includes `COPYING`, `LICENSE.txt`, `CREDITS.txt`, and `CREDITS.engine.txt`. `CREDITS.txt` lists contributors and directs readers to the per-file credits. This supports reuse of the Flare Game art/data in a separate original Flare-engine game, provided attribution and CC-BY-SA ShareAlike terms are carried forward and the separate game does not imply ownership of the original art. The engine code remains GPLv3-or-later.

For production shipping, retain a copy of the relevant license and credits files, preserve attribution, and verify any third-party additions against the per-file credits. The classification “directly reusable” here means license-compatible in principle; it is not a substitute for a legal review or per-asset provenance audit.

## Contact sheet

A raster contact sheet was attempted from the selected reference PNGs, but the available Windows `System.Drawing` runtime could not construct the composite bitmap in this environment. No reference files were copied or altered. Representative image paths are listed above; the most useful files to preview manually are:

```text
mods/fantasycore/images/npcs/peasant_man1.png
mods/fantasycore/images/npcs/peasant_woman1.png
mods/fantasycore/images/npcs/guild_man.png
mods/fantasycore/images/npcs/knight.png
mods/fantasycore/images/tilesets/tileset_grassland.png
mods/fantasycore/images/tilesets/tileset_dungeon.png
mods/empyrean_campaign/images/tilesets/tileset_ruins.png
```

## Missing-assets list for the first village vertical slice

The first village slice should budget for these additions rather than assuming the reference game already supplies them:

1. A cohesive village tileset or documented tile-ID catalog covering intact house walls/roofs, shop fronts, doors, windows, roads, fences, farm plots, wells, signs, and street clutter.
2. A small furnished house/shop interior kit: floors, walls, counters, shelves, beds, tables, chairs, chests, barrels, lamps, ovens, and workbenches.
3. Civilian walking animations for each selected appearance, with all eight directions.
4. Civilian work loops: farming, sweeping, carrying, smithing, chopping, cooking, reading, and shopkeeping.
5. Optional civilian hit/death/combat sets if villagers can be attacked; the existing enemy sets are not a suitable replacement for a civilian style.
6. Distinct guard/merchant/work clothes if visual role readability matters; current humanoid NPC appearances are limited to generic peasants, guild man, knight, and trader sheets.
7. Village-specific signs, portraits, and role props, unless generic campaign assets are intentionally accepted as placeholders.
8. A new village map and NPC placement data under the new mod, including collision/obstacle layers, intermap exits, dialogue files, and any required portraits or vendor definitions.

No village was created by this audit.
