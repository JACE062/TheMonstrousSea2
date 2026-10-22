import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';

/// Button with vintage typography, double borders, and brass/crimson variants.
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.subtitle,
    this.subtitleColor,
    this.isDanger = false,
    this.isPrimary = false,
    this.compact = false,
    this.width,
    this.semanticLabel,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final String? subtitle;
  final Color? subtitleColor;
  final bool isDanger;
  final bool isPrimary;

  /// Smaller secondary actions in headers and overlays, using the same styling.
  final bool compact;
  final double? width;
  final String? semanticLabel;
  final String? semanticHint;

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

    final buttonContent = ConstrainedBox(
      constraints: BoxConstraints(minWidth: 48, minHeight: compact ? 36 : 48),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 10,
        ),
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
              ExcludeSemantics(
                child: Opacity(opacity: isEnabled ? 1.0 : 0.45, child: icon!),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: InkTheme.titleMedium.copyWith(
                      fontSize: compact || subtitle != null ? 16 : 18,
                      color: textColor,
                      decoration: !isEnabled ? TextDecoration.none : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: InkTheme.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !isEnabled
                            ? InkTheme.inkFaint
                            : subtitleColor ?? InkTheme.goldAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final button = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      hint: semanticHint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: isEnabled
              ? buttonContent
              : Opacity(opacity: 0.6, child: buttonContent),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
