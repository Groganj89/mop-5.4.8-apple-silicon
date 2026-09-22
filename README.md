# World of Warcraft: Mists of Pandaria 5.4.8 on Apple Silicon

Run the Windows **World of Warcraft: Mists of Pandaria 5.4.8 (build 18414)** client on Apple Silicon Macs using Wine.

This project provides an automated setup and documents a working compatibility configuration originally developed and tested using the **TwinStar / Helios** Mists of Pandaria client.

The goal is simple:

```text
Clone → Setup → Download WoW → Play
```

No World of Warcraft game files, Blizzard assets, TwinStar binaries, Wine binaries, or Microsoft runtimes are distributed by this repository.

---

## Current Status

### Confirmed working

| Component | Tested configuration |
|---|---|
| Mac | MacBook Air |
| Apple Silicon | M1 |
| Architecture | ARM64 + Rosetta 2 |
| macOS | macOS 26 |
| Wine | Wine Staging 11.17 |
| WoW | Mists of Pandaria 5.4.8 |
| Build | 18414 |
| Client | 64-bit `Wow-64.exe` |
| Server | TwinStar / Helios |
| Graphics API | Direct3D 9 |
| Graphics backend | WineD3D |

The tested configuration successfully:

- Launches the TwinStar Launcher
- Downloads and updates the WoW client
- Launches `Wow-64.exe`
- Connects to TwinStar / Helios
- Logs into an account
- Reaches character selection
- Enters the game world
- Renders 3D graphics
- Plays audio
- Supports macOS fullscreen
- Can be wrapped in a normal macOS `.app`

Testing on additional Apple Silicon generations is welcome.

---

# Quick Start

## Requirements

You need:

- An Apple Silicon Mac
- macOS
- Rosetta 2
- Wine Staging
- An internet connection
- Sufficient disk space for the WoW client

The known-good configuration was developed using:

```text
Wine Staging 11.17
```

---

## 1. Install Rosetta 2

If Rosetta is not already installed:

```bash
softwareupdate --install-rosetta --agree-to-license
```

If Rosetta is already present, macOS will simply report that it is installed.

---

## 2. Install Wine Staging

Install a current Wine Staging build for macOS.

Wine does **not** need to be installed in a specific directory.

The setup scripts automatically search common locations including:

```text
~/Games/Wine/Wine Staging.app
/Applications/Wine Staging.app
~/Applications/Wine Staging.app
/opt/homebrew/bin/wine
/opt/homebrew/bin/wine64
/usr/local/bin/wine
/usr/local/bin/wine64
```

The user's `PATH` is also checked.

If Wine is installed somewhere unusual, specify it manually:

```bash
export WINE="/path/to/wine"
```

---

## 3. Clone the repository

```bash
git clone https://github.com/Groganj89/mop-5.4.8-apple-silicon.git
cd mop-5.4.8-apple-silicon
```

---

## 4. Run the automated setup

Make the setup script executable:

```bash
chmod +x setup.sh
```

Then run:

```bash
./setup.sh
```

The setup process will:

1. Detect your Wine installation.
2. Create or reuse a dedicated Wine prefix.
3. Download and install the Microsoft .NET 8 Desktop Runtime.
4. Download the latest official TwinStar Launcher.
5. Start the TwinStar Launcher.
6. Allow TwinStar to download/update the WoW 5.4.8 client.
7. Detect `Wow-64.exe`.
8. Isolate macOS protected user folders from the Wine prefix.
9. Prepare the client for the known-good WineD3D configuration.

By default, the Wine prefix is created at:

```text
~/Games/WoW-MoP/prefix
```

---

# Downloading World of Warcraft

The setup script downloads and launches the **official TwinStar Launcher**.

TwinStar itself is responsible for downloading and updating the World of Warcraft client.

When choosing an installation location in the TwinStar Launcher, use a location inside the Wine `C:` drive.

Recommended:

```text
C:\WoW
```

This corresponds to:

```text
~/Games/WoW-MoP/prefix/drive_c/WoW
```

when using the default prefix.

Allow TwinStar to finish downloading the complete client before closing the launcher.

The resulting installation should contain:

```text
Wow-64.exe
```

The setup script will attempt to locate it automatically.

---

# Launching WoW

Once the client has been downloaded:

```bash
./scripts/run-wow.sh
```

The launcher automatically detects:

- Wine
- The Wine prefix
- `Wow-64.exe`

It then launches the game using:

```text
WINEDLLOVERRIDES=d3d9=b
```

This is important.

It forces Wine's **builtin Direct3D 9 implementation** instead of allowing a native `d3d9.dll`, such as DXVK, to take over.

---

# Why WineD3D?

Getting the graphics backend working was the main compatibility problem encountered during development.

WoW 5.4.8 uses:

```text
Direct3D 9
```

DXVK was initially tested as the D3D9 implementation.

The intended path was:

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

DXVK successfully:

- Loaded
- Detected the Apple M1 GPU
- Detected MoltenVK
- Enumerated Vulkan capabilities
- Began Vulkan device creation

However, MoltenVK then returned:

```text
VK_ERROR_FEATURE_NOT_PRESENT
```

During testing, errors included:

```text
vkCreateDevice(): Requested physical device feature
specified by the 5th flag in VkPhysicalDeviceFeatures
is not available on this device.
```

and:

```text
vkCreateDevice(): Requested physical device feature
specified by the 39th flag in VkPhysicalDeviceFeatures
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

## DirectX 9.0c was not the problem

That WoW error is misleading in this configuration.

Installing DirectX 9.0c was **not** required.

The actual failure was DXVK being unable to create the required Vulkan device through MoltenVK.

The breakthrough was launching WoW with:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

This bypasses DXVK for D3D9.

The confirmed working path is:

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

# macOS Protected Folders

Another important issue discovered during testing involved Wine's default Windows user-directory mappings.

Wine may create mappings such as:

```text
C:\users\<username>\Desktop
C:\users\<username>\Documents
C:\users\<username>\Pictures
C:\users\<username>\Music
C:\users\<username>\Videos
```

as symbolic links to the equivalent directories in:

```text
/Users/<username>/
```

On modern macOS versions, some of these directories are protected by macOS privacy controls.

During testing, these mappings resulted in privacy prompts and contributed to WoW failing to progress normally during startup.

The project therefore includes:

```bash
./scripts/isolate-user-folders.sh
```

This replaces Wine symlinks for:

```text
Desktop
Documents
Pictures
Music
Videos
```

with normal directories contained entirely inside the Wine prefix.

## Downloads is intentionally preserved

The script does **not** alter the Wine `Downloads` mapping.

This is intentional because downloaded installers and launcher files may still need to be accessed from the host macOS Downloads directory.

You can inspect the mappings yourself with:

```bash
find "$WINEPREFIX/drive_c/users/$USER" \
    -maxdepth 1 \
    -type l \
    -ls
```

---

# World of Warcraft Configuration

An example configuration is included at:

```text
config/Config.wtf.example
```

The most important graphics setting is:

```text
SET gxApi "D3D9"
```

A minimal configuration looks like:

```text
SET locale "enUS"
SET installLocale "enUS"
SET gxApi "D3D9"
SET hwDetect "0"
SET gxWindow "1"
SET gxMaximize "1"
```

Server-specific settings such as the `realmlist` should be configured for the server you use.

Do not publish personal configuration values such as:

```text
accountName
realmName
lastCharacterIndex
```

when sharing your own `Config.wtf`.

---

# Resolution Detection

Display-mode enumeration can behave strangely when WoW is launched normally through Wine.

During testing, WoW sometimes generated:

```text
SET gxResolution "0x0"
```

and displayed no selectable resolutions in the graphics menu.

A Wine virtual desktop caused display modes to enumerate correctly.

Use:

```bash
./scripts/run-wow-desktop.sh
```

The underlying launch method is:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" explorer /desktop=WoW,1920x1080 "./Wow-64.exe"
```

On the tested M1 MacBook Air, Wine correctly exposed the macOS logical Retina resolution:

```text
1680x1050
```

along with the other supported display modes.

---

# Fullscreen

WoW's own Direct3D fullscreen switching was unreliable during testing.

The simplest working solution is:

1. Leave WoW in **Windowed** mode.
2. Launch the game normally.
3. Click the **green macOS window button**.

macOS will place the Wine/WoW window into native macOS fullscreen.

This provides fullscreen gameplay while allowing WoW to remain in its stable windowed Direct3D mode.

---

# Graphics Performance

WineD3D successfully runs the game but introduces additional translation overhead compared with native Direct3D on Windows.

On the tested M1 MacBook Air, moderate graphics settings perform significantly better than the highest presets.

Instead of simply setting the entire graphics preset to Low, consider adjusting expensive settings individually.

Settings worth testing include:

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

Texture quality can often remain relatively high without the same performance penalty as effects such as shadows and SSAO.

Performance tuning is still ongoing.

---

# macOS Application Launcher

Once everything is working, WoW can be wrapped in a normal macOS `.app`.

Open **Script Editor** and create a script containing:

```applescript
do shell script "export WINEPREFIX=\"$HOME/Games/WoW-MoP/prefix\"; " & ¬
"export WINE=\"$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine\"; " & ¬
"cd \"$WINEPREFIX/drive_c/WoW\"; " & ¬
"WINEDLLOVERRIDES=\"d3d9=b\" \"$WINE\" \"./Wow-64.exe\" >/tmp/wow-mop.log 2>&1 &"
```

Adjust the Wine and WoW paths if your installation differs.

Choose:

```text
File → Export
```

Then use:

```text
File Format: Application
Stay open after run handler: Off
```

The resulting application can be placed in:

```text
/Applications
```

and launched normally through Finder, Spotlight, Launchpad, or the Dock.

## Custom icon

A custom icon can be assigned using Finder:

1. Open an image in Preview.
2. Press `Command-A`.
3. Press `Command-C`.
4. Select the application in Finder.
5. Press `Command-I`.
6. Click the application icon in the top-left corner.
7. Press `Command-V`.

If Finder or the Dock continues showing an old icon:

```bash
killall Finder
killall Dock
```

Do not redistribute copyrighted World of Warcraft artwork as part of this repository unless you have permission to do so.

---

# Manual Setup

The automated setup is recommended:

```bash
./setup.sh
```

However, every stage remains available separately.

## Create the Wine prefix

```bash
./scripts/create-prefix.sh
```

## Install .NET 8 Desktop Runtime

```bash
./scripts/install-dotnet.sh
```

This downloads and installs the current Windows x64 **Microsoft .NET 8 Desktop Runtime** into the Wine prefix.

The Desktop Runtime is required because the TwinStar Launcher uses WPF.

## Install/run TwinStar

```bash
./scripts/install-twinstar.sh
```

This downloads the current official TwinStar Launcher and starts it through Wine.

TwinStar then handles downloading and updating the WoW client.

## Isolate macOS user folders

```bash
./scripts/isolate-user-folders.sh
```

## Launch WoW

```bash
./scripts/run-wow.sh
```

## Launch using Wine virtual desktop

```bash
./scripts/run-wow-desktop.sh
```

---

# Automatic Detection

The helper scripts share:

```text
scripts/common.sh
```

which performs Wine, prefix, and client discovery.

## Wine

Wine is automatically detected from several common installation locations.

Detection can be overridden with:

```bash
export WINE="/custom/path/to/wine"
```

## Wine prefix

The default project prefix is:

```text
~/Games/WoW-MoP/prefix
```

A custom prefix can be specified before running setup:

```bash
export WINEPREFIX="$HOME/Games/My-MoP-Prefix"
./setup.sh
```

Existing supported prefixes containing `Wow-64.exe` are preferred when using the standalone helper scripts.

## WoW executable

The scripts look for:

```text
Wow-64.exe
```

inside the selected Wine prefix.

An explicit executable can also be supplied:

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
└── scripts/
    ├── common.sh
    ├── create-prefix.sh
    ├── install-dotnet.sh
    ├── install-twinstar.sh
    ├── isolate-user-folders.sh
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

locate your Wine executable and specify it manually:

```bash
export WINE="/path/to/wine"
./setup.sh
```

---

## .NET installation fails

The TwinStar Launcher requires:

```text
Microsoft.WindowsDesktop.App 8.x
```

The installer script verifies the runtime after installation.

You can manually inspect installed runtimes with:

```bash
"$WINE" \
"C:\\Program Files\\dotnet\\dotnet.exe" \
--list-runtimes
```

You should see an entry similar to:

```text
Microsoft.WindowsDesktop.App 8.x.x
```

---

## TwinStar opens but WoW is not detected

Make sure the TwinStar Launcher has completely finished downloading the game.

The Wine prefix must contain:

```text
Wow-64.exe
```

You can search for it manually:

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

If WoW reports:

```text
World of Warcraft was unable to start up 3D acceleration.
```

do **not** immediately install DirectX 9.0c.

If DXVK is present, bypass it:

```bash
WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

The supplied launcher already does this automatically:

```bash
./scripts/run-wow.sh
```

---

## No resolutions appear

Try:

```bash
./scripts/run-wow-desktop.sh
```

This runs WoW inside a Wine virtual desktop and can cause the correct macOS display modes to be enumerated.

---

## Fullscreen does not work

Leave WoW in Windowed mode and use the green macOS window button.

This was more reliable during testing than WoW's native fullscreen mode switching.

---

# Clean Installation Testing

This project was developed by debugging an existing working environment, so clean-install testing is particularly valuable.

If testing a new Mac, please:

1. Clone the repository fresh.
2. Follow this README without manually compensating for errors.
3. Run `./setup.sh`.
4. Report any point where the documented process differs from reality.

This helps identify assumptions accidentally inherited from the original development machine.

---

# Compatibility Testing

The initial confirmed configuration is:

```text
Mac: MacBook Air
SoC: Apple M1
macOS: macOS 26
Wine: Wine Staging 11.17
WoW: 5.4.8.18414
Client: TwinStar / Helios
Executable: Wow-64.exe
Graphics API: Direct3D 9
Backend: WineD3D
```

Testing is particularly wanted on:

- M1 Pro
- M1 Max
- M1 Ultra
- M2
- M2 Pro
- M2 Max
- M2 Ultra
- M3
- M3 Pro
- M3 Max
- M4
- M4 Pro
- M4 Max
- Different macOS releases
- Different Wine releases
- Other MoP 5.4.8 client distributions

---

# Reporting Compatibility

If you successfully test another configuration, please open a GitHub issue and include:

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

Pull requests, compatibility reports, bug reports, and documentation improvements are welcome.

Particularly useful contributions include:

- Testing additional Apple Silicon generations
- Testing newer Wine releases
- Improving Wine detection
- Improving prefix/client discovery
- Graphics-performance tuning
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

Users must obtain all required third-party software themselves from the appropriate sources.

World of Warcraft, Warcraft, Mists of Pandaria, Blizzard Entertainment, and related names, artwork, and trademarks are the property of their respective owners.

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