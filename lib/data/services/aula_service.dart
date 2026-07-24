import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class AulaService {
  Future<List<dynamic>> getAulas(String jwtToken) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/aulas'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      return decodedData['aulas'];
    } else {
      throw Exception('Error al cargar las aulas: ${response.body}');
    }
  }
}