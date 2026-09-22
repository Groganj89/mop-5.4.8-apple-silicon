# World of Warcraft: Mists of Pandaria 5.4.8 on Apple Silicon

Run the Windows **World of Warcraft: Mists of Pandaria 5.4.8 (build 18414)** client on Apple Silicon Macs using Wine.

This project documents a working configuration tested with the TwinStar/Helios MoP client.

## Tested configuration

- Apple M1 MacBook Air
- Apple Silicon / Rosetta 2
- macOS 26
- Wine Staging 11.17
- World of Warcraft 5.4.8 build 18414
- TwinStar / Helios
- 64-bit `Wow-64.exe`

Other Apple Silicon Macs may work, but have not yet been tested.

## What works

- TwinStar Launcher
- Client download/update
- WoW 5.4.8 64-bit client
- Login and character selection
- Playing in-world
- Audio
- WineD3D / Direct3D 9
- macOS fullscreen using the native green window button
- macOS `.app` launcher

## Graphics

The known-good graphics path is:

```text
WoW 5.4.8
    ↓
Direct3D 9
    ↓
WineD3D
    ↓
macOS graphics stack
    ↓
Apple Silicon GPU
```

### Why not DXVK?

DXVK was tested but failed while creating the Vulkan device through MoltenVK.

DXVK 1.10.3 successfully detected the Apple M1 GPU but eventually failed with:

```text
VK_ERROR_FEATURE_NOT_PRESENT
DxvkAdapter: Failed to create device
```

MoltenVK reported requested `VkPhysicalDeviceFeatures` that were unavailable.

For this reason, this setup explicitly tells Wine to use its **builtin D3D9 implementation**:

```bash
WINEDLLOVERRIDES="d3d9=b"
```

Do not install DirectX 9.0c in response to WoW's generic:

> World of Warcraft was unable to start up 3D acceleration.

In the configuration tested here, that message was caused by DXVK failing to create its Vulkan device, not by DirectX 9.0c being absent.

## Installation

### 1. Install Rosetta 2

If Rosetta is not already installed:

```bash
softwareupdate --install-rosetta --agree-to-license
```

### 2. Install Wine

This project was tested using:

```text
Wine Staging 11.17
```

The Wine application used during testing was installed at:

```text
~/Games/Wine/Wine Staging.app
```

The corresponding Wine executable is:

```text
~/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine
```

### 3. Create the Wine prefix

The tested prefix location is:

```text
~/Games/TwinStar/prefix-wine11
```

Run:

```bash
./scripts/create-prefix.sh
```

### 4. Install the .NET Desktop Runtime

The TwinStar Launcher tested with this project requires:

```text
Microsoft.NETCore.App 8.x
Microsoft.WindowsDesktop.App 8.x
```

Download the Windows x64 .NET 8 Desktop Runtime directly from Microsoft and install it into the Wine prefix.

For example:

```bash
export WINEPREFIX="$HOME/Games/TwinStar/prefix-wine11"
export WINE="$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"

"$WINE" windowsdesktop-runtime-8.x.x-win-x64.exe
```

Verify with:

```bash
"$WINE" "C:\\Program Files\\dotnet\\dotnet.exe" --list-runtimes
```

### 5. Download the TwinStar client

Download the TwinStar launcher/client from TwinStar itself.

**This repository does not contain or distribute World of Warcraft, TwinStar, Blizzard, Microsoft or Wine binaries.**

Use the TwinStar launcher to download the MoP client.

In the tested installation, the resulting game was located at:

```text
~/Games/TwinStar/prefix-wine11/drive_c/Wow-64.exe
```

### 6. Fix macOS protected-folder mappings

This was important during testing.

Wine initially mapped Windows user directories such as:

```text
Desktop
Documents
Pictures
Music
Videos
```

directly to the corresponding macOS folders.

This caused macOS privacy prompts and, in the tested environment, prevented WoW from progressing normally during startup.

Run:

```bash
./scripts/isolate-user-folders.sh
```

The script replaces these mappings with directories contained entirely within the Wine prefix.

`Downloads` is intentionally left alone.

### 7. Configure WoW

A minimal configuration is provided in:

```text
config/Config.wtf.example
```

The important setting is:

```text
SET gxApi "D3D9"
```

Do not force D3D11. The tested 5.4.8 client uses D3D9.

### 8. Launch WoW

Run:

```bash
./scripts/run-wow.sh
```

The critical part of the command is:

```bash
WINEDLLOVERRIDES="d3d9=b"
```

This bypasses DXVK and forces Wine's builtin D3D9 implementation.

## Fullscreen and resolutions

There are some quirks with display-mode enumeration under Wine.

If WoW does not show any resolutions, it can be launched inside a Wine virtual desktop:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 "./Wow-64.exe"
```

On the tested M1 MacBook Air, Wine correctly reported the macOS logical Retina resolution of:

```text
1680x1050
```

Native WoW fullscreen switching did not work reliably.

Instead:

1. Run WoW in Windowed mode.
2. Click the **green macOS window button**.
3. macOS will place the Wine/WoW window into native fullscreen.

This provides fullscreen gameplay while leaving WoW itself in the more reliable windowed D3D9 mode.

## macOS application launcher

WoW can also be launched from `/Applications` without opening Terminal.

See:

```text
docs/macos-app.md
```

## Performance

WineD3D works but is not as efficient as a native graphics implementation.

Higher MoP graphics presets can therefore become expensive even on hardware that would otherwise have no difficulty running a 2013-era client.

Settings worth tuning individually include:

- Shadows
- SSAO
- Sun shafts
- View distance / far clip
- Ground-effect density
- Water detail
- Anti-aliasing

Avoid assuming the overall graphics preset needs to remain at Low. Keeping textures high while reducing expensive effects can provide much better image quality without the same performance penalty.

## Troubleshooting

See:

```text
docs/troubleshooting.md
```

## Legal

This project contains no World of Warcraft game files and no Blizzard Entertainment assets.

World of Warcraft and related names and trademarks belong to their respective owners.

TwinStar/Helios is not affiliated with this project.

Users must obtain all third-party software and game files themselves.

## Contributing

Testing on additional hardware would be particularly useful:

- M1 Pro / Max / Ultra
- M2 family
- M3 family
- M4 family
- Different macOS releases
- Other MoP 5.4.8 distributions/private servers

When reporting results, include:

```text
Mac:
SoC:
RAM:
macOS:
Wine version:
WoW build:
Server/client distribution:
Graphics settings:
Result:
```