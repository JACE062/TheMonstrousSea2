import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/harbor_monument_preview.dart';

int bonus(ProfileData profile, HarborMonumentId id) => switch (id) {
  HarborMonumentId.obsidianObelisk => profile.monumentBonusMaxHp,
  HarborMonumentId.serpentEffigy =>
    ((profile.monumentBountyGoldMultiplier - 1) * 100).round(),
  HarborMonumentId.calderaBrazier =>
    ((profile.monumentWeaponDamageMultiplier - 1) * 100).round(),
};

void main() {
  for (final id in HarborMonumentId.values) {
    for (final rank in [0, 1, 2, 10, 99, 100]) {
      test('$id rank $rank preview matches a paid upgrade', () {
        final s = GameSession(rng: SeededGameRng(42));
        s.profile.hasUnlockedCovenant = true;
        s.profile.portCivicLevels.addAll({
          for (final monument in HarborMonumentId.values) monument.name: rank,
        });
        s.dispatch(const NameCaptain('Monument witness'));
        s.dispatch(const ChooseShip(ShipClass.standard));
        s.ship!.currentHp -= 7;
        s.profile.metaInventory.add(
          seaGlass: 10000,
          monsterBone: 10000,
          depthWroughtIron: 10000,
          krakenBeak: 1000,
          serpentScale: 1000,
          leviathanCore: 1000,
          primordialCinders: 10000,
        );
        final profileBefore = jsonEncode(s.profile.toJson());
        final shipBefore = jsonEncode(s.ship!.toJson());
        final chartBefore = jsonEncode(s.seaChart.toJson());
        final preview = HarborMonumentPreview(s.profile, id);
        expect(preview.currentRank, rank);
        expect(preview.nextRank, rank + 1);
        expect(preview.currentBonus, bonus(s.profile, id));
        expect(
          preview.currentBonus,
          rank * (id == HarborMonumentId.serpentEffigy ? 10 : 5),
        );
        expect(
          preview.nextBonus - preview.currentBonus,
          id == HarborMonumentId.serpentEffigy ? 10 : 5,
        );
        expect(jsonEncode(s.profile.toJson()), profileBefore);
        expect(jsonEncode(s.ship!.toJson()), shipBefore);
        expect(jsonEncode(s.seaChart.toJson()), chartBefore);
        final inventory = MetaInventory.fromJson(
          s.profile.metaInventory.toJson(),
        );
        expect(inventory.spendCost(preview.cost), isTrue);
        final currentHp = s.ship!.currentHp;
        final maxHp = s.ship!.maxHp;
        s.dispatch(UpgradeHarborMonument(id));
        expect(s.profile.monumentRank(id), preview.nextRank);
        expect(bonus(s.profile, id), preview.nextBonus);
        expect(s.profile.metaInventory.toJson(), inventory.toJson());
        for (final other in HarborMonumentId.values.where(
          (other) => other != id,
        )) {
          expect(s.profile.monumentRank(other), rank);
        }
        if (id == HarborMonumentId.obsidianObelisk) {
          expect(
            s.ship!.currentHp,
            currentHp + preview.nextBonus - preview.currentBonus,
          );
          expect(
            s.ship!.maxHp,
            maxHp + preview.nextBonus - preview.currentBonus,
          );
          expect(s.ship!.maxHp - s.ship!.currentHp, 7);
        } else {
          expect(jsonEncode(s.ship!.toJson()), shipBefore);
        }
      });
    }
  }

  test('unaffordable and locked profiles still have read-only previews', () {
    final profile = ProfileData();
    final before = jsonEncode(profile.toJson());
    for (final id in HarborMonumentId.values) {
      final preview = HarborMonumentPreview(profile, id);
      expect(preview.currentRank, 0);
      expect(preview.nextRank, 1);
      expect(
        preview.currentText,
        id == HarborMonumentId.obsidianObelisk ? '+0 HP' : '+0%',
      );
      expect(profile.canUpgradeMonument(id), isFalse);
    }
    expect(jsonEncode(profile.toJson()), before);
  });

  test('rank 100 remains available with the existing rank-99 cost clamp', () {
    final profile = ProfileData(
      portCivicLevels: {for (final id in HarborMonumentId.values) id.name: 99},
    );
    final obelisk = HarborMonumentPreview(
      profile,
      HarborMonumentId.obsidianObelisk,
    );
    final effigy = HarborMonumentPreview(
      profile,
      HarborMonumentId.serpentEffigy,
    );
    final brazier = HarborMonumentPreview(
      profile,
      HarborMonumentId.calderaBrazier,
    );
    expect(obelisk.nextRank, 100);
    expect(obelisk.cost.krakenBeak, 99);
    expect(obelisk.cost.seaGlass, 495);
    expect(effigy.cost.serpentScale, 99);
    expect(effigy.cost.monsterBone, 495);
    expect(brazier.cost.leviathanCore, 1);
    expect(brazier.cost.primordialCinders, 198);
    expect(brazier.cost.depthWroughtIron, 396);
  });
}
