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

  group('Wallpaper API with mocked MethodChannel', () {
    test('getPlatformVersion returns value from platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        expect(call.method, 'getPlatformVersion');
        return 'Android 14';
      });

      final version = await Wallpaper.getPlatformVersion();
      expect(version, 'Android 14');
    });

    test('getPlatformVersion returns null when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        return null;
      });

      final version = await Wallpaper.getPlatformVersion();
      expect(version, isNull);
    });

    test('homeScreen invokes HomeScreen with correct arguments', () async {
      String? capturedMethod;
      Map<Object?, Object?>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        capturedMethod = call.method;
        capturedArgs = call.arguments as Map<Object?, Object?>?;
        return 'Home Screen Set Successfully';
      });

      final result = await Wallpaper.homeScreen(
        imageName: 'testimage',
        fileExtension: ImageFormat.png,
        width: 100,
        height: 200,
        options: RequestSizeOptions.resizeExact,
        location: DownloadLocation.applicationDirectory,
      );

      expect(capturedMethod, 'HomeScreen');
      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['imageName'], 'testimage');
      expect(args['fileExtension'], 'png');
      expect(args['maxWidth'], 100.0);
      expect(args['maxHeight'], 200.0);
      expect(args['RequestSizeOptions'], RequestSizeOptions.resizeExact.index);
      expect(args['location'], DownloadLocation.applicationDirectory.index);
      expect(result, 'Home Screen Set Successfully');
    });

    test('lockScreen invokes LockScreen with correct arguments', () async {
      String? capturedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        capturedMethod = call.method;
        return 'Lock Screen Set Successfully';
      });

      final result = await Wallpaper.lockScreen(
        imageName: 'lockimg',
        fileExtension: ImageFormat.jpeg,
      );

      expect(capturedMethod, 'LockScreen');
      expect(result, 'Lock Screen Set Successfully');
    });

    test('bothScreen invokes Both with correct arguments', () async {
      String? capturedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        capturedMethod = call.method;
        return 'Home and Lock Screen Set Successfully';
      });

      final result = await Wallpaper.bothScreen(
        imageName: 'bothimg',
        location: DownloadLocation.temporaryDirectory,
      );

      expect(capturedMethod, 'Both');
      expect(result, 'Home and Lock Screen Set Successfully');
    });

    test('systemScreen invokes SystemWallpaper with correct arguments', () async {
      String? capturedMethod;
      Map<Object?, Object?>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        capturedMethod = call.method;
        capturedArgs = call.arguments as Map<Object?, Object?>?;
        return 'System Screen Set Successfully';
      });

      final result = await Wallpaper.systemScreen(
        imageName: 'sysimg',
        fileExtension: ImageFormat.png,
        location: DownloadLocation.applicationDirectory,
      );

      expect(capturedMethod, 'SystemWallpaper');
      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['imageName'], 'sysimg');
      expect(args['fileExtension'], 'png');
      expect(args['location'], DownloadLocation.applicationDirectory.index);
      expect(result, 'System Screen Set Successfully');
    });

    test('homeScreen uses defaults when optional args omitted', () async {
      Map<Object?, Object?>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        capturedArgs = call.arguments as Map<Object?, Object?>?;
        return 'OK';
      });

      await Wallpaper.homeScreen();

      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['imageName'], 'myimage');
      expect(args['fileExtension'], 'jpeg');
      expect(args['maxWidth'], 0.0);
      expect(args['maxHeight'], 0.0);
      expect(args['location'], DownloadLocation.temporaryDirectory.index);
    });
  });

  group('Error handling', () {
    test('homeScreen throws PlatformException with code and message on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw PlatformException(
          code: 'FILE_NOT_FOUND',
          message: 'Image file not found. Download the image first.',
        );
      });

      expect(
        () => Wallpaper.homeScreen(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'FILE_NOT_FOUND')
            .having((e) => e.message, 'message', contains('Download the image first'))),
      );
    });

    test('lockScreen propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw PlatformException(code: 'DECODE_ERROR', message: 'Failed to decode image');
      });

      expect(
        () => Wallpaper.lockScreen(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'DECODE_ERROR')
            .having((e) => e.message, 'message', 'Failed to decode image')),
      );
    });

    test('bothScreen propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw PlatformException(code: 'PERMISSION_DENIED', message: 'Permission denied');
      });

      expect(
        () => Wallpaper.bothScreen(),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'PERMISSION_DENIED')),
      );
    });

    test('systemScreen propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw PlatformException(code: 'NO_ACTIVITY', message: 'Plugin not attached');
      });

      expect(
        () => Wallpaper.systemScreen(),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'NO_ACTIVITY')),
      );
    });

    test('getPlatformVersion propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Platform not available');
      });

      expect(
        () => Wallpaper.getPlatformVersion(),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'UNAVAILABLE')),
      );
    });
  });

  group('Enums', () {
    test('RequestSizeOptions has expected indices', () {
      expect(RequestSizeOptions.resizeFit.index, 0);
      expect(RequestSizeOptions.resizeInside.index, 1);
      expect(RequestSizeOptions.resizeExact.index, 2);
      expect(RequestSizeOptions.resizeCentreCrop.index, 3);
    });

    test('DownloadLocation has expected indices', () {
      expect(DownloadLocation.temporaryDirectory.index, 0);
      expect(DownloadLocation.applicationDirectory.index, 1);
      expect(DownloadLocation.externalDirectory.index, 2);
    });

    test('ImageFormat has expected values', () {
      expect(ImageFormat.jpeg.index, 0);
      expect(ImageFormat.png.index, 1);
    });
  });
}
