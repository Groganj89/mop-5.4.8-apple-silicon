# Creating a macOS application

WoW can be wrapped in a small AppleScript application so that it can be launched directly from `/Applications`.

Open **Script Editor** on macOS and create a new script containing:

```applescript
do shell script "export WINEPREFIX=\"$HOME/Games/TwinStar/prefix-wine11\"; " & ¬
"export WINE=\"$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine\"; " & ¬
"cd \"$WINEPREFIX/drive_c\"; " & ¬
"WINEDLLOVERRIDES=\"d3d9=b\" \"$WINE\" \"./Wow-64.exe\" >/tmp/twinstar-wow.log 2>&1 &"
```

Choose:

**File → Export**

Use:

```text
Export As: TwinStar WoW
Where: Applications
File Format: Application
Stay open after run handler: Off
```

The resulting application can then be launched normally from Finder or Launchpad.

## Fullscreen

Keep WoW itself in Windowed mode.

Once the game has launched, click the green macOS window control to place the Wine window into macOS native fullscreen.

This avoids WoW's unreliable Direct3D fullscreen mode switching.

## Custom icon

A custom icon can be applied using Finder:

1. Copy a square image in Preview.
2. Select the application in Finder.
3. Press `Command-I`.
4. Select the small application icon in the top-left corner.
5. Paste the image.

If Finder or Launchpad continues showing the previous icon:

```bash
killall Finder
killall Dock
```

Do not redistribute copyrighted World of Warcraft artwork as part of this repository unless you have permission to do so.