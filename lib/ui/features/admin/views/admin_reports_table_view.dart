import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_empty_state.dart';
import '../widgets/admin_report_detail_dialog.dart';
import '../widgets/admin_search_filter_bar.dart';

class AdminReportsTableView extends StatefulWidget {
  const AdminReportsTableView({super.key});

  @override
  State<AdminReportsTableView> createState() => _AdminReportsTableViewState();
}

class _AdminReportsTableViewState extends State<AdminReportsTableView> {
  String _searchQuery = '';
  ReportStatus? _selectedStatusFilter;

  final List<Report> _mockReports = [
    Report(
      id: '101',
      title: 'Proyector sin señal y parpadeo intermitente',
      building: 'Edificio de Cómputo',
      classroom: 'Lab Cómputo 3',
      dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      details: 'El proyector no reconoce el cable HDMI y presenta pantalla azul intermitente.',
      status: ReportStatus.pendiente,
      reportedBy: 'carlos_estudiante',
    ),
    Report(
      id: '102',
      title: 'Aire acondicionado haciendo ruido fuerte',
      building: 'Edificio A',
      classroom: 'Aula A-204',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      details: 'La unidad exterior emite vibraciones excesivas y no enfria adecuadamente.',
      status: ReportStatus.enProceso,
      reportedBy: 'maria_rodriguez',
    ),
    Report(
      id: '103',
      title: 'Falta de suministros de limpieza e higiene',
      building: 'Sala General',
      classroom: 'Baños Planta Baja',
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      details: 'Se requiere reposición de jabón líquido y papel sanitario.',
      status: ReportStatus.resuelto,
      reportedBy: 'juan_perez',
    ),
    Report(
      id: '104',
      title: 'Cable de red dañado en rack principal',
      building: 'Edificio de Cómputo',
      classroom: 'Server Room B',
      dateTime: DateTime.now().subtract(const Duration(hours: 6)),
      details: 'El conector RJ45 del puerto 12 se encuentra roto.',
      status: ReportStatus.resuelto,
      reportedBy: 'sofia_sistemas',
    ),
    Report(
      id: '105',
      title: 'Reporte sin imagen ni datos claros',
      building: 'Edificio B',
      classroom: 'Aula B-101',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      details: 'Reporte rechazado por falta de información gráfica de apoyo.',
      status: ReportStatus.rechazado,
      reportedBy: 'pedro_gomez',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredReports = _mockReports.where((r) {
      final matchesQuery = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.building.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.classroom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.reportedBy.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == null || r.status == _selectedStatusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tabla de Reportes Institucionales',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dashboard administrativo para el control y seguimiento de reportes registrados.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),

            // Buscador por Texto y Filtro por Estado
            AdminSearchFilterBar<ReportStatus>(
              searchQuery: _searchQuery,
              searchHint: 'Buscar por título, edificio, aula o usuario...',
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onClearSearch: () => setState(() => _searchQuery = ''),
              filterOptions: ReportStatus.values,
              selectedFilter: _selectedStatusFilter,
              onFilterSelected: (status) => setState(() => _selectedStatusFilter = status),
              getLabel: (status) => status.displayName,
            ),
            const SizedBox(height: 12),

            // Tabla de Datos Administrativa
            Expanded(
              child: filteredReports.isEmpty
                  ? const CustomEmptyState(
                      icon: Icons.assignment_late_outlined,
                      message: 'No se encontraron reportes con los filtros seleccionados.',
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppTheme.secondaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                              ),
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,
                              columns: const [
                                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Título', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Reportante', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredReports.map((report) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('#${report.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(
                                      SizedBox(
                                        width: 200,
                                        child: Text(
                                          report.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${report.building}\n${report.classroom}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DataCell(Text(report.reportedBy, style: const TextStyle(fontSize: 12))),
                                    DataCell(_buildStatusBadge(report.status, isDark)),
                                    DataCell(Text(report.timeAgo, style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor, size: 20),
                                        tooltip: 'Ver Detalle',
                                        onPressed: () => AdminReportDetailDialog.show(context, report),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status, bool isDark) {
    Color bg;
    Color fg;

    switch (status) {
      case ReportStatus.pendiente:
        bg = isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFFF3E0);
        fg = isDark ? Colors.amberAccent : const Color(0xFFD97706);
        break;
      case ReportStatus.enProceso:
        bg = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFE8F0FF);
        fg = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
        break;
      case ReportStatus.resuelto:
        bg = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F8EE);
        fg = isDark ? Colors.greenAccent : const Color(0xFF16A34A);
        break;
      case ReportStatus.rechazado:
        bg = isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFFE8E8);
        fg = isDark ? Colors.redAccent : const Color(0xFFDC2626);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
