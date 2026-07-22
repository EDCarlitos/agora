import '../../utils/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  // Usamos el baseUrl de tu archivo de configuración y le agregamos el endpoint
  final String reportsUrl = '${ApiConfig.baseUrl}/reports';
  
  // 1. Obtener todos los reportes
  Future<List<dynamic>> getReports(String jwtToken) async {
    final response = await http.get(
      Uri.parse(reportsUrl),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      return decodedData['reportes'];
    } else {
      throw Exception('Error al cargar los reportes: ${response.body}');
    }
  }

  // 2. Obtener el detalle de un reporte por ID
  Future<Map<String, dynamic>> getReportById(String jwtToken, int reportId) async {
    final response = await http.get(
      Uri.parse('$reportsUrl/$reportId'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      return decodedData['reporte'];
    } else {
      throw Exception('Error al cargar el reporte: ${response.body}');
    }
  }

  // 3. Crear un nuevo reporte con imagen
  Future<Map<String, dynamic>> createReport({
    required String jwtToken,
    required String titulo,
    required String descripcion,
    String? imagePath, // Ruta de la imagen en el dispositivo
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(reportsUrl));
    
    // Cabecera de autenticación
    request.headers['Authorization'] = 'Bearer $jwtToken';
    
    // Campos de texto
    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;

    // Adjuntar imagen si existe
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('imagenes', imagePath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final decodedData = jsonDecode(response.body);
      return decodedData['reporte'];
    } else {
      throw Exception('Error al crear el reporte: ${response.body}');
    }
  }
}