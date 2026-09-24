import 'character_definition.dart';

/// Registry holding exactly 10 hardcoded character definitions.
/// Every character uses the same body and animations, but has a distinct face image.
class CharacterRegistry {
  static const List<CharacterDefinition> characters = [
    CharacterDefinition(
      id: 1,
      name: 'Character 1',
      callsign: 'VIPER',
      faceAsset: 'assets/characters/face_01.png',
      description: 'Blue Beret Vanguard',
    ),
    CharacterDefinition(
      id: 2,
      name: 'Character 2',
      callsign: 'HAVOC',
      faceAsset: 'assets/characters/face_02.png',
      description: 'Crimson Commando',
    ),
    CharacterDefinition(
      id: 3,
      name: 'Character 3',
      callsign: 'GHOST',
      faceAsset: 'assets/characters/face_03.png',
      description: 'Emerald Scout',
    ),
    CharacterDefinition(
      id: 4,
      name: 'Character 4',
      callsign: 'TITAN',
      faceAsset: 'assets/characters/face_04.png',
      description: 'Heavy Juggernaut',
    ),
    CharacterDefinition(
      id: 5,
      name: 'Character 5',
      callsign: 'SHADOW',
      faceAsset: 'assets/characters/face_05.png',
      description: 'Spec-Ops Infiltrator',
    ),
    CharacterDefinition(
      id: 6,
      name: 'Character 6',
      callsign: 'RAZOR',
      faceAsset: 'assets/characters/face_06.png',
      description: 'Goggles Gunner',
    ),
    CharacterDefinition(
      id: 7,
      name: 'Character 7',
      callsign: 'BLAZE',
      faceAsset: 'assets/characters/face_07.png',
      description: 'Veteran Mercenary',
    ),
    CharacterDefinition(
      id: 8,
      name: 'Character 8',
      callsign: 'FROST',
      faceAsset: 'assets/characters/face_08.png',
      description: 'Arctic Recon',
    ),
    CharacterDefinition(
      id: 9,
      name: 'Character 9',
      callsign: 'APEX',
      faceAsset: 'assets/characters/face_09.png',
      description: 'Cyber Enforcer',
    ),
    CharacterDefinition(
      id: 10,
      name: 'Character 10',
      callsign: 'OMEGA',
      faceAsset: 'assets/characters/face_10.png',
      description: 'Tactical Commander',
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
