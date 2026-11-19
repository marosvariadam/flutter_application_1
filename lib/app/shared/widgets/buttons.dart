import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/design/dt_text.dart';

/// Filled accent button: 52 px tall, full width by default, with a small
/// spinner while [isLoading] (taps are ignored, the color stays) and a light
/// haptic tap.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Full width when true; sized to its label otherwise.
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    return _ButtonFrame(
      expand: expand,
      child: ElevatedButton(
        onPressed: _tapHandler(onPressed, isLoading),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentPrimary,
          foregroundColor: c.textOnAccent,
          disabledBackgroundColor: isLoading ? c.accentPrimary : c.borderGrey,
          disabledForegroundColor: isLoading ? c.textOnAccent : c.textSecondary,
          elevation: 0,
          textStyle: _labelStyle(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.rCardSmall)),
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: c.textOnAccent,
        ),
      ),
    );
  }
}

/// Outlined accent button with the same metrics as [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = DT.of(context);
    final enabled = onPressed != null || isLoading;
    return _ButtonFrame(
      expand: expand,
      child: OutlinedButton(
        onPressed: _tapHandler(onPressed, isLoading),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accentPrimary,
          disabledForegroundColor:
              isLoading ? c.accentPrimary : c.textSecondary,
          side: BorderSide(color: enabled ? c.accentPrimary : c.borderGrey),
          textStyle: _labelStyle(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.rCardSmall)),
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: c.accentPrimary,
        ),
      ),
    );
  }
}

VoidCallback? _tapHandler(VoidCallback? onPressed, bool isLoading) {
  if (onPressed == null || isLoading) return null;
  return () {
    HapticFeedback.lightImpact();
    onPressed();
  };
}

TextStyle _labelStyle(BuildContext context) {
  final title = DTText.of(context).title;
  // Color comes from the button's foreground; only size and weight here.
  return TextStyle(fontSize: title.fontSize, fontWeight: title.fontWeight);
}

class _ButtonFrame extends StatelessWidget {
  final bool expand;
  final Widget child;
  const _ButtonFrame({required this.expand, required this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: expand ? double.infinity : null,
        height: 52,
        child: child,
      );
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color spinnerColor;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.spinnerColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Semantics(
        label: '$label, folyamatban',
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
        ),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: DT.s2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
