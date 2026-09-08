import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test(
      'getPlatformVersion returns null when platform returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              return null;
            });

        final version = await Wallpaper.getPlatformVersion();
        expect(version, isNull);
      },
    );

    test('recommendedWallpaperSize returns value from platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            expect(call.method, 'getRecommendedWallpaperSize');
            return {'width': 1080, 'height': 2400};
          });

      final size = await Wallpaper.recommendedWallpaperSize();

      expect(size.width, 1080);
      expect(size.height, 2400);
    });

    test('openWallpaperChooser invokes platform chooser', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            expect(call.method, 'OpenWallpaperChooser');
            return 'Wallpaper Chooser Opened Successfully';
          });

      final result = await Wallpaper.openWallpaperChooser();

      expect(result, 'Wallpaper Chooser Opened Successfully');
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

    test(
      'systemScreen invokes SystemWallpaper with correct arguments',
      () async {
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
      },
    );

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
    test(
      'homeScreen throws PlatformException with code and message on platform error',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              throw PlatformException(
                code: 'FILE_NOT_FOUND',
                message: 'Image file not found. Download the image first.',
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

    test('lockScreen propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            throw PlatformException(
              code: 'DECODE_ERROR',
              message: 'Failed to decode image',
            );
          });

      expect(
        () => Wallpaper.lockScreen(),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'DECODE_ERROR')
              .having((e) => e.message, 'message', 'Failed to decode image'),
        ),
      );
    });

    test('bothScreen propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            throw PlatformException(
              code: 'PERMISSION_DENIED',
              message: 'Permission denied',
            );
          });

      expect(
        () => Wallpaper.bothScreen(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'PERMISSION_DENIED',
          ),
        ),
      );
    });

    test('systemScreen propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            throw PlatformException(
              code: 'NO_ACTIVITY',
              message: 'Plugin not attached',
            );
          });

      expect(
        () => Wallpaper.systemScreen(),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'NO_ACTIVITY'),
        ),
      );
    });

    test('getPlatformVersion propagates PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Platform not available',
            );
          });

      expect(
        () => Wallpaper.getPlatformVersion(),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'UNAVAILABLE'),
        ),
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

    test('WallpaperFit has expected indices', () {
      expect(WallpaperFit.cover.index, 0);
      expect(WallpaperFit.contain.index, 1);
      expect(WallpaperFit.fill.index, 2);
      expect(WallpaperFit.center.index, 3);
      expect(WallpaperFit.none.index, 4);
    });

    test('WallpaperAlignment exposes expected presets', () {
      expect(WallpaperAlignment.center, const WallpaperAlignment(0, 0));
      expect(WallpaperAlignment.topLeft, const WallpaperAlignment(-1, -1));
      expect(WallpaperAlignment.topCenter, const WallpaperAlignment(0, -1));
      expect(WallpaperAlignment.topRight, const WallpaperAlignment(1, -1));
      expect(WallpaperAlignment.centerLeft, const WallpaperAlignment(-1, 0));
      expect(WallpaperAlignment.centerRight, const WallpaperAlignment(1, 0));
      expect(WallpaperAlignment.bottomLeft, const WallpaperAlignment(-1, 1));
      expect(WallpaperAlignment.bottomCenter, const WallpaperAlignment(0, 1));
      expect(WallpaperAlignment.bottomRight, const WallpaperAlignment(1, 1));
    });
  });

  group('Improved API (setWallpaper, options)', () {
    test(
      'setWallpaper(home, options) invokes HomeScreen with options',
      () async {
        String? method;
        Map<Object?, Object?>? args;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              method = call.method;
              args = call.arguments as Map<Object?, Object?>?;
              return 'Home Screen Set Successfully';
            });

        const opts = SetWallpaperOptions(
          imageName: 'opttest',
          fileExtension: ImageFormat.png,
          width: 100,
          height: 200,
          resizeOption: RequestSizeOptions.resizeExact,
          location: DownloadLocation.applicationDirectory,
        );

        final result = await Wallpaper.setWallpaper(WallpaperTarget.home, opts);
        expect(method, 'HomeScreen');
        expect(args, isNotNull);
        final a = args!;
        expect(a['imageName'], 'opttest');
        expect(a['fileExtension'], 'png');
        expect(a['maxWidth'], 100.0);
        expect(a['maxHeight'], 200.0);
        expect(a['RequestSizeOptions'], RequestSizeOptions.resizeExact.index);
        expect(a['location'], DownloadLocation.applicationDirectory.index);
        expect(result, 'Home Screen Set Successfully');
      },
    );

    test('setWallpaper(lock, options) invokes LockScreen', () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            method = call.method;
            return 'Lock Screen Set Successfully';
          });

      final result = await Wallpaper.setWallpaper(
        WallpaperTarget.lock,
        const SetWallpaperOptions(imageName: 'lockopt'),
      );
      expect(method, 'LockScreen');
      expect(result, 'Lock Screen Set Successfully');
    });

    test('setWallpaper(both, options) invokes Both', () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
            method = call.method;
            return 'Home and Lock Screen Set Successfully';
          });

      final result = await Wallpaper.setWallpaper(
        WallpaperTarget.both,
        const SetWallpaperOptions(),
      );
      expect(method, 'Both');
      expect(result, 'Home and Lock Screen Set Successfully');
    });

    test(
      'systemScreenWithOptions invokes SystemWallpaper with options',
      () async {
        Map<Object?, Object?>? args;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (MethodCall call) async {
              args = call.arguments as Map<Object?, Object?>?;
              return 'OK';
            });

        await Wallpaper.systemScreenWithOptions(
          const SystemWallpaperOptions(
            imageName: 'sysopt',
            fileExtension: ImageFormat.png,
            location: DownloadLocation.externalDirectory,
          ),
        );
        expect(args, isNotNull);
        final a = args!;
        expect(a['imageName'], 'sysopt');
        expect(a['fileExtension'], 'png');
        expect(a['location'], DownloadLocation.externalDirectory.index);
      },
    );
  });

  group('Source APIs', () {
    test('setFromFile forwards options to platform', () async {
      final previous = WallpaperPlatform.instance;
      final platform = _FakeWallpaperPlatform();
      WallpaperPlatform.instance = platform;
      addTearDown(() => WallpaperPlatform.instance = previous);

      final result = await Wallpaper.setFromFile(
        '/tmp/wallpaper.png',
        target: WallpaperTarget.lock,
        imageName: 'local_wallpaper',
        fileExtension: ImageFormat.png,
        width: 320,
        height: 480,
        options: RequestSizeOptions.resizeExact,
        fit: WallpaperFit.cover,
        alignment: WallpaperAlignment.topCenter,
        location: DownloadLocation.applicationDirectory,
      );

      expect(result, 'file');
      expect(platform.filePath, '/tmp/wallpaper.png');
      expect(platform.target, WallpaperTarget.lock);
      expect(platform.imageName, 'local_wallpaper');
      expect(platform.fileExtension, ImageFormat.png);
      expect(platform.width, 320);
      expect(platform.height, 480);
      expect(platform.options, RequestSizeOptions.resizeExact);
      expect(platform.fit, WallpaperFit.cover);
      expect(platform.alignment, WallpaperAlignment.topCenter);
      expect(platform.location, DownloadLocation.applicationDirectory);
    });

    test('setFromBytes forwards bytes to platform', () async {
      final previous = WallpaperPlatform.instance;
      final platform = _FakeWallpaperPlatform();
      WallpaperPlatform.instance = platform;
      addTearDown(() => WallpaperPlatform.instance = previous);

      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await Wallpaper.setFromBytes(
        bytes,
        target: WallpaperTarget.both,
        fileExtension: ImageFormat.jpeg,
      );

      expect(result, 'bytes');
      expect(platform.imageBytes, bytes);
      expect(platform.target, WallpaperTarget.both);
      expect(platform.fileExtension, ImageFormat.jpeg);
    });

    test('setFromAsset forwards package asset options to platform', () async {
      final previous = WallpaperPlatform.instance;
      final platform = _FakeWallpaperPlatform();
      WallpaperPlatform.instance = platform;
      addTearDown(() => WallpaperPlatform.instance = previous);

      final result = await Wallpaper.setFromAsset(
        'assets/wallpaper.png',
        package: 'wallpaper_assets',
        target: WallpaperTarget.home,
      );

      expect(result, 'asset');
      expect(platform.assetPath, 'assets/wallpaper.png');
      expect(platform.package, 'wallpaper_assets');
      expect(platform.target, WallpaperTarget.home);
    });

    test('setWallpaperFromSource returns typed success', () async {
      final previous = WallpaperPlatform.instance;
      final platform = _FakeWallpaperPlatform();
      WallpaperPlatform.instance = platform;
      addTearDown(() => WallpaperPlatform.instance = previous);

      final result = await Wallpaper.setWallpaperFromSource(
        source: const WallpaperSource.file('/tmp/wallpaper.jpeg'),
        options: const WallpaperOptions(
          target: WallpaperTarget.both,
          imageName: 'unified',
          fileExtension: ImageFormat.jpeg,
          width: 100,
          height: 200,
          resizeOption: RequestSizeOptions.resizeFit,
          fit: WallpaperFit.contain,
          alignment: WallpaperAlignment.bottomRight,
          location: DownloadLocation.applicationDirectory,
        ),
      );

      expect(result, isA<WallpaperSuccess>());
      expect((result as WallpaperSuccess).message, 'file');
      expect(platform.filePath, '/tmp/wallpaper.jpeg');
      expect(platform.target, WallpaperTarget.both);
      expect(platform.imageName, 'unified');
      expect(platform.width, 100);
      expect(platform.height, 200);
      expect(platform.options, RequestSizeOptions.resizeFit);
      expect(platform.fit, WallpaperFit.contain);
      expect(platform.alignment, WallpaperAlignment.bottomRight);
      expect(platform.location, DownloadLocation.applicationDirectory);
    });

    test(
      'setWallpaperFromSource maps PlatformException to typed failure',
      () async {
        final previous = WallpaperPlatform.instance;
        final platform = _FakeWallpaperPlatform()
          ..exception = PlatformException(
            code: 'DECODE_ERROR',
            message: 'Could not decode image',
          );
        WallpaperPlatform.instance = platform;
        addTearDown(() => WallpaperPlatform.instance = previous);

        final result = await Wallpaper.setWallpaperFromSource(
          source: WallpaperSource.bytes(Uint8List.fromList([1])),
        );

        expect(result, isA<WallpaperFailure>());
        final failure = result as WallpaperFailure;
        expect(failure.exception, isA<WallpaperDecodeException>());
        expect(failure.exception.code, 'DECODE_ERROR');
        expect(failure.exception.message, 'Could not decode image');
      },
    );

    test('download forwards typed options to platform', () async {
      final previous = WallpaperPlatform.instance;
      final platform = _FakeWallpaperPlatform();
      WallpaperPlatform.instance = platform;
      addTearDown(() => WallpaperPlatform.instance = previous);

      final operation = Wallpaper.download(
        'https://example.com/wallpaper.png',
        options: const WallpaperDownloadOptions(
          imageName: 'typed',
          fileExtension: ImageFormat.png,
          location: DownloadLocation.applicationDirectory,
          headers: {'Authorization': 'Bearer token'},
          connectTimeout: Duration(seconds: 1),
          receiveTimeout: Duration(seconds: 2),
          cachePolicy: WallpaperCachePolicy.reuse,
        ),
      );
      final downloaded = await operation.completed;

      expect(platform.downloadUrl, 'https://example.com/wallpaper.png');
      expect(platform.downloadOptions?.imageName, 'typed');
      expect(platform.downloadOptions?.fileExtension, ImageFormat.png);
      expect(
        platform.downloadOptions?.location,
        DownloadLocation.applicationDirectory,
      );
      expect(platform.downloadOptions?.headers, {
        'Authorization': 'Bearer token',
      });
      expect(
        platform.downloadOptions?.connectTimeout,
        const Duration(seconds: 1),
      );
      expect(
        platform.downloadOptions?.receiveTimeout,
        const Duration(seconds: 2),
      );
      expect(platform.downloadOptions?.cachePolicy, WallpaperCachePolicy.reuse);
      expect(downloaded.path, '/tmp/typed.png');
      expect(downloaded.fromCache, false);
    });

    test('clearCache forwards to platform', () async {
      final previous = WallpaperPlatform.instance;
      final platform = _FakeWallpaperPlatform();
      WallpaperPlatform.instance = platform;
      addTearDown(() => WallpaperPlatform.instance = previous);

      await Wallpaper.clearCache();

      expect(platform.clearCacheCalled, isTrue);
    });
  });
}

class _FakeWallpaperPlatform extends WallpaperPlatform {
  String? filePath;
  Uint8List? imageBytes;
  String? assetPath;
  String? package;
  WallpaperTarget? target;
  String? imageName;
  ImageFormat? fileExtension;
  double? width;
  double? height;
  RequestSizeOptions? options;
  WallpaperFit? fit;
  WallpaperAlignment? alignment;
  DownloadLocation? location;
  PlatformException? exception;
  String? downloadUrl;
  WallpaperDownloadOptions? downloadOptions;
  bool clearCacheCalled = false;
  bool openWallpaperChooserCalled = false;
  WallpaperSize recommendedSize = const WallpaperSize(
    width: 1080,
    height: 2400,
  );

  @override
  Future<String?> getPlatformVersion() async => 'fake';

  @override
  Future<WallpaperSize> recommendedWallpaperSize() async => recommendedSize;

  @override
  Future<String> openWallpaperChooser() async {
    openWallpaperChooserCalled = true;
    return 'chooser';
  }

  @override
  Future<String> homeScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async => 'home';

  @override
  Future<String> lockScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async => 'lock';

  @override
  Future<String> bothScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async => 'both';

  @override
  Future<String> systemScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async => 'system';

  @override
  Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) => const Stream.empty();

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
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    this.filePath = filePath;
    this.target = target;
    this.imageName = imageName;
    this.fileExtension = fileExtension;
    this.width = width;
    this.height = height;
    this.options = options;
    this.fit = fit;
    this.alignment = alignment;
    this.location = location;
    return 'file';
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
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    this.imageBytes = imageBytes;
    this.target = target;
    this.imageName = imageName;
    this.fileExtension = fileExtension;
    this.width = width;
    this.height = height;
    this.options = options;
    this.fit = fit;
    this.alignment = alignment;
    this.location = location;
    return 'bytes';
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
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    this.assetPath = assetPath;
    this.package = package;
    this.target = target;
    this.imageName = imageName;
    this.fileExtension = fileExtension;
    this.width = width;
    this.height = height;
    this.options = options;
    this.fit = fit;
    this.alignment = alignment;
    this.location = location;
    return 'asset';
  }

  @override
  WallpaperDownloadOperation download(
    String url, {
    WallpaperDownloadOptions options = const WallpaperDownloadOptions(),
  }) {
    downloadUrl = url;
    downloadOptions = options;
    return WallpaperDownloadOperation(
      progress: const Stream.empty(),
      completed: Future.value(
        WallpaperDownloadedFile(
          path: '/tmp/${options.imageName ?? 'wallpaper'}.png',
          imageName: options.imageName ?? 'wallpaper',
          fileExtension: options.fileExtension,
          location: options.location,
          fromCache: false,
        ),
      ),
      cancel: () async {},
    );
  }

  @override
  Future<void> clearCache() async {
    clearCacheCalled = true;
  }
}
