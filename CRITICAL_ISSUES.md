# Critical Issues – Wallpaper Flutter Plugin

This document lists **critical** bugs and design flaws that can cause crashes, wrong behavior, memory leaks, or broken features.

---

## 1. **Infinite recursion in `getPlatformVersion()` (Dart) — CRASH**

**File:** `lib/wallpaper_method_channel.dart`

`MethodChannelWallpaper.getPlatformVersion()` calls `WallpaperPlatform.instance.getPlatformVersion()`. The default instance *is* `MethodChannelWallpaper`, so this calls itself and never uses the method channel, causing infinite recursion and stack overflow.

**Fix:** Call the platform via the method channel instead of the platform interface, e.g.:

```dart
@override
Future<String?> getPlatformVersion() async {
  return await methodChannel.invokeMethod<String>('getPlatformVersion');
}
```

---

## 2. **`lockScreen` and `bothScreen` ignore `fileExtension` (Dart) — WRONG BEHAVIOR**

**File:** `lib/wallpaper.dart`

`lockScreen()` and `bothScreen()` accept `fileExtension` but do not pass it to the platform:

- `lockScreen` (lines 86–92): no `fileExtension` in `WallpaperPlatform.instance.lockScreen(...)`.
- `bothScreen` (lines 104–110): no `fileExtension` in `WallpaperPlatform.instance.bothScreen(...)`.

So PNG (or any non‑default) format is ignored; native side uses whatever it has (e.g. previous call or default "jpeg"), leading to "file not found" or wrong file used.

**Fix:** Add `fileExtension: fileExtension` to both `lockScreen` and `bothScreen` calls to the platform instance.

---

## 3. **Android `SystemWallpaper`: does not read `fileExtension` — WRONG FILE**

**File:** `android/.../WallpaperPlugin.java`

In the `"SystemWallpaper"` branch (lines 95–101), `fileExtension` is never read from the method call. The code uses the instance field `fileExtension`, which is only set in the `HomeScreen`/`LockScreen`/`Both` branch. So for a call that only uses `systemScreen()` (e.g. with PNG), the app still looks for `imageName.jpeg`.

**Fix:** In the `SystemWallpaper` case, add:

```java
fileExtension = call.argument("fileExtension");
fileExtension = fileExtension == null ? "jpeg" : fileExtension;
```

(and keep using that when calling `GetFile` / building paths).

---

## 4. **Android `SystemWallpaper`: result returned before user action; `onActivityResult` never runs**

**Files:** `WallpaperPlugin.java`, `lib/wallpaper_method_channel.dart`

- The Dart API does `result.success(setSystemWallpaper())` immediately. `setSystemWallpaper()` starts the system wallpaper/crop activity and returns a string; it does not wait for the user to confirm or cancel.
- So the Flutter `Future<String>` completes with e.g. "System Screen Set Successfully" before the user has chosen anything.
- The plugin extends `FlutterActivity` and overrides `onActivityResult`, but the object that receives `startActivityForResult` is the **host app’s Activity** (e.g. `MainActivity`), not the plugin instance. So the plugin’s `onActivityResult` is never called, and the real result (OK/cancel) is never sent back to Dart.

**Consequences:** Incorrect “success” reporting and no way to know if the user set the wallpaper or cancelled.

**Fix (conceptual):**

- Do not complete the method channel result in `setSystemWallpaper()`. Store the `MethodChannel.Result` and complete it later.
- Use the Activity Result API (e.g. `ActivityResultLauncher`) on the **host activity** and have the plugin register for that (e.g. via `ActivityPluginBinding.addActivityResultListener` or equivalent), then complete the stored result when the system wallpaper activity returns.

---

## 5. **Possible NPE: `activity` null in `setSystemWallpaper()`**

**File:** `WallpaperPlugin.java`

`setSystemWallpaper()` uses `activity` (e.g. `WallpaperManager.getInstance(activity)`, `activity.startActivityForResult(...)`). If `systemScreen()` is invoked before the plugin is attached to an Activity (or after detach), `activity` can be null → NPE.

**Fix:** Guard use of `activity` (e.g. null check) and call `result.error(...)` if no activity is available, instead of starting the intent.

---

## 6. **Android `GetFile`: external directory always uses `.jpeg`**

**File:** `WallpaperHelper.java`, `GetFile()` (lines 86–99)

For `location == 2` (external directory), the file is built with a hardcoded `".jpeg"`:

```java
file = new File(activity.getExternalFilesDir(null), imageName + ".jpeg");
```

So even if the user downloaded a PNG, the plugin looks for `imageName.jpeg` in external storage → file not found.

**Fix:** Use the `ext` parameter, e.g. `imageName + "." + ext`, same as the other branches.

---

## 7. **Android `resizeBitmap`: RESIZE_EXACT does not resize; wrong dimensions**

**File:** `WallpaperHelper.java`, `resizeBitmap()` (lines 49–50)

For `RESIZE_EXACT` the code does:

```java
resized = Bitmap.createScaledBitmap(bitmap, width, height, false);
```

Here `width` and `height` are the **original** bitmap dimensions (lines 40–41), so the image is not resized to the requested max size. `finalWidth`/`finalHeight` (which are set to `maxWidth`/`maxHeight`) are never used for this branch.

**Fix:** Use the requested dimensions, e.g. `Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, false)` for the RESIZE_EXACT path (and ensure `finalWidth`/`finalHeight` are set from `maxWidth`/`maxHeight` for that option).

---

## 8. **Android `resizeBitmap`: possible NPE when decode fails**

**File:** `WallpaperHelper.java`

`BitmapFactory.decodeFile(...)` can return `null` (invalid or unreadable file). The code then calls `bitmap.getWidth()` / `bitmap.getHeight()` without a null check → NPE.

**Fix:** After `decodeFile`, if `bitmap == null`, return null or handle the error (and document the contract for callers).

---

## 9. **Android `resizeBitmap`: bitmap leak (no recycle)**

**File:** `WallpaperHelper.java`

- In the non–RESIZE_EXACT path, `bitmap` is replaced with `Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, true)`. The original decoded `bitmap` is never recycled → memory leak for large images.
- In the RESIZE_EXACT path, after creating `resized`, the original `bitmap` is only recycled when `resized != bitmap`; for RESIZE_EXACT, `resized` is a new bitmap, so `bitmap` should always be recycled before returning `resized`.

**Fix:** Recycle the original decoded bitmap whenever a new bitmap is created and used as the return value (and ensure no use-after-recycle).

---

## 10. **Android: `ExecutorService` never shut down — thread leak**

**File:** `WallpaperPlugin.java`

`executorService = Executors.newSingleThreadExecutor()` is created in the constructor but never shut down. In `onDetachedFromEngine` only the channel is cleared; the executor keeps running.

**Fix:** In `onDetachedFromEngine`, call `executorService.shutdown()` (or `shutdownNow()` and handle in-flight tasks), then set `executorService = null`.

---

## 11. **Android: possible `ArrayIndexOutOfBoundsException` on `RequestSizeOptions`**

**File:** `WallpaperPlugin.java`

`options` is taken from `call.argument("RequestSizeOptions")` (Integer). If the value is null, invalid, or out of range (e.g. &lt; 0 or ≥ 4), `WallpaperHelper.RequestSizeOptions.values()[options]` throws.

**Fix:** Validate `options` (null check and range 0–3) and call `result.error(...)` if invalid, before using it.

---

## 12. **Method channel name mismatch: Linux/Windows vs Dart**

**Files:**  
- Dart: `lib/wallpaper_method_channel.dart` → `'com.prateektimer.wallpaper/wallpaper'`  
- Linux: `linux/wallpaper_plugin.cc` → `"wallpaper"`  
- Windows: `windows/wallpaper_plugin.cpp` → `"wallpaper"`

Dart uses a different channel name than Linux and Windows. So on desktop, method calls from Dart never reach this plugin’s handlers; all wallpaper methods will fail (e.g. “not implemented” or no response depending on engine behavior).

**Fix:** Use the same channel name on all platforms, e.g. `"com.prateektimer.wallpaper/wallpaper"` in Linux and Windows, or document that only Android is supported and remove/guard desktop code.

---

## 13. **Web / `dart:io`: plugin will not compile or run on web**

**File:** `lib/wallpaper_method_channel.dart`

The file imports `dart:io` and uses `Directory`, `getTemporaryDirectory()`, etc. `dart:io` is not available on web, so this implementation cannot be used for web. The pubspec also includes `flutter_web_plugins` and a `web` dependency, which suggests web might be intended.

**Fix:** Either: (a) make the method channel implementation conditional (e.g. use conditional imports and a web-specific implementation that implements the interface without `dart:io`), or (b) document that web is not supported and exclude web from the plugin’s supported platforms so this code path is never used on web.

---

## 14. **Dart: platform errors surface as raw `PlatformException`**

**File:** `lib/wallpaper_method_channel.dart`

All `invokeMethod` calls are awaited directly. Android sends errors via `result.error("FILE_NOT_FOUND", ...)` or `result.error("EXCEPTION", ...)`, which become `PlatformException` on the Dart side. The public API returns `Future<String>`, so callers get exceptions rather than e.g. a `Result` type or documented error strings. Not necessarily wrong, but combined with issue 4 (wrong success for `systemScreen`) and missing validation (e.g. issue 11), error handling is easy to misuse.

**Recommendation:** Document that methods can throw `PlatformException` and under what conditions; optionally wrap in a plugin-specific exception type and/or handle specific error codes so apps can distinguish “file not found”, “permission denied”, “user cancelled”, etc.

---

## Summary table

| # | Severity   | Area   | Issue |
|---|------------|--------|--------|
| 1 | Crash      | Dart   | `getPlatformVersion()` infinite recursion |
| 2 | Wrong data | Dart   | `lockScreen` / `bothScreen` ignore `fileExtension` |
| 3 | Wrong file | Android| `SystemWallpaper` doesn’t read `fileExtension` |
| 4 | Broken UX  | Android| `systemScreen` success before user action; result never sent to Dart |
| 5 | Crash      | Android| NPE if `activity` is null in `setSystemWallpaper` |
| 6 | Wrong file | Android| External dir always uses `.jpeg` in `GetFile` |
| 7 | Wrong behavior | Android| RESIZE_EXACT doesn’t resize (wrong dimensions) |
| 8 | Crash      | Android| NPE if `decodeFile` returns null |
| 9 | Memory     | Android| Bitmap leak in `resizeBitmap` |
| 10| Leak       | Android| `ExecutorService` never shut down |
| 11| Crash      | Android| `RequestSizeOptions` index out of range |
| 12| Broken     | Linux/Windows | Method channel name mismatch with Dart |
| 13| Build/Runtime | Dart | `dart:io` prevents web support |
| 14| API        | Dart   | Platform errors as raw exceptions (document or wrap) |

Fixing issues **1–12** is strongly recommended for correctness and stability; **13** and **14** are important for platform support and API clarity.
