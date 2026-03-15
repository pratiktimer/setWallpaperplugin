import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper/wallpaper.dart';

const MethodChannel _channel = MethodChannel('com.prateektimer.wallpaper/wallpaper');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('MethodChannelWallpaper response handling', () {
    test('homeScreen throws INVALID_RESPONSE when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async => null);

      expect(
        () async => await Wallpaper.homeScreen(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'INVALID_RESPONSE')
            .having((e) => e.message, 'message', contains('null'))),
      );
    });

    test('homeScreen throws INVALID_RESPONSE when platform returns non-String', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async => 42);

      expect(
        () async => await Wallpaper.homeScreen(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'INVALID_RESPONSE')
            .having((e) => e.message, 'message', contains('int'))),
      );
    });

    test('lockScreen throws INVALID_RESPONSE when platform returns Map', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async => {'key': 'value'});

      expect(
        () async => await Wallpaper.lockScreen(),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'INVALID_RESPONSE')),
      );
    });

    test('bothScreen returns string when platform returns string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async => 'Done');

      final result = await Wallpaper.bothScreen();
      expect(result, 'Done');
    });

    test('systemScreen returns string when platform returns string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async => 'System OK');

      final result = await Wallpaper.systemScreen();
      expect(result, 'System OK');
    });
  });

  group('MethodChannelWallpaper argument encoding', () {
    test('fileExtension jpeg encoded as jpeg', () async {
      Map<Object?, Object?>? args;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        args = call.arguments as Map<Object?, Object?>?;
        return 'OK';
      });

      await Wallpaper.homeScreen(fileExtension: ImageFormat.jpeg);
      expect(args!['fileExtension'], 'jpeg');
    });

    test('fileExtension png encoded as png', () async {
      Map<Object?, Object?>? args;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        args = call.arguments as Map<Object?, Object?>?;
        return 'OK';
      });

      await Wallpaper.homeScreen(fileExtension: ImageFormat.png);
      expect(args!['fileExtension'], 'png');
    });

    test('RequestSizeOptions passed as index', () async {
      Map<Object?, Object?>? args;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        args = call.arguments as Map<Object?, Object?>?;
        return 'OK';
      });

      await Wallpaper.homeScreen(options: RequestSizeOptions.resizeCentreCrop);
      expect(args!['RequestSizeOptions'], RequestSizeOptions.resizeCentreCrop.index);
    });

    test('DownloadLocation passed as index', () async {
      Map<Object?, Object?>? args;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        args = call.arguments as Map<Object?, Object?>?;
        return 'OK';
      });

      await Wallpaper.homeScreen(location: DownloadLocation.externalDirectory);
      expect(args!['location'], DownloadLocation.externalDirectory.index);
    });
  });

  group('MethodChannelWallpaper channel name', () {
    test('getPlatformVersion uses correct channel', () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        method = call.method;
        return 'Android 14';
      });

      final version = await Wallpaper.getPlatformVersion();
      expect(method, 'getPlatformVersion');
      expect(version, 'Android 14');
    });
  });
}
