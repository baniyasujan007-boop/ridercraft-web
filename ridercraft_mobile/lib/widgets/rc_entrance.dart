import 'package:flutter/material.dart';

/// Coherent one-shot entrance animation: fade in with a subtle fixed upward
/// translation (320 ms, `Curves.easeOutCubic`). Used for page sections and
/// cards so content never pops in. Respects the platform reduced-motion
/// preference by rendering the child without animation when disabled.
class RcEntrance extends StatefulWidget {
  final Widget child;

  /// Fixed vertical (pixels) the content slides up from.
  final double offset;

  const RcEntrance({super.key, required this.child, this.offset = 18});

  @override
  State<RcEntrance> createState() => _RcEntranceState();
}

class _RcEntranceState extends State<RcEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _translate = Tween<double>(begin: widget.offset, end: 0).animate(curve);
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
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _translate,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _translate.value),
          child: child,
        ),
      ),
    );
  }
}
