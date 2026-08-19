import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../utils/wishlist_actions.dart';
import '../../widgets/cart_icon_button.dart';
import '../../widgets/rc_entrance.dart';
import 'widgets/product_gallery.dart';
import 'widgets/purchase_bar.dart';
import 'widgets/related_products.dart';

/// Product detail with swipeable hero gallery, thumbnails, server-computed
/// pricing (flash-sale aware), stock-aware variants and quantity, an animated
/// add-to-cart purchase bar and a same-category "More Like This" carousel.
///
/// Business behaviour is unchanged: the same cart payload built as before, the
/// same colour/size validation messages and the same Buy Now flow.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;
  String? _selectedSize;
  bool _adding = false;
  bool _added = false;
  Timer? _addedTimer;

  Product get _product => widget.product;

  bool get _isFlashActive =>
      _product.isFlashSaleActive && _product.flashSalePrice > 0;

  double get _displayedPrice => _isFlashActive
      ? _product.flashSalePrice
      : _product.displayPrice;

  /// The backend defines options per product; only require what it provides.
  bool get _requiresColor => _product.colors.isNotEmpty;
  bool get _requiresSize => _product.sizes.isNotEmpty;

  ProductVariant? get _selectedVariant => _selectedColor == null
      ? null
      : _variantFor(_selectedColor!);

  bool get _purchasable =>
      _product.inStock &&
      (_selectedVariant == null || _selectedVariant!.stock > 0);

  int get _effectiveStock {
    final variant = _selectedVariant;
    if (variant != null) return variant.stock;
    return _product.stock;
  }

  int get _maxQuantity {
    if (!_product.inStock) return 0;
    final cap = _effectiveStock < 99 ? _effectiveStock : 99;
    return cap < 0 ? 0 : cap;
  }

  ProductVariant? _variantFor(String color) {
    for (final variant in _product.variants) {
      if (variant.color == color) return variant;
    }
    return null;
  }

  Color? _swatchFor(String color) {
    final hex = _variantFor(color)?.colorHex ?? '';
    final value = hex.replaceFirst('#', '');
    if (value.length != 6 && value.length != 3) return null;
    try {
      final expanded = value.length == 3
          ? value.split('').map((c) => '$c$c').join()
          : value;
      return Color(int.parse('FF$expanded', radix: 16));
    } catch (_) {
      return null;
    }
  }

  bool _colorAvailable(String color) {
    final variant = _variantFor(color);
    return variant == null || variant.stock > 0;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectColor(String color) {
    if (!_colorAvailable(color)) {
      _showSnack('This color is currently unavailable.');
      return;
    }
    setState(() {
      _selectedColor = color;
      final variant = _variantFor(color);
      final cap = variant != null ? variant.stock : _product.stock;
      if (cap > 0 && _quantity > cap) _quantity = cap;
    });
  }

  void _selectSize(String size) => setState(() => _selectedSize = size);

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  Future<void> _addToCart({bool buyNow = false}) async {
    if (_requiresColor && _selectedColor == null) {
      _showSnack('Please select a color to continue.');
      return;
    }
    if (_requiresSize && _selectedSize == null) {
      _showSnack('Please select a size to continue.');
      return;
    }
    final variant = _selectedVariant;
    setState(() => _adding = true);
    final cart = context.read<CartProvider>();
    await cart.addProduct(
      _product,
      variantId: variant?.id ?? '',
      variantSku: variant?.sku ?? '',
      color: _selectedColor ?? '',
      colorHex: variant?.colorHex ?? '',
      size: _selectedSize ?? '',
      quantity: _quantity,
    );
    if (!mounted) return;
    setState(() => _adding = false);
    if (!buyNow) {
      setState(() => _added = true);
      _addedTimer?.cancel();
      _addedTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _added = false);
      });
    }
    _showSnack(buyNow ? 'Added to cart.' : '${_product.name} added to cart');
    if (buyNow) Navigator.pushNamed(context, RouteNames.cart);
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final related = _relatedProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          _WishlistButton(product: product),
          const SizedBox(width: 2),
          const CartIconButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ProductGallery(
            images: product.gallery,
            heroTag: 'product-hero-${product.id}',
            discountPercent: product.discountPercent,
            flashActive: _isFlashActive,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusRow(product: product),
                const SizedBox(height: 16),
                _PriceRow(
                  displayedPrice: _displayedPrice,
                  strikethroughPrice: _isFlashActive
                      ? product.displayPrice
                      : (product.displayPrice < product.originalPrice
                          ? product.originalPrice
                          : null),
                  isFlashActive: _isFlashActive,
                  discountPercent: product.discountPercent,
                ),
                if (_requiresColor) ...[
                  const SizedBox(height: 20),
                  _OptionLabel(label: 'Color', required: true),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final color in product.colors)
                        _OptionChip(
                          key: ValueKey('swatch-$color'),
                          label: color,
                          swatch: _swatchFor(color),
                          selected: _selectedColor == color,
                          available: _colorAvailable(color),
                          onTap: () => _selectColor(color),
                          onUnavailable: () => _showSnack(
                            'This color is currently unavailable.',
                          ),
                        ),
                    ],
                  ),
                ],
                if (_requiresSize) ...[
                  const SizedBox(height: 20),
                  _OptionLabel(label: 'Size', required: true),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final size in product.sizes)
                        _OptionChip(
                          label: size,
                          selected: _selectedSize == size,
                          available: true,
                          onTap: () => _selectSize(size),
                        ),
                    ],
                  ),
                ],
                const Divider(height: 40),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description.isEmpty
                      ? 'No description available for this product yet.'
                      : product.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 24),
            RcEntrance(
              child: RelatedProductsCarousel(
                products: related,
                onProductTap: (product) => Navigator.of(context).pushNamed(
                  RouteNames.productDetail,
                  arguments: product,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: PurchaseBar(
        quantity: _quantity,
        maxQuantity: _maxQuantity,
        outOfStock: !product.inStock || !_purchasable,
        adding: _adding,
        added: _added,
        onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
        onIncrement:
            _quantity < _maxQuantity && _maxQuantity > 0
            ? () => setState(() => _quantity++)
            : null,
        onAddToCart: _purchasable && product.inStock
            ? () => _addToCart()
            : null,
        onBuyNow: _purchasable && product.inStock
            ? () => _addToCart(buyNow: true)
            : null,
      ),
    );
  }

  List<Product> _relatedProducts() {
    final provider = context.watch<ProductProvider>();
    final tag = _product.tag.trim();
    if (tag.isEmpty) return const [];
    return provider.products
        .where(
          (product) => product.id != _product.id && product.tag == tag,
        )
        .take(8)
        .toList();
  }
}

class _WishlistButton extends StatelessWidget {
  final Product product;

  const _WishlistButton({required this.product});

  @override
  Widget build(BuildContext context) {
    final inWishlist = context.select<ProductProvider, bool>(
      (provider) => provider.isInWishlist(product.id),
    );
    return IconButton(
      tooltip: 'Save',
      onPressed: () => toggleWishlistFromContext(context, product),
      icon: Icon(
        inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: inWishlist ? AppColors.primary : null,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Product product;

  const _StatusRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: AppColors.accent,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          product.ratingCount > 0
              ? product.ratingAverage.toStringAsFixed(1)
              : 'New',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (product.ratingCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '(${product.ratingCount} ratings)',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const Spacer(),
        if (!product.inStock)
          const Text(
            'OUT OF STOCK',
            style: TextStyle(
              color: Color(0xFFF87171),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          )
        else ...[
          const Text(
            'IN STOCK',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          if (product.stock <= 10) ...[
            const SizedBox(width: 8),
            Text(
              'Only ${product.stock} left',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final double displayedPrice;
  final double? strikethroughPrice;
  final bool isFlashActive;
  final int discountPercent;

  const _PriceRow({
    required this.displayedPrice,
    required this.strikethroughPrice,
    required this.isFlashActive,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          Formatters.inr(displayedPrice),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (strikethroughPrice != null) ...[
          const SizedBox(width: 10),
          Text(
            Formatters.inr(strikethroughPrice!),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
        if (isFlashActive) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              'FLASH',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        if (discountPercent > 0 && strikethroughPrice != null && !isFlashActive) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '-$discountPercent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _OptionLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final Color? swatch;
  final bool selected;
  final bool available;
  final VoidCallback onTap;
  final VoidCallback? onUnavailable;

  const _OptionChip({
    super.key,
    required this.label,
    this.swatch,
    required this.selected,
    required this.available,
    required this.onTap,
    this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final action = available ? onTap : (onUnavailable ?? () {});

    if (swatch != null) {
      return Semantics(
        button: true,
        label: '$label color option',
        child: InkWell(
          onTap: action,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (available ? AppColors.border : AppColors.border),
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Opacity(
              opacity: available ? 1 : 0.45,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  if (!available)
                    Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 2,
                        height: 34,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 54, minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}