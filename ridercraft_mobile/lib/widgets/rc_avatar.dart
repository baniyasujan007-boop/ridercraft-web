import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/rc_image.dart';

/// Circular rider avatar with a branded fallback: shows the user's uploaded
/// photo via [RcImage] (network or data URI) or a red-gradient initials badge
/// when no avatar exists. Used in the Home header and account surfaces.
class RcAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;

  const RcAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 34,
    this.onTap,
  });

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .toList();
    final init = (parts.isEmpty ? 'R' : parts.join()).toUpperCase();
    return init;
  }

  Widget get _avatar {
    final url = avatarUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: RcImage(url, width: size, height: size, fit: BoxFit.cover),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * 0.22),
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Padding(padding: const EdgeInsets.all(2), child: _avatar),
    );

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
