import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper/src/method_channel_wallpaper.dart';
import 'package:wallpaper/wallpaper.dart';

const MethodChannel _channel = MethodChannel(
  'com.prateektimer.wallpaper/wallpaper',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('MethodChannelWallpaper response handling', () {
    test(
      'homeScreen throws INVALID_RESPONSE when platform returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              _channel,
              (MethodCall call) async => null,
            );

        expect(
          () async => await Wallpaper.homeScreen(),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'INVALID_RESPONSE')
                .having((e) => e.message, 'message', contains('null')),
          ),
        );
      },
    );

    test(
      'homeScreen throws INVALID_RESPONSE when platform returns non-String',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async => 42);

        expect(
          () async => await Wallpaper.homeScreen(),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'INVALID_RESPONSE')
                .having((e) => e.message, 'message', contains('int')),
          ),
        );
      },
    );

    test(
      'lockScreen throws INVALID_RESPONSE when platform returns Map',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              _channel,
              (MethodCall call) async => {'key': 'value'},
            );

        expect(
          () async => await Wallpaper.lockScreen(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
      },
    );

    test('bothScreen returns string when platform returns string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _channel,
            (MethodCall call) async => 'Done',
          );

      final result = await Wallpaper.bothScreen();
      expect(result, 'Done');
    });

    test('systemScreen returns string when platform returns string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _channel,
            (MethodCall call) async => 'System OK',
          );

      final result = await Wallpaper.systemScreen();
      expect(result, 'System OK');
    });

    test('recommendedWallpaperSize parses platform dimensions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            expect(call.method, 'getRecommendedWallpaperSize');
            return {'width': 1440, 'height': 3120};
          });

      final size = await Wallpaper.recommendedWallpaperSize();

      expect(size, const WallpaperSize(width: 1440, height: 3120));
    });

    test('openWallpaperChooser returns platform message', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            expect(call.method, 'OpenWallpaperChooser');
            return 'Wallpaper Chooser Opened Successfully';
          });

      final result = await Wallpaper.openWallpaperChooser();

      expect(result, 'Wallpaper Chooser Opened Successfully');
    });

    test(
      'recommendedWallpaperSize throws INVALID_RESPONSE for invalid dimensions',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              _channel,
              (MethodCall call) async => {'width': 0, 'height': 3120},
            );

        expect(
          () async => await Wallpaper.recommendedWallpaperSize(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
      },
    );
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
      expect(
        args!['RequestSizeOptions'],
        RequestSizeOptions.resizeCentreCrop.index,
      );
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

    test(
      'WallpaperFit and alignment pass as optional source path args',
      () async {
        Map<Object?, Object?>? args;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              args = call.arguments as Map<Object?, Object?>?;
              return 'OK';
            });

        await MethodChannelWallpaper().homeScreen(
          fit: WallpaperFit.cover,
          alignment: WallpaperAlignment.topRight,
        );

        expect(args!['WallpaperFit'], WallpaperFit.cover.index);
        expect(args!['WallpaperAlignmentX'], 1);
        expect(args!['WallpaperAlignmentY'], -1);
      },
    );
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

  group('Source API validation', () {
    test('setFromFile rejects empty filePath', () async {
      expect(
        () async => Wallpaper.setFromFile(''),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENT')
              .having((e) => e.message, 'message', contains('filePath')),
        ),
      );
    });

    test('setFromBytes rejects empty bytes', () async {
      expect(
        () async => Wallpaper.setFromBytes(Uint8List(0)),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENT')
              .having((e) => e.message, 'message', contains('imageBytes')),
        ),
      );
    });

    test('download rejects empty URL through completed future', () async {
      final operation = Wallpaper.download('');

      expect(
        () async => await operation.completed,
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENT')
              .having((e) => e.message, 'message', contains('URL')),
        ),
      );
    });
  });
}
