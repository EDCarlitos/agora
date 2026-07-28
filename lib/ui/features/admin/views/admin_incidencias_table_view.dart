import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_empty_state.dart';
import '../widgets/admin_incidencia_detail_dialog.dart';
import '../widgets/admin_search_filter_bar.dart';

class AdminIncidenciasTableView extends StatefulWidget {
  const AdminIncidenciasTableView({super.key});

  @override
  State<AdminIncidenciasTableView> createState() => _AdminIncidenciasTableViewState();
}

class _AdminIncidenciasTableViewState extends State<AdminIncidenciasTableView> {
  String _searchQuery = '';
  String? _selectedStatusFilter;

  static const List<String> _statusOptions = ['EN_PROCESO', 'FINALIZADA', 'REABIERTA'];

  final List<MockIncidencia> _mockIncidencias = [
    MockIncidencia(
      id: '201',
      reporteId: '102',
      titulo: 'Reparación compresor aire acondicionado',
      edificio: 'Edificio A',
      aula: 'Aula A-204',
      asignadoA: 'Roberto Mantenimiento',
      estado: 'EN_PROCESO',
      fechaCreacion: DateTime.now().subtract(const Duration(hours: 1)),
      descripcionResolucion: 'En revisión técnica del módulo de condensador.',
    ),
    MockIncidencia(
      id: '202',
      reporteId: '104',
      titulo: 'Restablecimiento de cableado ethernet puerto 12',
      edificio: 'Edificio de Cómputo',
      aula: 'Server Room B',
      asignadoA: 'Sofia Sistemas',
      estado: 'FINALIZADA',
      fechaCreacion: DateTime.now().subtract(const Duration(hours: 5)),
      descripcionResolucion: 'Reemplazo de patch cord Cat6 y prueba de enlace a 1Gbps exitosa.',
    ),
    MockIncidencia(
      id: '203',
      reporteId: '107',
      titulo: 'Revisión por falla intermitente en switch de red',
      edificio: 'Biblioteca',
      aula: 'Sala de Redes 1',
      asignadoA: 'Sofia Sistemas',
      estado: 'REABIERTA',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
      descripcionResolucion: 'Solicitud de reapertura por inconsistencia de conectividad.',
    ),
  ];

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'EN_PROCESO':
        return 'En Proceso';
      case 'FINALIZADA':
        return 'Finalizada';
      case 'REABIERTA':
        return 'Reabierta';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _mockIncidencias.where((inc) {
      final matchesQuery = inc.id.contains(_searchQuery) ||
          inc.reporteId.contains(_searchQuery) ||
          inc.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inc.asignadoA.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inc.edificio.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == null || inc.estado == _selectedStatusFilter;
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
                    'Tabla de Incidencias Técnicas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dashboard de supervisión de trabajos técnicos en curso, asignaciones y resoluciones.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),

            // Buscador por Texto y Filtro por Estado
            AdminSearchFilterBar<String>(
              searchQuery: _searchQuery,
              searchHint: 'Buscar por ID, título, encargado o ubicación...',
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onClearSearch: () => setState(() => _searchQuery = ''),
              filterOptions: _statusOptions,
              selectedFilter: _selectedStatusFilter,
              onFilterSelected: (status) => setState(() => _selectedStatusFilter = status),
              getLabel: _formatStatusLabel,
            ),
            const SizedBox(height: 12),

            // Tabla de Datos Administrativa
            Expanded(
              child: filtered.isEmpty
                  ? const CustomEmptyState(
                      icon: Icons.engineering_outlined,
                      message: 'No se encontraron incidencias con los criterios seleccionados.',
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
                                DataColumn(label: Text('Incidencia ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Reporte ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Título', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Personal Asignado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Antigüedad', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((inc) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('#${inc.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text('#${inc.reporteId}')),
                                    DataCell(
                                      SizedBox(
                                        width: 200,
                                        child: Text(
                                          inc.titulo,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${inc.edificio}\n${inc.aula}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DataCell(Text(inc.asignadoA, style: const TextStyle(fontSize: 12))),
                                    DataCell(_buildStatusBadge(inc.estado, isDark)),
                                    DataCell(Text(inc.timeAgo, style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor, size: 20),
                                        tooltip: 'Ver Detalle',
                                        onPressed: () => AdminIncidenciaDetailDialog.show(context, inc),
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

  Widget _buildStatusBadge(String estado, bool isDark) {
    Color bg;
    Color fg;
    String textLabel;

    switch (estado) {
      case 'EN_PROCESO':
        bg = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFE8F0FF);
        fg = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
        textLabel = 'En Proceso';
        break;
      case 'FINALIZADA':
        bg = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F8EE);
        fg = isDark ? Colors.greenAccent : const Color(0xFF16A34A);
        textLabel = 'Finalizada';
        break;
      case 'REABIERTA':
        bg = isDark ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF);
        fg = isDark ? Colors.purpleAccent : const Color(0xFF9333EA);
        textLabel = 'Reabierta';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey;
        textLabel = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        textLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
