/// CharacterDefinition defines the identity and face asset for a character slot.
class CharacterDefinition {
  final int id;
  final String name;
  final String faceAsset;
  final String callsign;
  final String description;

  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.faceAsset,
    this.callsign = 'SOLDIER',
    this.description = 'Combat specialist',
  });
}
