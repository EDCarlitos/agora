import '../../utils/api_config.dart';
import 'dart:convert';
import 'dart:typed_data';
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
    required int idEdificio,
    required int idAula,
    List<String>? imagePaths, // <-- CAMBIO: Ahora es una lista
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(reportsUrl));
    
    // Cabecera de autenticación
    request.headers['Authorization'] = 'Bearer $jwtToken';

    // CAMPOS EXACTOS DE LA API
    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['idEdificio'] = idEdificio.toString();
    request.fields['idAula'] = idAula.toString();

    // ADJUNTAR IMÁGENES (Con la llave "imagenes" que espera tu backend de Express)
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (String path in imagePaths) {
        request.files.add(
          await http.MultipartFile.fromPath('imagenes', path),
        );
      }
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

  // 4. Descargar PDF de Auditoría Mensual
  Future<Uint8List> downloadAuditPdf(String jwtToken, {int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['mes'] = month.toString();
    if (year != null) queryParams['anio'] = year.toString();

    final uri = Uri.parse('$reportsUrl/audit/pdf').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('La respuesta de la API para el PDF excedió el tiempo límite (20s).');
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al descargar el PDF de auditoría: ${response.statusCode} - ${response.body}');
    }
  }
}