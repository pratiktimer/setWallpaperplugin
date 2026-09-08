## 1.2.0

* Modernized the Android implementation while preserving the existing Dart API.
* Fixed Android wallpaper calls to capture request arguments per call, avoiding shared mutable state during concurrent operations.
* Improved Android activity lifecycle handling for the system wallpaper picker.
* Added Android API-level guards for lock screen and both-screen wallpaper operations.
* Reduced large-image memory pressure with bounds decoding, bitmap sampling, and bitmap recycling.
* Removed unnecessary legacy storage permissions from the Android manifest.
* Updated README guidance for app-private storage and concurrent download filenames.
* Added native argument-validation tests.
* Added additive APIs for setting wallpapers from local files, `Uint8List` bytes,
  and Flutter assets.
* Added a unified `setWallpaperFromSource` API with typed success/failure
  results and categorized wallpaper exceptions.
* Added typed, cancellable downloads with headers, timeouts, cache reuse, and
  plugin-managed temporary cache cleanup.
* Added `Wallpaper.recommendedWallpaperSize()` for reading platform-recommended
  wallpaper dimensions.
* Added `Wallpaper.openWallpaperChooser()` for launching Android's system
  wallpaper chooser.
* Added opt-in `WallpaperFit` modes for source-based wallpaper APIs without
  changing legacy `RequestSizeOptions` behavior.
* Added `WallpaperAlignment` for opt-in crop/placement control with modern
  source API fit modes.
