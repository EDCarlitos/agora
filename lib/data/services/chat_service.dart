import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class ChatService {
  final String chatsUrl = '${ApiConfig.baseUrl}/chats';

  // 1. Obtener la lista de chats activos del usuario
  Future<List<dynamic>> getChats(String jwtToken) async {
    final response = await http.get(
      Uri.parse(chatsUrl),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      return decodedData['chats'] ?? [];
    } else {
      throw Exception('Error al cargar los chats: ${response.body}');
    }
  }

  // 2. Obtener el detalle y el historial de mensajes de un chat
  Future<Map<String, dynamic>> getChatDetail(String jwtToken, int incidenciaId) async {
    final response = await http.get(
      Uri.parse('$chatsUrl/$incidenciaId'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      return decodedData['chat'];
    } else {
      throw Exception('Error al cargar chat: ${response.body}');
    }
  }

  // 3. Enviar un mensaje (Texto plano o Imagen)
  Future<Map<String, dynamic>> sendMessage({
    required String jwtToken,
    required int incidenciaId,
    required String tipo, // 'mensaje' o 'imagen'
    String? contenido,
    String? imagePath,
  }) async {
    final uri = Uri.parse('$chatsUrl/$incidenciaId/messages');

    if (tipo == 'imagen' && imagePath != null) {
      // Subida de imagen usando multipart/form-data (El backend la manda a Cloudinary)
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $jwtToken';
      request.fields['tipo'] = 'imagen';
      request.files.add(await http.MultipartFile.fromPath('imagen', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['mensaje'];
      } else {
        throw Exception('Error al enviar imagen: ${response.body}');
      }
    } else {
      // Envío de texto estándar usando JSON
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
        return jsonDecode(response.body)['mensaje'];
      } else {
        throw Exception('Error al enviar mensaje: ${response.body}');
      }
    }
  }
}