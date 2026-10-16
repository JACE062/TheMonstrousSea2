import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameSession Combat Range & Mobility Integration', () {
    test('Battle begins at CombatRange.medium and ChangeCombatRange shifts helm stance', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Ahab'));
      session.dispatch(const ChooseShip(ShipClass.standard));
      final battleEvents = session.dispatch(const VentureOutToSea());

      expect(session.phase, SessionPhase.battle);
      expect(session.combatRange, CombatRange.medium);
      expect(battleEvents.any((e) => e is BattleStarted), isTrue);

      final shiftEvents = session.dispatch(const ChangeCombatRange(CombatRange.long));
      expect(session.combatRange, CombatRange.long);
      expect(shiftEvents.any((e) => e is CombatRangeChanged), isTrue);
      final rangeEvent = shiftEvents.whereType<CombatRangeChanged>().first;
      expect(rangeEvent.previousRange, CombatRange.medium);
      expect(rangeEvent.newRange, CombatRange.long);
    });

    test('Prow Ram surges ship into CombatRange.short on strike', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Nemo'));
      session.dispatch(const ChooseShip(ShipClass.ironclad));
      session.dispatch(const VentureOutToSea());

      expect(session.combatRange, CombatRange.medium);

      // Ensure monster survives strike so combatRange does not reset to medium on victory
      session.currentMonster!.maxHp = 300;
      session.currentMonster!.currentHp = 300;

      // Firing Prow Ram charges into point-blank range
      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.prowRam));
      expect(session.combatRange, CombatRange.short);
      expect(
        events.any((e) =>
            e is CombatRangeChanged &&
            e.newRange == CombatRange.short &&
            e.reason.contains('Prow Ram')),
        isTrue,
      );
    });

    test('IssueHelmOrder repositions vessel and FireWeaponVolley resolves at new range', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Hawkins'));
      session.dispatch(const ChooseShip(ShipClass.clipper));
      session.dispatch(const VentureOutToSea());

      expect(session.combatRange, CombatRange.medium);

      // Clipper commands helm to fall back to Long Range
      final helmEvents = session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(session.combatRange, CombatRange.long);
      expect(
        helmEvents.any((e) =>
            e is CombatRangeChanged &&
            e.newRange == CombatRange.long),
        isTrue,
      );

      // Culverin volley at Long Range
      final fireEvents = session.dispatch(const FireWeaponVolley(
        ShipWeaponType.precisionCulverin,
      ));

      expect(session.combatRange, CombatRange.long);
      expect(fireEvents.any((e) => e is AttackAttempted), isTrue);
    });

    test('Bounded Helm Orders: cannot retreat beyond Long or sail into monster at Short', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Drake'));
      session.dispatch(const ChooseShip(ShipClass.standard));
      session.dispatch(const VentureOutToSea());

      // Fall back from Medium to Long
      session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(session.combatRange, CombatRange.long);

      // At Long: available orders are holdLine and advance
      expect(session.combatRange.availableHelmOrders, [HelmOrder.holdLine, HelmOrder.advance]);
      expect(
        () => session.dispatch(const IssueHelmOrder(HelmOrder.fallBack)),
        throwsStateError,
      );

      // Advance from Long to Medium
      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.medium);
      expect(session.combatRange.availableHelmOrders, [
        HelmOrder.advance,
        HelmOrder.holdLine,
        HelmOrder.fallBack,
      ]);

      // Advance from Medium to Short
      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.short);

      // At Short: available orders are holdLine and fallBack
      expect(session.combatRange.availableHelmOrders, [HelmOrder.holdLine, HelmOrder.fallBack]);
      expect(
        () => session.dispatch(const IssueHelmOrder(HelmOrder.advance)),
        throwsStateError,
      );
    });

    test('Prow Ram cannot fire from Long Range, but works at Medium and surges to Short', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Iron-Grip'));
      session.dispatch(const ChooseShip(ShipClass.ironclad));
      session.dispatch(const VentureOutToSea());

      // Move to Long Range
      session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(session.combatRange, CombatRange.long);

      // Ramming from Long Range is illegal
      expect(
        () => session.dispatch(const FireWeaponVolley(ShipWeaponType.prowRam)),
        throwsStateError,
      );

      // Advance to Medium Range
      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.medium);

      // Ensure monster survives strike so combatRange does not reset to medium on victory
      session.currentMonster!.maxHp = 300;
      session.currentMonster!.currentHp = 300;

      // Ramming from Medium is legal, and surges to Short Range on impact
      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.prowRam));
      expect(session.combatRange, CombatRange.short);
      expect(events.any((e) => e is AttackAttempted), isTrue);
      expect(
        events.any((e) =>
            e is CombatRangeChanged &&
            e.newRange == CombatRange.short &&
            e.reason.contains('Prow Ram kinetic charge surged')),
        isTrue,
      );
    });

    test('Harpoon Winch reels quarry 1 band closer', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Teach'));
      session.dispatch(const ChooseShip(ShipClass.corsair));
      session.dispatch(const VentureOutToSea());

      // Set to Long Range first
      session.dispatch(const ChangeCombatRange(CombatRange.long));
      expect(session.combatRange, CombatRange.long);

      // Fire Harpoon Winch -> reels from Long to Medium
      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.harpoonWinch));
      expect(session.combatRange, CombatRange.medium);
      expect(
        events.any((e) =>
            e is CombatRangeChanged &&
            e.previousRange == CombatRange.long &&
            e.newRange == CombatRange.medium),
        isTrue,
      );
    });

    test('Corvette Evasive Maneuvers opens range by 1 band away from danger', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Drake'));
      session.dispatch(const ChooseShip(ShipClass.corvette));
      session.dispatch(const VentureOutToSea());

      // Beast closed in to Short Range
      session.dispatch(const ChangeCombatRange(CombatRange.short));
      expect(session.combatRange, CombatRange.short);

      // Corvette executes evasive tacking action -> opens distance to Medium
      final events = session.dispatch(const ExecuteShipSpecialAction());
      expect(session.combatRange, CombatRange.medium);
      expect(
        events.any((e) =>
            e is CombatRangeChanged &&
            e.previousRange == CombatRange.short &&
            e.newRange == CombatRange.medium),
        isTrue,
      );
    });

    test('Defeating beast resets combatRange back to baseline medium', () {
      final session = GameSession();
      session.dispatch(const NameCaptain('Morgan'));
      session.dispatch(const ChooseShip(ShipClass.standard));
      session.dispatch(const VentureOutToSea());

      session.dispatch(const ChangeCombatRange(CombatRange.short));
      expect(session.combatRange, CombatRange.short);

      // Defeating monster (set HP to 0)
      session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));

      // After battle defeat and loot phase, range is reset
      expect(session.combatRange, CombatRange.medium);
    });
  });
}
