import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_view.dart';
import '../home/widgets/product_card.dart';

/// Shop tab: the real product catalogue from `GET /products`.
///
/// Mobile-friendly responsive grid of website-style product cards with
/// search (client-side filter over the loaded catalogue) and tag filtering.
/// Loading, empty, error/retry and pull-to-refresh states are all handled.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _tagFilter;
  bool _started = false;
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Defer past the first frame: ProductProvider notifies synchronously.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.loadProducts();
    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      await productProvider.loadWishlist();
    }
    if (mounted) setState(() => _loadedOnce = true);
  }

  Future<void> _refresh() async {
    final productProvider = context.read<ProductProvider>();
    final hadProducts = productProvider.products.isNotEmpty;
    await productProvider.loadProducts();
    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      await productProvider.loadWishlist();
    }
    if (!mounted) return;
    if (hadProducts && productProvider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(productProvider.error!)));
    }
  }

  void _openProduct(Product product) {
    Navigator.of(
      context,
    ).pushNamed(RouteNames.productDetail, arguments: product);
  }

  List<Product> _visible(ProductProvider provider) {
    var list = provider.products;
    if (_tagFilter != null) {
      list = list.where((p) => p.tag == _tagFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      list = provider
          .search(_searchQuery)
          .where((p) => _tagFilter == null || p.tag == _tagFilter)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          _CartButton(),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Retry load',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadedOnce && provider.products.isNotEmpty) ...[
            _buildSearchField(),
            _buildTagFilter(provider),
          ],
          Expanded(child: _buildContent(provider)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search products, brands…',
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildTagFilter(ProductProvider provider) {
    final tags = <String>{};
    for (final product in provider.products) {
      if (product.tag.isNotEmpty) tags.add(product.tag);
    }
    if (tags.isEmpty) return const SizedBox.shrink();

    final allSelected = _tagFilter == null;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _TagChip(
            label: 'All',
            selected: allSelected,
            onTap: () => setState(() => _tagFilter = null),
          ),
          for (final tag in tags.toList()..sort())
            _TagChip(
              label: tag,
              selected: _tagFilter == tag,
              onTap: () => setState(() => _tagFilter = tag),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ProductProvider provider) {
    if (!_loadedOnce ||
        (provider.loadingProducts && provider.products.isEmpty)) {
      return const _ShopSkeleton();
    }
    if (provider.error != null && provider.products.isEmpty) {
      return ErrorView(message: provider.error!, onRetry: _load);
    }
    if (provider.products.isEmpty) {
      return _EmptyShop(onRetry: _load);
    }

    final visible = _visible(provider);
    if (visible.isEmpty) {
      return _NoMatches(
        onClear: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
            _tagFilter = null;
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / 190)
              .floor()
              .clamp(2, 6)
              .toInt();
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              mainAxisExtent: ProductCard.slotHeight(context),
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final product = visible[index];
              return ProductCard(
                product: product,
                onTap: () => _openProduct(product),
              );
            },
          );
        },
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Cart',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.pushNamed(context, RouteNames.cart),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopSkeleton extends StatelessWidget {
  const _ShopSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 190)
            .floor()
            .clamp(2, 6)
            .toInt();
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            mainAxisExtent: ProductCard.slotHeight(context),
          ),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyShop extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyShop({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            const Text(
              'No products yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The catalogue is empty right now. Pull to refresh or try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final VoidCallback onClear;

  const _NoMatches({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            const Text(
              'No products found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different search or clear the filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}
