import 'package:flutter/material.dart';
import '../theme/ink_theme.dart';

/// Button with vintage typography, double borders, and brass/crimson variants.
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDanger = false,
    this.isPrimary = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isDanger;
  final bool isPrimary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    final borderColor = !isEnabled
        ? InkTheme.inkFaint
        : isDanger
            ? InkTheme.crimsonAccent
            : isPrimary
                ? InkTheme.goldAccent
                : InkTheme.inkPrimary;

    final textColor = !isEnabled
        ? InkTheme.inkFaint
        : isDanger
            ? InkTheme.crimsonAccent
            : InkTheme.inkPrimary;

    final buttonContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isEnabled
            ? InkTheme.parchmentSurface
            : InkTheme.parchmentDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: isEnabled && isPrimary ? 2.0 : 1.2,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: InkTheme.inkPrimary.withValues(alpha: 0.1),
                  offset: const Offset(1, 2),
                  blurRadius: 2,
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Opacity(
              opacity: isEnabled ? 1.0 : 0.45,
              child: icon!,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: InkTheme.titleMedium.copyWith(
                fontSize: 18,
                color: textColor,
                decoration: !isEnabled ? TextDecoration.none : null,
              ),
            ),
          ),
        ],
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: isEnabled
            ? buttonContent
            : Opacity(opacity: 0.6, child: buttonContent),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
