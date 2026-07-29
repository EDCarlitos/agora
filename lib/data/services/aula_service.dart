import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../models/aula.dart';

class AulaService {
  Future<List<Aula>> getAulas(String jwtToken) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/aulas'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      final List<dynamic> list = decodedData['aulas'] ?? [];
      return list.map((item) => Aula.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error al cargar las aulas: ${response.body}');
    }
  }
}