# Experimental D9MT / DXMT Metal Backend for WoW 5.4.8 on Apple Silicon

> **Status:** Experimental / paused  
> **Last tested:** September 2026  
> **Development machine:** Apple M1 MacBook Air, 16 GB  
> **Target game:** World of Warcraft 5.4.8 build 18414, 64-bit client  
> **Wine:** Wine Staging 11.17  
> **Result:** WoW renders through the experimental D3D9 → Metal path, but entering the world eventually triggers a Metal `Invalid Resource` command-buffer error and stalls.

This document preserves the experimental work carried out while investigating a native Metal rendering path for WoW 5.4.8 on Apple Silicon.

The normal, supported configuration in this repository remains WineD3D. The work documented here is **not production-ready**. It is archived so the investigation can be resumed without reconstructing the work from scratch.

---

## 1. Why this experiment existed

WoW 5.4.8 uses Direct3D 9.

The working Apple Silicon configuration is:

```text
WoW 5.4.8
    ↓ D3D9
Wine builtin d3d9
    ↓
WineD3D
    ↓ OpenGL
macOS / Apple GPU
```

This works, but performance is limited and graphical issues were observed, including vegetation/tree flickering.

DXVK 1.10.3 was also tested:

```text
WoW
    ↓ D3D9
DXVK
    ↓ Vulkan
MoltenVK
    ↓ Metal
Apple GPU
```

That failed during Vulkan device creation with:

```text
VK_ERROR_FEATURE_NOT_PRESENT
DxvkAdapter: Failed to create device
```

The next experiment was therefore **d9mt**, which provides a D3D9 frontend backed by DXMT/WineMetal:

```text
WoW 5.4.8
    ↓ D3D9
d9mt d3d9.dll
    ↓
d9mtmetal
    ↓
DXMT winemetal
    ↓
Metal
    ↓
Apple GPU
```

The objective was to use this with standalone open-source Wine Staging rather than CrossOver.

---

## 2. Source trees used

The development copies were:

```text
~/Developer/d9mt
~/Developer/dxmt-v0.80
~/Developer/wine-11.17-source
~/Developer/wine-11.17-build-x86_64
```

### d9mt

Upstream repository:

```text
https://github.com/neo773/d9mt
```

Upstream commit at the start of the experiment:

```text
237e293
tooling: apitrace D3D9 capture harness (run-apitrace.sh)
```

Local experimental branch:

```text
wine-11.17-gcenx
```

### DXMT

DXMT v0.80 source was used.

Commit:

```text
589adb780354b461645b29999cefaf533594ee99
```

Local experimental branch:

```text
wine-11.17-gcenx
```

### Wine

Official Wine 11.17 source was checked out.

Commit:

```text
36b6a2cf679fb395f668a917b76537190e212d9c
```

Local branch:

```text
d9mt-winemetal-bridge
```

---

## 3. Archived patches

The modifications made during this experiment are stored alongside this document:

```text
experimental/
├── README.md
├── d9mt-wine-11.17.patch
├── dxmt-wine-11.17.patch
└── wine-11.17-macdrv-metal-bridge.patch
```

### `d9mt-wine-11.17.patch`

Contains changes to:

```text
src/d9mtmetal/dll.c
tools/build-d9mtmetal.sh
```

This includes the Wine 11.17 Unix-call compatibility work.

### `dxmt-wine-11.17.patch`

Contains changes to:

```text
meson.build
src/airconv/shaders/air_tessellation.metal
src/winemetal/unix/winemetal_unix.c
```

This contains:

- Xcode 27 build compatibility
- Metal shader compatibility work
- Wine 11.17 Metal bridge integration
- command-buffer diagnostics
- render encoder diagnostics
- presentation diagnostics
- blit diagnostics
- resource-property diagnostics

### `wine-11.17-macdrv-metal-bridge.patch`

Contains changes to:

```text
dlls/winemac.drv/macdrv.h
dlls/winemac.drv/window.c
```

This implements the experimental bridge between DXMT WineMetal and Wine 11.17's current macOS driver internals.

---

## 4. Development toolchain

The experiment was performed on:

```text
Apple M1 MacBook Air
16 GB RAM
macOS 26.6.2
Xcode 27.0
```

Relevant Homebrew dependencies included:

```text
mingw-w64
glslang
cmake
meson
ninja
pkgconf
bison
llvm@15
```

The Homebrew LLVM 15 binaries/libraries were ARM64 and therefore unsuitable for the required x86_64 WineMetal build.

An x86_64 Darwin LLVM 15.0.7 toolchain was therefore built separately at:

```text
~/Developer/toolchains/llvm-darwin-15-x86_64
```

A dedicated Meson environment was used:

```text
~/Developer/dxmt-v0.80/.venv-meson110
```

The Metal Toolchain component was installed using Xcode:

```bash
sudo xcodebuild -downloadComponent MetalToolchain
```

A significant Xcode 27 issue was that:

```bash
xcrun -sdk macosx metal
```

did not work correctly for this build.

Direct lookup worked:

```bash
xcrun --find metal
```

and the DXMT Meson build was adjusted to invoke:

```bash
xcrun metal
```

---

## 5. Experimental Wine installation

The known-good Wine installation was deliberately left untouched.

A disposable copy was created:

```text
~/Games/Wine-d9mt/Wine Staging d9mt.app
```

Its Wine root was:

```bash
D9MT_WINE_ROOT="$HOME/Games/Wine-d9mt/Wine Staging d9mt.app/Contents/Resources/wine"
```

The experimental prefix was:

```text
~/Games/WoW-MoP-d9mt/prefix
```

The WoW copy was:

```text
~/Games/WoW-MoP-d9mt/prefix/drive_c/WoW
```

This isolation was important because the experiment replaced components inside the Wine runtime.

---

## 6. Initial DXMT WineMetal integration

DXMT's prebuilt WineMetal files were fetched using:

```bash
cd ~/Developer/d9mt
bash scripts/fetch-winemetal.sh
```

The fetched DXMT v0.80 components included:

```text
libwinemetal.a
winemetal.dll
winemetal.so
winemetal32.def
winemetal32.dll
```

`winemetal.so` was x86_64 Mach-O.

The Gcenx Wine layout matched the expected Wine directory structure:

```text
lib/wine/x86_64-unix
lib/wine/x86_64-windows
lib/wine/i386-windows
```

WineMetal was installed only into the disposable Wine copy.

Registry override:

```text
winemetal=builtin
```

---

## 7. Wine 11.17 Unix-call ABI issue

d9mt initially expected a Wine Unix-call interface that did not match Wine 11.17.

Wine 11.17 exports:

```text
__wine_unix_call_dispatcher
```

rather than using the older direct arrangement expected by the d9mt bridge.

The d9mt bridge was modified to use the dispatcher and import it as data.

This produced:

```text
d9mtmetal.dll
d9mtmetal.so
```

Both were installed into the experimental Wine runtime.

Registry override:

```text
d9mtmetal=builtin
```

A PE → Wine → Unix-library smoke test succeeded.

The test invoked a d9mt Unix function and returned:

```text
STATUS_SUCCESS
```

This established that the following bridge worked:

```text
Windows PE
    ↓
d9mtmetal.dll
    ↓
Wine 11.17 Unix-call dispatcher
    ↓
d9mtmetal.so
```

---

## 8. Building the x86_64 D3D9 frontend

Although upstream tooling was primarily oriented around i686, the d9mt frontend was successfully compiled for x86_64.

A 64-bit WineMetal import library was generated from the 64-bit WineMetal DLL exports.

The resulting D3D9 library was:

```text
build/d3d9-x64.dll
```

It was PE32+ x86-64 and exported the standard D3D9 entry points, including:

```text
Direct3DCreate9
Direct3DCreate9Ex
```

Its imports included:

```text
KERNEL32
USER32
UCRT components
d9mtmetal.dll
winemetal.dll
```

A loader test using:

```text
d3d9=n
d9mtmetal=b
winemetal=b
```

succeeded.

---

## 9. The Wine macdrv incompatibility

The first real D3D9 triangle test reached Metal device creation but failed at device creation with:

```text
D3DERR_NOTAVAILABLE
0x8876086a
```

Diagnostics showed:

```text
Direct3DCreate9(SDK 32)
Init: Metal device 'Apple M1', 800x600, hwnd=...
Init: CreateMetalViewFromHWND failed (view=0 layer=0)
```

This proved:

- WineMetal could enumerate the Apple M1 Metal device.
- Metal command queue creation worked.
- The failure was the HWND → Cocoa view → CAMetalLayer path.

### Root incompatibility

DXMT v0.80 expected an older Wine macdrv structure resembling:

```c
struct macdrv_win_data {
    HWND hwnd;
    macdrv_window cocoa_window;
    macdrv_view cocoa_view;
    macdrv_view client_cocoa_view;
};
```

Wine 11.17 instead uses:

```c
struct macdrv_win_data
{
    HWND hwnd;
    macdrv_window cocoa_window;
    macdrv_view client_view;
    struct window_rects rects;
    ...
};
```

DXMT also attempted to locate old private macdrv functions using `dlsym`.

Current Wine hides these internal functions because of symbol visibility.

Simply replacing `client_cocoa_view` with `client_view` did **not** solve the problem because `client_view` is transient and can legitimately be `NULL`.

---

## 10. Wine 11.17 Metal bridge

Two explicit exported bridge functions were added to Wine's macOS driver.

Conceptually:

```c
macdrv_create_metal_view_from_hwnd(...)
macdrv_release_metal_view_for_winemetal(...)
```

The DXMT WineMetal implementation was changed to use:

```c
dlsym(RTLD_DEFAULT, "macdrv_create_metal_view_from_hwnd")
```

rather than attempting to access obsolete Wine internals.

The release path similarly used:

```c
dlsym(RTLD_DEFAULT, "macdrv_release_metal_view_for_winemetal")
```

A custom x86_64 `winemac.so` was built from official Wine 11.17 source.

The bridge symbols were confirmed exported.

The patched `winemac.so` was then installed into the disposable Gcenx Wine Staging runtime.

A normal Wine Notepad test succeeded, showing that the official patched Wine 11.17 `winemac.so` was sufficiently compatible with the Gcenx Wine Staging 11.17 runtime for ordinary window creation.

---

## 11. The `client_view == NULL` problem

Instrumentation produced:

```text
[winemac-bridge] get_win_data=...
[winemac-bridge] client_view=0x0 cocoa_window=...
[winemac-bridge] returning view=0x0 layer=0x0
```

This established that:

- the HWND was valid,
- `macdrv_win_data` existed,
- `cocoa_window` existed,
- but `client_view` did not yet exist.

Wine 11.17 creates the presentation view through its client-surface machinery.

A diagnostic bridge was therefore implemented which, when `client_view` was `NULL`:

1. released the `get_win_data()` lock,
2. called `macdrv_CreateClientSurface(hwnd, 0, FALSE)`,
3. reacquired the window data,
4. used the resulting `client_view`,
5. created a Metal view and obtained its CAMetalLayer.

Releasing the window-data lock before creating the client surface was important because the client-surface update/presentation path itself accesses the window data.

---

## 12. First major success: real D3D9 → Metal rendering

A small D3D9 triangle application was used as the first renderer test.

Command:

```bash
export WINEPREFIX="$HOME/Games/WoW-MoP-d9mt/prefix"
export WINE="$HOME/Games/Wine-d9mt/Wine Staging d9mt.app/Contents/Resources/wine/bin/wine"

cd "$WINEPREFIX/drive_c/d9mt-triangle"

WINEDLLOVERRIDES="d3d9=n;d9mtmetal=b;winemetal=b" \
"$WINE" ./triangle.exe
```

The bridge returned a valid Metal view and layer:

```text
Direct3DCreate9 OK
[winemac-bridge] client_view NULL; creating client surface
[winemac-bridge] after surface client_view=...
[winemac-bridge] metal_view=...
[winemac-bridge] metal_layer=...
CreateDevice OK
```

The test presented three frames.

A visible RGB triangle appeared in the Wine window.

This proved the complete rendering path:

```text
D3D9 application
    ↓
d9mt d3d9.dll
    ↓
d9mtmetal PE/Unix bridge
    ↓
DXMT WineMetal
    ↓
patched Wine 11.17 macdrv
    ↓
Cocoa view
    ↓
CAMetalLayer
    ↓
Metal
    ↓
Apple M1 GPU
```

This was no longer merely a loader test: actual D3D9 content was rendered by Metal.

---

## 13. WoW test

The experimental WoW client was staged at:

```text
~/Games/WoW-MoP-d9mt/prefix/drive_c/WoW
```

The custom x64 d9mt frontend was copied to:

```text
WoW/d3d9.dll
```

WoW was launched using:

```bash
export WINEPREFIX="$HOME/Games/WoW-MoP-d9mt/prefix"
export WINE="$HOME/Games/Wine-d9mt/Wine Staging d9mt.app/Contents/Resources/wine/bin/wine"

cd "$WINEPREFIX/drive_c/WoW"

WINEDLLOVERRIDES="d3d9=n;d9mtmetal=b;winemetal=b" \
"$WINE" "./Wow-64.exe"
```

### Result

WoW:

- started,
- rendered its UI,
- reached the login screen,
- accepted login,
- displayed the character/world loading screen,
- rendered through the d9mt/WineMetal/Metal path.

It then stalled while entering the world.

Therefore:

> **WoW 5.4.8 rendering through d9mt and Metal on an Apple M1 was proven. Gameplay was not achieved.**

---

## 14. Command-buffer investigation

An initial macOS process sample showed a thread repeatedly inside:

```text
_MTLCommandBuffer_waitUntilCompleted
```

This initially suggested a possible command-buffer synchronization problem.

WineMetal was instrumented to print command-buffer state before and after waiting.

Example successful sequence:

```text
[winemetal-cmdbuf] WAIT begin buffer=... status=2
[winemetal-cmdbuf] WAIT end buffer=... status=4 error=(none)
```

Status values:

```text
0 = NotEnqueued
1 = Enqueued
2 = Committed
3 = Scheduled
4 = Completed
5 = Error
```

The critical result was eventually captured:

```text
[winemetal-cmdbuf] WAIT end buffer=... status=5
error=Error Domain=MTLCommandBufferErrorDomain Code=9
"Invalid Resource (00000009:kIOGPUCommandBufferCallbackErrorInvalidResource)"
```

This was substantially more useful than the original apparent wait.

The command buffer was not merely hanging indefinitely: at least one important frame was reaching a Metal GPU error state.

---

## 15. Render and blit diagnostics

Additional instrumentation recorded render encoders, attachments, blits, presentation, and texture properties.

Before the failure, WoW performed many render passes, including multiple 512×512 intermediate targets.

The final presentation-sized render target observed during one failure was:

```text
1488x930
```

Example:

```text
[winemetal-render] ... colors:
c0=...(1488x930)
depth=...(1488x930)
stencil=...(1488x930)
```

The frame then used a texture-to-texture blit:

```text
src=...(1488x930x1)
dst=...(1488x930x1)
size=1488x930x1
```

and presented a drawable.

One captured failure sequence was:

```text
[winemetal-encoder] RENDER ...
[winemetal-encoder] BLIT ...
[winemetal-blit] TEX->TEX ...
[winemetal-present] ...
[winemetal-cmdbuf] WAIT begin ... status=2
[winemetal-cmdbuf] WAIT end ... status=5 error=...Invalid Resource...
```

### Texture properties

A successful smaller frame showed:

```text
src fmt=80 usage=5 storage=2 hazard=2
dst fmt=80 usage=23 storage=1 hazard=2
```

Another copy showed:

```text
src fmt=80 usage=5 storage=2 hazard=2
dst fmt=80 usage=5 storage=0 hazard=2
```

The experiment was paused while narrowing down which Metal resource or operation causes the GPU's `Invalid Resource` error during the transition into the game world.

---

## 16. Important unresolved issue: client-surface lifetime

The Wine bridge that enabled rendering was still diagnostic.

The bridge creates a Wine client surface when no `client_view` exists, but the returned `client_surface` was not yet given a correct long-term ownership model.

Relevant Wine APIs include:

```c
client_surface_create(...)
client_surface_add_ref(...)
client_surface_release(...)
client_surface_present(...)
update_client_surfaces(...)
detach_client_surfaces(...)
```

Wine's macOS client surface owns resources including:

```text
cocoa_view
metal_swapchain
```

The current bridge's release function only releases the Metal view.

Before treating this implementation as production-safe, the client-surface lifetime needs to be fixed.

A likely direction is to associate the Metal view returned to WineMetal with a retained Wine `client_surface`, then release the corresponding surface when WineMetal calls its Metal-view release operation.

Another possible direction is to redesign the bridge around Wine 11.17's modern Metal swapchain APIs instead of adapting the older DXMT view interface.

This should be resolved independently of the GPU `Invalid Resource` problem.

---

## 17. What was conclusively proven

The experiment established all of the following:

1. d9mt's D3D9 frontend can be built as x86_64 for this environment.
2. d9mt can be adapted to Wine Staging 11.17's Unix-call ABI.
3. DXMT WineMetal can run inside the standalone Gcenx Wine Staging 11.17 environment.
4. Wine 11.17's macdrv can be bridged to WineMetal without CrossOver.
5. A D3D9 test application successfully renders visible frames through Metal on an Apple M1.
6. WoW 5.4.8 itself starts and visibly renders through this path.
7. WoW reaches login and world loading using d9mt/WineMetal.
8. The current failure is associated with a Metal command buffer entering `MTLCommandBufferStatusError`.
9. Metal reports:
   `kIOGPUCommandBufferCallbackErrorInvalidResource`.
10. The experiment therefore progressed considerably beyond DLL loading or API initialization.

---

## 18. What was NOT proven

The following should not be claimed:

- WoW 5.4.8 gameplay works through d9mt on Apple Silicon.
- d9mt is stable with Wine 11.17.
- the current Wine client-surface bridge has correct lifetime semantics.
- the final invalid resource has been identified.
- the presentation blit is definitely the invalid operation merely because it occurs immediately before command-buffer completion.
- DXMT shared-event synchronization is the cause.
- the experimental path is currently faster than WineD3D.

At the point the experiment was paused, the Metal `Invalid Resource` failure was reproducible but its exact offending resource had not yet been isolated.

---

## 19. Suggested continuation point

If this work is resumed, do **not** restart from basic Wine/D3D9 investigation.

The rendering path is already proven.

Recommended next work:

1. Reconstruct the three source trees at the recorded commits.
2. Apply the patches in this directory.
3. Rebuild the x86_64 d9mt/DXMT/Wine components.
4. Restore the isolated experimental Wine runtime and prefix.
5. Verify the D3D9 triangle still renders.
6. Verify WoW reaches the same world-loading failure.
7. Finish the Wine client-surface ownership/lifetime implementation.
8. Instrument Metal resource creation/destruction and the operations encoded into the command buffer that first returns `Invalid Resource`.
9. Narrow the failing command buffer rather than assuming the final blit is responsible.
10. Once stable, remove diagnostic `fprintf()` logging and turn the build into reproducible project scripts.

Metal validation/debug facilities should also be investigated if they can provide more precise resource-lifetime diagnostics.

---

## 20. Experimental build notes

The Wine x86_64 build was configured approximately as:

```bash
cd "$HOME/Developer/wine-11.17-build-x86_64"

export PATH="/opt/homebrew/opt/bison/bin:$PATH"

CC="clang -arch x86_64" \
CXX="clang++ -arch x86_64" \
CFLAGS="-O2" \
CXXFLAGS="-O2" \
../wine-11.17-source/configure \
  --host=x86_64-apple-darwin \
  --enable-win64 \
  --without-freetype
```

The DXMT WineMetal build used approximately:

```bash
cd "$HOME/Developer/dxmt-v0.80"

.venv-meson110/bin/python -m mesonbuild.mesonmain setup \
  --cross-file build-win64.txt \
  -Dnative_llvm_path="$HOME/Developer/toolchains/llvm-darwin-15-x86_64" \
  -Dwine_build_path="$HOME/Developer/wine-11.17-build-x86_64" \
  build-winemetal-x64 \
  --buildtype release
```

WineMetal was rebuilt with:

```bash
ninja -C build-winemetal-x64 src/winemetal/unix/winemetal.so
```

The resulting binary was installed into the **experimental Wine only**:

```text
~/Games/Wine-d9mt/Wine Staging d9mt.app/Contents/Resources/wine/lib/wine/x86_64-unix/winemetal.so
```

The patched Wine macOS driver was similarly installed as:

```text
.../lib/wine/x86_64-unix/winemac.so
```

Do not overwrite a known-good Wine installation while reproducing this work.

---

## 21. Known-good fallback

The working non-experimental M1 configuration remained:

```bash
export WINEPREFIX="$HOME/Games/TwinStar/prefix-wine11"
export WINE="$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"

cd "$WINEPREFIX/drive_c"

WINEDLLOVERRIDES="d3d9=b" \
"$WINE" "./Wow-64.exe"
```

That uses Wine's builtin D3D9/WineD3D path rather than d9mt.

The repository's normal setup should continue to favour the proven WineD3D route unless the Metal backend work is resumed and stabilized.

---

## 22. Final state when paused

The experiment ended with:

```text
WoW D3D9
   ↓
d9mt x86_64 d3d9.dll
   ↓
d9mtmetal
   ↓
DXMT v0.80 WineMetal
   ↓
custom Wine 11.17 macdrv bridge
   ↓
Metal / Apple M1
```

**Working:**

```text
D3D9 initialization
Metal device creation
HWND → Cocoa/Metal view bridge
CAMetalLayer creation
D3D9 triangle rendering
WoW startup rendering
WoW login rendering
WoW loading-screen rendering
Metal presentation for many frames
```

**Remaining blocker:**

```text
MTLCommandBufferErrorDomain Code=9
kIOGPUCommandBufferCallbackErrorInvalidResource
```

during the heavier rendering workload encountered while entering the WoW world.

The patches in this directory are the authoritative archive of the source changes made during the experiment.
