import 'dart:async';

import 'package:flutter/services.dart';

class Wallpaper {
  static const MethodChannel _channel =
      const MethodChannel('wallpaper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  static Future<String> homeScreen(String url) async {
    final String resultvar=await _channel.invokeMethod('HomeScreen',url );
    return resultvar;
  }
  static Future<String> lockScreen(String url) async {
    final String resultvar= await _channel.invokeMethod('LockScreen',url );
    return resultvar;
  }
  static Future<String> bothScreen(String url) async {
    final String resultvar=await _channel.invokeMethod('Both',url );
    return resultvar;
  }
}
