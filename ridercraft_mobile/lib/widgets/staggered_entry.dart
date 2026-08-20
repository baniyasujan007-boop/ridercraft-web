import 'package:flutter/material.dart';

/// Subtle list entrance: fade + gentle upward slide, staggered by [index]
/// across [parent]. When the parent controller has finished (animations
/// disabled), every row is fully visible so nothing disappears forever.
class StaggeredEntry extends StatelessWidget {
  final Animation<double> parent;
  final int index;
  final Widget child;

  const StaggeredEntry({
    super.key,
    required this.parent,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (parent.isCompleted) return child;

    final start = (index * 0.06).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: parent,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}