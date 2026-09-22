# Troubleshooting

## WoW appears to hang before opening a window

Check Wine's Windows user-folder mappings:

```bash
find "$HOME/Games/TwinStar/prefix-wine11/drive_c/users/$USER" \
    -maxdepth 1 -type l -ls
```

macOS-protected folders such as Desktop, Documents, Pictures, Music and Videos should preferably be prefix-local directories rather than symlinks into the corresponding macOS folders.

Run:

```bash
./scripts/isolate-user-folders.sh
```

## "Unable to start up 3D acceleration"

If DXVK is installed, WoW may display:

```text
World of Warcraft was unable to start up 3D acceleration.
Please make sure DirectX 9.0c is installed and your video
drivers are up-to-date.
```

Do not assume this means DirectX 9.0c needs installing.

In the tested Apple M1 configuration, DXVK detected the GPU but failed during Vulkan device creation.

MoltenVK reported:

```text
VK_ERROR_FEATURE_NOT_PRESENT
```

followed by:

```text
DxvkAdapter: Failed to create device
```

Launch with Wine's builtin D3D9 instead:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

## No resolutions are listed

The client may report:

```text
SET gxResolution "0x0"
```

and show no available resolutions.

Try Wine's virtual desktop:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 "./Wow-64.exe"
```

This caused the tested M1 MacBook Air to enumerate its logical Retina display modes correctly, up to 1680x1050.

## WoW fullscreen does not work

Keep WoW in Windowed mode.

Use the green macOS window control to make the Wine window fullscreen instead.

This was more reliable than asking the WoW D3D9 client to perform a native fullscreen mode switch.

## Verify Wine

```bash
"$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine" --version
```

Known-good tested version:

```text
wine-11.17 (Staging)
```

## Verify the .NET runtime

```bash
export WINEPREFIX="$HOME/Games/TwinStar/prefix-wine11"
export WINE="$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"

"$WINE" "C:\\Program Files\\dotnet\\dotnet.exe" --list-runtimes
```

The TwinStar Launcher requires the Windows Desktop runtime in addition to the base .NET runtime.

## DXVK diagnostics

For troubleshooting only, DXVK can generate logs using:

```bash
DXVK_LOG_LEVEL=debug \
DXVK_LOG_PATH="$HOME/Desktop" \
"$WINE" "./Wow-64.exe"
```

On the tested M1 configuration, DXVK 1.10.3 reached the Apple M1 GPU but ultimately produced:

```text
DxvkAdapter: Failed to create device
```

WineD3D is therefore the known-good D3D9 backend for this configuration.