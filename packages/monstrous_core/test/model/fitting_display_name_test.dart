import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'legacy Standard utility displays current label without rewriting save',
    () {
      final saved = <String, dynamic>{
        'id': 'utility_drill',
        'name': 'Gunnery Drill',
        'type': 'utility',
        'isSignature': false,
      };
      final slot = HardpointSlot.fromJson(saved);

      expect(slot.displayName, 'Gun-Deck Bracing');
      expect(slot.name, 'Gunnery Drill');
      expect(slot.toJson(), saved);
      expect(UtilityHardpointId.gunneryDrill.name, 'gunneryDrill');
      expect(UtilityHardpointId.gunneryDrill.cooldownTurns, 2);
      expect(
        FlagshipBlueprint
            .catalog[BlueprintId.standard]!
            .hardpoints
            .last
            .displayName,
        slot.displayName,
      );
    },
  );

  test('other saved fitting names remain intact', () {
    const slot = HardpointSlot(
      id: 'custom_utility',
      name: 'Saved fitting name',
      type: HardpointType.utility,
    );
    expect(slot.displayName, slot.name);
    expect(HardpointSlot.fromJson(slot.toJson()).toJson(), slot.toJson());
  });

  test('Standard bracing narration retains its utility and volley effects', () {
    final session = GameSession(rng: SeededGameRng(91))
      ..dispatch(const BeginFirstVoyage('Founder Vane'));
    final events = session.dispatch(const ExecuteShipSpecialAction());
    final narration = events.whereType<NarrationEvent>().map((e) => e.message);

    expect(narration, contains(contains('Gun-Deck Bracing:')));
    expect(narration, contains(contains('sets the hull and gun-deck braces')));
    expect(narration, contains(contains('-20% incoming damage this round')));
    expect(narration, contains(contains('+15% Accuracy & +20% Damage')));
    expect(session.ship!.gunneryDrillBuffActive, isTrue);
  });
}
