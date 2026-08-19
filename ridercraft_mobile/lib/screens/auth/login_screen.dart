import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/home_router.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../theme/app_colors.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_feedback.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_reveal.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/google_button.dart';

/// Premium RiderCraft sign-in: brand moment, email + password with the
/// existing validation rules, the existing Google Sign-In flow and clear
/// loading / error states. Authentication logic is untouched.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    try {
      await auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        homeRouteFor(auth.user!),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showAuthSnack(
        context,
        message: authErrorMessage(
          error,
          fallback: 'Unable to sign in. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);

    final auth = context.read<AuthProvider>();
    try {
      final signedIn = await auth.loginWithGoogle();
      if (!mounted) return;
      if (signedIn) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          homeRouteFor(auth.user!),
          (route) => false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      // SAFE diagnostic only: surfaces non-ApiException failures (e.g. a
      // platform-layer error) so the Google layer can be triaged on-device.
      if (error is! ApiException) {
        debugPrint('google-auth: login_screen non-ApiException $error');
      }
      showAuthSnack(
        context,
        message: error is ApiException
            ? error.message
            : 'Google sign-in failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).pushNamed(RouteNames.forgotPassword);
  }

  void _openRegister() {
    Navigator.of(context).pushNamed(RouteNames.register);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AuthReveal(
        children: [
          const Center(child: AuthBrand(size: 72)),
          const SizedBox(height: 24),
          const AuthHeader(
            kicker: 'WELCOME BACK',
            title: 'Ready for your next ride?',
            subtitle: 'Book services, shop parts and track your rides.',
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AuthField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: _submitting ? null : _submit,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: _openForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AuthSubmitButton(
                  label: 'Sign In',
                  loadingLabel: 'Signing you in...',
                  icon: Icons.arrow_forward_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AuthOrDivider(),
          const SizedBox(height: 16),
          GoogleButton(
            loading: _googleLoading,
            onPressed: _submitting ? null : _googleSignIn,
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New to RiderCraft? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _openRegister,
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}