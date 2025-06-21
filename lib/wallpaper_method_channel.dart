import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper/wallpaper.dart';
import 'dart:async';

import 'wallpaper_platform_interface.dart';

/// An implementation of [WallpaperPlatform] that uses method channels.
class MethodChannelWallpaper extends WallpaperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'com.prateektimer.wallpaper/wallpaper',
  );

  @override
  Future<String?> getPlatformVersion() async {
    final version = await WallpaperPlatform.instance.getPlatformVersion();
    return version;
  }

  @override
  Future<String> homeScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final String resultvar = await methodChannel.invokeMethod('HomeScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return resultvar;
  }

  @override
  Future<String> lockScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final String resultvar = await methodChannel.invokeMethod('LockScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return resultvar;
  }

  @override
  Future<String> bothScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final String resultvar = await methodChannel.invokeMethod('Both', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return resultvar;
  }

  @override
  Future<String> systemScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    final String resultvar = await methodChannel
        .invokeMethod('SystemWallpaper', {
          'location': location.index,
          'imageName': imageName,
          'fileExtension': _imageFormatToExtension(fileExtension),
        });
    return resultvar;
  }

  @override
  Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) {
    final streamController = StreamController<String>();

    (() async {
      try {
        Directory dir;
        switch (location) {
          case DownloadLocation.applicationDirectory:
            dir = await getApplicationSupportDirectory();
            break;
          case DownloadLocation.externalDirectory:
            final externalDir = await getExternalStorageDirectory();
            if (externalDir == null) {
              throw Exception("External dir not available");
            }
            dir = externalDir;
            break;
          default:
            dir = await getTemporaryDirectory();
        }

        final ext = _imageFormatToExtension(fileExtension);
        final filePath = "${dir.path}/$imageName.$ext";

        final receivePort = ReceivePort();

        // Spawn isolate
        await Isolate.spawn(
          _downloadImageWithProgress,
          DownloadParams(url, filePath, receivePort.sendPort),
        );

        receivePort.listen((msg) {
          if (msg == "done") {
            streamController.close();
            receivePort.close();
          } else if (msg.toString().startsWith("error:")) {
            streamController.addError(msg);
            streamController.close();
            receivePort.close();
          } else {
            streamController.add(msg); // <--- progress update (e.g., "45%")
          }
        });
      } catch (e) {
        streamController.addError("Failed: ${e.toString()}");
        streamController.close();
      }
    })();

    return streamController.stream;
  }

  String _imageFormatToExtension(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return 'png';
      case ImageFormat.jpeg:
        return 'jpeg';
    }
  }
}

class DownloadParams {
  final String url;
  final String path;
  final SendPort sendPort;

  DownloadParams(this.url, this.path, this.sendPort);
}

void _downloadImageWithProgress(DownloadParams params) async {
  Dio dio = Dio();
  try {
    await dio.download(
      params.url,
      params.path,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = ((received / total) * 100).toStringAsFixed(0);
          params.sendPort.send('$progress%');
        }
      },
    );
    params.sendPort.send("done");
  } catch (e) {
    params.sendPort.send("error: ${e.toString()}");
  }
}
