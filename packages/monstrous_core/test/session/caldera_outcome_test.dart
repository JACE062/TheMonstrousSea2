import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

GameSession atCaldera() => GameSession(rng: SeededGameRng(42))
  ..dispatch(const NameCaptain('Mara Thorne'))
  ..dispatch(const ChooseShip(ShipClass.standard))
  ..profile.metaInventory.add(leviathanCore: 1)
  ..phase = SessionPhase.expeditionVictory;

GameSession reload(GameSession session) {
  final restored = GameSession(
    rng: SeededGameRng(99),
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  VoyageSaveData.fromJson(VoyageSaveData.fromSession(session).toJson())
      .restoreToSession(restored);
  return restored;
}

void main() {
  for (final choice in CalderaClimaxChoice.values) {
    test(
      '$choice uses canonical prose and acknowledgement never reapplies it',
      () {
        var session = atCaldera();
        final events = session.dispatch(ResolveCalderaClimax(choice));
        expect(
          events.whereType<CalderaClimaxResolved>().single.narrative,
          EldritchLore.calderaClimax[choice]!.narrativeOutcome,
        );
        expect(
          events.whereType<NarrationEvent>().single.message,
          EldritchLore.calderaClimax[choice]!.narrativeOutcome,
        );
        final originalHeirs = session.pendingHeirCandidates
            .map((h) => h.toJson())
            .toList();
        final inventory = session.profile.metaInventory.toJson();
        final deaths = session.lineage.captainsLost;
        final loops = session.profile.ascensionLoopCount;
        session = reload(session);
        expect(session.captainName, 'Mara Thorne');
        expect(session.calderaOutcome, choice);
        expect(session.hasReadCalderaOutcome, isFalse);
        expect(
          session.pendingHeirCandidates.map((h) => h.toJson()).toList(),
          originalHeirs,
        );
        expect(
          () => session.dispatch(ResolveCalderaClimax(choice)),
          throwsStateError,
        );
        session.dispatch(const AcknowledgeCalderaOutcome());
        session.dispatch(const AcknowledgeCalderaOutcome());
        session = reload(session);
        expect(session.hasReadCalderaOutcome, isTrue);
        expect(session.profile.metaInventory.toJson(), inventory);
        expect(session.lineage.captainsLost, deaths);
        expect(session.profile.ascensionLoopCount, loops);
        expect(
          session.phase,
          choice == CalderaClimaxChoice.shatterCore
              ? SessionPhase.ended
              : SessionPhase.death,
        );
        if (choice == CalderaClimaxChoice.claimCore) {
          expect(
            session.lineage.history.last.causeOfDeath,
            EldritchLore.claimLedgerCause,
          );
          final heir = session.pendingHeirCandidates.first;
          session.dispatch(
            ContinueLineage(
              heir.defaultName,
              ShipClass.standard,
              boon: heir.boon,
              quirk: heir.quirk,
            ),
          );
          expect(session.phase, SessionPhase.port);
          expect(session.calderaOutcome, isNull);
          expect(session.hasReadCalderaOutcome, isFalse);
        }
      },
    );
  }

  test('older snapshots have no pending outcome or synthetic heirs', () {
    final session = atCaldera();
    final json = VoyageSaveData.fromSession(session).toJson()
      ..remove('calderaOutcome')
      ..remove('hasReadCalderaOutcome')
      ..remove('pendingHeirCandidates');
    final restored = GameSession();
    VoyageSaveData.fromJson(json).restoreToSession(restored);
    expect(restored.phase, SessionPhase.expeditionVictory);
    expect(restored.calderaOutcome, isNull);
    expect(restored.pendingHeirCandidates, isEmpty);
    expect(
      () => restored.dispatch(const AcknowledgeCalderaOutcome()),
      throwsStateError,
    );
  });
}
