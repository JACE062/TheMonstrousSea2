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
    final borderColor = isDanger
        ? InkTheme.crimsonAccent
        : isPrimary
            ? InkTheme.goldAccent
            : InkTheme.inkPrimary;

    final textColor = isDanger ? InkTheme.crimsonAccent : InkTheme.inkPrimary;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: InkTheme.parchmentSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: isPrimary ? 2.0 : 1.5),
            boxShadow: [
              BoxShadow(
                color: InkTheme.inkPrimary.withValues(alpha: 0.1),
                offset: const Offset(1, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: InkTheme.titleMedium.copyWith(
                    fontSize: 18,
                    color: onPressed != null ? textColor : InkTheme.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
