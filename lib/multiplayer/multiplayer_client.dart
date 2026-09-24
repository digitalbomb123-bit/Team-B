import 'player_state.dart';

/// Abstract contract for multiplayer networking.
/// Allows swapping MockMultiplayerClient with a WebSocketMultiplayerClient
/// in the future without altering the game systems or Player components.
abstract class MultiplayerClient {
  /// Stream broadcasting all active players' states (up to 10 players).
  Stream<List<PlayerState>> get playersStream;

  /// Stream of bullets spawned across the network.
  Stream<BulletNetworkEvent> get bulletStream;

  /// Current snapshot of all remote/mock players.
  List<PlayerState> get currentPlayers;

  /// ID of the local client player.
  String get localPlayerId;

  /// Connect to a room with a specified character selection.
  Future<void> connect({
    required String roomId,
    required String playerName,
    required int characterId,
  });

  /// Broadcast local player's updated state.
  void sendPlayerUpdate(PlayerState state);

  /// Broadcast a bullet fired by the local player.
  void sendShootEvent(BulletNetworkEvent event);

  /// Report damage inflicted on another player.
  void sendDamageEvent({
    required String targetPlayerId,
    required double damage,
    required String attackerId,
  });

  /// Disconnect and release resources.
  void disconnect();
}
