import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/eldritch_relic_preview.dart';

void main() {
  for (final id in EldritchRelicId.values) {
    for (final state in ['locked', 'poor', 'ready', 'forged', 'inactive']) {
      test('$id $state preview is read-only and agrees with forge gates', () {
        final s = GameSession(rng: SeededGameRng(42));
        s.profile.hasUnlockedCovenant = true;
        final def = EldritchRelicDef.catalog[id]!;
        if (state != 'locked') {
          s.profile.unlockedBlueprints.add(def.blueprintId.name);
        }
        if (state != 'poor') {
          s.profile.metaInventory.add(
            krakenBeak: 10,
            serpentScale: 10,
            leviathanCore: 10,
            primordialCinders: 20,
          );
        }
        s.dispatch(const NameCaptain('Forge witness'));
        s.dispatch(const ChooseShip(ShipClass.standard));
        if (state == 'forged' || state == 'inactive') {
          s.dispatch(UnlockEldritchRelic(id));
        }
        if (state == 'inactive') s.profile.activeEldritchRelics.remove(id.name);
        final before = jsonEncode({
          'profile': s.profile.toJson(),
          'ship': s.ship!.toJson(),
          'chart': s.seaChart.toJson(),
        });
        final preview = EldritchRelicPreview(s.profile, id);
        expect(preview.isForged, state == 'forged' || state == 'inactive');
        expect(preview.isActive, state == 'forged');
        expect(preview.canForge, state == 'ready');
        expect(preview.blueprintUnlocked, state != 'locked');
        expect(preview.cost.toJson(), def.unlockCost.toJson());
        expect(preview.stats, isNotEmpty);
        expect(
          preview.stats.every(
            (stat) => (stat.next == null) == preview.isForged,
          ),
          isTrue,
        );
        expect(
          jsonEncode({
            'profile': s.profile.toJson(),
            'ship': s.ship!.toJson(),
            'chart': s.seaChart.toJson(),
          }),
          before,
        );
        if (preview.canForge) {
          final inventory = MetaInventory.fromJson(
            s.profile.metaInventory.toJson(),
          );
          inventory.spendCost(preview.cost);
          final shipBefore = jsonEncode(s.ship!.toJson());
          s.dispatch(UnlockEldritchRelic(id));
          expect(s.profile.isEldritchRelicActive(id), isTrue);
          expect(s.profile.isEldritchRelicUnlocked(id), isTrue);
          expect(s.profile.metaInventory.toJson(), inventory.toJson());
          expect(
            jsonEncode(s.ship!.toJson()),
            shipBefore,
            reason: 'Forging adds a permanent rider without rolling or replacing a weapon.',
          );
          final after = EldritchRelicPreview(s.profile, id);
          expect(
            after.stats.map((stat) => stat.current),
            preview.stats.map((stat) => stat.next),
          );
        }
      });
    }
  }
  test(
    'previews list added effects without implying intrinsic stat changes',
    () {
      final p = ProfileData();
      final ram = EldritchRelicPreview(p, EldritchRelicId.siphonRam);
      expect(ram.stats.single.next, '30%');
      final ghost = EldritchRelicPreview(p, EldritchRelicId.ghostwakeCulverin);
      expect(ghost.stats.map((s) => s.next), ['Yes', '8']);
      expect(ghost.stats.last.label, 'Base Shock per flesh hit');
      expect(
        EldritchRelicPreview(
          p,
          EldritchRelicId.brimstoneMortar,
        ).stats.single.label,
        'Burning on hit',
      );
      expect(
        EldritchRelicPreview(p, EldritchRelicId.sinewWinch).stats.single.label,
        'Poison on hit',
      );
    },
  );
}
