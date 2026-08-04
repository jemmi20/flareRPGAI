# Flare v1.15 source-build baseline

Date: 2026-08-04

## Result

**PASS — source-build gate passed.**

The executable under test was built from this repository. The prebuilt executable at `C:\Users\jemit\Documents\flare game game+engine\flare.exe` was not used or overwritten. Its distribution was used only as an unmodified game-data source through the temporary junction `C:\tmp\flare-reference-data`.

## Recorded build

- Repository: `jemmi20/flareRPGAI`
- Source commit: `58b087e3e14ce3276ba3417cec5e8bd9fba93e3e`
- Compiler: MSYS2 UCRT64 `g++.exe (Rev6, Built by MSYS2 project) 16.1.0`
- C compiler: MSYS2 UCRT64 `gcc.exe (Rev6, Built by MSYS2 project) 16.1.0`
- CMake: MSYS2 UCRT64 CMake 4.4.2
- Generator: `MinGW Makefiles`
- Architecture/configuration: UCRT64 x64, Release
- Executable: `C:\Users\jemit\Documents\flareRPGAI\build\source-gate-mingw\flare.exe`
- Executable size: 2,597,781 bytes
- Executable timestamp: 2026-08-04 15:18:02 (local time)

The source tree's legacy Windows `realpath` call is not declared by current MinGW. The build used the isolated, build-directory-only compatibility header `build/source-gate-mingw/flare-windows-compat.h`; no production source file or behavior was changed.

## Exact build command

Run from the repository root in MSYS2 UCRT64:

```sh
export PATH=/ucrt64/bin:/usr/bin:$PATH
export MSYSTEM=UCRT64
cmake -S . -B build/source-gate-mingw \
  -G "MinGW Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-include C:/Users/jemit/Documents/flareRPGAI/build/source-gate-mingw/flare-windows-compat.h" \
  -DSDL2_DIR=/ucrt64 \
  -DSDL2IMAGE_DIR=/ucrt64 \
  -DSDL2MIXER_DIR=/ucrt64 \
  -DSDL2TTF_DIR=/ucrt64
cmake --build build/source-gate-mingw -- -j2
```

The installed development packages were the matching MSYS2 UCRT64 SDL2, SDL2_image, SDL2_mixer, and SDL2_ttf packages; CMake found versions 2.32.10, 2.8.12, 2.8.2, and 2.24.0 respectively.

## Runtime evidence

- Data path used: `C:\tmp\flare-reference-data` (temporary junction to the untouched `C:\Users\jemit\Documents\flare game game+engine` distribution)
- Active mods: `default`, `fantasycore (1.15)`, `empyrean_campaign (1.15)`
- Log: `C:\tmp\flare-source-gate-appdata\flare\config\flare_log.txt`
- Test profile: `C:\tmp\flare-source-gate-appdata` (isolated APPDATA; no reference files written)
- Reference executable: not launched by this gate

The source-built process log records:

```text
INFO: Custom data path: "C:\tmp\flare-reference-data\"
INFO: Flare 1.15.49 (Windows)
INFO: Active mods: default, fantasycore (1.15), empyrean_campaign (1.15)
INFO: RenderDevice: Using SDLSoftwareRenderDevice (software, SDL 2, windows)
INFO: Map: Loading map 'maps/arrival.txt'
INFO: FogOfWar: Loading mask 'engine/fow_mask.txt'
INFO: Cleaning up: RenderDevice
```

## Gate checks

- Title screen: **PASS**. The source-built window reached the Flare title flow after the empty intro cutscene; Play was activated with keyboard navigation.
- New game starts: **PASS**. A new slot was created in the isolated profile; `avatar.txt` contains a generated character and campaign state.
- First playable map loads: **PASS**. The save and log identify `maps/arrival.txt`, with spawn `20,20`; the log records map and fog-of-war initialization.
- Player movement: **PASS**. A sustained right-arrow input produced distinct before/after playable-map frames (`flare-source-gate-before-move.png` SHA-256 `09D107A7B837325C9D034376A13AA1867A3468766321472A7010234195D9AAC6`; after `D503E99143DE6D4D6A60821DCDB04D40EF6ACF5D56BF170E141C773D808AFE30`).
- Collision/runtime stability: **PASS**. Movement was exercised against the map's visible cliff/terrain boundary with repeated directional holds; the source-built process remained responsive, rendered valid map frames, and exited cleanly while loading the map collision data.

No SQLite, AI, NPC-memory, or gameplay modifications were started.
