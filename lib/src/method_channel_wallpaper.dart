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
import 'wallpaper_platform_interface.dart';

/// Method channel name; must match native registration (Android, Linux, Windows).
const String kWallpaperChannelName = 'com.prateektimer.wallpaper/wallpaper';

/// Method-channel implementation of [WallpaperPlatform].
///
/// **Separation of concerns:** This file is the only place that knows about
/// method channel names, argument encoding (enum index, string extension), and
/// the download isolate. The public API and platform interface use only
/// strongly typed enums and Dart types.
class MethodChannelWallpaper extends WallpaperPlatform {
  @override
  @visibleForTesting
  final methodChannel = const MethodChannel(kWallpaperChannelName);

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<String> homeScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod('HomeScreen', _encodeSetWallpaperArgs(
      imageName: imageName,
      fileExtension: fileExtension,
      width: width,
      height: height,
      options: options,
      location: location,
    ));
    return _stringResult(raw, 'HomeScreen');
  }

  @override
  Future<String> lockScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod('LockScreen', _encodeSetWallpaperArgs(
      imageName: imageName,
      fileExtension: fileExtension,
      width: width,
      height: height,
      options: options,
      location: location,
    ));
    return _stringResult(raw, 'LockScreen');
  }

  @override
  Future<String> bothScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final Object? raw = await methodChannel.invokeMethod('Both', _encodeSetWallpaperArgs(
      imageName: imageName,
      fileExtension: fileExtension,
      width: width,
      height: height,
      options: options,
      location: location,
    ));
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
          controller.addError(PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'URL must not be empty',
          ));
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

  /// Encode set-wallpaper arguments for method channel (enums → indices).
  Map<String, Object> _encodeSetWallpaperArgs({
    required String imageName,
    required ImageFormat fileExtension,
    required double width,
    required double height,
    required RequestSizeOptions options,
    required DownloadLocation location,
  }) =>
      {
        'imageName': imageName,
        'fileExtension': _imageFormatToExtension(fileExtension),
        'maxWidth': width,
        'maxHeight': height,
        'RequestSizeOptions': options.index,
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
        message: 'Platform returned unexpected type for $method: ${value.runtimeType}',
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
