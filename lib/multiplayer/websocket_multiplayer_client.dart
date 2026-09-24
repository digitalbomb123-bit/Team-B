import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'multiplayer_client.dart';
import 'player_state.dart';

/// Real-time WebSocket multiplayer implementation of [MultiplayerClient].
/// Connects to the Mini Militia game server and replicates player movements,
/// jetpack flights, shooting events, and combat damage across all connected clients.
class WebSocketMultiplayerClient implements MultiplayerClient {
  final String serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final Map<String, PlayerState> _remotePlayers = {};
  final _playersController = StreamController<List<PlayerState>>.broadcast();
  final _bulletController = StreamController<BulletNetworkEvent>.broadcast();

  final String _localPlayerId = 'p_${DateTime.now().millisecondsSinceEpoch % 100000}';
  String _roomId = 'ARENA-1';
  bool _isConnected = false;

  WebSocketMultiplayerClient({
    this.serverUrl = 'wss://team-b-6hro.onrender.com',
  });

  bool get isConnected => _isConnected;
  String get roomId => _roomId;

  @override
  Stream<List<PlayerState>> get playersStream => _playersController.stream;

  @override
  Stream<BulletNetworkEvent> get bulletStream => _bulletController.stream;

  @override
  List<PlayerState> get currentPlayers => _remotePlayers.values.toList();

  @override
  String get localPlayerId => _localPlayerId;

  @override
  Future<void> connect({
    required String roomId,
    required String playerName,
    required int characterId,
  }) async {
    _roomId = roomId.trim().toUpperCase();
    if (_roomId.isEmpty) _roomId = 'ARENA-1';

    try {
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);

      final completer = Completer<void>();

      _subscription = _channel!.stream.listen(
        (dynamic rawData) {
          try {
            final data = jsonDecode(rawData as String) as Map<String, dynamic>;
            final type = data['type'] as String?;

            switch (type) {
              case 'room_joined':
                _isConnected = true;
                final existing = data['existingPlayers'] as List<dynamic>? ?? [];
                for (final item in existing) {
                  final map = item as Map<String, dynamic>;
                  final state = PlayerState.fromMap(map);
                  if (state.playerId != _localPlayerId) {
                    _remotePlayers[state.playerId] = state;
                  }
                }
                _playersController.add(_remotePlayers.values.toList());
                if (!completer.isCompleted) completer.complete();
                break;

              case 'player_joined':
                final pid = data['playerId'] as String?;
                if (pid != null && pid != _localPlayerId) {
                  final pName = data['name'] as String? ?? 'Player';
                  final charId = (data['characterId'] as num?)?.toInt() ?? 1;
                  _remotePlayers[pid] = PlayerState(
                    playerId: pid,
                    characterId: charId,
                    name: pName,
                    x: 600.0,
                    y: 200.0,
                  );
                  _playersController.add(_remotePlayers.values.toList());
                }
                break;

              case 'player_update':
                final stateMap = data['state'] as Map<String, dynamic>?;
                if (stateMap != null) {
                  final state = PlayerState.fromMap(stateMap);
                  if (state.playerId != _localPlayerId) {
                    _remotePlayers[state.playerId] = state;
                    _playersController.add(_remotePlayers.values.toList());
                  }
                }
                break;

              case 'shoot':
                final eventMap = data['event'] as Map<String, dynamic>?;
                if (eventMap != null) {
                  final event = BulletNetworkEvent.fromMap(eventMap);
                  if (event.shooterId != _localPlayerId) {
                    _bulletController.add(event);
                  }
                }
                break;

              case 'player_left':
                final leftId = data['playerId'] as String?;
                if (leftId != null) {
                  _remotePlayers.remove(leftId);
                  _playersController.add(_remotePlayers.values.toList());
                }
                break;

              case 'damage':
                final targetId = data['targetPlayerId'] as String?;
                final dmg = (data['damage'] as num?)?.toDouble() ?? 0.0;
                if (targetId != null && _remotePlayers.containsKey(targetId)) {
                  final current = _remotePlayers[targetId]!;
                  final newHp = (current.health - dmg).clamp(0.0, current.maxHealth);
                  _remotePlayers[targetId] = current.copyWith(
                    health: newHp,
                    isDead: newHp <= 0,
                  );
                  _playersController.add(_remotePlayers.values.toList());
                }
                break;
            }
          } catch (e) {
            debugPrint('[WebSocketMultiplayerClient] Message parse error: $e');
          }
        },
        onError: (err) {
          debugPrint('[WebSocketMultiplayerClient] Connection error: $err');
          _isConnected = false;
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          debugPrint('[WebSocketMultiplayerClient] Disconnected from server');
          _isConnected = false;
        },
      );

      // Send initial join packet
      _channel!.sink.add(jsonEncode({
        'type': 'join',
        'roomId': _roomId,
        'playerId': _localPlayerId,
        'name': playerName,
        'characterId': characterId,
      }));

      // Timeout after 3 seconds if room_joined not received
      await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          _isConnected = true; // Proceed anyway in optimistic mode
        },
      );
    } catch (e) {
      debugPrint('[WebSocketMultiplayerClient] Connect failed: $e');
      _isConnected = false;
    }
  }

  @override
  void sendPlayerUpdate(PlayerState state) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'player_update',
        'state': state.toMap(),
      }));
    } catch (e) {
      // Ignored if network transient
    }
  }

  @override
  void sendShootEvent(BulletNetworkEvent event) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'shoot',
        'event': event.toMap(),
      }));
    } catch (e) {
      // Ignored
    }
  }

  @override
  void sendDamageEvent({
    required String targetPlayerId,
    required double damage,
    required String attackerId,
  }) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'damage',
        'targetPlayerId': targetPlayerId,
        'damage': damage,
        'attackerId': attackerId,
      }));
    } catch (e) {
      // Ignored
    }
  }

  @override
  void disconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _remotePlayers.clear();
    _playersController.close();
    _bulletController.close();
  }
}
