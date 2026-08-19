import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_feedback.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_reveal.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_submit_button.dart';

/// Premium password reset: takes the existing flow and wraps it in the new
/// brand aesthetic with a safe loading / success / error rhythm.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    try {
      await auth.forgotPassword(email: _emailController.text);
      if (!mounted) return;
      showAuthSnack(
        context,
        isError: false,
        message: 'Reset link sent to your email',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      showAuthSnack(
        context,
        message: authErrorMessage(
          error,
          fallback: 'Unable to send reset link. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      child: AuthReveal(
        children: [
          const AuthHeader(
            kicker: 'RESET PASSWORD',
            title: 'Trouble getting in?',
            subtitle: 'Enter your email and we\'ll send you a reset link.',
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: _submitting ? null : _submit,
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
                const SizedBox(height: 24),
                AuthSubmitButton(
                  label: 'Send Reset Link',
                  loadingLabel: 'Sending...',
                  icon: Icons.send_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}