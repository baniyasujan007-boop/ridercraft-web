import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import 'order_status_style.dart';

/// Reusable order-status timeline for the four backend-supported states:
/// placed → processing → shipped → delivered.
///
/// Completed steps are shown as success checks, the current step is the
/// highlighted primary accent (with a one-shot pulse on first appearance and
/// whenever [status] changes), and future steps stay muted. The step labels
/// under each node keep the meaning readable even without color.
class OrderStatusTimeline extends StatefulWidget {
  /// Backend order status value (`placed`, `processing`, `shipped`,
  /// `delivered`). Unknown values render as the first (placed) step.
  final String status;

  const OrderStatusTimeline({super.key, required this.status});

  @override
  State<OrderStatusTimeline> createState() => _OrderStatusTimelineState();
}

class _OrderStatusTimelineState extends State<OrderStatusTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

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
  void didUpdateWidget(OrderStatusTimeline oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final steps = OrderStatusStyle.steps;
    final currentIndex = OrderStatusStyle.stepIndex(widget.status);
    final label = OrderStatusStyle.stepLabel(widget.status);
    const double nodeSize = 26;
    const double bandHeight = 30;

    final iconNodes = List<Widget>.generate(steps.length, (index) {
      final isComplete = index < currentIndex;
      final isCurrent = index == currentIndex;

      return Expanded(
        child: SizedBox(
          height: bandHeight,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = isCurrent ? 0.7 + (0.3 * _pulse.value) : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: _StepNode(
                isComplete: isComplete,
                isCurrent: isCurrent,
                icon: OrderStatusStyle.statusIcon(steps[index]),
                size: nodeSize,
              ),
            ),
          ),
        ),
      );
    });

    final labels = List<Widget>.generate(steps.length, (index) {
      final isComplete = index < currentIndex;
      final isCurrent = index == currentIndex;
      return Expanded(
        child: Semantics(
          label: '${OrderStatusStyle.stepLabels[index]} status',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                OrderStatusStyle.stepLabels[index],
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
    });

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
      label: 'Order status: $label. '
          '${OrderStatusStyle.stepLabels.join(', ')}.',
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.45, curve: Curves.easeOut),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: bandHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: line),
                  Row(children: iconNodes),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: labels),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  OrderStatusStyle.statusIcon(widget.status),
                  size: 16,
                  color: OrderStatusStyle.statusColor(widget.status),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Current status: $label',
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
class _StepNode extends StatelessWidget {
  final bool isComplete;
  final bool isCurrent;
  final IconData icon;
  final double size;

  const _StepNode({
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