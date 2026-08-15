// Unit tests for AvatarProcessor: any picked file is normalized into a small
// JPEG `data:` URI (never a full-resolution base64 blob), invalid input fails
// with a friendly error, and small images are not upscaled.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ridercraft_mobile/utils/avatar_processor.dart';

Uint8List _png(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgba8(255, 120, 0, 255));
  return img.encodePng(image);
}

(int, int) _dimensionsOf(String dataUri) {
  final bytes = base64Decode(
    dataUri.substring(dataUri.indexOf(',') + 1),
  );
  final decoded = img.decodeImage(Uint8List.fromList(bytes));
  return (decoded!.width, decoded.height);
}

void main() {
  test('encodes a picked PNG into a JPEG data URI the backend accepts', () {
    final uri = AvatarProcessor.processImage(_png(600, 400));

    expect(uri, startsWith('data:image/jpeg;base64,'));
    final decoded = base64Decode(uri.substring(uri.indexOf(',') + 1));
    expect(decoded.length, greaterThan(0));
  });

  test('downscales an oversized image to the max dimension', () {
    final uri = AvatarProcessor.processImage(_png(2000, 1500));

    final (width, height) = _dimensionsOf(uri);
    expect(width, lessThanOrEqualTo(512));
    expect(height, lessThanOrEqualTo(512));
    // Aspect ratio preserved.
    expect(height / width, closeTo(1500 / 2000, 0.02));
  });

  test('keeps a small image at its original size (no upscaling)', () {
    final uri = AvatarProcessor.processImage(_png(100, 80));

    final (width, height) = _dimensionsOf(uri);
    expect(width, 100);
    expect(height, 80);
  });

  test('the resized base64 payload is small enough for the 5mb body limit', () {
    final uri = AvatarProcessor.processImage(_png(4000, 3000));

    // The original 4000x3000 PNG would be several MB once base64-encoded; the
    // processed avatar must stay tiny.
    expect(uri.length, lessThan(500 * 1024));
  });

  test('rejects empty bytes without touching the backend contract', () {
    expect(
      () => AvatarProcessor.processImage(Uint8List(0)),
      throwsA(
        isA<AvatarProcessException>()
            .having((e) => e.message, 'message', contains('No image data')),
      ),
    );
  });

  test('rejects undecodable bytes with a friendly message', () {
    expect(
      () => AvatarProcessor.processImage(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(
        isA<AvatarProcessException>()
            .having(
              (e) => e.message,
              'message',
              contains("Couldn't read that image"),
            ),
      ),
    );
  });
}