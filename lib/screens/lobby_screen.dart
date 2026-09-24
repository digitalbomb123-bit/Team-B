import 'package:flutter/material.dart';
import '../characters/character_definition.dart';
import '../characters/character_registry.dart';
import '../ui/orientation_overlay.dart';
import 'game_screen.dart';

/// Pre-game Lobby & Character Selection screen.
/// Displays all 10 hardcoded character slots and lets player pick their soldier face.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  static const String defaultServerUrl = 'wss://team-b-6hro.onrender.com';

  int _selectedCharacterId = 1;
  final TextEditingController _nameController =
      TextEditingController(text: 'Soldier');
  final TextEditingController _roomController =
      TextEditingController(text: 'ARENA-1');
  final TextEditingController _serverController =
      TextEditingController(text: defaultServerUrl);

  final ScrollController _scrollController = ScrollController();

  bool _isOnlineMultiplayer = false;
  int _botCount = 4; // Default 4 bots (total 5 players)

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _serverController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startGame() {
    final name = _nameController.text.trim().isEmpty
        ? 'Hero'
        : _nameController.text.trim();

    final room = _roomController.text.trim().isEmpty
        ? 'ARENA-1'
        : _roomController.text.trim().toUpperCase();

    final server = _serverController.text.trim().isEmpty
        ? defaultServerUrl
        : _serverController.text.trim();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          characterId: _selectedCharacterId,
          playerName: name,
          botCount: _botCount,
          isOnlineMultiplayer: _isOnlineMultiplayer,
          roomId: room,
          serverUrl: server,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = CharacterRegistry.getAll();
    final selectedDef = CharacterRegistry.getById(_selectedCharacterId);
    final size = MediaQuery.of(context).size;
    final isCompactHeight = size.height < 520;
    final isVeryCompact = size.height < 400;

    return OrientationOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompactHeight ? 12 : 24,
              vertical: isCompactHeight ? 8 : 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT PANEL: Character Preview & Join Arena Form
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactHeight ? 10 : 16,
                      vertical: isCompactHeight ? 8 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SCROLLABLE AREA FOR SETTINGS & CHARACTER DETAILS
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: isCompactHeight,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Title & Badge
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.military_tech_rounded,
                                          color: const Color(0xFF38BDF8),
                                          size: isCompactHeight ? 20 : 26,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'MINI MILITIA 2D',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isCompactHeight ? 16 : 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isCompactHeight ? 6 : 12),

                                  // Selected Face Avatar Preview
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: isVeryCompact
                                            ? 52
                                            : (isCompactHeight ? 64 : 84),
                                        height: isVeryCompact
                                            ? 52
                                            : (isCompactHeight ? 64 : 84),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0F172A),
                                          border: Border.all(
                                            color: const Color(0xFF38BDF8),
                                            width: isCompactHeight ? 2.5 : 3.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            selectedDef.faceAsset,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '#${selectedDef.id}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: isCompactHeight ? 4 : 8),

                                  Text(
                                    '${selectedDef.name} (${selectedDef.callsign})',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompactHeight ? 13 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isVeryCompact)
                                    Text(
                                      selectedDef.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                    ),

                                  SizedBox(height: isCompactHeight ? 6 : 10),

                                  // Name input
                                  TextField(
                                    controller: _nameController,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompactHeight ? 12 : 13,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: isCompactHeight ? 7 : 10,
                                      ),
                                      labelText: 'Callsign / Name',
                                      labelStyle: TextStyle(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: isCompactHeight ? 11 : 12,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF0F172A),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF38BDF8),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF38BDF8),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isCompactHeight ? 6 : 10),

                                  // MODE SWITCHER: Solo Bots vs Online Multiplayer
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => setState(
                                                () => _isOnlineMultiplayer = false),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical:
                                                    isCompactHeight ? 5 : 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: !_isOnlineMultiplayer
                                                    ? const Color(0xFF0284C7)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.smart_toy_rounded,
                                                      size: 13,
                                                      color: !_isOnlineMultiplayer
                                                          ? Colors.white
                                                          : const Color(0xFF94A3B8),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'SOLO BOTS',
                                                      style: TextStyle(
                                                        color: !_isOnlineMultiplayer
                                                            ? Colors.white
                                                            : const Color(0xFF94A3B8),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => setState(
                                                () => _isOnlineMultiplayer = true),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical:
                                                    isCompactHeight ? 5 : 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _isOnlineMultiplayer
                                                    ? const Color(0xFF10B981)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.public_rounded,
                                                      size: 13,
                                                      color: _isOnlineMultiplayer
                                                          ? Colors.white
                                                          : const Color(0xFF94A3B8),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'MULTIPLAYER',
                                                      style: TextStyle(
                                                        color: _isOnlineMultiplayer
                                                            ? Colors.white
                                                            : const Color(0xFF94A3B8),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isCompactHeight ? 6 : 8),

                                  if (!_isOnlineMultiplayer) ...[
                                    // Bot Count Slider
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Arena Bots: ',
                                            style: TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '$_botCount Bots (${_botCount + 1}/10)',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor:
                                            const Color(0xFF38BDF8),
                                        inactiveTrackColor:
                                            const Color(0xFF334155),
                                        thumbColor: const Color(0xFF38BDF8),
                                        trackHeight: 2.5,
                                        thumbShape:
                                            const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _botCount.toDouble(),
                                        min: 1,
                                        max: 9,
                                        divisions: 8,
                                        onChanged: (val) {
                                          setState(
                                              () => _botCount = val.toInt());
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    // Room Code input
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: TextField(
                                            controller: _roomController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              labelText: 'Room Code',
                                              labelStyle: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 10,
                                              ),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFF0F172A),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          flex: 7,
                                          child: TextField(
                                            controller: _serverController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              labelText: 'Server URL',
                                              labelStyle: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 10,
                                              ),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFF0F172A),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Cloud WebSocket Relay (Live on Render)',
                                            style: TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isCompactHeight ? 6 : 8),

                        // PINNED ENTER ARENA BUTTON - ALWAYS VISIBLE AT BOTTOM
                        SizedBox(
                          width: double.infinity,
                          height: isCompactHeight ? 36 : 42,
                          child: ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isOnlineMultiplayer
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                              padding: EdgeInsets.zero,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isOnlineMultiplayer
                                        ? Icons.wifi_tethering_rounded
                                        : Icons.play_arrow_rounded,
                                    size: isCompactHeight ? 18 : 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnlineMultiplayer
                                        ? 'JOIN ONLINE ARENA'
                                        : 'ENTER ARENA',
                                    style: TextStyle(
                                      fontSize: isCompactHeight ? 12 : 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: isCompactHeight ? 10 : 18),

                // RIGHT PANEL: Character Slots Grid (10 Hardcoded Slots)
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: EdgeInsets.all(isCompactHeight ? 10 : 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SELECT CHARACTER (10 SLOTS)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompactHeight ? 11 : 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Shared body • Custom face',
                                style: TextStyle(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: isCompactHeight ? 10 : 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompactHeight ? 6 : 12),

                        // Grid of 10 Character Slots (2 rows of 5 or responsive)
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: isCompactHeight ? 6 : 10,
                              mainAxisSpacing: isCompactHeight ? 6 : 10,
                              childAspectRatio: isCompactHeight ? 0.95 : 0.85,
                            ),
                            itemCount: characters.length,
                            itemBuilder: (context, index) {
                              final char = characters[index];
                              final isSelected =
                                  char.id == _selectedCharacterId;

                              return _buildCharacterSlotCard(
                                char,
                                isSelected,
                                isCompact: isCompactHeight,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterSlotCard(
    CharacterDefinition char,
    bool isSelected, {
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedCharacterId = char.id);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7).withValues(alpha: 0.3)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(isCompact ? 4 : 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Face thumbnail
            Expanded(
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    char.faceAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 2 : 4),
            Text(
              char.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: isCompact ? 9 : 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            Text(
              char.callsign,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF64748B),
                fontSize: isCompact ? 7.5 : 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
