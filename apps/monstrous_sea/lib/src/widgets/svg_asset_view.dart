import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../theme/ink_theme.dart';

/// Renders authentic ink-and-parchment SVG illustrations for ships, monsters, and icons.
class SvgAssetView extends StatelessWidget {
  const SvgAssetView({
    super.key,
    required this.assetPath,
    this.width = 64,
    this.height = 64,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;

  /// Returns the SVG asset path for [shipClass].
  static String pathForShip(ShipClass shipClass, {bool isDavyJones = false}) {
    if (isDavyJones) return 'assets/art/ship_flying_dutchman.svg';
    return switch (shipClass) {
      ShipClass.standard => 'assets/art/ship_standard.svg',
      ShipClass.freighter => 'assets/art/ship_freighter.svg',
      ShipClass.ironclad => 'assets/art/ship_ironclad.svg',
      ShipClass.corvette => 'assets/art/ship_corvette.svg',
    };
  }

  /// Returns the SVG asset path for monster [name] or [species].
  static String pathForMonster(String monsterName) {
    final lower = monsterName.toLowerCase();
    if (lower.contains('kraken')) return 'assets/art/monster_kraken.svg';
    if (lower.contains('shark')) return 'assets/art/monster_shark.svg';
    if (lower.contains('serpent') || lower.contains('viper') || lower.contains('eel')) {
      return 'assets/art/monster_serpent.svg';
    }
    if (lower.contains('jellyfish') || lower.contains('tendril') || lower.contains('medusa')) {
      return 'assets/art/monster_jellyfish.svg';
    }
    if (lower.contains('squid') || lower.contains('horror') || lower.contains('ink')) {
      return 'assets/art/monster_squid.svg';
    }
    if (lower.contains('crustacean') || lower.contains('crab') || lower.contains('lobster')) {
      return 'assets/art/monster_crustacean.svg';
    }
    // Default fallback
    return 'assets/art/monster_squid.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (context) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: InkTheme.inkMuted),
        ),
      ),
    );
  }
}
