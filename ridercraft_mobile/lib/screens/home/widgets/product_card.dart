import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../utils/wishlist_actions.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/rc_image.dart';
import '../../../widgets/rc_price.dart';

/// Premium dark product card: elevated surface, contained product image over a
/// red-tinted glow, rider red brand kicker, animated wishlist toggle, bold
/// pricing (with flash-sale support), rating, and a functional footer.
///
/// The footer is context-aware:
/// - products with required options open the detail screen ("Select Options"),
/// - option-less in-stock products quick-add straight to the cart ("ADD"),
/// - out-of-stock products get a disabled pill.
///
/// The image tile carries a [Hero] so tapping a card flies the image into the
/// product detail gallery.
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  /// Height a [ProductCard] needs inside a fixed-slot host (a grid cell or a
  /// horizontal row) for the current text scaler.
  ///
  /// The card is made of fixed chrome — the image tile, paddings, gaps and the
  /// footer pill — plus text lines (brand, two-line title, price, rating) that
  /// grow with the accessibility font size. Hosts size their slots from this so
  /// scaled text never overflows the card.
  static double slotHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 3.0);
    return 216 + 136 * scale;
  }

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _adding = false;
  bool _added = false;
  Timer? _addedTimer;

  Product get _product => widget.product;

  bool get _hasOptions =>
      _product.colors.isNotEmpty || _product.sizes.isNotEmpty;

  double get _effectivePrice {
    if (_product.isFlashSaleActive && _product.flashSalePrice > 0) {
      return _product.flashSalePrice;
    }
    return _product.displayPrice;
  }

  CartProvider? _readCart(BuildContext context) {
    try {
      return Provider.of<CartProvider>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _quickAdd() async {
    final cart = _readCart(context);
    if (cart == null) {
      // No cart in this tree (e.g. some test harnesses): fall back to opening
      // the detail screen which owns the full purchase flow.
      widget.onTap();
      return;
    }
    setState(() => _adding = true);
    await cart.addProduct(_product, quantity: 1);
    if (!mounted) return;
    setState(() {
      _adding = false;
      _added = true;
    });
    _addedTimer?.cancel();
    _addedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inWishlist = context.select<ProductProvider, bool>(
      (provider) => provider.isInWishlist(_product.id),
    );

    return PressScale(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadow.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(inWishlist),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm - 2),
                  Row(
                    children: [
                      Flexible(
                        child: RcPrice(
                          amount: Formatters.inr(_effectivePrice),
                          originalAmount:
                              _effectivePrice < _product.originalPrice ||
                                      _effectivePrice < _product.displayPrice
                                  ? Formatters.inr(
                                      _product.isFlashSaleActive
                                          ? _product.displayPrice
                                          : _product.originalPrice,
                                    )
                                  : null,
                          size: 16,
                        ),
                      ),
                      if (_product.isFlashSaleActive &&
                          _product.flashSalePrice > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppRadius.pill,
                            ),
                          ),
                          child: const Text(
                            'FLASH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _product.ratingCount > 0
                              ? _product.ratingAverage.toStringAsFixed(1)
                              : 'New',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFooter(onTap: widget.onTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool inWishlist) {
    return Stack(
      children: [
        Hero(
          tag: 'product-hero-${_product.id}',
          child: Container(
            height: 168,
            width: double.infinity,
            color: AppColors.surfaceAlt,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.2, -0.6),
                        radius: 1.1,
                        colors: [
                          Color(0x1FE31B23),
                          Color(0x00E31B23),
                        ],
                      ),
                    ),
                  ),
                  RcImage(_product.image, fit: BoxFit.contain),
                ],
              ),
            ),
          ),
        ),
        if (_product.discountPercent > 0 || _isFlashActive)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_product.discountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '-${_product.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (_isFlashActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'FLASH SALE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (!_product.inStock)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: AppColors.surfaceElevated,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => toggleWishlistFromContext(context, _product),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    inWishlist
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(inWishlist),
                    size: 16,
                    color: inWishlist
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _isFlashActive =>
      _product.isFlashSaleActive && _product.flashSalePrice > 0;

  Widget _buildFooter({required VoidCallback onTap}) {
    if (!_product.inStock) {
      return Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    if (_hasOptions) {
      return _FooterPill(
        outlined: true,
        label: 'Select Options',
        icon: Icons.tune_rounded,
        onTap: onTap,
      );
    }

    return Semantics(
      button: true,
      label: 'Add ${_product.name} to cart',
      child: _FooterPill(
        outlined: false,
        label: _adding
            ? 'Adding…'
            : (_added ? 'Added' : 'Add'),
        icon: _adding
            ? null
            : (_added ? Icons.check_rounded : Icons.shopping_bag_outlined),
        onTap: _adding ? null : _quickAdd,
        showSpinner: _adding,
        accent: _added,
      ),
    );
  }
}

class _FooterPill extends StatelessWidget {
  final bool outlined;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showSpinner;
  final bool accent;

  const _FooterPill({
    required this.outlined,
    required this.label,
    this.icon,
    this.onTap,
    this.showSpinner = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = showSpinner ? false : (onTap != null);
    return PressScale(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : 0.55,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: outlined ? null : AppColors.primaryGradient,
            color: outlined ? AppColors.surfaceAlt : null,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: accent
                  ? AppColors.success
                  : (outlined ? AppColors.border : AppColors.primary),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSpinner)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else if (icon != null) ...[
                    Icon(
                      icon,
                      size: 13,
                      color: accent
                          ? const Color(0xFF7CF29D)
                          : (outlined
                              ? AppColors.textSecondary
                              : Colors.white),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: outlined
                          ? AppColors.textSecondary
                          : (accent ? const Color(0xFF7CF29D) : Colors.white),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}