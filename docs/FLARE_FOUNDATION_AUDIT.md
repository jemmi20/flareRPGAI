# Flare v1.15 foundation audit

Audit scope: the checked-out Flare Engine source and its bundled `mods/default` fallback data. This is a read-only architecture/build audit; no production source behavior was changed. The checkout does **not** contain the official Flare Game campaign data: no `maps/`, `npcs/`, or campaign content is present. The launch gate therefore requires a separate, unmodified Flare Game v1.15 data root.

## Repository relationship

Flare Engine is the C++ runtime. Flare Game is a separate content repository whose `mods/` directory supplies a game/mod package. The engine README documents the split and the historical clone/build workflow. The engine ships `mods/default` as the fallback/core mod (including engine translations, fonts, menus, and engine config), but that is not the campaign.

The CMake target is `flare`; the source tree builds one executable from `src/*.cpp` and, on Windows, `src/Flare.rc`. The engine CMake install rule stages the executable under `BINDIR` and the engine `mods` directory under `DATADIR`.

## Exact Windows build and launch procedure

Official supported Windows development environment is MSYS2/MinGW. Install one matching architecture of SDL2, SDL2_image, SDL2_mixer, SDL2_ttf, CMake, GCC, and make. From an MSYS2 MinGW shell, the documented commands are:

```text
cmake -S <engine> -B <engine>/build/windows -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
mingw32-make -C <engine>/build/windows
```

The repository also documents MSVC through vcpkg: install `sdl2`, `sdl2-image`, `sdl2-mixer`, and `sdl2-ttf` for the selected triplet, then configure with `-DCMAKE_TOOLCHAIN_FILE=<vcpkg>\scripts\buildsystems\vcpkg.cmake`. The supplied reproducible wrapper is [`tools/build-windows.ps1`](../tools/build-windows.ps1); it supports Ninja, MinGW Makefiles, or Visual Studio 17 2022, Debug/Release, staging, and an optional launch.

Example with vcpkg/MSVC:

```powershell
.\tools\build-windows.ps1 -Generator 'Visual Studio 17 2022' -Architecture x64 -VcpkgRoot C:\src\vcpkg
```

The script intentionally does not copy or alter game content. For the first gate, launch with an unmodified game-data root:

```powershell
.\tools\build-windows.ps1 -Generator 'Visual Studio 17 2022' -Architecture x64 `
  -VcpkgRoot C:\src\vcpkg -GameRoot C:\src\flare-game -Launch -NoAudio -SafeVideo
```

## Windows runtime paths and data-path requirements

`PlatformWin32.cpp` sets both config and user-data roots to `%APPDATA%\flare` when `APPDATA` exists, creating:

```text
%APPDATA%\flare\config\        settings.txt, mods.txt, custom_data_path.txt
%APPDATA%\flare\userdata\     saves and user overrides
%APPDATA%\flare\userdata\mods\ user-installed/overriding mods
%APPDATA%\flare\userdata\saves\
```

If `APPDATA` is unavailable, the fallback is relative `config\` and `userdata\` beside the process working directory. `PATH_DATA` is empty on Windows unless `--data-path=<PATH>` is supplied; a custom path must exist. The executable searches user data first and the configured/system data path second. The engine fallback is found in `mods/default` under one of those data roots.

`--data-path=<PATH>` selects an exact data root. `--save-data-path` persists it in `config/custom_data_path.txt`; `--ignore-data-path` bypasses the saved value for one run; `--clear-data-path` removes it. Use `--renderer=sdl` and `--no-audio` for a deterministic compatibility smoke run.

## Save architecture

Saves are plain INI-style text, not a database or binary blob. `SaveLoad` writes under `%APPDATA%\flare\userdata\saves\<save_prefix>\<slot>\`, where `save_prefix` comes from the active mod's `engine/misc.txt` and prevents collisions between games. The principal file is `avatar.txt`; stash tabs are separate files, with private stash files nested by slot and shared stash files at the prefix level. Extended randomized/foreign item state is in `extended_items.txt`; optional fog-of-war state is map-specific cache data.

`avatar.txt` stores identity/permadeath, appearance/class, XP, optional HP/MP, stats/build, currency, equipment/carried inventories and quantities, spawn map/position, action bar, powers/transformation, campaign status serialization, play time, engine version, vendor buyback, quest-log dismissal, and stash tab. Saves are automatically triggered according to `engine/misc.txt` (`save_onload`, `save_onexit`, map/cutscene/stash settings); the actual files are created on save. Load validates IDs and bounds, warns on engine-version mismatch, and falls back to `maps/spawn.txt` if the saved map is unavailable.

## NPC/entity architecture

`Entity` is the common runtime character object for the player, allies, enemies, and NPCs. It owns a `StatBlock`, animation/sound state, collision-facing movement, and an `EntityBehavior` component. `EntityManager` loads entity prototypes from stat/animation data, instantiates map entities, handles map transitions, and processes queued/power/event spawns.

`NPC` derives from `Entity`. `NPCManager` owns map NPC instances and creates them from map `filename` references. NPC definition files are simple config files under `npcs/`: base identity/portrait/talker/vendor settings, stats, inventories/vendor stock, voice files, and repeated `[dialog]` sections. Map NPC objects add position, direction, requirements, waypoints, and optional wandering.

Enemies can be declared as map groups or spawned by events/powers. Entity collision occupancy is registered in `MapCollision`; ally/enemy flags affect blocking and AI targeting. Dialog-active NPCs are explicitly prevented from acting by `EntityBehavior`.

## Map format

Maps are Flare's INI-style text format, normally authored with Tiled and Flare Tiled Tools, then exported to text. `Map::load` parses `[header]`, repeated `[layer]`, `[enemy]`, `[npc]`, and `[event]` sections. Header data includes title, width/height, tileset, hero spawn, music, background/parallax, fog-of-war, and procedural-generation settings. Layers contain named, width-by-height tile grids; a `collision` layer is required and synthesized if absent. Map objects become enemy groups, NPCs, or events.

Events are data-driven and can trigger on load, trigger/interact, leave, map exit, clear, or continuously. Components cover teleports, tile edits, status/item/currency/XP effects, loot, powers, spawns, NPC dialogue, cutscenes, scripts, saves, and requirements. Procedural maps use event-declared generation rules and may write a generated map cache through `MapSaver`; fog-of-war can also be cached per map.

## Movement and pathfinding flow

Keyboard/controller movement feeds the avatar's desired movement into `MapCollision::move`, which advances in tile-boundary-sized substeps and attempts wall sliding. Validity is determined by the collision layer, movement type (normal/flying/intangible), and entity collision type. Continuous movement uses floating-point positions centered in integer map tiles.

Mouse movement and AI can request a path. `MapCollision::computePath` converts the floating-point endpoints to tile coordinates, temporarily unblocks a blocking target, and runs bounded A* over 8-neighbor `AStarNode`s. It returns waypoints in reverse traversal order; `Avatar`/`EntityBehavior` pop waypoints, recalculate when blocked or the target changes, and back off after repeated failures. The default path exploration limit is `DEFAULT_PATH_LIMIT` or 10% of map area when zero. Line-of-sight and line-of-movement checks use sampled collision rays.

## Dialogue system

NPC `[dialog]` sections are ordered event-component streams. Text components are `him`/`her` and `you`; `topic` labels a selectable node; `id` names it; `response` links selectable response nodes; `response_only` hides a node from the primary topic list. Portraits, voice, movement permission, party changes, and the full event component vocabulary can be mixed into the same node.

`MenuTalker` presents the primary topics, executes a selected node, advances an event cursor through that node, executes embedded events, and then returns to the topic list or closes. Requirements/statuses and random dialog groups are resolved by `NPC`; one-node conversations can auto-select on first interaction. Vendor access is a sibling action in the talker UI, not a dialog response. Map event `npc=<filename>` can initiate an NPC conversation without a placed map NPC.

## Mod-loading boundaries

`ModManager` always starts with the `default` fallback if available. It reads mod names from `[PATH_CONF]/mods.txt`, falling back to `[PATH_DATA]/mods/mods.txt`, unless `--mods=a,b,...` supplies the list. Later active mods override earlier ones. Lookup order is latest active mod to earliest, and for each mod user data paths precede the configured data path; `locate()` returns the first matching file while `list()` aggregates files for append/merge-style consumers.

Each mod may declare `settings.txt` metadata (`game`, version, dependencies, engine min/max) and `engine/gameplay.txt` (`enable_playgame`). Dependencies are inserted/validated, incompatible game IDs and engine versions are skipped. The engine loads only recognized data files and event components; mods cannot add native C++ behavior or replace the executable. They can override/append supported config, images, audio, maps, NPCs, scripts/events, menus, translations, and other documented content files. `--data-path` changes the data root; it does not change the executable or save root.

## Gate status

The requested first gate is **not passed in this environment**. Two independently verified prerequisites are missing: this checkout has no Flare Game campaign maps/NPC data, and the Windows host has CMake but no Ninja, MinGW make/GCC, or MSVC compiler available on `PATH`. The wrapper fails at configure rather than producing an unverified executable. Run it with a provisioned toolchain and `-GameRoot` pointing at the extracted Flare Game v1.15 root, then apply the checklist. A valid pass requires the source-built executable to reach the title screen and load the game's first map while using that untouched data root.
