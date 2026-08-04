# Flare v1.15 Windows smoke-test checklist

Run from the engine repository root. Keep the Flare Game v1.15 data untouched; use a separate writable user profile if testing saves.

## Build and launch gate

- [ ] Confirm CMake and the selected toolchain are installed; confirm SDL2, SDL2_image, SDL2_mixer, and SDL2_ttf development packages match the target architecture.
- [ ] Confirm the game root contains `mods/` and the game mod's `settings.txt`; for campaign launch, confirm it also contains map data such as `maps/spawn.txt`.
- [ ] Build with [`tools/build-windows.ps1`](../tools/build-windows.ps1), using `-GameRoot <unmodified flare-game root> -Launch -NoAudio -SafeVideo`.
- [ ] Confirm `flare.exe` is source-built and the process starts without a missing-DLL or missing-data error.
- [ ] Confirm the title screen renders and the first/new-game flow loads the first map.
- [ ] Confirm the player avatar appears at a valid spawn position and the HUD renders.

## Runtime/data-path checks

- [ ] Confirm the log reports the intended data path and that the active core/game mods are the expected ones.
- [ ] Confirm `%APPDATA%\flare\config\settings.txt` and `%APPDATA%\flare\userdata\` are created (or verify the documented relative fallback when `APPDATA` is absent).
- [ ] Confirm `--data-path=<PATH>` launches using that path and does not require copying game data into the engine tree.
- [ ] Confirm `--renderer=sdl --no-audio --safe-video` is usable on compatibility hardware.

## Minimum gameplay smoke

- [ ] Move in four cardinal directions and diagonals; verify collision against a wall and that the player cannot leave the map.
- [ ] Use mouse movement if enabled; verify a blocked route does not hang the game.
- [ ] Interact with one placed NPC and one event-triggered NPC, if the game data provides both.
- [ ] Advance a multi-line dialog and select a response; verify the topic list returns and movement lock is released.
- [ ] Enter/exit a map transition and verify the avatar and party spawn correctly.
- [ ] Trigger one enemy encounter and verify entity movement/collision and combat remain responsive.

## Save/load checks

- [ ] Start a new game, save/exit using the normal UI, and verify files appear below `%APPDATA%\flare\userdata\saves\`.
- [ ] Reload the slot and verify map, spawn, class, inventory, campaign status, and action bar restore.
- [ ] If the game uses vendors/stashes, change stock and verify the relevant stash/buyback files persist.
- [ ] Verify a missing saved map falls back to `maps/spawn.txt` rather than crashing.

## Evidence to record

- [ ] CMake generator, compiler version, architecture, configuration, and exact command line.
- [ ] Source commit, game-data commit/archive checksum, executable path, and data path.
- [ ] `flare.log`/console output and screenshots of title screen plus first map.
- [ ] Result: **PASS** only when a source-built executable launches the unmodified Flare Game data and loads its first map; otherwise record the first failing step and do not call the gate passed.
