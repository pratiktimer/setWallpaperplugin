// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this file is governed by a BSD-style license.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'wallpaper_enums.dart';
import 'wallpaper_alignment.dart';
import 'wallpaper_download.dart';
import 'wallpaper_platform_interface.dart';
import 'wallpaper_size.dart';

/// Method channel name; must match native registration (Android, Linux, Windows).
const String kWallpaperChannelName = 'com.prateektimer.wallpaper/wallpaper';
const String _typedDownloadPrefix = 'wallpaper_download_';

/// Method-channel implementation of [WallpaperPlatform].
///
/// **Separation of concerns:** This file is the only place that knows about
/// method channel names, argument encoding (enum index, string extension), and
/// the download isolate. The public API and platform interface use only
/// strongly typed enums and Dart types.
class MethodChannelWallpaper extends WallpaperPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(kWallpaperChannelName);

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<WallpaperSize> recommendedWallpaperSize() async {
    final Object? raw = await methodChannel.invokeMethod(
      'getRecommendedWallpaperSize',
    );
    if (raw is! Map) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message:
            'Platform returned unexpected type for getRecommendedWallpaperSize: ${raw.runtimeType}',
      );
    }

    final width = raw['width'];
    final height = raw['height'];
    if (width is! int || height is! int || width <= 0 || height <= 0) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message:
            'Platform returned invalid dimensions for getRecommendedWallpaperSize',
      );
    }
    return WallpaperSize(width: width, height: height);
  }

  @override
  Future<String> openWallpaperChooser() async {
    final Object? raw = await methodChannel.invokeMethod(
      'OpenWallpaperChooser',
    );
    return _stringResult(raw, 'OpenWallpaperChooser');
  }

  @override
  Future<String> homeScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod(
      'HomeScreen',
      _encodeSetWallpaperArgs(
        imageName: imageName,
        fileExtension: fileExtension,
        width: width,
        height: height,
        options: options,
        fit: fit,
        alignment: alignment,
        location: location,
      ),
    );
    return _stringResult(raw, 'HomeScreen');
  }

  @override
  Future<String> lockScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod(
      'LockScreen',
      _encodeSetWallpaperArgs(
        imageName: imageName,
        fileExtension: fileExtension,
        width: width,
        height: height,
        options: options,
        fit: fit,
        alignment: alignment,
        location: location,
      ),
    );
    return _stringResult(raw, 'LockScreen');
  }

  @override
  Future<String> bothScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod(
      'Both',
      _encodeSetWallpaperArgs(
        imageName: imageName,
        fileExtension: fileExtension,
        width: width,
        height: height,
        options: options,
        fit: fit,
        alignment: alignment,
        location: location,
      ),
    );
    return _stringResult(raw, 'Both');
  }

  @override
  Future<String> systemScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod('SystemWallpaper', {
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return _stringResult(raw, 'SystemWallpaper');
  }

  @override
  Future<String> setFromFile(
    String filePath, {
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat? fileExtension,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    if (filePath.isEmpty) {
      throw PlatformException(
        code: 'INVALID_ARGUMENT',
        message: 'filePath must not be empty',
      );
    }

    final source = File(filePath);
    if (!await source.exists()) {
      throw PlatformException(
        code: 'FILE_NOT_FOUND',
        message: 'Image file not found: $filePath',
      );
    }
    final stat = await source.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw PlatformException(
        code: 'INVALID_ARGUMENT',
        message: 'filePath must point to a file',
      );
    }

    final format = fileExtension ?? _inferImageFormat(filePath);
    final storedImageName = _resolveImageName(imageName);
    final destination = await _destinationFile(
      imageName: storedImageName,
      fileExtension: format,
      location: location,
    );
    await source.copy(destination.path);

    return _setWallpaperForTarget(
      target,
      imageName: storedImageName,
      fileExtension: format,
      width: width,
      height: height,
      options: options,
      fit: fit,
      alignment: alignment,
      location: location,
    );
  }

  @override
  Future<String> setFromBytes(
    Uint8List imageBytes, {
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    if (imageBytes.isEmpty) {
      throw PlatformException(
        code: 'INVALID_ARGUMENT',
        message: 'imageBytes must not be empty',
      );
    }

    final storedImageName = _resolveImageName(imageName);
    final destination = await _destinationFile(
      imageName: storedImageName,
      fileExtension: fileExtension,
      location: location,
    );
    await destination.writeAsBytes(imageBytes, flush: true);

    return _setWallpaperForTarget(
      target,
      imageName: storedImageName,
      fileExtension: fileExtension,
      width: width,
      height: height,
      options: options,
      fit: fit,
      alignment: alignment,
      location: location,
    );
  }

  @override
  Future<String> setFromAsset(
    String assetPath, {
    String? package,
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat? fileExtension,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    if (assetPath.isEmpty) {
      throw PlatformException(
        code: 'INVALID_ARGUMENT',
        message: 'assetPath must not be empty',
      );
    }

    final key = package == null ? assetPath : 'packages/$package/$assetPath';
    final ByteData data;
    try {
      data = await rootBundle.load(key);
    } on FlutterError catch (e) {
      throw PlatformException(
        code: 'ASSET_NOT_FOUND',
        message: 'Asset not found: $key',
        details: e.message,
      );
    }

    return setFromBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      target: target,
      imageName: imageName,
      fileExtension: fileExtension ?? _inferImageFormat(assetPath),
      width: width,
      height: height,
      options: options,
      fit: fit,
      alignment: alignment,
      location: location,
    );
  }

  @override
  Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) {
    final controller = StreamController<String>();

    (() async {
      try {
        if (url.isEmpty) {
          controller.addError(
            PlatformException(
              code: 'INVALID_ARGUMENT',
              message: 'URL must not be empty',
            ),
          );
          controller.close();
          return;
        }
        final dir = await _directoryForLocation(location);
        final ext = _imageFormatToExtension(fileExtension);
        final path = '${dir.path}/$imageName.$ext';
        final port = ReceivePort();

        await Isolate.spawn(
          _downloadImageWithProgress,
          _DownloadParams(url, path, port.sendPort),
        );

        port.listen((msg) {
          if (msg == 'done') {
            controller.close();
            port.close();
          } else if (msg.toString().startsWith('error:')) {
            controller.addError(msg);
            controller.close();
            port.close();
          } else {
            controller.add(msg as String);
          }
        });
      } catch (e) {
        controller.addError('Failed: $e');
        controller.close();
      }
    })();

    return controller.stream;
  }

  @override
  WallpaperDownloadOperation download(
    String url, {
    WallpaperDownloadOptions options = const WallpaperDownloadOptions(),
  }) {
    final progressController = StreamController<WallpaperDownloadProgress>();
    final completed = Completer<WallpaperDownloadedFile>();
    final cancelToken = CancelToken();

    (() async {
      File? destination;
      try {
        if (url.isEmpty) {
          throw PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'URL must not be empty',
          );
        }

        final imageName = _resolveDownloadImageName(options.imageName);
        destination = await _destinationFile(
          imageName: imageName,
          fileExtension: options.fileExtension,
          location: options.location,
        );

        if (options.cachePolicy == WallpaperCachePolicy.reuse &&
            await destination.exists()) {
          _closeProgress(progressController);
          completed.complete(
            WallpaperDownloadedFile(
              path: destination.path,
              imageName: imageName,
              fileExtension: options.fileExtension,
              location: options.location,
              fromCache: true,
            ),
          );
          return;
        }

        final dio = Dio(
          BaseOptions(
            connectTimeout: options.connectTimeout,
            receiveTimeout: options.receiveTimeout,
          ),
        );

        await dio.download(
          url,
          destination.path,
          cancelToken: cancelToken,
          options: Options(headers: options.headers),
          onReceiveProgress: (received, total) {
            if (!progressController.isClosed) {
              progressController.add(
                WallpaperDownloadProgress(
                  receivedBytes: received,
                  totalBytes: total,
                ),
              );
            }
          },
        );

        _closeProgress(progressController);
        completed.complete(
          WallpaperDownloadedFile(
            path: destination.path,
            imageName: imageName,
            fileExtension: options.fileExtension,
            location: options.location,
            fromCache: false,
          ),
        );
      } on PlatformException catch (e) {
        _closeProgress(progressController);
        completed.completeError(e);
      } on DioException catch (e) {
        await _deletePartialDownload(destination);
        _closeProgress(progressController);
        completed.completeError(
          PlatformException(
            code: CancelToken.isCancel(e) ? 'CANCELLED' : 'DOWNLOAD_FAILED',
            message: CancelToken.isCancel(e)
                ? 'Download cancelled'
                : 'Failed to download image: ${e.message}',
          ),
        );
      } catch (e) {
        await _deletePartialDownload(destination);
        _closeProgress(progressController);
        completed.completeError(
          PlatformException(
            code: 'DOWNLOAD_FAILED',
            message: 'Failed to download image: $e',
          ),
        );
      }
    })();

    return WallpaperDownloadOperation(
      progress: progressController.stream,
      completed: completed.future,
      cancel: () async {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Download cancelled');
        }
      },
    );
  }

  @override
  Future<void> clearCache() async {
    final dir = await _directoryForLocation(
      DownloadLocation.temporaryDirectory,
    );
    if (!await dir.exists()) {
      return;
    }

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (name.startsWith(_typedDownloadPrefix)) {
          await entity.delete();
        }
      }
    }
  }

  /// Encode set-wallpaper arguments for method channel (enums → indices).
  Map<String, Object> _encodeSetWallpaperArgs({
    required String imageName,
    required ImageFormat fileExtension,
    required double width,
    required double height,
    required RequestSizeOptions options,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    required DownloadLocation location,
  }) => {
    'imageName': imageName,
    'fileExtension': _imageFormatToExtension(fileExtension),
    'maxWidth': width,
    'maxHeight': height,
    'RequestSizeOptions': options.index,
    if (fit != null) 'WallpaperFit': fit.index,
    if (alignment != null) 'WallpaperAlignmentX': alignment.x,
    if (alignment != null) 'WallpaperAlignmentY': alignment.y,
    'location': location.index,
  };

  static String _imageFormatToExtension(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return 'png';
      case ImageFormat.jpeg:
        return 'jpeg';
    }
  }

  Future<Directory> _directoryForLocation(DownloadLocation location) async {
    switch (location) {
      case DownloadLocation.applicationDirectory:
        return getApplicationSupportDirectory();
      case DownloadLocation.externalDirectory:
        final dir = await getExternalStorageDirectory();
        if (dir == null) throw Exception('External dir not available');
        return dir;
      case DownloadLocation.temporaryDirectory:
        return getTemporaryDirectory();
    }
  }

  Future<File> _destinationFile({
    required String imageName,
    required ImageFormat fileExtension,
    required DownloadLocation location,
  }) async {
    final dir = await _directoryForLocation(location);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext = _imageFormatToExtension(fileExtension);
    return File('${dir.path}${Platform.pathSeparator}$imageName.$ext');
  }

  Future<String> _setWallpaperForTarget(
    WallpaperTarget target, {
    required String imageName,
    required ImageFormat fileExtension,
    required double width,
    required double height,
    required RequestSizeOptions options,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    required DownloadLocation location,
  }) {
    switch (target) {
      case WallpaperTarget.home:
        return homeScreen(
          imageName: imageName,
          fileExtension: fileExtension,
          width: width,
          height: height,
          options: options,
          fit: fit,
          alignment: alignment,
          location: location,
        );
      case WallpaperTarget.lock:
        return lockScreen(
          imageName: imageName,
          fileExtension: fileExtension,
          width: width,
          height: height,
          options: options,
          fit: fit,
          alignment: alignment,
          location: location,
        );
      case WallpaperTarget.both:
        return bothScreen(
          imageName: imageName,
          fileExtension: fileExtension,
          width: width,
          height: height,
          options: options,
          fit: fit,
          alignment: alignment,
          location: location,
        );
    }
  }

  static String _resolveImageName(String? imageName) {
    if (imageName == null || imageName.isEmpty) {
      return 'wallpaper_${DateTime.now().microsecondsSinceEpoch}';
    }
    return _validateImageName(imageName);
  }

  static String _resolveDownloadImageName(String? imageName) {
    if (imageName == null || imageName.isEmpty) {
      return '$_typedDownloadPrefix${DateTime.now().microsecondsSinceEpoch}';
    }
    return _validateImageName(imageName);
  }

  static String _validateImageName(String imageName) {
    if (imageName.contains('/') || imageName.contains(r'\')) {
      throw PlatformException(
        code: 'INVALID_ARGUMENT',
        message: 'imageName must be a file basename, not a path',
      );
    }
    return imageName;
  }

  static Future<void> _deletePartialDownload(File? destination) async {
    if (destination != null && await destination.exists()) {
      try {
        await destination.delete();
      } catch (_) {
        // Best-effort cleanup for cancelled or failed downloads.
      }
    }
  }

  static void _closeProgress(
    StreamController<WallpaperDownloadProgress> controller,
  ) {
    if (!controller.isClosed) {
      unawaited(controller.close());
    }
  }

  static ImageFormat _inferImageFormat(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return ImageFormat.png;
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return ImageFormat.jpeg;
    }
    throw PlatformException(
      code: 'INVALID_ARGUMENT',
      message: 'Could not infer image format from path. Pass fileExtension.',
    );
  }

  static String _stringResult(Object? value, String method) {
    if (value == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Platform returned null for $method',
      );
    }
    if (value is! String) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message:
            'Platform returned unexpected type for $method: ${value.runtimeType}',
      );
    }
    return value;
  }
}

class _DownloadParams {
  final String url;
  final String path;
  final SendPort sendPort;

  _DownloadParams(this.url, this.path, this.sendPort);
}

void _downloadImageWithProgress(_DownloadParams params) async {
  final dio = Dio();
  try {
    await dio.download(
      params.url,
      params.path,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final pct = ((received / total) * 100).toStringAsFixed(0);
          params.sendPort.send('$pct%');
        }
      },
    );
    params.sendPort.send('done');
  } catch (e) {
    params.sendPort.send('error: $e');
  }
}
