import 'package:flutter/material.dart';

import '../../../models/hero_offer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/press_scale.dart';

/// Horizontally swipeable hero carousel fed by `GET /hero-offers`.
///
/// Premium RiderCraft hero: dark neutral gradient with a red radial glow,
/// uppercase red badge, scale-fitted headline and a RiderCraft Red CTA.
/// When the API returns no offers a branded fallback is shown.
///
/// The hero height scales with the screen width and the device text scaler,
/// and the copy is scale-fitted so longer titles never overflow the card.
class HeroCarousel extends StatefulWidget {
  final List<HeroOffer> offers;
  final ValueChanged<HeroOffer> onOfferCta;
  final VoidCallback onDefaultCta;

  const HeroCarousel({
    super.key,
    required this.offers,
    required this.onOfferCta,
    required this.onDefaultCta,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Hero height grows with viewport width (roughly the website's aspect)
  /// and the text scaler, clamped to a sane range.
  double _heroHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.75);
    return ((width - 32) * 0.62 * textScale).clamp(170.0, 400.0);
  }

  @override
  Widget build(BuildContext context) {
    final offers = widget.offers;
    final height = _heroHeight(context);

    if (offers.isEmpty) {
      return _BrandedHero(
        onCta: widget.onDefaultCta,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: offers.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _OfferHeroCard(
                  offer: offer,
                  onCta: () => widget.onOfferCta(offer),
                ),
              );
            },
          ),
        ),
        if (offers.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(offers.length, (index) {
              final active = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Hero card for an API offer. Uses only server-provided fields: title,
/// offerType, endsAt/remainingSeconds and ctaQuery.
class _OfferHeroCard extends StatelessWidget {
  final HeroOffer offer;
  final VoidCallback onCta;

  const _OfferHeroCard({required this.offer, required this.onCta});

  @override
  Widget build(BuildContext context) {
    final isFlash = offer.offerType == 'flash';
    final badge = isFlash ? 'FLASH SALE' : 'LIMITED TIME';
    final ctaLabel = isFlash ? 'Shop Now' : 'Book Service';

    return _HeroShell(
      isFlash: isFlash,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBadge(label: badge, flash: isFlash),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (offer.ctaQuery.isNotEmpty ||
                            offer.remainingSeconds > 0) ...[
                          const SizedBox(height: 6),
                          if (offer.ctaQuery.isNotEmpty)
                            Text(
                              offer.ctaQuery,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            )
                          else
                            Text(
                              'Ends in ${Formatters.remainingDuration(offer.remainingSeconds)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _HeroCta(label: ctaLabel, onTap: onCta),
        ],
      ),
    );
  }
}

/// Branded fallback shown when the API returns no hero offers. The headline
/// stays exactly "Premium motorcycle gear for every rider." as the branded
/// promise.
class _BrandedHero extends StatelessWidget {
  final VoidCallback onCta;
  final double height;
  final EdgeInsetsGeometry margin;

  const _BrandedHero({
    required this.onCta,
    required this.height,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SizedBox(
        height: height,
        child: _HeroShell(
          isFlash: false,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(label: 'RIDERCRAFT', flash: false),
              const SizedBox(height: 10),
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: constraints.maxWidth),
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Premium motorcycle gear\n',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'for every rider.',
                                style: TextStyle(color: AppColors.primaryLight),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: constraints.maxWidth),
                        child: const _TrustRow(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _HeroCta(label: 'Book Service', onTap: onCta),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trust row lifted from the website hero (`✓` list under the CTA).
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const items = ['Free delivery', '1-year warranty', 'Easy returns'];
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                item,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Shared hero card shell: dark neutral gradient with a RiderCraft Red radial
/// glow and a motorcycle watermark.
class _HeroShell extends StatelessWidget {
  final bool isFlash;
  final Widget content;

  const _HeroShell({required this.isFlash, required this.content});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.985, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: PressScale(
        onTap: null,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14171C), Color(0xFF0D0F12)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadow.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.hero),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  left: -50,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isFlash
                            ? const [Color(0x40FF2B32), Color(0x00FF2B32)]
                            : AppColors.heroGlowColors,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -28,
                  bottom: -34,
                  child: Icon(
                    Icons.sports_motorsports_rounded,
                    size: 150,
                    color: isFlash
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final bool flash;

  const _HeroBadge({required this.label, required this.flash});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: flash ? 0.20 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeroCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: AppShadow.redGlow,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}