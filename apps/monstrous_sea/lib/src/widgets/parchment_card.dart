import 'package:flutter/material.dart';
import '../theme/ink_theme.dart';

/// Distinctive card panel styled like an aged document or chart cutout.
class ParchmentCard extends StatelessWidget {
  const ParchmentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderColor = InkTheme.inkMuted,
    this.backgroundColor = InkTheme.parchmentSurface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: InkTheme.inkPrimary.withValues(alpha: 0.08),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}
