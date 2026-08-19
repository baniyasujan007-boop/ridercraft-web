import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/error_view.dart';
import '../../widgets/rc_entrance.dart';
import '../../widgets/rc_icon_button.dart';
import '../../widgets/rc_search_bar.dart';
import '../home/widgets/product_card.dart';
import 'widgets/category_carousel.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/shop_skeleton.dart';
import 'widgets/shop_toolbar.dart';
import '../../widgets/cart_icon_button.dart';

/// Shop tab: the real product catalogue from `GET /products`.
///
/// Premium marketplace layout — search, data-driven category rail, client-side
/// filter/sort toolbar (in-stock filter + relevance/price/rating/discount
/// sorts over the loaded catalogue), and a responsive grid of redesigned
/// product cards. Loading, empty, error/retry and pull-to-refresh are handled.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _tagFilter;
  bool _inStockOnly = false;
  String _sort = 'relevance';
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

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<ShopFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(sort: _sort, inStockOnly: _inStockOnly),
    );
    if (result != null && mounted) {
      setState(() {
        _sort = result.sort;
        _inStockOnly = result.inStockOnly;
      });
    }
  }

  double _effectivePrice(Product product) {
    if (product.isFlashSaleActive && product.flashSalePrice > 0) {
      return product.flashSalePrice;
    }
    return product.displayPrice;
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
    if (_inStockOnly) {
      list = list.where((p) => p.inStock).toList();
    }
    if (_sort == 'relevance') return List.of(list);

    final sorted = List.of(list);
    switch (_sort) {
      case 'price_asc':
        sorted.sort(
          (a, b) => _effectivePrice(a).compareTo(_effectivePrice(b)),
        );
      case 'price_desc':
        sorted.sort(
          (a, b) => _effectivePrice(b).compareTo(_effectivePrice(a)),
        );
      case 'rating':
        sorted.sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
      case 'discount':
        sorted.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final catalogueVisible = _loadedOnce && provider.products.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          const CartIconButton(),
          const SizedBox(width: 4),
          RcIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Retry load',
            onTap: _load,
            showDot: provider.error != null,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (catalogueVisible) ...[
            RcEntrance(
              offset: 10,
              child: _buildSearchField(),
            ),
            RcEntrance(
              offset: 10,
              child: CategoryCarousel(
                tags: _catalogueTags(provider),
                selected: _tagFilter,
                onSelected: (tag) => setState(() => _tagFilter = tag),
              ),
            ),
            RcEntrance(
              offset: 10,
              child: ShopToolbar(
                sortLabel: shopSortLabel(_sort),
                filterActive: _inStockOnly,
                countLabel: '${_visible(provider).length} items',
                onFilter: _openFilterSheet,
                onSort: _openFilterSheet,
              ),
            ),
          ],
          Expanded(child: _buildContent(provider)),
        ],
      ),
    );
  }

  List<String> _catalogueTags(ProductProvider provider) {
    final tags = <String>{};
    for (final product in provider.products) {
      if (product.tag.isNotEmpty) tags.add(product.tag);
    }
    return tags.toList();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 4),
      child: RcSearchBar(
        controller: _searchController,
        hint: 'Search products, brands…',
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: () => setState(() => _searchQuery = ''),
      ),
    );
  }

  Widget _buildContent(ProductProvider provider) {
    if (!_loadedOnce ||
        (provider.loadingProducts && provider.products.isEmpty)) {
      return const ShopSkeleton();
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
            _inStockOnly = false;
            _sort = 'relevance';
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              mainAxisExtent: ProductCard.slotHeight(context),
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final product = visible[index];
              return RcEntrance(
                offset: 12,
                child: ProductCard(
                  product: product,
                  onTap: () => _openProduct(product),
                ),
              );
            },
          );
        },
      ),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 34,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
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