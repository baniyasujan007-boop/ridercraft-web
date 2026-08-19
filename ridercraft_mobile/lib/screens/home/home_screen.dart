import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hero_offer.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bike_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/route_names.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/error_view.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/rc_entrance.dart';
import '../../widgets/rc_image.dart';
import '../../widgets/rc_search_bar.dart';
import '../../widgets/section_header.dart';
import 'home_skeleton.dart';
import 'widgets/category_chips.dart';
import 'widgets/featured_section.dart';
import 'widgets/garage_card.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/promo_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_orders_card.dart';
import 'widgets/services_preview.dart';

/// Premium RiderCraft dashboard: greeting, search, the rider's garage, hero
/// offers, quick actions, live categories, featured sections, service
/// previews, active promotions and the most recent order — all fed by the
/// production APIs.
class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _started = false;
  String _searchQuery = '';
  List<Order> _recentOrders = [];
  bool _recentOrdersLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Load once in the provider; the UI reacts to its state. Deferred past the
    // first frame: product/booking loads notify listeners synchronously, and
    // notifying them during the build phase throws
    // "setState() or markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().load();
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<ProductProvider>().loadWishlist();
        _loadRecentOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasProvider<T extends Object>(BuildContext context) {
    try {
      Provider.of<T>(context, listen: false);
      return true;
    } on ProviderNotFoundException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadRecentOrders({bool force = false}) async {
    if (!force && _recentOrdersLoaded) return;
    _recentOrdersLoaded = true;
    if (!context.read<AuthProvider>().isAuthenticated) return;
    OrderService? service;
    try {
      service = Provider.of<OrderService>(context, listen: false);
    } on ProviderNotFoundException {
      service = null;
    } catch (_) {
      service = null;
    }
    if (service == null) return;
    try {
      final orders = await service.listMyOrders();
      if (!mounted) return;
      setState(() => _recentOrders = orders.take(3).toList());
    } catch (_) {
      // Optional enhancement: keep Home stable if orders fail to load.
    }
  }

  Future<void> _refresh() async {
    final homeProvider = context.read<HomeProvider>();
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    await homeProvider.refresh();
    if (authProvider.isAuthenticated) {
      await productProvider.loadWishlist();
      await _loadRecentOrders(force: true);
    }
  }

  Future<void> _ensureProducts() async {
    final provider = context.read<ProductProvider>();
    if (provider.products.isEmpty && !provider.loadingProducts) {
      await provider.loadProducts();
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (value.trim().isNotEmpty) _ensureProducts();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _openTab(int index) => widget.onNavigateTab(index);

  void _openProduct(Product product) {
    Navigator.of(
      context,
    ).pushNamed(RouteNames.productDetail, arguments: product);
  }

  void _handleHeroCta(HeroOffer offer) {
    // The API does not return a destination; route by offer type.
    if (offer.offerType == 'flash') {
      _openTab(2); // Flash sales → Shop
    } else {
      _openTab(1); // Service offers → Services
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      appBar: HomeAppBar(
        onNotificationsTap: () =>
            Navigator.of(context).pushNamed(RouteNames.notifications),
        onProfileTap: () => _openTab(4),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: home.loadedOnce ? _buildContent(home) : const HomeSkeleton(),
      ),
    );
  }

  Widget _buildContent(HomeProvider home) {
    final searching = _searchQuery.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RcEntrance(child: searching ? _searchBar() : _greetingHeader()),
          if (searching)
            ..._buildSearchResults()
          else ...[
            const SizedBox(height: AppSpacing.md),
            RcEntrance(child: _searchBar()),
            const SizedBox(height: AppSpacing.sm),
            if (_hasProvider<BikeProvider>(context)) ...[
              RcEntrance(child: _garageSection()),
              const SizedBox(height: AppSpacing.xl),
            ],
            RcEntrance(child: _buildHeroSection(home)),
            const SizedBox(height: AppSpacing.xl),
            RcEntrance(
              child: QuickActions(onNavigateTab: widget.onNavigateTab),
            ),
            const SizedBox(height: AppSpacing.xl),
            ..._buildCategoriesSection(home),
            ..._buildFeaturedSections(home),
            const SizedBox(height: AppSpacing.lg),
            RcEntrance(
              child: ServicesPreview(onServicesTap: () => _openTab(1)),
            ),
            ..._buildPromosSection(home),
            if (_recentOrders.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              RcEntrance(
                child: RecentOrdersCard(
                  order: _recentOrders.first,
                  onViewOrders: () =>
                      Navigator.of(context).pushNamed(RouteNames.orders),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // --- Greeting & search ---
  Widget _greetingHeader() {
    final user = context.select<AuthProvider, User?>(
      (provider) => provider.user,
    );
    final name = (user?.name ?? '').trim();
    final firstName = name.isEmpty ? 'Rider' : name.split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RIDERCRAFT',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$part, $firstName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: RcSearchBar(
        controller: _searchController,
        onChanged: _onSearchChanged,
      ),
    );
  }

  // --- Search results ---
  List<Widget> _buildSearchResults() {
    final provider = context.watch<ProductProvider>();

    if (provider.products.isEmpty && provider.loadingProducts) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _SectionLoading(height: 132),
        ),
      ];
    }
    if (provider.products.isEmpty && provider.error != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _InlineError(
            message: 'Unable to search products',
            onRetry: _ensureProducts,
          ),
        ),
      ];
    }

    final results = provider.search(_searchQuery);
    if (results.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _EmptySection(
            message:
                'No products match "$_searchQuery". Try a bike model, brand or part.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: _clearSearch,
            child: const Text('Clear search'),
          ),
        ),
      ];
    }

    return [
      const SizedBox(height: AppSpacing.md),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SectionHeader(title: 'Search results', showDivider: false),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final product in results)
        _SearchResultTile(product: product, onTap: () => _openProduct(product)),
    ];
  }

  // --- Garage ---
  Widget _garageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Builder(
        builder: (context) {
          final bike = context.watch<BikeProvider>().selectedBike;
          return GarageCard(bike: bike);
        },
      ),
    );
  }

  // --- Hero ---
  Widget _buildHeroSection(HomeProvider home) {
    if (home.loadingHero && home.heroOffers.isEmpty) {
      return const _SectionLoading(height: 200);
    }
    if (home.heroError != null) {
      return _InlineError(message: 'Hero unavailable', onRetry: home.retryHero);
    }
    return HeroCarousel(
      offers: home.heroOffers,
      onOfferCta: _handleHeroCta,
      onDefaultCta: () => _openTab(1),
    );
  }

  // --- Categories ---
  List<Widget> _buildCategoriesSection(HomeProvider home) {
    final productProvider = context.watch<ProductProvider>();
    final tags = <String>{};
    for (final section in home.featuredSections) {
      for (final product in section.products) {
        if (product.tag.trim().isNotEmpty) tags.add(product.tag.trim());
      }
    }
    for (final product in productProvider.products) {
      if (product.tag.trim().isNotEmpty) tags.add(product.tag.trim());
    }
    if (tags.isEmpty) return const [];

    final sorted = tags.toList()..sort();
    return [
      RcEntrance(
        child: CategoryChips(tags: sorted, onCategoryTap: () => _openTab(2)),
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // --- Featured sections ---
  List<Widget> _buildFeaturedSections(HomeProvider home) {
    if (home.loadingFeatured && home.featuredSections.isEmpty) {
      return const [
        _SectionHeader(title: 'Featured Products'),
        SizedBox(height: 12),
        _SectionLoading(height: 252),
      ];
    }
    if (home.featuredError != null) {
      return [
        _InlineError(
          message: 'Unable to load featured products',
          onRetry: home.retryFeatured,
        ),
      ];
    }
    if (home.featuredSections.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _EmptySection(
            message: 'No featured products available right now.',
          ),
        ),
      ];
    }

    return [
      for (final section in home.featuredSections)
        RcEntrance(
          child: FeaturedSectionView(
            section: section,
            onProductTap: _openProduct,
            onSeeAll: () => _openTab(2),
          ),
        ),
    ];
  }

  // --- Promotions ---
  List<Widget> _buildPromosSection(HomeProvider home) {
    if (home.promoError != null) {
      return [
        const SizedBox(height: AppSpacing.lg),
        _InlineError(
          message: 'Unable to load offers',
          onRetry: home.retryPromos,
        ),
      ];
    }
    if (home.activePromos.isEmpty) {
      // Collapse the section when the API has no active promos.
      return const [];
    }

    return [
      const SizedBox(height: AppSpacing.xl),
      const SectionHeader(title: 'Offers & Deals', kicker: 'Deals'),
      const SizedBox(height: AppSpacing.sm),
      for (final promo in home.activePromos)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 6,
          ),
          child: PromoCard(promo: promo, onShopNow: () => _openTab(2)),
        ),
    ];
  }
}

class _SearchResultTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _SearchResultTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: PressScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: RcImage(product.image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                Formatters.inr(product.price),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title);
  }
}

class _SectionLoading extends StatelessWidget {
  final double height;
  const _SectionLoading({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ErrorView(message: message, onRetry: onRetry),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
