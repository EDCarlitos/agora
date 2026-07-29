import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';

class ChatService {
  final String chatsUrl = '${ApiConfig.baseUrl}/chats';

  // 1. Obtener la lista de chats activos del usuario
  Future<List<Chat>> getChats(String jwtToken) async {
    final response = await http.get(
      Uri.parse(chatsUrl),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final List<dynamic> rawChats = decodedData['chats'] ?? [];
      return rawChats
          .whereType<Map<String, dynamic>>()
          .map((c) => Chat.fromJson(c))
          .toList();
    } else {
      throw Exception('Error al cargar los chats: ${response.body}');
    }
  }

  // 2. Obtener el detalle y el historial de mensajes de un chat
  Future<Chat> getChatDetail(String jwtToken, int incidenciaId) async {
    final response = await http.get(
      Uri.parse('$chatsUrl/$incidenciaId'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final chatMap = decodedData['chat'] as Map<String, dynamic>? ?? {};
      return Chat.fromJson(chatMap);
    } else {
      throw Exception('Error al cargar chat: ${response.body}');
    }
  }

  // 3. Enviar un mensaje (Texto plano o Imagen)
  Future<ChatMessage> sendMessage({
    required String jwtToken,
    required int incidenciaId,
    required String tipo, // 'mensaje' o 'imagen'
    String? contenido,
    String? imagePath,
  }) async {
    final uri = Uri.parse('$chatsUrl/$incidenciaId/messages');

    if (tipo == 'imagen' && imagePath != null) {
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $jwtToken';
      request.fields['tipo'] = 'imagen';
      request.files.add(await http.MultipartFile.fromPath('imagen', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final rawMsg = jsonDecode(response.body)['mensaje'] as Map<String, dynamic>;
        return ChatMessage.fromJson(rawMsg);
      } else {
        throw Exception('Error al enviar imagen: ${response.body}');
      }
    } else {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contenido': contenido,
          'tipo': 'mensaje',
        }),
      );

      if (response.statusCode == 201) {
        final rawMsg = jsonDecode(response.body)['mensaje'] as Map<String, dynamic>;
        return ChatMessage.fromJson(rawMsg);
      } else {
        throw Exception('Error al enviar mensaje: ${response.body}');
      }
    }
  }
}