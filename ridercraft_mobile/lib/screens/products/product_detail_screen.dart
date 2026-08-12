import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/wishlist_actions.dart';
import '../../widgets/rc_image.dart';

/// Product detail with image gallery, server-computed pricing, quantity
/// selector and add-to-cart. Opened from the Home featured sections.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _galleryController;
  int _galleryIndex = 0;
  int _quantity = 1;
  String? _selectedColor;
  String? _selectedSize;

  Product get _product => widget.product;

  /// The backend defines options per product; only require what it provides.
  bool get _requiresColor => _product.colors.isNotEmpty;
  bool get _requiresSize => _product.sizes.isNotEmpty;

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
  }

  @override
  void dispose() {
    _galleryController.dispose();
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
    final variant = _selectedColor == null
        ? null
        : _variantFor(_selectedColor!);
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
    _showSnack(buyNow ? 'Added to cart.' : '${_product.name} added to cart');
    if (buyNow) Navigator.pushNamed(context, RouteNames.cart);
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final gallery = product.gallery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          _WishlistButton(product: product),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, RouteNames.cart),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Gallery (light tile like the website PDP)
          Container(
            height: 320,
            color: const Color(0xFFF7F8FA),
            child: Stack(
              children: [
                if (gallery.isEmpty)
                  const RcImage('', fit: BoxFit.contain)
                else
                  PageView.builder(
                    controller: _galleryController,
                    itemCount: gallery.length,
                    onPageChanged: (index) =>
                        setState(() => _galleryIndex = index),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(14),
                      child: RcImage(gallery[index], fit: BoxFit.contain),
                    ),
                  ),
                if (product.discountPercent > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${product.discountPercent}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (gallery.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17202D).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_galleryIndex + 1}/${gallery.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFF4D00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
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
                          color: Color(0xFF3EE24F),
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
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      Formatters.inr(product.displayPrice),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.displayPrice < product.originalPrice) ...[
                      const SizedBox(width: 10),
                      Text(
                        Formatters.inr(product.originalPrice),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A00),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                if (_requiresColor) ...[
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
                          onTap: () => setState(() => _selectedColor = color),
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
                          onTap: () => setState(() => _selectedSize = size),
                        ),
                    ],
                  ),
                ],
                const Divider(height: 40),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
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
        ],
      ),
      bottomNavigationBar: _BottomBar(
        quantity: _quantity,
        onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
        onIncrement: () => setState(() => _quantity++),
        onAddToCart: product.inStock ? () => _addToCart() : null,
        onBuyNow: product.inStock ? () => _addToCart(buyNow: true) : null,
      ),
    );
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
              color: Color(0xFFFF4D00),
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
  final VoidCallback onTap;

  const _OptionChip({
    super.key,
    required this.label,
    this.swatch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (swatch != null) {
      // Website-style color swatch: 34px circle, orange selection ring.
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFFFF4D00) : AppColors.border,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
        ),
      );
    }

    // Website-style size button: min 54x38, orange border when active.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 54, minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF4D00) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF4D00)
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

class _BottomBar extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const _BottomBar({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Color(0xFF071426),
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onDecrement,
                    icon: const Icon(Icons.remove_rounded, size: 20),
                    iconSize: 20,
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onBuyNow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF4D00), Color(0xFFFF3D00)],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: FilledButton(
                  onPressed: onAddToCart,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
