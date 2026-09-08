# Wallpaper

A Flutter plugin that allows you to **download an image from a URL and set it as wallpaper on Android**.

The plugin supports setting wallpapers for:

* Home screen
* Lock screen
* Both screens
* System wallpaper

---

# Features

* Download image from URL
* Track download progress
* Set wallpaper for **home screen**
* Set wallpaper for **lock screen**
* Set wallpaper for **both screens**
* Set **system wallpaper**
* Resize images before setting wallpaper
* Use modern opt-in fit modes for source-based wallpapers
* Read the platform-recommended wallpaper size
* Open the Android system wallpaper chooser

---

# Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  wallpaper: ^1.2.0
```

Then run:

```bash
flutter pub get
```

---

# Android Configuration

The plugin manifest already declares the permissions it needs for downloading
network images and setting wallpapers:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.SET_WALLPAPER"/>
```

Downloaded images are stored in app-private cache, files, or external files
directories depending on `DownloadLocation`. Apps using the default workflow do
not need `READ_EXTERNAL_STORAGE` or `WRITE_EXTERNAL_STORAGE`, and they do not
need to add their own `file_paths.xml`.

---

# Usage

Import the plugin:

```dart
import 'package:wallpaper/wallpaper.dart';
```

---

## Recommended Wallpaper Size

Use the recommended size when choosing, generating, cropping, or downloading an
image for the current Android launcher:

```dart
final size = await Wallpaper.recommendedWallpaperSize();
print('${size.width} x ${size.height}');
```

---

## Open Wallpaper Chooser

Open Android's built-in wallpaper chooser without passing a specific image:

```dart
await Wallpaper.openWallpaperChooser();
```

---

## Download Image

```dart
final stream = Wallpaper.imageDownloadProgress(
  imageUrl,
  location: DownloadLocation.applicationDirectory,
);

stream.listen((progress) {
  print(progress);
});
```

---

## Typed Download Operation

Use `download` when you need typed progress, headers, timeouts, cache reuse, or
cancellation:

```dart
final operation = Wallpaper.download(
  imageUrl,
  options: const WallpaperDownloadOptions(
    imageName: 'daily_wallpaper',
    headers: {'Authorization': 'Bearer token'},
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    cachePolicy: WallpaperCachePolicy.reuse,
  ),
);

operation.progress.listen((progress) {
  print(progress.percentage);
});

final file = await operation.completed;

await Wallpaper.homeScreen(
  imageName: file.imageName,
  fileExtension: file.fileExtension,
  location: file.location,
);
```

Cancel an active operation:

```dart
await operation.cancel();
```

Clear plugin-managed temporary downloads created by the typed download API:

```dart
await Wallpaper.clearCache();
```

---

## Set Home Screen Wallpaper

```dart
await Wallpaper.homeScreen(
  width: width,
  height: height,
  options: RequestSizeOptions.resizeFit,
  location: DownloadLocation.applicationDirectory,
);
```

---

## Set Lock Screen Wallpaper

```dart
await Wallpaper.lockScreen(
  location: DownloadLocation.applicationDirectory,
);
```

---

## Set Both Wallpapers

```dart
await Wallpaper.bothScreen(
  location: DownloadLocation.applicationDirectory,
);
```

---

## Set System Wallpaper

```dart
await Wallpaper.systemScreen(
  location: DownloadLocation.applicationDirectory,
);
```

---

## Set Wallpaper From a Local File

```dart
await Wallpaper.setFromFile(
  file.path,
  target: WallpaperTarget.home,
  options: RequestSizeOptions.resizeFit,
  fit: WallpaperFit.cover,
  alignment: WallpaperAlignment.topCenter,
);
```

`alignment` is optional and defaults to center. It applies to `WallpaperFit.cover`
cropping and `WallpaperFit.center` placement.

---

## Set Wallpaper From Bytes

```dart
await Wallpaper.setFromBytes(
  imageBytes,
  target: WallpaperTarget.both,
  fileExtension: ImageFormat.png,
);
```

---

## Set Wallpaper From an Asset

```dart
await Wallpaper.setFromAsset(
  'assets/wallpaper.jpg',
  target: WallpaperTarget.lock,
);
```

For assets bundled by another package:

```dart
await Wallpaper.setFromAsset(
  'assets/wallpaper.jpg',
  package: 'wallpaper_assets',
);
```

---

## Unified Source API

Use `setWallpaperFromSource` when you prefer a typed result instead of catching
`PlatformException` from the legacy methods:

```dart
final result = await Wallpaper.setWallpaperFromSource(
  source: WallpaperSource.file(file.path),
  options: const WallpaperOptions(
    target: WallpaperTarget.home,
    fit: WallpaperFit.cover,
    alignment: WallpaperAlignment.topCenter,
  ),
);

switch (result) {
  case WallpaperSuccess(:final message):
    print(message);
  case WallpaperFailure(:final exception):
    print('${exception.code}: ${exception.message}');
}
```

---

# Example

```dart
final stream = Wallpaper.imageDownloadProgress(imageUrl);

stream.listen((progress) {
  print("Downloading: $progress");
}, onDone: () async {

  await Wallpaper.homeScreen(
    width: 1080,
    height: 1920,
    options: RequestSizeOptions.resizeFit,
  );

});
```

---

# Supported Platform

| Platform | Supported |
| -------- | --------- |
| Android  | ✅         |
| iOS      | ❌         |

---

# Notes

* Internet connection is required to download images.
* Lock screen wallpaper requires **Android 7.0+ (API 24)**.
* Behavior may vary depending on device manufacturer.
* Starting multiple downloads with the same `imageName` writes to the same file.
  Use unique names for concurrent downloads.

---

# License

MIT License
