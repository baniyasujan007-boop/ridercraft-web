import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

/// Brand splash. Restores the saved session and routes the user to Home
/// (authenticated) or Login (not authenticated).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp =
        Tween<double>(begin: 0.06, end: 0).animate(_controller);
    _controller.forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();

    if (!mounted) return;

    final destination = auth.isAuthenticated
        ? RouteNames.main
        : RouteNames.login;

    Navigator.of(context).pushNamedAndRemoveUntil(
      destination,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E141C), AppColors.background],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(_slideUp),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(fontSize: 36),
                  SizedBox(height: 32),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
