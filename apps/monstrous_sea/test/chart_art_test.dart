import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';

class _ChartFontCache extends PathProviderPlatform {
  _ChartFontCache(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontCache = String.fromEnvironment('artFontCache');
  InkTheme.disableGoogleFonts = fontCache.isEmpty;
  for (final asset in PilotArt.chartAssets) {
    test('$asset has a 1024 RGBA canvas and transparent 10% margins', () async {
      final bytes = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      try {
        expect(image.width, 1024);
        expect(image.height, 1024);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        var painted = 0;
        var paddingAlpha = 0;
        for (var y = 0; y < 1024; y++) {
          for (var x = 0; x < 1024; x++) {
            final alpha = pixels[(y * 1024 + x) * 4 + 3];
            if (alpha > 200) painted++;
            if (x < 102 || y < 102 || x >= 922 || y >= 922) {
              if (alpha > paddingAlpha) paddingAlpha = alpha;
            }
          }
        }
        expect(
          paddingAlpha,
          0,
          reason: 'All four margins must be truly transparent',
        );
        expect(
          painted,
          greaterThan(50000),
          reason: 'The icon must paint visible artwork',
        );
      } finally {
        image.dispose();
        codec.dispose();
      }
    });
  }
  for (final isInPort in [true, false]) {
    testWidgets(
      'Sea Chart shows artwork and vessel location ${isInPort ? 'in port' : 'underway'}',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (fontCache.isNotEmpty) {
          final previous = PathProviderPlatform.instance;
          PathProviderPlatform.instance = _ChartFontCache(fontCache);
          addTearDown(() => PathProviderPlatform.instance = previous);
          await tester.runAsync(() async {
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
            InkTheme.themeData;
            await GoogleFonts.pendingFonts([
              InkTheme.titleLarge,
              InkTheme.titleMedium,
              InkTheme.subtitle,
              InkTheme.body,
              InkTheme.caption,
              InkTheme.statLabel,
            ]);
          });
        }
        final chart = SeaChart(
          currentRow: isInPort ? 0 : 1,
          currentCol: isInPort ? 0 : 2,
        );
        final boundaryKey = GlobalKey();
        var closed = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: InkTheme.themeData,
            home: RepaintBoundary(
              key: boundaryKey,
              child: SeaChartScreen(
                seaChart: chart,
                isInPort: isInPort,
                onClose: () => closed = true,
              ),
            ),
          ),
        );
        final context = tester.element(find.byType(SeaChartScreen));
        await tester.runAsync(() async {
          for (final asset in {
            ...PilotArt.chartAssets,
            ...MonsterSpecies.values.map(PilotArt.forSpecies),
          }) {
            await precacheImage(AssetImage(asset), context);
          }
        });
        await tester.pumpAndSettle();
        Finder art(String asset) => find.byWidgetPredicate(
          (widget) => widget is SvgAssetView && widget.assetPath == asset,
        );
        expect(art(PilotArt.portHaven), findsOneWidget);
        expect(art(PilotArt.defeatedMonster), findsNWidgets(isInPort ? 0 : 7));
        expect(art(PilotArt.fog), findsNWidgets(isInPort ? 8 : 1));
        expect(find.text('VESSEL'), findsOneWidget);
        expect(
          find.text('ANCHORED IN PORT'),
          isInPort ? findsOneWidget : findsNothing,
        );
        expect(find.text('DEFEATED'), findsNWidgets(isInPort ? 0 : 7));
        expect(find.byIcon(Icons.anchor), findsNothing);
        expect(find.byIcon(Icons.cloud_queue), findsNothing);
        expect(find.text('☠'), findsNothing);
        expect(tester.takeException(), isNull);
        const proofPrefix = String.fromEnvironment('chartProofPath');
        Future<void> saveProof(String suffix) async {
          if (proofPrefix.isEmpty) return;
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$proofPrefix-${isInPort ? 'port' : 'underway'}-$suffix.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        await saveProof('wide');
        tester.view.physicalSize = const Size(480, 800);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await saveProof('compact');
        await tester.ensureVisible(find.text('CLOSE SEA CHART'));
        await tester.tap(find.text('CLOSE SEA CHART'));
        expect(closed, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
