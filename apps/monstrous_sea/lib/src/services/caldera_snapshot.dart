import 'package:monstrous_core/monstrous_core.dart';

/// A matched profile/voyage pair before either ending has changed progression.
/// Never reconstruct this from a resolved ending or reverse its rewards.
class CalderaSnapshot {
  CalderaSnapshot({required this.profile, required this.voyage}) {
    if (profile.hasShatteredFont ||
        voyage.phase != SessionPhase.expeditionVictory ||
        voyage.calderaOutcome != null ||
        voyage.hasReadCalderaOutcome) {
      throw const FormatException('Not an unresolved Caldera snapshot');
    }
  }

  final ProfileData profile;
  final VoyageSaveData voyage;

  factory CalderaSnapshot.fromSession(GameSession session) =>
      CalderaSnapshot.fromJson({
        'version': 1,
        'profile': session.profile.toJson(),
        'voyage': VoyageSaveData.fromSession(session).toJson(),
      });

  factory CalderaSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported Caldera snapshot');
    }
    return CalderaSnapshot(
      profile: ProfileData.fromJson(json['profile'] as Map<String, dynamic>),
      voyage: VoyageSaveData.fromJson(json['voyage'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'profile': profile.toJson(),
    'voyage': voyage.toJson(),
  };
}
