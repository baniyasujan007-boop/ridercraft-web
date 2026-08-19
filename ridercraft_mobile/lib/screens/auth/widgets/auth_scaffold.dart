import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/rc_icon_button.dart';

/// Premium background shell for the authentication screens: dark graphite
/// gradient, a very subtle RiderCraft Red ambient glow at the top, an optional
/// pinned back button and a content column constrained to a comfortable
/// reading width on larger screens.
///
/// Handles keyboard insets and text scaling through a scroll view so auth
/// screens never overflow at 320px or 2.0x text.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool showBack;

  const AuthScaffold({super.key, required this.child, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _backdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    if (showBack) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: RcIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          showBack ? 16 : 48,
                          24,
                          24,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backdrop() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10151C), AppColors.background],
        ),
      ),
      child: DecoratedBox(
        position: DecorationPosition.background,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.95),
            radius: 1.1,
            colors: [Color(0x38E31B23), Color(0x0008090B)],
          ),
        ),
      ),
    );
  }
}