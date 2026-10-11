import 'package:flutter/material.dart';
import '../theme/ink_theme.dart';
import 'painters/cartouche_border_painter.dart';
import 'painters/parchment_texture_painter.dart';

/// Standard page container framing children with aged parchment texture and cartouche borders.
class ParchmentScaffold extends StatelessWidget {
  const ParchmentScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showBorder = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InkTheme.parchmentBackground,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Texture & edge vignette
          const CustomPaint(painter: ParchmentTexturePainter()),
          // Outer border flourish
          if (showBorder)
            const IgnorePointer(
              child: CustomPaint(painter: CartoucheBorderPainter()),
            ),
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(showBorder ? 16.0 : 0.0),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
