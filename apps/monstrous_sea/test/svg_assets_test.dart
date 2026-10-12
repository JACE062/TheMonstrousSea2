import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const plates = [
    'ship_ironclad',
    'ship_freighter',
    'ship_corvette',
    'ship_standard',
    'ship_flying_dutchman',
    'monster_shark',
    'monster_serpent',
    'monster_jellyfish',
    'monster_squid',
    'monster_crustacean',
    'monster_kraken',
    'icon_unstable_tincture',
    'icon_blast_pack',
    'icon_chakram',
    'icon_cannon',
    'icon_torpedo_launcher',
    'icon_blade_launcher',
    'icon_lightning_railgun',
    'icon_flamethrower',
  ];

  for (final plate in plates) {
    test(
      '$plate loads from the Flutter bundle and paints visible vectors',
      () async {
        final picture = await vg.loadPicture(
          SvgAssetLoader('assets/art/$plate.svg'),
          null,
        );
        final size = plate.startsWith('icon_') ? 64 : 200;
        try {
          expect(picture.size, ui.Size(size.toDouble(), size.toDouble()));
          final image = await picture.picture.toImage(size, size);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            expect(bytes, isNotNull);
            final pixels = bytes!.buffer.asUint8List();
            var painted = 0;
            for (var i = 3; i < pixels.length; i += 4) {
              if (pixels[i] > 0) painted++;
            }
            // A parsed but empty drawing must not silently pass the pipeline.
            expect(
              painted,
              greaterThan(size),
              reason: '$plate must contain visible art',
            );
          } finally {
            image.dispose();
          }
        } finally {
          picture.picture.dispose();
        }
      },
    );
  }
}
