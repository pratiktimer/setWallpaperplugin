import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum RequestSizeOptions {
  RESIZE_FIT,
  RESIZE_INSIDE,
  RESIZE_EXACT,
  RESIZE_CENTRE_CROP
}

// This are the locations where image can be downloaded
enum DownloadLocation {
  TEMPORARY_DIRECTORY,
  APPLICATION_DIRECTORY,
  EXTERNAL_DIRECTORY
}

class Wallpaper {
  static const MethodChannel _channel =
      const MethodChannel('com.prateektimer.wallpaper/wallpaper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // homeScreen is to set home screen
  // imageName -> Name of the downloaded image to set as home screen
  // width and height -> send the width and height to use while setting the image as wallpaper else will use the entire image as it is
  // options to use when setting wallpaper RESIZE_FIT, RESIZE_INSIDE, RESIZE_EXACT,RESIZE_CENTRE_CROP
  // loaction where the image is downloaded

  static Future<String> homeScreen(
      {String imageName = "myimage",
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.RESIZE_CENTRE_CROP,
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('HomeScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName
    });
    return resultvar;
  }

  // lockScreen is to set lock screen
  // imageName -> Name of the downloaded image to set as lock screen
  // width and height -> send the width and height to use while setting the image as wallpaper else will use the entire image as it is
  // options to use when setting wallpaper RESIZE_FIT, RESIZE_INSIDE, RESIZE_EXACT,RESIZE_CENTRE_CROP
  // loaction where the image is downloaded
  static Future<String> lockScreen(
      {String imageName = "myimage",
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.RESIZE_EXACT,
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('LockScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName
    });
    return resultvar;
  }

  // bothScreen is to set home and lock screen
  // imageName -> Name of the downloaded image to set as both screen
  // width and height -> send the width and height to use while setting the image as wallpaper else will use the entire image as it is
  // options to use when setting wallpaper RESIZE_FIT, RESIZE_INSIDE, RESIZE_EXACT,RESIZE_CENTRE_CROP
  // loaction where the image is downloaded
  static Future<String> bothScreen(
      {String imageName = "myimage",
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.RESIZE_EXACT,
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('Both', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName
    });
    return resultvar;
  }

  // systemScreen gives you the option to use default wallpaper system which allows you to set home, lock screen or both
  // loaction where the image is downloaded
  // Requires Read and Write Storage Permissions
  static Future<String> systemScreen(
      {String imageName = "myimage",
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('SystemWallpaper',
        {'location': location.index, 'imageName': imageName});
    return resultvar;
  }

  // before using homeScreen, lockScreen , bothScreen, systemScreen . we need to download image .
  // imageName -> after downloading image name to be saved so when using home screen, etc we can pass this name and
  //  location
  // loaction where the image is downloaded
  static Stream<String> imageDownloadProgress(String url,
      {String imageName = 'myimage',
      DownloadLocation location =
          DownloadLocation.TEMPORARY_DIRECTORY}) async* {
    StreamController<String> streamController = new StreamController();
    try {
      var dir;
      switch (location) {
        case DownloadLocation.APPLICATION_DIRECTORY:
          dir = await getApplicationSupportDirectory();
          break;
        case DownloadLocation.EXTERNAL_DIRECTORY:
          dir = await getExternalStorageDirectory();
          break;
        case DownloadLocation.TEMPORARY_DIRECTORY:
        default:
          dir = await getTemporaryDirectory();
          break;
      }
      Dio dio = new Dio();
      dio
          .download(
            url,
            "${dir.path}/" + imageName + ".jpeg",
            onReceiveProgress: (int received, int total) {
              streamController
                  .add(((received / total) * 100).toStringAsFixed(0) + "%");
            },
          )
          .then((Response response) {})
          .catchError((ex) {
            streamController.add(ex.toString());
          })
          .whenComplete(() {
            streamController.close();
          });
      yield* streamController.stream;
    } catch (ex) {
      throw ex;
    }
  }
}
