/// Lifecycle phases of a game session.
enum SessionPhase {
  captainCreation('Captain Creation'),
  port("Hunter's Respite Port"),
  merchant('Harpoon & Helm Merchant'),
  battle('Naval Battle'),
  loot('Spoils of Victory'),
  restArea('Rest on Open Sea'),
  death('Watery Grave'),
  ended('Hunt Concluded');

  const SessionPhase(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}
