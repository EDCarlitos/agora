import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../utils/api_config.dart';

class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get stream =>
      _messageController?.stream ?? const Stream.empty();
  bool get isConnected => _isConnected;

  /// Conecta con el servidor WebSocket usando el token JWT del usuario.
  void connect(String jwtToken) {
    if (_isConnected && _channel != null) return;

    try {
      final baseUrl = ApiConfig.baseUrl;
      String wsUrl;

      if (baseUrl.startsWith('https://')) {
        wsUrl = baseUrl.replaceFirst('https://', 'wss://');
      } else if (baseUrl.startsWith('http://')) {
        wsUrl = baseUrl.replaceFirst('http://', 'ws://');
      } else {
        wsUrl = 'ws://$baseUrl';
      }

      final uri = Uri.parse('$wsUrl/ws/chat?token=$jwtToken');
      _channel = WebSocketChannel.connect(uri);
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      _isConnected = true;

      _channel!.stream.listen(
        (rawData) {
          try {
            final Map<String, dynamic> data = jsonDecode(rawData.toString());
            _messageController?.add(data);
          } catch (e) {
            debugPrint('Error decodificando mensaje WebSocket: $e');
          }
        },
        onError: (error) {
          debugPrint('Error en conexión WebSocket: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('Conexión WebSocket cerrada');
          _handleDisconnect();
        },
      );

      debugPrint('WebSocket conectado a $wsUrl/ws/chat');
    } catch (e) {
      debugPrint('Excepción al conectar WebSocket: $e');
      _handleDisconnect();
    }
  }

  /// Suscribe el cliente a la sala de una incidencia específica.
  void joinRoom(int incidenciaId) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'type': 'join',
        'incidenciaId': incidenciaId,
      }));
    }
  }

  /// Desuscribe el cliente de la sala de una incidencia.
  void leaveRoom(int incidenciaId) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'type': 'leave',
        'incidenciaId': incidenciaId,
      }));
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
  }

  /// Cierra la conexión del WebSocket.
  void disconnect() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _messageController?.close();
    _messageController = null;
    _channel = null;
    _isConnected = false;
  }
}
