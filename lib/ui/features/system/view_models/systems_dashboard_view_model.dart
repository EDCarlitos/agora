import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/report_service.dart';
import '../../../../utils/api_config.dart';

class SystemsDashboardViewModel extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Listas de datos crudos (JSON) parseadas desde la API
  List<dynamic> _availableReports = []; 
  List<dynamic> _myInProgressIncidents = []; 
  List<dynamic> _myResolvedIncidents = []; 
  
  List<dynamic> get availableReports => _availableReports;
  List<dynamic> get myInProgressIncidents => _myInProgressIncidents;
  List<dynamic> get myResolvedIncidents => _myResolvedIncidents;

  Future<void> loadDashboardData(User currentUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = AuthService().token;
      if (token != null) {
        // 1. Obtenemos TODOS los reportes desde la API
        final apiReports = await _reportService.getReports(token);
        
        // 2. Filtramos los "Disponibles" (Estado NUEVO y que correspondan a Sistemas)
        _availableReports = apiReports.where((r) {
          final estado = r['estado'];
          final tipo = (r['tipo'] ?? '').toString().toLowerCase();
          // Inferimos el área igual que en el dashboard de estudiante
          final isSistemas = !tipo.contains('limpieza') && !tipo.contains('basura') && !tipo.contains('silla'); 
          return estado == 'NUEVO' && isSistemas;
        }).toList();

        // 3. Filtramos "Mis Asignaciones" (Tienen incidencia, son mías, y están abiertas o en proceso)
        _myInProgressIncidents = apiReports.where((r) {
          final inc = r['incidencia'];
          if (inc == null) return false;
          
          final isMine = inc['id_usuarioAministrativo'] == int.parse(currentUser.id);
          final isActiva = inc['estado'] == 'abierta' || inc['estado'] == 'en_proceso' || inc['estado'] == 'reabierta';
          return isMine && isActiva;
        }).toList();

        // 4. Filtramos "Resueltos" (Tienen incidencia, son mías, y están finalizadas)
        _myResolvedIncidents = apiReports.where((r) {
          final inc = r['incidencia'];
          if (inc == null) return false;

          final isMine = inc['id_usuarioAministrativo'] == int.parse(currentUser.id);
          final isTerminada = inc['estado'] == 'finalizada' || inc['estado'] == 'cerrada';
          return isMine && isTerminada;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error cargando datos de sistemas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto-asignarse un reporte (POST /incidencias)
  Future<bool> assignReportToMe(int reporteId, User currentUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = AuthService().token;
      if (token == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/incidencias');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reporteId': reporteId}),
      );

      if (response.statusCode == 201) {
        await loadDashboardData(currentUser); // Recargamos para actualizar las listas
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al asignarse reporte: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Finalizar incidencia con evidencia (POST /incidencias/:id/finalizar)
  Future<bool> resolveIncident(int incidenciaId, String descripcion, List<String> imagePaths, User currentUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = AuthService().token;
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/incidencias/$incidenciaId/finalizar');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      if (descripcion.isNotEmpty) {
        request.fields['descripcion'] = descripcion;
      }

      for (String path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('imagenes', path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadDashboardData(currentUser); // Recargamos para mover a la pestaña de historial
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al finalizar incidencia: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}