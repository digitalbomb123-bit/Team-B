import 'character_definition.dart';

/// Registry holding exactly 10 hardcoded character definitions.
/// Every character uses the same body and animations, but has a distinct face image.
class CharacterRegistry {
  static const List<CharacterDefinition> characters = [
    CharacterDefinition(
      id: 1,
      name: 'Nandhu',
      callsign: 'NANDHU',
      faceAsset: 'assets/characters/face_01.png',
      description: 'Tactical Operative Nandhu',
    ),
    CharacterDefinition(
      id: 2,
      name: 'Albin',
      callsign: 'ALBIN',
      faceAsset: 'assets/characters/face_02.png',
      description: 'Commando Albin',
    ),
    CharacterDefinition(
      id: 3,
      name: 'Chinnaran',
      callsign: 'CHINNARAN',
      faceAsset: 'assets/characters/face_03.png',
      description: 'Vanguard Chinnaran',
    ),
    CharacterDefinition(
      id: 4,
      name: 'Chunni',
      callsign: 'CHUNNI',
      faceAsset: 'assets/characters/face_04.png',
      description: 'Enforcer Chunni',
    ),
    CharacterDefinition(
      id: 5,
      name: 'Jos',
      callsign: 'JOS',
      faceAsset: 'assets/characters/face_05.png',
      description: 'Poop Master Jos - Special Poop Trap Ability (Traps & Stun Enemies!)',
    ),
    CharacterDefinition(
      id: 6,
      name: 'OD',
      callsign: 'OD',
      faceAsset: 'assets/characters/face_06.png',
      description: 'Heavy Gunner OD',
    ),
    CharacterDefinition(
      id: 7,
      name: 'PR',
      callsign: 'PR',
      faceAsset: 'assets/characters/face_07.png',
      description: 'Spec-Ops PR',
    ),
    CharacterDefinition(
      id: 8,
      name: 'Paulose',
      callsign: 'PAULOSE',
      faceAsset: 'assets/characters/face_08.png',
      description: 'Veteran Paulose',
    ),
    CharacterDefinition(
      id: 9,
      name: 'Rajappan',
      callsign: 'RAJAPPAN',
      faceAsset: 'assets/characters/face_09.png',
      description: 'Strike Specialist Rajappan',
    ),
    CharacterDefinition(
      id: 10,
      name: 'Vava',
      callsign: 'VAVA',
      faceAsset: 'assets/characters/face_10.png',
      description: 'Commander Vava',
    ),
  ];

  /// Retrieve character by ID (1-based, 1 to 10).
  static CharacterDefinition getById(int id) {
    return characters.firstWhere(
      (c) => c.id == id,
      orElse: () => characters.first,
    );
  }

  /// Retrieve all 10 registered characters.
  static List<CharacterDefinition> getAll() => List.unmodifiable(characters);
}
