import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hero_offer.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/product_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import 'home_skeleton.dart';
import 'widgets/featured_section.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/promo_card.dart';
import 'widgets/quick_actions.dart';

/// Premium RiderCraft dashboard: hero offers, quick actions, featured
/// sections and active promotions from the production API.
class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Load once in the provider; the UI reacts to its state.
    context.read<HomeProvider>().load();
    if (context.read<AuthProvider>().isAuthenticated) {
      context.read<ProductProvider>().loadWishlist();
    }
  }

  Future<void> _refresh() async {
    final homeProvider = context.read<HomeProvider>();
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    await homeProvider.refresh();
    if (authProvider.isAuthenticated) {
      await productProvider.loadWishlist();
    }
  }

  void _openTab(int index) => widget.onNavigateTab(index);

  void _openProduct(Product product) {
    Navigator.of(context).pushNamed(
      RouteNames.productDetail,
      arguments: product,
    );
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 12),
        _buildHeroSection(home),
        const SizedBox(height: 20),
        QuickActions(onNavigateTab: widget.onNavigateTab),
        const SizedBox(height: 28),
        ..._buildFeaturedSections(home),
        ..._buildPromosSection(home),
      ],
    );
  }

  // --- Hero ---
  Widget _buildHeroSection(HomeProvider home) {
    if (home.loadingHero && home.heroOffers.isEmpty) {
      return const _SectionLoading(height: 200);
    }
    if (home.heroError != null) {
      return _InlineError(
        message: 'Hero unavailable',
        onRetry: home.retryHero,
      );
    }
    return HeroCarousel(
      offers: home.heroOffers,
      onOfferCta: _handleHeroCta,
      onDefaultCta: () => _openTab(1),
    );
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
      return const [_EmptySection(message: 'No featured products available right now.')];
    }

    return [
      for (final section in home.featuredSections)
        FeaturedSectionView(
          section: section,
          onProductTap: _openProduct,
          onSeeAll: () => _openTab(2),
        ),
    ];
  }

  // --- Promotions ---
  List<Widget> _buildPromosSection(HomeProvider home) {
    if (home.promoError != null) {
      return [
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
      const SizedBox(height: 28),
      const SectionHeader(title: 'Offers & Deals', kicker: 'Deals'),
      const SizedBox(height: 12),
      for (final promo in home.activePromos)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: PromoCard(
            promo: promo,
            onShopNow: () => _openTab(2),
          ),
        ),
    ];
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ErrorView(message: message, onRetry: onRetry),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
