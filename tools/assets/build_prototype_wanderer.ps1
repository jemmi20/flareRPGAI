[CmdletBinding()]
param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot '..\..\art\source\characters\prototype_wanderer\flattened'),
    [switch]$DiagnosticPlaceholders,
    [switch]$Clean,
    [switch]$Launch,
    [int]$LaunchSeconds = 10
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Drawing

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$character = 'prototype_wanderer'
$manifestPath = Join-Path $repo 'tools\assets\manifests\characters\prototype_wanderer.json'
$buildRoot = Join-Path $repo 'build\prototype-wanderer'
$atlasPath = Join-Path $buildRoot 'prototype_wanderer.png'
$atlasMetaPath = Join-Path $buildRoot 'prototype_wanderer.atlas.json'
$definitionPath = Join-Path $buildRoot 'prototype_wanderer.txt'
$previewRoot = Join-Path $repo 'build\prototype-wanderer-preview-data'
$previewMod = Join-Path $previewRoot 'mods\jemmi_asset_preview'
$directionsArtist = @('s','sw','w','nw','n','ne','e','se')
$directionsEngine = @('SW','W','NW','N','NE','E','SE','S')
$states = [ordered]@{ idle = 4; walk = 8 }

function Fail([string]$Message) { throw "prototype_wanderer: $Message" }

function New-DiagnosticFrames {
    if (Test-Path $SourceRoot) {
        $existing = Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -ErrorAction SilentlyContinue
        if ($existing) { Fail "diagnostic mode will not overwrite existing source frames: $SourceRoot" }
    }
    foreach ($state in $states.Keys) {
        foreach ($direction in $directionsArtist) {
            $dir = Join-Path $SourceRoot "$state\$direction"
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            for ($frame = 0; $frame -lt $states[$state]; $frame++) {
                $path = Join-Path $dir ("{0:D2}.png" -f $frame)
                $bmp = New-Object System.Drawing.Bitmap(128,192,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
                $g = [Drawing.Graphics]::FromImage($bmp)
                $g.Clear([Drawing.Color]::Transparent)
                $hue = [Array]::IndexOf($directionsArtist,$direction) * 28
                $color = [Drawing.Color]::FromArgb(255,(80 + $hue) % 220,120,190)
                $bob = if ($state -eq 'idle') { $frame % 2 } else { $frame % 3 }
                $g.FillEllipse((New-Object Drawing.SolidBrush($color)),52,(54-$bob),24,30)
                $g.FillRectangle((New-Object Drawing.SolidBrush($color)),48,(82-$bob),32,56)
                $g.FillRectangle([Drawing.Brushes]::White,52,(138-$bob),9,46)
                $g.FillRectangle([Drawing.Brushes]::White,67,(138-$bob),9,46)
                if ($state -eq 'walk' -and ($frame % 2 -eq 1)) {
                    $g.FillRectangle([Drawing.Brushes]::White,47,(177-$bob),14,8)
                    $g.FillRectangle([Drawing.Brushes]::White,68,(169-$bob),14,8)
                }
                $g.Dispose()
                $bmp.Save($path,[Drawing.Imaging.ImageFormat]::Png)
                $bmp.Dispose()
            }
        }
    }
    Write-Host "Created diagnostic-only placeholder frames under $SourceRoot" -ForegroundColor Yellow
}

function Read-Manifest {
    if (!(Test-Path $manifestPath)) { Fail "manifest missing: $manifestPath" }
    $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($m.character_id -ne $character) { Fail "manifest character_id must be $character" }
    if ($m.layer -ne 'flattened') { Fail 'prototype must use the flattened layer' }
    if ($m.canvas.width -ne 128 -or $m.canvas.height -ne 192) { Fail 'canvas must be 128x192' }
    if ($m.pivot.x -ne 64 -or $m.pivot.y -ne 184) { Fail 'pivot must be 64,184' }
    if ($m.directions.Count -ne 8) { Fail 'manifest must declare eight directions' }
    return $m
}

function Test-Frame([string]$Path, $Manifest) {
    if (!(Test-Path $Path)) { Fail "missing frame: $Path" }
    $img = [Drawing.Image]::FromFile($Path)
    try {
        if ($img.Width -ne 128 -or $img.Height -ne 192) { Fail "wrong dimensions: $Path ($($img.Width)x$($img.Height))" }
        $pf = $img.PixelFormat.ToString()
        if ($pf -notmatch 'Format32bppArgb|Format32bppPArgb') { Fail "frame is not RGBA 32bpp: $Path ($pf)" }
        $bmp = New-Object Drawing.Bitmap($img)
        for ($y=0; $y -lt 192; $y++) {
            for ($x=0; $x -lt 128; $x++) {
                $alpha = $bmp.GetPixel($x,$y).A
                $inside = ($x -ge 16 -and $x -le 112 -and $y -ge 8 -and $y -le 184)
                if (!$inside -and $alpha -ne 0) { Fail "nontransparent padding at $x,$y in $Path" }
                if ($y -gt 184 -and $alpha -ne 0) { Fail "pixels below pivot in $Path" }
            }
        }
        $bmp.Dispose()
    } finally { $img.Dispose() }
}

function Get-FramePath([string]$State,[string]$Direction,[int]$Frame) {
    return (Join-Path $SourceRoot "$State\$Direction\$('{0:D2}' -f $Frame).png")
}

function Validate-Frames($Manifest) {
    $count = 0
    foreach ($state in $states.Keys) {
        foreach ($direction in $directionsArtist) {
            for ($frame=0; $frame -lt $states[$state]; $frame++) {
                $path = Get-FramePath $state $direction $frame
                Test-Frame $path $Manifest
                $count++
            }
        }
    }
    if ($count -ne 96) { Fail "expected 96 logical frames, found $count" }
    Write-Host "Validated 96 frames: 128x192 RGBA, transparent padding, pivot (64,184)" -ForegroundColor Green
}

function New-Atlas($Manifest) {
    New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
    $cellW=132; $cellH=196; $columns=12; $rows=8
    $bmp = New-Object Drawing.Bitmap([int]($cellW*$columns),[int]($cellH*$rows),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::Transparent)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($row in 0..7) {
        $direction=$directionsEngine[$row]
        $artist=$directionsArtist[$row]
        foreach ($state in $states.Keys) {
            for ($frame=0; $frame -lt $states[$state]; $frame++) {
                $column = if ($state -eq 'idle') { $frame } else { 4+$frame }
                $path=Get-FramePath $state $artist $frame
                $im=[Drawing.Image]::FromFile($path)
                $g.DrawImageUnscaled($im,($column*$cellW)+2,($row*$cellH)+2)
                $im.Dispose()
                $records.Add([PSCustomObject]@{state=$state; frame=$frame; direction=$direction; x=($column*$cellW)+2; y=($row*$cellH)+2; w=128; h=192; offsetx=64; offsety=184})
            }
        }
    }
    $g.Dispose(); $bmp.Save($atlasPath,[Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    $records | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $atlasMetaPath -Encoding utf8
    Write-Host "Built deterministic atlas: $atlasPath" -ForegroundColor Green
}

function New-Definition($Manifest) {
    $lines=New-Object System.Collections.Generic.List[string]
    $lines.Add('image=images/characters/prototype_wanderer.png')
    foreach ($state in $states.Keys) {
        $lines.Add(''); $lines.Add("[$state]"); $lines.Add("frames=$($states[$state])")
        $duration = if ($state -eq 'idle') { 'duration=1200ms' } else { 'duration=640ms' }
        $type = if ($state -eq 'idle') { 'type=back_forth' } else { 'type=looped' }
        $lines.Add($duration)
        $lines.Add($type)
        foreach ($frame in 0..($states[$state]-1)) {
            foreach ($direction in $directionsEngine) {
                $r=Get-Content $atlasMetaPath -Raw | ConvertFrom-Json | Where-Object {$_.state -eq $state -and $_.frame -eq $frame -and $_.direction -eq $direction}
                $lines.Add("frame=$frame,$direction,$($r.x),$($r.y),$($r.w),$($r.h),$($r.offsetx),$($r.offsety)")
            }
        }
    }
    $lines -join "`n" | Set-Content -LiteralPath $definitionPath -Encoding utf8
    $frameLines = @($lines | Where-Object { $_ -like 'frame=*' })
    if ($frameLines.Count -ne 96) { Fail "generated Flare definition contains $($frameLines.Count) frame records; expected 96" }
    foreach ($direction in $directionsEngine) {
        if (@($frameLines | Where-Object { $_ -match ",$direction," }).Count -ne 12) {
            Fail "generated Flare definition does not contain 12 records for direction $direction"
        }
    }
    Write-Host "Validated Flare definition: 96 frame records across 8 directions" -ForegroundColor Green
}

function New-PreviewData($Manifest) {
    if (Test-Path $previewRoot) { Remove-Item -LiteralPath $previewRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $previewMod -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repo 'mods\default') -Destination (Join-Path $previewRoot 'mods\default') -Recurse
    New-Item -ItemType Directory -Path (Join-Path $previewMod 'engine'),(Join-Path $previewMod 'images\characters'),(Join-Path $previewMod 'animations\characters'),(Join-Path $previewMod 'npcs'),(Join-Path $previewMod 'maps'),(Join-Path $previewMod 'tilesetdefs') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $previewMod 'cutscenes'),(Join-Path $previewMod 'images\menus') -Force | Out-Null
    @('description=Jemmi diagnostic asset preview','version=1.0','game=jemmi-ai-world','requires=default') | Set-Content (Join-Path $previewMod 'settings.txt')
    'enable_playgame=1' | Set-Content (Join-Path $previewMod 'engine\gameplay.txt')
    'save_prefix=prototype_wanderer_preview' | Set-Content (Join-Path $previewMod 'engine\misc.txt')
    "orientation=isometric`ntile_size=96,48" | Set-Content (Join-Path $previewMod 'engine\tileset_config.txt')
    'option=0,prototype,prototype,images/menus/logo.png,Prototype Wanderer' | Set-Content (Join-Path $previewMod 'engine\hero_options.txt')
    @('[class]','name=Adventurer','description=Prototype preview class','hero_options=0') | Set-Content (Join-Path $previewMod 'engine\classes.txt')
    '[tileset]' | Set-Content (Join-Path $previewMod 'tilesetdefs\preview.txt')
    $ui = New-Object Drawing.Bitmap(320,48,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $ug = [Drawing.Graphics]::FromImage($ui); $ug.Clear([Drawing.Color]::Transparent); $ug.DrawRectangle([Drawing.Pens]::White,1,1,318,46); $ug.Dispose()
    $ui.Save((Join-Path $previewMod 'images\menus\input.png'),[Drawing.Imaging.ImageFormat]::Png); $ui.Dispose()
    $portrait = New-Object Drawing.Bitmap(320,320,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $pg = [Drawing.Graphics]::FromImage($portrait); $pg.Clear([Drawing.Color]::Transparent); $pg.DrawRectangle([Drawing.Pens]::White,1,1,318,318); $pg.Dispose()
    $portrait.Save((Join-Path $previewMod 'images\menus\portrait_border.png'),[Drawing.Imaging.ImageFormat]::Png); $portrait.Dispose()
    '# Intentionally empty: skip the engine intro in this isolated preview.' | Set-Content (Join-Path $previewMod 'cutscenes\intro.txt')
    Copy-Item $atlasPath (Join-Path $previewMod 'images\characters\prototype_wanderer.png')
    Copy-Item $definitionPath (Join-Path $previewMod 'animations\characters\prototype_wanderer.txt')
    $hero = ((Get-Content $definitionPath -Raw) -replace '\[idle\]','[stance]' -replace 'duration=1200ms','duration=800ms' -replace '\[walk\]','[run]')
    $hero | Set-Content (Join-Path $previewMod 'animations\hero.txt') -Encoding utf8
    @('name=Prototype Wanderer','animations=animations/characters/prototype_wanderer.txt','talker=false') | Set-Content (Join-Path $previewMod 'npcs\prototype_wanderer.txt')
    $zeros = ((0..15 | ForEach-Object { (0..15 | ForEach-Object { '0' }) -join ',' }) -join "`n")
    @('[header]','width=16','height=16','tilewidth=96','tileheight=48','orientation=isometric','hero_pos=8,8','title=Prototype Wanderer Asset Preview','','[tilesets]','','[layer]','type=ground','data=',$zeros,'','[layer]','type=collision','data=',$zeros,'','[npc]','type=npc','location=8,8','filename=npcs/prototype_wanderer.txt','direction=S','waypoints=8,4,12,4,14,6,14,10,12,12,8,12,4,10,2,6,2,4,8,8') | Set-Content (Join-Path $previewMod 'maps\spawn.txt') -Encoding utf8
    Write-Host "Created isolated preview data: $previewRoot" -ForegroundColor Green
}

function Launch-Preview {
    $exe=Join-Path $repo 'build\source-gate-mingw\flare.exe'
    if (!(Test-Path $exe)) { Fail "source-built executable missing: $exe" }
    $ucrtBin = 'C:\msys64\ucrt64\bin'
    if (Test-Path $ucrtBin) { $env:PATH = "$ucrtBin;$env:PATH" }
    $appdata=Join-Path $buildRoot 'appdata'
    if (Test-Path $appdata) { Remove-Item $appdata -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $appdata 'flare\config') -Force | Out-Null
    @('fullscreen=0','renderer=sdl','setup_language=1','setup_mousemove=1','enable_joystick=0','resolution_w=640','resolution_h=480') | Set-Content (Join-Path $appdata 'flare\config\settings.txt')
    $env:APPDATA=$appdata
    $args="--data-path=$previewRoot --mods=default,jemmi_asset_preview --renderer=sdl --no-audio --safe-video"
    if (-not ('PrototypePreviewInput' -as [type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class PrototypePreviewInput {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    public static void SendAccept(IntPtr hWnd) { PostMessage(hWnd,0x0100,(IntPtr)0x0D,IntPtr.Zero); PostMessage(hWnd,0x0101,(IntPtr)0x0D,IntPtr.Zero); }
    public static void ClickWindowClient(IntPtr hWnd, int x, int y) {
        IntPtr lp = (IntPtr)((y << 16) | (x & 0xFFFF));
        PostMessage(hWnd,0x0201,(IntPtr)0x0001,lp); PostMessage(hWnd,0x0202,IntPtr.Zero,lp);
    }
    public static void ClickWindowRelative(IntPtr hWnd, int dx, int dy) {
        RECT r; if (!GetWindowRect(hWnd, out r)) return;
        int x = r.Left + ((r.Right-r.Left)/2) + dx;
        int y = r.Top + (r.Bottom-r.Top) + dy;
        SetCursorPos(x,y); mouse_event(2,0,0,0,UIntPtr.Zero); mouse_event(4,0,0,0,UIntPtr.Zero);
    }
}
"@
    }
    $p=Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory $repo -PassThru
    Start-Sleep -Seconds 2
    $p.Refresh(); Write-Host "Preview window handle: $($p.MainWindowHandle)" -ForegroundColor DarkGray
    [PrototypePreviewInput]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
    # The SDL window is not guaranteed to start at desktop (0,0).  Use the
    # window rectangle so the smoke test remains valid on multi-monitor and
    # VS Code layouts.  The menu definitions place Play Game at bottom - 84
    # and Create at bottom, centered around the selected class panel.
    [PrototypePreviewInput]::ClickWindowClient($p.MainWindowHandle,320,368)
    Start-Sleep -Seconds 3
    [PrototypePreviewInput]::ClickWindowClient($p.MainWindowHandle,391,452)
    Start-Sleep -Seconds ([Math]::Max(1,$LaunchSeconds-6))
    $shot = New-Object Drawing.Bitmap(1536,864)
    $sg = [Drawing.Graphics]::FromImage($shot); $sg.CopyFromScreen(0,0,0,0,$shot.Size); $sg.Dispose()
    $shot.Save((Join-Path $buildRoot 'preview-screen.png'),[Drawing.Imaging.ImageFormat]::Png); $shot.Dispose()
    if ($p.HasExited) { Fail "source-built preview exited early with code $($p.ExitCode)" }
    Stop-Process -Id $p.Id -Force
    $logPath = Join-Path $appdata 'flare\config\flare_log.txt'
    if (!(Test-Path $logPath)) { Fail "preview log missing: $logPath" }
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($log -notmatch "Map: Loading map 'maps/spawn\.txt'") {
        Fail "source-built preview did not load isolated maps/spawn.txt; log: $logPath"
    }
    $mapLoads = [regex]::Matches($log,"Map: Loading map '([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    if (@($mapLoads).Count -ne 1 -or $mapLoads -ne 'maps/spawn.txt') {
        Fail "preview loaded an unexpected map set: $($mapLoads -join ', ')"
    }
    Write-Host "Verified isolated map load and preview log: $logPath" -ForegroundColor Green
    Write-Host "Source-built executable launched the isolated preview for $LaunchSeconds seconds" -ForegroundColor Green
}

$Manifest = Read-Manifest
if ($Clean -and (Test-Path $buildRoot)) { Remove-Item $buildRoot -Recurse -Force }
if ($DiagnosticPlaceholders) { New-DiagnosticFrames }
Validate-Frames $Manifest
New-Atlas $Manifest
New-Definition $Manifest
New-PreviewData $Manifest
if ($Launch) { Launch-Preview }
Write-Host "PASS: prototype_wanderer pipeline complete" -ForegroundColor Green
