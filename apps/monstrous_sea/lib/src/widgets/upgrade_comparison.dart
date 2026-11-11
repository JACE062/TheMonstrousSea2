import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';

class UpgradeStatComparison extends StatelessWidget {
  const UpgradeStatComparison({
    super.key,
    required this.valueKey,
    required this.label,
    required this.current,
    required this.next,
  });
  final Key valueKey;
  final String label;
  final String current;
  final String? next;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      label: '$label: $current${next == null ? '' : ' to $next'}',
      excludeSemantics: true,
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$label:', style: InkTheme.body),
          UpgradeValueComparison(
            key: valueKey,
            current: current,
            next: next,
            style: InkTheme.bodyBold,
          ),
        ],
      ),
    ),
  );
}

/// Draw arrows as icons: the atmospheric fonts do not contain that glyph.
class UpgradeValueComparison extends StatelessWidget {
  const UpgradeValueComparison({
    super.key,
    required this.current,
    required this.next,
    required this.style,
  });
  final String current;
  final String? next;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Wrap(
    runSpacing: 2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(current, style: style),
      if (next != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_right_alt,
                size: 20,
                color: InkTheme.inkMuted,
              ),
            ),
            Text(next!, style: style.copyWith(color: InkTheme.goldAccent)),
          ],
        ),
    ],
  );
}
