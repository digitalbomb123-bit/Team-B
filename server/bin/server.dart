// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// In-memory room record
class GameRoom {
  final String id;
  final Map<String, ConnectedClient> clients = {};
  final Map<String, Map<String, dynamic>> playerStates = {};

  GameRoom(this.id);
}

class ConnectedClient {
  final String playerId;
  final WebSocket socket;
  String name;
  int characterId;

  ConnectedClient({
    required this.playerId,
    required this.socket,
    required this.name,
    required this.characterId,
  });
}

final Map<String, GameRoom> rooms = {};

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8081;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('====================================================');
  print(' Mini Militia 2D WebSocket Server');
  print(' Listening on port $port');
  print(' Ready for health checks & multiplayer connections');
  print('====================================================');

  server.listen((HttpRequest request) async {
    // 1. If it's a WebSocket upgrade request, establish WebSocket connection
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocketClient(socket);
      } catch (e) {
        print('[WS UPGRADE ERROR] $e');
      }
      return;
    }

    // 2. HTTP Health Check endpoint (for Render.com, Cloudflare, etc.)
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({
        'status': 'healthy',
        'service': 'Mini Militia 2D WebSocket Relay',
        'activeRooms': rooms.length,
        'uptime': DateTime.now().toIso8601String(),
      }))
      ..close();
  });
}

void _handleWebSocketClient(WebSocket socket) {
  String? currentRoomId;
  String? currentPlayerId;

  socket.listen(
    (dynamic rawData) {
      try {
        final data = jsonDecode(rawData as String) as Map<String, dynamic>;
        final type = data['type'] as String?;

        switch (type) {
          case 'join':
            currentRoomId = (data['roomId'] as String?)?.trim().toUpperCase();
            if (currentRoomId == null || currentRoomId!.isEmpty) {
              currentRoomId = 'ARENA-1';
            }
            currentPlayerId = data['playerId'] as String? ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
            final playerName = data['name'] as String? ?? 'Soldier';
            final characterId = (data['characterId'] as num?)?.toInt() ?? 1;

            final room = rooms.putIfAbsent(currentRoomId!, () => GameRoom(currentRoomId!));

            // Max 10 players per room
            if (room.clients.length >= 10 && !room.clients.containsKey(currentPlayerId)) {
              socket.add(jsonEncode({
                'type': 'error',
                'message': 'Room $currentRoomId is full (Max 10 players).',
              }));
              socket.close();
              return;
            }

            final client = ConnectedClient(
              playerId: currentPlayerId!,
              socket: socket,
              name: playerName,
              characterId: characterId,
            );
            room.clients[currentPlayerId!] = client;

            print('[JOIN] Player "$playerName" ($currentPlayerId) joined room [$currentRoomId]. Room count: ${room.clients.length}');

            // Send back confirmation and current states of existing players in this room
            socket.add(jsonEncode({
              'type': 'room_joined',
              'roomId': currentRoomId,
              'playerId': currentPlayerId,
              'existingPlayers': room.playerStates.values.toList(),
            }));

            // Notify other players in the room
            _broadcastToRoom(
              roomId: currentRoomId!,
              excludePlayerId: currentPlayerId,
              payload: jsonEncode({
                'type': 'player_joined',
                'playerId': currentPlayerId,
                'name': playerName,
                'characterId': characterId,
              }),
            );
            break;

          case 'player_update':
            if (currentRoomId != null && currentPlayerId != null) {
              final state = data['state'] as Map<String, dynamic>?;
              if (state != null) {
                final room = rooms[currentRoomId];
                if (room != null) {
                  room.playerStates[currentPlayerId!] = state;
                  _broadcastToRoom(
                    roomId: currentRoomId!,
                    excludePlayerId: currentPlayerId,
                    payload: rawData.toString(),
                  );
                }
              }
            }
            break;

          case 'shoot':
          case 'damage':
          case 'respawn':
          case 'chat':
            if (currentRoomId != null) {
              _broadcastToRoom(
                roomId: currentRoomId!,
                excludePlayerId: currentPlayerId,
                payload: rawData.toString(),
              );
            }
            break;

          default:
            print('[WARN] Unknown message type: $type');
        }
      } catch (e) {
        print('[ERROR] Error processing message: $e');
      }
    },
    onDone: () {
      if (currentRoomId != null && currentPlayerId != null) {
        final room = rooms[currentRoomId];
        if (room != null) {
          room.clients.remove(currentPlayerId);
          room.playerStates.remove(currentPlayerId);
          print('[LEAVE] Player $currentPlayerId left room [$currentRoomId]. Remaining: ${room.clients.length}');

          _broadcastToRoom(
            roomId: currentRoomId!,
            excludePlayerId: null,
            payload: jsonEncode({
              'type': 'player_left',
              'playerId': currentPlayerId,
            }),
          );

          if (room.clients.isEmpty) {
            rooms.remove(currentRoomId);
            print('[CLEANUP] Room [$currentRoomId] closed because it is empty.');
          }
        }
      }
    },
    onError: (err) {
      print('[SOCKET ERROR] $err');
    },
  );
}

void _broadcastToRoom({
  required String roomId,
  required String? excludePlayerId,
  required String payload,
}) {
  final room = rooms[roomId];
  if (room == null) return;

  for (final client in room.clients.values) {
    if (client.playerId != excludePlayerId && client.socket.readyState == WebSocket.open) {
      try {
        client.socket.add(payload);
      } catch (e) {
        // Socket error, will be cleaned up in onDone
      }
    }
  }
}
