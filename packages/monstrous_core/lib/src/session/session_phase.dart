/// Lifecycle phases of a game session.
enum SessionPhase {
  captainCreation('Captain Creation'),
  port("Hunter's Respite Port"),
  stronghold('Voyage Stronghold'),
  merchant('Harpoon & Helm Merchant'),
  helm("The Ship's Helm"),
  battle('Naval Battle'),
  loot('Spoils of Victory'),
  restArea('Rest on Open Sea'),
  respiteIsland('Respite Island Haven'),
  shipwreck('Shipwreck Derelict'),
  smuggler("Smuggler's Ketch"),
  shrine('Ancient Sea Shrine'),
  expeditionVictory('Grand Expedition Victory'),
  death('Watery Grave'),
  ended('Hunt Concluded');

  const SessionPhase(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}
