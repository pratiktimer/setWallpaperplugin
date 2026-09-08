import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper/wallpaper.dart';

const MethodChannel _channel = MethodChannel(
  'com.prateektimer.wallpaper/wallpaper',
);

/// Integration tests: simulate platform method calls (via mock handler) and verify
/// Flutter/Dart API responses. Runs with `flutter test`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('Simulated platform method calls – success responses', () {
    test(
      'getPlatformVersion → platform returns string → Dart returns same',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              if (call.method == 'getPlatformVersion') {
                return 'Android 14';
              }
              return null;
            });

        final response = await Wallpaper.getPlatformVersion();
        expect(response, 'Android 14');
      },
    );

    test(
      'HomeScreen → platform returns success string → Dart returns same',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              if (call.method == 'HomeScreen') {
                return 'Home Screen Set Successfully';
              }
              return null;
            });

        final response = await Wallpaper.homeScreen(imageName: 'test');
        expect(response, 'Home Screen Set Successfully');
      },
    );

    test(
      'LockScreen → platform returns success string → Dart returns same',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              if (call.method == 'LockScreen') {
                return 'Lock Screen Set Successfully';
              }
              return null;
            });

        final response = await Wallpaper.lockScreen();
        expect(response, 'Lock Screen Set Successfully');
      },
    );

    test(
      'Both → platform returns success string → Dart returns same',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              if (call.method == 'Both') {
                return 'Home and Lock Screen Set Successfully';
              }
              return null;
            });

        final response = await Wallpaper.bothScreen();
        expect(response, 'Home and Lock Screen Set Successfully');
      },
    );

    test(
      'SystemWallpaper → platform returns success string → Dart returns same',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              if (call.method == 'SystemWallpaper') {
                return 'System Screen Set Successfully';
              }
              return null;
            });

        final response = await Wallpaper.systemScreen();
        expect(response, 'System Screen Set Successfully');
      },
    );
  });

  group('Simulated platform method calls – error responses', () {
    test(
      'platform returns FILE_NOT_FOUND → Dart throws PlatformException with code',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              throw PlatformException(
                code: 'FILE_NOT_FOUND',
                message:
                    'Image file not found: /path/to/file. Download the image first.',
              );
            });

        expect(
          () => Wallpaper.homeScreen(),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'FILE_NOT_FOUND')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Download the image first'),
                ),
          ),
        );
      },
    );

    test(
      'platform returns PERMISSION_DENIED → Dart throws PlatformException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              throw PlatformException(
                code: 'PERMISSION_DENIED',
                message: 'Permission denied for setting wallpaper',
              );
            });

        expect(
          () => Wallpaper.lockScreen(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'PERMISSION_DENIED',
            ),
          ),
        );
      },
    );

    test(
      'platform returns STORAGE_UNAVAILABLE → Dart throws PlatformException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              throw PlatformException(
                code: 'STORAGE_UNAVAILABLE',
                message: 'Could not resolve storage path for location 2.',
              );
            });

        expect(
          () => Wallpaper.bothScreen(
            location: DownloadLocation.externalDirectory,
          ),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'STORAGE_UNAVAILABLE',
            ),
          ),
        );
      },
    );
  });

  group('Simulated platform method calls – argument verification', () {
    test('HomeScreen receives correct argument map from Dart', () async {
      Map<Object?, Object?>? receivedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            if (call.method == 'HomeScreen') {
              receivedArgs = call.arguments as Map<Object?, Object?>?;
            }
            return 'OK';
          });

      await Wallpaper.homeScreen(
        imageName: 'argtest',
        fileExtension: ImageFormat.png,
        width: 320,
        height: 480,
        options: RequestSizeOptions.resizeFit,
        location: DownloadLocation.applicationDirectory,
      );

      expect(receivedArgs, isNotNull);
      final args = receivedArgs!;
      expect(args['imageName'], 'argtest');
      expect(args['fileExtension'], 'png');
      expect(args['maxWidth'], 320.0);
      expect(args['maxHeight'], 480.0);
      expect(args['RequestSizeOptions'], RequestSizeOptions.resizeFit.index);
      expect(args['location'], DownloadLocation.applicationDirectory.index);
    });

    test('SystemWallpaper receives location and imageName only', () async {
      Map<Object?, Object?>? receivedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            if (call.method == 'SystemWallpaper') {
              receivedArgs = call.arguments as Map<Object?, Object?>?;
            }
            return 'OK';
          });

      await Wallpaper.systemScreen(
        imageName: 'sysimg',
        fileExtension: ImageFormat.jpeg,
        location: DownloadLocation.temporaryDirectory,
      );

      expect(receivedArgs, isNotNull);
      final args = receivedArgs!;
      expect(
        args.keys,
        containsAll(['location', 'imageName', 'fileExtension']),
      );
      expect(args['imageName'], 'sysimg');
      expect(args['fileExtension'], 'jpeg');
      expect(args['location'], 0);
    });
  });

  group('Sequence of platform calls', () {
    test('multiple methods in sequence all get correct responses', () async {
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            callCount++;
            switch (call.method) {
              case 'getPlatformVersion':
                return 'Android 14';
              case 'HomeScreen':
                return 'Home Screen Set Successfully';
              case 'LockScreen':
                return 'Lock Screen Set Successfully';
              case 'Both':
                return 'Home and Lock Screen Set Successfully';
              case 'SystemWallpaper':
                return 'System Screen Set Successfully';
              default:
                return null;
            }
          });

      expect(await Wallpaper.getPlatformVersion(), 'Android 14');
      expect(await Wallpaper.homeScreen(), 'Home Screen Set Successfully');
      expect(await Wallpaper.lockScreen(), 'Lock Screen Set Successfully');
      expect(
        await Wallpaper.bothScreen(),
        'Home and Lock Screen Set Successfully',
      );
      expect(await Wallpaper.systemScreen(), 'System Screen Set Successfully');

      expect(callCount, 5);
    });
  });
}
