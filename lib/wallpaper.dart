// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this file is governed by a BSD-style license.

import 'dart:async';

import 'package:flutter/services.dart';

import 'src/wallpaper_enums.dart';
import 'src/wallpaper_alignment.dart';
import 'src/wallpaper_download.dart';
import 'src/wallpaper_platform_interface.dart';
import 'src/wallpaper_size.dart';

// Re-export enums and platform interface for public use and testing.
export 'src/wallpaper_enums.dart'
    show
        RequestSizeOptions,
        DownloadLocation,
        ImageFormat,
        WallpaperTarget,
        WallpaperFit;
export 'src/wallpaper_alignment.dart' show WallpaperAlignment;
export 'src/wallpaper_download.dart'
    show
        WallpaperCachePolicy,
        WallpaperDownloadOptions,
        WallpaperDownloadProgress,
        WallpaperDownloadedFile,
        WallpaperDownloadOperation;
export 'src/wallpaper_platform_interface.dart' show WallpaperPlatform;
export 'src/wallpaper_size.dart' show WallpaperSize;

/// Options for setting wallpaper (home, lock, or both).
///
/// Use with [Wallpaper.setWallpaper] for a single, strongly-typed call.
/// All fields have defaults; only override what you need.
class SetWallpaperOptions {
  const SetWallpaperOptions({
    this.imageName = 'myimage',
    this.fileExtension = ImageFormat.jpeg,
    this.width = 0,
    this.height = 0,
    this.resizeOption = RequestSizeOptions.resizeCentreCrop,
    this.fit,
    this.location = DownloadLocation.temporaryDirectory,
  });

  /// Basename of the downloaded image file (without extension).
  final String imageName;

  /// Image format (determines file extension).
  final ImageFormat fileExtension;

  /// Max width for resize; 0 means use screen width.
  final double width;

  /// Max height for resize; 0 means use screen height.
  final double height;

  /// How to resize the image to fit the screen.
  ///
  /// Used when [fit] is omitted, preserving legacy source API behavior.
  final RequestSizeOptions resizeOption;

  /// Modern opt-in fit behavior.
  ///
  /// When provided, this takes precedence over [resizeOption] for source-based
  /// wallpaper setting without changing legacy [RequestSizeOptions] semantics.
  final WallpaperFit? fit;

  /// Where the image was downloaded (must match [Wallpaper.imageDownloadProgress]).
  final DownloadLocation location;
}

/// Options for the system wallpaper picker (crop/set UI).
class SystemWallpaperOptions {
  const SystemWallpaperOptions({
    this.imageName = 'myimage',
    this.fileExtension = ImageFormat.jpeg,
    this.location = DownloadLocation.temporaryDirectory,
  });

  final String imageName;
  final ImageFormat fileExtension;
  final DownloadLocation location;
}

/// Source image for [Wallpaper.setWallpaperFromSource].
sealed class WallpaperSource {
  const WallpaperSource();

  /// Uses an image that has already been downloaded to a local file.
  const factory WallpaperSource.file(String path) = WallpaperFileSource;

  /// Uses image bytes already available in memory.
  const factory WallpaperSource.bytes(
    Uint8List bytes, {
    ImageFormat fileExtension,
  }) = WallpaperBytesSource;

  /// Uses a Flutter asset.
  const factory WallpaperSource.asset(String assetPath, {String? package}) =
      WallpaperAssetSource;
}

/// Local-file wallpaper source.
final class WallpaperFileSource extends WallpaperSource {
  const WallpaperFileSource(this.path);

  /// Local image file path.
  final String path;
}

/// In-memory bytes wallpaper source.
final class WallpaperBytesSource extends WallpaperSource {
  const WallpaperBytesSource(
    this.bytes, {
    this.fileExtension = ImageFormat.jpeg,
  });

  /// Encoded image bytes.
  final Uint8List bytes;

  /// Image format used when writing bytes to plugin storage.
  final ImageFormat fileExtension;
}

/// Flutter asset wallpaper source.
final class WallpaperAssetSource extends WallpaperSource {
  const WallpaperAssetSource(this.assetPath, {this.package});

  /// Asset key in the app or package bundle.
  final String assetPath;

  /// Optional package name for package-bundled assets.
  final String? package;
}

/// Options for [Wallpaper.setWallpaperFromSource].
class WallpaperOptions {
  const WallpaperOptions({
    this.target = WallpaperTarget.home,
    this.imageName,
    this.fileExtension,
    this.width = 0,
    this.height = 0,
    this.resizeOption = RequestSizeOptions.resizeCentreCrop,
    this.fit,
    this.alignment,
    this.location = DownloadLocation.temporaryDirectory,
  });

  /// Target screen.
  final WallpaperTarget target;

  /// Optional storage basename. Omit to let source APIs generate one.
  final String? imageName;

  /// Optional format override for file and asset sources.
  final ImageFormat? fileExtension;

  /// Max width for resize; 0 means use screen width.
  final double width;

  /// Max height for resize; 0 means use screen height.
  final double height;

  /// How to resize the image to fit the screen.
  ///
  /// Used when [fit] is omitted, preserving legacy source API behavior.
  final RequestSizeOptions resizeOption;

  /// Modern opt-in fit behavior.
  ///
  /// When provided, this takes precedence over [resizeOption] for source-based
  /// wallpaper setting without changing legacy [RequestSizeOptions] semantics.
  final WallpaperFit? fit;

  /// Optional placement for [WallpaperFit.cover] and [WallpaperFit.center].
  ///
  /// Defaults to centered placement when omitted.
  final WallpaperAlignment? alignment;

  /// Where the source image is copied before setting wallpaper.
  final DownloadLocation location;
}

/// Typed result returned by [Wallpaper.setWallpaperFromSource].
sealed class WallpaperResult {
  const WallpaperResult();
}

/// Wallpaper operation completed successfully.
final class WallpaperSuccess extends WallpaperResult {
  const WallpaperSuccess(this.message);

  /// Platform success message.
  final String message;
}

/// Wallpaper operation failed with a typed exception.
final class WallpaperFailure extends WallpaperResult {
  const WallpaperFailure(this.exception);

  /// Failure details.
  final WallpaperException exception;
}

/// Base exception for typed wallpaper failures.
class WallpaperException implements Exception {
  const WallpaperException({required this.code, this.message, this.details});

  /// Stable failure code.
  final String code;

  /// Human-readable failure message.
  final String? message;

  /// Optional platform details.
  final Object? details;

  @override
  String toString() {
    final text = message;
    return text == null
        ? 'WallpaperException($code)'
        : 'WallpaperException($code, $text)';
  }
}

/// The source file or downloaded/copied file was not found.
final class WallpaperFileNotFoundException extends WallpaperException {
  const WallpaperFileNotFoundException({super.message, super.details})
    : super(code: 'FILE_NOT_FOUND');
}

/// The image could not be decoded by the platform.
final class WallpaperDecodeException extends WallpaperException {
  const WallpaperDecodeException({super.message, super.details})
    : super(code: 'DECODE_ERROR');
}

/// Storage was unavailable or could not be written.
final class WallpaperStorageException extends WallpaperException {
  const WallpaperStorageException({
    required super.code,
    super.message,
    super.details,
  });
}

/// The target wallpaper operation is unsupported on the device.
final class WallpaperUnsupportedException extends WallpaperException {
  const WallpaperUnsupportedException({
    required super.code,
    super.message,
    super.details,
  });
}

/// Permission was denied while setting wallpaper.
final class WallpaperPermissionException extends WallpaperException {
  const WallpaperPermissionException({super.message, super.details})
    : super(code: 'PERMISSION_DENIED');
}

/// The wallpaper could not be set.
final class WallpaperSetException extends WallpaperException {
  const WallpaperSetException({
    required super.code,
    super.message,
    super.details,
  });
}

/// Public API for setting wallpapers and downloading images.
///
/// **Architecture:**
/// - This class is the only public entry point. It delegates to [WallpaperPlatform.instance].
/// - Platform-specific code lives in [WallpaperPlatform] implementations (see [MethodChannelWallpaper] in `src/`).
/// - All options use strongly typed enums ([RequestSizeOptions], [DownloadLocation], [ImageFormat]); no raw strings for these.
///
/// **Backward compatibility:** [homeScreen], [lockScreen], [bothScreen], [systemScreen], [imageDownloadProgress],
/// and [getPlatformVersion] keep the same signatures and behavior. The new [setWallpaper] and [systemScreenWithOptions]
/// methods offer a cleaner API using [SetWallpaperOptions] and [SystemWallpaperOptions].
///
/// **Errors:** Methods throw [PlatformException] on failure. Use [PlatformException.code] and [PlatformException.message].
/// Common codes: `FILE_NOT_FOUND`, `DECODE_ERROR`, `STORAGE_UNAVAILABLE`, `SET_WALLPAPER_FAILED`, `PERMISSION_DENIED`,
/// `INVALID_ARGUMENT`, `NO_ACTIVITY`, `ACTIVITY_NOT_FOUND`, `PLUGIN_DETACHED`, `DETACHED`.
class Wallpaper {
  Wallpaper._();

  static WallpaperPlatform get _platform => WallpaperPlatform.instance;

  /// Returns the platform version string, or null if unavailable.
  ///
  /// Throws [PlatformException] if the platform call fails.
  static Future<String?> getPlatformVersion() => _platform.getPlatformVersion();

  /// Returns the platform-recommended wallpaper dimensions in physical pixels.
  ///
  /// On Android this uses `WallpaperManager`'s desired minimum dimensions, with
  /// a display-size fallback when the launcher does not report a preference.
  static Future<WallpaperSize> recommendedWallpaperSize() =>
      _platform.recommendedWallpaperSize();

  /// Opens Android's system wallpaper chooser.
  ///
  /// This launches the platform UI for choosing wallpapers and does not require
  /// a downloaded image. Use [systemScreen] when you want to open the system
  /// crop/set UI for a specific image file managed by this plugin.
  static Future<String> openWallpaperChooser() =>
      _platform.openWallpaperChooser();

  /// Sets the wallpaper for the given [target] using [options].
  ///
  /// **Improved API:** Prefer this over [homeScreen]/[lockScreen]/[bothScreen] when
  /// you have an [SetWallpaperOptions] object or want a single call for any target.
  static Future<String> setWallpaper(
    WallpaperTarget target,
    SetWallpaperOptions options,
  ) {
    switch (target) {
      case WallpaperTarget.home:
        return _platform.homeScreen(
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          location: options.location,
        );
      case WallpaperTarget.lock:
        return _platform.lockScreen(
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          location: options.location,
        );
      case WallpaperTarget.both:
        return _platform.bothScreen(
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          location: options.location,
        );
    }
  }

  /// Sets wallpaper from a local file path.
  ///
  /// The file is copied into app-private plugin storage before being passed to
  /// the native wallpaper implementation. When [imageName] is omitted, a unique
  /// name is generated to avoid overwriting concurrent operations.
  static Future<String> setFromFile(
    String filePath, {
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat? fileExtension,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeCentreCrop,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.setFromFile(
    filePath,
    target: target,
    imageName: imageName,
    fileExtension: fileExtension,
    width: width,
    height: height,
    options: options,
    fit: fit,
    alignment: alignment,
    location: location,
  );

  /// Sets wallpaper from in-memory image bytes.
  ///
  /// [fileExtension] tells the plugin how to name the temporary image file.
  static Future<String> setFromBytes(
    Uint8List imageBytes, {
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeCentreCrop,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.setFromBytes(
    imageBytes,
    target: target,
    imageName: imageName,
    fileExtension: fileExtension,
    width: width,
    height: height,
    options: options,
    fit: fit,
    alignment: alignment,
    location: location,
  );

  /// Sets wallpaper from a Flutter asset.
  ///
  /// Use [package] for assets bundled by another package.
  static Future<String> setFromAsset(
    String assetPath, {
    String? package,
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat? fileExtension,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeCentreCrop,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.setFromAsset(
    assetPath,
    package: package,
    target: target,
    imageName: imageName,
    fileExtension: fileExtension,
    width: width,
    height: height,
    options: options,
    fit: fit,
    alignment: alignment,
    location: location,
  );

  /// Starts a typed, cancellable image download for later wallpaper use.
  ///
  /// This does not replace [imageDownloadProgress], which remains unchanged.
  static WallpaperDownloadOperation download(
    String url, {
    WallpaperDownloadOptions options = const WallpaperDownloadOptions(),
  }) => _platform.download(url, options: options);

  /// Clears plugin-managed downloaded wallpaper files from temporary storage.
  static Future<void> clearCache() => _platform.clearCache();

  /// Sets wallpaper from a typed [WallpaperSource] and returns a typed result.
  ///
  /// This is additive and does not change the legacy APIs. Legacy methods still
  /// return `Future<String>` and throw [PlatformException] on failure.
  static Future<WallpaperResult> setWallpaperFromSource({
    required WallpaperSource source,
    WallpaperOptions options = const WallpaperOptions(),
  }) async {
    try {
      final message = switch (source) {
        WallpaperFileSource(:final path) => await setFromFile(
          path,
          target: options.target,
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          fit: options.fit,
          alignment: options.alignment,
          location: options.location,
        ),
        WallpaperBytesSource(:final bytes, :final fileExtension) =>
          await setFromBytes(
            bytes,
            target: options.target,
            imageName: options.imageName,
            fileExtension: options.fileExtension ?? fileExtension,
            width: options.width,
            height: options.height,
            options: options.resizeOption,
            fit: options.fit,
            alignment: options.alignment,
            location: options.location,
          ),
        WallpaperAssetSource(:final assetPath, :final package) =>
          await setFromAsset(
            assetPath,
            package: package,
            target: options.target,
            imageName: options.imageName,
            fileExtension: options.fileExtension,
            width: options.width,
            height: options.height,
            options: options.resizeOption,
            fit: options.fit,
            alignment: options.alignment,
            location: options.location,
          ),
      };
      return WallpaperSuccess(message);
    } on PlatformException catch (e) {
      return WallpaperFailure(_exceptionFromPlatformException(e));
    }
  }

  /// Sets the home screen wallpaper. [imageName] and [location] must match the download.
  ///
  /// Throws [PlatformException] on failure (e.g. `FILE_NOT_FOUND`, `DECODE_ERROR`).
  static Future<String> homeScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeCentreCrop,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.homeScreen(
    imageName: imageName,
    fileExtension: fileExtension,
    width: width,
    height: height,
    options: options,
    location: location,
  );

  /// Sets the lock screen wallpaper.
  static Future<String> lockScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeExact,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.lockScreen(
    imageName: imageName,
    fileExtension: fileExtension,
    width: width,
    height: height,
    options: options,
    location: location,
  );

  /// Sets both home and lock screen to the same image.
  static Future<String> bothScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeExact,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.bothScreen(
    imageName: imageName,
    fileExtension: fileExtension,
    width: width,
    height: height,
    options: options,
    location: location,
  );

  /// Opens the system wallpaper picker (crop/set). Requires activity on Android.
  static Future<String> systemScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.systemScreen(
    imageName: imageName,
    fileExtension: fileExtension,
    location: location,
  );

  /// Opens the system wallpaper picker with [SystemWallpaperOptions].
  static Future<String> systemScreenWithOptions(
    SystemWallpaperOptions options,
  ) => _platform.systemScreen(
    imageName: options.imageName,
    fileExtension: options.fileExtension,
    location: options.location,
  );

  /// Stream of download progress (e.g. "45%") for saving an image from [url].
  ///
  /// Use the same [imageName], [fileExtension], and [location] when calling
  /// [homeScreen], [lockScreen], [bothScreen], or [systemScreen] later.
  static Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => _platform.imageDownloadProgress(
    url,
    imageName: imageName,
    fileExtension: fileExtension,
    location: location,
  );

  static WallpaperException _exceptionFromPlatformException(
    PlatformException exception,
  ) {
    switch (exception.code) {
      case 'FILE_NOT_FOUND':
        return WallpaperFileNotFoundException(
          message: exception.message,
          details: exception.details,
        );
      case 'DECODE_ERROR':
        return WallpaperDecodeException(
          message: exception.message,
          details: exception.details,
        );
      case 'PERMISSION_DENIED':
        return WallpaperPermissionException(
          message: exception.message,
          details: exception.details,
        );
      case 'STORAGE_UNAVAILABLE':
      case 'INVALID_ARGUMENT':
      case 'ASSET_NOT_FOUND':
        return WallpaperStorageException(
          code: exception.code,
          message: exception.message,
          details: exception.details,
        );
      case 'UNSUPPORTED_ANDROID_VERSION':
      case 'NO_ACTIVITY':
      case 'ACTIVITY_NOT_FOUND':
      case 'OPERATION_IN_PROGRESS':
        return WallpaperUnsupportedException(
          code: exception.code,
          message: exception.message,
          details: exception.details,
        );
      default:
        return WallpaperSetException(
          code: exception.code,
          message: exception.message,
          details: exception.details,
        );
    }
  }
}
