# World of Warcraft: Mists of Pandaria 5.4.8 on Apple Silicon

Run the Windows **World of Warcraft: Mists of Pandaria 5.4.8 (build 18414)** client on Apple Silicon Macs using Wine.

This project provides an automated installation and compatibility configuration developed using the **TwinStar / Helios** Mists of Pandaria client.

The goal is simple:

```text
Clone → Setup → Download → Play
```

The automated setup can install Wine, create the Wine environment, discover the current TwinStar MoP client manifest, download the required game data, and configure the client for the known-working graphics path.

No World of Warcraft game files, Blizzard assets, TwinStar binaries, Microsoft runtimes, or Wine binaries are distributed by this repository.

---

## Current Status

### Confirmed working

| Component | Tested configurations |
|---|---|
| Apple Silicon | M1, M4 Pro |
| Mac | MacBook Air (M1), MacBook Pro (M4 Pro) |
| Architecture | ARM64 + Rosetta 2 |
| macOS | macOS 26 |
| Wine | Wine Staging 11.17 |
| WoW | Mists of Pandaria 5.4.8 |
| Build | 18414 |
| Client | 64-bit `Wow-64.exe` |
| Server | TwinStar / Helios |
| Graphics API | Direct3D 9 |
| Graphics backend | WineD3D |

The configuration has successfully been tested for:

- Automated Wine installation
- Automated Wine-prefix creation
- Dynamic TwinStar CDN discovery
- Dynamic MoP manifest discovery
- Automated client bootstrap
- Resumable game-data download
- Locale-aware manifest filtering
- Blizzard `ptv3` partial-file metadata detection
- Safe repeated setup/download runs after WoW has modified MPQ files
- Direct `Wow-64.exe` launch
- TwinStar / Helios authentication
- Character selection
- Entering the game world
- Gameplay
- Audio
- macOS fullscreen

A **clean installation was successfully tested on an M4 Pro MacBook Pro**, including downloading the complete client without copying files from an existing installation.

The same installation was then launched, allowed to update its local MPQ metadata, and passed through the downloader again. All 58 manifest records were correctly recognised without unnecessarily downloading the client again.

Graphics compatibility and performance tuning remain ongoing. WineD3D works, but graphical artefacts and reduced performance can occur at higher settings.

---

# Quick Start

## Requirements

You need:

- An Apple Silicon Mac
- macOS
- An internet connection
- Approximately 25 GB or more of available disk space
- Rosetta 2

The tested Wine version is:

```text
Wine Staging 11.17
```

The setup script can install the tested Wine build automatically.

---

## Install Rosetta 2

If Rosetta is not already installed:

```bash
softwareupdate --install-rosetta --agree-to-license
```

If Rosetta is already present, macOS will report that it is installed.

---

## Clone the repository

```bash
git clone https://github.com/Groganj89/mop-5.4.8-apple-silicon.git
cd mop-5.4.8-apple-silicon
```

Make the setup script executable:

```bash
chmod +x setup.sh
```

Then run:

```bash
./setup.sh
```

The setup process will:

1. Check Rosetta and install Wine Staging if required.
2. Create or reuse a dedicated Wine prefix.
3. Isolate Wine's Windows user folders from protected macOS folders.
4. Discover the current TwinStar MoP build and CDN.
5. Download the required client bootstrap files.
6. Parse the current MoP manifest.
7. Select the generic and appropriate locale-specific game files.
8. Download or resume the game data.
9. Validate existing client data where possible.
10. Prepare the client for the known-working WineD3D configuration.

The default Wine prefix is:

```text
~/Games/WoW-MoP/prefix
```

The default WoW installation is:

```text
~/Games/WoW-MoP/prefix/drive_c/WoW
```

---

# Client Downloader

The project no longer requires the TwinStar WPF launcher or Microsoft .NET Desktop Runtime for normal installation.

Instead, `scripts/download-client.sh` reproduces the client-download process required for the MoP client directly.

The downloader:

1. Retrieves TwinStar's current MoP bootstrap manifest.
2. Downloads and verifies the bootstrap files.
3. Queries TwinStar's MoP patch service.
4. Discovers the current game build and manifest.
5. Resolves the current TwinStar CDN.
6. Parses the manifest using TwinStar-compatible locale filtering.
7. Downloads or resumes the required game data.
8. Recognises valid Blizzard partial-file metadata added by the WoW client.

For the currently tested `enUS` build, this resolves to:

```text
Build:            18414
Locale:           enUS
Manifest records: 58
Game data:        ~21.98 GiB
```

These values are discovered dynamically rather than being used as hard-coded download requirements.

## Resume support

Large game-data files can be resumed.

If a download is interrupted because of:

- Network loss
- Terminal interruption
- System restart
- Insufficient disk space

run:

```bash
./scripts/download-client.sh
```

again.

Files already at their expected size are skipped and partial downloads continue from their existing data.

The downloader does not require an existing WoW installation.

## Blizzard partial-file metadata

After World of Warcraft has been launched, some MPQ files may become slightly larger than the sizes listed in the TwinStar manifest.

This is expected behaviour.

WoW can append Blizzard partial-file metadata to an otherwise complete archive. The metadata found during testing uses a footer with the signature:

```text
ptv3
```

The downloader recognises this condition rather than assuming that every oversized MPQ is corrupt.

For an oversized file, it validates the footer and requires:

```text
Signature:    ptv3
Version:      3
Map offset:   expected manifest payload size
Block size:   16384 bytes
```

The embedded build number is also displayed for diagnostic purposes, but it is not required to match build 18414. Base and update archives legitimately contain metadata associated with earlier WoW builds.

For example, testing observed base archives associated with build:

```text
15890
```

and update archives progressing through later builds including:

```text
16016
16048
16057
16309
...
18273
18274
```

If the footer is valid and its map offset exactly matches the expected manifest size, the archive is treated as complete:

```text
Status:   complete - Blizzard partial-file metadata detected
```

If an existing file is larger than the manifest size but does **not** contain recognised metadata, the downloader stops and leaves the file untouched rather than deleting or replacing potentially valid client data.

This behaviour makes repeated setup runs safe after WoW has modified its local MPQ files.

Do **not** manually truncate MPQ files simply because their local size is slightly larger than the manifest size.

---

# Launching WoW

Once setup is complete:

```bash
./scripts/run-wow.sh
```

The launcher automatically discovers:

- Wine
- The Wine prefix
- `Wow-64.exe`

The canonical installation is:

```text
~/Games/WoW-MoP/prefix/drive_c/WoW/Wow-64.exe
```

Existing installations using the older layout:

```text
~/Games/TwinStar/prefix-wine11/drive_c/Wow-64.exe
```

are also supported by the discovery scripts.

WoW is launched using:

```text
WINEDLLOVERRIDES=d3d9=b
```

This forces Wine's **builtin Direct3D 9 implementation** rather than allowing a native `d3d9.dll`, such as DXVK, to take over.

---

# Why WineD3D?

WoW 5.4.8 uses:

```text
Direct3D 9
```

DXVK was tested as an alternative graphics implementation.

The attempted path was:

```text
WoW 5.4.8
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
    ↓
Apple Silicon GPU
```

DXVK successfully loaded, detected the Apple GPU and MoltenVK, and began Vulkan device creation.

MoltenVK then returned:

```text
VK_ERROR_FEATURE_NOT_PRESENT
```

Testing also produced errors including:

```text
vkCreateDevice(): Requested physical device feature
is not available on this device.
```

and:

```text
Metal does not support buffer robustness.
```

DXVK ultimately failed with:

```text
DxvkAdapter: Failed to create device
```

WoW then displayed:

```text
World of Warcraft was unable to start up 3D acceleration.

Please make sure DirectX 9.0c is installed and your video
drivers are up-to-date.
```

## DirectX 9.0c was not the problem

That WoW error is misleading in this configuration.

Installing DirectX 9.0c was not required.

The failure occurred because DXVK could not create the required Vulkan device through MoltenVK.

The working launch method is:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

The confirmed graphics path is therefore:

```text
WoW 5.4.8
    ↓
Direct3D 9
    ↓
Wine builtin D3D9
    ↓
WineD3D
    ↓
macOS graphics stack
    ↓
Apple Silicon GPU
```

This override is automatically applied by:

```bash
./scripts/run-wow.sh
```

---

# Graphics Performance

WineD3D successfully runs the game, but graphics performance and compatibility are currently the main limitations.

Testing on both **M1** and **M4 Pro** has shown that simply using substantially faster Apple Silicon does not eliminate the graphics issues.

Observed behaviour includes:

- Reduced performance at higher graphics presets
- Occasional graphical artefacts
- Vegetation/tree flickering in some scenes
- Better results at moderate graphics settings

This suggests that at least some of the remaining limitations are related to the Direct3D 9 translation path rather than raw GPU performance.

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

Graphics-backend investigation is ongoing.

---

# macOS Protected Folders

Wine normally creates Windows user-folder mappings such as:

```text
C:\users\<username>\Desktop
C:\users\<username>\Documents
C:\users\<username>\Pictures
C:\users\<username>\Music
C:\users\<username>\Videos
```

as symbolic links to directories under:

```text
/Users/<username>/
```

Modern macOS privacy controls can interfere with applications accessing these directories.

During development, these mappings generated privacy prompts and contributed to WoW startup problems.

The project therefore runs:

```bash
./scripts/isolate-user-folders.sh
```

This replaces the relevant Wine symlinks with normal directories contained entirely inside the Wine prefix.

`Downloads` is intentionally left mapped to the host Downloads directory.

---

# World of Warcraft Configuration

An example configuration is provided at:

```text
config/Config.wtf.example
```

The important graphics API setting is:

```text
SET gxApi "D3D9"
```

A minimal example is:

```text
SET locale "enUS"
SET installLocale "enUS"
SET gxApi "D3D9"
SET hwDetect "0"
SET gxWindow "1"
SET gxMaximize "1"
```

Server-specific settings such as the realmlist should be configured for the server being used.

Do not publish personal values such as:

```text
accountName
realmName
lastCharacterIndex
```

when sharing `Config.wtf`.

---

# Resolution and Fullscreen

Display-mode enumeration can behave differently under Wine.

During development, WoW occasionally generated:

```text
SET gxResolution "0x0"
```

or displayed no selectable resolutions.

A Wine virtual desktop can be tested with:

```bash
./scripts/run-wow-desktop.sh
```

The underlying method is:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 "./Wow-64.exe"
```

For normal use, leaving WoW in **Windowed** mode and using the green macOS window button has proven reliable.

macOS then places the Wine window into native macOS fullscreen while WoW remains in its windowed Direct3D mode.

---

# Manual Setup

The automated setup is recommended:

```bash
./setup.sh
```

Individual stages can also be run manually.

## Install Wine

```bash
./scripts/install-wine.sh
```

## Create the Wine prefix

```bash
./scripts/create-prefix.sh
```

## Isolate macOS user folders

```bash
./scripts/isolate-user-folders.sh
```

## Download or resume the MoP client

```bash
./scripts/download-client.sh
```

## Launch WoW

```bash
./scripts/run-wow.sh
```

## Launch using a Wine virtual desktop

```bash
./scripts/run-wow-desktop.sh
```

---

# Automatic Detection

The helper scripts share:

```text
scripts/common.sh
```

which performs Wine, prefix and WoW-client discovery.

## Wine

Common Wine locations are searched automatically.

Detection can be overridden with:

```bash
export WINE="/custom/path/to/wine"
```

## Wine prefix

The default project prefix is:

```text
~/Games/WoW-MoP/prefix
```

A custom prefix can be specified with:

```bash
export WINEPREFIX="$HOME/Games/My-MoP-Prefix"
./setup.sh
```

The discovery code also supports existing installations, including the original development prefix:

```text
~/Games/TwinStar/prefix-wine11
```

## WoW executable

The preferred location is:

```text
$WINEPREFIX/drive_c/WoW/Wow-64.exe
```

The older layout:

```text
$WINEPREFIX/drive_c/Wow-64.exe
```

is also recognised.

As a fallback, the scripts search the selected prefix for `Wow-64.exe`.

An explicit executable can be supplied with:

```bash
export WOW_EXE="/path/to/Wow-64.exe"
./scripts/run-wow.sh
```

---

# Project Structure

```text
mop-5.4.8-apple-silicon/
├── README.md
├── LICENSE
├── .gitignore
├── setup.sh
│
├── config/
│   └── Config.wtf.example
│
├── docs/
│   ├── macos-app.md
│   └── troubleshooting.md
│
└── scripts/
    ├── common.sh
    ├── install-wine.sh
    ├── create-prefix.sh
    ├── isolate-user-folders.sh
    ├── download-client.sh
    ├── run-wow.sh
    └── run-wow-desktop.sh
```

---

# Troubleshooting

## Wine cannot be found

If setup reports:

```text
ERROR: Wine could not be found.
```

specify Wine manually:

```bash
export WINE="/path/to/wine"
./setup.sh
```

---

## Client download is interrupted

Simply run:

```bash
./scripts/download-client.sh
```

again.

Completed files are skipped and partial game-data files can be resumed.

Ensure sufficient free disk space is available. The current `enUS` client requires approximately **22 GiB of game data**, in addition to space required by Wine, macOS and temporary files.

---

## MPQ file is larger than the manifest size

This can be normal after WoW has been launched.

The client may append Blizzard `ptv3` partial-file metadata to MPQ archives, causing their local file size to exceed the payload size recorded in the download manifest.

The downloader automatically validates recognised metadata.

A valid file produces:

```text
Status:   complete - Blizzard partial-file metadata detected
```

and is not downloaded again.

If the metadata cannot be validated, the downloader stops and preserves the existing file.

Do not delete or truncate an oversized MPQ solely because its size differs from the manifest.

---

## WoW cannot be found

The default executable should be:

```text
~/Games/WoW-MoP/prefix/drive_c/WoW/Wow-64.exe
```

You can search manually with:

```bash
find "$WINEPREFIX/drive_c" \
    -type f \
    -name "Wow-64.exe" \
    -print
```

Then run:

```bash
./scripts/run-wow.sh
```

---

## WoW hangs before opening a window

Check Wine's Windows user-folder mappings:

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

---

## "Unable to start up 3D acceleration"

Do not immediately install DirectX 9.0c.

If DXVK or another native `d3d9.dll` is present, bypass it with:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

The supplied launcher does this automatically:

```bash
./scripts/run-wow.sh
```

---

## No resolutions appear

Try:

```bash
./scripts/run-wow-desktop.sh
```

This runs WoW inside a Wine virtual desktop and may allow the correct display modes to enumerate.

---

# Clean Installation and Idempotency Testing

A full clean installation has been successfully tested on an **M4 Pro MacBook Pro**.

The test intentionally did not copy the existing ~22 GiB M1 installation.

Instead, the M4:

1. Started without the WoW client.
2. Installed/used Wine Staging 11.17.
3. Created a fresh Wine prefix.
4. Discovered the TwinStar MoP bootstrap data.
5. Discovered build `18414`.
6. Resolved the current TwinStar CDN.
7. Parsed the current manifest.
8. Selected 58 records for `enUS`.
9. Downloaded approximately 21.98 GiB of game data.
10. Successfully resumed an interrupted game-data download.
11. Launched `Wow-64.exe`.
12. Logged into TwinStar / Helios.
13. Entered the game world.
14. Successfully ran around in-game.

The installation was then tested again **after WoW had modified the downloaded MPQ files**.

The downloader processed all 58 manifest records successfully:

- Exact-size files were skipped.
- MPQs containing valid Blizzard `ptv3` metadata were recognised as complete.
- The metadata's embedded map offset was validated against the manifest payload size.
- No valid expanded MPQ was deleted or unnecessarily downloaded again.
- The downloader reached `Client download complete`.

This validates the complete lifecycle:

```text
Fresh install
    ↓
Interrupted download
    ↓
Resume
    ↓
Complete client
    ↓
Launch WoW
    ↓
WoW appends MPQ metadata
    ↓
Run downloader again
    ↓
Existing client validated and preserved
```

This clean-room and repeat-run testing removes the dependency on assumptions inherited from the original M1 development environment.

Testing on additional Apple Silicon generations remains welcome.

---

# Compatibility Testing

Currently confirmed:

| SoC | Result | Notes |
|---|---|---|
| Apple M1 | Working | Original development environment |
| Apple M4 Pro | Working | Fresh installation, full client download, gameplay and repeat-run validation |

Testing is particularly useful on:

- M1 Pro / Max / Ultra
- M2 / M2 Pro / M2 Max / M2 Ultra
- M3 / M3 Pro / M3 Max
- M4 / M4 Max
- Newer Apple Silicon generations
- Different macOS releases
- Different Wine releases

---

# Reporting Compatibility

If you test another configuration, please open a GitHub issue and include:

```text
Mac model:
Apple SoC:
RAM:
macOS version:
Wine version:
WoW version/build:
Server/client distribution:
Graphics settings:
Resolution:
Result:
```

For failures, include the exact Terminal output or relevant Wine logs where possible.

---

# Contributing

Pull requests, compatibility reports, bug reports and documentation improvements are welcome.

Particularly useful contributions include:

- Testing additional Apple Silicon generations
- Testing newer Wine releases
- Improving client/CDN discovery
- Improving download reliability
- Graphics-performance tuning
- Alternative graphics backends
- Display/fullscreen improvements
- Setup automation
- Documentation corrections

Please do **not** submit:

- World of Warcraft client files
- Blizzard game data
- TwinStar binaries
- Microsoft runtime binaries
- Wine binaries
- Copyrighted game artwork

---

# Legal

This is an independent compatibility and documentation project.

This repository does **not** distribute World of Warcraft, Blizzard game data, TwinStar/Helios client files, Microsoft runtimes, or Wine binaries.

The scripts retrieve required third-party files from third-party servers. Availability, licensing and permission to use those files are determined by their respective providers and rights holders.

World of Warcraft, Warcraft, Mists of Pandaria, Blizzard Entertainment, and related names, artwork and trademarks are the property of their respective owners.

TwinStar / Helios is not affiliated with this project.

This project is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment.

---

# License

The original scripts and documentation in this repository are released under the MIT License.

See:

```text
LICENSE
```

for details.