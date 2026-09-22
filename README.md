# World of Warcraft: Mists of Pandaria 5.4.8 on Apple Silicon

Run the Windows **World of Warcraft: Mists of Pandaria 5.4.8 (build 18414)** client on Apple Silicon Macs using Wine.

This project documents and provides helper scripts for a working Apple Silicon configuration originally tested with the **TwinStar / Helios** Mists of Pandaria client.

No World of Warcraft game files, Blizzard assets, TwinStar files, Wine binaries, or Microsoft runtimes are distributed by this repository.

---

## Status

### Tested and working

| Component | Tested configuration |
|---|---|
| Mac | MacBook Air |
| SoC | Apple M1 |
| Architecture | Apple Silicon / Rosetta 2 |
| macOS | macOS 26 |
| Wine | Wine Staging 11.17 |
| WoW | Mists of Pandaria 5.4.8 |
| Build | 18414 |
| Executable | `Wow-64.exe` |
| Server | TwinStar / Helios |
| Graphics API | Direct3D 9 |
| Graphics backend | WineD3D |

The tested client successfully:

- Launches on Apple Silicon
- Connects to TwinStar
- Logs into an account
- Reaches character selection
- Enters the game world
- Renders 3D graphics
- Plays audio
- Runs in macOS fullscreen
- Launches from a normal macOS `.app`

Other Apple Silicon Macs and macOS versions may also work, but have not yet been verified.

---

# Quick Start

## 1. Install Rosetta 2

Wine runs the x86-64 WoW client through Rosetta.

If Rosetta is not already installed:

```bash
softwareupdate --install-rosetta --agree-to-license
```

---

## 2. Install Wine Staging

The known-good configuration uses:

```text
Wine Staging 11.17
```

Wine does **not** need to be installed in a specific location.

The helper scripts automatically check several common locations, including:

```text
~/Games/Wine/Wine Staging.app
/Applications/Wine Staging.app
~/Applications/Wine Staging.app
/opt/homebrew/bin/wine
/usr/local/bin/wine
```

They will also check the current `PATH`.

You can explicitly specify Wine if necessary:

```bash
export WINE="/path/to/wine"
```

Verify your Wine installation with:

```bash
"$WINE" --version
```

when using a custom path.

---

## 3. Clone this repository

```bash
git clone https://github.com/Groganj89/mop-5.4.8-apple-silicon.git
cd wow-mop-apple-silicon
```

Make the helper scripts executable:

```bash
chmod +x scripts/*.sh
```

---

## 4. Create a Wine prefix

Run:

```bash
./scripts/create-prefix.sh
```

If no `WINEPREFIX` has been specified, a new prefix will be created at:

```text
~/Games/WoW-MoP/prefix
```

Advanced users can choose another location:

```bash
export WINEPREFIX="$HOME/Games/My-WoW-Prefix"
./scripts/create-prefix.sh
```

---

## 5. Install the .NET 8 Desktop Runtime

The TwinStar Launcher requires the **Windows x64 .NET 8 Desktop Runtime**.

Download it directly from Microsoft.

Once downloaded, install it into your Wine prefix.

For example:

```bash
export WINEPREFIX="$HOME/Games/WoW-MoP/prefix"
```

Then run the installer using the same Wine installation used to create the prefix.

The required runtime includes:

```text
Microsoft.NETCore.App 8.x
Microsoft.WindowsDesktop.App 8.x
```

The Windows **Desktop Runtime** is important because the TwinStar Launcher uses WPF.

---

## 6. Download/install the MoP client

Obtain the Mists of Pandaria client from your server/provider.

For TwinStar / Helios, use the official TwinStar launcher and allow it to download/update the client.

This repository does **not** redistribute the launcher or game client.

The scripts expect the 64-bit client:

```text
Wow-64.exe
```

to exist in the Wine prefix.

For example:

```text
~/Games/WoW-MoP/prefix/drive_c/Wow-64.exe
```

The scripts can also detect the original development/test location:

```text
~/Games/TwinStar/prefix-wine11/drive_c/Wow-64.exe
```

---

# Important: isolate macOS user folders

This was one of the key discoveries while getting the client working.

By default, Wine may map Windows folders such as:

```text
C:\users\<username>\Desktop
C:\users\<username>\Documents
C:\users\<username>\Pictures
C:\users\<username>\Music
C:\users\<username>\Videos
```

directly to the equivalent macOS directories.

On macOS, these locations can be protected by privacy controls.

During testing, the client encountered macOS permission prompts and startup problems while these directories were mapped into the Wine prefix.

Run:

```bash
./scripts/isolate-user-folders.sh
```

The script checks:

```text
Desktop
Documents
Pictures
Music
Videos
```

and replaces Wine symlinks to macOS locations with normal directories stored inside the Wine prefix.

### Downloads is intentionally left unchanged

The script does **not** alter:

```text
Downloads
```

because launchers/installers may still be running from the user's macOS Downloads directory.

You can inspect the remaining mappings with:

```bash
find "$WINEPREFIX/drive_c/users/$USER" -maxdepth 1 -type l -ls
```

---

# Configure World of Warcraft

An example configuration is provided at:

```text
config/Config.wtf.example
```

The most important graphics setting is:

```text
SET gxApi "D3D9"
```

The tested MoP 5.4.8 client uses Direct3D 9.

A minimal configuration looks like:

```text
SET locale "enUS"
SET installLocale "enUS"
SET gxApi "D3D9"
SET hwDetect "0"
SET gxWindow "1"
SET gxMaximize "1"
```

Server-specific settings such as `realmlist` should be configured for your own server.

Do not copy account names, character information or other personal settings into a public configuration file.

---

# Launch WoW

Once `Wow-64.exe` has been installed, simply run:

```bash
./scripts/run-wow.sh
```

The script automatically attempts to detect:

- Wine
- The Wine prefix
- `Wow-64.exe`

It then launches WoW using the critical compatibility override:

```bash
WINEDLLOVERRIDES="d3d9=b"
```

This tells Wine to use its **builtin D3D9 implementation** rather than a native `d3d9.dll` such as DXVK.

---

# Why WineD3D instead of DXVK?

This was the main graphics compatibility issue discovered during testing.

The desired graphics path initially looked like:

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
Apple M1
```

DXVK successfully:

- Loaded
- Detected the Apple M1
- Detected MoltenVK
- Enumerated Vulkan extensions
- Enumerated GPU features
- Began Vulkan device creation

However, MoltenVK then reported:

```text
VK_ERROR_FEATURE_NOT_PRESENT
```

including:

```text
vkCreateDevice(): Requested physical device feature
is not available on this device.
```

MoltenVK also reported:

```text
Metal does not support buffer robustness.
```

DXVK ultimately failed with:

```text
DxvkAdapter: Failed to create device
```

WoW then displayed its generic error:

```text
World of Warcraft was unable to start up 3D acceleration.
Please make sure DirectX 9.0c is installed and your video
drivers are up-to-date.
```

### This was not a missing DirectX 9.0c installation

Installing DirectX 9.0c was therefore not the solution.

Instead, bypassing DXVK immediately allowed the client to launch:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

The working graphics path is therefore:

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

---

# Resolution and fullscreen

There are currently some quirks with resolution enumeration and fullscreen mode.

## No resolutions listed

During testing, a normal Wine launch sometimes caused WoW to report:

```text
SET gxResolution "0x0"
```

The in-game resolution list would consequently be empty.

Launching through a Wine virtual desktop caused display modes to be enumerated correctly:

```bash
./scripts/run-wow-desktop.sh
```

The equivalent command is:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 "./Wow-64.exe"
```

On the tested M1 MacBook Air, Wine correctly detected the macOS logical Retina resolution as:

```text
1680x1050
```

and exposed the available display modes to WoW.

---

## Fullscreen

WoW's own Direct3D fullscreen switching did not work reliably in the tested configuration.

There is a much simpler solution.

Leave WoW in:

```text
Windowed
```

Then click the **green macOS window button**.

macOS will place the Wine/WoW window into native macOS fullscreen.

This provides fullscreen gameplay while allowing WoW to remain in its stable windowed Direct3D mode.

---

# Create a normal macOS application

WoW can be launched from Finder, Launchpad or the Dock without opening Terminal.

Instructions are available here:

```text
docs/macos-app.md
```

The resulting application can appear in:

```text
/Applications
```

just like any other macOS application.

The launcher internally starts WoW using:

```text
WINEDLLOVERRIDES=d3d9=b
```

so the known-good WineD3D configuration is preserved.

A custom icon can also be applied through Finder.

---

# Graphics performance

WineD3D successfully runs the game, but its performance characteristics are different from running Direct3D natively on Windows.

The overall MoP graphics slider can therefore become expensive at higher presets.

On the tested M1 MacBook Air, lower/moderate presets were substantially smoother than the higher presets.

Rather than simply reducing everything to Low, consider tuning expensive options individually.

Good candidates include:

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

Textures can often remain relatively high without the same performance impact as effects such as shadows and SSAO.

Performance tuning is still ongoing.

---

# Automatic detection

The scripts share:

```text
scripts/common.sh
```

which performs environment discovery.

## Wine detection

The scripts check common Wine locations and the user's `PATH`.

You can override detection at any time:

```bash
export WINE="/custom/path/to/wine"
```

## Prefix detection

Known/common prefix locations are checked automatically.

If a prefix contains:

```text
drive_c/Wow-64.exe
```

it is preferred over a generic Wine prefix.

You can override detection with:

```bash
export WINEPREFIX="/custom/path/to/prefix"
```

## WoW detection

The scripts look for:

```text
$WINEPREFIX/drive_c/Wow-64.exe
```

You can explicitly specify another executable with:

```bash
export WOW_EXE="/path/to/Wow-64.exe"
```

Then run:

```bash
./scripts/run-wow.sh
```

---

# Project structure

```text
wow-mop-apple-silicon/
├── README.md
├── LICENSE
├── .gitignore
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
    ├── create-prefix.sh
    ├── isolate-user-folders.sh
    ├── run-wow.sh
    └── run-wow-desktop.sh
```

---

# Troubleshooting

More detailed troubleshooting information is available in:

```text
docs/troubleshooting.md
```

Some useful checks are included below.

## Check Wine

```bash
./scripts/run-wow.sh
```

will print the detected Wine installation and version before starting the game.

Known-good:

```text
wine-11.17 (Staging)
```

---

## Check user-folder mappings

```bash
find "$WINEPREFIX/drive_c/users/$USER" \
    -maxdepth 1 -type l -ls
```

If Desktop, Documents, Pictures, Music or Videos point directly into `/Users/...`, run:

```bash
./scripts/isolate-user-folders.sh
```

---

## 3D acceleration error

If you see:

```text
World of Warcraft was unable to start up 3D acceleration.
```

and DXVK is installed, try:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

or simply use:

```bash
./scripts/run-wow.sh
```

which applies this override automatically.

---

# Tested vs expected

This repository currently documents **one confirmed working Apple Silicon configuration**.

Confirmed:

```text
Apple M1
macOS 26
Wine Staging 11.17
WoW 5.4.8 build 18414
TwinStar / Helios
WineD3D
D3D9
Wow-64.exe
```

Other configurations should currently be considered experimental until reported by users.

In particular, testing would be useful on:

- M1 Pro
- M1 Max
- M1 Ultra
- M2
- M2 Pro / Max / Ultra
- M3 family
- M4 family
- Other macOS releases
- Other Wine releases
- Other MoP 5.4.8 distributions

---

# Reporting compatibility

If you test another configuration, please open an issue and include:

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

If the game fails, logs are extremely useful.

---

# Contributing

Pull requests and compatibility reports are welcome.

Useful contributions include:

- Testing other Apple Silicon generations
- Testing newer Wine versions
- Improving automatic Wine detection
- Improving prefix discovery
- Graphics-performance tuning
- Fullscreen/display improvements
- Launcher improvements
- Documentation corrections

Please do not submit copyrighted World of Warcraft client files or proprietary third-party binaries.

---

# Legal

This is an independent compatibility/documentation project.

It does **not** distribute:

- World of Warcraft
- Blizzard game data
- TwinStar/Helios client files
- Microsoft runtimes
- Wine binaries

Users must obtain all required third-party software themselves from the appropriate sources.

World of Warcraft, Warcraft, Mists of Pandaria, Blizzard Entertainment and related names, artwork and trademarks are the property of their respective owners.

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