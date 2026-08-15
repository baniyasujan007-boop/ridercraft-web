import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network image with a RiderCraft branded placeholder on loading and a
/// branded error fallback instead of crashing.
///
/// Accepts standard `http(s)://` image URLs (served through
/// [CachedNetworkImage]) as well as base64 `data:` URIs — the format the web
/// profile settings send for uploaded avatars — which are decoded and
/// rendered from memory. Any URL that cannot be loaded falls back to the
/// branded placeholder.
class RcImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const RcImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  static const String _dataUriPrefix = 'data:image/';
  static const String _dataUriBase64Marker = ';base64,';

  /// Decodes a `data:image/*;base64,...` URI to raw image bytes, or null when
  /// the value is not a supported data URI or its payload is malformed.
  static Uint8List? _decodeDataUri(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith(_dataUriPrefix)) return null;
    final markerIndex = trimmed.indexOf(_dataUriBase64Marker);
    if (markerIndex < 0) return null;
    final encoded = trimmed
        .substring(markerIndex + _dataUriBase64Marker.length)
        .trim();
    if (encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  static Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: const Icon(
        Icons.sports_motorsports_rounded,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }

  Widget _dataUriImage(Uint8List bytes) {
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          _placeholder(height ?? width ?? double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    final urlTrimmed = url.trim();
    final double? sizeFallback = height ?? width;

    if (urlTrimmed.isEmpty) {
      child = _placeholder(sizeFallback ?? double.infinity);
    } else {
      final dataBytes = _decodeDataUri(urlTrimmed);
      if (dataBytes != null) {
        child = _dataUriImage(dataBytes);
      } else if (urlTrimmed.startsWith('data:')) {
        // A data URI that cannot be decoded should never hit the network.
        child = _placeholder(sizeFallback ?? double.infinity);
      } else {
        child = CachedNetworkImage(
          imageUrl: urlTrimmed,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, _) => _placeholder(sizeFallback ?? double.infinity),
          errorWidget: (_, _, _) =>
              _placeholder(sizeFallback ?? double.infinity),
        );
      }
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
