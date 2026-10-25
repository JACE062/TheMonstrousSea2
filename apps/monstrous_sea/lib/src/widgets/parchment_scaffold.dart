import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'pause_menu.dart';
import 'painters/cartouche_border_painter.dart';
import 'painters/parchment_texture_painter.dart';

/// Adds shell controls to the next page's frame, including across navigator routes.
/// Hosts compose their headers here instead of placing UI outside the cartouche.
class ParchmentHeaderScope extends StatelessWidget {
  const ParchmentHeaderScope({
    super.key,
    required this.header,
    required this.child,
  });

  final Widget header;
  final Widget child;

  static List<Widget> headersOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ParchmentHeaders>()
          ?.headers ??
      const [];

  @override
  Widget build(BuildContext context) =>
      _ParchmentHeaders(headers: [...headersOf(context), header], child: child);
}

class _ParchmentHeaders extends InheritedWidget {
  const _ParchmentHeaders({required this.headers, required super.child});
  final List<Widget> headers;

  @override
  bool updateShouldNotify(_ParchmentHeaders oldWidget) =>
      headers != oldWidget.headers;
}

/// Standard page container framing children with aged parchment texture and cartouche borders.
class ParchmentScaffold extends StatelessWidget {
  const ParchmentScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showBorder = true,
    this.showPauseButton = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showBorder;
  final bool showPauseButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InkTheme.parchmentBackground,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...ParchmentHeaderScope.headersOf(context),
                  if (showPauseButton && PauseMenuScope.maybeOf(context) != null)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: PauseMenuButton(),
                    ),
                  if (appBar != null)
                    SizedBox(
                      height: appBar!.preferredSize.height,
                      child: appBar,
                    ),
                  Expanded(child: body),
                  ?bottomNavigationBar,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
