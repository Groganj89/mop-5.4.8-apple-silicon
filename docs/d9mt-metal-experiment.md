# Experimental D3D9 → Metal Work for WoW 5.4.8 on Apple Silicon

> **Status:** Experimental / unfinished  
> **Development machine:** Apple M1 MacBook Air  
> **Target game:** World of Warcraft: Mists of Pandaria 5.4.8 build 18414  
> **Last worked on:** September 2026

This document records the experimental work carried out to run the 64-bit WoW 5.4.8 client through a native Metal rendering path on Apple Silicon using Wine, d9mt, and DXMT.

This work is intentionally preserved as a technical checkpoint. It is **not currently the supported/default rendering path for this project**.

The project's normal WineD3D-based setup remains functional. The work below was an attempt to improve graphics performance and compatibility by replacing the D3D9 → WineD3D → OpenGL path with a D3D9 → Metal path.

---

## 1. Background

WoW 5.4.8 build 18414 uses Direct3D 9.

The working configuration on Apple Silicon is:

```text
WoW 5.4.8
    ↓
Direct3D 9
    ↓
Wine builtin d3d9
    ↓
WineD3D
    ↓
OpenGL/macOS
    ↓
Apple GPU
```

A known-good launch on the M1 development machine was:

```bash
export WINEPREFIX="$HOME/Games/TwinStar/prefix-wine11"
export WINE="$HOME/Games/Wine/Wine Staging.app/Contents/Resources/wine/bin/wine"

cd "$WINEPREFIX/drive_c"

WINEDLLOVERRIDES="d3d9=b" "$WINE" "./Wow-64.exe"
```

This works, but higher graphics settings perform poorly and vegetation/tree rendering has exhibited flickering.

DXVK 1.10.3 was also tested previously. It failed while creating the Vulkan device through MoltenVK with:

```text
VK_ERROR_FEATURE_NOT_PRESENT
DxvkAdapter: Failed to create device
```

That led to investigation of a direct Metal route.

---

## 2. d9mt / DXMT Approach

The project investigated:

- d9mt: D3D9 frontend based on the DXVK D3D9 implementation
- DXMT: Metal backend / `winemetal`
- Wine Staging 11.17
- Apple Metal

The intended rendering path was:

```text
WoW 5.4.8
    ↓
D3D9
    ↓
d9mt d3d9.dll
    ↓
d9mtmetal Wine bridge
    ↓
DXMT winemetal
    ↓
Metal
    ↓
Apple GPU
```

This was pursued without CrossOver. The goal was to determine whether the open-source components could be made to work with standalone Wine Staging.

---

## 3. Versions Used

### d9mt

Source:

```text
~/Developer/d9mt
```

Upstream commit at the start of the work:

```text
237e293
tooling: apitrace D3D9 capture harness (run-apitrace.sh)
```

A local branch named:

```text
wine-11.17-gcenx
```

was used for Wine 11.17 compatibility work.

### DXMT

DXMT release:

```text
v0.80
```

Source:

```text
~/Developer/dxmt-v0.80
```

Commit:

```text
589adb780354b461645b29999cefaf533594ee99
```

A local branch named:

```text
wine-11.17-gcenx
```

was used.

### Wine

Runtime:

```text
Wine Staging 11.17
```

Known-good Wine installation:

```text
~/Games/Wine/Wine Staging.app
```

A separate experimental Wine copy was deliberately created:

```text
~/Games/Wine-d9mt/Wine Staging d9mt.app
```

The working Wine installation was never intended to be modified by this experiment.

Official Wine 11.17 source:

```text
~/Developer/wine-11.17-source
```

Commit:

```text
36b6a2cf679fb395f668a917b76537190e212d9c
```

64-bit Wine build directory:

```text
~/Developer/wine-11.17-build-x86_64
```

### LLVM

An x86_64 Darwin build of LLVM 15.0.7 was created at:

```text
~/Developer/toolchains/llvm-darwin-15-x86_64
```

Homebrew LLVM 15 could not be used for the relevant Unix Wine components because the Homebrew libraries were arm64 while `winemetal.so` needed to be x86_64.

---

## 4. Development Dependencies

The M1 development machine had:

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

Relevant compiler/tool paths included:

```text
/opt/homebrew/bin/i686-w64-mingw32-gcc
/opt/homebrew/bin/x86_64-w64-mingw32-gcc
/opt/homebrew/bin/glslangValidator
/opt/homebrew/bin/cmake
/opt/homebrew/bin/meson
/opt/homebrew/bin/ninja
/opt/homebrew/opt/bison/bin/bison
```

Full Xcode was installed.

The Metal Toolchain was installed with:

```bash
sudo xcodebuild -downloadComponent MetalToolchain
```

A direct Metal compiler lookup worked:

```bash
xcrun --find metal
```

Using:

```bash
xcrun -sdk macosx metal
```

caused problems with the Xcode version used during the experiment.

---

## 5. Experimental Prefix

A completely separate prefix was used:

```text
~/Games/WoW-MoP-d9mt/prefix
```

The disposable WoW installation was:

```text
~/Games/WoW-MoP-d9mt/prefix/drive_c/WoW
```

The original known-good WoW files remained under:

```text
~/Games/TwinStar/prefix-wine11/drive_c
```

---

## 6. DXMT winemetal Installation

d9mt's fetch script downloaded DXMT v0.80:

```bash
bash scripts/fetch-winemetal.sh
```

The resulting files included:

```text
libwinemetal.a
winemetal.dll
winemetal.so
winemetal32.def
winemetal32.dll
```

`winemetal.so` was Mach-O x86_64.

The expected Wine layout was compatible with the Gcenx Wine bundle:

```text
lib/wine/i386-windows/
lib/wine/x86_64-windows/
lib/wine/x86_64-unix/
```

The experimental Wine installation received:

```text
winemetal32.dll → lib/wine/i386-windows/winemetal.dll
winemetal.dll   → lib/wine/x86_64-windows/winemetal.dll
winemetal.so    → lib/wine/x86_64-unix/winemetal.so
```

Registry configuration used:

```text
winemetal=builtin
```

The PE builtin loader test succeeded.

---

## 7. Wine 11.17 Unix Call ABI Adaptation

The Wine runtime exported:

```text
__wine_unix_call_dispatcher
```

rather than exposing the direct interface expected by the original d9mt bridge.

Wine 11.17 source confirmed that `__wine_unix_call()` ultimately invokes:

```text
__wine_unix_call_dispatcher
```

The d9mt bridge was modified to use the dispatcher and import it appropriately.

This produced:

```text
d9mtmetal.dll
d9mtmetal.so
```

Both were installed only into the experimental Wine environment.

Registry configuration:

```text
d9mtmetal=builtin
```

A PE → Wine → Unixlib smoke test succeeded.

The test reached a d9mt Unix function and returned:

```text
STATUS_SUCCESS
```

This proved the following bridge worked:

```text
Windows PE
    ↓
d9mtmetal.dll
    ↓
Wine Unix-call dispatcher
    ↓
d9mtmetal.so
```

It did not yet prove rendering.

---

## 8. x86_64 D3D9 Frontend

The upstream d9mt build scripts were primarily oriented around i686, but the source was successfully compiled for x86_64.

A 64-bit import library was generated from the exports of the 64-bit `winemetal.dll`.

The resulting frontend was:

```text
build/d3d9-x64.dll
```

It was a PE32+ x86-64 DLL.

Imports included:

```text
KERNEL32
USER32
UCRT components
d9mtmetal.dll
winemetal.dll
```

It exported the expected D3D9 entry points, including:

```text
Direct3DCreate9
Direct3DCreate9Ex
```

A loader test using:

```text
d3d9=n
d9mtmetal=b
winemetal=b
```

succeeded.

---

## 9. First D3D9 Triangle Test

A small D3D9 triangle program was built:

```text
test/triangle.c
```

It was staged under:

```text
~/Games/WoW-MoP-d9mt/prefix/drive_c/d9mt-triangle
```

Launch command:

```bash
cd "$WINEPREFIX/drive_c/d9mt-triangle"

WINEDLLOVERRIDES="d3d9=n;d9mtmetal=b;winemetal=b" \
"$WINE" ./triangle.exe
```

Initially:

```text
Direct3DCreate9 OK
CreateDevice failed: 0x8876086a
```

The d9mt log showed:

```text
Init: Metal device 'Apple M1', 800x600
Init: CreateMetalViewFromHWND failed (view=0 layer=0)
```

This established that Metal device enumeration and command queue creation worked, but conversion of the Wine HWND into a usable native Metal view/layer did not.

---

## 10. DXMT / Wine macdrv Compatibility Problem

DXMT v0.80 contained assumptions about older Wine macOS driver internals.

Its implementation expected an old `macdrv_win_data` layout resembling:

```c
struct macdrv_win_data {
    HWND hwnd;
    macdrv_window cocoa_window;
    macdrv_view cocoa_view;
    macdrv_view client_cocoa_view;
};
```

Wine 11.17 instead used a structure resembling:

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

DXMT also attempted to dynamically locate older private macdrv functions such as:

```text
get_win_data
release_win_data
macdrv_view_create_metal_view
macdrv_view_get_metal_layer
macdrv_view_release_metal_view
```

Those were not available as dynamic exports in the Gcenx Wine runtime.

This was the first major compatibility barrier.

---

## 11. Wine macdrv Bridge

Official Wine 11.17 source was patched to expose a small, explicit bridge instead of having DXMT depend directly on Wine's private `macdrv_win_data` layout.

An exported create function was introduced:

```c
extern __attribute__((visibility("default"))) macdrv_metal_view
macdrv_create_metal_view_from_hwnd(HWND hwnd,
                                   macdrv_metal_device device,
                                   macdrv_metal_layer *layer);
```

A release function was also introduced:

```c
extern __attribute__((visibility("default"))) void
macdrv_release_metal_view_for_winemetal(macdrv_metal_view view);
```

The initial release implementation called:

```c
macdrv_view_release_metal_view(view);
```

The patched `winemac.so` exported:

```text
_macdrv_create_metal_view_from_hwnd
_macdrv_release_metal_view_for_winemetal
```

The custom `winemac.so` was built as x86_64.

---

## 12. DXMT Bridge Adaptation

DXMT's `_CreateMetalViewFromHWND` was changed to dynamically resolve:

```text
macdrv_create_metal_view_from_hwnd
```

instead of reading Wine's private window structure itself.

Conceptually:

```c
pfn_create_metal_view_from_hwnd =
    dlsym(RTLD_DEFAULT, "macdrv_create_metal_view_from_hwnd");

params->ret_view = 0;
params->ret_layer = 0;

if (pfn_create_metal_view_from_hwnd)
{
    macdrv_metal_layer layer = NULL;
    macdrv_metal_view view =
        pfn_create_metal_view_from_hwnd(
            (HWND)params->hwnd,
            (macdrv_metal_device)params->device,
            &layer);

    params->ret_view = (obj_handle_t)view;
    params->ret_layer = (obj_handle_t)layer;
}
```

`_ReleaseMetalView` similarly resolved:

```text
macdrv_release_metal_view_for_winemetal
```

This removed DXMT's direct dependency on the obsolete private Wine structure layout.

---

## 13. Building winemetal.so

A Meson environment was used under:

```text
~/Developer/dxmt-v0.80/.venv-meson110
```

Setup was approximately:

```bash
cd "$HOME/Developer/dxmt-v0.80"

.venv-meson110/bin/python -m mesonbuild.mesonmain setup \
  --cross-file build-win64.txt \
  -Dnative_llvm_path="$HOME/Developer/toolchains/llvm-darwin-15-x86_64" \
  -Dwine_build_path="$HOME/Developer/wine-11.17-build-x86_64" \
  build-winemetal-x64 \
  --buildtype release
```

The Metal generator also needed adjustment for the installed Xcode version.

A Metal atomic operation required an explicit cast:

```cpp
return atomic_fetch_add_explicit(
    reinterpret_cast<threadgroup atomic_int *>(out_count),
    1,
    memory_order_relaxed);
```

The Unix library was then successfully built:

```bash
ninja -C build-winemetal-x64 src/winemetal/unix/winemetal.so
```

Result:

```text
~/Developer/dxmt-v0.80/build-winemetal-x64/src/winemetal/unix/winemetal.so
```

It was Mach-O x86_64.

---

## 14. Experimental Wine Compatibility

The patched Wine `winemac.so` and patched DXMT `winemetal.so` were installed only into:

```text
~/Games/Wine-d9mt/Wine Staging d9mt.app
```

Backups were kept during development.

A normal Wine smoke test was performed:

```bash
"$WINE" --version
"$WINE" notepad
```

Wine reported:

```text
wine-11.17 (Staging)
```

Notepad opened and remained interactive.

This demonstrated that the custom Wine macdrv build was sufficiently compatible with the Gcenx Wine Staging runtime for basic window creation.

---

## 15. `client_view` Discovery

Instrumentation showed that the new Wine bridge successfully located the HWND's `macdrv_win_data`.

However:

```text
client_view = NULL
cocoa_window != NULL
```

This explained why simply replacing DXMT's old `client_cocoa_view` access with Wine 11.17's `client_view` was insufficient.

Wine 11.17 treats the client view as transient.

Investigation of Wine's client-surface implementation found APIs including:

```text
client_surface_create
client_surface_add_ref
client_surface_release
client_surface_present
client_surface_update
use_window_client_surface
```

and macdrv functions including:

```text
macdrv_CreateClientSurface
macdrv_client_surface_acquire_metal_swapchain
```

Modern Wine's Metal/Vulkan presentation path operates around these client surfaces rather than assuming a permanently available Cocoa client view.

---

## 16. Diagnostic Client-Surface Workaround

For diagnostic purposes, the Wine bridge was changed so that when:

```text
data->client_view == NULL
```

it would:

1. Release the `get_win_data()` lock.
2. Call `macdrv_CreateClientSurface(hwnd, 0, FALSE)`.
3. Reacquire `get_win_data()`.
4. Use the resulting `data->client_view`.
5. Create the Metal view and obtain its CAMetalLayer.

Releasing the Wine window-data lock before creating the client surface was important because the client-surface update/present path itself accesses the window data.

This diagnostic implementation did **not** correctly retain and release the resulting `client_surface`.

It was therefore a proof-of-concept, not a production-safe implementation.

---

## 17. First Successful D3D9 → Metal Rendering

With the diagnostic client-surface workaround in place, the triangle test changed from:

```text
CreateDevice failed
```

to:

```text
Direct3DCreate9 OK
CreateDevice OK
3 frames presented
```

The window visibly displayed the RGB D3D9 triangle.

This was the first proof that the complete path worked:

```text
D3D9 application
    ↓
d9mt d3d9.dll
    ↓
d9mtmetal.dll
    ↓
Wine Unix-call bridge
    ↓
d9mtmetal.so
    ↓
DXMT winemetal
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

This is an important result: **actual D3D9 rendering through Metal was achieved using standalone Wine Staging on Apple Silicon.**

---

## 18. WoW Test

The x86_64 d9mt frontend was copied to the disposable WoW installation as:

```text
d3d9.dll
```

WoW was launched through the experimental Wine runtime with:

```bash
export WINEPREFIX="$HOME/Games/WoW-MoP-d9mt/prefix"
export WINE="$HOME/Games/Wine-d9mt/Wine Staging d9mt.app/Contents/Resources/wine/bin/wine"

cd "$WINEPREFIX/drive_c/WoW"

WINEDLLOVERRIDES="d3d9=n;d9mtmetal=b;winemetal=b" \
"$WINE" "./Wow-64.exe"
```

The game successfully:

- created its window;
- initialized through d9mt;
- obtained a Metal view;
- obtained a CAMetalLayer;
- rendered the login/UI;
- allowed login;
- rendered the world-loading screen.

This proved that WoW 5.4.8 itself was using the experimental D3D9 → Metal path.

However, entering the game world stalled/froze.

**Gameplay through d9mt was never achieved.**

---

## 19. Command Buffer Investigation

A process sample taken during the freeze showed a thread repeatedly inside:

```text
_MTLCommandBuffer_waitUntilCompleted
    ↓
-[MTLCommandBuffer waitUntilCompleted]
    ↓
pthread condition wait
```

Initially this suggested that a Metal command buffer might not be completing.

DXMT was instrumented around command-buffer completion.

Typical successful output was:

```text
[winemetal-cmdbuf] WAIT begin ... status=2
[winemetal-cmdbuf] WAIT end ... status=4 error=(none)
```

The status values used by winemetal were:

```text
0 = NotEnqueued
1 = Enqueued
2 = Committed
3 = Scheduled
4 = Completed
5 = Error
```

Later testing produced the more useful failure:

```text
[winemetal-cmdbuf] WAIT end ... status=5
error=Error Domain=MTLCommandBufferErrorDomain Code=9
"Invalid Resource
(00000009:kIOGPUCommandBufferCallbackErrorInvalidResource)"
```

The underlying error was:

```text
IOGPUCommandQueueErrorDomain Code=9
```

This moved the investigation away from a generic command-buffer deadlock and toward invalid Metal resource use.

---

## 20. Render/Blit Instrumentation

Additional diagnostics were added for:

- render command encoders;
- compute command encoders;
- blit command encoders;
- render attachments;
- texture-to-texture copies;
- presentation;
- command-buffer completion.

WoW generated numerous 512×512 render targets while loading the world.

The final main render target observed in one failing run was:

```text
1488x930
```

Example render attachments:

```text
color   1488x930
depth   1488x930
stencil 1488x930
```

The final presentation path included a texture-to-texture blit:

```text
src = 1488x930
dst = 1488x930
srcSlice = 0
srcLevel = 0
dstSlice = 0
dstLevel = 0
size = 1488x930x1
```

One failing command buffer then returned:

```text
status=5
MTLCommandBufferErrorDomain Code=9
Invalid Resource
```

---

## 21. Metal Texture Properties

The exact TEX→TEX branch in DXMT was instrumented to inspect Metal resource properties.

One successful presentation copy reported approximately:

```text
src:
    pixelFormat = 80
    usage       = 5
    storageMode = 2
    hazard      = 2

dst:
    pixelFormat = 80
    usage       = 23
    storageMode = 1
    hazard      = 2
```

The command buffer completed:

```text
status=4
error=(none)
```

Another successful copy reported:

```text
src:
    format      = 80
    usage       = 5
    storageMode = 2
    hazard      = 2

dst:
    format      = 80
    usage       = 5
    storageMode = 0
    hazard      = 2
```

That command buffer also completed successfully.

This demonstrated that the basic TEX→TEX blit operation was not universally invalid.

---

## 22. Final Observed State

During the last test session, WoW opened a native Wine/macOS window but displayed an incorrect mostly blank frame:

- a white rectangular region across the upper portion;
- dark/empty content elsewhere.

Despite the incorrect display, logs showed:

```text
RENDER
BLIT
PRESENT
WAIT begin status=2
WAIT end status=4 error=(none)
```

Therefore, at the point the experiment was paused:

- Wine window creation worked.
- d9mt D3D9 initialization worked.
- DXMT/winemetal loaded.
- Metal device creation worked.
- Metal render encoders worked.
- Metal blit encoders worked.
- CAMetalLayer/drawable presentation was being attempted.
- Many command buffers completed normally.
- Actual WoW frames had previously rendered.
- Some heavier world-loading workloads produced `Invalid Resource`.
- A later run avoided the immediate `Invalid Resource` error but displayed malformed/blank output.
- Stable in-world gameplay was **not achieved**.

---

## 23. Unresolved Client-Surface Lifetime Issue

The diagnostic Wine bridge creates a Wine client surface when no current `client_view` exists.

The lifetime of that client surface was not correctly implemented.

Wine exposes:

```text
client_surface_add_ref()
client_surface_release()
```

and macdrv destroys/detaches resources as the surface lifecycle changes.

A production implementation should not simply create the client surface and forget the returned reference.

Possible future approaches include:

1. Associate the returned `macdrv_metal_view` with the retained `client_surface`.
2. Retain the client surface while DXMT owns the Metal view.
3. Release the corresponding client surface when DXMT calls `ReleaseMetalView`.
4. Ensure window destruction/recreation does not leave stale Cocoa/Metal resources.
5. Alternatively, redesign the bridge around Wine 11.17's newer Metal swapchain/client-surface APIs rather than exposing a raw Metal view.

This issue should be addressed before treating the bridge as safe for sustained gameplay.

---

## 24. Likely Areas for Future Investigation

If this experiment is resumed, investigate these areas rather than starting again from scratch.

### A. Client-surface ownership

Implement proper reference ownership for the client surface created by the Wine bridge.

This is a prerequisite for a robust implementation.

### B. Invalid Metal resource

Determine which resource in the failing command buffer becomes invalid.

The failing command buffer can contain many render encoders before the final blit/present, so the final blit is not necessarily the operation that introduced the invalid resource.

Instrument resource creation/destruction and retain/release behaviour.

### C. Resource lifetime

Correlate:

```text
MTLTexture pointer
creation
use
release/destruction
command buffer
```

The failure may be caused by a resource being destroyed or replaced while still referenced by a queued Metal command.

### D. Render attachments

The world-loading transition creates many intermediate 512×512 render targets.

Investigate whether one of these resources is invalidated before the large 1488×930 presentation command buffer executes.

### E. Synchronisation

If resource lifetime appears valid, instrument:

```text
commit
waitUntilCompleted
encodeWaitForEvent
encodeSignalEvent
fence operations
shared-event values
```

Do not assume a shared-event deadlock without evidence.

### F. Presentation/client view

The final malformed/blank-window run suggests presentation or client-surface attachment may still be incorrect even when Metal command buffers complete successfully.

Compare the custom bridge with Wine 11.17's native Metal/Vulkan swapchain path.

---

## 25. Diagnostic Changes vs. Production Changes

Several modifications were made solely to understand the problem.

### Potentially reusable architectural changes

- Wine 11.17-safe exported macdrv bridge.
- DXMT resolving that bridge instead of accessing private Wine structures.
- Wine 11.17 `__wine_unix_call_dispatcher` compatibility.
- x86_64 d9mt frontend build support.
- Xcode/Metal build fixes.

### Diagnostic-only changes

- `fprintf()` tracing throughout winemetal.
- command-buffer status/error logging;
- render-target pointer/size logging;
- blit resource-property logging;
- temporary client-surface creation without correct ownership;
- verbose Wine macdrv view/surface diagnostics.

These should not simply be shipped as-is.

---

## 26. Important Result

Although the experiment did not reach stable gameplay, it established something useful:

> A WoW 5.4.8 64-bit D3D9 client can reach and visibly render through an open-source d9mt/DXMT Metal path on Apple Silicon using standalone Wine Staging, provided the Wine/macdrv compatibility gap is bridged.

The remaining problems are deeper integration/resource-lifecycle/presentation issues rather than failure to initialize D3D9 or Metal.

---

## 27. Development Directories

At the time this work was paused, the main experimental directories were:

```text
~/Developer/d9mt
~/Developer/dxmt-v0.80
~/Developer/wine-11.17-source
~/Developer/wine-11.17-build-x86_64
~/Developer/toolchains/llvm-darwin-15-x86_64

~/Games/Wine-d9mt
~/Games/WoW-MoP-d9mt
```

These can be removed after all desired patches/diffs have been preserved in the Git repository.

The known-good WineD3D installation should not be confused with the experimental directories:

```text
~/Games/Wine/Wine Staging.app
~/Games/TwinStar/prefix-wine11
```

---

## 28. Before Deleting the Development Trees

The source trees contain local changes that are more useful than this prose alone.

Before deleting them, export the diffs, for example:

```bash
mkdir -p /path/to/mop-5.4.8-apple-silicon/experimental

cd "$HOME/Developer/d9mt"
git diff > /path/to/mop-5.4.8-apple-silicon/experimental/d9mt-wine-11.17.patch

cd "$HOME/Developer/dxmt-v0.80"
git diff > /path/to/mop-5.4.8-apple-silicon/experimental/dxmt-wine-11.17.patch

cd "$HOME/Developer/wine-11.17-source"
git diff > /path/to/mop-5.4.8-apple-silicon/experimental/wine-11.17-macdrv-metal-bridge.patch
```

Review the patches before committing them, particularly because the source currently contains temporary diagnostic instrumentation.

---

## 29. Project Status

The d9mt/Metal experiment is **paused**, not completed.

The main `mop-5.4.8-apple-silicon` project should continue to regard WineD3D as its known-working rendering path.

The experimental Metal work should not be presented as providing working WoW gameplay until the remaining resource-lifetime and presentation problems are resolved.
