# Wallpaper plugin – architecture

This document describes the refactored Flutter plugin architecture and how each part fits together.

---

## 1. Platform interface pattern

**What it is:** The plugin uses a single abstract **platform interface** ([WallpaperPlatform]) that defines all operations (get version, set home/lock/both, system picker, download progress). The **public API** ([Wallpaper]) does not talk to the platform directly; it always calls `WallpaperPlatform.instance`.

**Why:**  
- **Testability:** Tests can set `WallpaperPlatform.instance` to a mock and never hit native code.  
- **Extensibility:** New platforms (e.g. iOS, macOS) can add their own implementation of [WallpaperPlatform] and register it.  
- **Consistency:** Same pattern as official plugins (e.g. `shared_preferences`, `path_provider`).

**Where:**  
- Interface: `lib/src/wallpaper_platform_interface.dart`  
- Default implementation: `lib/src/method_channel_wallpaper.dart` (sets `_instance = MethodChannelWallpaper()` in the interface).

---

## 2. Clean separation: API vs platform implementation

**What changed:**  
- **Public surface:** Only `lib/wallpaper.dart` is the intended entry point. It exports the [Wallpaper] class, enums ([RequestSizeOptions], [DownloadLocation], [ImageFormat]), and [WallpaperPlatform] (for tests and custom implementations).  
- **Implementation details:** All platform and channel logic lives under `lib/src/`: enums, platform interface, and method-channel implementation. The rest of the package does not import `src/` except via the public export.

**Why:**  
- Callers depend only on `package:wallpaper/wallpaper.dart`.  
- Method channel names, argument encoding (enum → index), and download isolate are internal; changing them does not break the public API.

**Layout:**

```
lib/
  wallpaper.dart              # Public API + re-exports
  src/
    wallpaper_enums.dart      # RequestSizeOptions, DownloadLocation, ImageFormat
    wallpaper_platform_interface.dart
    method_channel_wallpaper.dart
```

---

## 3. Strongly typed enums (no raw strings for options)

**What:** All “choice” values in the API are Dart enums, not strings or magic numbers:

- **RequestSizeOptions** – resize behavior (resizeFit, resizeInside, resizeExact, resizeCentreCrop)  
- **DownloadLocation** – where the file is stored (temporaryDirectory, applicationDirectory, externalDirectory)  
- **ImageFormat** – jpeg, png  

**Where strings still appear:**  
- Success/error **messages** (e.g. `"Home Screen Set Successfully"`) remain strings by design.  
- **File extension** for the platform is derived at the boundary: `ImageFormat.jpeg` → `"jpeg"`, `ImageFormat.png` → `"png"` only inside [MethodChannelWallpaper].

**Why:**  
- Compile-time safety and IDE completion.  
- Single source of truth: enums in `lib/src/wallpaper_enums.dart`; platform code maps enum index/extension only in the implementation layer.

---

## 4. Improved public API (backward compatible)

**Unchanged (backward compatible):**  
- [Wallpaper.getPlatformVersion]  
- [Wallpaper.homeScreen], [Wallpaper.lockScreen], [Wallpaper.bothScreen], [Wallpaper.systemScreen] – same named parameters and return types  
- [Wallpaper.imageDownloadProgress] – same signature  

**New additions:**  
- **[WallpaperTarget]** enum: `home`, `lock`, `both`.  
- **[SetWallpaperOptions]** – immutable class with `imageName`, `fileExtension`, `width`, `height`, `resizeOption`, `location` (all with defaults).  
- **[Wallpaper.setWallpaper]** – single entry point for home/lock/both: `Wallpaper.setWallpaper(WallpaperTarget.home, options)`.  
- **[SystemWallpaperOptions]** – options for the system picker.  
- **[Wallpaper.systemScreenWithOptions]** – system picker using [SystemWallpaperOptions].

**Why:**  
- Existing code keeps working without changes.  
- New code can use one call with a strongly-typed options object and target enum instead of three separate methods with long parameter lists.

---

## 5. Method channel boundary

**Single place for encoding:** Only [MethodChannelWallpaper] converts Dart types to what the platform expects:

- Enums → `.index` (int) for method channel arguments.  
- [ImageFormat] → `"jpeg"` / `"png"` for the `fileExtension` argument.  
- Channel name is a constant: `kWallpaperChannelName = 'com.prateektimer.wallpaper/wallpaper'`.

The public API and platform interface never see these encodings; they work only with enums and Dart types.

---

## 6. Error handling

- Platform errors are reported as [PlatformException] with `code` and `message`.  
- The same error codes are used as before (e.g. `FILE_NOT_FOUND`, `DECODE_ERROR`, `PERMISSION_DENIED`).  
- Documented on [Wallpaper] and in the code; no architectural change to error handling.

---

## Summary

| Aspect | Before | After |
|--------|--------|--------|
| Entry point | `wallpaper.dart` + scattered imports | Single `wallpaper.dart`; implementation in `src/` |
| Platform abstraction | Platform interface present | Same pattern; interface and default impl in `src/` |
| Options | Named params only | Same + [SetWallpaperOptions] / [SystemWallpaperOptions] and [WallpaperTarget] |
| Enums | Already enums | Centralized in `src/wallpaper_enums.dart`; encoding only at channel boundary |
| Backward compatibility | – | All existing methods and signatures unchanged |

[Wallpaper]: lib/wallpaper.dart
[WallpaperPlatform]: lib/src/wallpaper_platform_interface.dart
[MethodChannelWallpaper]: lib/src/method_channel_wallpaper.dart
[RequestSizeOptions]: lib/src/wallpaper_enums.dart
[DownloadLocation]: lib/src/wallpaper_enums.dart
[ImageFormat]: lib/src/wallpaper_enums.dart
[SetWallpaperOptions]: lib/wallpaper.dart
[SystemWallpaperOptions]: lib/wallpaper.dart
[WallpaperTarget]: lib/wallpaper.dart
[Wallpaper.getPlatformVersion]: lib/wallpaper.dart
[Wallpaper.homeScreen]: lib/wallpaper.dart
[Wallpaper.lockScreen]: lib/wallpaper.dart
[Wallpaper.bothScreen]: lib/wallpaper.dart
[Wallpaper.systemScreen]: lib/wallpaper.dart
[Wallpaper.imageDownloadProgress]: lib/wallpaper.dart
[Wallpaper.setWallpaper]: lib/wallpaper.dart
[Wallpaper.systemScreenWithOptions]: lib/wallpaper.dart
[PlatformException]: https://api.flutter.dev/flutter/services/PlatformException-class.html
