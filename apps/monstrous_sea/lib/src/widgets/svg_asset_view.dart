import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'pilot_art.dart';

/// Renders ink-and-parchment SVGs and the simple sea-map raster illustrations.
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

  /// Selects equipment art by its game type, including renamed or rare items.
  static String pathForItem(Item item) {
    if (item is Consumable) {
      return switch (item.type) {
        ConsumableType.unstableTincture => PilotArt.unstableTincture,
        ConsumableType.blastPack => PilotArt.blastPack,
        ConsumableType.chakram => PilotArt.chakram,
      };
    }
    if (item is ShipWeapon) {
      return switch (item.weaponType) {
        ShipWeaponType.cannon => PilotArt.cannon,
        ShipWeaponType.precisionCulverin => PilotArt.cannon,
        ShipWeaponType.heavyMortar => PilotArt.cannons,
        ShipWeaponType.prowRam => PilotArt.anchor,
        ShipWeaponType.harpoonWinch => PilotArt.anchor,
        ShipWeaponType.torpedoLauncher => PilotArt.torpedoLauncher,
        ShipWeaponType.bladeLauncher => PilotArt.bladeLauncher,
        ShipWeaponType.lightningRailgun => PilotArt.lightningRailgun,
        ShipWeaponType.flamethrower => PilotArt.flamethrower,
      };
    }
    return item is Treasure ? PilotArt.treasure : PilotArt.helm;
  }

  /// Returns the approved illustration for [shipClass].
  static String pathForShip(ShipClass shipClass, {bool isDavyJones = false}) {
    return isDavyJones
        ? PilotArt.flyingDutchman
        : PilotArt.forShipClass(shipClass);
  }

  /// Returns the illustration for a legacy monster name.
  static String pathForMonster(String monsterName) {
    final lower = monsterName.toLowerCase();
    if (lower.contains('kraken')) return PilotArt.kraken;
    if (lower.contains('shark')) return PilotArt.shark;
    if (lower.contains('serpent') ||
        lower.contains('viper') ||
        lower.contains('eel')) {
      return PilotArt.serpent;
    }
    if (lower.contains('jellyfish') ||
        lower.contains('tendril') ||
        lower.contains('medusa')) {
      return PilotArt.jellyfish;
    }
    if (lower.contains('squid') ||
        lower.contains('horror') ||
        lower.contains('ink')) {
      return PilotArt.squid;
    }
    if (lower.contains('crustacean') ||
        lower.contains('crab') ||
        lower.contains('lobster')) {
      return PilotArt.crustacean;
    }
    // Default fallback
    return PilotArt.squid;
  }

  /// Returns the asset path for a [MonsterSpecies].
  static String pathForSpecies(MonsterSpecies species) {
    return PilotArt.forSpecies(species);
  }

  @override
  Widget build(BuildContext context) {
    // Existing callers can display either a vector plate or a pilot engraving.
    if (!assetPath.toLowerCase().endsWith('.svg')) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,
      );
    }
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (context) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: InkTheme.inkMuted,
          ),
        ),
      ),
    );
  }
}
