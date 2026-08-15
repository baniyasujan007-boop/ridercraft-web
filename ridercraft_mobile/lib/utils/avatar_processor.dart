import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Raised when the picked file cannot be turned into a usable avatar.
class AvatarProcessException implements Exception {
  final String message;

  const AvatarProcessException(this.message);

  @override
  String toString() => message;
}

/// Normalizes picked image bytes into the avatar `data:` URI the backend stores
/// in `User.avatar` — the same format the website sends.
///
/// The source image is downscaled to at most [defaultMaxDimension] on the
/// longest edge and re-encoded as JPEG so a full-resolution photo never turns
/// into a multi-megabyte base64 payload (which would blow the Express 5mb JSON
/// body limit and the MongoDB document limit).
class AvatarProcessor {
  const AvatarProcessor._();

  /// Longest edge (px) an avatar is stored at. 512px is far more than the
  /// 64px displayed on the profile screen while keeping JPEGs tens of KB.
  static const int defaultMaxDimension = 512;

  /// JPEG quality used when re-encoding the avatar.
  static const int defaultQuality = 82;

  /// Returns `data:image/jpeg;base64,<…>` for [bytes], or throws
  /// [AvatarProcessException] when the file is empty / undecodable.
  static String processImage(
    Uint8List bytes, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) {
    if (bytes.isEmpty) {
      throw const AvatarProcessException('No image data was received.');
    }
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      // Some decoders throw on truncated/short input instead of returning null.
      decoded = null;
    }
    if (decoded == null) {
      throw const AvatarProcessException(
        "Couldn't read that image. Please try another one.",
      );
    }

    var image = decoded;
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxDimension) {
      final scale = maxDimension / longest;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    final encoded = img.encodeJpg(image, quality: quality);
    return 'data:image/jpeg;base64,${base64Encode(encoded)}';
  }
}