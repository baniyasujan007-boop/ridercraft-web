import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

/// Premium RiderCraft form input for the auth screens.
///
/// Dark elevated surface, a RiderCraft Red border and a soft red glow on
/// focus, floating label, password visibility toggle and a clear error state.
/// Validation stays with the enclosing [Form] so the screens keep the exact
/// backend-facing rules.
class AuthField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool isPassword;
  final bool enabled;
  final bool autocorrect;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;
  final List<String>? autofillHints;

  const AuthField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.enabled = true,
    this.autocorrect = true,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final FocusNode _focusNode = FocusNode();
  bool _obscured = true;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  OutlineInputBorder _outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.large),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefixColor = _focused ? AppColors.primary : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: _focused
            ? const [
                BoxShadow(
                  color: Color(0x2EE31B23),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.isPassword && _obscured,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.autocorrect,
        autofillHints: widget.autofillHints,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onFieldSubmitted: (_) => widget.onSubmitted?.call(),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: prefixColor)
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
          labelStyle: TextStyle(
            color: _focused ? AppColors.primary : AppColors.textSecondary,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
          border: _outline(AppColors.border),
          enabledBorder: _outline(AppColors.border),
          focusedBorder: _outline(AppColors.primary, width: 1.5),
          errorBorder: _outline(AppColors.error),
          focusedErrorBorder: _outline(AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}