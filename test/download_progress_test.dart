import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper/wallpaper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('imageDownloadProgress', () {
    test('empty URL emits PlatformException with INVALID_ARGUMENT', () async {
      final stream = Wallpaper.imageDownloadProgress('');
      final errors = <Object>[];
      final completer = Completer<void>();

      final subscription = stream.listen(
        (_) {},
        onError: (e, _) {
          errors.add(e);
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw Exception('Expected stream to emit error or complete'),
      );

      expect(errors, isNotEmpty);
      expect(errors.first, isA<PlatformException>());
      expect((errors.first as PlatformException).code, 'INVALID_ARGUMENT');
      expect((errors.first as PlatformException).message, contains('URL'));

      await subscription.cancel();
    });

    test('stream is a Stream<String>', () {
      final stream = Wallpaper.imageDownloadProgress('https://example.com/image.jpg');
      expect(stream, isA<Stream<String>>());
      stream.listen(null, onError: (_, __) {}, onDone: () {}).cancel();
    });
  });
}
