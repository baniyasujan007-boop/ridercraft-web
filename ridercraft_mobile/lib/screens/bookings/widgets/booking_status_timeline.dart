import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

/// Reusable booking status timeline for the four backend-supported states:
/// requested → confirmed → in_progress → completed.
///
/// Completed steps are shown as success checks, the current step is the
/// highlighted primary accent (with a one-shot pulse on first appearance and
/// whenever [status] changes), and future steps stay muted. The step labels
/// under each node keep the meaning readable even without color.
class BookingStatusTimeline extends StatefulWidget {
  /// Backend booking status value (requested, confirmed, in_progress,
  /// completed, cancelled). Unknown values render as the first (requested) step.
  final String status;

  const BookingStatusTimeline({super.key, required this.status});

  @override
  State<BookingStatusTimeline> createState() => _BookingStatusTimelineState();
}

class _BookingStatusTimelineState extends State<BookingStatusTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  static const List<String> steps = ['requested', 'confirmed', 'in_progress', 'completed'];
  static const List<String> stepLabels = ['Requested', 'Confirmed', 'In Progress', 'Completed'];
  static const List<IconData> stepIcons = [
    Icons.event_available_rounded,
    Icons.check_circle_outline_rounded,
    Icons.build_rounded,
    Icons.verified_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BookingStatusTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get currentIndex {
    final idx = steps.indexOf(widget.status);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    const double nodeSize = 26;
    const double bandHeight = 28;

    // Build node row
    final nodeRow = Row(
      children: List<Widget>.generate(steps.length, (index) {
        final isComplete = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: SizedBox(
            height: bandHeight,
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final scale = isCurrent
                      ? 0.7 + (0.3 * _pulse.value)
                      : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: _TimelineNode(
                  isComplete: isComplete,
                  isCurrent: isCurrent,
                  icon: stepIcons[index],
                  size: nodeSize,
                ),
              ),
            ),
          ),
        );
      }),
    );

    // Build label row
    final labelRow = Row(
      children: List<Widget>.generate(steps.length, (index) {
        final isComplete = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Semantics(
              label: '${stepLabels[index]} status',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stepLabels[index],
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isCurrent
                        ? FontWeight.w800
                        : (isComplete ? FontWeight.w600 : FontWeight.w500),
                    color: isCurrent
                        ? AppColors.textPrimary
                        : (isComplete
                            ? AppColors.textSecondary
                            : AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );

    // Build progress line
    final line = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final start = nodeSize / 2;
        final end = width - nodeSize / 2;
        final fraction = steps.length <= 1
            ? 1.0
            : (currentIndex / (steps.length - 1)).clamp(0.0, 1.0);
        return Stack(
          children: [
            // Base track.
            Positioned(
              left: start,
              right: nodeSize / 2,
              top: bandHeight / 2 - 1.5,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
              ),
            ),
            // Completed segment in success green.
            Positioned(
              left: start,
              top: bandHeight / 2 - 1.5,
              width: (end - start) * fraction,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      image: false,
      label:
          'Booking status: ${stepLabels[currentIndex]}. ${stepLabels.join(', ')}.',
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.45, curve: Curves.easeOut),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node row with progress line
            SizedBox(
              height: bandHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: line),
                  nodeRow,
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Label row
            labelRow,
            const SizedBox(height: AppSpacing.sm),
            // Current status text
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  stepIcons[currentIndex],
                  size: 16,
                  color: currentIndex == 3
                      ? AppColors.success
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Current status: ${stepLabels[currentIndex]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single circular timeline node.
class _TimelineNode extends StatelessWidget {
  final bool isComplete;
  final bool isCurrent;
  final IconData icon;
  final double size;

  const _TimelineNode({
    required this.isComplete,
    required this.isCurrent,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    }

    if (isCurrent) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textMuted, size: 15),
    );
  }
}