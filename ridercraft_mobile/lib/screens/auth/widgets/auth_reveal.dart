import 'package:flutter/material.dart';

/// One-shot staggered entrance for the auth screens.
///
/// Fades each [children] element in and slides it up, staggering the start of
/// each element slightly so the form feels choreographed rather than loud.
/// A single driving controller means no lingering timers (widget-test safe)
/// and honours the platform reduced-motion preference.
class AuthReveal extends StatefulWidget {
  final List<Widget> children;

  const AuthReveal({super.key, required this.children});

  @override
  State<AuthReveal> createState() => _AuthRevealState();
}

class _AuthRevealState extends State<AuthReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) _reveal(i, count, widget.children[i]),
      ],
    );
  }

  Widget _reveal(int index, int count, Widget child) {
    final start = index * 0.09;
    final end = (start + 0.55).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}