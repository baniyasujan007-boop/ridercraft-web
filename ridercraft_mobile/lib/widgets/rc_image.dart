import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network image with a RiderCraft branded placeholder on loading and a
/// branded error fallback instead of crashing.
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

  @override
  Widget build(BuildContext context) {
    Widget child;
    final urlTrimmed = url.trim();

    if (urlTrimmed.isEmpty) {
      child = _placeholder(height ?? width ?? double.infinity);
    } else {
      child = CachedNetworkImage(
        imageUrl: urlTrimmed,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => _placeholder(height ?? width ?? double.infinity),
        errorWidget: (_, _, _) =>
            _placeholder(height ?? width ?? double.infinity),
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
