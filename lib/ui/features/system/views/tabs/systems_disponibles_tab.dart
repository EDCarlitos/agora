import 'package:flutter/material.dart';
import '../../../../../data/models/user.dart';
import '../../../../../data/models/report.dart'; // Asegúrate de importar el modelo Report
import '../../../../core/theme.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../widgets/agora_incident_card.dart';
import '../../../widgets/agora_horizontal_incident_card.dart'; // Importamos la nueva tarjeta horizontal
import '../../view_models/systems_dashboard_view_model.dart';
import '../../utils/system_utils.dart';
import '../../../students/views/report_detail_view.dart';

class SystemsDisponiblesTab extends StatelessWidget {
  final SystemsDashboardViewModel viewModel;
  final User user;
  final Function(int) onTabChange;

  const SystemsDisponiblesTab({
    super.key,
    required this.viewModel,
    required this.user,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final items = viewModel.availableReports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return const CustomEmptyState(
          message: 'No hay reportes nuevos por asignar.',
          icon: Icons.inbox_outlined);
    }

    final List<Report> reports = items;
    
    // Tomamos los primeros 5 para el carrusel superior
    final List<Report> recentReports = reports.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // --- 1. SECCIÓN: REPORTES RECIENTES ---
          _buildSectionHeader('Reportes Recientes', 'Ver todos', isDark),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recentReports.length,
              itemBuilder: (context, index) {
                final report = recentReports[index];
                return AgoraHorizontalIncidentCard(
                  report: report,
                  onTap: () => _navigateToDetail(context, report),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. SECCIÓN: INCIDENCIAS PENDIENTES ---
          _buildSectionHeader('Incidencias pendientes', 'Ver todos', isDark),
          ListView.builder(
            shrinkWrap: true, // Importante para que funcione dentro del SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Evita scroll doble
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return AgoraIncidentCard(
                report: report,
                headerIconColor: AppTheme.primaryColor,
                onTap: () => _navigateToDetail(context, report),
              );
            },
          ),
          
          const SizedBox(height: 24), // Espaciado extra al final
        ],
      ),
    );
  }

  // Lógica centralizada para navegar y manejar la auto-asignación
  void _navigateToDetail(BuildContext context, Report report) async {
    final assigned = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailView(
          report: report,
          currentUser: user,
        ),
      ),
    );

    if (assigned == true) {
      onTabChange(1); 
    }
  }

  // Constructor de encabezados de sección para mantener DRY
  Widget _buildSectionHeader(String title, String actionText, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.secondaryColor,
            ),
          ),
          Text(
            actionText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor, // Usando el color guinda
            ),
          ),
        ],
      ),
    );
  }
}