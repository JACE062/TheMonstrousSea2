import 'package:monstrous_core/monstrous_core.dart';

/// Base interface defining automated bot decision logic.
abstract class BotStrategy {
  /// Unique identifier of the bot strategy.
  String get name;

  /// Decides and returns the next [Command] to dispatch given [session].
  Command decideNextAction(GameSession session);
}
