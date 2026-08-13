import 'package:flutter/material.dart';

import '../../../models/hero_offer.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/press_scale.dart';

/// Horizontally swipeable hero carousel fed by `GET /hero-offers`.
///
/// Styled like the website's `.ridercraft-hero`: dark navy base with an
/// orange radial glow, italic uppercase headline and a gradient CTA.
/// When the API returns no offers a branded fallback hero is shown.
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
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(offers.length, (index) {
              final active = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
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
          _HeroBadge(label: badge),
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
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            height: 1.1,
                            letterSpacing: 0.3,
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
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            )
                          else
                            Text(
                              'Ends in ${Formatters.remainingDuration(offer.remainingSeconds)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
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

/// Branded fallback shown when the API returns no hero offers.
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
              const _HeroBadge(label: 'RIDERCRAFT'),
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
                                style: TextStyle(color: Color(0xFFFF7A1A)),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            height: 1.12,
                            letterSpacing: 0.3,
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
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFFFF7A1A)),
              const SizedBox(width: 4),
              Text(
                item,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Shared hero card shell: dark navy gradient with an orange radial glow and
/// a motorcycle watermark, like the website hero section.
class _HeroShell extends StatelessWidget {
  final bool isFlash;
  final Widget content;

  const _HeroShell({required this.isFlash, required this.content});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: null,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1119), Color(0xFF0E1A2B)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Orange radial glow (top center, like the website hero).
              Positioned(
                top: -60,
                left: -40,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isFlash
                          ? const [Color(0x4DFF4D00), Color(0x00FF4D00)]
                          : AppColors.heroGlowColors,
                    ),
                  ),
                ),
              ),
              if (isFlash)
                Positioned(
                  right: -30,
                  top: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -24,
                bottom: -28,
                child: Icon(
                  Icons.sports_motorsports_rounded,
                  size: 130,
                  color: isFlash
                      ? Colors.white.withValues(alpha: 0.10)
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
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFFF8A22),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.2,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6A00), Color(0xFFF0440B)],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x47FF5B00),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
