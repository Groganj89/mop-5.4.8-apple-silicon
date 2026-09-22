# Troubleshooting

This document covers common issues encountered while running World of Warcraft: Mists of Pandaria 5.4.8 build 18414 on Apple Silicon through Wine.

## Wine cannot be found

The project automatically checks several common Wine locations.

To specify Wine manually:

```bash
export WINE="/path/to/wine"
```

Then rerun the required script.

For example:

```bash
./setup.sh
```

## Verify Wine

The tested Wine version is:

```text
wine-11.17 (Staging)
```

If using the default project installation:

```bash
"$HOME/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine" --version
```

Existing installations in other supported locations are also detected automatically.

## Verify the Wine prefix

The default prefix is:

```text
~/Games/WoW-MoP/prefix
```

Check it with:

```bash
ls -la "$HOME/Games/WoW-MoP/prefix"
```

Existing installations using the original development prefix are also supported:

```text
~/Games/TwinStar/prefix-wine11
```

## Client download was interrupted

The client downloader supports restarting interrupted downloads.

Run:

```bash
./scripts/download-client.sh
```

again.

Files already at their expected size are skipped.

Partial downloads can resume from the existing data.

This is useful after:

- Network interruption
- Terminal interruption
- System restart
- Running out of disk space

Ensure sufficient free storage is available. The tested `enUS` client requires approximately 22 GiB of game data.

## Wow-64.exe cannot be found

The default installation location is:

```text
~/Games/WoW-MoP/prefix/drive_c/WoW/Wow-64.exe
```

Search the current Wine prefix manually with:

```bash
find "$WINEPREFIX/drive_c" \
    -type f \
    -name "Wow-64.exe" \
    -print
```

If the client download has not completed, run:

```bash
./scripts/download-client.sh
```

again.

## WoW hangs before opening a window

Wine can create symbolic links from its Windows user directories into protected macOS directories.

Inspect them with:

```bash
find "$WINEPREFIX/drive_c/users/$USER" \
    -maxdepth 1 \
    -type l \
    -ls
```

Then run:

```bash
./scripts/isolate-user-folders.sh
```

The script replaces mappings for protected directories with normal directories contained inside the Wine prefix.

## Unable to start up 3D acceleration

WoW may display:

```text
World of Warcraft was unable to start up 3D acceleration.
Please make sure DirectX 9.0c is installed and your video
drivers are up-to-date.
```

Do not immediately install DirectX 9.0c.

During development, this error was produced when DXVK failed to create the required Vulkan device through MoltenVK.

The known-working configuration uses Wine's builtin D3D9 implementation:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

The supplied launcher applies this automatically:

```bash
./scripts/run-wow.sh
```

## DXVK diagnostics

DXVK was tested as an alternative D3D9 implementation.

The attempted graphics path was:

```text
WoW
 ↓
Direct3D 9
 ↓
DXVK
 ↓
Vulkan
 ↓
MoltenVK
 ↓
Metal
```

On the tested Apple Silicon configuration, DXVK 1.10.3 reached the Apple GPU but ultimately failed with:

```text
DxvkAdapter: Failed to create device
```

MoltenVK also reported unavailable Vulkan features, including:

```text
VK_ERROR_FEATURE_NOT_PRESENT
```

and:

```text
Metal does not support buffer robustness.
```

For troubleshooting only, DXVK logging can be enabled with:

```bash
DXVK_LOG_LEVEL=debug \
DXVK_LOG_PATH="$HOME/Desktop" \
"$WINE" "./Wow-64.exe"
```

WineD3D is currently the known-working D3D9 backend.

## No resolutions appear

WoW can occasionally fail to enumerate display modes correctly through Wine.

Try:

```bash
./scripts/run-wow-desktop.sh
```

This launches WoW inside a Wine virtual desktop.

The underlying method is:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 "./Wow-64.exe"
```

On the tested M1 MacBook Air, this caused Wine to enumerate the logical Retina display modes correctly, including:

```text
1680x1050
```

## WoW fullscreen does not work

Keep WoW in **Windowed** mode.

Launch normally:

```bash
./scripts/run-wow.sh
```

Then use the green macOS window control to put the Wine window into native macOS fullscreen.

This has proven more reliable than asking the WoW D3D9 client to perform its own fullscreen mode switch.

## Poor graphics performance

WineD3D works but currently has performance and rendering limitations.

Testing on both M1 and M4 Pro has shown reduced performance at higher graphics settings.

Some scenes may also exhibit graphical artefacts such as vegetation or tree flickering.

Settings worth reducing individually include:

```text
Shadows
SSAO
Sun Shafts
View Distance
Environment Detail
Ground Effect Density
Water Detail
Anti-Aliasing
```

Texture quality can generally remain higher without the same performance impact as some effects.

Graphics-backend optimisation remains an area for further investigation.

## Collecting Wine output

To capture Wine output while launching WoW:

```bash
./scripts/run-wow.sh > ~/Desktop/wow-wine.log 2>&1
```

Then inspect:

```bash
cat ~/Desktop/wow-wine.log
```

When reporting a problem, include:

```text
Mac model:
Apple SoC:
RAM:
macOS version:
Wine version:
WoW version/build:
Graphics settings:
Resolution:
Exact error:
```

and relevant Terminal or Wine output.