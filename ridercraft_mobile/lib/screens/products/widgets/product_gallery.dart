import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_image.dart';

/// Swipeable hero gallery with page counter, flash/discount badges and a
/// thumbnail strip when multiple images exist. The first page carries a
/// [Hero] so tapping a product card flies its image in from the grid.
class ProductGallery extends StatefulWidget {
  final List<String> images;
  final String heroTag;
  final int discountPercent;
  final bool flashActive;

  const ProductGallery({
    super.key,
    required this.images,
    required this.heroTag,
    this.discountPercent = 0,
    this.flashActive = false,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    _controller.jumpToPage(index);
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 300,
          color: AppColors.surfaceAlt,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.15, -0.7),
                      radius: 1.2,
                      colors: AppColors.heroGlowColors,
                    ),
                  ),
                ),
              ),
              if (images.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: RcImage('', fit: BoxFit.contain),
                )
              else
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final image = Padding(
                      padding: const EdgeInsets.all(16),
                      child: RcImage(images[index], fit: BoxFit.contain),
                    );
                    return index == 0
                        ? Hero(tag: widget.heroTag, child: image)
                        : image;
                  },
                ),
              if (widget.discountPercent > 0 || widget.flashActive)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.discountPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${widget.discountPercent}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (widget.flashActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            'FLASH SALE',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${_index + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = _index == index;
                return GestureDetector(
                  onTap: () => _jumpTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 58,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: RcImage(images[index], fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}